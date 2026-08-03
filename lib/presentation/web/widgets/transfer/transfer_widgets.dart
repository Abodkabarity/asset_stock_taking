part of '../../../pages/web_asset_dashboard_page.dart';

class _TransferHeroCard extends StatelessWidget {
  final String title;
  final int totalAssets;
  final String? selectedBranch;
  final VoidCallback onExport;

  const _TransferHeroCard({
    required this.title,
    required this.totalAssets,
    required this.selectedBranch,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return WebHoverLift(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 178),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff102b50), Color(0xff174b82), Color(0xff2463a8)],
            stops: [0, 0.55, 1],
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff174b82).withValues(alpha: 0.24),
              blurRadius: 34,
              spreadRadius: -10,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            children: [
              Positioned(
                right: -90,
                top: -130,
                child: Container(
                  width: 310,
                  height: 310,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.055),
                  ),
                ),
              ),
              Positioned(
                right: 155,
                bottom: -115,
                child: Container(
                  width: 245,
                  height: 245,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xff59d5e0).withValues(alpha: 0.07),
                  ),
                ),
              ),
              Positioned(
                right: 42,
                top: 20,
                child: Transform.rotate(
                  angle: -0.13,
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    size: 142,
                    color: Colors.white.withValues(alpha: 0.055),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 27,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 820;

                    final information = Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(19),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.17),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 18,
                                offset: const Offset(0, 9),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.compare_arrows_rounded,
                            color: Colors.white,
                            size: 33,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 27,
                                      height: 1.15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.7,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 11,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.14,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.16,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      '$totalAssets assets',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 9),
                              const Text(
                                'Move assets between branches and sites with a clear, '
                                'organized transfer workflow and better visibility.',
                                style: TextStyle(
                                  color: Color(0xffd9e8f8),
                                  fontSize: 13,
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 13),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: Color(0xff9fd8ff),
                                    size: 17,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      selectedBranch ?? 'All Branches',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xffd9e8f8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
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
                        _MaintenanceHeroButton(
                          icon: Icons.file_download_outlined,
                          label: 'Export',
                          filled: false,
                          onTap: onExport,
                        ),
                      ],
                    );

                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          information,
                          const SizedBox(height: 24),
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
      ),
    );
  }
}

class _TransferInformationIcon extends StatelessWidget {
  const _TransferInformationIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xff4169e1).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Icon(
        Icons.info_outline_rounded,
        color: Color(0xff4169e1),
        size: 20,
      ),
    );
  }
}

class _ModernTransferTableHeader extends StatelessWidget {
  final String operationLabel;

  const _ModernTransferTableHeader({required this.operationLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xfff1f5fb),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xffdfe7f2)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 56, child: _ModernTransferHeaderText('Photo')),
          const Expanded(
            flex: 2,
            child: _ModernTransferHeaderText('Asset Tag ID'),
          ),
          const Expanded(
            flex: 3,
            child: _ModernTransferHeaderText('Asset Details'),
          ),
          const Expanded(flex: 2, child: _ModernTransferHeaderText('Status')),
          const Expanded(flex: 2, child: _ModernTransferHeaderText('Location')),
          SizedBox(
            width: 146,
            child: _ModernTransferHeaderText(
              operationLabel,
              alignment: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernTransferHeaderText extends StatelessWidget {
  final String label;
  final TextAlign alignment;

  const _ModernTransferHeaderText(
    this.label, {
    this.alignment = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: alignment,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xff53627a),
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.05,
      ),
    );
  }
}

class _ModernTransferAssetRow extends StatefulWidget {
  final AssetStockModel asset;
  final int animationDelay;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onDetails;
  final VoidCallback onOperation;

  const _ModernTransferAssetRow({
    super.key,
    required this.asset,
    required this.animationDelay,
    required this.actionLabel,
    required this.actionIcon,
    required this.onDetails,
    required this.onOperation,
  });

  @override
  State<_ModernTransferAssetRow> createState() =>
      _ModernTransferAssetRowState();
}

class _ModernTransferAssetRowState extends State<_ModernTransferAssetRow> {
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
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOut,
      opacity: visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        offset: visible ? Offset.zero : const Offset(0.025, 0),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => hovered = true),
          onExit: (_) => setState(() => hovered = false),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: hovered ? 1 : 0),
            duration: const Duration(milliseconds: 210),
            curve: Curves.easeOutCubic,
            builder: (context, hoverValue, child) {
              return Transform.translate(
                offset: Offset(4 * hoverValue, 0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onDetails,
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 210),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.only(bottom: 8),
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
                            const Color(0xffb9ccef),
                            hoverValue,
                          )!,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xff294f87,
                            ).withValues(alpha: 0.065 * hoverValue),
                            blurRadius: 20,
                            spreadRadius: -8,
                            offset: const Offset(0, 9),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 56,
                            child: Hero(
                              tag: 'transfer-image-${asset.itemCode}',
                              child: _AssetImage(path: asset.imagePath),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: WebAssetColors.classification(
                                      asset.classification,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: WebAssetColors.classification(
                                          asset.classification,
                                        ).withValues(alpha: 0.26),
                                        blurRadius: 7,
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
                                    style: const TextStyle(
                                      color: Color(0xff2664c7),
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
                              padding: const EdgeInsets.only(right: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    asset.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xff24324a),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (asset.category.trim().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      asset.category,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xff96a1b1),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
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
                                    size: 16,
                                    color: Color(0xff9aa6b7),
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
                                        color: Color(0xff46546b),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 146,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _TransferActionButton(
                                label: widget.actionLabel,
                                icon: widget.actionIcon,
                                onTap: widget.onOperation,
                              ),
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

class _TransferActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _TransferActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_TransferActionButton> createState() => _TransferActionButtonState();
}

class _TransferActionButtonState extends State<_TransferActionButton> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: hovered ? 1 : 0),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 1 + (0.025 * value),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(11),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.lerp(
                          const Color(0xff4263eb),
                          const Color(0xff3451d1),
                          value,
                        )!,
                        Color.lerp(
                          const Color(0xff5475f5),
                          const Color(0xff4263eb),
                          value,
                        )!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xff4263eb,
                        ).withValues(alpha: 0.20 + (value * 0.10)),
                        blurRadius: 13 + (value * 5),
                        spreadRadius: -5,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon, color: Colors.white, size: 16),
                      const SizedBox(width: 7),
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
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

class _TransferEmptyState extends StatelessWidget {
  final bool hasSearch;

  const _TransferEmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 285),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: const Color(0xfffbfcfe),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xffe6ebf2)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 35),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xffedf3ff), Color(0xffe8f6fb)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xffd7e4fa)),
                ),
                child: Icon(
                  hasSearch
                      ? Icons.search_off_rounded
                      : Icons.compare_arrows_rounded,
                  color: const Color(0xff4263eb),
                  size: 36,
                ),
              ),
              const SizedBox(height: 17),
              Text(
                hasSearch
                    ? 'No matching transferable assets'
                    : 'No assets available for transfer',
                style: const TextStyle(
                  color: Color(0xff26354d),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                hasSearch
                    ? 'Try another asset name, tag ID or location.'
                    : 'Assets will appear here once they are available to move between locations.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xff8b98aa),
                  fontSize: 12.5,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
