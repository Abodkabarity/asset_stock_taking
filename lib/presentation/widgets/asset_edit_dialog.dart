import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
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

  File? selectedImage;

  String? selectedImagePath;

  final statuses = ['New', 'Very Good', 'Good', 'Fair', 'Bad'];

  @override
  void initState() {
    super.initState();

    brandController = TextEditingController(text: widget.asset.brand);

    modelController = TextEditingController(text: widget.asset.model);

    serialController = TextEditingController(text: widget.asset.serialNo);

    costController = TextEditingController(text: widget.asset.cost.toString());

    selectedStatus = widget.asset.status;

    selectedImagePath = widget.asset.imagePath;

    final items = context.read<AssetBloc>().state.items;

    final baseAssetCode = widget.asset.itemCode.split('-').take(2).join('-');

    selectedItem = items.firstWhere(
      (e) => e.itemCode == baseAssetCode,
      orElse: () => items.first,
    );
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();

    final image = await picker.pickImage(source: source, imageQuality: 70);

    if (image == null) return;

    setState(() {
      selectedImage = File(image.path);

      /// IMPORTANT
      /// LOCAL TEMP IMAGE
      selectedImagePath = image.path;
    });
  }

  Future<void> showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,

      backgroundColor: Colors.white,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),

      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                Container(
                  width: 50,
                  height: 5,

                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Select Image',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.blue),

                  title: const Text('Take Photo'),

                  onTap: () async {
                    Navigator.pop(context);

                    await pickImage(ImageSource.camera);
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.green),

                  title: const Text('Choose From Gallery'),

                  onTap: () async {
                    Navigator.pop(context);

                    await pickImage(ImageSource.gallery);
                  },
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
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
              ],
            ),

            const SizedBox(height: 20),

            /// IMAGE SECTION
            Column(
              children: [
                if (selectedImagePath != null && selectedImagePath!.isNotEmpty)
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) {
                              return Dialog(
                                child: InteractiveViewer(
                                  child: selectedImagePath!.startsWith('http')
                                      ? Image.network(
                                          selectedImagePath!,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(selectedImagePath!),
                                          fit: BoxFit.contain,
                                        ),
                                ),
                              );
                            },
                          );
                        },

                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),

                          child: selectedImagePath!.startsWith('http')
                              ? Image.network(
                                  selectedImagePath!,
                                  height: 120,
                                  width: 120,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(selectedImagePath!),
                                  height: 120,
                                  width: 120,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),

                      Positioned(
                        top: 0,
                        right: 0,

                        child: InkWell(
                          onTap: () async {
                            final confirmDelete = await showDialog<bool>(
                              context: context,

                              builder: (dialogContext) {
                                return AlertDialog(
                                  backgroundColor: Colors.white,

                                  title: const Text('Delete Image'),

                                  content: const Text(
                                    'Are you sure you want to remove this image?',
                                  ),

                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(dialogContext, false);
                                      },

                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),

                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),

                                      onPressed: () {
                                        Navigator.pop(dialogContext, true);
                                      },

                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirmDelete == true) {
                              setState(() {
                                selectedImage = null;

                                selectedImagePath = null;
                              });
                            }
                          },

                          child: Container(
                            padding: const EdgeInsets.all(6),

                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),

                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 10),

                ElevatedButton.icon(
                  onPressed: showImagePickerOptions,

                  icon: const Icon(Icons.image, color: Colors.white),

                  label: Text(
                    selectedImagePath == null ? 'Add Image' : 'Change Image',

                    style: const TextStyle(color: Colors.white),
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// NAME
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

            /// BRAND
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

            /// MODEL
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

            /// SERIAL
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

            /// COST
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

            /// STATUS
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
                /// DELETE ASSET
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),

                    onPressed: () async {
                      final confirmDelete = await showDialog<bool>(
                        context: context,

                        builder: (dialogContext) {
                          return AlertDialog(
                            backgroundColor: Colors.white,

                            title: const Text('Confirm Delete'),

                            content: Text(
                              'Are you sure you want to delete ${widget.asset.name} ?',
                            ),

                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext, false);
                                },

                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),

                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),

                                onPressed: () {
                                  Navigator.pop(dialogContext, true);
                                },

                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirmDelete == true) {
                        context.read<AssetBloc>().add(
                          DeleteAssetEvent(
                            itemCode: widget.asset.itemCode,

                            branch: widget.branch,

                            project: widget.project,
                          ),
                        );

                        Navigator.pop(context);
                      }
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
                    onPressed: () {
                      Navigator.pop(context);
                    },

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
                        print('EDIT ID: ${widget.asset.id}');
                        final updated = AssetStockModel(
                          id: widget.asset.id,
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

                          imagePath:
                              selectedImagePath != null &&
                                  selectedImagePath!.startsWith('http')
                              ? selectedImagePath
                              : null,

                          localImagePath:
                              selectedImagePath != null &&
                                  !selectedImagePath!.startsWith('http')
                              ? selectedImagePath
                              : null,

                          createdAt: widget.asset.createdAt,
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
