import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/chat_model.dart';
import '../models/journal_model.dart';

class ChatProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  bool _isLoading = false;
  String? _currentSessionId;
  final List<ChatMessageModel> _messages = [];
  RiskAssessmentModel? _activeAlert;

  bool get isLoading => _isLoading;
  String? get currentSessionId => _currentSessionId;
  List<ChatMessageModel> get messages => _messages;
  RiskAssessmentModel? get activeAlert => _activeAlert;

  final List<String> suggestions = [
    'Tôi bị mất ngủ sau khi đổi từ ca ngày sang ca đêm',
    'Chân tôi rất đau khi mang giày ESD và đứng 12 tiếng',
    'Tôi cảm thấy lo âu vì làm việc trái ngành',
    'Tôi bất đồng về giờ giấc với bạn cùng phòng KTX',
    'Quy tắc 5S tại LG Display yêu cầu những gì?',
  ];

  void dismissAlert() {
    _activeAlert = null;
    notifyListeners();
  }

  Future<void> initSession() async {
    if (_messages.isNotEmpty) return;

    // Welcome greeting from Enigma AI
    _messages.add(
      ChatMessageModel(
        id: 'welcome-msg',
        isUser: false,
        content: 'Chào bạn! Mình là Trợ lý AI Enigma 🤖. Mình ở đây để đồng hành và hỗ trợ bạn vượt qua những khó khăn về giấc ngủ, áp lực ca kíp và thích nghi với môi trường thực tập tại nhà máy. Bạn đang cảm thấy thế nào hôm nay?',
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();

    try {
      final res = await _api.dio.post(
        ApiConstants.chatSessions,
        data: {'title': 'Tư vấn Enigma AI'},
      );
      if (res.statusCode == 200) {
        _currentSessionId = res.data['id'];
      }
    } catch (_) {
      _currentSessionId = 'local-session-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<void> sendMessage(String text, {int stressLevel = 3, double sleepHours = 6.0}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final userMsg = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      isUser: true,
      content: trimmed,
      createdAt: DateTime.now(),
    );

    _messages.add(userMsg);
    _isLoading = true;
    notifyListeners();

    try {
      if (_currentSessionId != null && !_currentSessionId!.startsWith('local-')) {
        final res = await _api.dio.post(
          ApiConstants.chatMessages(_currentSessionId!),
          data: {
            'content': trimmed,
            'stress_level': stressLevel,
            'sleep_hours': sleepHours,
            'recent_symptoms': [],
          },
        );

        if (res.statusCode == 200) {
          final aiData = res.data['ai_message'];
          final aiMsg = ChatMessageModel.fromJson(aiData);
          _messages.add(aiMsg);

          if (res.data['risk_assessment'] != null) {
            final risk = RiskAssessmentModel.fromJson(res.data['risk_assessment']);
            if (risk.level == 'RED' || risk.level == 'YELLOW') {
              _activeAlert = risk;
            }
          }

          _isLoading = false;
          notifyListeners();
          return;
        }
      }
    } catch (_) {
      // Local intelligent fallback with RAG simulation
    }

    // Local simulation based on keywords
    await Future.delayed(const Duration(milliseconds: 1000));
    _generateLocalReply(trimmed);
    _isLoading = false;
    notifyListeners();
  }

  void _generateLocalReply(String text) {
    final lower = text.toLowerCase();
    String reply = '';
    List<dynamic> sources = [];

    if (lower.contains('chân') || lower.contains('esd') || lower.contains('đứng')) {
      reply = 'Việc đau nhức bàn chân khi mang giày ESD và đứng ca dài là tình trạng rất phổ biến ở các bạn thực tập sinh mới tại LG Display. Theo cẩm nang cựu sinh viên:\n\n1. Bạn nên trang bị miếng lót giày silicon có đệm vòm chân.\n2. Tối nay hãy ngâm chân nước ấm pha muối gừng 15 phút.\n3. Khi ngủ, nhớ kê gối cao dưới bắp chân để máu hồi lưu tốt hơn.';
      sources = ['Cẩm nang [h6-esd-shoes-care]: Giảm đau chân khi mang giày bảo hộ ESD'];
    } else if (lower.contains('ngủ') || lower.contains('ca đêm') || lower.contains('mệt')) {
      reply = 'Khi chuyển từ ca ngày sang ca đêm, đồng hồ sinh học bị xáo trộn mạnh. Bạn hãy áp dụng ngay:\n\n1. Treo rèm chắn sáng và đeo bịt mắt khi ngủ ban ngày.\n2. Cắt hoàn toàn cà phê sau 03:00 sáng.\n3. Nếu khó ngủ, hãy thử bài tập hít thở Box Breathing 4-4-4-4.';
      sources = ['Cẩm nang [h2-sleep-shift]: Cân bằng nhịp sinh học khi đổi ca'];
    } else if (lower.contains('căng thẳng') || lower.contains('stress') || lower.contains('áp lực')) {
      reply = 'Mình rất hiểu áp lực của bạn lúc này. Môi trường công xưởng đòi hỏi tính kỷ luật cao có thể gây choáng ngợp trong tháng đầu.\n\nHãy dành ra đúng 1 phút để thực hiện kỹ thuật Thở 4 nhịp (Box Breathing):\n- Hít vào 4 giây\n- Nín thở 4 giây\n- Thở ra 4 giây\n- Nín thở 4 giây\n\nNó sẽ giúp hạ nhịp tim và ổn định tinh thần ngay lập tức.';
      sources = ['Cẩm nang [h3-stress-relief]: Kỹ thuật thở Box Breathing'];
    } else if (lower.contains('phòng') || lower.contains('ktx') || lower.contains('bạn')) {
      reply = 'Ở trọ chung phòng khi làm việc lệch ca rất dễ va chạm. Bạn nên chủ động ngồi lại với bạn cùng phòng để thống nhất "Khung giờ yên tĩnh" (Quiet Hours). Khi về phòng lúc bạn đang ngủ, hãy dùng đèn bàn nhỏ và đeo tai nghe nhé.';
      sources = ['Cẩm nang [h7-roommate-conflict]: Ứng xử khi bất đồng bạn cùng phòng'];
    } else {
      reply = 'Cảm ơn bạn đã chia sẻ với Enigma. Mình luôn ở đây để lắng nghe. Bạn có thể xem thêm các bài viết trong mục "Cẩm nang" hoặc chia sẻ cụ thể hơn về triệu chứng mệt mỏi hay khó khăn trong ca làm để mình hỗ trợ nhé!';
    }

    _messages.add(
      ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        isUser: false,
        content: reply,
        ragSources: sources,
        createdAt: DateTime.now(),
      ),
    );
  }
}
