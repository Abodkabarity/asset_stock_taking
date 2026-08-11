part of '../../../pages/web_asset_dashboard_page.dart';

class _AssetTableHeader extends StatelessWidget {
  final String? operationLabel;

  const _AssetTableHeader({this.operationLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.blueSoft,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          const SizedBox(width: 54, child: _TableHeaderText('Photo')),
          const Expanded(flex: 2, child: _TableHeaderText('Asset Tag ID')),
          const Expanded(flex: 3, child: _TableHeaderText('Description')),
          const Expanded(flex: 2, child: _TableHeaderText('Status')),
          const Expanded(flex: 2, child: _TableHeaderText('Location')),
          SizedBox(
            width: 138,
            child: _TableHeaderText(operationLabel ?? 'Actions'),
          ),
        ],
      ),
    );
  }
}

class _TableHeaderText extends StatelessWidget {
  final String label;

  const _TableHeaderText(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
    );
  }
}

class _AssetTableRow extends StatelessWidget {
  final AssetStockModel asset;
  final VoidCallback onDetails;
  final VoidCallback onTransfer;
  final VoidCallback onDispose;
  final VoidCallback onMaintenance;
  final String? operationLabel;
  final IconData? operationIcon;
  final VoidCallback? onOperation;

  const _AssetTableRow({
    required this.asset,
    required this.onDetails,
    required this.onTransfer,
    required this.onDispose,
    required this.onMaintenance,
    this.operationLabel,
    this.operationIcon,
    this.onOperation,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onDetails,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            SizedBox(width: 54, child: _AssetImage(path: asset.imagePath)),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  SizedBox(width: 10),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: WebAssetColors.classification(
                        asset.classification,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      asset.itemCode,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff005bd3),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                asset.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5),
              ),
            ),
            Expanded(flex: 2, child: _StatusPill(status: asset.status)),
            Expanded(
              flex: 2,
              child: Text(
                asset.location,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5),
              ),
            ),
            SizedBox(
              width: 138,
              child: operationLabel == null
                  ? Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Transfer',
                          onPressed: onTransfer,
                          icon: const Icon(Icons.open_with),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Maintenance',
                          onPressed: onMaintenance,
                          icon: const Icon(Icons.build),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Dispose',
                          onPressed: onDispose,
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    )
                  : ElevatedButton.icon(
                      onPressed: onOperation,
                      icon: Icon(operationIcon, size: 17, color: Colors.white),
                      label: Text(
                        operationLabel!,
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetImage extends StatefulWidget {
  final String? path;

  const _AssetImage({this.path});

  @override
  State<_AssetImage> createState() => _AssetImageState();
}

class _AssetImageState extends State<_AssetImage> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final path = widget.path?.trim();
    final hasImage = path != null && path.isNotEmpty;

    final image = AnimatedScale(
      scale: hovered && hasImage ? 1.06 : 1,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.backgroundWidget,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0xffdfe7f2)),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    path,
                    fit: BoxFit.cover,
                    cacheWidth: 96,
                    cacheHeight: 96,
                    filterQuality: FilterQuality.low,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.7,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.subText,
                      size: 20,
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: hovered ? 1 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: Container(
                      color: const Color(0x6607182e),
                      child: const Icon(
                        Icons.zoom_in_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              )
            : const Icon(
                Icons.inventory_2_outlined,
                color: AppColors.primaryColor,
              ),
      ),
    );

    if (!hasImage) return image;
    return Tooltip(
      message: 'Open image',
      child: MouseRegion(
        cursor: SystemMouseCursors.zoomIn,
        onEnter: (_) => setState(() => hovered = true),
        onExit: (_) => setState(() => hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => showDialog<void>(
            context: context,
            barrierColor: const Color(0xe6071528),
            builder: (_) => _AssetImageViewerDialog(path: path),
          ),
          child: image,
        ),
      ),
    );
  }
}

class _AssetImageViewerDialog extends StatefulWidget {
  final String path;

  const _AssetImageViewerDialog({required this.path});

  @override
  State<_AssetImageViewerDialog> createState() =>
      _AssetImageViewerDialogState();
}

class _AssetImageViewerDialogState extends State<_AssetImageViewerDialog> {
  final TransformationController controller = TransformationController();
  double scale = 1;

  @override
  void initState() {
    super.initState();
    controller.addListener(_syncScale);
  }

  @override
  void dispose() {
    controller.removeListener(_syncScale);
    controller.dispose();
    super.dispose();
  }

  void _syncScale() {
    final nextScale = controller.value.getMaxScaleOnAxis();
    if ((nextScale - scale).abs() < 0.01 || !mounted) return;
    setState(() => scale = nextScale);
  }

  void _setScale(double value) {
    final nextScale = value.clamp(0.5, 6.0);
    controller.value = Matrix4.diagonal3Values(nextScale, nextScale, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120, maxHeight: 780),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Material(
            color: const Color(0xff0c1b2f),
            child: Column(
              children: [
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: const Color(0xff112640),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xff1f6fff),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.image_outlined,
                          color: Colors.white,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Asset image',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${(scale * 100).round()}%',
                        style: const TextStyle(
                          color: Color(0xffa9bad0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 14),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xff071426),
                    child: InteractiveViewer(
                      transformationController: controller,
                      minScale: 0.5,
                      maxScale: 6,
                      boundaryMargin: const EdgeInsets.all(120),
                      child: Center(
                        child: Image.network(
                          widget.path,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xff48c6ef),
                              ),
                            );
                          },
                          errorBuilder: (_, _, _) => const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white70,
                                size: 52,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Unable to load this image',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 68,
                  color: const Color(0xff112640),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ImageViewerButton(
                        tooltip: 'Zoom out',
                        icon: Icons.remove_rounded,
                        onPressed: () => _setScale(scale - 0.25),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => _setScale(1),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xff3a506d)),
                          minimumSize: const Size(92, 40),
                        ),
                        child: const Text('Reset'),
                      ),
                      const SizedBox(width: 10),
                      _ImageViewerButton(
                        tooltip: 'Zoom in',
                        icon: Icons.add_rounded,
                        onPressed: () => _setScale(scale + 0.25),
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
  }
}

class _ImageViewerButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _ImageViewerButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xff1c3553),
        minimumSize: const Size(40, 40),
      ),
      icon: Icon(icon),
    );
  }
}
