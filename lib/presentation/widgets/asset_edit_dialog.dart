import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/barcode_print_service.dart';
import '../../data/models/asset_item_model.dart';
import '../../data/models/asset_stock_model.dart';
import '../bloc/asset_bloc.dart';

class AssetEditDialog extends StatefulWidget {
  final AssetStockModel asset;

  final String branch;

  final String project;

  const AssetEditDialog({
    super.key,
    required this.asset,
    required this.branch,
    required this.project,
  });

  @override
  State<AssetEditDialog> createState() => _AssetEditDialogState();
}

class _AssetEditDialogState extends State<AssetEditDialog> {
  late TextEditingController brandController;

  late TextEditingController modelController;
  late TextEditingController costController;
  late TextEditingController serialController;

  late String selectedStatus;

  late AssetItemModel selectedItem;

  final statuses = ['New', 'Very Good', 'Good', 'Fair', 'Bad'];

  @override
  void initState() {
    super.initState();

    brandController = TextEditingController(text: widget.asset.brand);

    modelController = TextEditingController(text: widget.asset.model);

    serialController = TextEditingController(text: widget.asset.serialNo);
    costController = TextEditingController(text: widget.asset.cost.toString());
    selectedStatus = widget.asset.status;

    final items = context.read<AssetBloc>().state.items;

    final baseAssetCode = widget.asset.itemCode.split('-').take(2).join('-');

    selectedItem = items.firstWhere(
      (e) => e.itemCode == baseAssetCode,

      orElse: () => items.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        widget.asset.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        widget.asset.itemCode,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                /// IMAGE BUTTON
                if (widget.asset.imagePath != null &&
                    widget.asset.imagePath!.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.image),

                    onPressed: () {
                      showDialog(
                        context: context,

                        builder: (_) {
                          return Dialog(
                            child: InteractiveViewer(
                              child:
                                  (widget.asset.imagePath != null &&
                                      widget.asset.imagePath!.startsWith(
                                        'http',
                                      ))
                                  ? Image.network(
                                      widget.asset.imagePath!,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(
                                        widget.asset.localImagePath ??
                                            widget.asset.imagePath!,
                                      ),
                                      fit: BoxFit.contain,
                                    ),
                            ),
                          );
                        },
                      );
                    },
                  ),
              ],
            ),

            const SizedBox(height: 20),

            /// NAME DROPDOWN
            /// NAME READ ONLY
            TextField(
              controller: TextEditingController(text: selectedItem.name),

              readOnly: true,

              decoration: InputDecoration(
                labelText: 'Name',
                filled: true,
                fillColor: AppColors.backgroundWidget,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primaryColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primaryColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primaryColor),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: brandController,

              decoration: InputDecoration(
                labelText: 'Brand',
                filled: true,
                fillColor: AppColors.backgroundWidget,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primaryColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primaryColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primaryColor),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: modelController,

              decoration: InputDecoration(
                labelText: 'Model',
                filled: true,
                fillColor: AppColors.backgroundWidget,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primaryColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primaryColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primaryColor),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: serialController,

              decoration: InputDecoration(
                labelText: 'Serial No',
                filled: true,
                fillColor: AppColors.backgroundWidget,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primaryColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primaryColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primaryColor),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: costController,

              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),

              decoration: InputDecoration(
                labelText: 'Cost',

                filled: true,
                fillColor: AppColors.backgroundWidget,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primaryColor),
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primaryColor),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 12),

            /// STATUS DROPDOWN
            DropdownButtonFormField<String>(
              initialValue: selectedStatus,

              decoration: InputDecoration(
                labelText: 'Status',

                filled: true,
                fillColor: AppColors.backgroundWidget,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primaryColor),
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primaryColor),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primaryColor),
                ),
              ),

              items: statuses.map((e) {
                return DropdownMenuItem(value: e, child: Text(e));
              }).toList(),

              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedStatus = value;
                });
              },
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                /// DELETE
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),

                    onPressed: () {
                      context.read<AssetBloc>().add(
                        DeleteAssetEvent(
                          itemCode: widget.asset.itemCode,
                          branch: widget.branch,
                          project: widget.project,
                        ),
                      );

                      Navigator.pop(context);
                    },

                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                /// PRINT
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final pdf = await BarcodePrintService.generateBarcodePdf(
                        assets: [widget.asset],
                      );

                      await Printing.layoutPdf(onLayout: (_) async => pdf);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryColor,
                    ),
                    child: const Text(
                      'Print',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// SAVE
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: AppColors.secondaryColor),
                    ),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    width: double.infinity,

                    child: ElevatedButton(
                      onPressed: () {
                        final cost =
                            double.tryParse(
                              costController.text.replaceAll(',', ''),
                            ) ??
                            0;
                        final updated = AssetStockModel(
                          name: selectedItem.name,

                          assetCode: widget.asset.assetCode,

                          itemCode: widget.asset.itemCode,

                          category: selectedItem.category,

                          subCategory: selectedItem.subCategory,

                          classification: selectedItem.classification,

                          location: widget.asset.location,

                          projectName: widget.asset.projectName,

                          status: selectedStatus,

                          brand: brandController.text,

                          model: modelController.text,

                          serialNo: serialController.text,
                          cost: cost,
                          imagePath: widget.asset.imagePath,
                          createdAt: DateTime.now(),
                          isSynced: false,
                        );

                        context.read<AssetBloc>().add(
                          SaveAssetEvent(
                            updated,
                            branch: widget.branch,
                            project: widget.project,
                          ),
                        );

                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
