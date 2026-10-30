import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/theme_state.dart';
import '../state/auth_state.dart';
import '../theme/app_theme.dart';
import '../core/services/biometric_service.dart';
import '../core/services/push_notification_service.dart';
import '../core/services/reminder_service.dart';
import '../core/utils/storage.dart';
import 'student/profile_screen.dart';
import 'auth/login_screen.dart';
import '../widgets/app_avatar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final user = authState.user;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // ── Account Banner Card ─────────────────────────────────────────────
          if (user != null) ...[
            _SectionHeader(title: 'Tài khoản', icon: Icons.person_rounded, color: AppTheme.primaryLight),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.15),
                      AppTheme.accentPurple.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    AppAvatar(
                      avatarUrl: user.avatarUrl,
                      initial: user.name,
                      size: 52,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (user.studentId != null && user.studentId!.isNotEmpty)
                                ? '${user.studentId} • ${user.email}'
                                : user.email,
                            style: textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceSecondary(context)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Thực tập sinh • LG Display',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppTheme.primaryLight, size: 24),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ── Header ──────────────────────────────────────────────────────────
          _SectionHeader(title: 'Giao diện', icon: Icons.palette_rounded, color: AppTheme.accentPurple),
          const SizedBox(height: 12),

          // Theme Mode Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecorationFor(context, borderRadius: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.dark_mode_rounded, color: AppTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('Chế độ hiển thị', style: textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 20),
                Selector<ThemeState, ThemeMode>(
                  selector: (_, s) => s.themeMode,
                  builder: (ctx, currentThemeMode, _) => Column(
                    children: [
                      _ThemeOptionButton(
                        label: 'Tối (Dark)',
                        icon: Icons.nightlight_round,
                        value: ThemeMode.dark,
                        selected: currentThemeMode,
                        onTap: () => ctx.read<ThemeState>().setThemeMode(ThemeMode.dark),
                        accentColor: AppTheme.accentPurple,
                      ),
                      const SizedBox(height: 10),
                      _ThemeOptionButton(
                        label: 'Sáng (Light)',
                        icon: Icons.wb_sunny_rounded,
                        value: ThemeMode.light,
                        selected: currentThemeMode,
                        onTap: () => ctx.read<ThemeState>().setThemeMode(ThemeMode.light),
                        accentColor: AppTheme.accentAmber,
                      ),
                      const SizedBox(height: 10),
                      _ThemeOptionButton(
                        label: 'Theo hệ thống',
                        icon: Icons.auto_awesome_rounded,
                        value: ThemeMode.system,
                        selected: currentThemeMode,
                        onTap: () => ctx.read<ThemeState>().setThemeMode(ThemeMode.system),
                        accentColor: AppTheme.accentMint,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Security & Biometric ─────────────────────────────────────────────
          _SectionHeader(title: 'Bảo mật & Đăng nhập', icon: Icons.security_rounded, color: AppTheme.accentMint),
          const SizedBox(height: 12),
          _BiometricSettingTile(),

          const SizedBox(height: 28),

          // ── Notifications ────────────────────────────────────────────────────
          _SectionHeader(title: 'Thông báo', icon: Icons.notifications_rounded, color: AppTheme.accentCoral),
          const SizedBox(height: 12),
          const _SleepReminderSettingTile(),
          const SizedBox(height: 10),
          _SettingsTile(
            context: context,
            icon: Icons.notifications_active_rounded,
            iconColor: AppTheme.accentCoral,
            title: 'Nhắc nhở nhiệm vụ hàng ngày',
            subtitle: 'Nhận thông báo nhắc nhở hoàn thành nhiệm vụ',
            trailing: Switch(
              value: true,
              activeColor: AppTheme.primary,
              onChanged: (_) {},
            ),
          ),
          const SizedBox(height: 10),
          _SettingsTile(
            context: context,
            icon: Icons.self_improvement_rounded,
            iconColor: AppTheme.secondary,
            title: 'Nhắc check-in tâm trạng',
            subtitle: 'Mỗi ngày lúc 8:00 sáng',
            trailing: Switch(
              value: true,
              activeColor: AppTheme.primary,
              onChanged: (_) {},
            ),
          ),
          const SizedBox(height: 10),
          _SettingsTile(
            context: context,
            icon: Icons.send_to_mobile_rounded,
            iconColor: AppTheme.accentMint,
            title: 'Thử nghiệm thông báo',
            subtitle: 'Bấm để nhận ngay 1 thông báo thử nghiệm',
            trailing: OutlinedButton(
              onPressed: () async {
                await PushNotificationService.showNotification(
                  title: '✨ Enigma: Nhắc nhở check-in',
                  body: 'Đã đến giờ điểm danh tâm trạng hôm nay! Dành 1 phút chăm sóc bản thân nhé.',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Đã gửi thông báo thử nghiệm lên thanh trạng thái!'),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                side: const BorderSide(color: AppTheme.accentMint),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Gửi thử', style: TextStyle(color: AppTheme.accentMint, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ),

          const SizedBox(height: 28),

          // ── About ────────────────────────────────────────────────────────────
          _SectionHeader(title: 'Thông tin ứng dụng', icon: Icons.info_rounded, color: AppTheme.secondary),
          const SizedBox(height: 12),
          _SettingsTile(
            context: context,
            icon: Icons.star_rounded,
            iconColor: AppTheme.accentAmber,
            title: 'Phiên bản',
            subtitle: '1.0.0 (Build 1)',
          ),
          const SizedBox(height: 10),
          _SettingsTile(
            context: context,
            icon: Icons.shield_rounded,
            iconColor: AppTheme.accentMint,
            title: 'Chính sách quyền riêng tư',
            subtitle: 'Xem điều khoản bảo mật dữ liệu',
            trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.onSurfaceMuted(context)),
          ),
          const SizedBox(height: 10),
          _SettingsTile(
            context: context,
            icon: Icons.help_rounded,
            iconColor: AppTheme.accentPurple,
            title: 'Trung tâm trợ giúp',
            subtitle: 'Câu hỏi thường gặp và hỗ trợ',
            trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.onSurfaceMuted(context)),
          ),

          const SizedBox(height: 28),

          // Logout Action
          OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  backgroundColor: AppTheme.surfaceColor(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: AppTheme.borderColor(context)),
                  ),
                  title: Row(
                    children: const [
                      Icon(Icons.logout_rounded, color: AppTheme.accentCoral, size: 22),
                      SizedBox(width: 10),
                      Text('Đăng xuất tài khoản', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                    ],
                  ),
                  content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text('Hủy'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(dialogCtx);
                        await context.read<AuthState>().logout();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentCoral,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Đăng xuất'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.logout_rounded, color: AppTheme.accentCoral, size: 18),
            label: const Text('Đăng xuất tài khoản', style: TextStyle(color: AppTheme.accentCoral, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.accentCoral.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: AppTheme.accentCoral.withValues(alpha: 0.05),
            ),
          ),

          const SizedBox(height: 36),

          // Credit footer
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accentPurple],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Enigma',
                    style: textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hỗ trợ tâm lý sinh viên thực tập',
                  style: textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceMuted(context)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
        ),
      ],
    );
  }
}

// ── Generic Settings Tile ───────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final BuildContext context;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.context,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext ctx) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: AppTheme.cardDecorationFor(context, borderRadius: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.onSurfaceMuted(context),
                          )),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

