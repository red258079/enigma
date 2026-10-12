import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Một container hiệu ứng Liquid Glass (Kính lỏng) phong cách iOS cao cấp
/// Tích hợp:
/// - Lớp lọc mờ BackdropFilter (Frosted Glass)
/// - Viền phản xạ ánh sáng (Specular Highlight Border)
/// - Gradient chuyển sắc ánh sáng mặt kính
/// - Đổ bóng đa tầng mềm mại (Ambient Occlusion Shadow)
class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? tintColor;
  final double opacity;
  final Border? border;
  final List<BoxShadow>? customShadows;
  final VoidCallback? onTap;
  final bool interactive;
  final AlignmentGeometry? gradientBegin;
  final AlignmentGeometry? gradientEnd;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 18.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.tintColor,
    this.opacity = 0.55,
    this.border,
    this.customShadows,
    this.onTap,
    this.interactive = false,
    this.gradientBegin,
    this.gradientEnd,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Màu kính cơ sở theo theme
    final baseColor = tintColor ??
        (isDark
            ? const Color(0xFF141B2D).withValues(alpha: opacity.clamp(0.4, 0.75))
            : const Color(0xFFFFFBF4).withValues(alpha: opacity.clamp(0.5, 0.85)));

    // Gradient phản chiếu ánh sáng specular phong cách kính iOS
    final glassGradient = LinearGradient(
      begin: gradientBegin ?? Alignment.topLeft,
      end: gradientEnd ?? Alignment.bottomRight,
      colors: isDark
          ? [
              (tintColor ?? const Color(0xFF26334D)).withValues(alpha: 0.65),
              baseColor,
              (tintColor ?? const Color(0xFF0F1524)).withValues(alpha: 0.50),
            ]
          : [
              Colors.white.withValues(alpha: 0.85),
              baseColor,
              const Color(0xFFF9EDE0).withValues(alpha: 0.55),
            ],
      stops: const [0.0, 0.45, 1.0],
    );

    // Viền kính phát sáng (Specular Rim)
    final glassBorder = border ??
        Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.65),
          width: 1.2,
        );

    // Đổ bóng nổi đa tầng
    final shadows = customShadows ??
        [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : const Color(0xFF8C6A3C).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.50),
            blurRadius: 6,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ];

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: glassGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: glassBorder,
      ),
      child: child,
    );

    if (onTap != null || interactive) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: AppTheme.primary.withValues(alpha: 0.12),
          highlightColor: Colors.white.withValues(alpha: isDark ? 0.05 : 0.2),
          child: content,
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      ),
    );
  }
}

/// Nút bấm hiệu ứng Liquid Glass lấp lánh phản quang
class LiquidGlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? color;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double blur;

  const LiquidGlassButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.color,
    this.borderRadius = 18.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.blur = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final btnColor = color ?? AppTheme.primary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: btnColor.withValues(alpha: isDark ? 0.35 : 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(borderRadius),
              splashColor: Colors.white.withValues(alpha: 0.2),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      btnColor.withValues(alpha: 0.90),
                      btnColor.withValues(alpha: 0.72),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.40),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Thẻ Card dạng Liquid Glass chuyên dụng hiển thị nội dung
class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? tintColor;
  final VoidCallback? onTap;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 22.0,
    this.padding = const EdgeInsets.all(18.0),
    this.margin,
    this.tintColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassContainer(
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      tintColor: tintColor,
      onTap: onTap,
      child: child,
    );
  }
}
