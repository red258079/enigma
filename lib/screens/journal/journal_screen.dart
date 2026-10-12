import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/journal_model.dart';
import '../../providers/journal_provider.dart';
import 'journal_history_screen.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  double _sleepHours = 6.5;
  int _stressLevel = 3;
  final List<String> _selectedSymptoms = [];
  final _noteController = TextEditingController();

  final List<String> _availableSymptoms = [
    'Đau gan bàn chân (giày ESD)',
    'Mỏi thắt lưng (ca đứng dài)',
    'Đau mỏi cổ vai gáy',
    'Khó ngủ / Chập chờn',
    'Đau đầu / Choáng váng',
    'Khô mắt phòng sạch',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _showRiskDialog(RiskAssessmentModel risk) {
    Color riskColor = AppColors.riskGreen;
    String riskTitle = 'TÂM LÝ & THỂ CHẤT ỔN ĐỊNH (MỨC XANH)';
    IconData riskIcon = Icons.check_circle_outline;

    if (risk.level == 'YELLOW') {
      riskColor = AppColors.riskYellow;
      riskTitle = 'CẢNH BÁO CĂNG THẲNG / MỆT MỎI (MỨC VÀNG)';
      riskIcon = Icons.warning_amber_outlined;
    } else if (risk.level == 'RED') {
      riskColor = AppColors.riskRed;
      riskTitle = 'NGUY CƠ KIỆT SỨC CẤP TÍNH (MỨC ĐỎ)';
      riskIcon = Icons.error_outline;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(riskIcon, color: riskColor, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                riskTitle,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: riskColor),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (risk.reasons.isNotEmpty) ...[
              const Text(
                'Lý do ghi nhận:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              ...risk.reasons.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: AppColors.textSecondary)),
                        Expanded(child: Text(r, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
            ],
            const Text(
              'Hành động đề xuất ngay:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            ...risk.recommendedActions.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('✓ ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      Expanded(child: Text(a, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary))),
                    ],
                  ),
                )),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Return to previous screen
            },
            child: const Text('Đã hiểu & Ghi nhận'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final journal = Provider.of<JournalProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nhật ký Sinh hoạt & Stress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.textPrimary),
            tooltip: 'Lịch sử nhật ký',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JournalHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner info
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Dữ liệu giúp hệ thống AI sàng lọc nguy cơ kiệt sức (PHQ-2 / GAD-7) và đưa ra bài tập phục hồi cá nhân hóa.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 1. Sleep Hours Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '1. Thời gian ngủ thực tế:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _sleepHours < 5.0
                          ? AppColors.riskRed.withOpacity(0.15)
                          : AppColors.pillarSleep.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_sleepHours.toStringAsFixed(1)} giờ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _sleepHours < 5.0 ? AppColors.riskRed : AppColors.pillarSleep,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _sleepHours < 5.0 ? AppColors.riskRed : AppColors.pillarSleep,
                  inactiveTrackColor: AppColors.surfaceLight,
                  thumbColor: _sleepHours < 5.0 ? AppColors.riskRed : AppColors.pillarSleep,
                ),
                child: Slider(
                  value: _sleepHours,
                  min: 0.0,
                  max: 12.0,
                  divisions: 24,
                  onChanged: (val) => setState(() => _sleepHours = val),
                ),
              ),
              if (_sleepHours < 5.0)
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Text(
                    '⚠️ Ngủ dưới 5 giờ khi làm ca kíp làm tăng 70% nguy cơ mệt mỏi và đau cơ.',
                    style: TextStyle(fontSize: 12, color: AppColors.riskYellow),
                  ),
                ),
              const SizedBox(height: 24),

              // 2. Stress Level (1 - 5)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '2. Mức độ căng thẳng / áp lực:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$_stressLevel / 5',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _getStressColor(_stressLevel),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (index) {
                  final level = index + 1;
                  final isSelected = _stressLevel == level;
                  return GestureDetector(
                    onTap: () => setState(() => _stressLevel = level),
                    child: Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: isSelected ? _getStressColor(level).withOpacity(0.2) : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? _getStressColor(level) : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$level',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? _getStressColor(level) : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // 3. Physical Symptoms
              const Text(
                '3. Triệu chứng thể chất nổi bật:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableSymptoms.map((sym) {
                  final isSelected = _selectedSymptoms.contains(sym);
                  return FilterChip(
                    label: Text(sym),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedSymptoms.add(sym);
                        } else {
                          _selectedSymptoms.remove(sym);
                        }
                      });
                    },
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // 4. Note
              const Text(
                '4. Chia sẻ cảm xúc hoặc sự cố ca làm:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Hôm nay dây chuyền có lỗi, chân đau nhức nhiều khi phải đứng liên tục...',
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: journal.isLoading
                      ? null
                      : () async {
                          final navigator = Navigator.of(context);
                          final entry = await journal.submitJournal(
                            stressLevel: _stressLevel,
                            sleepHours: _sleepHours,
                            physicalSymptoms: _selectedSymptoms,
                            note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
                          );

                          if (!mounted) return;
                          if (entry != null && entry.riskAssessment != null) {
                            _showRiskDialog(entry.riskAssessment!);
                          } else {
                            navigator.pop();
                          }
                        },
                  icon: const Icon(Icons.analytics_outlined, size: 20),
                  label: journal.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnPrimary),
                        )
                      : const Text('Lưu nhật ký & Phân tích tâm lý'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStressColor(int level) {
    switch (level) {
      case 1:
        return AppColors.secondary;
      case 2:
        return AppColors.primary;
      case 3:
        return AppColors.pillarSleep;
      case 4:
        return AppColors.riskYellow;
      case 5:
        return AppColors.riskRed;
      default:
        return AppColors.primary;
    }
  }
}
