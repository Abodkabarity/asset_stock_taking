import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Shared animated surface used by web cards across the asset experience.
class WebHoverSurface extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;
  final Color color;
  final bool liftOnHover;
  final double? width;

  const WebHoverSurface({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.color = Colors.white,
    this.liftOnHover = true,
    this.width,
  });

  @override
  State<WebHoverSurface> createState() => _WebHoverSurfaceState();
}

class _WebHoverSurfaceState extends State<WebHoverSurface> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = hovered && widget.liftOnHover;
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedScale(
        scale: active ? 1.008 : 1,
        alignment: Alignment.center,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: widget.padding,
          width: widget.width,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: widget.borderRadius,
            border: Border.all(
              color: active
                  ? AppColors.primaryColor.withValues(alpha: 0.26)
                  : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: active
                    ? AppColors.primaryColor.withValues(alpha: 0.14)
                    : const Color(0x0D10264D),
                blurRadius: active ? 30 : 18,
                offset: Offset(0, active ? 12 : 7),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
