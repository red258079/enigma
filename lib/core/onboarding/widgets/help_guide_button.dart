import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class HelpGuideButton extends StatelessWidget {
  final VoidCallback onTap;
  final String tooltip;

  const HelpGuideButton({
    super.key,
    required this.onTap,
    this.tooltip = 'Xem hướng dẫn chức năng này',
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.help_outline_rounded, size: 22),
      color: AppTheme.primaryLight,
      tooltip: tooltip,
      onPressed: onTap,
    );
  }
}
