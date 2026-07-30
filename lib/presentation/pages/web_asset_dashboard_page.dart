import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/asset_excel_service.dart';
import '../../core/services/barcode_print_service.dart';
import '../../core/utils/asset_classification_utils.dart';
import '../../data/models/asset_stock_model.dart';
import '../web/data/web_asset_repository.dart';
import '../web/pages/web_asset_add_page.dart';
import '../web/utils/web_asset_colors.dart';
import '../web/widgets/web_asset_quick_view_dialog.dart';

enum WebAssetSection {
  dashboard,
  alerts,
  assets,
  inventory,
  transfer,
  dispose,
  maintenance,
}

class WebAssetDashboardPage extends StatefulWidget {
  final WebAssetSection initialSection;

  const WebAssetDashboardPage({
    super.key,
    this.initialSection = WebAssetSection.dashboard,
  });

  @override
  State<WebAssetDashboardPage> createState() => _WebAssetDashboardPageState();
}

class _WebAssetDashboardPageState extends State<WebAssetDashboardPage> {
  final webRepository = WebAssetRepository();
  final searchController = TextEditingController();
  final maintenanceTitleController = TextEditingController();
  final maintenanceDetailsController = TextEditingController();
  final maintenanceDueDateController = TextEditingController();
  final maintenanceCompletedDateController = TextEditingController();
  final maintenanceByController = TextEditingController();
  final maintenanceCostController = TextEditingController();
  final disposeDateController = TextEditingController();
  final disposeToController = TextEditingController();
  final disposeNotesController = TextEditingController();

