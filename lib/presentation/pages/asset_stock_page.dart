import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/asset_excel_service.dart';
import '../../core/services/barcode_print_service.dart';
import '../../core/utils/asset_classification_utils.dart';
import '../../data/models/asset_item_model.dart';
import '../../data/models/asset_stock_model.dart';
import '../bloc/asset_bloc.dart';
import '../widgets/asset_card.dart';

class AssetStockPage extends StatefulWidget {
  final String branch;

  final String project;

  const AssetStockPage({
    super.key,
    required this.branch,
    required this.project,
  });

  @override
  State<AssetStockPage> createState() => _AssetStockPageState();
}

class _AssetStockPageState extends State<AssetStockPage> {
  final assetCodeController = TextEditingController();

  final brandController = TextEditingController();
  final searchController = TextEditingController();

  TextEditingController? autoCompleteController;
  final modelController = TextEditingController();
  String searchQuery = '';
  final serialController = TextEditingController();
  final costController = TextEditingController();
  final qtyController = TextEditingController();
  final descriptionController = TextEditingController();
  final warrantyDescriptionController = TextEditingController();

  AssetItemModel? selectedItem;
  File? selectedImage;
  File? selectedWarrantyImage;
  String? selectedStatus;
  bool hasWarranty = false;

  final statuses = ['New', 'Good', 'Bad'];

  @override
  void dispose() {
    assetCodeController.dispose();

    brandController.dispose();
    searchController.dispose();
    modelController.dispose();
    costController.dispose();
    serialController.dispose();
    descriptionController.dispose();
    warrantyDescriptionController.dispose();

    qtyController.dispose();

    super.dispose();
  }

  Future<void> _saveAsset() async {
    if (selectedItem == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please Select Asset')));

      return;
    }

    if (selectedStatus == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please Select Status')));

      return;
    }

    final bloc = context.read<AssetBloc>();

    /// START LOADING
    bloc.emit(bloc.state.copyWith(saving: true));

    final qty = int.tryParse(qtyController.text) ?? 1;

    for (int i = 0; i < qty; i++) {
      /// GENERATE CODE
      final generatedCode = await bloc.repository.generateAssetCode(
        selectedItem!.itemCode,

        branch: widget.branch,

        project: widget.project,
      );
      final cost =
          double.tryParse(costController.text.replaceAll(',', '')) ?? 0;

      /// CREATE MODEL
      final asset = AssetStockModel(
        name: selectedItem!.name,

        /// MASTER CODE
        assetCode: selectedItem!.itemCode,

        /// GENERATED UNIQUE CODE
        itemCode: generatedCode,

        category: selectedItem!.category,

        subCategory: selectedItem!.subCategory,

        classification: selectedItem!.classification,

        assetClassification: selectedItem!.assetClassification,

        assetInventory: selectedItem!.assetInventory,

        location: widget.branch,

        projectName: widget.project,

        status: selectedStatus!,

        brand: brandController.text,

        model: modelController.text,

        serialNo: serialController.text,

        description: descriptionController.text,

        hasWarranty: hasWarranty,

        warrantyDescription: hasWarranty
            ? warrantyDescriptionController.text
            : '',

        warrantyImagePath: null,

        localWarrantyImagePath: hasWarranty
            ? selectedWarrantyImage?.path
            : null,

        imagePath: null,
        localImagePath: selectedImage?.path,
        createdAt: DateTime.now()
            .toUtc()
            .add(const Duration(hours: 4))
            .add(Duration(microseconds: i)),
        isSynced: false,
        cost: cost,
        isDeleted: false,
      );

      /// SAVE LOCAL
      await bloc.repository.saveLocalAsset(asset);
    }

    /// RELOAD ONLINE
    /// RELOAD LOCAL ONLY
    final local = bloc.repository.getLocalAssets(
      branch: widget.branch,
      project: widget.project,
    );

    final merged = AssetBloc.mergeAndSortAssets(
      base: bloc.state.localAssets,
      override: local,
    );

    /// STOP LOADING
    bloc.emit(bloc.state.copyWith(localAssets: merged, saving: false));

    /// CLEAR
    assetCodeController.clear();

    brandController.clear();

    modelController.clear();

    autoCompleteController?.clear();

    serialController.clear();

    qtyController.clear();
    costController.clear();
    descriptionController.clear();
    warrantyDescriptionController.clear();
    selectedItem = null;

    selectedStatus = null;

    selectedImage = null;
    selectedWarrantyImage = null;
    hasWarranty = false;

    setState(() {});
  }

  Future<void> _takePicture() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (image == null) {
      return;
    }