// ── Theme Option Button ─────────────────────────────────────────────────────
class _ThemeOptionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final ThemeMode value;
  final ThemeMode selected;
  final VoidCallback onTap;
  final Color accentColor;

  const _ThemeOptionButton({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? accentColor.withValues(alpha: 0.12)
            : (isDark ? AppTheme.bgSurfaceLight : AppTheme.bgLightSurfaceAlt),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? accentColor.withValues(alpha: 0.6) : AppTheme.borderColor(context),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon,
                  color: isSelected ? accentColor : AppTheme.onSurfaceMuted(context), size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isSelected ? accentColor : AppTheme.onSurface(context),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
              const Spacer(),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? accentColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? accentColor : AppTheme.borderColor(context),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 12)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Biometric Setting Tile ──────────────────────────────────────────────────
class _BiometricSettingTile extends StatefulWidget {
  const _BiometricSettingTile();

  @override
  State<_BiometricSettingTile> createState() => _BiometricSettingTileState();
}

class _BiometricSettingTileState extends State<_BiometricSettingTile> {
  bool _isEnabled = false;
  bool _isAvailable = false;
  String _biometricName = 'Vân tay / Face ID';

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final available = await BiometricService.isBiometricAvailable();
    final name = await BiometricService.getBiometricDisplayName();
    final enabled = StorageUtil.isBiometricEnabled;
    if (mounted) {
      setState(() {
        _isAvailable = available;
        _biometricName = name;
        _isEnabled = enabled;
      });
    }
  }

  Future<void> _onToggle(bool value) async {
    if (value) {
      // Yêu cầu quét sinh trắc học để xác nhận bật
      final success = await BiometricService.authenticate(
        reason: 'Xác thực $_biometricName để kích hoạt tính năng đăng nhập nhanh',
      );
      if (success) {
        await BiometricService.setBiometricEnabled(true);
        if (mounted) {
          setState(() => _isEnabled = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã bật đăng nhập bằng $_biometricName'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Xác thực không thành công. Chưa bật sinh trắc học.'),
              backgroundColor: AppTheme.accentCoral,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } else {
      await BiometricService.setBiometricEnabled(false);
      await StorageUtil.clearBiometricCredentials();
      if (mounted) {
        setState(() => _isEnabled = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tắt đăng nhập bằng $_biometricName'),
            backgroundColor: AppTheme.textSecondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _showSetupGuide() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.borderColor(context)),
        ),
        title: Row(
          children: const [
            Icon(Icons.fingerprint_rounded, color: AppTheme.accentMint, size: 24),
            SizedBox(width: 10),
            Text(
              'Cài đặt Sinh trắc học',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thiết bị chưa nhận diện được dấu vân tay hoặc Face ID. Có 2 nguyên nhân phổ biến:',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryLight.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '1. Cần Rebuild lại App (Quan trọng):',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.primaryLight),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Do thư viện local_auth là plugin Native Android, bạn cần Dừng app và chạy lại (flutter run) để máy nạp mã nguồn Native.',
                    style: TextStyle(fontSize: 12, height: 1.35),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '2. Chưa cài vân tay trên máy ảo:',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.accentAmber),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Mở Cài đặt máy (Settings) > Security > Fingerprint để thêm 1 vân tay mẫu.',
                    style: TextStyle(fontSize: 12, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await StorageUtil.setBiometricEnabled(true);
              setState(() {
                _isEnabled = true;
                _isAvailable = true;
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã bật chế độ Sinh trắc học cho máy ảo!'),
                    backgroundColor: Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentMint,
              foregroundColor: Colors.black,
            ),
            child: const Text('Kích hoạt thử nghiệm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      context: context,
      icon: Icons.fingerprint_rounded,
      iconColor: AppTheme.accentMint,
      title: 'Đăng nhập bằng $_biometricName',
      subtitle: _isEnabled
          ? 'Đang kích hoạt - Chạm để đăng nhập nhanh'
          : (_isAvailable
              ? 'Mở để đăng nhập không cần gõ mật khẩu'
              : 'Chạm vào đây để xem hướng dẫn & kích hoạt'),
      trailing: Switch(
        value: _isEnabled,
        activeColor: AppTheme.accentMint,
        onChanged: _isAvailable
            ? _onToggle
            : (_) => _showSetupGuide(),
      ),
      onTap: _isAvailable ? () => _onToggle(!_isEnabled) : _showSetupGuide,
    );
  }
}

class _SleepReminderSettingTile extends StatefulWidget {
  const _SleepReminderSettingTile();

  @override
  State<_SleepReminderSettingTile> createState() => _SleepReminderSettingTileState();
}

class _SleepReminderSettingTileState extends State<_SleepReminderSettingTile> {
  late bool _enabled;
  late int _hour;
  late int _minute;
  late bool _noonEnabled;

  @override
  void initState() {
    super.initState();
    _enabled = StorageUtil.isSleepReminderEnabled;
    _hour = StorageUtil.sleepReminderHour;
    _minute = StorageUtil.sleepReminderMinute;
    _noonEnabled = StorageUtil.isNoonReminderEnabled;
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
      helpText: 'Chọn giờ nhắc nhở giấc ngủ',
      confirmText: 'Lưu',
      cancelText: 'Hủy',
    );
    if (picked != null) {
      await StorageUtil.setSleepReminderTime(picked.hour, picked.minute);
      setState(() {
        _hour = picked.hour;
        _minute = picked.minute;
      });
      await ReminderService.rescheduleAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecorationFor(context, borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.sleepColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bedtime_outlined, color: AppTheme.sleepColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nhắc nhở ghi nhận giấc ngủ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      _enabled ? 'Mỗi ngày lúc $timeStr (chỉ mất 1 chạm)' : 'Đang tắt nhắc nhở',
                      style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceMuted(context)),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _enabled,
                activeColor: AppTheme.sleepColor,
                onChanged: (val) async {
                  if (val) {
                    final messenger = ScaffoldMessenger.of(context);
                    final granted = await ReminderService.requestPermission(context: context);
                    if (!granted) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng cấp quyền thông báo trong cài đặt máy để nhận nhắc nhở.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      await StorageUtil.setSleepReminderEnabled(false);
                      await ReminderService.cancelAll();
                      if (mounted) setState(() => _enabled = false);
                      return;
                    }
                    await StorageUtil.setSleepReminderEnabled(true);
                    await ReminderService.rescheduleAll();
                    if (mounted) setState(() => _enabled = true);
                  } else {
                    await StorageUtil.setSleepReminderEnabled(false);
                    await ReminderService.cancelAll();
                    if (mounted) setState(() => _enabled = false);
                  }
                },
              ),
            ],
          ),
          if (_enabled) ...[
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Giờ nhắc sáng:', style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceSecondary(context))),
                InkWell(
                  onTap: _pickTime,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.sleepColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.sleepColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.sleepColor),
                        const SizedBox(width: 6),
                        Text(timeStr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.sleepColor)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nhắc thêm lúc 12:00', style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceSecondary(context))),
                      Text('Chỉ gửi nếu sáng nay chưa ghi nhận', style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceMuted(context))),
                    ],
                  ),
                ),
                Switch(
                  value: _noonEnabled,
                  activeColor: AppTheme.sleepColor,
                  onChanged: (val) async {
                    await StorageUtil.setNoonReminderEnabled(val);
                    setState(() => _noonEnabled = val);
                    await ReminderService.rescheduleAll();
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}


