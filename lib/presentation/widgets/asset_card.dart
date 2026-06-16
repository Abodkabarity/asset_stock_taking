import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/asset_classification_utils.dart';
import '../../data/models/asset_stock_model.dart';
import '../bloc/asset_bloc.dart';
import 'asset_edit_dialog.dart';

class AssetCard extends StatelessWidget {
  final AssetStockModel item;

  final VoidCallback onDelete;

  const AssetCard({super.key, required this.item, required this.onDelete});
  Color getClassificationColor(String classification) {
    switch (classification.trim().toLowerCase()) {
      case 'public':
        return Colors.green;

      case 'restricted':
        return Colors.lightBlue;

      case 'confidential':
        return Colors.amber;

      default:
        return Colors.grey;
    }
  }

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
        padding: const EdgeInsets.only(bottom: 20, top: 20, left: 5),
        margin: EdgeInsets.all(4),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(22),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),

              blurRadius: 14,

              offset: const Offset(0, 6),
            ),
          ],
        ),

        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Container(
                margin: EdgeInsets.only(left: 10),

                child: Column(
                  children: [
                    if (item.imagePath != null || item.localImagePath != null)
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) {
                              return Dialog(
                                backgroundColor: Colors.black,

                                child: InteractiveViewer(
                                  child:
                                      (item.imagePath != null &&
                                          item.imagePath!.startsWith('http'))
                                      ? Image.network(
                                          item.imagePath!,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(
                                            item.localImagePath ??
                                                item.imagePath!,
                                          ),
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
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.1,
                            ),

                            borderRadius: BorderRadius.circular(12),
                          ),

                          child: const Icon(
                            Icons.image,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                    SizedBox(height: 8),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: getClassificationColor(item.classification),

                        shape: BoxShape.circle,

                        boxShadow: [
                          BoxShadow(
                            color: getClassificationColor(
                              item.classification,
                            ).withValues(alpha: 0.5),

                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],

                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10),
              SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Item Name: '),

                        TextSpan(
                          text: item.name,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Asset Classification: '),
                        TextSpan(
                          text: item.assetClassification.isEmpty
                              ? '-'
                              : item.assetClassification,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                AssetClassificationUtils.canPrintBarcode(
                                  item.assetClassification,
                                )
                                ? AppColors.primaryColor
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Item Code: '),

                        TextSpan(
                          text: item.itemCode,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
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
                      SizedBox(width: 60),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Cost: '),

                            TextSpan(
                              text: item.cost.toString(),
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

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
                  if (item.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.72,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Description: '),
                            TextSpan(
                              text: item.description,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (item.hasWarranty) ...[
                    const SizedBox(height: 6),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'Warranty: '),
                          TextSpan(
                            text: item.warrantyDescription.trim().isEmpty
                                ? 'Yes'
                                : item.warrantyDescription,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
