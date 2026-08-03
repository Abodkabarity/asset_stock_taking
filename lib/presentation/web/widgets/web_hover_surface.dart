import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Static surface for structural cards, forms, tables and record containers.
class WebHoverSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;
  final Color color;
  final Color accentColor;
  final bool liftOnHover;
  final double? width;

  const WebHoverSurface({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.color = Colors.white,
    this.accentColor = AppColors.primaryColor,
    this.liftOnHover = true,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D10264D),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Static wrapper retained for decorated structural cards and hero sections.
class WebHoverLift extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final bool enabled;

  const WebHoverLift({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) => child;
}

/// The exact dashboard metric-card movement, colors and rotating icon.
class WebDashboardMetricCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String subtitle;
  final double height;

  const WebDashboardMetricCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.subtitle,
    this.height = 116,
  });

  @override
  State<WebDashboardMetricCard> createState() => _WebDashboardMetricCardState();
}

class _WebDashboardMetricCardState extends State<WebDashboardMetricCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: hovered ? 1 : 0),
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          final angle = .785398 * value;
          return Transform.translate(
            offset: Offset(0, -6 * value),
            child: Transform.scale(
              scale: 1 + (.012 * value),
              child: SizedBox(
                height: widget.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            Colors.white,
                            widget.color.withValues(alpha: .035),
                            value,
                          ),
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(
                            color: Color.lerp(
                              AppColors.border,
                              widget.color.withValues(alpha: .48),
                              value,
                            )!,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: .045 + (.025 * value),
                              ),
                              blurRadius: 12 + (10 * value),
                              offset: Offset(0, 5 + (5 * value)),
                            ),
                            BoxShadow(
                              color: widget.color.withValues(
                                alpha: .12 * value,
                              ),
                              blurRadius: 26,
                              spreadRadius: -5,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 28,
                      right: 28,
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.color.withValues(alpha: 0),
                                widget.color,
                                widget.color.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -25,
                      bottom: -45,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: .025 + (.035 * value),
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.color,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      top: (widget.height - 60) / 2 - (10 * value),
                      child: Transform.rotate(
                        angle: angle,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                widget.color.withValues(alpha: .78),
                                widget.color,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              16 - (3 * value),
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .22),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.color.withValues(
                                  alpha: .25 + (.12 * value),
                                ),
                                blurRadius: 15 + (7 * value),
                                offset: Offset(0, 7 + (3 * value)),
                              ),
                            ],
                          ),
                          child: Transform.rotate(
                            angle: -angle,
                            child: Icon(
                              widget.icon,
                              color: Colors.white,
                              size: 29 + (2 * value),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(96, 15, 16, 15),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color.lerp(
                                  AppColors.subText,
                                  widget.color,
                                  value * .55,
                                ),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 23,
                                height: 1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.subText,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
