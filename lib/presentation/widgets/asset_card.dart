import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/asset_stock_model.dart';
import '../bloc/asset_bloc.dart';
import 'asset_edit_dialog.dart';

class AssetCard extends StatelessWidget {
  final AssetStockModel item;

  final VoidCallback onDelete;

  const AssetCard({super.key, required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),

      onTap: () {
        showDialog(
          context: context,

          builder: (_) {
            return BlocProvider.value(
              value: context.read<AssetBloc>(),

              child: AssetEditDialog(
                asset: item,

                branch: item.location,

                project: item.projectName,
              ),
            );
          },
        );
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 16),

        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(22),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),

              blurRadius: 14,

              offset: const Offset(0, 6),
            ),
          ],
        ),

        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (item.imagePath != null)
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) {
                        return Dialog(
                          backgroundColor: Colors.black,

                          child: InteractiveViewer(
                            child: Image.file(
                              File(item.imagePath!),
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      },
                    );
                  },

                  child: Container(
                    padding: const EdgeInsets.all(8),

                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),

                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: const Icon(
                      Icons.image,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Item Code: '),

                        TextSpan(
                          text: item.itemCode,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        TextSpan(
                          text: '  ${item.name}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Status: '),

                        TextSpan(
                          text: item.status,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Brand: '),

                        TextSpan(
                          text: item.brand,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
