import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';

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
    final masterItems = context.read<AssetBloc>().state.items;

    return Dialog(
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
                        widget.asset.itemCode,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        widget.asset.assetCode,
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
                              child: Image.file(File(widget.asset.imagePath!)),
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
            DropdownButtonFormField<AssetItemModel>(
              value: selectedItem,

              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),

              items: masterItems.map((e) {
                return DropdownMenuItem(value: e, child: Text(e.name));
              }).toList(),

              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedItem = value;
                });
              },
            ),

            const SizedBox(height: 12),

            TextField(
              controller: brandController,

              decoration: const InputDecoration(
                labelText: 'Brand',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: modelController,

              decoration: const InputDecoration(
                labelText: 'Model',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: serialController,

              decoration: const InputDecoration(
                labelText: 'Serial No',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            /// STATUS DROPDOWN
            DropdownButtonFormField<String>(
              value: selectedStatus,

              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
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

                    child: const Text('Delete'),
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

                    child: const Text('Print'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// SAVE
            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: () {
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

                    imagePath: widget.asset.imagePath,
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

                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
