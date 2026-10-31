import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/chat_model.dart';
import '../../providers/chat_provider.dart';

class AiChatScreen extends StatefulWidget {
  final String? initialPrompt;

  const AiChatScreen({super.key, this.initialPrompt});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chat = Provider.of<ChatProvider>(context, listen: false);
      chat.initSession();
      if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
        chat.sendMessage(widget.initialPrompt!);
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    _inputController.clear();
    final chat = Provider.of<ChatProvider>(context, listen: false);
    chat.sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chat = Provider.of<ChatProvider>(context);

    // Scroll down when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chat.isLoading) {
        _scrollToBottom();
      }
    });

    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          actions: [
            if (isKeyboardOpen)
              IconButton(
                icon: const Icon(Icons.keyboard_hide_rounded),
                tooltip: 'Thu gọn bàn phím',
                onPressed: () => FocusScope.of(context).unfocus(),
              ),
          ],
          title: Row(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.smart_toy_outlined, color: AppColors.primary, size: 20),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trợ lý AI Enigma', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text('Kỹ thuật RAG & Tâm lý thích nghi', style: TextStyle(fontSize: 11, color: AppColors.secondary)),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Emergency Crisis Banner if active
            if (chat.activeAlert != null && chat.activeAlert!.level == 'RED')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: AppColors.riskRed.withOpacity(0.9),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Phát hiện dấu hiệu quá tải tâm lý! Nếu bạn cần trợ giúp khẩn cấp, hãy liên hệ ngay Quản lý ca hoặc Giảng viên phụ trách.',
                        style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 18),
                      onPressed: () => chat.dismissAlert(),
                    ),
                  ],
                ),
              ),

            // Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                itemCount: chat.messages.length + (chat.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == chat.messages.length && chat.isLoading) {
                    return _buildLoadingBubble();
                  }
                  final msg = chat.messages[index];
                  return _buildMessageBubble(msg);
                },
              ),
            ),

            // Quick Prompt Suggestions (if few messages)
            if (chat.messages.length <= 2)
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: chat.suggestions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final sug = chat.suggestions[idx];
                    return ActionChip(
                      label: Text(sug, style: const TextStyle(fontSize: 11, color: AppColors.primaryLight)),
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onPressed: () {
                        _inputController.text = sug;
                        _send();
                      },
                    );
                  },
                ),
              ),

            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Nhập câu hỏi hoặc tâm sự khó khăn ca làm...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        suffixIcon: isKeyboardOpen
                            ? IconButton(
                                icon: const Icon(Icons.keyboard_hide_rounded, size: 20),
                                tooltip: 'Ẩn bàn phím',
                                color: AppColors.textMuted,
                                onPressed: () => FocusScope.of(context).unfocus(),
                              )
                            : null,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: chat.isLoading ? null : _send,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: msg.isUser ? AppColors.surfaceElevated : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 18),
          ),
          border: Border.all(
            color: msg.isUser ? AppColors.primary.withOpacity(0.3) : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.content,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: msg.isUser ? AppColors.textPrimary : AppColors.textPrimary,
              ),
            ),
            if (msg.ragSources != null && msg.ragSources!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.menu_book, size: 12, color: AppColors.secondary),
                        SizedBox(width: 4),
                        Text(
                          'CƠ SỞ TRI THỨC ĐỐI CHIẾU (RAG):',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...msg.ragSources!.map((s) => Text(
                          '• ${s.toString()}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Text(
              'Enigma đang tra cứu cẩm nang & suy nghĩ...',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
