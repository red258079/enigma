import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../state/notification_state.dart';
import '../../models/notification_item.dart';
import '../../theme/app_theme.dart';
import '../../navigation/student_nav.dart';
import 'journal_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _filterUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationState>().fetchNotifications();
    });
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return ' phút trước';
    if (diff.inHours < 24) return ' giờ trước';
    if (diff.inDays == 1) return 'Hôm qua lúc ';
    if (diff.inDays < 7) return ' ngày trước';
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  void _handleNotificationTap(NotificationItem item) {
    context.read<NotificationState>().markAsRead(item.id);

    switch (item.type) {
      case 'reminder_checkin':
        Navigator.pop(context);
        StudentNav.switchToTab(context, 2); // Check-in tab
        break;
      case 'task_unlock':
        Navigator.pop(context);
        StudentNav.switchToTab(context, 1); // Tasks tab
        break;
      case 'new_article':
        Navigator.pop(context);
        StudentNav.switchToTab(context, 3); // Handbook tab
        break;
      case 'reminder_journal':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const JournalScreen()),
        );
        break;
      default:
        // System or general
        break;
    }
  }

  (IconData, Color, String) _getTypeMeta(String type) {
    switch (type) {
      case 'reminder_checkin':
        return (Icons.wb_sunny_rounded, AppTheme.accentAmber, 'Check-in');
      case 'task_unlock':
        return (Icons.fact_check_rounded, AppTheme.accentMint, 'Nhiệm vụ');
      case 'new_article':
        return (Icons.menu_book_rounded, AppTheme.primaryLight, 'Cẩm nang');
      case 'reminder_journal':
        return (Icons.auto_stories_rounded, AppTheme.accentPurple, 'Nhật ký');
      case 'streak_warning':
        return (Icons.local_fire_department_rounded, AppTheme.accentCoral, 'Chuỗi ngày');
      default:
        return (Icons.notifications_rounded, const Color(0xFF38BDF8), 'Thông báo');
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifState = context.watch<NotificationState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = _filterUnreadOnly
        ? notifState.notifications.where((n) => !n.isRead).toList()
        : notifState.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trung tâm thông báo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (notifState.unreadCount > 0)
            TextButton.icon(
              onPressed: () => context.read<NotificationState>().markAllAsRead(),
              icon: const Icon(Icons.done_all_rounded, size: 16, color: AppTheme.primaryLight),
              label: const Text(
                'Đã đọc tất cả',
                style: TextStyle(color: AppTheme.primaryLight, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter Chips ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Tất cả ()',
                  selected: !_filterUnreadOnly,
                  onTap: () => setState(() => _filterUnreadOnly = false),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Chưa đọc ()',
                  selected: _filterUnreadOnly,
                  onTap: () => setState(() => _filterUnreadOnly = true),
                ),
              ],
            ),
          ),

          // ── Notification List ──────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context.read<NotificationState>().fetchNotifications(),
              color: AppTheme.primary,
              child: notifState.isLoading && notifState.notifications.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                      ? _buildEmptyState(isDark)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, index) {
                            final item = items[index];
                            return _buildNotificationCard(ctx, item, isDark);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withOpacity(0.18)
              : (Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.bgSurface
                  : AppTheme.bgLightSurfaceAlt),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primaryLight : AppTheme.borderColor(context),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.primaryLight : AppTheme.onSurfaceSecondary(context),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationItem item, bool isDark) {
    final (icon, iconColor, typeLabel) = _getTypeMeta(item.type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleNotificationTap(item),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: item.isRead
                ? (isDark ? AppTheme.bgSurface.withOpacity(0.6) : AppTheme.bgLightSurfaceAlt.withOpacity(0.7))
                : (isDark ? AppTheme.bgSurfaceLight : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isRead
                  ? AppTheme.borderColor(context).withOpacity(0.4)
                  : iconColor.withOpacity(0.4),
              width: item.isRead ? 1 : 1.5,
            ),
            boxShadow: item.isRead
                ? []
                : [
                    BoxShadow(
                      color: iconColor.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Type
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: iconColor.withOpacity(0.35)),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Type Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            typeLabel,
                            style: TextStyle(
                              color: iconColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        // Time
                        Text(
                          _formatTime(item.createdAt),
                          style: TextStyle(
                            color: AppTheme.onSurfaceMuted(context),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      style: TextStyle(
                        color: AppTheme.onSurface(context),
                        fontSize: 14.5,
                        fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: TextStyle(
                        color: AppTheme.onSurfaceSecondary(context),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              // Unread Dot
              if (!item.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryLight,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded, size: 40, color: AppTheme.primaryLight),
          ),
          const SizedBox(height: 18),
          Text(
            _filterUnreadOnly ? 'Không có thông báo chưa đọc' : 'Chưa có thông báo nào',
            style: TextStyle(
              color: AppTheme.onSurface(context),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Các lời nhắc check-in, nhiệm vụ và bài viết mới\nsẽ hiển thị tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.onSurfaceMuted(context),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
