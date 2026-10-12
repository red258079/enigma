import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/wellbeing_score_card.dart';
import '../widgets/mood_checkin_card.dart';
import '../widgets/task_tile.dart';
import '../widgets/dashboard_summary_card.dart';
import '../widgets/app_avatar.dart';
import 'assessment_screen.dart';
import 'breathing_screen.dart';
import 'career_reflection_screen.dart';
import 'student/journal_screen.dart';
import 'student/life_log_screen.dart';
import 'student/profile_screen.dart';
import '../state/auth_state.dart';
import '../state/notification_state.dart';
import 'package:provider/provider.dart';
import '../navigation/student_nav.dart';
import 'settings_screen.dart';
import 'student/notifications_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openAssessment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => AssessmentScreen(
          onComplete: (newScore) {
            context.read<AppState>().saveAssessment(newScore);
          },
        ),
      ),
    );
  }

  void _openBreathing(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const BreathingScreen()),
    );
  }

  void _openCheckin(BuildContext context) {
    StudentNav.switchToTab(context, 2);
  }

  void _openLifeLog(BuildContext context) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const LifeLogScreen()),
    );
    if (res == true && context.mounted) {
      context.read<AppState>().triggerRefresh();
    }
  }

  void _openCareerReflection(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const CareerReflectionScreen()),
    );
  }

  void _openJournal(BuildContext context) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const JournalScreen()),
    );
    if (res == true && context.mounted) {
      context.read<AppState>().triggerRefresh();
    }
  }

  void _showSafetyDisclaimer(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.cardBorder),
        ),
        title: const Row(
          children: [
            Icon(Icons.health_and_safety_rounded, color: AppTheme.accentCoral),
            SizedBox(width: 10),
            Text('Thông điệp An toàn', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enigma là hệ thống hỗ trợ xây dựng thói quen phục hồi và tái thích nghi sau kỳ thực tập, KHÔNG PHẢI là công cụ chẩn đoán y khoa.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
            ),
            SizedBox(height: 12),
            Text(
              'Nếu bạn đang trải qua cảm giác trầm cảm nặng, kiệt sức kéo dài hoặc có ý nghĩ tiêu cực làm hại bản thân, xin hãy liên hệ ngay với người thân hoặc các kênh hỗ trợ:',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
            ),
            SizedBox(height: 8),
            Text('• Phòng Y tế / Phòng Tham vấn Tâm lý trường', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryLight, fontSize: 13)),
            Text('• Tổng đài Quốc gia bảo vệ sức khỏe: 111', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.accentMint, fontSize: 13)),
            Text('• Đường dây nóng Cấp cứu Y tế: 115', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.accentCoral, fontSize: 13)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tôi đã hiểu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final authState = context.watch<AuthState>();
    final todayTasks = appState.todayTasks;
    final userName = authState.user?.name ?? 'Bạn';
    final avatarUrl = authState.user?.avatarUrl;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<AppState>().triggerRefresh();
            context.read<NotificationState>().fetchUnreadCount();
            await Future.delayed(const Duration(milliseconds: 600));
          },
          color: AppTheme.primary,
          backgroundColor: AppTheme.surfaceColor(context),
          child: CustomScrollView(
            slivers: [
            // Top App Bar with greetings and actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Avatar (Tap to open Profile) ───────────────────────
                    AppAvatar(
                      avatarUrl: avatarUrl,
                      initial: userName,
                      size: 44,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: 12),

                    // ── Greeting (Tap to open Profile) ─────────────────────
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProfileScreen()),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xin chào, $userName 👋',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.accentMint,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Thực tập sinh • LG Display',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.onSurfaceSecondary(context),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Right actions ────────────────────────────────────────
                    const SizedBox(width: 6),
                    // Notification Bell with Badge
                    Consumer<NotificationState>(
                      builder: (ctx, notifState, _) {
                        final unread = notifState.unreadCount;
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                            );
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor(context),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.borderColor(context)),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  unread > 0 ? Icons.notifications_active_rounded : Icons.notifications_outlined,
                                  color: unread > 0 ? AppTheme.primaryLight : AppTheme.onSurfaceSecondary(context),
                                  size: 19,
                                ),
                                if (unread > 0)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(2.5),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.accentCoral,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 14,
                                        minHeight: 14,
                                      ),
                                      child: Center(
                                        child: Text(
                                          unread > 9 ? '9+' : '$unread',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w900,
                                            height: 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    // Streak badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.accentAmber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department_rounded, color: AppTheme.accentAmber, size: 16),
                          const SizedBox(width: 3),
                          Text(
                            '${appState.streakDays}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.accentAmber,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 3-dot menu
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded, color: AppTheme.onSurfaceMuted(context), size: 22),
                      color: AppTheme.surfaceColor(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: AppTheme.borderColor(context)),
                      ),
                      elevation: 8,
                      offset: const Offset(0, 48),
                      onSelected: (value) {
                        if (value == 'profile') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProfileScreen()),
                          );
                        } else if (value == 'settings') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        } else if (value == 'safety') {
                          _showSafetyDisclaimer(context);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'profile',
                          child: Row(
                            children: [
                              Icon(Icons.person_rounded, color: AppTheme.primary, size: 18),
                              const SizedBox(width: 10),
                              const Text('Thông tin tài khoản', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'settings',
                          child: Row(
                            children: [
                              Icon(Icons.settings_rounded, color: AppTheme.secondary, size: 18),
                              const SizedBox(width: 10),
                              const Text('Cài đặt', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'safety',
                          child: Row(
                            children: [
                              const Icon(Icons.shield_outlined, color: AppTheme.accentCoral, size: 18),
                              const SizedBox(width: 10),
                              const Text('Thông điệp an toàn', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),


              // Main Content
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 4),

                    // 1. Live Dashboard Summary Card (Real API data)
                    GestureDetector(
                      onTap: () => _openLifeLog(context),
                      child: const RepaintBoundary(
                        child: DashboardSummaryCard(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 2. Daily Mood Check-in
                    MoodCheckinCard(
                      todayCheckin: appState.todayCheckin,
                      onCheckinSubmitted: (mood, factors, note) {
                        appState.recordCheckin(mood, factors, note);
                      },
                      onStartBreathing: () => _openBreathing(context),
                    ),

                    const SizedBox(height: 16),

                    // 3. Well-being Score Card (Assessment-based)
                    WellbeingScoreCard(
                      score: appState.score,
                      onRetakeAssessment: () => _openAssessment(context),
                    ),

                    const SizedBox(height: 16),

                    // 4. Weekly Trend Mini Chart
                    const RepaintBoundary(
                      child: WeeklyTrendChart(),
                    ),

                    const SizedBox(height: 22),

                    // 5. Quick Action Bento Grid
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tiện ích nhanh',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface(context),
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          '4 tính năng',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.onSurfaceMuted(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildActionTile(
                            context,
                            icon: Icons.edit_note_rounded,
                            title: 'Viết nhật ký',
                            subtitle: 'Ghi nhận tâm trạng',
                            color: AppTheme.accentPurple,
                            onTap: () => _openJournal(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionTile(
                            context,
                            icon: Icons.auto_awesome_rounded,
                            title: 'Điểm danh',
                            subtitle: 'Vòng quay may mắn',
                            color: AppTheme.accentAmber,
                            onTap: () => _openCheckin(context),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildActionTile(
                            context,
                            icon: Icons.explore_rounded,
                            title: 'What Next?',
                            subtitle: 'Định hướng sau kỳ',
                            color: AppTheme.careerColor,
                            onTap: () => _openCareerReflection(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionTile(
                            context,
                            icon: Icons.air_rounded,
                            title: 'Hít thở sâu',
                            subtitle: 'Box Breathing 4-4',
                            color: AppTheme.secondary,
                            onTap: () => _openBreathing(context),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 6. Today's Recovery Routines Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Nhiệm vụ hôm nay',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface(context),
                            letterSpacing: -0.2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceAltColor(context),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${todayTasks.where((t) => t.isCompleted).length}/${todayTasks.length} hoàn thành',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurfaceSecondary(context),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Today Tasks List
                    ...todayTasks.take(4).map(
                      (task) => TaskTile(
                        task: task,
                        onToggle: () => appState.toggleTaskCompletion(task.id),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Bottom Disclaimer Banner
                    InkWell(
                      onTap: () => _showSafetyDisclaimer(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor(context).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderColor(context)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.health_and_safety_outlined, size: 20, color: AppTheme.onSurfaceMuted(context)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Enigma hỗ trợ phục hồi sức khỏe sinh viên • Không phải chẩn đoán y khoa',
                                style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceMuted(context), height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.cardDecorationFor(context, borderRadius: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.25),
                    color.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.onSurfaceSecondary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
