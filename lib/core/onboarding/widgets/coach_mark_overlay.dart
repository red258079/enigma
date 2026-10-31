import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/onboarding_step.dart';
import '../../../theme/app_theme.dart';

class CoachMarkOverlay extends StatefulWidget {
  final List<OnboardingStep> steps;
  final VoidCallback onFinish;
  final VoidCallback onSkip;

  const CoachMarkOverlay({
    super.key,
    required this.steps,
    required this.onFinish,
    required this.onSkip,
  });

  @override
  State<CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<CoachMarkOverlay> with SingleTickerProviderStateMixin {
  int _currentStepIndex = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStepIndex < widget.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
    } else {
      widget.onFinish();
    }
  }

  void _prev() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
      });
    }
  }

  Rect? _getTargetRect(GlobalKey key) {
    try {
      final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) return null;
      final offset = renderBox.localToGlobal(Offset.zero);
      return offset & renderBox.size;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStepIndex];
    final targetRect = _getTargetRect(step.targetKey);
    final screenSize = MediaQuery.of(context).size;
    final totalSteps = widget.steps.length;
    final isLast = _currentStepIndex == totalSteps - 1;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 1. Dark Backdrop with Cutout Spotlight
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, _) {
              return CustomPaint(
                size: screenSize,
                painter: _SpotlightPainter(
                  targetRect: targetRect,
                  pulseScale: _pulseAnimation.value,
                  shape: step.shape,
                ),
              );
            },
          ),

          // 2. Click outside overlay to dismiss / go next
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _next,
              child: const SizedBox.expand(),
            ),
          ),

          // 3. Floating Tooltip Card
          _buildTooltipCard(
            context,
            step: step,
            targetRect: targetRect,
            screenSize: screenSize,
            currentIndex: _currentStepIndex,
            totalSteps: totalSteps,
            isLast: isLast,
          ),
        ],
      ),
    );
  }

  Widget _buildTooltipCard(
    BuildContext context, {
    required OnboardingStep step,
    required Rect? targetRect,
    required Size screenSize,
    required int currentIndex,
    required int totalSteps,
    required bool isLast,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardWidth = math.min(screenSize.width - 36, 360.0);

    // Tính toán toạ độ vị trí đặt Tooltip (ở trên hay ở dưới target)
    double top = screenSize.height / 2 - 100;
    bool placeAbove = false;

    if (targetRect != null) {
      final targetCenterY = targetRect.center.dy;
      if (step.preferredPosition == TooltipPosition.top) {
        placeAbove = true;
      } else if (step.preferredPosition == TooltipPosition.bottom) {
        placeAbove = false;
      } else {
        placeAbove = targetCenterY > (screenSize.height * 0.48);
      }

      if (placeAbove) {
        top = targetRect.top - 200;
        if (top < 50) top = 50;
      } else {
        top = targetRect.bottom + 18;
        if (top + 190 > screenSize.height - 30) {
          top = screenSize.height - 220;
        }
      }
    }

    final double left = (screenSize.width - cardWidth) / 2;

    return Positioned(
      top: top,
      left: left,
      width: cardWidth,
      child: GestureDetector(
        onTap: () {}, // Tránh click xuyên thấu
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E232E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 26,
                offset: const Offset(0, 10),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: AppTheme.primaryLight.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isDark ? const Color(0xFF333B4F) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Badge step + Close icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryLight],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      totalSteps > 1 ? 'Bước ${currentIndex + 1}/$totalSteps' : 'Mẹo nhanh',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: widget.onSkip,
                    tooltip: 'Đóng hướng dẫn',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Row(
                children: [
                  if (step.icon != null) ...[
                    Icon(step.icon, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      step.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                step.description,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 18),

              // Bottom Actions Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Bỏ qua
                  TextButton(
                    onPressed: widget.onSkip,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      'Bỏ qua',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black45,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      // Quay lại (nếu bước > 0)
                      if (currentIndex > 0) ...[
                        OutlinedButton(
                          onPressed: _prev,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(
                              color: isDark ? Colors.white24 : Colors.black12,
                            ),
                          ),
                          child: Text(
                            'Quay lại',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Tiếp theo / Đã hiểu
                      ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isLast ? 'Đã hiểu' : 'Tiếp theo',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            if (!isLast) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, size: 14),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  final double pulseScale;
  final ShapeBorder shape;

  _SpotlightPainter({
    required this.targetRect,
    required this.pulseScale,
    required this.shape,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = const Color(0xBE0A0F1D); // ~75% dark tint

    if (targetRect == null) {
      canvas.drawRect(Offset.zero & size, backgroundPaint);
      return;
    }

    // Add safe padding to target rect
    final inflated = targetRect!.inflate(8);

    final fullScreenPath = Path()..addRect(Offset.zero & size);
    final targetPath = Path();

    if (shape is CircleBorder) {
      final radius = math.max(inflated.width, inflated.height) / 2;
      targetPath.addOval(Rect.fromCircle(center: inflated.center, radius: radius));
    } else {
      final r = (shape is RoundedRectangleBorder)
          ? (shape as RoundedRectangleBorder).borderRadius.resolve(null).topLeft.x
          : 16.0;
      targetPath.addRRect(RRect.fromRectAndRadius(inflated, Radius.circular(r)));
    }

    // Combine difference to punch hole
    final cutoutPath = Path.combine(PathOperation.difference, fullScreenPath, targetPath);
    canvas.drawPath(cutoutPath, backgroundPaint);

    // Draw glowing animated pulse ring around target
    final pulseRect = Rect.fromCenter(
      center: inflated.center,
      width: inflated.width * pulseScale,
      height: inflated.height * pulseScale,
    );

    final pulsePaint = Paint()
      ..color = AppTheme.primaryLight.withOpacity(0.6 * (1.1 - (pulseScale - 0.96) / 0.12))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    if (shape is CircleBorder) {
      final pulseRadius = math.max(pulseRect.width, pulseRect.height) / 2;
      canvas.drawCircle(inflated.center, pulseRadius, pulsePaint);
    } else {
      canvas.drawRRect(RRect.fromRectAndRadius(pulseRect, const Radius.circular(18)), pulsePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.pulseScale != pulseScale ||
        oldDelegate.shape != shape;
  }
}
