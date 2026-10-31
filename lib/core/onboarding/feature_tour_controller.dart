import 'package:flutter/material.dart';
import 'models/onboarding_step.dart';
import 'services/feature_onboarding_service.dart';
import 'widgets/coach_mark_overlay.dart';

class FeatureTour {
  static OverlayEntry? _currentEntry;

  /// Bắt đầu hiển thị hướng dẫn cho một chức năng.
  /// [force] = true: Luôn hiển thị lại (dùng khi người dùng bấm "Xem hướng dẫn").
  static void start(
    BuildContext context, {
    required String featureKey,
    required List<OnboardingStep> steps,
    bool force = false,
  }) {
    if (steps.isEmpty) return;

    final service = FeatureOnboardingService.instance;
    // Nếu đã hoàn thành và không phải yêu cầu xem lại chủ động -> không hiển thị
    if (!force && service.hasCompleted(featureKey)) {
      return;
    }

    // Đóng hướng dẫn cũ nếu đang mở
    dismiss();

    final overlay = Overlay.of(context);

    // Chờ frame giao diện dựng hoàn tất để đo chính xác toạ độ các nút
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      _currentEntry = OverlayEntry(
        builder: (ctx) => CoachMarkOverlay(
          steps: steps,
          onFinish: () {
            dismiss();
            service.markCompleted(featureKey);
          },
          onSkip: () {
            dismiss();
            service.markCompleted(featureKey);
          },
        ),
      );

      overlay.insert(_currentEntry!);
    });
  }

  /// Đóng lớp hướng dẫn đang hiển thị
  static void dismiss() {
    try {
      _currentEntry?.remove();
    } catch (_) {}
    _currentEntry = null;
  }

  /// Kiểm tra xem hướng dẫn có đang hiển thị không
  static bool get isShowing => _currentEntry != null;
}
