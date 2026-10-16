import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/asset_status.dart';
import '../../data/models/asset_stock_model.dart';

/// Shows condition and availability separately without overloading one status.
class AssetStateBadges extends StatelessWidget {
  final AssetStockModel asset;
  const AssetStateBadges({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    final conditionColor = switch (asset.status.toLowerCase()) {
      'good' || 'very good' => const Color(0xff16875a),
      'damaged' || 'bad' => const Color(0xffd64052),
      'new' => AppColors.primaryColor,
      _ => const Color(0xffaa6d12),
    };
    final operationColor = switch (asset.operationalStatus) {
      AssetStatus.available => const Color(0xff16875a),
      AssetStatus.maintenance => const Color(0xffaa6d12),
      AssetStatus.reserved => const Color(0xff7950ce),
      AssetStatus.checkedOut => const Color(0xff2c6ebc),
      _ => AppColors.subText,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _badge(
          'Condition',
          asset.needsConditionReview ? 'Needs review' : asset.status,
          Icons.verified_outlined,
          conditionColor,
        ),
        if (!asset.isAvailable) ...[
          const SizedBox(height: 5),
          _badge(
            'Availability',
            asset.operationalStatus,
            Icons.work_outline_rounded,
            operationColor,
          ),
        ],
      ],
    );
  }

  Widget _badge(String label, String value, IconData icon, Color color) =>
      Tooltip(
        message: '$label: $value',
        child: Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: color.withValues(alpha: .12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
