import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/asset_item_model.dart';
import '../data/web_asset_repository.dart';
import '../utils/web_dropdown_options.dart';
import '../widgets/web_asset_shell.dart';
import '../widgets/web_asset_image.dart';
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
  final quantityController = TextEditingController(text: '1');
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
    quantityController.dispose();
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

  int get _quantity {
    final parsed = int.tryParse(quantityController.text.trim()) ?? 1;
    return parsed.clamp(1, 500);
  }

  String? get _lastPreviewCode {
    final first = tagController.text.trim();
    if (first.isEmpty || _quantity == 1) return null;
    final separator = first.lastIndexOf('-');
    if (separator < 0) return null;
    final serial = int.tryParse(first.substring(separator + 1));
    if (serial == null) return null;
    return '${first.substring(0, separator)}-'
        '${(serial + _quantity - 1).toString().padLeft(4, '0')}';
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
    final requestedQuantity = int.tryParse(quantityController.text.trim());

    if (item == null || targetBranch == null || tag.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete required fields')),
      );
      return;
    }
    if (requestedQuantity == null ||
        requestedQuantity < 1 ||
        requestedQuantity > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be between 1 and 500')),
      );
      return;
    }

    setState(() => saving = true);

    try {
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

      final cost =
          double.tryParse(costController.text.replaceAll(',', '')) ?? 0;
      final createdCodes = await repository.addAssetsBatch(
        assetCode: item.itemCode,
        quantity: _quantity,
        template: {
          'name': descriptionController.text.trim().isEmpty
              ? item.name
              : descriptionController.text.trim(),
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
          'warranty_serial_no': hasWarranty
              ? warrantySerialController.text
              : '',
          'warranty_image_path': hasWarranty ? warrantyImageUrl : null,
          'cost': cost,
          'image_path': imageUrl,
        },
      );

      if (!mounted) return;
      setState(() => saving = false);
      final range = createdCodes.length == 1
          ? createdCodes.first
          : '${createdCodes.first} - ${createdCodes.last}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xff0f9f7f),
          content: Text(
            '${createdCodes.length} ${widget.inventoryMode ? 'inventory items' : 'assets'} created successfully - $range',
          ),
        ),
      );

      if (widget.onSaved != null) {
        widget.onSaved!();
      } else {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xffd83b4d),
          content: Text('Creation failed: $error'),
        ),
      );
    }
  }

  void _cancel() {
    if (saving) return;
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
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 24,
                  ),
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
                                child: saving
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 9),
                                          Text('Creating $_quantity...'),
                                        ],
                                      )
                                    : Text(
                                        _quantity == 1
                                            ? 'Save'
                                            : 'Create $_quantity',
                                      ),
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
                                  displayStringForOption: (option) =>
                                      option.name,
                                  optionsBuilder: (value) {
                                    final search = value.text
                                        .trim()
                                        .toLowerCase();
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
                                          item.subCategory
                                              .toLowerCase()
                                              .contains(search);
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
                                                flex: 2,
                                                child: _Field(
                                                  label: 'First Asset Tag ID',
                                                  controller: tagController,
                                                  readOnly: true,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              SizedBox(
                                                width: 160,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom: 14,
                                                      ),
                                                  child: TextField(
                                                    controller:
                                                        quantityController,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    inputFormatters: [
                                                      FilteringTextInputFormatter
                                                          .digitsOnly,
                                                    ],
                                                    onChanged: (_) {
                                                      setState(() {});
                                                    },
                                                    decoration:
                                                        _decoration(
                                                          'Quantity *',
                                                        ).copyWith(
                                                          prefixIcon: const Icon(
                                                            Icons
                                                                .copy_all_outlined,
                                                            size: 20,
                                                          ),
                                                          suffixText: 'max 500',
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (_lastPreviewCode != null)
                                            Container(
                                              width: double.infinity,
                                              margin: const EdgeInsets.only(
                                                bottom: 14,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 11,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xffeef5ff),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xffc9dcff,
                                                  ),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.auto_awesome_outlined,
                                                    size: 18,
                                                    color:
                                                        AppColors.primaryColor,
                                                  ),
                                                  const SizedBox(width: 9),
                                                  Expanded(
                                                    child: Text(
                                                      'Preview: ${tagController.text} - $_lastPreviewCode',
                                                      style: const TextStyle(
                                                        color: Color(
                                                          0xff244b87,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
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
                                            value:
                                                selectedItem?.subCategory ?? '',
                                            readOnly: true,
                                          ),
                                          _Field(
                                            label: 'Classification',
                                            value:
                                                selectedItem?.classification ??
                                                '',
                                            readOnly: true,
                                          ),
                                          _Field(
                                            label: 'Asset Classification',
                                            value:
                                                selectedItem
                                                    ?.assetClassification ??
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
                                    decoration: _decoration(
                                      'Warranty Description',
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: WarrantyDateField(
                                          label: 'Warranty Start Date',
                                          controller:
                                              warrantyStartDateController,
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
                if (saving)
                  Positioned.fill(
                    child: _BulkCreationLoadingOverlay(
                      quantity: _quantity,
                      inventoryMode: widget.inventoryMode,
                    ),
                  ),
              ],
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

class _BulkCreationLoadingOverlay extends StatelessWidget {
  final int quantity;
  final bool inventoryMode;

  const _BulkCreationLoadingOverlay({
    required this.quantity,
    required this.inventoryMode,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xaa071b36),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: .96, end: 1),
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Container(
            width: 430,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 34,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff315ff4), Color(0xff11b8d7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55315ff4),
                        blurRadius: 22,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, color: Colors.white),
                      SizedBox(
                        width: 58,
                        height: 58,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Creating $quantity ${inventoryMode ? 'inventory items' : 'assets'}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff0b2142),
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Reserving unique item codes and saving everything securely. Please keep this page open.',
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.45, color: AppColors.subText),
                ),
                const SizedBox(height: 22),
                const LinearProgressIndicator(
                  minHeight: 6,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  color: AppColors.primaryColor,
                  backgroundColor: Color(0xffe7eefb),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
                  : WebAssetMemoryImage(
                      bytes: selectedBytes!,
                      width: 180,
                      height: 130,
                    ),
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
