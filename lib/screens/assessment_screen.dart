import 'package:flutter/material.dart';
import '../models/assessment_question.dart';
import '../models/wellbeing_score.dart';
import '../theme/app_theme.dart';

class AssessmentScreen extends StatefulWidget {
  final Function(WellbeingScore newScore) onComplete;

  const AssessmentScreen({super.key, required this.onComplete});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final List<AssessmentQuestion> _questions = AssessmentQuestion.defaultQuestions;
  int _currentIndex = 0;
  final Map<String, double> _answers = {};

  void _selectOption(double score) {
    setState(() {
      _answers[_questions[_currentIndex].id] = score;
    });

    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _finishAssessment();
    }
  }

  void _finishAssessment() {
    // Group answers by pillar
    double mentalSum = 0;
    int mentalCount = 0;
    double sleepSum = 0;
    int sleepCount = 0;
    double physicalSum = 0;
    int physicalCount = 0;
    double socialSum = 0;
    int socialCount = 0;
    double careerSum = 0;
    int careerCount = 0;

    for (final q in _questions) {
      final val = _answers[q.id] ?? 70.0;
      switch (q.pillar) {
        case PillarType.mental:
          mentalSum += val;
          mentalCount++;
          break;
        case PillarType.sleep:
          sleepSum += val;
          sleepCount++;
          break;
        case PillarType.physical:
          physicalSum += val;
          physicalCount++;
          break;
        case PillarType.social:
          socialSum += val;
          socialCount++;
          break;
        case PillarType.career:
          careerSum += val;
          careerCount++;
          break;
      }
    }

    final newScore = WellbeingScore(
      mental: mentalCount > 0 ? mentalSum / mentalCount : 70,
      sleep: sleepCount > 0 ? sleepSum / sleepCount : 70,
      physical: physicalCount > 0 ? physicalSum / physicalCount : 70,
      social: socialCount > 0 ? socialSum / socialCount : 70,
      career: careerCount > 0 ? careerSum / careerCount : 70,
      assessedAt: DateTime.now(),
    );

    widget.onComplete(newScore);

    // Show result dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.bgSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.cardBorder),
          ),
          title: const Text(
            'Kết quả Đánh giá Sức khỏe',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Điểm tổng hợp: ${newScore.overall.round()} / 100',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: newScore.overallColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tình trạng: ${newScore.overallStatus}',
                style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceSecondary(context)),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceAltColor(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Hệ thống đã điều chỉnh lộ trình 30 ngày tập trung ưu tiên vào: ${PillarInfo.registry[newScore.priorityPillar]!.title}',
                  style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceSecondary(context)),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Bắt đầu lộ trình 30 ngày'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQ = _questions[_currentIndex];
    final pillarInfo = PillarInfo.registry[currentQ.pillar]!;
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đánh giá Tái thích nghi'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Câu ${_currentIndex + 1} / ${_questions.length}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurfaceSecondary(context),
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppTheme.surfaceAltColor(context),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
              const SizedBox(height: 24),

              // Pillar Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: pillarInfo.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(pillarInfo.icon, size: 14, color: pillarInfo.color),
                    const SizedBox(width: 6),
                    Text(
                      pillarInfo.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: pillarInfo.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Question Title
              Text(
                currentQ.question,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                  color: AppTheme.onSurface(context),
                ),
              ),
              const SizedBox(height: 6),

              // Context hint
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 15, color: AppTheme.onSurfaceMuted(context)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      currentQ.contextHint,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.onSurfaceMuted(context),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Options
              Expanded(
                child: ListView.separated(
                  itemCount: currentQ.options.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final opt = currentQ.options[idx];
                    return InkWell(
                      onTap: () => _selectOption(opt.score),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.cardDecorationFor(context),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.surfaceAltColor(context),
                                border: Border.all(color: AppTheme.borderColor(context)),
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(65 + idx), // A, B, C, D
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.onSurfaceSecondary(context),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                opt.text,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.onSurface(context),
                                  height: 1.3,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: AppTheme.onSurfaceMuted(context),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              if (_currentIndex > 0)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentIndex--;
                    });
                  },
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Quay lại câu trước'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.onSurfaceSecondary(context),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
