import 'package:flutter/material.dart';

enum TooltipPosition { auto, top, bottom }

class OnboardingStep {
  final String title;
  final String description;
  final GlobalKey targetKey;
  final ShapeBorder shape;
  final IconData? icon;
  final TooltipPosition preferredPosition;

  const OnboardingStep({
    required this.title,
    required this.description,
    required this.targetKey,
    this.shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
    this.icon,
    this.preferredPosition = TooltipPosition.auto,
  });
}
