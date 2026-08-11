import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

Future<void> showWebAssetImageViewer(
  BuildContext context, {
  String? path,
  Uint8List? bytes,
  String title = 'Asset image',
}) {
  final cleanPath = path?.trim();
  if ((cleanPath == null || cleanPath.isEmpty) && bytes == null) {
    return Future<void>.value();
  }
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0xe6071528),
    builder: (_) =>
        _WebAssetImageViewer(path: cleanPath, bytes: bytes, title: title),
  );
}

class WebAssetImage extends StatefulWidget {
  final String? path;
  final double width;
  final double height;
  final String viewerTitle;
  final bool enableViewer;

  const WebAssetImage({
    super.key,
    required this.path,
    this.width = 96,
    this.height = 96,
    this.viewerTitle = 'Asset image',
    this.enableViewer = true,
  });

  @override
  State<WebAssetImage> createState() => _WebAssetImageState();
}

class _WebAssetImageState extends State<WebAssetImage> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final cleanPath = widget.path?.trim();
    final hasImage = cleanPath != null && cleanPath.isNotEmpty;
    final finiteWidth = widget.width.isFinite ? widget.width : 640.0;
    final finiteHeight = widget.height.isFinite ? widget.height : 480.0;

    final image = Container(
      width: widget.width,
      height: widget.height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.backgroundWidget,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  cleanPath,
                  fit: BoxFit.cover,
                  cacheWidth: (finiteWidth * 2).round(),
                  cacheHeight: (finiteHeight * 2).round(),
                  filterQuality: FilterQuality.medium,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.subText,
                    size: 30,
                  ),
                ),
                if (widget.enableViewer)
                  AnimatedOpacity(
                    opacity: hovered ? 1 : 0,
                    duration: const Duration(milliseconds: 170),
                    child: Container(
                      color: const Color(0x5907182e),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.zoom_in_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
              ],
            )
          : const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.primaryColor,
              size: 34,
            ),
    );

    if (!hasImage || !widget.enableViewer) return image;
    return Tooltip(
      message: 'Click to enlarge',
      child: MouseRegion(
        cursor: SystemMouseCursors.zoomIn,
        onEnter: (_) => setState(() => hovered = true),
        onExit: (_) => setState(() => hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => showWebAssetImageViewer(
            context,
            path: cleanPath,
            title: widget.viewerTitle,
          ),
          child: AnimatedScale(
            scale: hovered ? 1.015 : 1,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: image,
          ),
        ),
      ),
    );
  }
}

class WebAssetMemoryImage extends StatefulWidget {
  final Uint8List bytes;
  final double width;
  final double height;
  final String viewerTitle;

  const WebAssetMemoryImage({
    super.key,
    required this.bytes,
    required this.width,
    required this.height,
    this.viewerTitle = 'Selected asset image',
  });

  @override
  State<WebAssetMemoryImage> createState() => _WebAssetMemoryImageState();
}

class _WebAssetMemoryImageState extends State<WebAssetMemoryImage> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Click to enlarge',
      child: MouseRegion(
        cursor: SystemMouseCursors.zoomIn,
        onEnter: (_) => setState(() => hovered = true),
        onExit: (_) => setState(() => hovered = false),
        child: GestureDetector(
          onTap: () => showWebAssetImageViewer(
            context,
            bytes: widget.bytes,
            title: widget.viewerTitle,
          ),
          child: Stack(
            children: [
              Image.memory(
                widget.bytes,
                width: widget.width,
                height: widget.height,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              ),
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: hovered ? 1 : 0,
                  duration: const Duration(milliseconds: 170),
                  child: Container(
                    color: const Color(0x5907182e),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.zoom_in_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebAssetImageViewer extends StatefulWidget {
  final String? path;
  final Uint8List? bytes;
  final String title;

  const _WebAssetImageViewer({this.path, this.bytes, required this.title});

  @override
  State<_WebAssetImageViewer> createState() => _WebAssetImageViewerState();
}

class _WebAssetImageViewerState extends State<_WebAssetImageViewer> {
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
    final image = widget.bytes != null
        ? Image.memory(
            widget.bytes!,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          )
        : Image.network(
            widget.path!,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Color(0xff48c6ef)),
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
          );

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
                      Expanded(
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
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
                      child: Center(child: image),
                    ),
                  ),
                ),
                Container(
                  height: 68,
                  color: const Color(0xff112640),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ViewerIconButton(
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
                      _ViewerIconButton(
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

class _ViewerIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _ViewerIconButton({
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
