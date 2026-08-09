import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class WebAssetImage extends StatelessWidget {
  final String? path;
  final double width;
  final double height;

  const WebAssetImage({
    super.key,
    required this.path,
    this.width = 96,
    this.height = 96,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = path != null && path!.trim().isNotEmpty;

    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.backgroundWidget,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.network(
              path!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              cacheWidth: (width * 2).round(),
              cacheHeight: (height * 2).round(),
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, _, _) => const Icon(
                Icons.broken_image_outlined,
                color: AppColors.subText,
                size: 30,
              ),
            )
          : const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.primaryColor,
              size: 34,
            ),
    );
  }
}
