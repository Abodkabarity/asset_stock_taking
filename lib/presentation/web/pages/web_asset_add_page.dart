import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/asset_item_model.dart';
import '../data/web_asset_repository.dart';
import '../utils/web_dropdown_options.dart';
import '../widgets/web_asset_shell.dart';
import '../widgets/web_hover_surface.dart';
import '../widgets/common/web_single_date_picker.dart';

class WebAssetAddPage extends StatefulWidget {
  final String? initialBranch;
  final bool inventoryMode;
  final bool embedded;
  final VoidCallback? onCancel;
  final VoidCallback? onSaved;

  const WebAssetAddPage({
    super.key,
    this.initialBranch,
    this.inventoryMode = false,
    this.embedded = false,
    this.onCancel,
    this.onSaved,
  });

  @override
  State<WebAssetAddPage> createState() => _WebAssetAddPageState();
}

class _WebAssetAddPageState extends State<WebAssetAddPage> {
  final repository = WebAssetRepository();
  final descriptionController = TextEditingController();
  final tagController = TextEditingController();
  final purchaseDateController = TextEditingController();
  final purchasedFromController = TextEditingController();
  final costController = TextEditingController();
  final brandController = TextEditingController();
  final modelController = TextEditingController();
  final serialController = TextEditingController();
  final notesController = TextEditingController();
  final warrantyDescriptionController = TextEditingController();
  final warrantyStartDateController = TextEditingController();
  final warrantyEndDateController = TextEditingController();
  final warrantySerialController = TextEditingController();

  List<AssetItemModel> masterItems = [];
  List<String> branches = [];
  AssetItemModel? selectedItem;
  String? branch;
  String status = 'New';
  bool hasWarranty = false;
  bool loading = true;
  bool saving = false;
  Uint8List? selectedAssetImageBytes;
  Uint8List? selectedWarrantyImageBytes;
  String? selectedAssetImageName;
  String? selectedWarrantyImageName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    tagController.dispose();
    purchaseDateController.dispose();
    purchasedFromController.dispose();
    costController.dispose();
    brandController.dispose();
    modelController.dispose();
    serialController.dispose();
    notesController.dispose();
    warrantyDescriptionController.dispose();
    warrantyStartDateController.dispose();
    warrantyEndDateController.dispose();
    warrantySerialController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final loadedBranches = await repository.getBranches();
    final loadedItems = await repository.getMasterItems();
    final sortedBranches = alphabetizedWebOptions([
      'Asset Store',
      ...loadedBranches,
    ]);
    final nextBranch = preferredAssetStore(sortedBranches);

    if (!mounted) return;

