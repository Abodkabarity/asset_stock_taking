import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/asset_stock_model.dart';
import 'web_asset_image.dart';
import 'web_asset_info_table.dart';

class WebAssetQuickViewDialog extends StatelessWidget {
  final AssetStockModel asset;
  final VoidCallback onMoreDetails;
  final VoidCallback onEdit;

  const WebAssetQuickViewDialog({
    super.key,
    required this.asset,
    required this.onMoreDetails,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: SizedBox(
        width: 650,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      asset.itemCode,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.headerText,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 150,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asset.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 14),
                        WebAssetImage(
                          path: asset.imagePath,
                          width: 150,
                          height: 150,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    child: WebAssetInfoTable(
                      rows: [
                        ('Asset Tag ID', asset.itemCode),
                        ('Purchase Date', _date(asset.createdAt)),
                        ('Cost', asset.cost.toStringAsFixed(2)),
                        ('Brand', asset.brand),
                        ('Model', asset.model),
                        ('Serial No', asset.serialNo),
                        ('Site', asset.projectName),
                        ('Location', asset.location),
                        ('Category', asset.category),
                        ('Sub Category', asset.subCategory),
                        ('Asset Type', asset.assetClassification),
                        ('Status', asset.status),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onMoreDetails();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text(
                      'More Details',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onEdit();
                    },
                    icon: const Icon(Icons.edit, size: 17),
                    label: const Text('Edit Asset'),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }
}
