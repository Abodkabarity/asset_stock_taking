part of '../../../pages/web_asset_dashboard_page.dart';

class _AssetRegistryHeader extends StatelessWidget {
  final int totalAssets;
  final String? selectedBranch;
  final VoidCallback onAddAsset;
  final VoidCallback onExport;

  const _AssetRegistryHeader({
    required this.totalAssets,
    required this.selectedBranch,
    required this.onAddAsset,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 128),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffdfe7f2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff183b66).withValues(alpha: 0.06),
            blurRadius: 26,
            spreadRadius: -10,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 5,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xff4263eb),
                      Color(0xff2f80ed),
                      Color(0xff15aabf),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -36,
              top: -65,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xff4263eb).withValues(alpha: 0.035),
                ),
              ),
            ),
            Positioned(
              right: 110,
              bottom: -75,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xff15aabf).withValues(alpha: 0.025),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 780;

                  final information = Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xff4c6ef5),
                              Color(0xff2f80ed),
                              Color(0xff15aabf),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xff4263eb,
                              ).withValues(alpha: 0.25),
                              blurRadius: 20,
                              spreadRadius: -5,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.white,
                          size: 31,
                        ),
                      ),
                      const SizedBox(width: 17),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 10,
                              runSpacing: 7,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  'Asset Registry',
                                  style: TextStyle(
                                    color: Color(0xff17243b),
                                    fontSize: 25,
                                    height: 1.1,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.65,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffedf3ff),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xffd4e1ff),
                                    ),
                                  ),
                                  child: Text(
                                    '$totalAssets assets',
                                    style: const TextStyle(
                                      color: Color(0xff3156c8),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'A central workspace for searching, reviewing '
                              'and managing active company assets.',
                              style: TextStyle(
                                color: Color(0xff75839a),
                                fontSize: 12.5,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: Color(0xff6e7e95),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    selectedBranch ?? 'All Branches',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xff53627a),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  final actions = Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.end,
                    children: [
                      _AssetRegistryHeaderButton(
                        icon: Icons.file_download_outlined,
                        label: 'Export',
                        filled: false,
                        onTap: onExport,
                      ),
                      _AssetRegistryHeaderButton(
                        icon: Icons.add_rounded,
                        label: 'Add Asset',
                        filled: true,
                        onTap: onAddAsset,
                      ),
                    ],
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        information,
                        const SizedBox(height: 20),
                        actions,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: information),
                      const SizedBox(width: 24),
                      actions,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetRegistryHeaderButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _AssetRegistryHeaderButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  State<_AssetRegistryHeaderButton> createState() =>
      _AssetRegistryHeaderButtonState();
}

class _AssetRegistryHeaderButtonState
    extends State<_AssetRegistryHeaderButton> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: hovered ? 1 : 0),
        duration: const Duration(milliseconds: 190),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, -3 * value),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 190),
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: widget.filled
                        ? LinearGradient(
                            colors: [
                              Color.lerp(
                                const Color(0xff4263eb),
                                const Color(0xff3153d4),
                                value,
                              )!,
                              Color.lerp(
                                const Color(0xff2f80ed),
                                const Color(0xff4263eb),
                                value,
                              )!,
                            ],
                          )
                        : null,
                    color: widget.filled
                        ? null
                        : Color.lerp(
                            Colors.white,
                            const Color(0xfff4f7fc),
                            value,
                          ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.filled
                          ? const Color(0xff4263eb)
                          : Color.lerp(
                              const Color(0xffdce4ef),
                              const Color(0xffaebfe0),
                              value,
                            )!,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.filled
                            ? const Color(
                                0xff4263eb,
                              ).withValues(alpha: 0.18 + (0.09 * value))
                            : Colors.black.withValues(alpha: 0.025 * value),
                        blurRadius: 14 + (6 * value),
                        spreadRadius: -6,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.icon,
                        size: 18,
                        color: widget.filled
                            ? Colors.white
                            : const Color(0xff44536a),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: widget.filled
                              ? Colors.white
                              : const Color(0xff34435a),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
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
    );
  }
}
