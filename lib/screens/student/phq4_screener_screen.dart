import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../theme/app_theme.dart';
import 'chat_screen.dart';

class PHQ4ScreenerScreen extends StatefulWidget {
  const PHQ4ScreenerScreen({super.key});

  @override
  State<PHQ4ScreenerScreen> createState() => _PHQ4ScreenerScreenState();
}

class _PHQ4ScreenerScreenState extends State<PHQ4ScreenerScreen> {
  // 4 Câu hỏi chuẩn y khoa PHQ-4 (0 - 3 điểm)
  int _q1 = 0; // Ít hứng thú
  int _q2 = 0; // Buồn rầu
  int _q3 = 0; // Lo lắng
  int _q4 = 0; // Khó kiểm soát lo lắng

  bool _isSubmitting = false;

  static const List<String> _scaleLabels = [
    'Không hề (0đ)',
    'Vài ngày (1đ)',
    'Hơn 50% số ngày (2đ)',
    'Gần như mỗi ngày (3đ)',
  ];

  int get _depressionScore => _q1 + _q2;
  int get _anxietyScore => _q3 + _q4;
  int get _totalScore => _depressionScore + _anxietyScore;

  String get _riskLevel {
    if (_totalScore >= 9) return 'RED';
    if (_totalScore >= 6) return 'ORANGE';
    if (_totalScore >= 3) return 'YELLOW';
    return 'GREEN';
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'RED':
        return AppTheme.accentCoral;
      case 'ORANGE':
        return Colors.deepOrangeAccent;
      case 'YELLOW':
        return AppTheme.accentAmber;
      case 'GREEN':
      default:
        return AppTheme.accentMint;
    }
  }

  String _getLevelTitle(String level) {
    switch (level) {
      case 'RED':
        return 'Nguy cơ cao (Severe)';
      case 'ORANGE':
        return 'Nguy cơ vừa (Moderate)';
      case 'YELLOW':
        return 'Nguy cơ nhẹ (Mild)';
      case 'GREEN':
      default:
        return 'Tâm lý ổn định (Minimal)';
    }
  }

  Future<void> _submitAssessment() async {
    setState(() => _isSubmitting = true);

    Map<String, dynamic>? result;
    try {
      final res = await ApiClient.instance.post('/checkins/phq4', data: {
        'q1_interest': _q1,
        'q2_depressed': _q2,
        'q3_anxious': _q3,
        'q4_worry': _q4,
      });
      result = res.data is Map<String, dynamic> ? res.data : null;
    } catch (_) {
      // Local calculation fallback
      result = {
        'total_score': _totalScore,
        'depression_score': _depressionScore,
        'anxiety_score': _anxietyScore,
        'has_depression_risk': _depressionScore >= 3,
        'has_anxiety_risk': _anxietyScore >= 3,
        'level': _riskLevel,
        'severity': _getLevelTitle(_riskLevel),
        'advice': _totalScore >= 9
            ? 'Bạn đang ở ngưỡng căng thẳng nghiêm trọng. Hãy liên hệ ngay phòng Y tế hoặc hotline 111.'
            : (_totalScore >= 6
                ? 'Dấu hiệu lo âu/căng thẳng đáng kể. Hãy chủ động giảm giờ làm thêm (OT) và nghỉ ngơi.'
                : (_totalScore >= 3
                    ? 'Bạn có dấu hiệu mệt mỏi nhẹ. Hãy thực hành hít thở Box Breathing và ngủ đủ giấc.'
                    : 'Tâm lý của bạn rất ổn định và tràn đầy năng lượng!')),
        'citation': 'Dựa trên thang đo y khoa PHQ-4 (Đại học Columbia & NIH PMC8038412)',
      };
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showResultDialog(result);
      }
    }
  }

  void _showResultDialog(Map<String, dynamic>? data) {
    final level = data?['level']?.toString() ?? _riskLevel;
    final severity = data?['severity']?.toString() ?? _getLevelTitle(level);
    final advice = data?['advice']?.toString() ?? '';
    final color = _getLevelColor(level);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.onSurfaceMuted(context).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.verified_user_rounded, color: color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kết quả Sàng lọc PHQ-4',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        severity,
                        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Score cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    'Tổng điểm PHQ-4',
                    '$_totalScore / 12',
                    color,
                    'Thang đo 0 - 12',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    'Trầm cảm (PHQ-2)',
                    '$_depressionScore / 6',
                    _depressionScore >= 3 ? AppTheme.accentCoral : AppTheme.accentMint,
                    _depressionScore >= 3 ? 'Cần lưu ý (≥3)' : 'Bình thường',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    'Lo âu (GAD-2)',
                    '$_anxietyScore / 6',
                    _anxietyScore >= 3 ? AppTheme.accentCoral : AppTheme.accentMint,
                    _anxietyScore >= 3 ? 'Cần lưu ý (≥3)' : 'Bình thường',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Advice box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceAltColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor(context)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: AppTheme.accentAmber, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      advice,
                      style: const TextStyle(fontSize: 13.5, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Citation note
            Text(
              '📚 Cơ sở khoa học: Kroenke et al. (2009) & NIH PMC8038412. Công cụ hỗ trợ sàng lọc ban đầu, không thay thế chẩn đoán chuyên khoa.',
              style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceMuted(context)),
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Đóng'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChatScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.smart_toy_rounded, size: 18),
                    label: const Text('Tư vấn với AI', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color, String sub) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 9.5, color: color.withValues(alpha: 0.9)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sàng Lọc Tâm Lý PHQ-4'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medical Accreditation Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.15),
                    AppTheme.accentMint.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.health_and_safety_rounded, color: AppTheme.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chuẩn Y Khoa Quốc Tế PHQ-4',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Theo nghiên cứu Đại học Columbia (phqscreeners.com) & Viện Y tế Quốc gia Hoa Kỳ (NIH PMC8038412) cho nhân sự ca kíp.',
                          style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceSecondary(context), height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Instructions
            Text(
              'Trong 2 tuần qua, bạn bị ảnh hưởng bởi những cảm giác sau ở mức độ nào?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Chọn mức độ trung thực nhất giúp AI bảo vệ và điều chỉnh ca kíp phù hợp:',
              style: TextStyle(fontSize: 12.5, color: AppTheme.onSurfaceMuted(context)),
            ),
            const SizedBox(height: 18),

            // Question 1
            _buildQuestionCard(
              index: 1,
              category: 'Phân nhóm Trầm cảm (PHQ-2)',
              question: 'Ít hứng thú hoặc không còn cảm thấy niềm vui trong công việc / học tập?',
              selectedVal: _q1,
              onChanged: (val) => setState(() => _q1 = val),
            ),
            const SizedBox(height: 16),

            // Question 2
            _buildQuestionCard(
              index: 2,
              category: 'Phân nhóm Trầm cảm (PHQ-2)',
              question: 'Cảm thấy buồn bã, chán nản, u uất hoặc tuyệt vọng?',
              selectedVal: _q2,
              onChanged: (val) => setState(() => _q2 = val),
            ),
            const SizedBox(height: 16),

            // Question 3
            _buildQuestionCard(
              index: 3,
              category: 'Phân nhóm Lo âu (GAD-2)',
              question: 'Cảm thấy lo lắng, căng thẳng, bồn chồn hoặc đứng ngồi không yên?',
              selectedVal: _q3,
              onChanged: (val) => setState(() => _q3 = val),
            ),
            const SizedBox(height: 16),

            // Question 4
            _buildQuestionCard(
              index: 4,
              category: 'Phân nhóm Lo âu (GAD-2)',
              question: 'Không thể ngừng hoặc không thể kiểm soát được sự lo lắng của mình?',
              selectedVal: _q4,
              onChanged: (val) => setState(() => _q4 = val),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAssessment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.analytics_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Xem Kết Quả & Phân Tầng Nguy Cơ',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard({
    required int index,
    required String category,
    required String question,
    required int selectedVal,
    required Function(int) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Câu $index', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.primary)),
              ),
              const SizedBox(width: 8),
              Text(
                category,
                style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceMuted(context), fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            question,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, height: 1.35),
          ),
          const SizedBox(height: 14),

          // Options Grid / Column
          Column(
            children: List.generate(4, (i) {
              final isSelected = selectedVal == i;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: () => onChanged(i),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary.withValues(alpha: 0.12) : AppTheme.surfaceAltColor(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : AppTheme.borderColor(context),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          color: isSelected ? AppTheme.primary : AppTheme.onSurfaceMuted(context),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _scaleLabels[i],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppTheme.primary : AppTheme.onSurface(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
