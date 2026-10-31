import 'package:flutter/material.dart';

import '../models/daily_checkin.dart';
import '../theme/app_theme.dart';

class MoodCheckinCard extends StatelessWidget {
  final DailyCheckin? todayCheckin;
  final ValueChanged<MoodLevel> onMoodSelected;

  const MoodCheckinCard({
    super.key,
    this.todayCheckin,
    required this.onMoodSelected,
  });

  Color _getMoodColor(MoodLevel level) {
    switch (level) {
      case MoodLevel.great:
        return AppTheme.accentMint;
      case MoodLevel.good:
        return AppTheme.sleepColor;
      case MoodLevel.neutral:
        return AppTheme.accentAmber;
      case MoodLevel.stressed:
        return const Color(0xFFFB923C);
      case MoodLevel.overwhelmed:
        return AppTheme.accentCoral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecorationFor(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cảm xúc hôm nay',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface(context),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      todayCheckin == null
                          ? 'Chọn cảm xúc để bắt đầu điểm danh'
                          : 'Hôm nay bạn cảm thấy ${todayCheckin!.mood.checkinLabel.toLowerCase()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.onSurfaceSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (todayCheckin != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentMint.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.accentMint.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 13,
                        color: AppTheme.accentMint,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Đã điểm danh',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.accentMint,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: MoodOption.options.map((opt) {
              final isCurrent = todayCheckin?.mood == opt.level;
              final moodColor = _getMoodColor(opt.level);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: todayCheckin == null
                        ? () => onMoodSelected(opt.level)
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? moodColor.withValues(alpha: 0.18)
                            : AppTheme.surfaceAltColor(context)
                                  .withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCurrent
                              ? moodColor
                              : AppTheme.borderColor(context),
                          width: isCurrent ? 1.5 : 1.0,
                        ),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: moodColor.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            opt.emoji,
                            style: TextStyle(fontSize: isCurrent ? 26 : 22),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            opt.level.checkinLabel,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isCurrent
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isCurrent
                                  ? moodColor
                                  : AppTheme.onSurfaceSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