  late WebAssetSection selectedSection;
  List<AssetStockModel> assets = [];
  List<String> branches = [];
  List<Map<String, dynamic>> maintenanceAlerts = [];
  List<Map<String, dynamic>> maintenanceRecords = [];
  String? selectedBranch;
  String searchQuery = '';
  DateTime alertMonth = DateTime(DateTime.now().year, DateTime.now().month);
  AssetStockModel? selectedMaintenanceAsset;
  String maintenanceStatus = 'Open';
  bool maintenanceRepeating = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    selectedSection = widget.initialSection;
    _loadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    maintenanceTitleController.dispose();
    maintenanceDetailsController.dispose();
    maintenanceDueDateController.dispose();
    maintenanceCompletedDateController.dispose();
    maintenanceByController.dispose();
    maintenanceCostController.dispose();
    disposeDateController.dispose();
    disposeToController.dispose();
    disposeNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      loading = true;
    });

    branches = await webRepository.getBranches();
    assets = await webRepository.getAssets();
    maintenanceAlerts = await webRepository.getMaintenanceAlertsWithinDays();
    maintenanceRecords = await webRepository.getMaintenanceRecords();

    setState(() {
      loading = false;
    });
  }

  List<AssetStockModel> get visibleAssets {
    final search = searchQuery.trim().toLowerCase();

    return assets.where((asset) {
      return _matchesBranchAndSearch(asset, search) && _isRegularAsset(asset);
    }).toList();
  }

  List<AssetStockModel> get visibleInventoryAssets {
    final search = searchQuery.trim().toLowerCase();

    return assets.where((asset) {
      return _matchesBranchAndSearch(asset, search) && _isInventoryAsset(asset);
    }).toList();
  }

  bool _matchesBranchAndSearch(AssetStockModel asset, String search) {
    final matchesBranch =
        selectedBranch == null || asset.location == selectedBranch;
    return matchesBranch && _matchesSearch(asset, search);
  }

  bool _matchesSearch(AssetStockModel asset, String search) {
    return search.isEmpty ||
        asset.name.toLowerCase().contains(search) ||
        asset.itemCode.toLowerCase().contains(search) ||
        asset.category.toLowerCase().contains(search) ||
        asset.subCategory.toLowerCase().contains(search) ||
        asset.brand.toLowerCase().contains(search) ||
        asset.status.toLowerCase().contains(search) ||
        asset.assetInventory.toLowerCase().contains(search);
  }

  bool _isInventoryAsset(AssetStockModel asset) {
    return asset.assetInventory.trim().toLowerCase() == 'inventory';
  }

  bool _isRegularAsset(AssetStockModel asset) {
    final status = asset.status.trim().toLowerCase();
    return status != 'disposed' &&
        status != 'maintenance' &&
        !_isInventoryAsset(asset);
  }

  double get totalValue {
    return visibleAssets.fold(0, (sum, asset) => sum + asset.cost);
  }

  int get activeCount {
    return visibleAssets.length;
  }

  int get disposedCount {
    return assets.where((asset) {
      final search = searchQuery.trim().toLowerCase();
      return _matchesBranchAndSearch(asset, search) &&
          asset.status.toLowerCase() == 'disposed';
    }).length;
  }

  int get maintenanceCount {
    return assets.where((asset) {
      final search = searchQuery.trim().toLowerCase();
      return _matchesBranchAndSearch(asset, search) &&
          asset.status.toLowerCase() == 'maintenance';
    }).length;
  }

  int get alertCount {
    return maintenanceAlerts.length;
  }

  Future<void> _addAsset() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => WebAssetAddPage(initialBranch: selectedBranch),
      ),
    );

    if (result == true) {
      await _loadData();
    }
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
    final printableAssets = visibleAssets.where((asset) {
      return AssetClassificationUtils.canPrintBarcode(
        asset.assetClassification,
      );
    }).toList();

    if (printableAssets.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No printable assets found')),
      );
      return;
    }

    final classification = await _selectPrintClassification(printableAssets);
    if (classification == null) return;

    final assetsToPrint = classification == '__all__'
        ? printableAssets
        : printableAssets.where((asset) {
            return asset.classification.trim().toLowerCase() ==
                classification.trim().toLowerCase();
          }).toList();

    if (assetsToPrint.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No assets found for this print option')),
      );
      return;
    }

    final pdf = await BarcodePrintService.generateBarcodePdf(
      assets: assetsToPrint,
    );
    await Printing.layoutPdf(onLayout: (_) async => pdf);
  }

  Future<String?> _selectPrintClassification(
    List<AssetStockModel> printableAssets,
  ) async {
    final classifications =
        printableAssets
            .map((asset) => asset.classification.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Print Barcodes'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.select_all),
                  title: const Text('All Trackable Assets'),
                  subtitle: Text('${printableAssets.length} assets'),
                  onTap: () => Navigator.pop(context, '__all__'),
                ),
                const Divider(),
                ...classifications.map((classification) {
                  final count = printableAssets.where((asset) {
                    return asset.classification.trim().toLowerCase() ==
                        classification.toLowerCase();
                  }).length;

                  return ListTile(
                    leading: Icon(
                      Icons.circle,
                      size: 16,
                      color: AssetClassificationUtils.classificationColor(
                        classification,
                      ),
                    ),
                    title: Text(
                      classification,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AssetClassificationUtils.classificationColor(
                          classification,
                        ),
                      ),
                    ),
                    subtitle: Text('$count assets'),
                    onTap: () => Navigator.pop(context, classification),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAssetDetails(AssetStockModel asset) async {
    await showDialog<void>(
      context: context,
      builder: (context) =>
          WebAssetQuickViewDialog(asset: asset, onRefresh: _loadData),
    );
  }

  Future<void> _transferAsset(AssetStockModel asset) async {
    String branch = selectedBranch ?? asset.location;

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
                            project: branch,
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

                        setDialogState(() {
                          branch = value;
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
                  onPressed: () => Navigator.pop(context, true),
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

    if (result != true) return;

    await webRepository.transferAsset(
      itemCode: asset.itemCode,
      branch: branch,
      project: branch,
    );
    await webRepository.addActivityLog(
      itemCode: asset.itemCode,
      action: 'transfer',
      description: 'Transferred from ${asset.location} to $branch',
      fromBranch: asset.location,
      toBranch: branch,
      metadata: {'previous_project': asset.projectName},
    );

    await _loadData();
  }

  Future<void> _disposeAsset(AssetStockModel asset) async {
    await webRepository.updateStatus(
      itemCode: asset.itemCode,
      status: 'Disposed',
    );
    await webRepository.addActivityLog(
      itemCode: asset.itemCode,
      action: 'dispose',
      description: disposeNotesController.text.isEmpty
          ? 'Disposed asset'
          : disposeNotesController.text,
      fromBranch: asset.location,
      toBranch: asset.location,
      metadata: {
        'dispose_to': disposeToController.text,
        'disposed_date': disposeDateController.text,
      },
    );

    await _loadData();
  }

  Future<void> _maintenanceAsset(AssetStockModel asset) async {
    final cost =
        double.tryParse(maintenanceCostController.text.replaceAll(',', '')) ??
        0;

    await webRepository.addMaintenanceRecord(
      asset: asset,
      title: maintenanceTitleController.text,
      details: maintenanceDetailsController.text,
      maintenanceStatus: maintenanceStatus,
      dueDate: maintenanceDueDateController.text,
      completedDate: maintenanceCompletedDateController.text,
      maintenanceBy: maintenanceByController.text,
      cost: cost,
      repeating: maintenanceRepeating,
    );
    await webRepository.updateStatus(
      itemCode: asset.itemCode,
      status: 'Maintenance',
    );
    await webRepository.addActivityLog(
      itemCode: asset.itemCode,
      action: 'maintenance',
      description: maintenanceTitleController.text.isEmpty
          ? 'Maintenance added'
          : maintenanceTitleController.text,
      fromBranch: asset.location,
      toBranch: asset.location,
      metadata: {
        'status': maintenanceStatus,
        'due_date': maintenanceDueDateController.text,
        'completed_date': maintenanceCompletedDateController.text,
        'cost': cost,
        'repeating': maintenanceRepeating,
      },
    );

    maintenanceTitleController.clear();
    maintenanceDetailsController.clear();
    maintenanceDueDateController.clear();
    maintenanceCompletedDateController.clear();
    maintenanceByController.clear();
    maintenanceCostController.clear();
    setState(() {
      selectedMaintenanceAsset = null;
      maintenanceStatus = 'Open';
      maintenanceRepeating = false;
    });

    await _loadData();
  }

  void _resetDisposeForm() {
    disposeDateController.clear();
    disposeToController.clear();
    disposeNotesController.clear();
  }

  Future<void> _openDisposeAssetPicker() async {
    final picked = await showDialog<AssetStockModel>(
      context: context,
      builder: (context) {
        var dialogBranch = selectedBranch;
        var dialogSearch = '';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = assets.where((asset) {
              final search = dialogSearch.trim().toLowerCase();
              return _matchesSearch(asset, search) &&
                  _isRegularAsset(asset) &&
                  (dialogBranch == null || asset.location == dialogBranch);
            }).toList();

            return AlertDialog(
              backgroundColor: Colors.white,
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
              contentPadding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              title: Row(
                children: [
                  const Expanded(child: Text('Select Assets')),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              content: SizedBox(
                width: 900,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            onChanged: (value) {
                              setDialogState(() {
                                dialogSearch = value;
                              });
                            },
                            decoration: const InputDecoration(
                              hintText: 'Search...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: dialogBranch,
                            decoration: const InputDecoration(
                              labelText: 'Branch',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('All Branches'),
                              ),
                              ...branches.map(
                                (branch) => DropdownMenuItem<String>(
                                  value: branch,
                                  child: Text(branch),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setDialogState(() {
                                dialogBranch = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _AssetTableHeader(operationLabel: 'Dispose'),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: SingleChildScrollView(
                        child: Column(
                          children: filtered.isEmpty
                              ? const [
                                  SizedBox(
                                    height: 140,
                                    child: Center(
                                      child: Text('No available assets'),
                                    ),
                                  ),
                                ]
                              : filtered.take(10).map((asset) {
                                  return _AssetTableRow(
                                    asset: asset,
                                    operationLabel: 'Select',
                                    operationIcon: Icons.add_circle_outline,
                                    onOperation: () =>
                                        Navigator.pop(context, asset),
                                    onDetails: () {},
                                    onTransfer: () {},
                                    onDispose: () {},
                                    onMaintenance: () {},
                                  );
                                }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked == null) return;
    await _openDisposeDetailsDialog(picked);
  }

  Future<void> _openDisposeDetailsDialog(AssetStockModel asset) async {
    _resetDisposeForm();
    disposeDateController.text = _formatPickerDate(DateTime.now());

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 36,
                vertical: 28,
              ),
              titlePadding: const EdgeInsets.fromLTRB(26, 22, 16, 10),
              contentPadding: const EdgeInsets.fromLTRB(26, 8, 26, 18),
              actionsPadding: const EdgeInsets.fromLTRB(26, 0, 26, 22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              title: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.change_circle_outlined,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Dispose Asset'),
                        const SizedBox(height: 3),
                        Text(
                          '${asset.name} | ${asset.itemCode}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.subText,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              content: SizedBox(
                width: 760,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xfffffbfb),
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          _AssetImage(path: asset.imagePath),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Wrap(
                              spacing: 24,
                              runSpacing: 8,
                              children: [
                                _DialogInfo(
                                  label: 'Status',
                                  value: asset.status,
                                ),
                                _DialogInfo(
                                  label: 'Site',
                                  value: asset.projectName,
                                ),
                                _DialogInfo(
                                  label: 'Location',
                                  value: asset.location,
                                ),
                                _DialogInfo(
                                  label: 'Category',
                                  value: asset.category,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _DateTextField(
                                controller: disposeDateController,
                                label: 'Date Disposed *',
                                onTap: () => _pickDateInto(
                                  disposeDateController,
                                  setDialogState,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: disposeToController,
                                decoration: _inputDecoration('Dispose to'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: TextField(
                            controller: disposeNotesController,
                            minLines: 5,
                            maxLines: 5,
                            decoration: _inputDecoration('Notes'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (disposeDateController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Date Disposed is required'),
                        ),
                      );
                      return;
                    }

                    await _disposeAsset(asset);
                    if (!context.mounted) return;
                    Navigator.pop(context, true);
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  label: const Text(
                    'Dispose',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 15,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) {
      _resetDisposeForm();
    }
  }

  void _resetMaintenanceForm() {
    maintenanceTitleController.clear();
    maintenanceDetailsController.clear();
    maintenanceDueDateController.clear();
    maintenanceCompletedDateController.clear();
    maintenanceByController.clear();
    maintenanceCostController.clear();
    setState(() {
      selectedMaintenanceAsset = null;
      maintenanceStatus = 'Open';
      maintenanceRepeating = false;
    });
  }

  String _formatPickerDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  DateTime? _maintenanceRecordDate(Map<String, dynamic> record) {
    final value =
        record['completed_date']?.toString() ??
        record['due_date']?.toString() ??
        record['created_at']?.toString();
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  String _formatDisplayDate(String? value) {
    if (value == null || value.trim().isEmpty) return '-';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return _formatPickerDate(parsed.toLocal());
  }

  AssetStockModel? _assetByItemCode(String itemCode) {
    for (final asset in assets) {
      if (asset.itemCode == itemCode) return asset;
    }
    return null;
  }

  Future<void> _pickDateInto(
    TextEditingController controller,
    StateSetter setDialogState,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(controller.text) ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 20),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.headerText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;
    setDialogState(() {
      controller.text = _formatPickerDate(picked);
    });
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
      backgroundColor: const Color(0xfff4f7fb),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              _Sidebar(
                section: selectedSection,
                alertCount: alertCount,
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
                          ? const Center(child: CircularProgressIndicator())
                          : SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                22,
                                20,
                                22,
                                32,
                              ),
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 1540,
                                  ),
                                  child: _content(),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _content() {
    switch (selectedSection) {
      case WebAssetSection.assets:
        return _assetsPanel();
      case WebAssetSection.inventory:
        return _inventoryPanel();
      case WebAssetSection.alerts:
        return _alertsPanel();
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
        return _disposePanel();
      case WebAssetSection.maintenance:
        return _maintenancePanel();
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
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'dashboard & statistics',
          style: TextStyle(fontSize: 13, color: AppColors.subText),
        ),
        const SizedBox(height: 14),
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
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                icon: Icons.payments_outlined,
                color: Colors.redAccent,
                title: 'Value of Assets',
                value: totalValue.toStringAsFixed(2),
                subtitle: 'AED',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                icon: Icons.delete_outline,
                color: Colors.orange,
                title: 'Disposed Assets',
                value: disposedCount.toString(),
                subtitle: 'Archived in place',
              ),
            ),
            const SizedBox(width: 12),
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
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _categoryPanel()),
            const SizedBox(width: 14),
            Expanded(child: _alertPanel()),
          ],
        ),
        const SizedBox(height: 14),
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
                  padding: const EdgeInsets.only(bottom: 11),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 140,
                        child: Text(
                          entry.key,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            minHeight: 12,
                            borderRadius: BorderRadius.circular(99),
                            value: percent,
                            color: AppColors.primaryColor,
                            backgroundColor: AppColors.backgroundWidget,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 24,
                        child: Text(
                          entry.value.toString(),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
  }

  Future<void> _showMaintenanceRecordDialog(Map<String, dynamic> record) async {
    final itemCode = record['item_code']?.toString() ?? '';
    final asset = _assetByItemCode(itemCode);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 36,
            vertical: 28,
          ),
          titlePadding: const EdgeInsets.fromLTRB(22, 18, 12, 12),
          contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
          actionsPadding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
          title: Row(
            children: [
              const Expanded(
                child: Text(
                  'Asset Maintenance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          content: SizedBox(
            width: 640,
            child: DefaultTabController(
              length: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TabBar(
                    labelColor: AppColors.headerText,
                    unselectedLabelColor: AppColors.headerText,
                    indicatorColor: Color(0xffffbd0a),
                    indicatorWeight: 2,
                    tabs: [
                      Tab(text: 'Maintenance Details'),
                      Tab(text: 'Asset Details'),
                    ],
                  ),
                  Container(
                    height: 330,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TabBarView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: SingleChildScrollView(
                            child: _InfoTable(
                              rows: [
                                _InfoRow(
                                  'Title',
                                  record['title']?.toString() ?? '-',
                                ),
                                _InfoRow(
                                  'Details',
                                  record['details']?.toString() ?? '-',
                                ),
                                _InfoRow(
                                  'Due Date',
                                  _formatDisplayDate(
                                    record['due_date']?.toString(),
                                  ),
                                ),
                                _InfoRow(
                                  'Maintenance By',
                                  record['maintenance_by']?.toString() ?? '-',
                                ),
                                _InfoRow(
                                  'Maintenance Status',
                                  record['status']?.toString() ?? '-',
                                ),
                                _InfoRow(
                                  'Date completed',
                                  _formatDisplayDate(
                                    record['completed_date']?.toString(),
                                  ),
                                ),
                                _InfoRow(
                                  'Maintenance Cost',
                                  record['cost']?.toString() ?? '-',
                                ),
                                _InfoRow(
                                  'Repeating',
                                  record['repeating'] == true ? 'Yes' : 'No',
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: asset == null
                              ? Center(
                                  child: Text(
                                    itemCode.isEmpty
                                        ? 'Asset not found'
                                        : 'Asset $itemCode not found',
                                  ),
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 150,
                                      child: _LargeAssetImage(
                                        path: asset.imagePath,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: _InfoTable(
                                          rows: [
                                            _InfoRow(
                                              'Asset Tag ID',
                                              asset.itemCode,
                                            ),
                                            _InfoRow('Description', asset.name),
                                            _InfoRow(
                                              'Purchase Date',
                                              _formatPickerDate(
                                                asset.createdAt,
                                              ),
                                            ),
                                            const _InfoRow(
                                              'Purchased from',
                                              '-',
                                            ),
                                            _InfoRow(
                                              'Cost',
                                              asset.cost.toStringAsFixed(2),
                                            ),
                                            _InfoRow('Brand', asset.brand),
                                            _InfoRow('Model', asset.model),
                                            _InfoRow(
                                              'Serial No',
                                              asset.serialNo,
                                            ),
                                            _InfoRow('Site', asset.projectName),
                                            _InfoRow(
                                              'Location',
                                              asset.location,
                                            ),
                                            _InfoRow(
                                              'Category',
                                              asset.category,
                                            ),
                                            _InfoRow(
                                              'Sub Category',
                                              asset.subCategory,
                                            ),
                                            const _InfoRow('Department', '-'),
                                            _InfoRow('Status', asset.status),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (asset != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showAssetDetails(asset);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffffbd0a),
                  foregroundColor: Colors.black,
                ),
                child: const Text('More Details'),
              ),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _alertPanel() {
    final monthStart = DateTime(alertMonth.year, alertMonth.month);
    final gridStart = monthStart.subtract(
      Duration(days: monthStart.weekday % 7),
    );
    final monthLabel =
        '${_monthName(alertMonth.month).toUpperCase()} ${alertMonth.year}';
    final recordsByDate = <String, List<Map<String, dynamic>>>{};

    for (final record in maintenanceRecords) {
      final recordBranch = record['branch']?.toString() ?? '';
      if (selectedBranch != null && recordBranch != selectedBranch) continue;
      final date = _maintenanceRecordDate(record);
      if (date == null) continue;
      final key = _dateKey(date);
      recordsByDate.putIfAbsent(key, () => []).add(record);
    }

    return _Panel(
      title: 'Alert',
      trailing: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _AlertChip(label: 'Assets Due', color: Color(0xff4f83ff)),
            SizedBox(width: 5),
            _AlertChip(label: 'Maintenance', color: Color(0xff8e54c9)),
            SizedBox(width: 5),
            _AlertChip(label: 'Warranty', color: Color(0xffff6868)),
            SizedBox(width: 5),
            _AlertChip(label: 'Lease', color: Color(0xffffb23f)),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(42, 34),
                  padding: EdgeInsets.zero,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    alertMonth = DateTime(
                      alertMonth.year,
                      alertMonth.month - 1,
                    );
                  });
                },
                child: const Icon(Icons.chevron_left, size: 19),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(42, 34),
                  padding: EdgeInsets.zero,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    alertMonth = DateTime(
                      alertMonth.year,
                      alertMonth.month + 1,
                    );
                  });
                },
                child: const Icon(Icons.chevron_right, size: 19),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    monthLabel,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffffbd0a),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'month',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              _CalendarDayHeader('Sun'),
              _CalendarDayHeader('Mon'),
              _CalendarDayHeader('Tue'),
              _CalendarDayHeader('Wed'),
              _CalendarDayHeader('Thu'),
              _CalendarDayHeader('Fri'),
              _CalendarDayHeader('Sat'),
            ],
          ),
          SizedBox(
            height: 352,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.15,
              ),
              itemCount: 42,
              itemBuilder: (context, index) {
                final date = gridStart.add(Duration(days: index));
                final isCurrentMonth = date.month == alertMonth.month;
                final today = DateTime.now();
                final isToday =
                    date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                final records = recordsByDate[_dateKey(date)] ?? const [];

                return Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isToday ? const Color(0xfffff7de) : Colors.white,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        date.day.toString(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isCurrentMonth
                              ? const Color(0xff0051c8)
                              : const Color(0xffaac8ef),
                        ),
                      ),
                      const SizedBox(height: 5),
                      ...records.take(2).map((record) {
                        final itemCode = record['asset_name']?.toString() ?? '';
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: InkWell(
                            onTap: () => _showMaintenanceRecordDialog(record),
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xff9b55c7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                itemCode.isEmpty ? 'Maintenance' : itemCode,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      if (records.length > 2)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '+${records.length - 2} more',
                            style: const TextStyle(
                              color: AppColors.subText,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
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
        width: 280,
        child: TextField(
          controller: searchController,
          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search Assets',
            prefixIcon: const Icon(Icons.search, size: 20),
            filled: true,
            fillColor: const Color(0xfff8fafc),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
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
                onDispose: () => _openDisposeDetailsDialog(asset),
                onMaintenance: () => _openMaintenanceDetailsDialog(asset),
              );
            }),
        ],
      ),
    );
  }

  Widget _inventoryPanel() {
    return _Panel(
      title: 'Inventory',
      trailing: SizedBox(
        width: 280,
        child: TextField(
          controller: searchController,
          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search Inventory',
            prefixIcon: const Icon(Icons.search, size: 20),
            filled: true,
            fillColor: const Color(0xfff8fafc),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ),
      child: Column(
        children: [
          _AssetTableHeader(),
          if (visibleInventoryAssets.isEmpty)
            const SizedBox(
              height: 180,
              child: Center(child: Text('No inventory items found')),
            )
          else
            ...visibleInventoryAssets.map((asset) {
              return _AssetTableRow(
                asset: asset,
                onDetails: () => _showAssetDetails(asset),
                onTransfer: () => _transferAsset(asset),
                onDispose: () => _openDisposeDetailsDialog(asset),
                onMaintenance: () => _openMaintenanceDetailsDialog(asset),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _openMaintenanceAssetPicker() async {
    final picked = await showDialog<AssetStockModel>(
      context: context,
      builder: (context) {
        var dialogBranch = selectedBranch;
        var dialogSearch = '';
        AssetStockModel? selected;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = assets.where((asset) {
              final search = dialogSearch.trim().toLowerCase();
              return _matchesSearch(asset, search) &&
                  _isRegularAsset(asset) &&
                  (dialogBranch == null || asset.location == dialogBranch);
            }).toList();

            return AlertDialog(
              backgroundColor: Colors.white,
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
              contentPadding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              title: Row(
                children: [
                  const Expanded(child: Text('Select Assets')),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              content: SizedBox(
                width: 900,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            onChanged: (value) {
                              setDialogState(() {
                                dialogSearch = value;
                              });
                            },
                            decoration: const InputDecoration(
                              hintText: 'Search...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: dialogBranch,
                            decoration: const InputDecoration(
                              labelText: 'Branch',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('All Branches'),
                              ),
                              ...branches.map(
                                (branch) => DropdownMenuItem<String>(
                                  value: branch,
                                  child: Text(branch),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setDialogState(() {
                                dialogBranch = value;
                                selected = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Show 10 entries'),
                    const SizedBox(height: 8),
                    _AssetTableHeader(operationLabel: 'Select'),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: SingleChildScrollView(
                        child: Column(
                          children: filtered.isEmpty
                              ? const [
                                  SizedBox(
                                    height: 140,
                                    child: Center(
                                      child: Text('No available assets'),
                                    ),
                                  ),
                                ]
                              : filtered.take(10).map((asset) {
                                  final isSelected =
                                      selected?.itemCode == asset.itemCode;
                                  return Container(
                                    color: isSelected
                                        ? const Color(0xfffff8de)
                                        : null,
                                    child: _AssetTableRow(
                                      asset: asset,
                                      operationLabel: isSelected
                                          ? 'Selected'
                                          : 'Select',
                                      operationIcon: isSelected
                                          ? Icons.check_circle
                                          : Icons.add_circle_outline,
                                      onOperation: () {
                                        setDialogState(() {
                                          selected = asset;
                                        });
                                        Navigator.pop(context, asset);
                                      },
                                      onDetails: () {},
                                      onTransfer: () {},
                                      onDispose: () {},
                                      onMaintenance: () {},
                                    ),
                                  );
                                }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: selected == null
                      ? null
                      : () => Navigator.pop(context, selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffffbd0a),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('Add to List'),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked == null) return;
    await _openMaintenanceDetailsDialog(picked);
  }

  Future<void> _openMaintenanceDetailsDialog(AssetStockModel asset) async {
    maintenanceTitleController.text = asset.name;
    maintenanceDetailsController.clear();
    maintenanceDueDateController.clear();
    maintenanceCompletedDateController.clear();
    maintenanceByController.clear();
    maintenanceCostController.text = asset.cost == 0
        ? ''
        : asset.cost.toStringAsFixed(2);

    var dialogStatus = maintenanceStatus;
    var dialogRepeating = maintenanceRepeating;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 36,
                vertical: 28,
              ),
              titlePadding: const EdgeInsets.fromLTRB(26, 22, 16, 10),
              contentPadding: const EdgeInsets.fromLTRB(26, 8, 26, 18),
              actionsPadding: const EdgeInsets.fromLTRB(26, 0, 26, 22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              title: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.settings_suggest_outlined,
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Add Maintenance'),
                        const SizedBox(height: 3),
                        Text(
                          '${asset.name} | ${asset.itemCode}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.subText,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              content: SizedBox(
                width: 820,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xfff7fbff),
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          _AssetImage(path: asset.imagePath),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Wrap(
                              spacing: 24,
                              runSpacing: 8,
                              children: [
                                _DialogInfo(
                                  label: 'Status',
                                  value: asset.status,
                                ),
                                _DialogInfo(
                                  label: 'Site',
                                  value: asset.projectName,
                                ),
                                _DialogInfo(
                                  label: 'Location',
                                  value: asset.location,
                                ),
                                _DialogInfo(
                                  label: 'Category',
                                  value: asset.category,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              TextField(
                                controller: maintenanceTitleController,
                                decoration: _inputDecoration(
                                  'Maintenance Title *',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: maintenanceDetailsController,
                                minLines: 4,
                                maxLines: 5,
                                decoration: _inputDecoration(
                                  'Maintenance Details',
                                ),
                              ),
                              const SizedBox(height: 12),
                              _DateTextField(
                                controller: maintenanceDueDateController,
                                label: 'Maint. Due Date',
                                onTap: () => _pickDateInto(
                                  maintenanceDueDateController,
                                  setDialogState,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: maintenanceByController,
                                decoration: _inputDecoration('Maintenance By'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            children: [
                              DropdownButtonFormField<String>(
                                initialValue: dialogStatus,
                                decoration: _inputDecoration(
                                  'Maintenance Status',
                                ),
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
                                    dialogStatus = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              _DateTextField(
                                controller: maintenanceCompletedDateController,
                                label: 'Date completed',
                                onTap: () => _pickDateInto(
                                  maintenanceCompletedDateController,
                                  setDialogState,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: maintenanceCostController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: _inputDecoration(
                                  'Maintenance Cost',
                                ).copyWith(prefixText: 'AED  '),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Text('Repeating'),
                                  const SizedBox(width: 18),
                                  Radio<bool>(
                                    value: true,
                                    groupValue: dialogRepeating,
                                    onChanged: (value) {
                                      setDialogState(() {
                                        dialogRepeating = value ?? false;
                                      });
                                    },
                                  ),
                                  const Text('Yes'),
                                  const SizedBox(width: 8),
                                  Radio<bool>(
                                    value: false,
                                    groupValue: dialogRepeating,
                                    onChanged: (value) {
                                      setDialogState(() {
                                        dialogRepeating = value ?? false;
                                      });
                                    },
                                  ),
                                  const Text('No'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (maintenanceTitleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Maintenance Title is required'),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      selectedMaintenanceAsset = asset;
                      maintenanceStatus = dialogStatus;
                      maintenanceRepeating = dialogRepeating;
                    });
                    await _maintenanceAsset(asset);
                    if (!context.mounted) return;
                    Navigator.pop(context, true);
                  },
                  icon: const Icon(Icons.add, color: Colors.black),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffffbd0a),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 15,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) {
      _resetMaintenanceForm();
    }
  }

  Widget _alertsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flag_outlined, color: Colors.deepOrange),
            const SizedBox(width: 12),
            const Text(
              'Alerts',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 12),
            if (alertCount > 0)
              CircleAvatar(
                radius: 15,
                backgroundColor: Colors.redAccent,
                child: Text(
                  alertCount.toString(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        _Panel(
          title: 'Maintenance due in 3 days',
          child: maintenanceAlerts.isEmpty
              ? const SizedBox(
                  height: 160,
                  child: Center(child: Text('No maintenance alerts')),
                )
              : Column(
                  children: maintenanceAlerts.map((alert) {
                    final itemCode = alert['item_code']?.toString() ?? '';
                    AssetStockModel? asset;
                    for (final candidate in assets) {
                      if (candidate.itemCode == itemCode) {
                        asset = candidate;
                        break;
                      }
                    }
                    final date =
                        alert['completed_date']?.toString() ??
                        alert['due_date']?.toString() ??
                        '-';

                    final tappedAsset = asset;

                    return ListTile(
                      leading: const Icon(
                        Icons.settings_suggest_outlined,
                        color: Colors.deepOrange,
                      ),
                      title: Text(
                        '${alert['asset_name'] ?? itemCode} - $itemCode',
                      ),
                      subtitle: Text(
                        'Complete date: $date | ${alert['branch'] ?? '-'}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: tappedAsset == null
                          ? null
                          : () {
                              setState(() {
                                selectedSection = WebAssetSection.assets;
                              });
                              _showAssetDetails(tappedAsset);
                            },
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _disposePanel() {
    final search = searchQuery.trim().toLowerCase();
    final disposedAssets = assets.where((asset) {
      return _matchesBranchAndSearch(asset, search) &&
          asset.status.trim().toLowerCase() == 'disposed';
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.change_circle_outlined, color: Colors.deepOrange),
            const SizedBox(width: 12),
            const Text(
              'Dispose',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _openDisposeAssetPicker,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Select Assets',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff3ec37b),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _Panel(
          title: '',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search disposed assets',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 15,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          '${disposedAssets.length} disposed',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xfffffbfb),
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Select an asset to document disposal. Only assets already marked as Disposed stay listed here.',
                  style: TextStyle(color: AppColors.subText),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Assets Pending Disposal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  Text(
                    '${disposedAssets.length} records',
                    style: const TextStyle(color: AppColors.subText),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _AssetTableHeader(operationLabel: 'Dispose'),
              if (disposedAssets.isEmpty)
                const SizedBox(
                  height: 180,
                  child: Center(child: Text('No disposed assets found')),
                )
              else
                ...disposedAssets.map((asset) {
                  return _AssetTableRow(
                    asset: asset,
                    operationLabel: 'Edit',
                    operationIcon: Icons.edit,
                    onOperation: () => _openDisposeDetailsDialog(asset),
                    onDetails: () => _showAssetDetails(asset),
                    onTransfer: () => _transferAsset(asset),
                    onDispose: () => _openDisposeDetailsDialog(asset),
                    onMaintenance: () => _openMaintenanceDetailsDialog(asset),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _maintenancePanel() {
    final search = searchQuery.trim().toLowerCase();
    final maintenanceAssets = assets.where((asset) {
      return _matchesBranchAndSearch(asset, search) &&
          asset.status.trim().toLowerCase() == 'maintenance';
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.settings_suggest_outlined,
              color: Colors.deepOrange,
            ),
            const SizedBox(width: 12),
            const Text(
              'Maintenance',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _openMaintenanceAssetPicker,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Select Assets',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff3ec37b),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _Panel(
          title: '',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search maintenance assets',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 15,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.build, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          '${maintenanceAssets.length} in maintenance',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xfff8fbff),
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Select an asset to open the maintenance form. Only assets currently marked as Maintenance stay listed here.',
                  style: TextStyle(color: AppColors.subText),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Assets Pending Maintenance',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  Text(
                    '${maintenanceAssets.length} records',
                    style: const TextStyle(color: AppColors.subText),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _AssetTableHeader(operationLabel: 'Maintenance'),
              if (maintenanceAssets.isEmpty)
                const SizedBox(
                  height: 180,
                  child: Center(child: Text('No assets pending maintenance')),
                )
              else
                ...maintenanceAssets.map((asset) {
                  return _AssetTableRow(
                    asset: asset,
                    operationLabel: 'Edit',
                    operationIcon: Icons.edit,
                    onOperation: () => _openMaintenanceDetailsDialog(asset),
                    onDetails: () => _showAssetDetails(asset),
                    onTransfer: () => _transferAsset(asset),
                    onDispose: () => _openDisposeDetailsDialog(asset),
                    onMaintenance: () => _openMaintenanceDetailsDialog(asset),
                  );
                }),
            ],
          ),
        ),
      ],
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
              //  Text(description),
              /*   const SizedBox(height: 18),
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
              ),*/
              const SizedBox(height: 20),
              Text(
                'Select Asset For $title',
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
                  onDispose: () => _openDisposeDetailsDialog(asset),
                  onMaintenance: () => _openMaintenanceDetailsDialog(asset),
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
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Image.asset('assets/images/icon.png', height: 42, width: 50),
          const SizedBox(width: 12),
          const Text(
            'Asset Stock Taking',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(width: 26),
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
            width: 210,
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
          IconButton(
            tooltip: 'Refresh',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: 22),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final WebAssetSection section;
  final int alertCount;
  final ValueChanged<WebAssetSection> onSelected;

  const _Sidebar({
    required this.section,
    required this.alertCount,
    required this.onSelected,
  });

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
            height: 88,
            padding: const EdgeInsets.fromLTRB(22, 26, 18, 20),
            color: AppColors.primaryColor,
            child: const Text(
              'Al Ain Pharmacy',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
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
            badge: alertCount > 0 ? alertCount.toString() : null,
            selected: section == WebAssetSection.alerts,
            onTap: () => onSelected(WebAssetSection.alerts),
          ),
          _SidebarGroup(selected: section, onSelected: onSelected),
          _SidebarItem(
            icon: Icons.inventory_2_outlined,
            label: 'Inventory',
            selected: section == WebAssetSection.inventory,
            onTap: () => onSelected(WebAssetSection.inventory),
          ),
          /*  _SidebarItem(
            icon: Icons.list_alt_outlined,
            label: 'Lists',
            selected: false,
            onTap: () => onSelected(WebAssetSection.assets),
          ),*/
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
              size: 20,
              color: selected ? Colors.deepOrange : Colors.deepOrange,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (badge != null)
              CircleAvatar(
                radius: 13,
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
        height: 38,
        color: selected ? const Color(0xfffff4ce) : Colors.white,
        padding: const EdgeInsets.only(left: 52, right: 18),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.deepOrange),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.text),
            ),
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
            Icon(icon, size: 21, color: AppColors.secondaryColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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
      height: 88,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(9),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.16),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.12,
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    height: 1,
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.subText,
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty || trailing != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
              child: Row(
                children: [
                  if (title.isNotEmpty)
                    if (trailing == null)
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      )
                    else
                      Flexible(
                        fit: FlexFit.loose,
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                  if (trailing != null) const SizedBox(width: 10),
                  if (trailing != null)
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: trailing!,
                      ),
                    ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CalendarDayHeader extends StatelessWidget {
  final String label;

  const _CalendarDayHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xfffffbec),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);
}

class _InfoTable extends StatelessWidget {
  final List<_InfoRow> rows;

  const _InfoTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {0: FixedColumnWidth(150), 1: FlexColumnWidth()},
      border: TableBorder.all(color: AppColors.border),
      children: rows.map((row) {
        return TableRow(
          children: [
            Container(
              color: const Color(0xfffff9e5),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              child: Text(row.label),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              child: Text(row.value.trim().isEmpty ? '-' : row.value),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _LargeAssetImage extends StatelessWidget {
  final String? path;

  const _LargeAssetImage({this.path});

  @override
  Widget build(BuildContext context) {
    final hasImage = path != null && path!.trim().isNotEmpty;

    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.backgroundWidget,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.network(path!, fit: BoxFit.cover)
          : const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.primaryColor,
              size: 42,
            ),
    );
  }
}

class _DialogInfo extends StatelessWidget {
  final String label;
  final String value;

  const _DialogInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final shownValue = value.trim().isEmpty ? '-' : value;

    return SizedBox(
      width: 155,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.subText),
          ),
          const SizedBox(height: 3),
          Text(
            shownValue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _DateTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final VoidCallback onTap;

  const _DateTextField({
    required this.controller,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          tooltip: label,
          onPressed: onTap,
          icon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primaryColor),
        ),
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

class _AssetTableHeader extends StatelessWidget {
  final String? operationLabel;

  const _AssetTableHeader({this.operationLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xfffffbec),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          const SizedBox(width: 54, child: _TableHeaderText('Photo')),
          const Expanded(flex: 2, child: _TableHeaderText('Asset Tag ID')),
          const Expanded(flex: 3, child: _TableHeaderText('Description')),
          const Expanded(flex: 2, child: _TableHeaderText('Status')),
          const Expanded(flex: 2, child: _TableHeaderText('Site')),
          const Expanded(flex: 2, child: _TableHeaderText('Location')),
          SizedBox(
            width: 138,
            child: _TableHeaderText(operationLabel ?? 'Actions'),
          ),
        ],
      ),
    );
  }
}

class _TableHeaderText extends StatelessWidget {
  final String label;

  const _TableHeaderText(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            SizedBox(width: 54, child: _AssetImage(path: asset.imagePath)),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  SizedBox(width: 10),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: WebAssetColors.classification(
                        asset.classification,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      asset.itemCode,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff005bd3),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                asset.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5),
              ),
            ),
            Expanded(flex: 2, child: _StatusPill(status: asset.status)),
            Expanded(
              flex: 2,
              child: Text(
                asset.projectName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                asset.location,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5),
              ),
            ),
            SizedBox(
              width: 138,
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

  const _AssetImage({this.path});

  @override
  Widget build(BuildContext context) {
    final hasImage = path != null && path!.trim().isNotEmpty;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.backgroundWidget,
        borderRadius: BorderRadius.circular(6),
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
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
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
