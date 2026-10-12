import 'package:flutter/material.dart';
import '../models/daily_checkin.dart';
import '../theme/app_theme.dart';

class MoodCheckinCard extends StatelessWidget {
  final DailyCheckin? todayCheckin;
  final Function(MoodLevel mood, List<String> stressFactors, String note) onCheckinSubmitted;
  final VoidCallback onStartBreathing;

  const MoodCheckinCard({
    super.key,
    this.todayCheckin,
    required this.onCheckinSubmitted,
    required this.onStartBreathing,
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

  void _showCheckinDialog(BuildContext context, MoodLevel selectedMood) {
    final selectedFactors = <String>[];
    final noteController = TextEditingController();
    final moodColor = _getMoodColor(selectedMood);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final moodOpt = MoodOption.options.firstWhere((o) => o.level == selectedMood);
            final isNegative = selectedMood == MoodLevel.stressed ||
                selectedMood == MoodLevel.overwhelmed ||
                selectedMood == MoodLevel.neutral;

            return Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(top: BorderSide(color: AppTheme.borderColor(context), width: 1)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceAltColor(context),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: moodColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: moodColor.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: moodColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Text(moodOpt.emoji, style: const TextStyle(fontSize: 32)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cảm xúc của bạn',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.onSurfaceSecondary(context),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  moodOpt.label,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: moodColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (isNegative) ...[
                      Text(
                        'Điều gì đang tác động đến bạn?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: DailyCheckin.commonStressFactors.map((factor) {
                          final isSelected = selectedFactors.contains(factor);
                          return FilterChip(
                            label: Text(factor),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              setSheetState(() {
                                if (selected) {
                                  selectedFactors.add(factor);
                                } else {
                                  selectedFactors.remove(factor);
                                }
                              });
                            },
                            selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                            checkmarkColor: AppTheme.primaryLight,
                            backgroundColor: AppTheme.surfaceAltColor(context),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? AppTheme.primary : AppTheme.onSurfaceSecondary(context),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: isSelected ? AppTheme.primary : AppTheme.borderColor(context),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                    ],
                    Text(
                      'Ghi chú thêm (Tùy chọn)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      style: TextStyle(color: AppTheme.onSurface(context), fontSize: 14),
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'VD: Ca làm hôm nay hơi mệt, cần nghỉ ngơi sớm...',
                        hintStyle: TextStyle(color: AppTheme.onSurfaceMuted(context), fontSize: 13),
                        filled: true,
                        fillColor: AppTheme.surfaceAltColor(context),
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppTheme.borderColor(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppTheme.borderColor(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppTheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        if (isNegative) ...[
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              onStartBreathing();
                            },
                            icon: const Icon(Icons.air_rounded, size: 18, color: AppTheme.accentMint),
                            label: const Text(
                              'Thở sâu 3p',
                              style: TextStyle(color: AppTheme.accentMint, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.accentMint),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              onCheckinSubmitted(selectedMood, selectedFactors, noteController.text.trim());
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã lưu cảm xúc hôm nay! Hãy giữ tinh thần thật tốt nhé! ✨'),
                                  backgroundColor: AppTheme.accentMint,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Lưu Check-in', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
                      'Bạn đang cảm thấy như thế nào?',
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.accentMint.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.accentMint.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 13, color: AppTheme.accentMint),
                      SizedBox(width: 5),
                      Text(
                        'Đã check-in',
                        style: TextStyle(fontSize: 11, color: AppTheme.accentMint, fontWeight: FontWeight.w700),
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
                    onTap: () => _showCheckinDialog(context, opt.level),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? moodColor.withValues(alpha: 0.18)
                            : AppTheme.surfaceAltColor(context).withValues(alpha: 0.7),
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
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            opt.emoji,
                            style: TextStyle(
                              fontSize: isCurrent ? 26 : 22,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _getShortMoodLabel(opt.level),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                              color: isCurrent ? moodColor : AppTheme.onSurfaceSecondary(context),
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

  String _getShortMoodLabel(MoodLevel level) {
    switch (level) {
      case MoodLevel.great:
        return 'Tuyệt vời';
      case MoodLevel.good:
        return 'Khá ổn';
      case MoodLevel.neutral:
        return 'Hơi mệt';
      case MoodLevel.stressed:
        return 'Căng thẳng';
      case MoodLevel.overwhelmed:
        return 'Quá tải';
    }
  }
}
