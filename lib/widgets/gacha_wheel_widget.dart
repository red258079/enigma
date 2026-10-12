import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class GachaWheelWidget extends StatefulWidget {
  final VoidCallback onSpinComplete;
  
  const GachaWheelWidget({super.key, required this.onSpinComplete});

  @override
  State<GachaWheelWidget> createState() => GachaWheelWidgetState();
}

class GachaWheelWidgetState extends State<GachaWheelWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isSpinning = false);
        widget.onSpinComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void spin() {
    if (_isSpinning) return;
    setState(() => _isSpinning = true);
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: spin,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _animation.value * 10 * 3.14159, // Spin 5 times
            child: child,
          );
        },
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.accentPurple, AppTheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 5,
              )
            ],
          ),
          child: Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.bgDark,
                border: Border.all(color: AppTheme.primaryLight, width: 4),
              ),
              child: Center(
                child: const Icon(
                  Icons.star_rounded,
                  size: 80,
                  color: AppTheme.accentAmber,
                )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 2000.ms, color: Colors.white),
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }
}
