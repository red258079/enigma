import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../core/api/life_log_repository.dart';

/// Dashboard Widget hiển thị tóm tắt sức khỏe tổng quan từ API
class DashboardSummaryCard extends StatefulWidget {
  const DashboardSummaryCard({super.key});

  @override
  State<DashboardSummaryCard> createState() => _DashboardSummaryCardState();
}

class _DashboardSummaryCardState extends State<DashboardSummaryCard> {
  Map<String, dynamic>? _dashData;
  bool _isLoading = true;
  String? _error;
  int? _lastRefreshCounter;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final data = await LifeLogRepository.getDashboardSummary();
      if (mounted) {
        setState(() {
          _dashData = data;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRefresh = context.watch<AppState>().refreshCounter;
    if (_lastRefreshCounter != currentRefresh) {
      _lastRefreshCounter = currentRefresh;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadDashboard();
      });
    }

    if (_isLoading && _dashData == null) {
      return _buildSkeleton();
    }
    if (_error != null || _dashData == null) {
      return _buildOfflineCard();
    }
    return _buildDashCard();
  }

  Widget _buildSkeleton() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
      color: AppTheme.surfaceAltColor(context).withValues(alpha: 0.5),
      duration: 1200.ms,
    );
  }

  Widget _buildOfflineCard() {
    final appState = context.read<AppState>();
    return _buildStreakBadgeCard(
      streak: appState.streakDays,
      wellbeing: null,
      sleepHours: null,
      stressLevel: null,
    );
  }

  Widget _buildDashCard() {
    final today = _dashData!['today'] is Map ? Map<String, dynamic>.from(_dashData!['today'] as Map) : <String, dynamic>{};
    final streak = _dashData!['streak'] is Map ? Map<String, dynamic>.from(_dashData!['streak'] as Map) : <String, dynamic>{};
    final analytics = _dashData!['weekly_analytics'] is Map ? Map<String, dynamic>.from(_dashData!['weekly_analytics'] as Map) : <String, dynamic>{};

    final wellbeingScore = (today['wellbeing_score'] as num?)?.toInt();
    final sleepHours = (today['sleep_hours'] as num?)?.toDouble();
    final stressLevel = (today['stress_level'] as num?)?.toInt();
    final stressDesc = today['stress_description'] is Map ? Map<String, dynamic>.from(today['stress_description'] as Map) : null;
    final currentStreak = (streak['current_streak'] as num?)?.toInt() ?? 0;
    final hasCheckedIn = today['has_checked_in'] as bool? ?? false;
    final riskLevel = analytics['overall_risk_level'] as String? ?? 'GREEN';

    return _buildStreakBadgeCard(
      streak: currentStreak,
      wellbeing: wellbeingScore,
      sleepHours: sleepHours,
      stressLevel: stressLevel,
      stressDesc: stressDesc,
      hasCheckedIn: hasCheckedIn,
      riskLevel: riskLevel,
    );
  }

  Widget _buildStreakBadgeCard({
    required int streak,
    required int? wellbeing,
    required double? sleepHours,
    required int? stressLevel,
    Map<String, dynamic>? stressDesc,
    bool hasCheckedIn = false,
    String riskLevel = 'GREEN',
  }) {
    Color riskColor = AppTheme.accentMint;
    String riskLabel = 'Ổn định';
    if (riskLevel == 'YELLOW') { riskColor = AppTheme.accentAmber; riskLabel = 'Cần chú ý'; }
    if (riskLevel == 'RED') { riskColor = AppTheme.accentCoral; riskLabel = 'Cần hỗ trợ'; }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF1E1B4B), Color(0xFF111726)]
              : [AppTheme.primary.withValues(alpha: 0.08), AppTheme.bgLightSurface],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? AppTheme.primary.withValues(alpha: 0.3)
              : AppTheme.primary.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: isDark ? 0.15 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Streak + Status + Risk Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department_rounded, color: AppTheme.accentAmber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '$streak ngày liên tiếp',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.accentAmber),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Risk Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: riskColor.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: riskColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      riskLabel,
                      style: TextStyle(fontSize: 11, color: riskColor, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Metrics Row
          if (wellbeing != null || sleepHours != null || stressLevel != null)
            Row(
              children: [
                if (wellbeing != null) ...[
                  Expanded(child: _buildMetricChip(
                    label: 'Sức khỏe',
                    value: '$wellbeing',
                    unit: '/100',
                    icon: Icons.favorite_rounded,
                    color: _wellbeingColor(wellbeing),
                  )),
                  const SizedBox(width: 8),
                ],
                if (sleepHours != null) ...[
                  Expanded(child: _buildMetricChip(
                    label: 'Giờ ngủ',
                    value: sleepHours.toStringAsFixed(1),
                    unit: 'h',
                    icon: Icons.bedtime_rounded,
                    color: _sleepColor(sleepHours),
                  )),
                  const SizedBox(width: 8),
                ],
                if (stressLevel != null)
                  Expanded(child: _buildMetricChip(
                    label: 'Áp lực',
                    value: '$stressLevel',
                    unit: '/5',
                    icon: Icons.psychology_rounded,
                    color: _stressColor(stressLevel),
                    emoji: stressDesc?['emoji'] as String?,
                  )),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.borderColor(context).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_calendar_rounded, size: 16, color: AppTheme.onSurfaceMuted(context)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chưa có dữ liệu sinh hoạt hôm nay. Hãy ghi nhận nhé!',
                      style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceSecondary(context)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    String? emoji,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.4)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.onSurfaceSecondary(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                emoji ?? value,
                style: TextStyle(
                  fontSize: emoji != null ? 18 : 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1.0,
                ),
              ),
              if (emoji == null) ...[
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.onSurfaceMuted(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _wellbeingColor(int score) {
    if (score >= 80) return AppTheme.accentMint;
    if (score >= 60) return AppTheme.accentAmber;
    if (score >= 40) return AppTheme.accentCoral;
    return const Color(0xFFEF4444);
  }

  Color _sleepColor(double hours) {
    if (hours >= 8) return AppTheme.accentMint;
    if (hours >= 7) return const Color(0xFF34D399);
    if (hours >= 6) return AppTheme.accentAmber;
    return AppTheme.accentCoral;
  }

  Color _stressColor(int level) {
    if (level <= 2) return AppTheme.accentMint;
    if (level == 3) return AppTheme.accentAmber;
    return AppTheme.accentCoral;
  }
}

/// Weekly Analytics Trend Chart Widget
class WeeklyTrendChart extends StatefulWidget {
  const WeeklyTrendChart({super.key});

  @override
  State<WeeklyTrendChart> createState() => _WeeklyTrendChartState();
}

class _WeeklyTrendChartState extends State<WeeklyTrendChart> {
  List<Map<String, dynamic>> _dailyScores = [];
  bool _isLoading = true;
  int? _lastRefreshCounter;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final data = await LifeLogRepository.getAnalytics(days: 7);
      final rawList = data['daily_scores'] as List? ?? [];
      final scores = rawList
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (mounted) setState(() { _dailyScores = scores; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRefresh = context.watch<AppState>().refreshCounter;
    if (_lastRefreshCounter != currentRefresh) {
      _lastRefreshCounter = currentRefresh;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadAnalytics();
      });
    }

    if (_isLoading || _dailyScores.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecorationFor(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: AppTheme.primaryLight, size: 18),
              const SizedBox(width: 8),
              Text(
                'Xu hướng 7 ngày qua',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface(context),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _dailyScores.take(7).map((entry) {
                final score = (entry['score'] as num?)?.toInt() ?? 50;
                final dateStr = entry['date'] as String? ?? '';
                final dayLabel = dateStr.isNotEmpty ? dateStr.split('-').last : '?';
                final barHeight = (score / 100 * 56).clamp(10.0, 56.0);
                final barColor = score >= 70 ? AppTheme.accentMint : score >= 50 ? AppTheme.accentAmber : AppTheme.accentCoral;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [barColor, barColor.withValues(alpha: 0.6)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dayLabel,
                          style: TextStyle(fontSize: 10, color: AppTheme.onSurfaceMuted(context), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
