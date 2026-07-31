part of '../../../pages/web_asset_dashboard_page.dart';

class _MetricTile extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String subtitle;

  const _MetricTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  State<_MetricTile> createState() => _MetricTileState();
}

class _MetricTileState extends State<_MetricTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) {
        if (!_isHovered) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) {
        if (_isHovered) {
          setState(() => _isHovered = false);
        }
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: _isHovered ? 1 : 0),
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        builder: (context, animationValue, child) {
          final hoverValue = animationValue.clamp(0.0, 1.0);
          final rotationAngle = 0.785398 * hoverValue;

          final borderColor = Color.lerp(
            AppColors.border,
            widget.color.withValues(alpha: 0.48),
            hoverValue,
          )!;

          final cardColor = Color.lerp(
            Colors.white,
            widget.color.withValues(alpha: 0.035),
            hoverValue,
          )!;

          return Transform.translate(
            offset: Offset(0, -6 * hoverValue),
            child: Transform.scale(
              scale: 1 + (0.012 * hoverValue),
              alignment: Alignment.center,
              child: SizedBox(
                height: 112,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderColor, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: 0.045 + (0.025 * hoverValue),
                              ),
                              blurRadius: 12 + (10 * hoverValue),
                              offset: Offset(0, 5 + (5 * hoverValue)),
                            ),
                            BoxShadow(
                              color: widget.color.withValues(
                                alpha: 0.12 * hoverValue,
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
                        opacity: hoverValue,
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
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(20),
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
                          opacity: 0.025 + (0.035 * hoverValue),
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
                      top: 25 - (10 * hoverValue),
                      child: Transform.rotate(
                        angle: rotationAngle,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color.lerp(
                                  widget.color.withValues(alpha: 0.76),
                                  widget.color.withValues(alpha: 0.88),
                                  hoverValue,
                                )!,
                                widget.color,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              16 - (3 * hoverValue),
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.color.withValues(
                                  alpha: 0.25 + (0.12 * hoverValue),
                                ),
                                blurRadius: 15 + (7 * hoverValue),
                                offset: Offset(0, 7 + (3 * hoverValue)),
                              ),
                            ],
                          ),
                          child: Transform.rotate(
                            angle: -rotationAngle,
                            child: Icon(
                              widget.icon,
                              color: Colors.white,
                              size: 29 + (2 * hoverValue),
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
                                fontSize: 12.5,
                                height: 1.1,
                                color: Color.lerp(
                                  AppColors.text,
                                  widget.color,
                                  hoverValue * 0.55,
                                ),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Flexible(
                                  flex: 0,
                                  child: Text(
                                    widget.value,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 23,
                                      height: 1,
                                      color: AppColors.text,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.35,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 1),
                                    child: Text(
                                      widget.subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        height: 1.2,
                                        color: AppColors.subText,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
