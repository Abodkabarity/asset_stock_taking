part of '../../../pages/web_asset_dashboard_page.dart';

class _PrintClassificationOption extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final int count;
  final Color color;
  final VoidCallback onTap;
  final bool highlighted;
  final bool compact;

  const _PrintClassificationOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.count,
    required this.color,
    required this.onTap,
    this.highlighted = false,
    this.compact = false,
  });

  @override
  State<_PrintClassificationOption> createState() =>
      _PrintClassificationOptionState();
}

class _PrintClassificationOptionState
    extends State<_PrintClassificationOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!_hovered) {
          setState(() => _hovered = true);
        }
      },
      onExit: (_) {
        if (_hovered) {
          setState(() => _hovered = false);
        }
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: _hovered ? 1 : 0),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, -2.5 * value),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.compact ? 14 : 16,
                    vertical: widget.compact ? 14 : 15,
                  ),
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      Colors.white,
                      widget.color.withValues(alpha: 0.055),
                      value,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Color.lerp(
                        const Color(0xffe0e6ef),
                        widget.color.withValues(alpha: 0.48),
                        value,
                      )!,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.13 * value),
                        blurRadius: 20,
                        spreadRadius: -8,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: widget.compact ? 43 : 48,
                        height: widget.compact ? 43 : 48,
                        decoration: BoxDecoration(
                          color: widget.color.withValues(
                            alpha: widget.highlighted
                                ? 0.14
                                : 0.10 + (0.05 * value),
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          widget.icon,
                          size: widget.compact ? 21 : 23,
                          color: widget.color,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                height: 1.15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xff25324a),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              widget.description,
                              maxLines: widget.compact ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                                color: Color(0xff8190a6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: widget.color.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.count.toString(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: widget.color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          AnimatedSlide(
                            duration: const Duration(milliseconds: 220),
                            offset: _hovered
                                ? Offset.zero
                                : const Offset(-0.18, 0),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: Color.lerp(
                                const Color(0xffa1acbd),
                                widget.color,
                                value,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
