import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/asset_stock_model.dart';
import '../data/web_asset_repository.dart';
import '../utils/web_page_route.dart';
import '../widgets/web_asset_image.dart';
import '../widgets/web_asset_shell.dart';
import '../widgets/web_hover_surface.dart';
import 'web_asset_add_page.dart';

class WebAssetEditPage extends StatefulWidget {
  final AssetStockModel asset;
  final bool embedded;
  final VoidCallback? onCancel;
  final VoidCallback? onSaved;

  const WebAssetEditPage({
    super.key,
    required this.asset,
    this.embedded = false,
    this.onCancel,
    this.onSaved,
  });

  @override
  State<WebAssetEditPage> createState() => _WebAssetEditPageState();
}

class _WebAssetEditPageState extends State<WebAssetEditPage> {
  final repository = WebAssetRepository();
  late final TextEditingController nameController;
  late final TextEditingController tagController;
  late final TextEditingController brandController;
  late final TextEditingController modelController;
  late final TextEditingController serialController;
  late final TextEditingController costController;
  late final TextEditingController descriptionController;
  late final TextEditingController warrantyDescriptionController;
  late final TextEditingController warrantyStartDateController;
  late final TextEditingController warrantyEndDateController;
  late final TextEditingController warrantySerialController;
  late String status;
  late bool hasWarranty;
  String? assetImageUrl;
  String? warrantyImageUrl;
  Uint8List? selectedAssetImageBytes;
  Uint8List? selectedWarrantyImageBytes;
  String? selectedAssetImageName;
  String? selectedWarrantyImageName;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.asset.name);
    tagController = TextEditingController(text: widget.asset.itemCode);
    brandController = TextEditingController(text: widget.asset.brand);
    modelController = TextEditingController(text: widget.asset.model);
    serialController = TextEditingController(text: widget.asset.serialNo);
    costController = TextEditingController(
      text: widget.asset.cost.toStringAsFixed(2),
    );
    descriptionController = TextEditingController(
      text: widget.asset.description,
    );
    warrantyDescriptionController = TextEditingController(
      text: widget.asset.warrantyDescription,
    );
    warrantyStartDateController = TextEditingController(
      text: widget.asset.warrantyStartDate,
    );
    warrantyEndDateController = TextEditingController(
      text: widget.asset.warrantyEndDate,
    );
    warrantySerialController = TextEditingController(
      text: widget.asset.warrantySerialNo,
    );
    status = widget.asset.status.isEmpty ? 'New' : widget.asset.status;
    hasWarranty = widget.asset.hasWarranty;
    assetImageUrl = widget.asset.imagePath;
    warrantyImageUrl = widget.asset.warrantyImagePath;
  }

  @override
  void dispose() {
    nameController.dispose();
    tagController.dispose();
    brandController.dispose();
    modelController.dispose();
    serialController.dispose();
    costController.dispose();
    descriptionController.dispose();
    warrantyDescriptionController.dispose();
    warrantyStartDateController.dispose();
    warrantyEndDateController.dispose();
    warrantySerialController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required bool warranty}) async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );

    final file = result?.files.single;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return;

    setState(() {
      if (warranty) {
        selectedWarrantyImageBytes = bytes;
        selectedWarrantyImageName = file.name;
      } else {
        selectedAssetImageBytes = bytes;
        selectedAssetImageName = file.name;
      }
    });
  }

  Future<void> _save() async {
    setState(() {
      saving = true;
    });

    final cost = double.tryParse(costController.text.replaceAll(',', '')) ?? 0;
    var nextAssetImageUrl = assetImageUrl;
    var nextWarrantyImageUrl = warrantyImageUrl;

    if (selectedAssetImageBytes != null && selectedAssetImageName != null) {
      nextAssetImageUrl = await repository.uploadWebImage(
        itemCode: widget.asset.itemCode,
        bytes: selectedAssetImageBytes!,
        fileName: selectedAssetImageName!,
        warranty: false,
      );
    }

    if (hasWarranty &&
        selectedWarrantyImageBytes != null &&
        selectedWarrantyImageName != null) {
      nextWarrantyImageUrl = await repository.uploadWebImage(
        itemCode: widget.asset.itemCode,
        bytes: selectedWarrantyImageBytes!,
        fileName: selectedWarrantyImageName!,
        warranty: true,
      );
    }

    if (!hasWarranty) {
      nextWarrantyImageUrl = null;
      warrantyDescriptionController.clear();
      warrantyStartDateController.clear();
      warrantyEndDateController.clear();
      warrantySerialController.clear();
    }

    await repository.updateAsset(
      itemCode: widget.asset.itemCode,
      values: {
        'brand': brandController.text,
        'model': modelController.text,
        'serial_no': serialController.text,
        'cost': cost,
        'status': status,
        'description': descriptionController.text,
        'image_path': nextAssetImageUrl,
        'has_warranty': hasWarranty,
        'warranty_description': hasWarranty
            ? warrantyDescriptionController.text
            : '',
        'warranty_image_path': nextWarrantyImageUrl,
        'warranty_start_date': hasWarranty
            ? _databaseDate(warrantyStartDateController.text)
            : null,
        'warranty_end_date': hasWarranty
            ? _databaseDate(warrantyEndDateController.text)
            : null,
        'warranty_serial_no': hasWarranty ? warrantySerialController.text : '',
      },
    );

    if (!mounted) return;

    setState(() {
      saving = false;
    });
    if (widget.onSaved != null) {
      widget.onSaved!();
    } else {
      Navigator.pop(context);
    }
  }

  void _cancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebAssetShell(
      embedded: widget.embedded,
      selectedSection: WebShellSection.assets,
      title: 'Edit Asset',
      onAddAsset: () {
        Navigator.push(
          context,
          webPageRoute(WebAssetAddPage(initialBranch: widget.asset.location)),
        );
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1320),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.edit, color: AppColors.primaryColor),
                    const SizedBox(width: 12),
                    const Text(
                      'Edit Asset',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: _cancel,
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(saving ? 'Saving...' : 'Save'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                WebHoverSurface(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Asset Details',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _Field(
                                  label: 'Description *',
                                  controller: nameController,
                                  readOnly: true,
                                ),
                                _Field(
                                  label: 'Asset Tag ID *',
                                  controller: tagController,
                                  readOnly: true,
                                ),
                                _Field(
                                  label: 'Purchase Date',
                                  value: _date(widget.asset.createdAt),
                                  readOnly: true,
                                ),
                                _Field(
                                  label: 'Cost',
                                  controller: costController,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 60),
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _Field(
                                  label: 'Brand',
                                  controller: brandController,
                                ),
                                _Field(
                                  label: 'Model',
                                  controller: modelController,
                                ),
                                _Field(
                                  label: 'Serial No',
                                  controller: serialController,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: DropdownButtonFormField<String>(
                                    initialValue: status,
                                    decoration: _decoration('Status'),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Bad',
                                        child: Text('Bad'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Disposed',
                                        child: Text('Disposed'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Good',
                                        child: Text('Good'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Maintenance',
                                        child: Text('Maintenance'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'New',
                                        child: Text('New'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() {
                                        status = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 36),
                      const Text(
                        'Location, Category and Department',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _Field(
                                  label: 'Location',
                                  value: widget.asset.location,
                                  readOnly: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 60),
                          Expanded(
                            child: Column(
                              children: [
                                _Field(
                                  label: 'Category',
                                  value: widget.asset.category,
                                  readOnly: true,
                                ),
                                _Field(
                                  label: 'Sub Category',
                                  value: widget.asset.subCategory,
                                  readOnly: true,
                                ),
                                _Field(
                                  label: 'Asset Type',
                                  value: widget.asset.assetClassification,
                                  readOnly: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 36),
                      const Text(
                        'Description and Warranty',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: descriptionController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: _decoration('Description'),
                      ),
                      const SizedBox(height: 18),
                      Material(
                        color: Colors.transparent,
                        child: SwitchListTile(
                          value: hasWarranty,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Warranty'),
                          activeThumbColor: AppColors.primaryColor,
                          onChanged: (value) {
                            setState(() {
                              hasWarranty = value;
                              if (!hasWarranty) {
                                selectedWarrantyImageBytes = null;
                                selectedWarrantyImageName = null;
                                warrantyStartDateController.clear();
                                warrantyEndDateController.clear();
                                warrantySerialController.clear();
                              }
                            });
                          },
                        ),
                      ),
                      if (hasWarranty) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: warrantyDescriptionController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: _decoration('Warranty Description'),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: WarrantyDateField(
                                label: 'Warranty Start Date',
                                controller: warrantyStartDateController,
                                format: _date,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: WarrantyDateField(
                                label: 'Warranty End Date',
                                controller: warrantyEndDateController,
                                format: _date,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: warrantySerialController,
                          decoration: _decoration(
                            'Warranty Serial No. (optional)',
                          ),
                        ),
                        const SizedBox(height: 14),
                        _ImagePickerPanel(
                          title: 'Warranty Photo',
                          currentUrl: warrantyImageUrl,
                          selectedBytes: selectedWarrantyImageBytes,
                          selectedName: selectedWarrantyImageName,
                          onPick: () => _pickImage(warranty: true),
                        ),
                      ],
                      const SizedBox(height: 22),
                      _ImagePickerPanel(
                        title: 'Asset Photo',
                        currentUrl: assetImageUrl,
                        selectedBytes: selectedAssetImageBytes,
                        selectedName: selectedAssetImageName,
                        onPick: () => _pickImage(warranty: false),
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

  String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  String? _databaseDate(String value) {
    final parts = value.trim().split('/');
    if (parts.length == 3) {
      return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
    }
    return value.trim().isEmpty ? null : value.trim();
  }
}

class _ImagePickerPanel extends StatelessWidget {
  final String title;
  final String? currentUrl;
  final Uint8List? selectedBytes;
  final String? selectedName;
  final VoidCallback onPick;

  const _ImagePickerPanel({
    required this.title,
    required this.currentUrl,
    required this.selectedBytes,
    required this.selectedName,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelected = selectedBytes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 180,
              height: 130,
              color: const Color(0xffe8f5fb),
              child: hasSelected
                  ? Image.memory(selectedBytes!, fit: BoxFit.cover)
                  : WebAssetImage(path: currentUrl, width: 180, height: 130),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton.icon(
                  onPressed: onPick,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Choose Image'),
                ),
                if (selectedName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    selectedName!,
                    style: const TextStyle(color: AppColors.subText),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? value;
  final bool readOnly;

  const _Field({
    required this.label,
    this.controller,
    this.value,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final readOnlyController = controller;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: readOnlyController == null
          ? TextFormField(
              initialValue: value ?? '',
              readOnly: readOnly,
              decoration: _decoration(label),
            )
          : TextField(
              controller: readOnlyController,
              readOnly: readOnly,
              decoration: _decoration(label),
            ),
    );
  }
}

InputDecoration _decoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: const OutlineInputBorder(),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.primaryColor),
    ),
  );
}