    final dir = await getApplicationDocumentsDirectory();

    final fileName = DateTime.now().millisecondsSinceEpoch.toString();

    final savedImage = await File(image.path).copy('${dir.path}/$fileName.jpg');

    selectedImage = savedImage;

    setState(() {});
  }

  Future<void> _takeWarrantyPicture() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (image == null) {
      return;
    }

    final dir = await getApplicationDocumentsDirectory();

    final fileName = '${DateTime.now().millisecondsSinceEpoch}_warranty'
        .toString();

    final savedImage = await File(image.path).copy('${dir.path}/$fileName.jpg');

    selectedWarrantyImage = savedImage;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.project,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryColor,
        actions: [
          IconButton(
            onPressed: () async {
              try {
                final supabase = Supabase.instance.client;

                /// =========================
                /// SERVER ONLY
                /// =========================
                final response = await supabase
                    .from('asset_stock_taking')
                    .select()
                    .eq('location', widget.branch)
                    .eq('project_name', widget.project);

                /// CONVERT
                final assets = response
                    .map<AssetStockModel>((e) => AssetStockModel.fromJson(e))
                    .toList();

                if (assets.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No Uploaded Assets Found')),
                  );

                  return;
                }

                /// EXPORT EXCEL
                await AssetExcelService.exportAssets(
                  assets: assets,
                  fileName: '${widget.branch}_${widget.project}_assets',
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Excel Exported Successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Export Failed: $e')));
              }
            },

            icon: const Icon(Icons.file_download),
          ),
          IconButton(
            onPressed: () async {
              final supabase = Supabase.instance.client;

              /// =========================
              /// SERVER ONLY
              /// =========================
              final response = await supabase
                  .from('asset_stock_taking')
                  .select()
                  .eq('location', widget.branch)
                  .eq('project_name', widget.project);

              /// CONVERT
              final onlineAssets = response
                  .map<AssetStockModel>((e) => AssetStockModel.fromJson(e))
                  .toList();

              /// CLASSIFICATIONS
              final classifications = onlineAssets
                  .map((e) => e.assetClassification)
                  .where(AssetClassificationUtils.canPrintBarcode)
                  .toSet()
                  .toList();

              if (classifications.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No Uploaded Assets Found')),
                );

                return;
              }

              String? selectedClassification;

              /// =========================
              /// DIALOG
              /// =========================
              final result = await showDialog<String>(
                context: context,
                builder: (_) {
                  return AlertDialog(
                    backgroundColor: Colors.white,
                    title: const Text('Select Asset Classification'),

                    content: DropdownButtonFormField<String>(
                      initialValue: selectedClassification,

                      decoration: InputDecoration(
                        labelText: 'Asset Classification',

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

                      items: classifications.map((e) {
                        return DropdownMenuItem<String>(
                          value: e,
                          child: Text(e),
                        );
                      }).toList(),

                      onChanged: (value) {
                        if (value == null) return;

                        selectedClassification = value;
                      },
                    ),

                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: AppColors.secondaryColor),
                        ),
                      ),

                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, selectedClassification);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                        ),
                        child: const Text(
                          'Print',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  );
                },
              );

              if (result == null) {
                return;
              }

              /// =========================
              /// FILTER ONLINE ONLY
              /// =========================
              final filtered = onlineAssets.where((e) {
                return e.assetClassification.toLowerCase() ==
                        result.toLowerCase() &&
                    AssetClassificationUtils.canPrintBarcode(
                      e.assetClassification,
                    );
              }).toList();

              if (filtered.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No Assets Found')),
                );

                return;
              }

              /// =========================
              /// GENERATE PDF
              /// =========================
              final pdf = await BarcodePrintService.generateBarcodePdf(
                assets: filtered,
              );

              /// =========================
              /// PRINT
              /// =========================
              await Printing.layoutPdf(onLayout: (_) async => pdf);
            },

            icon: const Icon(Icons.print),
          ),
          BlocBuilder<AssetBloc, AssetState>(
            builder: (context, state) {
              return IconButton(
                onPressed:
                    context
                            .read<AssetBloc>()
                            .repository
                            .getPendingUploads(
                              branch: widget.branch,
                              project: widget.project,
                            )
                            .isEmpty ||
                        state.loading
                    ? null
                    : () async {
                        context.read<AssetBloc>().add(UploadAssetsEvent());

                        await Future.doWhile(() async {
                          await Future.delayed(
                            const Duration(milliseconds: 200),
                          );

                          return context.read<AssetBloc>().state.loading;
                        });

                        if (!context.mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),

                            content: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),

                                SizedBox(width: 12),

                                Text(
                                  'Upload Successfully',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },

                icon: state.loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,

                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Badge(
                        label: Text(
                          context
                              .read<AssetBloc>()
                              .repository
                              .getPendingUploads(
                                branch: widget.branch,
                                project: widget.project,
                              )
                              .length
                              .toString(),
                        ),

                        child: const Icon(Icons.cloud_upload),
                      ),
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: SizedBox(
          height: 1000,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/background.png"),
                fit: BoxFit.fill,
              ),
            ),
            child: BlocBuilder<AssetBloc, AssetState>(
              builder: (context, state) {
                if (state.syncingMaster) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),

                        SizedBox(height: 20),

                        Text(
                          'Loading Assets...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final visibleAssets = state.localAssets.where((e) {
                  if (e.isDeleted) {
                    return false;
                  }

                  if (searchQuery.isEmpty) {
                    return true;
                  }

                  final search = searchQuery.toLowerCase();

                  return e.name.toLowerCase().contains(search) ||
                      e.itemCode.toLowerCase().contains(search) ||
                      e.brand.toLowerCase().contains(search) ||
                      e.category.toLowerCase().contains(search) ||
                      e.subCategory.toLowerCase().contains(search) ||
                      e.classification.toLowerCase().contains(search) ||
                      e.assetClassification.toLowerCase().contains(search) ||
                      e.status.toLowerCase().contains(search);
                }).toList();

                final sortedAssets = AssetBloc.sortNewestFirst(visibleAssets);
                return Padding(
                  padding: const EdgeInsets.all(16),

                  child: Column(
                    children: [
                      /// SEARCH ASSET
                      Autocomplete<AssetItemModel>(
                        displayStringForOption: (option) {
                          return option.name;
                        },

                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<AssetItemModel>.empty();
                          }

                          return state.items.where((item) {
                            final search = textEditingValue.text.toLowerCase();

                            return item.name.toLowerCase().contains(search) ||
                                item.itemCode.toLowerCase().contains(search) ||
                                item.category.toLowerCase().contains(search) ||
                                item.subCategory.toLowerCase().contains(
                                  search,
                                ) ||
                                item.assetClassification.toLowerCase().contains(
                                  search,
                                );
                          });
                        },

                        onSelected: (AssetItemModel selection) async {
                          selectedItem = selection;

                          final code = await context
                              .read<AssetBloc>()
                              .repository
                              .generateAssetCode(
                                selection.itemCode,
                                branch: widget.branch,
                                project: widget.project,
                              );

                          assetCodeController.text = code;

                          setState(() {});
                        },

                        fieldViewBuilder:
                            (context, controller, focusNode, onFieldSubmitted) {
                              /// IMPORTANT
                              autoCompleteController = controller;
                              return TextField(
                                controller: controller,

                                focusNode: focusNode,

                                decoration: InputDecoration(
                                  hintText: 'Search Asset',

                                  prefixIcon: const Icon(Icons.search),

                                  fillColor: AppColors.backgroundWidget,

                                  filled: true,

                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.primaryColor,
                                    ),

                                    borderRadius: BorderRadius.circular(14),
                                  ),

                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.primaryColor,
                                    ),

                                    borderRadius: BorderRadius.circular(14),
                                  ),

                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.primaryColor,
                                    ),

                                    borderRadius: BorderRadius.circular(14),
                                  ),

                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                              );
                            },

                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,

                            child: Material(
                              elevation: 8,

                              borderRadius: BorderRadius.circular(16),

                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.9,

                                constraints: const BoxConstraints(
                                  maxHeight: 300,
                                ),

                                child: ListView.builder(
                                  padding: EdgeInsets.zero,

                                  itemCount: options.length,

                                  itemBuilder: (context, index) {
                                    final option = options.elementAt(index);

                                    return InkWell(
                                      onTap: () {
                                        onSelected(option);
                                      },

                                      child: Container(
                                        padding: const EdgeInsets.all(16),

                                        decoration: const BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.black12,
                                            ),
                                          ),
                                        ),

                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,

                                          children: [
                                            Text(
                                              option.name,

                                              style: const TextStyle(
                                                fontSize: 18,

                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),

                                            const SizedBox(height: 4),

                                            Text(
                                              option.itemCode,

                                              style: const TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      /// ASSET CODE
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: costController,

                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),

                              decoration: InputDecoration(
                                labelText: 'Cost',

                                fillColor: AppColors.backgroundWidget,
                                filled: true,

                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.primaryColor,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.primaryColor,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),

                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.primaryColor,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedStatus,

                              items: statuses.map((e) {
                                return DropdownMenuItem(
                                  value: e,
                                  child: Text(e),
                                );
                              }).toList(),

                              onChanged: (v) {
                                selectedStatus = v;

                                setState(() {});
                              },

                              decoration: InputDecoration(
                                labelText: 'Status',
                                fillColor: AppColors.backgroundWidget,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.primaryColor,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.primaryColor,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.primaryColor,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      /// STATUS
                      const SizedBox(height: 12),

                      /// BRAND
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: brandController,

                              decoration: InputDecoration(
                                labelText: 'Brand',
                                fillColor: AppColors.backgroundWidget,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.primaryColor,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.primaryColor,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.primaryColor,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 5),
                          Expanded(
                            child: TextField(
                              controller: qtyController,

                              keyboardType: TextInputType.number,

                              decoration: InputDecoration(
                                labelText: 'Quantity',

                                fillColor: AppColors.backgroundWidget,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.primaryColor,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.primaryColor,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.primaryColor,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      /// MODEL
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: modelController,

                              decoration: InputDecoration(
                                labelText: 'Model',

                                fillColor: AppColors.backgroundWidget,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.primaryColor,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.primaryColor,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.primaryColor,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 5),
                          Expanded(
                            child: TextField(
                              controller: serialController,

                              decoration: InputDecoration(
                                labelText: 'Serial Number',

                                fillColor: AppColors.backgroundWidget,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.primaryColor,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.primaryColor,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.primaryColor,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      TextField(
                        controller: descriptionController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          fillColor: AppColors.backgroundWidget,
                          filled: true,
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.primaryColor,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.primaryColor,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.primaryColor,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SwitchListTile(
                        value: hasWarranty,
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppColors.primaryColor,
                        title: const Text('Warranty'),
                        onChanged: (value) {
                          setState(() {
                            hasWarranty = value;

                            if (!hasWarranty) {
                              warrantyDescriptionController.clear();
                              selectedWarrantyImage = null;
                            }
                          });
                        },
                      ),

                      if (hasWarranty) ...[
                        TextField(
                          controller: warrantyDescriptionController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: 'Warranty Details',
                            fillColor: AppColors.backgroundWidget,
                            filled: true,
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.primaryColor,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.primaryColor,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.primaryColor,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _takeWarrantyPicture,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondaryColor,
                            ),
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                            ),
                            label: Text(
                              selectedWarrantyImage == null
                                  ? 'Take Warranty Picture'
                                  : 'Change Warranty Picture',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (selectedWarrantyImage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                selectedWarrantyImage!,
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                      ],

                      const SizedBox(height: 12),

                      /// SUBMIT
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              width: double.infinity,
                              height: 50,

                              child: ElevatedButton.icon(
                                onPressed: _takePicture,

                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondaryColor,
                                ),

                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                ),

                                label: const Text(
                                  'Take Picture',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: 5),
                          Expanded(
                            child: SizedBox(
                              width: double.infinity,

                              height: 50,

                              child: BlocBuilder<AssetBloc, AssetState>(
                                builder: (context, state) {
                                  return ElevatedButton(
                                    onPressed: state.saving ? null : _saveAsset,

                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryColor,
                                    ),

                                    child: state.saving
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Submit',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      if (selectedImage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),

                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),

                            child: Image.file(
                              selectedImage!,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      TextField(
                        controller: searchController,

                        onChanged: (value) {
                          setState(() {
                            searchQuery = value.toLowerCase();
                          });
                        },

                        decoration: InputDecoration(
                          hintText: 'Search Assets',

                          prefixIcon: const Icon(Icons.search),

                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    searchController.clear();

                                    setState(() {
                                      searchQuery = '';
                                    });
                                  },
                                  icon: const Icon(Icons.close),
                                )
                              : null,

                          filled: true,
                          fillColor: AppColors.backgroundWidget,

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),

                            borderSide: BorderSide(
                              color: AppColors.primaryColor,
                            ),
                          ),

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),

                            borderSide: BorderSide(
                              color: AppColors.primaryColor,
                            ),
                          ),

                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),

                            borderSide: BorderSide(
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// LOCAL LIST
                      Expanded(
                        child: sortedAssets.isEmpty
                            ? const Center(child: Text('No Local Assets'))
                            : ListView.builder(
                                itemCount: sortedAssets.length,
                                itemBuilder: (_, index) {
                                  final item = sortedAssets[index];
                                  return AssetCard(
                                    item: item,

                                    onDelete: () {
                                      context.read<AssetBloc>().add(
                                        DeleteAssetEvent(
                                          itemCode: item.itemCode,

                                          branch: widget.branch,

                                          project: widget.project,
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
