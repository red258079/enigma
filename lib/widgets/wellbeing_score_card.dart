import 'package:flutter/material.dart';
import '../models/wellbeing_score.dart';
import '../theme/app_theme.dart';

class WellbeingScoreCard extends StatelessWidget {
  final WellbeingScore score;
  final VoidCallback onRetakeAssessment;

  const WellbeingScoreCard({
    super.key,
    required this.score,
    required this.onRetakeAssessment,
  });

  @override
  Widget build(BuildContext context) {
    final priority = score.priorityPillar;
    final priorityInfo = PillarInfo.registry[priority]!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecorationFor(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Overall Score & Status with Circular Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: score.overallColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: score.overallColor.withValues(alpha: 0.6),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Chỉ số phục hồi sức khỏe',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface(context),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: score.overallColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: score.overallColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        score.overallStatus,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: score.overallColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Circular Score Gauge
              SizedBox(
                width: 68,
                height: 68,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 68,
                      height: 68,
                      child: CircularProgressIndicator(
                        value: (score.overall / 100).clamp(0.0, 1.0),
                        strokeWidth: 6,
                        strokeCap: StrokeCap.round,
                        backgroundColor: AppTheme.surfaceAltColor(context),
                        valueColor: AlwaysStoppedAnimation<Color>(score.overallColor),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          score.overall.round().toString(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: score.overallColor,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          '/100',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurfaceMuted(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          Container(
            height: 1,
            color: AppTheme.borderColor(context),
          ),
          const SizedBox(height: 16),

          // 5 Pillars Progress Bars
          _buildPillarRow(context, PillarType.mental, score.mental),
          const SizedBox(height: 10),
          _buildPillarRow(context, PillarType.sleep, score.sleep),
          const SizedBox(height: 10),
          _buildPillarRow(context, PillarType.physical, score.physical),
          const SizedBox(height: 10),
          _buildPillarRow(context, PillarType.social, score.social),
          const SizedBox(height: 10),
          _buildPillarRow(context, PillarType.career, score.career),

          const SizedBox(height: 18),

          // Priority Alert Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: priorityInfo.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: priorityInfo.color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: priorityInfo.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(priorityInfo.icon, color: priorityInfo.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cần chú ý: ${priorityInfo.title}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: priorityInfo.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        priorityInfo.subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.onSurfaceSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onRetakeAssessment,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceAltColor(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderColor(context)),
                    ),
                    child: Text(
                      'Đo lại',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarRow(BuildContext context, PillarType type, double value) {
    final info = PillarInfo.registry[type]!;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: info.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(info.icon, size: 14, color: info.color),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: Text(
            info.title.split(' ')[0],
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurface(context),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: AppTheme.surfaceAltColor(context),
              valueColor: AlwaysStoppedAnimation<Color>(info.color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 30,
          child: Text(
            '${value.round()}',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: info.color,
            ),
          ),
        ),
      ],
    );
  }
}
