import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/sync_service.dart';
import '../state/auth_state.dart';

/// Thanh thông báo trạng thái kết nối & tiến trình sao lưu ngoại tuyến
class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final syncService = context.watch<SyncService>();
    final authState = context.watch<AuthState>();

    final isOffline = !syncService.isOnline || authState.isOfflineMode;
    final isSyncing = syncService.isSyncing;
    final pendingCount = syncService.pendingCount;

    // Không hiển thị nếu đang online, không có tác vụ nào chờ và trạng thái là idle
    if (!isOffline && !isSyncing && pendingCount == 0 && syncService.syncStatus != SyncStatus.completed) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    Color textColor;
    IconData icon;
    String text;
    Widget? trailing;

    if (isSyncing) {
      bgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE0F2FE);
      textColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1);
      icon = Icons.sync_rounded;
      text = 'Đang tự động sao lưu dữ liệu lên máy chủ...';
      trailing = const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (syncService.syncStatus == SyncStatus.completed) {
      bgColor = isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5);
      textColor = isDark ? const Color(0xFF34D399) : const Color(0xFF047857);
      icon = Icons.check_circle_rounded;
      text = syncService.lastSyncMessage ?? 'Đã sao lưu toàn bộ dữ liệu lên máy chủ!';
    } else if (isOffline) {
      bgColor = isDark ? const Color(0xFF27272A) : const Color(0xFFFEF3C7);
      textColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E);
      icon = Icons.wifi_off_rounded;
      text = pendingCount > 0
          ? 'Chế độ ngoại tuyến • $pendingCount mục chờ sao lưu'
          : 'Chế độ ngoại tuyến (Dữ liệu lưu an toàn trên máy)';
    } else {
      // Có mạng nhưng còn mục chờ sao lưu
      bgColor = isDark ? const Color(0xFF14532D).withValues(alpha: 0.4) : const Color(0xFFDCFCE7);
      textColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534);
      icon = Icons.cloud_upload_outlined;
      text = 'Có $pendingCount mục chờ đưa lên máy chủ';
      trailing = InkWell(
        onTap: () => syncService.syncNow(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: textColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sync_rounded, size: 14, color: textColor),
              const SizedBox(width: 4),
              Text(
                'Đồng bộ ngay',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: textColor.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );
  }
}