    setState(() {
      branches = sortedBranches;
      masterItems =
          loadedItems.where((item) {
            final type = item.assetInventory.trim().toLowerCase();
            return type == (widget.inventoryMode ? 'inventory' : 'asset');
          }).toList()..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
      branch = nextBranch;
      purchaseDateController.text = _date(DateTime.now());
      loading = false;
    });
  }

  Future<void> _selectItem(AssetItemModel item) async {
    selectedItem = item;
    descriptionController.text = item.name;
    await _autoFillCode();
    setState(() {});
  }

  Future<void> _autoFillCode() async {
    final item = selectedItem;
    if (item == null) return;

    final code = await repository.generateAssetCode(item.itemCode);
    if (!mounted) return;

    setState(() {
      tagController.text = code;
    });
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
    final item = selectedItem;
    final targetBranch = branch;
    final tag = tagController.text.trim();

    if (item == null || targetBranch == null || tag.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete required fields')),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    String? imageUrl;
    String? warrantyImageUrl;

    if (selectedAssetImageBytes != null && selectedAssetImageName != null) {
      imageUrl = await repository.uploadWebImage(
        itemCode: tag,
        bytes: selectedAssetImageBytes!,
        fileName: selectedAssetImageName!,
        warranty: false,
      );
    }

    if (hasWarranty &&
        selectedWarrantyImageBytes != null &&
        selectedWarrantyImageName != null) {
      warrantyImageUrl = await repository.uploadWebImage(
        itemCode: tag,
        bytes: selectedWarrantyImageBytes!,
        fileName: selectedWarrantyImageName!,
        warranty: true,
      );
    }

    final createdAt = DateTime.now().toUtc().add(const Duration(hours: 4));
    final cost = double.tryParse(costController.text.replaceAll(',', '')) ?? 0;

    await repository.addAsset({
      'name': descriptionController.text.trim().isEmpty
          ? item.name
          : descriptionController.text.trim(),
      'asset_code': item.itemCode,
      'item_code': tag,
      'category': item.category,
      'sub_category': item.subCategory,
      'classification': item.classification,
      'asset_classification': item.assetClassification,
      'asset_inventory': item.assetInventory,
      'location': targetBranch,
      'project_name': '',
      'status': status,
      'brand': brandController.text,
      'model': modelController.text,
      'serial_no': serialController.text,
      'description': notesController.text,
      'has_warranty': hasWarranty,
      'warranty_description': hasWarranty
          ? warrantyDescriptionController.text
          : '',
      'warranty_start_date': hasWarranty
          ? _databaseDate(warrantyStartDateController.text)
          : null,
      'warranty_end_date': hasWarranty
          ? _databaseDate(warrantyEndDateController.text)
          : null,
      'warranty_serial_no': hasWarranty ? warrantySerialController.text : '',
      'warranty_image_path': hasWarranty ? warrantyImageUrl : null,
      'cost': cost,
      'image_path': imageUrl,
      'created_at': createdAt.toIso8601String(),
    });

    if (!mounted) return;

    setState(() {
      saving = false;
    });

    if (widget.onSaved != null) {
      widget.onSaved!();
    } else {
      Navigator.pop(context, true);
    }
  }

  void _cancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebAssetShell(
      embedded: widget.embedded,
      selectedSection: widget.inventoryMode
          ? WebShellSection.inventory
          : WebShellSection.assets,
      title: widget.inventoryMode ? 'Add Inventory' : 'Add Asset',
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.add_circle_outline,
                            color: AppColors.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.inventoryMode
                                ? 'Add Inventory'
                                : 'Add an Asset',
                            style: const TextStyle(
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
                            Text(
                              widget.inventoryMode
                                  ? 'Inventory Details'
                                  : 'Asset Details',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Autocomplete<AssetItemModel>(
                              displayStringForOption: (option) => option.name,
                              optionsBuilder: (value) {
                                final search = value.text.trim().toLowerCase();
                                if (search.isEmpty) {
                                  return masterItems.take(20);
                                }

                                return masterItems.where((item) {
                                  return item.name.toLowerCase().contains(
                                        search,
                                      ) ||
                                      item.itemCode.toLowerCase().contains(
                                        search,
                                      ) ||
                                      item.category.toLowerCase().contains(
                                        search,
                                      ) ||
                                      item.subCategory.toLowerCase().contains(
                                        search,
                                      );
                                });
                              },
                              onSelected: _selectItem,
                              fieldViewBuilder:
                                  (
                                    context,
                                    controller,
                                    focusNode,
                                    onSubmitted,
                                  ) {
                                    return TextField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      decoration: _decoration(
                                        widget.inventoryMode
                                            ? 'Search Master Inventory *'
                                            : 'Search Master Asset *',
                                      ),
                                    );
                                  },
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
                                        controller: descriptionController,
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _Field(
                                              label: 'Asset Tag ID *',
                                              controller: tagController,
                                            ),
                                          ),
                                        ],
                                      ),
                                      _Field(
                                        label: 'Purchase Date',
                                        controller: purchaseDateController,
                                      ),
                                      _MoneyField(
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
                                        label: 'Purchased from',
                                        controller: purchasedFromController,
                                      ),
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
                                      DropdownButtonFormField<String>(
                                        initialValue: status,
                                        decoration: _decoration('Status'),
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'Bad',
                                            child: Text('Bad'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Good',
                                            child: Text('Good'),
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
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const Divider(height: 38),
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
                                      _DropdownField(
                                        label: 'Location',
                                        value: branch,
                                        items: branches,
                                        onChanged: (value) {
                                          if (value == null) return;
                                          setState(() {
                                            branch = value;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 60),
                                Expanded(
                                  child: Column(
                                    children: [
                                      _Field(
                                        label: 'Master Code',
                                        value: selectedItem?.itemCode ?? '',
                                        readOnly: true,
                                      ),
                                      _Field(
                                        label: 'Category',
                                        value: selectedItem?.category ?? '',
                                        readOnly: true,
                                      ),
                                      _Field(
                                        label: 'Sub Category',
                                        value: selectedItem?.subCategory ?? '',
                                        readOnly: true,
                                      ),
                                      _Field(
                                        label: 'Classification',
                                        value:
                                            selectedItem?.classification ?? '',
                                        readOnly: true,
                                      ),
                                      _Field(
                                        label: 'Asset Classification',
                                        value:
                                            selectedItem?.assetClassification ??
                                            '',
                                        readOnly: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 38),
                            const Text(
                              'Description and Warranty',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 18),
                            TextField(
                              controller: notesController,
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
                                      warrantyDescriptionController.clear();
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
                                selectedBytes: selectedWarrantyImageBytes,
                                selectedName: selectedWarrantyImageName,
                                onPick: () => _pickImage(warranty: true),
                              ),
                            ],
                            const SizedBox(height: 22),
                            _ImagePickerPanel(
                              title: 'Asset Photo',
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
  final Uint8List? selectedBytes;
  final String? selectedName;
  final VoidCallback onPick;

  const _ImagePickerPanel({
    required this.title,
    required this.selectedBytes,
    required this.selectedName,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 180,
              height: 130,
              color: const Color(0xffe8f5fb),
              child: selectedBytes == null
                  ? const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.primaryColor,
                      size: 34,
                    )
                  : Image.memory(selectedBytes!, fit: BoxFit.cover),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: onPick,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff16864a),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Choose File'),
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

class _DropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sortedItems = alphabetizedWebOptions(items);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: _decoration(label),
        items: sortedItems.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _MoneyField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _MoneyField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: _decoration(label).copyWith(
          prefixIcon: Container(
            width: 44,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              color: Color(0xfff2f5f8),
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            child: const Text('AED'),
          ),
        ),
      ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: controller == null
          ? TextFormField(
              key: ValueKey('$label-${value ?? ''}'),
              initialValue: value ?? '',
              readOnly: readOnly,
              decoration: _decoration(label),
            )
          : TextField(
              controller: controller,
              readOnly: readOnly,
              decoration: _decoration(label),
            ),
    );
  }
}

class WarrantyDateField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String Function(DateTime) format;

  const WarrantyDateField({
    super.key,
    required this.label,
    required this.controller,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: () async {
        final initialDate = _parseWebDate(controller.text) ?? DateTime.now();
        final selected = await showWebSingleDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          title: label,
        );
        if (selected != null) controller.text = format(selected);
      },
      decoration: _decoration(
        label,
      ).copyWith(suffixIcon: const Icon(Icons.calendar_month_outlined)),
    );
  }
}

DateTime? _parseWebDate(String value) {
  final direct = DateTime.tryParse(value.trim());
  if (direct != null) return direct;
  final parts = value.trim().split('/');
  if (parts.length != 3) return null;
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return null;
  return DateTime(year, month, day);
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
