part of '../../../pages/web_asset_dashboard_page.dart';

class _AssetRegistryTableHeader extends StatelessWidget {
  const _AssetRegistryTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xffedf3fc), Color(0xfff3f6fb)],
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xffdce5f1)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 62, child: _AssetRegistryHeaderText('Photo')),
          Expanded(flex: 2, child: _AssetRegistryHeaderText('Asset Tag ID')),
          Expanded(flex: 3, child: _AssetRegistryHeaderText('Asset Details')),
          Expanded(flex: 2, child: _AssetRegistryHeaderText('Status')),
          Expanded(flex: 2, child: _AssetRegistryHeaderText('Location')),
          SizedBox(
            width: 188,
            child: _AssetRegistryHeaderText(
              'Quick Actions',
              alignment: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetRegistryHeaderText extends StatelessWidget {
  final String label;
  final TextAlign alignment;

  const _AssetRegistryHeaderText(this.label, {this.alignment = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: alignment,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xff4f5f77),
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.05,
      ),
    );
  }
}

class _AssetRegistryRow extends StatefulWidget {
  final AssetStockModel asset;
  final int animationDelay;
  final VoidCallback onDetails;
  final VoidCallback onTransfer;
  final VoidCallback onMaintenance;
  final VoidCallback onDispose;

  const _AssetRegistryRow({
    super.key,
    required this.asset,
    required this.animationDelay,
    required this.onDetails,
    required this.onTransfer,
    required this.onMaintenance,
    required this.onDispose,
  });

  @override
  State<_AssetRegistryRow> createState() => _AssetRegistryRowState();
}

class _AssetRegistryRowState extends State<_AssetRegistryRow> {
  bool hovered = false;
  bool visible = false;

  @override
  void initState() {
    super.initState();

    Future<void>.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (!mounted) return;

      setState(() {
        visible = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.asset;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 330),
      curve: Curves.easeOut,
      opacity: visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 390),
        curve: Curves.easeOutCubic,
        offset: visible ? Offset.zero : const Offset(0.018, 0),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => hovered = true),
          onExit: (_) => setState(() => hovered = false),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: hovered ? 1 : 0),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            builder: (context, hoverValue, child) {
              return Transform.translate(
                offset: Offset(3.5 * hoverValue, 0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onDetails,
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 7),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          Colors.white,
                          const Color(0xfff7faff),
                          hoverValue,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Color.lerp(
                            const Color(0xffedf1f6),
                            const Color(0xffb9cbed),
                            hoverValue,
                          )!,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xff294f87,
                            ).withValues(alpha: 0.06 * hoverValue),
                            blurRadius: 18,
                            spreadRadius: -8,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 62,
                            child: Hero(
                              tag: 'asset-registry-image-${asset.itemCode}',
                              child: _AssetImage(path: asset.imagePath),
                            ),
                          ),

                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: WebAssetColors.classification(
                                      asset.classification,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            WebAssetColors.classification(
                                              asset.classification,
                                            ).withValues(
                                              alpha: 0.25 + (0.10 * hoverValue),
                                            ),
                                        blurRadius: 6 + (2 * hoverValue),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    asset.itemCode,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Color.lerp(
                                        const Color(0xff2664c7),
                                        const Color(0xff194da5),
                                        hoverValue,
                                      ),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 13),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    asset.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xff26354c),
                                      fontSize: 12.8,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    asset.category.trim().isEmpty
                                        ? 'Uncategorized'
                                        : asset.category,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xff96a1b1),
                                      fontSize: 10.3,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          Expanded(
                            flex: 2,
                            child: _StatusPill(status: asset.status),
                          ),

                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 15,
                                    color: Color(0xff9ba6b7),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      asset.location.trim().isEmpty
                                          ? '-'
                                          : asset.location,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xff4b596f),
                                        fontSize: 11.7,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(
                            width: 188,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _AssetRegistryActionButton(
                                  tooltip: 'View asset',
                                  icon: Icons.visibility_outlined,
                                  color: const Color(0xff60718a),
                                  onTap: widget.onDetails,
                                ),
                                const SizedBox(width: 6),
                                _AssetRegistryActionButton(
                                  tooltip: 'Transfer asset',
                                  icon: Icons.swap_horiz_rounded,
                                  color: const Color(0xff4263eb),
                                  onTap: widget.onTransfer,
                                ),
                                const SizedBox(width: 6),
                                _AssetRegistryActionButton(
                                  tooltip: 'Add maintenance',
                                  icon: Icons.build_circle_outlined,
                                  color: const Color(0xffe58b00),
                                  onTap: widget.onMaintenance,
                                ),
                                const SizedBox(width: 6),
                                _AssetRegistryActionButton(
                                  tooltip: 'Dispose asset',
                                  icon: Icons.delete_outline_rounded,
                                  color: const Color(0xffd9485f),
                                  onTap: widget.onDispose,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AssetRegistryActionButton extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AssetRegistryActionButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_AssetRegistryActionButton> createState() =>
      _AssetRegistryActionButtonState();
}

class _AssetRegistryActionButtonState
    extends State<_AssetRegistryActionButton> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => hovered = true),
        onExit: (_) => setState(() => hovered = false),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: hovered ? 1 : 0),
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, -2.5 * value),
              child: Transform.scale(
                scale: 1 + (0.045 * value),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 170),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: widget.color.withValues(
                          alpha: 0.07 + (0.07 * value),
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: widget.color.withValues(
                            alpha: 0.12 + (0.18 * value),
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.12 * value),
                            blurRadius: 12,
                            spreadRadius: -5,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(widget.icon, size: 18, color: widget.color),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
