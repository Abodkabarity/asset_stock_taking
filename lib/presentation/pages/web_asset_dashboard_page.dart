import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/asset_excel_service.dart';
import '../../core/services/barcode_print_service.dart';
import '../../core/utils/asset_classification_utils.dart';
import '../../data/models/asset_item_model.dart';
import '../../data/models/asset_stock_model.dart';

enum WebAssetSection { dashboard, assets, transfer, dispose, maintenance }

Color _classificationColor(String classification) {
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

class WebAssetDashboardPage extends StatefulWidget {
  const WebAssetDashboardPage({super.key});

  @override
  State<WebAssetDashboardPage> createState() => _WebAssetDashboardPageState();
}

class _WebAssetDashboardPageState extends State<WebAssetDashboardPage> {
  final supabase = Supabase.instance.client;
  final searchController = TextEditingController();

  static const double pageScale = 1;
  WebAssetSection selectedSection = WebAssetSection.dashboard;
  List<AssetStockModel> assets = [];
  List<AssetItemModel> masterItems = [];
  List<String> branches = [];
  String? selectedBranch;
  String searchQuery = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      loading = true;
    });

    final branchResponse = await supabase
        .from('branches')
        .select('branch_name')
        .order('branch_name');
    final assetResponse = await supabase
        .from('asset_stock_taking')
        .select()
        .order('created_at', ascending: false);
    final masterResponse = await supabase
        .from('asset_master')
        .select()
        .order('name');

    branches = branchResponse
        .map<String>((e) => e['branch_name']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
    assets = assetResponse
        .map<AssetStockModel>((e) => AssetStockModel.fromJson(e))
        .toList();
    masterItems = masterResponse
        .map<AssetItemModel>((e) => AssetItemModel.fromJson(e))
        .toList();

    setState(() {
      loading = false;
    });
  }

  List<AssetStockModel> get visibleAssets {
    final search = searchQuery.trim().toLowerCase();

    return assets.where((asset) {
      final matchesBranch =
          selectedBranch == null || asset.location == selectedBranch;
      final matchesSearch =
          search.isEmpty ||
          asset.name.toLowerCase().contains(search) ||
          asset.itemCode.toLowerCase().contains(search) ||
          asset.category.toLowerCase().contains(search) ||
          asset.subCategory.toLowerCase().contains(search) ||
          asset.brand.toLowerCase().contains(search) ||
          asset.status.toLowerCase().contains(search);

      return matchesBranch && matchesSearch;
    }).toList();
  }

  double get totalValue {
    return visibleAssets.fold(0, (sum, asset) => sum + asset.cost);
  }

  int get activeCount {
    return visibleAssets.where((asset) {
      return asset.status.toLowerCase() != 'disposed';
    }).length;
  }

  int get disposedCount {
    return visibleAssets.where((asset) {
      return asset.status.toLowerCase() == 'disposed';
    }).length;
  }

  int get maintenanceCount {
    return visibleAssets.where((asset) {
      return asset.status.toLowerCase() == 'maintenance';
    }).length;
  }

  Future<List<String>> _loadProjects(String branch) async {
    final response = await supabase
        .from('projects')
        .select('project_name')
        .eq('branch_name', branch)
        .order('project_name');

    return response
        .map<String>((e) => e['project_name']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<String> _generateAssetCode(String assetCode) async {
    final response = await supabase
        .from('asset_stock_taking')
        .select('item_code')
        .eq('asset_code', assetCode);

    final usedSerials = <int>{};

    for (final row in response) {
      final itemCode = row['item_code']?.toString() ?? '';
      final serial = int.tryParse(itemCode.split('-').last);

      if (serial != null) {
        usedSerials.add(serial);
      }
    }

    var nextSerial = 1;
    while (usedSerials.contains(nextSerial)) {
      nextSerial++;
    }

    return '$assetCode-${nextSerial.toString().padLeft(4, '0')}';
  }

  Future<void> _addAsset() async {
    AssetItemModel? selectedItem;
    String? branch =
        selectedBranch ?? (branches.isEmpty ? null : branches.first);
    List<String> projects = branch == null ? [] : await _loadProjects(branch);
    String? project = projects.isEmpty ? null : projects.first;
    String status = 'New';
    final brandController = TextEditingController();
    final modelController = TextEditingController();
    final serialController = TextEditingController();
    final costController = TextEditingController();
    final descriptionController = TextEditingController();

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Add an Asset'),
              content: SizedBox(
                width: 760,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Autocomplete<AssetItemModel>(
                        displayStringForOption: (option) => option.name,
                        optionsBuilder: (value) {
                          final search = value.text.trim().toLowerCase();
                          if (search.isEmpty) {
                            return const Iterable<AssetItemModel>.empty();
                          }

                          return masterItems.where((item) {
                            return item.name.toLowerCase().contains(search) ||
                                item.itemCode.toLowerCase().contains(search) ||
                                item.category.toLowerCase().contains(search) ||
                                item.subCategory.toLowerCase().contains(search);
                          });
                        },
                        onSelected: (item) {
                          setDialogState(() {
                            selectedItem = item;
                          });
                        },
                        fieldViewBuilder:
                            (context, controller, focusNode, onSubmitted) {
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: _inputDecoration(
                                  'Search Master Asset',
                                ),
                              );
                            },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 6,
                              child: SizedBox(
                                width: 520,
                                height: 280,
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final item = options.elementAt(index);

                                    return ListTile(
                                      title: Text(item.name),
                                      subtitle: Text(
                                        '${item.itemCode} | ${item.category}',
                                      ),
                                      onTap: () => onSelected(item),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (selectedItem != null) ...[
                        const SizedBox(height: 12),
                        _MasterPreview(item: selectedItem!),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: branch,
                              decoration: _inputDecoration('Branch'),
                              items: branches.map((item) {
                                return DropdownMenuItem(
                                  value: item,
                                  child: Text(item),
                                );
                              }).toList(),
                              onChanged: (value) async {
                                if (value == null) return;
                                final loadedProjects = await _loadProjects(
                                  value,
                                );
                                setDialogState(() {
                                  branch = value;
                                  projects = loadedProjects;
                                  project = loadedProjects.isEmpty
                                      ? null
                                      : loadedProjects.first;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: project,
                              decoration: _inputDecoration('Project'),
                              items: projects.map((item) {
                                return DropdownMenuItem(
                                  value: item,
                                  child: Text(item),
                                );
                              }).toList(),
                              onChanged: (value) {
                                project = value;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: brandController,
                              decoration: _inputDecoration('Brand'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: modelController,
                              decoration: _inputDecoration('Model'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: serialController,
                              decoration: _inputDecoration('Serial Number'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: costController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: _inputDecoration('Cost'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: status,
                              decoration: _inputDecoration('Status'),
                              items: const [
                                DropdownMenuItem(
                                  value: 'New',
                                  child: Text('New'),
                                ),
                                DropdownMenuItem(
                                  value: 'Good',
                                  child: Text('Good'),
                                ),
                                DropdownMenuItem(
                                  value: 'Bad',
                                  child: Text('Bad'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                status = value;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: descriptionController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: _inputDecoration('Description'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed:
                      selectedItem == null || branch == null || project == null
                      ? null
                      : () => Navigator.pop(context, true),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Add Asset',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true ||
        selectedItem == null ||
        branch == null ||
        project == null) {
      brandController.dispose();
      modelController.dispose();
      serialController.dispose();
      costController.dispose();
      descriptionController.dispose();
      return;
    }

    final generatedCode = await _generateAssetCode(selectedItem!.itemCode);
    final cost = double.tryParse(costController.text.replaceAll(',', '')) ?? 0;
    final createdAt = DateTime.now().toUtc().add(const Duration(hours: 4));

    await supabase.from('asset_stock_taking').insert({
      'name': selectedItem!.name,
      'asset_code': selectedItem!.itemCode,
      'item_code': generatedCode,
      'category': selectedItem!.category,
      'sub_category': selectedItem!.subCategory,
      'classification': selectedItem!.classification,
      'asset_classification': selectedItem!.assetClassification,
      'asset_inventory': selectedItem!.assetInventory,
      'location': branch,
      'project_name': project,
      'status': status,
      'brand': brandController.text,
      'model': modelController.text,
      'serial_no': serialController.text,
      'description': descriptionController.text,
      'has_warranty': false,
      'warranty_description': '',
      'cost': cost,
      'image_path': null,
      'created_at': createdAt.toIso8601String(),
    });

    brandController.dispose();
    modelController.dispose();
    serialController.dispose();
    costController.dispose();
    descriptionController.dispose();

    await _loadData();
  }

  Future<void> _exportAssets() async {
    await AssetExcelService.exportAssets(
      assets: visibleAssets,
      fileName: selectedBranch == null
          ? 'all_assets'
          : '${selectedBranch}_assets',
    );
  }

  Future<void> _printAssets() async {
    final printable = visibleAssets.where((asset) {
      return AssetClassificationUtils.canPrintBarcode(
        asset.assetClassification,
      );
    }).toList();

    if (printable.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No printable assets found')),
      );
      return;
    }

    final pdf = await BarcodePrintService.generateBarcodePdf(assets: printable);
    await Printing.layoutPdf(onLayout: (_) async => pdf);
  }

  Future<void> _showAssetDetails(AssetStockModel asset) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Asset Details'),
          content: SizedBox(
            width: 760,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AssetImage(path: asset.imagePath, size: 140),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              asset.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(asset.itemCode),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _DetailChip(
                                  label: asset.classification.isEmpty
                                      ? 'No Classification'
                                      : asset.classification,
                                  color: _classificationColor(
                                    asset.classification,
                                  ),
                                ),
                                _DetailChip(
                                  label: asset.assetClassification.isEmpty
                                      ? 'No Asset Classification'
                                      : asset.assetClassification,
                                  color: AppColors.primaryColor,
                                ),
                                _StatusPill(status: asset.status),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _DetailField(label: 'Branch', value: asset.location),
                      _DetailField(label: 'Project', value: asset.projectName),
                      _DetailField(label: 'Category', value: asset.category),
                      _DetailField(
                        label: 'Sub Category',
                        value: asset.subCategory,
                      ),
                      _DetailField(label: 'Brand', value: asset.brand),
                      _DetailField(label: 'Model', value: asset.model),
                      _DetailField(label: 'Serial No', value: asset.serialNo),
                      _DetailField(
                        label: 'Cost',
                        value: asset.cost.toStringAsFixed(2),
                      ),
                      _DetailField(
                        label: 'Description',
                        value: asset.description,
                        wide: true,
                      ),
                      _DetailField(
                        label: 'Warranty',
                        value: asset.hasWarranty
                            ? (asset.warrantyDescription.isEmpty
                                  ? 'Yes'
                                  : asset.warrantyDescription)
                            : 'No',
                        wide: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _transferAsset(asset);
              },
              icon: const Icon(Icons.swap_horiz, color: Colors.white),
              label: const Text(
                'Transfer',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _transferAsset(AssetStockModel asset) async {
    String branch = selectedBranch ?? asset.location;
    List<String> projects = await _loadProjects(branch);
    String? project = projects.contains(asset.projectName)
        ? asset.projectName
        : (projects.isEmpty ? null : projects.first);

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Transfer Asset'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DialogAssetHeader(asset: asset),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _TransferInfoBox(
                            title: 'From',
                            branch: asset.location,
                            project: asset.projectName,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.arrow_forward),
                        ),
                        Expanded(
                          child: _TransferInfoBox(
                            title: 'To',
                            branch: branch,
                            project: project ?? '-',
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      initialValue: branch,
                      decoration: _inputDecoration('Branch'),
                      items: branches.map((item) {
                        return DropdownMenuItem(value: item, child: Text(item));
                      }).toList(),
                      onChanged: (value) async {
                        if (value == null) return;

                        final loadedProjects = await _loadProjects(value);
                        setDialogState(() {
                          branch = value;
                          projects = loadedProjects;
                          project = loadedProjects.isEmpty
                              ? null
                              : loadedProjects.first;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: project,
                      decoration: _inputDecoration('Project'),
                      items: projects.map((item) {
                        return DropdownMenuItem(value: item, child: Text(item));
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          project = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: project == null
                      ? null
                      : () => Navigator.pop(context, true),
                  icon: const Icon(Icons.swap_horiz, color: Colors.white),
                  label: const Text(
                    'Transfer',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true || project == null) return;

    await supabase
        .from('asset_stock_taking')
        .update({'location': branch, 'project_name': project})
        .eq('item_code', asset.itemCode);

    await _loadData();
  }

  Future<void> _disposeAsset(AssetStockModel asset) async {
    final disposeToController = TextEditingController();
    final notesController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Dispose Asset'),
          content: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogAssetHeader(asset: asset),
                const SizedBox(height: 18),
                TextField(
                  controller: disposeToController,
                  decoration: _inputDecoration('Dispose To'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: notesController,
                  minLines: 3,
                  maxLines: 4,
                  decoration: _inputDecoration('Notes'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              label: const Text(
                'Dispose',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    await supabase
        .from('asset_stock_taking')
        .update({'status': 'Disposed'})
        .eq('item_code', asset.itemCode);

    disposeToController.dispose();
    notesController.dispose();

    await _loadData();
  }

  Future<void> _maintenanceAsset(AssetStockModel asset) async {
    final titleController = TextEditingController();
    final detailsController = TextEditingController();
    final costController = TextEditingController();
    String maintenanceStatus = 'Open';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Maintenance'),
              content: SizedBox(
                width: 640,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DialogAssetHeader(asset: asset),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: titleController,
                            decoration: _inputDecoration('Maintenance Title'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: maintenanceStatus,
                            decoration: _inputDecoration('Status'),
                            items: const [
                              DropdownMenuItem(
                                value: 'Open',
                                child: Text('Open'),
                              ),
                              DropdownMenuItem(
                                value: 'In Progress',
                                child: Text('In Progress'),
                              ),
                              DropdownMenuItem(
                                value: 'Completed',
                                child: Text('Completed'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setDialogState(() {
                                maintenanceStatus = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: detailsController,
                      minLines: 3,
                      maxLines: 4,
                      decoration: _inputDecoration('Maintenance Details'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: costController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _inputDecoration('Maintenance Cost'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.build, color: Colors.white),
                  label: const Text(
                    'Add',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return;

    await supabase
        .from('asset_stock_taking')
        .update({'status': 'Maintenance'})
        .eq('item_code', asset.itemCode);

    titleController.dispose();
    detailsController.dispose();
    costController.dispose();

    await _loadData();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.primaryColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffedf1f6),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return ClipRect(
            child: Transform.scale(
              scale: pageScale,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: constraints.maxWidth / pageScale,
                height: constraints.maxHeight / pageScale,
                child: Row(
                  children: [
                    _Sidebar(
                      section: selectedSection,
                      onSelected: (section) {
                        setState(() {
                          selectedSection = section;
                        });
                      },
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          _TopBar(
                            selectedBranch: selectedBranch,
                            branches: branches,
                            onBranchChanged: (value) {
                              setState(() {
                                selectedBranch = value;
                              });
                            },
                            onAssets: () {
                              setState(() {
                                selectedSection = WebAssetSection.assets;
                              });
                            },
                            onAddAsset: _addAsset,
                            onExport: _exportAssets,
                            onPrint: _printAssets,
                            onRefresh: _loadData,
                          ),
                          Expanded(
                            child: loading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : SingleChildScrollView(
                                    padding: const EdgeInsets.all(20),
                                    child: _content(),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _content() {
    switch (selectedSection) {
      case WebAssetSection.assets:
        return _assetsPanel();
      case WebAssetSection.transfer:
        return _operationPanel(
          title: 'Transfer / Move',
          icon: Icons.open_with,
          description: 'Move an asset from one branch or project to another.',
          actionLabel: 'Transfer',
          actionIcon: Icons.swap_horiz,
          onAction: _transferAsset,
        );
      case WebAssetSection.dispose:
        return _operationPanel(
          title: 'Dispose',
          icon: Icons.change_circle_outlined,
          description:
              'Dispose assets while keeping the asset record in the database.',
          actionLabel: 'Dispose',
          actionIcon: Icons.delete_outline,
          onAction: _disposeAsset,
        );
      case WebAssetSection.maintenance:
        return _operationPanel(
          title: 'Maintenance',
          icon: Icons.settings_suggest_outlined,
          description: 'Bulk define maintenance for selected assets.',
          actionLabel: 'Maintenance',
          actionIcon: Icons.build,
          onAction: _maintenanceAsset,
        );
      case WebAssetSection.dashboard:
        return _dashboard();
    }
  }

  Widget _dashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dashboard',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        const Text(
          'dashboard & statistics',
          style: TextStyle(fontSize: 16, color: AppColors.subText),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.extension,
                color: AppColors.primaryColor,
                title: 'Active Assets',
                value: activeCount.toString(),
                subtitle: 'Total Assets: ${visibleAssets.length}',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _MetricTile(
                icon: Icons.payments_outlined,
                color: Colors.redAccent,
                title: 'Value of Assets',
                value: totalValue.toStringAsFixed(2),
                subtitle: 'AED',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _MetricTile(
                icon: Icons.delete_outline,
                color: Colors.orange,
                title: 'Disposed Assets',
                value: disposedCount.toString(),
                subtitle: 'Archived in place',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _MetricTile(
                icon: Icons.build,
                color: Colors.deepPurple,
                title: 'Maintenance',
                value: maintenanceCount.toString(),
                subtitle: 'Assets under work',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: _categoryPanel()),
            const SizedBox(width: 18),
            Expanded(flex: 5, child: _alertPanel()),
          ],
        ),
        const SizedBox(height: 18),
        _assetsPanel(limit: 8),
      ],
    );
  }

  Widget _categoryPanel() {
    final Map<String, int> counts = {};
    for (final asset in visibleAssets) {
      final key = asset.category.trim().isEmpty
          ? 'Uncategorized'
          : asset.category;
      counts[key] = (counts[key] ?? 0) + 1;
    }

    return _Panel(
      title: 'Asset Value by Category',
      child: counts.isEmpty
          ? const SizedBox(height: 220, child: Center(child: Text('No data')))
          : Column(
              children: counts.entries.map((entry) {
                final percent = entry.value / visibleAssets.length;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 155,
                        child: Text(entry.key, overflow: TextOverflow.ellipsis),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            minHeight: 16,
                            value: percent,
                            color: AppColors.primaryColor,
                            backgroundColor: AppColors.backgroundWidget,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(entry.value.toString()),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _alertPanel() {
    return _Panel(
      title: 'Alert',
      trailing: Wrap(
        spacing: 5,
        runSpacing: 5,
        children: const [
          _AlertChip(label: 'Assets Due', color: Color(0xff4f83ff)),
          _AlertChip(label: 'Maintenance', color: Color(0xff8e54c9)),
          _AlertChip(label: 'Warranty', color: Color(0xffff6868)),
          _AlertChip(label: 'Lease', color: Color(0xffffb23f)),
        ],
      ),
      child: SizedBox(
        height: 300,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.45,
          ),
          itemCount: 35,
          itemBuilder: (context, index) {
            final day = index - 1;
            final isToday = day == DateTime.now().day;

            return Container(
              alignment: Alignment.topRight,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isToday ? const Color(0xfffff6d8) : Colors.white,
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                day < 1 ? '' : day.toString(),
                style: const TextStyle(color: Color(0xff0051c8)),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _assetsPanel({int? limit}) {
    final shownAssets = limit == null
        ? visibleAssets
        : visibleAssets.take(limit).toList();

    return _Panel(
      title: limit == null ? 'List of Assets' : 'Recent Assets',
      trailing: SizedBox(
        width: 300,
        child: TextField(
          controller: searchController,
          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search Assets',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
      ),
      child: Column(
        children: [
          _AssetTableHeader(),
          if (shownAssets.isEmpty)
            const SizedBox(
              height: 180,
              child: Center(child: Text('No assets found')),
            )
          else
            ...shownAssets.map((asset) {
              return _AssetTableRow(
                asset: asset,
                onDetails: () => _showAssetDetails(asset),
                onTransfer: () => _transferAsset(asset),
                onDispose: () => _disposeAsset(asset),
                onMaintenance: () => _maintenanceAsset(asset),
              );
            }),
        ],
      ),
    );
  }

  Widget _operationPanel({
    required String title,
    required IconData icon,
    required String description,
    required String actionLabel,
    required IconData actionIcon,
    required Future<void> Function(AssetStockModel asset) onAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.deepOrange),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _Panel(
          title: '',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(description),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: visibleAssets.isEmpty
                    ? null
                    : () => onAction(visibleAssets.first),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Select Assets',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff3ec37b),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Assets Pending $title',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _AssetTableHeader(operationLabel: actionLabel),
              ...visibleAssets.map((asset) {
                return _AssetTableRow(
                  asset: asset,
                  operationLabel: actionLabel,
                  operationIcon: actionIcon,
                  onOperation: () => onAction(asset),
                  onDetails: () => _showAssetDetails(asset),
                  onTransfer: () => _transferAsset(asset),
                  onDispose: () => _disposeAsset(asset),
                  onMaintenance: () => _maintenanceAsset(asset),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final String? selectedBranch;
  final List<String> branches;
  final ValueChanged<String?> onBranchChanged;
  final VoidCallback onAssets;
  final VoidCallback onAddAsset;
  final VoidCallback onExport;
  final VoidCallback onPrint;
  final VoidCallback onRefresh;

  const _TopBar({
    required this.selectedBranch,
    required this.branches,
    required this.onBranchChanged,
    required this.onAssets,
    required this.onAddAsset,
    required this.onExport,
    required this.onPrint,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final branchValue = selectedBranch ?? '__all__';
    final branchItems = ['__all__', ...branches];

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Image.asset('assets/images/icon.png', height: 42, width: 42),
          const SizedBox(width: 12),
          const Text(
            'Asset Stock Taking',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 24),
          _TopNavIcon(
            icon: Icons.inventory_2_outlined,
            label: 'Assets',
            onTap: onAssets,
          ),
          _TopNavIcon(
            icon: Icons.add_circle_outline,
            label: 'Asset',
            onTap: onAddAsset,
          ),
          _TopNavIcon(
            icon: Icons.file_download_outlined,
            label: 'Export',
            onTap: onExport,
          ),
          _TopNavIcon(
            icon: Icons.print_outlined,
            label: 'Print',
            onTap: onPrint,
          ),
          const Spacer(),
          SizedBox(
            width: 190,
            child: DropdownButtonFormField<String>(
              initialValue: branchValue,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Branch',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: branchItems.map((branch) {
                return DropdownMenuItem(
                  value: branch,
                  child: Text(
                    branch == '__all__' ? 'All Branches' : branch,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                onBranchChanged(value == '__all__' ? null : value);
              },
            ),
          ),
          IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh)),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final WebAssetSection section;
  final ValueChanged<WebAssetSection> onSelected;

  const _Sidebar({required this.section, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 24, 18, 20),
            color: AppColors.primaryColor,
            child: const Text(
              'Al Ain Pharmacy',
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _SidebarItem(
            icon: Icons.home_outlined,
            label: 'Dashboard',
            selected: section == WebAssetSection.dashboard,
            onTap: () => onSelected(WebAssetSection.dashboard),
          ),
          _SidebarItem(
            icon: Icons.notifications_none,
            label: 'Alerts',
            badge: '1',
            selected: false,
            onTap: () => onSelected(WebAssetSection.dashboard),
          ),
          _SidebarGroup(selected: section, onSelected: onSelected),
          _SidebarItem(
            icon: Icons.list_alt_outlined,
            label: 'Lists',
            selected: false,
            onTap: () => onSelected(WebAssetSection.assets),
          ),
          _SidebarItem(
            icon: Icons.description_outlined,
            label: 'Reports',
            selected: false,
            onTap: () => onSelected(WebAssetSection.dashboard),
          ),
          _SidebarItem(
            icon: Icons.settings_outlined,
            label: 'Setup',
            selected: false,
            onTap: () => onSelected(WebAssetSection.dashboard),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
              'Web management console',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarGroup extends StatelessWidget {
  final WebAssetSection selected;
  final ValueChanged<WebAssetSection> onSelected;

  const _SidebarGroup({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SidebarItem(
          icon: Icons.extension_outlined,
          label: 'Assets',
          selected: selected == WebAssetSection.assets,
          onTap: () => onSelected(WebAssetSection.assets),
        ),
        _SidebarSubItem(
          icon: Icons.format_list_bulleted,
          label: 'List of Assets',
          selected: selected == WebAssetSection.assets,
          onTap: () => onSelected(WebAssetSection.assets),
        ),
        _SidebarSubItem(
          icon: Icons.open_with,
          label: 'Move',
          selected: selected == WebAssetSection.transfer,
          onTap: () => onSelected(WebAssetSection.transfer),
        ),
        _SidebarSubItem(
          icon: Icons.change_circle_outlined,
          label: 'Dispose',
          selected: selected == WebAssetSection.dispose,
          onTap: () => onSelected(WebAssetSection.dispose),
        ),
        _SidebarSubItem(
          icon: Icons.settings_suggest_outlined,
          label: 'Maintenance',
          selected: selected == WebAssetSection.maintenance,
          onTap: () => onSelected(WebAssetSection.maintenance),
        ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        color: selected ? const Color(0xffffbd0a) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? Colors.deepOrange : Colors.deepOrange,
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
            if (badge != null)
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.redAccent,
                child: Text(
                  badge!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SidebarSubItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarSubItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 39,
        color: selected ? const Color(0xfffff4ce) : Colors.white,
        padding: const EdgeInsets.only(left: 48, right: 18),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.deepOrange),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _TopNavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TopNavIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 24, color: AppColors.secondaryColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String subtitle;

  const _MetricTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 96,
            margin: const EdgeInsets.only(left: 18, top: 12),
            padding: const EdgeInsets.fromLTRB(78, 18, 18, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(fontSize: 24, height: 1.05),
                    ),
                    Text(subtitle, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 30,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(7),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _Panel({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty || trailing != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Row(
                children: [
                  if (title.isNotEmpty)
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (trailing != null) const SizedBox(width: 12),
                  if (trailing != null) Flexible(child: trailing!),
                ],
              ),
            ),
          if (title.isNotEmpty || trailing != null)
            const Divider(height: 1, color: AppColors.border),
          Padding(padding: const EdgeInsets.all(18), child: child),
        ],
      ),
    );
  }
}

class _AlertChip extends StatelessWidget {
  final String label;
  final Color color;

  const _AlertChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

class _TransferInfoBox extends StatelessWidget {
  final String title;
  final String branch;
  final String project;
  final Color color;

  const _TransferInfoBox({
    required this.title,
    required this.branch,
    required this.project,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(branch, overflow: TextOverflow.ellipsis),
          Text(
            project,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.subText),
          ),
        ],
      ),
    );
  }
}

class _MasterPreview extends StatelessWidget {
  final AssetItemModel item;

  const _MasterPreview({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfff6f8fb),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _classificationColor(item.classification),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('${item.itemCode} | ${item.category}'),
              ],
            ),
          ),
          Text(item.assetClassification),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final Color color;

  const _DetailChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  final String label;
  final String value;
  final bool wide;

  const _DetailField({
    required this.label,
    required this.value,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: wide ? 720 : 230,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.subText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(value.trim().isEmpty ? '-' : value),
        ],
      ),
    );
  }
}

class _AssetTableHeader extends StatelessWidget {
  final String? operationLabel;

  const _AssetTableHeader({this.operationLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xfffff9e5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const SizedBox(width: 58, child: Text('Photo')),
          const Expanded(flex: 2, child: Text('Asset Tag ID')),
          const Expanded(flex: 3, child: Text('Description')),
          const Expanded(flex: 2, child: Text('Status')),
          const Expanded(flex: 2, child: Text('Site')),
          const Expanded(flex: 2, child: Text('Location')),
          SizedBox(width: 150, child: Text(operationLabel ?? 'Actions')),
        ],
      ),
    );
  }
}

class _AssetTableRow extends StatelessWidget {
  final AssetStockModel asset;
  final VoidCallback onDetails;
  final VoidCallback onTransfer;
  final VoidCallback onDispose;
  final VoidCallback onMaintenance;
  final String? operationLabel;
  final IconData? operationIcon;
  final VoidCallback? onOperation;

  const _AssetTableRow({
    required this.asset,
    required this.onDetails,
    required this.onTransfer,
    required this.onDispose,
    required this.onMaintenance,
    this.operationLabel,
    this.operationIcon,
    this.onOperation,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onDetails,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            SizedBox(width: 58, child: _AssetImage(path: asset.imagePath)),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _classificationColor(asset.classification),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      asset.itemCode,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xff005bd3)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(asset.name, overflow: TextOverflow.ellipsis),
            ),
            Expanded(flex: 2, child: _StatusPill(status: asset.status)),
            Expanded(flex: 2, child: Text(asset.projectName)),
            Expanded(flex: 2, child: Text(asset.location)),
            SizedBox(
              width: 150,
              child: operationLabel == null
                  ? Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Transfer',
                          onPressed: onTransfer,
                          icon: const Icon(Icons.open_with),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Maintenance',
                          onPressed: onMaintenance,
                          icon: const Icon(Icons.build),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Dispose',
                          onPressed: onDispose,
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    )
                  : ElevatedButton.icon(
                      onPressed: onOperation,
                      icon: Icon(operationIcon, size: 17, color: Colors.white),
                      label: Text(
                        operationLabel!,
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetImage extends StatelessWidget {
  final String? path;
  final double size;

  const _AssetImage({this.path, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final hasImage = path != null && path!.trim().isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.backgroundWidget,
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.network(path!, fit: BoxFit.cover)
          : const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.primaryColor,
            ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final color = normalized == 'disposed'
        ? Colors.red
        : normalized == 'maintenance'
        ? Colors.orange
        : Colors.green;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          status.isEmpty ? 'Active' : status,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _DialogAssetHeader extends StatelessWidget {
  final AssetStockModel asset;

  const _DialogAssetHeader({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xfff6f8fb),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _AssetImage(path: asset.imagePath),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('${asset.itemCode} | ${asset.location}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
