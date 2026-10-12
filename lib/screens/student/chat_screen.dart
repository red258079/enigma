import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../widgets/chat_bubble.dart';
import '../../theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/api/api_client.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dio/dio.dart';

class ChatScreen extends StatefulWidget {
  final String? initialContext;

  const ChatScreen({super.key, this.initialContext});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  String? _sessionId;
  String? _riskWarning;

  final List<String> _quickTopics = [
    'Quy tắc 5S & An toàn nhà máy',
    'Giảm đau chân giày bảo hộ ESD',
    'Bí quyết ngủ ngon khi đổi ca',
    'Xử lý bất đồng phòng trọ KTX',
    'Hít thở Box Breathing 4-4-4-4',
  ];

  @override
  void initState() {
    super.initState();
    _addInitialMessage();
    _initSession();
    if (widget.initialContext != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage('Tôi muốn hỏi về: ${widget.initialContext}');
      });
    }
  }

  Future<void> _initSession() async {
    if (AppConstants.useMockApi) return;
    try {
      final res = await ApiClient.instance.post('/chat/sessions', data: {'title': 'Tư vấn Thích nghi & Tâm lý'});
      if (mounted) {
        setState(() {
          _sessionId = res.data['id'];
        });
      }
    } catch (_) {}
  }

  void _resetSession() async {
    setState(() {
      _messages.clear();
      _sessionId = null;
      _riskWarning = null;
      _addInitialMessage();
    });
    await _initSession();
  }

  void _addInitialMessage() {
    _messages.add(
      ChatMessage(
        id: 'init_welcome',
        content: 'Chào bạn! Mình là Enigma AI — Trợ lý Đồng hành Tâm lý & Thích nghi Thực tập tại LG Display. 💙\n\nBạn đang gặp khó khăn gì về nhịp ca kíp, sức khỏe đứng máy, quy trình làm việc hay cuộc sống ký túc xá không?',
        isUser: false,
        timestamp: DateTime.now(),
        suggestedReplies: [
          'Đau nhức chân khi mang giày ESD',
          'Mất ngủ sau khi làm ca đêm',
          'Ngại giao tiếp với Trưởng ca',
        ],
      ),
    );
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
    });

    _controller.clear();
    _scrollToBottom();

    if (AppConstants.useMockApi || _sessionId == null) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      final mockAi = ChatMessage(
        id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
        content: 'Cảm ơn bạn đã chia sẻ! Enigma khuyên bạn nên kết hợp kỹ thuật hít thở Box Breathing 4-4-4-4 và ngâm chân nước ấm sau ca làm để phục hồi năng lượng nhé.',
        isUser: false,
        timestamp: DateTime.now(),
        suggestedReplies: ['Bài tập giãn cơ vai gáy', 'Kinh nghiệm đổi ca'],
      );

      setState(() {
        _messages.add(mockAi);
        _isTyping = false;
      });
      _scrollToBottom();
      return;
    }

    // Call Real FastAPI RAG API Endpoint
    try {
      final response = await ApiClient.instance.post(
        '/chat/sessions/$_sessionId/messages',
        data: {
          'content': text,
          'stress_level': 2,
          'sleep_hours': 7.0,
          'recent_symptoms': [],
        },
      );

      if (!mounted) return;

      final aiData = response.data['ai_message'];
      final rawSources = response.data['rag_sources'] as List?;
      final riskAssessment = response.data['risk_assessment'] as Map<String, dynamic>?;

      List<RAGSource>? sources;
      if (rawSources != null && rawSources.isNotEmpty) {
        sources = rawSources.map((s) => RAGSource.fromJson(s)).toList();
      }

      if (riskAssessment != null && riskAssessment['level'] == 'RED') {
        setState(() {
          _riskWarning = 'Cảnh báo: Phát hiện mức độ căng thẳng cao. Hãy liên hệ Y tế công ty hoặc Hotline 111 để được hỗ trợ.';
        });
      }

      final aiMsg = ChatMessage(
        id: aiData['id'],
        content: aiData['content'],
        isUser: false,
        timestamp: DateTime.now(),
        ragSources: sources,
      );

      setState(() {
        _messages.add(aiMsg);
        _isTyping = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final errorMsg = ChatMessage(
        id: 'err_${DateTime.now().millisecondsSinceEpoch}',
        content: 'Chưa thể kết nối tới máy chủ AI: ${e.response?.data['detail'] ?? 'Vui lòng kiểm tra lại kết nối mạng.'}',
        isUser: false,
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(errorMsg);
        _isTyping = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
      });
    }

    _scrollToBottom();
  }

  void _handleFeedback(ChatMessage msg, int feedback) async {
    setState(() {
      msg.feedback = feedback;
    });

    try {
      await ApiClient.instance.post(
        '/chat/messages/${msg.id}/feedback',
        data: {'feedback': feedback},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(feedback == 1 ? 'Cảm ơn bạn đã khen ngợi!' : 'Cảm ơn bạn đã góp ý để Enigma hoàn thiện hơn!'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.psychology_rounded, color: AppTheme.primaryLight, size: 24),
            SizedBox(width: 8),
            Text('Trợ Lý Thích Nghi AI'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới cuộc trò chuyện',
            onPressed: _resetSession,
          )
        ],
      ),
      body: Column(
        children: [
          // Emergency / High Risk Banner
          if (_riskWarning != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.redAccent.withOpacity(0.15),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _riskWarning!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                    onPressed: () => setState(() => _riskWarning = null),
                  ),
                ],
              ),
            ),
          ],

          // Quick Topic Chips Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: _quickTopics.map((topic) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ActionChip(
                    label: Text(topic, style: TextStyle(fontSize: 12, color: AppTheme.onSurface(context))),
                    onPressed: () => _sendMessage(topic),
                    backgroundColor: AppTheme.surfaceAltColor(context),
                    side: BorderSide(color: AppTheme.borderColor(context)),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return ChatBubble(
                    message: ChatMessage(
                      id: 'typing',
                      content: '',
                      isUser: false,
                      timestamp: DateTime.now(),
                      isLoading: true,
                    ),
                  ).animate().fade();
                }

                final msg = _messages[index];
                return ChatBubble(
                  key: ValueKey(msg.id),
                  message: msg,
                  onSuggestionTap: _sendMessage,
                  onFeedbackTap: (fb) => _handleFeedback(msg, fb),
                );
              },
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor(context),
              border: Border(top: BorderSide(color: AppTheme.borderColor(context))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(color: AppTheme.onSurface(context), fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Nhập câu hỏi hoặc tâm sự khó khăn...',
                        hintStyle: TextStyle(color: AppTheme.onSurfaceMuted(context), fontSize: 13),
                        filled: true,
                        fillColor: AppTheme.surfaceAltColor(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: () => _sendMessage(_controller.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
