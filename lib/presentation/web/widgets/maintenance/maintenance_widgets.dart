part of '../../../pages/web_asset_dashboard_page.dart';

class _MaintenanceHeroCard extends StatelessWidget {
  final int totalAssets;
  final String? selectedBranch;
  final VoidCallback onExport;
  final VoidCallback onSelectAssets;

  const _MaintenanceHeroCard({
    required this.totalAssets,
    required this.selectedBranch,
    required this.onExport,
    required this.onSelectAssets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              right: 45,
              top: 20,
              child: Transform.rotate(
                angle: -0.13,
                child: Icon(
                  Icons.settings_suggest_rounded,
                  size: 142,
                  color: Colors.white.withValues(alpha: 0.055),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 27),
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
                          Icons.engineering_rounded,
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
                                const Text(
                                  'Maintenance Center',
                                  style: TextStyle(
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
                                    color: Colors.white.withValues(alpha: 0.14),
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
                              'Track service activity, update maintenance details '
                              'and return assets to operation efficiently.',
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
                      _MaintenanceHeroButton(
                        icon: Icons.add_rounded,
                        label: 'Select Assets',
                        filled: true,
                        onTap: onSelectAssets,
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
    );
  }
}

class _MaintenanceHeroButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _MaintenanceHeroButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  State<_MaintenanceHeroButton> createState() => _MaintenanceHeroButtonState();
}

class _MaintenanceHeroButtonState extends State<_MaintenanceHeroButton> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: hovered ? 1 : 0),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, -3 * value),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(13),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  decoration: BoxDecoration(
                    color: widget.filled
                        ? Color.lerp(
                            Colors.white,
                            const Color(0xfff0f7ff),
                            value,
                          )
                        : Colors.white.withValues(alpha: 0.10 + (value * 0.06)),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: widget.filled
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.25),
                    ),
                    boxShadow: widget.filled
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: 0.08 + (0.05 * value),
                              ),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.icon,
                        size: 19,
                        color: widget.filled
                            ? const Color(0xff1d5c9e)
                            : Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: widget.filled
                              ? const Color(0xff1d5c9e)
                              : Colors.white,
                          fontSize: 12.5,
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

class _MaintenanceStatCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String subtitle;

  const _MaintenanceStatCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  State<_MaintenanceStatCard> createState() => _MaintenanceStatCardState();
}

class _MaintenanceStatCardState extends State<_MaintenanceStatCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: hovered ? 1 : 0),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        builder: (context, animationValue, child) {
          return Transform.translate(
            offset: Offset(0, -5 * animationValue),
            child: Container(
              height: 116,
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: Color.lerp(
                  Colors.white,
                  widget.color.withValues(alpha: 0.035),
                  animationValue,
                ),
                borderRadius: BorderRadius.circular(19),
                border: Border.all(
                  color: Color.lerp(
                    const Color(0xffdfe7f2),
                    widget.color.withValues(alpha: 0.38),
                    animationValue,
                  )!,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.035 + (0.025 * animationValue),
                    ),
                    blurRadius: 18 + (10 * animationValue),
                    spreadRadius: -7,
                    offset: Offset(0, 8 + (4 * animationValue)),
                  ),
                  BoxShadow(
                    color: widget.color.withValues(
                      alpha: 0.09 * animationValue,
                    ),
                    blurRadius: 28,
                    spreadRadius: -12,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    bottom: -35,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color.withValues(
                          alpha: 0.025 + (animationValue * 0.025),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: widget.color.withValues(
                            alpha: 0.10 + (animationValue * 0.05),
                          ),
                          borderRadius: BorderRadius.circular(
                            16 - (animationValue * 2),
                          ),
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.color,
                          size: 26 + (animationValue * 2),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xff75839a),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              widget.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xff16243c),
                                fontSize: 23,
                                height: 1,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xff9aa5b5),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MaintenanceInformationIcon extends StatelessWidget {
  const _MaintenanceInformationIcon();

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

class _ModernMaintenanceTableHeader extends StatelessWidget {
  const _ModernMaintenanceTableHeader();

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
      child: const Row(
        children: [
          SizedBox(width: 56, child: _ModernMaintenanceHeaderText('Photo')),
          Expanded(
            flex: 2,
            child: _ModernMaintenanceHeaderText('Asset Tag ID'),
          ),
          Expanded(
            flex: 3,
            child: _ModernMaintenanceHeaderText('Asset Details'),
          ),
          Expanded(flex: 2, child: _ModernMaintenanceHeaderText('Status')),
          Expanded(flex: 2, child: _ModernMaintenanceHeaderText('Site')),
          Expanded(flex: 2, child: _ModernMaintenanceHeaderText('Location')),
          SizedBox(
            width: 146,
            child: _ModernMaintenanceHeaderText(
              'Maintenance',
              alignment: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernMaintenanceHeaderText extends StatelessWidget {
  final String label;
  final TextAlign alignment;

  const _ModernMaintenanceHeaderText(
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

class _ModernMaintenanceAssetRow extends StatefulWidget {
  final AssetStockModel asset;
  final int animationDelay;
  final VoidCallback onDetails;
  final VoidCallback onEdit;

  const _ModernMaintenanceAssetRow({
    super.key,
    required this.asset,
    required this.animationDelay,
    required this.onDetails,
    required this.onEdit,
  });

  @override
  State<_ModernMaintenanceAssetRow> createState() =>
      _ModernMaintenanceAssetRowState();
}

class _ModernMaintenanceAssetRowState
    extends State<_ModernMaintenanceAssetRow> {
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
                              tag: 'maintenance-image-${asset.itemCode}',
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
                                    Icons.business_outlined,
                                    size: 16,
                                    color: Color(0xff9aa6b7),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      asset.projectName.trim().isEmpty
                                          ? '-'
                                          : asset.projectName,
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
                              child: _MaintenanceEditButton(
                                onTap: widget.onEdit,
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

class _MaintenanceEditButton extends StatefulWidget {
  final VoidCallback onTap;

  const _MaintenanceEditButton({required this.onTap});

  @override
  State<_MaintenanceEditButton> createState() => _MaintenanceEditButtonState();
}

class _MaintenanceEditButtonState extends State<_MaintenanceEditButton> {
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 7),
                      Text(
                        'Edit',
                        style: TextStyle(
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

class _MaintenanceEmptyState extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onSelectAssets;

  const _MaintenanceEmptyState({
    required this.hasSearch,
    required this.onSelectAssets,
  });

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
                      : Icons.engineering_outlined,
                  color: const Color(0xff4263eb),
                  size: 36,
                ),
              ),
              const SizedBox(height: 17),
              Text(
                hasSearch
                    ? 'No matching maintenance assets'
                    : 'No assets under maintenance',
                style: const TextStyle(
                  color: Color(0xff26354d),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                hasSearch
                    ? 'Try another asset name, tag ID, site or location.'
                    : 'Select an asset to create its first maintenance record.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xff8b98aa),
                  fontSize: 12.5,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (!hasSearch) ...[
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: onSelectAssets,
                  icon: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                  label: const Text(
                    'Select Assets',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff4263eb),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
