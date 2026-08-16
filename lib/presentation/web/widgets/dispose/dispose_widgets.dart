part of '../../../pages/web_asset_dashboard_page.dart';

class _DisposeEvidencePicker extends StatelessWidget {
  final Uint8List? bytes;
  final String? existingImagePath;
  final String? fileName;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback? onRemove;

  const _DisposeEvidencePicker({
    required this.bytes,
    required this.existingImagePath,
    required this.fileName,
    required this.enabled,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasExisting = existingImagePath?.trim().isNotEmpty == true;
    final hasPreview = bytes != null || hasExisting;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xfffff8f8), Color(0xfffffcfc)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffffd3d5)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final preview = ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: bytes != null
                ? WebAssetMemoryImage(
                    bytes: bytes!,
                    width: compact ? constraints.maxWidth : 132,
                    height: 100,
                    viewerTitle: 'Image after disposal',
                  )
                : WebAssetImage(
                    path: existingImagePath,
                    width: compact ? constraints.maxWidth : 132,
                    height: 100,
                    viewerTitle: 'Image after disposal',
                  ),
          );

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    color: Color(0xffe5484d),
                    size: 21,
                  ),
                  SizedBox(width: 9),
                  Text(
                    'Image After Dispose',
                    style: TextStyle(
                      color: Color(0xff16243c),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Attach clear visual evidence of the asset condition after disposal.',
                style: TextStyle(
                  color: Color(0xff718096),
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
              if (fileName?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 7),
                Text(
                  fileName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff3b5b92),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 11),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: enabled ? onPick : null,
                    icon: Icon(
                      hasPreview
                          ? Icons.change_circle_outlined
                          : Icons.upload_file_outlined,
                      size: 18,
                    ),
                    label: Text(hasPreview ? 'Replace image' : 'Choose image'),
                  ),
                  if (onRemove != null)
                    TextButton.icon(
                      onPressed: enabled ? onRemove : null,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Remove'),
                    ),
                ],
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasPreview) ...[preview, const SizedBox(height: 14)],
                details,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (hasPreview) ...[preview, const SizedBox(width: 16)],
              Expanded(child: details),
            ],
          );
        },
      ),
    );
  }
}

class _DisposedHeroCard extends StatelessWidget {
  final int totalAssets;
  final String? selectedBranch;
  final VoidCallback onExport;
  final VoidCallback onSelectAssets;

  const _DisposedHeroCard({
    required this.totalAssets,
    required this.selectedBranch,
    required this.onExport,
    required this.onSelectAssets,
  });

  @override
  Widget build(BuildContext context) {
    return WebHoverLift(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 136),
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
            alignment: Alignment.centerLeft,
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
                    color: const Color(0xffff7b7f).withValues(alpha: 0.075),
                  ),
                ),
              ),
              Positioned(
                right: 43,
                top: 18,
                child: Transform.rotate(
                  angle: -0.10,
                  child: Icon(
                    Icons.delete_sweep_outlined,
                    size: 145,
                    color: Colors.white.withValues(alpha: 0.055),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 820;

                    final information = Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(16),
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
                            Icons.inventory_2_outlined,
                            color: Colors.white,
                            size: 27,
                          ),
                        ),
                        const SizedBox(width: 15),
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
                                    'Disposal Center',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
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
                                      color: const Color(
                                        0xffff7b7f,
                                      ).withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(
                                          0xffffb6b8,
                                        ).withValues(alpha: 0.27),
                                      ),
                                    ),
                                    child: Text(
                                      '$totalAssets disposed',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Maintain a clear disposal register, document '
                                'asset retirement and preserve a complete audit trail.',
                                style: TextStyle(
                                  color: Color(0xffd9e8f8),
                                  fontSize: 12,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: Color(0xff9fd8ff),
                                    size: 15,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      selectedBranch ?? 'All Branches',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xffd9e8f8),
                                        fontSize: 11.5,
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
                          const SizedBox(height: 16),
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

class _DisposedInformationIcon extends StatelessWidget {
  const _DisposedInformationIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xffe5484d).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Icon(
        Icons.info_outline_rounded,
        color: Color(0xffd9363e),
        size: 20,
      ),
    );
  }
}

class _ModernDisposedTableHeader extends StatelessWidget {
  const _ModernDisposedTableHeader();

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
          SizedBox(width: 56, child: _ModernDisposedHeaderText('After photo')),
          Expanded(flex: 2, child: _ModernDisposedHeaderText('Asset Tag ID')),
          Expanded(flex: 3, child: _ModernDisposedHeaderText('Asset Details')),
          Expanded(flex: 2, child: _ModernDisposedHeaderText('Status')),
          Expanded(flex: 2, child: _ModernDisposedHeaderText('Location')),
          SizedBox(
            width: 146,
            child: _ModernDisposedHeaderText(
              'Disposal',
              alignment: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernDisposedHeaderText extends StatelessWidget {
  final String label;
  final TextAlign alignment;

  const _ModernDisposedHeaderText(
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

class _ModernDisposedAssetRow extends StatefulWidget {
  final AssetStockModel asset;
  final int animationDelay;
  final VoidCallback onDetails;
  final VoidCallback onEdit;

  const _ModernDisposedAssetRow({
    super.key,
    required this.asset,
    required this.animationDelay,
    required this.onDetails,
    required this.onEdit,
  });

  @override
  State<_ModernDisposedAssetRow> createState() =>
      _ModernDisposedAssetRowState();
}

class _ModernDisposedAssetRowState extends State<_ModernDisposedAssetRow> {
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
                          const Color(0xfffff9f9),
                          hoverValue,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Color.lerp(
                            const Color(0xffedf1f6),
                            const Color(0xffffc6c8),
                            hoverValue,
                          )!,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xffc9343b,
                            ).withValues(alpha: 0.06 * hoverValue),
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
                              tag: 'disposed-image-${asset.itemCode}',
                              child: Tooltip(
                                message:
                                    asset.disposedImagePath
                                            ?.trim()
                                            .isNotEmpty ==
                                        true
                                    ? 'Image after disposal — click to enlarge'
                                    : 'No after-disposal image recorded',
                                child: _AssetImage(
                                  path: asset.disposedImagePath,
                                ),
                              ),
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
                              child: _DisposedEditButton(onTap: widget.onEdit),
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

class _DisposedEditButton extends StatefulWidget {
  final VoidCallback onTap;

  const _DisposedEditButton({required this.onTap});

  @override
  State<_DisposedEditButton> createState() => _DisposedEditButtonState();
}

class _DisposedEditButtonState extends State<_DisposedEditButton> {
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
                          const Color(0xffe5484d),
                          const Color(0xffc9343b),
                          value,
                        )!,
                        Color.lerp(
                          const Color(0xfff05b61),
                          const Color(0xffe5484d),
                          value,
                        )!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xffe5484d,
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

class _DisposedEmptyState extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onSelectAssets;

  const _DisposedEmptyState({
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
                    colors: [Color(0xffffeeee), Color(0xfffff7f7)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xffffd6d8)),
                ),
                child: Icon(
                  hasSearch
                      ? Icons.search_off_rounded
                      : Icons.delete_outline_rounded,
                  color: const Color(0xffe5484d),
                  size: 36,
                ),
              ),
              const SizedBox(height: 17),
              Text(
                hasSearch
                    ? 'No matching disposed assets'
                    : 'No disposed assets found',
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
                    : 'Select an asset to document its disposal details.',
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
                    backgroundColor: const Color(0xffe5484d),
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
