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
import '../web/utils/web_page_route.dart';
import '../web/widgets/web_asset_quick_view_dialog.dart';
import '../web/widgets/web_hover_surface.dart';

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
  static const int _assetsPerPage = 50;

  final webRepository = WebAssetRepository();
  final searchController = TextEditingController();
  final contentScrollController = ScrollController();
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
  String? selectedStatus;
  DateTime alertMonth = DateTime(DateTime.now().year, DateTime.now().month);
  AssetStockModel? selectedMaintenanceAsset;
  String maintenanceStatus = 'Open';
  bool maintenanceRepeating = false;
  bool loading = true;
  bool sectionLoading = false;
  WebAssetSection? pendingSection;
  final Map<WebAssetSection, int> _sectionPages = {};

  @override
  void initState() {
    super.initState();
    selectedSection = widget.initialSection;
    _loadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    contentScrollController.dispose();
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

    final branchesFuture = webRepository.getBranches();
    final assetsFuture = webRepository.getAssets();
    final alertsFuture = webRepository.getMaintenanceAlertsWithinDays();
    final recordsFuture = webRepository.getMaintenanceRecords();

    final loadedBranches = await branchesFuture;
    final loadedAssets = await assetsFuture;

    if (!mounted) return;

    setState(() {
      branches = loadedBranches;
      assets = loadedAssets;
      _sectionPages.clear();
      loading = false;
    });

    final loadedAlerts = await alertsFuture;
    final loadedRecords = await recordsFuture;

    if (!mounted) return;
    setState(() {
      maintenanceAlerts = loadedAlerts;
      maintenanceRecords = loadedRecords;
    });
  }

  Future<void> _selectSection(WebAssetSection section) async {
    if (section == selectedSection || sectionLoading) return;

    setState(() {
      sectionLoading = true;
      pendingSection = section;
      selectedStatus = null;
      searchQuery = '';
      searchController.clear();
    });
    await WidgetsBinding.instance.endOfFrame;

    if (!mounted) return;
    setState(() {
      selectedSection = section;
      _sectionPages[section] = 0;
    });
    await Future<void>.delayed(const Duration(milliseconds: 120));

    if (!mounted) return;
    setState(() {
      sectionLoading = false;
      pendingSection = null;
    });
    _scrollContentToTop();
  }

  int _pageFor(WebAssetSection section) => _sectionPages[section] ?? 0;

  void _resetPage(WebAssetSection section) {
    _sectionPages[section] = 0;
  }

  void _changePage(WebAssetSection section, int page) {
    if (page == _pageFor(section)) return;
    setState(() {
      _sectionPages[section] = page;
    });
    _scrollContentToTop();
  }

  _PagedItems<T> _paginate<T>(List<T> items, WebAssetSection section) {
    final totalPages = items.isEmpty
        ? 0
        : (items.length + _assetsPerPage - 1) ~/ _assetsPerPage;
    final page = totalPages == 0
        ? 0
        : _pageFor(section).clamp(0, totalPages - 1);
    final start = page * _assetsPerPage;
    final end = (start + _assetsPerPage).clamp(0, items.length);
    return _PagedItems(
      items: items.sublist(start, end),
      currentPage: page,
      totalPages: totalPages,
      totalItems: items.length,
    );
  }

  void _scrollContentToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!contentScrollController.hasClients) return;
      contentScrollController.animateTo(
        contentScrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  List<AssetStockModel> get visibleAssets {
    final search = searchQuery.trim().toLowerCase();

    return assets.where((asset) {
      return _matchesBranchAndSearch(asset, search) &&
          _matchesSelectedStatus(asset) &&
          _isRegularAsset(asset);
    }).toList();
  }

  List<AssetStockModel> get visibleInventoryAssets {
    final search = searchQuery.trim().toLowerCase();

    return assets.where((asset) {
      return _matchesBranchAndSearch(asset, search) &&
          _matchesSelectedStatus(asset) &&
          _isInventoryAsset(asset);
    }).toList();
  }

  bool _matchesBranchAndSearch(AssetStockModel asset, String search) {
    final matchesBranch =
        selectedBranch == null || asset.location == selectedBranch;
    return matchesBranch && _matchesSearch(asset, search);
  }

  bool _matchesSelectedStatus(AssetStockModel asset) {
    return selectedStatus == null ||
        asset.status.trim().toLowerCase() == selectedStatus!.toLowerCase();
  }

  bool _matchesSearch(AssetStockModel asset, String search) {
    return search.isEmpty ||
        asset.name.toLowerCase().contains(search) ||
        asset.itemCode.toLowerCase().contains(search) ||
        asset.category.toLowerCase().contains(search) ||
        asset.subCategory.toLowerCase().contains(search) ||
        asset.brand.toLowerCase().contains(search) ||
        asset.status.toLowerCase().contains(search) ||
        asset.location.toLowerCase().contains(search) ||
        asset.projectName.toLowerCase().contains(search) ||
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
      webPageRoute(WebAssetAddPage(initialBranch: selectedBranch)),
    );

    if (result == true) {
      await _loadData();
    }
  }

  Future<void> _exportList(List<AssetStockModel> items, String fileName) async {
    if (items.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No assets available to export')),
      );
      return;
    }
    await AssetExcelService.exportAssets(assets: items, fileName: fileName);
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

    return showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close print barcodes dialog',
      barrierColor: Colors.black.withValues(alpha: 0.48),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 610,
                    maxHeight: 700,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xfff8faff),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: const Color(0xffdfe6f2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 45,
                          spreadRadius: -8,
                          offset: const Offset(0, 22),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(26, 23, 18, 21),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                bottom: BorderSide(color: Color(0xffe4e9f2)),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xff5b7cff),
                                        Color(0xff3156e8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xff4568f2,
                                        ).withValues(alpha: 0.28),
                                        blurRadius: 18,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.qr_code_2_rounded,
                                    color: Colors.white,
                                    size: 29,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Print Barcodes',
                                        style: TextStyle(
                                          fontSize: 21,
                                          height: 1.15,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xff15213b),
                                          letterSpacing: -0.35,
                                        ),
                                      ),
                                      SizedBox(height: 7),
                                      Text(
                                        'Choose the assets you want to include in the barcode print.',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          height: 1.45,
                                          color: Color(0xff71809b),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Material(
                                  color: const Color(0xfff2f5fa),
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () =>
                                        Navigator.of(dialogContext).pop(),
                                    child: const SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 21,
                                        color: Color(0xff66748d),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Flexible(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                22,
                                24,
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xffedf2ff),
                                      borderRadius: BorderRadius.circular(19),
                                      border: Border.all(
                                        color: const Color(0xffdce5ff),
                                      ),
                                    ),
                                    child: _PrintClassificationOption(
                                      icon: Icons.select_all_rounded,
                                      title: 'All Trackable Assets',
                                      description:
                                          'Print every asset available for barcode tracking',
                                      count: printableAssets.length,
                                      color: const Color(0xff4568f2),
                                      highlighted: true,
                                      onTap: () {
                                        Navigator.of(
                                          dialogContext,
                                        ).pop('__all__');
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'ASSET CLASSIFICATION',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.1,
                                            color: Color(0xff8491a8),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xffe0e6ef),
                                          ),
                                        ),
                                        child: Text(
                                          '${classifications.length} options',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xff6d7b93),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  if (classifications.isEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 32,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: const Color(0xffe1e7f0),
                                        ),
                                      ),
                                      child: const Column(
                                        children: [
                                          Icon(
                                            Icons.inventory_2_outlined,
                                            size: 34,
                                            color: Color(0xff98a5ba),
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            'No classifications found',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xff34415a),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final useTwoColumns =
                                            constraints.maxWidth >= 480;

                                        if (!useTwoColumns) {
                                          return Column(
                                            children: classifications.map((
                                              classification,
                                            ) {
                                              final count = printableAssets
                                                  .where((asset) {
                                                    return asset.classification
                                                            .trim()
                                                            .toLowerCase() ==
                                                        classification
                                                            .toLowerCase();
                                                  })
                                                  .length;

                                              final classificationColor =
                                                  AssetClassificationUtils.classificationColor(
                                                    classification,
                                                  );

                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 10,
                                                ),
                                                child: _PrintClassificationOption(
                                                  icon: _classificationIcon(
                                                    classification,
                                                  ),
                                                  title: classification,
                                                  description:
                                                      'Print assets classified as $classification',
                                                  count: count,
                                                  color: classificationColor,
                                                  onTap: () {
                                                    Navigator.of(
                                                      dialogContext,
                                                    ).pop(classification);
                                                  },
                                                ),
                                              );
                                            }).toList(),
                                          );
                                        }

                                        return Wrap(
                                          spacing: 10,
                                          runSpacing: 10,
                                          children: classifications.map((
                                            classification,
                                          ) {
                                            final count = printableAssets.where(
                                              (asset) {
                                                return asset.classification
                                                        .trim()
                                                        .toLowerCase() ==
                                                    classification
                                                        .toLowerCase();
                                              },
                                            ).length;

                                            final classificationColor =
                                                AssetClassificationUtils.classificationColor(
                                                  classification,
                                                );

                                            return SizedBox(
                                              width:
                                                  (constraints.maxWidth - 10) /
                                                  2,
                                              child: _PrintClassificationOption(
                                                icon: _classificationIcon(
                                                  classification,
                                                ),
                                                title: classification,
                                                description:
                                                    'Print $classification assets',
                                                count: count,
                                                color: classificationColor,
                                                compact: true,
                                                onTap: () {
                                                  Navigator.of(
                                                    dialogContext,
                                                  ).pop(classification);
                                                },
                                              ),
                                            );
                                          }).toList(),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(24, 14, 24, 19),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                top: BorderSide(color: Color(0xffe4e9f2)),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 17,
                                  color: Color(0xff8b98ac),
                                ),
                                const SizedBox(width: 7),
                                const Expanded(
                                  child: Text(
                                    'A PDF preview will open before printing.',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xff7a879c),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xff53627a),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 13,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(curvedAnimation),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.035),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            ),
          ),
        );
      },
    );
  }

  IconData _classificationIcon(String classification) {
    switch (classification.trim().toLowerCase()) {
      case 'confidential':
        return Icons.lock_outline_rounded;

      case 'public':
        return Icons.public_rounded;

      case 'restricted':
        return Icons.gpp_maybe_outlined;

      default:
        return Icons.label_outline_rounded;
    }
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

  Future<List<AssetStockModel>?> _showAssetSearchPicker({
    required String actionLabel,
  }) {
    return showDialog<List<AssetStockModel>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _MultiAssetSearchDialog(
        assets: assets.where(_isRegularAsset).toList(growable: false),
        branches: branches,
        initialBranch: selectedBranch,
        actionLabel: actionLabel,
      ),
    );
  }

  Future<void> _openDisposeAssetPicker() async {
    final picked = await _showAssetSearchPicker(
      actionLabel: 'Continue to Dispose',
    );

    if (picked == null || picked.isEmpty) return;
    for (final asset in picked) {
      if (!mounted) return;
      final completed = await _openDisposeDetailsDialog(asset);
      if (!completed) break;
    }
  }

  Future<bool> _openDisposeDetailsDialog(AssetStockModel asset) async {
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
    return saved == true;
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
      backgroundColor: AppColors.bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              _Sidebar(
                section: selectedSection,
                alertCount: alertCount,
                onSelected: _selectSection,
              ),
              Expanded(
                child: Column(
                  children: [
                    _TopBar(
                      section: selectedSection,
                      selectedBranch: selectedBranch,
                      branches: branches,
                      onBranchChanged: (value) {
                        setState(() {
                          selectedBranch = value;
                          _sectionPages.clear();
                        });
                      },
                      onAssets: () => _selectSection(WebAssetSection.assets),
                      onAddAsset: _addAsset,
                      onPrint: _printAssets,
                      onRefresh: _loadData,
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: loading || sectionLoading
                            ? _WebLoadingView(
                                key: const ValueKey('web-loading'),
                                message: loading
                                    ? 'Loading asset data...'
                                    : 'Opening ${_sectionLabel(pendingSection ?? selectedSection)}...',
                              )
                            : SingleChildScrollView(
                                key: ValueKey(selectedSection),
                                controller: contentScrollController,
                                padding: const EdgeInsets.fromLTRB(
                                  26,
                                  24,
                                  26,
                                  34,
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

  String _sectionLabel(WebAssetSection section) {
    switch (section) {
      case WebAssetSection.dashboard:
        return 'Dashboard';
      case WebAssetSection.alerts:
        return 'Alerts';
      case WebAssetSection.assets:
        return 'List of Assets';
      case WebAssetSection.inventory:
        return 'Inventory';
      case WebAssetSection.transfer:
        return 'Move Assets';
      case WebAssetSection.dispose:
        return 'Disposed Assets';
      case WebAssetSection.maintenance:
        return 'Maintenance';
    }
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
                    indicatorColor: AppColors.primaryColor,
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
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'More Details',
                  style: TextStyle(color: Colors.white),
                ),
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

    final leadingDays = monthStart.weekday % 7;

    final gridStart = monthStart.subtract(Duration(days: leadingDays));

    final daysInMonth = DateTime(alertMonth.year, alertMonth.month + 1, 0).day;

    final calendarRows = ((leadingDays + daysInMonth) / 7).ceil();
    final calendarItemCount = calendarRows * 7;
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
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Month',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
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
            height: calendarRows * 78.0,
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: 78,
              ),
              itemCount: calendarItemCount,
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
                  padding: const EdgeInsets.all(4),
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
                      const SizedBox(height: 2),
                      ...records.take(1).map((record) {
                        final itemCode = record['asset_name']?.toString() ?? '';
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: InkWell(
                            onTap: () => _showMaintenanceRecordDialog(record),
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
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
                      if (records.length > 1)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '+${records.length - 1} more',
                            style: const TextStyle(
                              color: AppColors.subText,
                              fontSize: 9.5,
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
    final filteredAssets = [...visibleAssets]
      ..sort((first, second) => second.createdAt.compareTo(first.createdAt));

    if (limit != null) {
      final recentAssets = filteredAssets.take(limit).toList(growable: false);

      return _AssetRegistryRecentPanel(
        assets: recentAssets,
        onDetails: _showAssetDetails,
        onTransfer: _transferAsset,
        onMaintenance: _openMaintenanceDetailsDialog,
        onDispose: _openDisposeDetailsDialog,
      );
    }

    final pagedAssets = _paginate(filteredAssets, WebAssetSection.assets);

    final statuses = _statusesFor(assets.where(_isRegularAsset));

    final totalAssetValue = filteredAssets.fold<double>(
      0,
      (total, asset) => total + asset.cost,
    );

    final locationsCount = filteredAssets
        .map((asset) => asset.location.trim())
        .where((location) => location.isNotEmpty)
        .toSet()
        .length;

    final categoriesCount = filteredAssets
        .map((asset) => asset.category.trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .length;

    final hasFilters = searchQuery.trim().isNotEmpty || selectedStatus != null;

    return TweenAnimationBuilder<double>(
      key: ValueKey('asset-registry-${selectedBranch ?? 'all'}'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AssetRegistryHeader(
            totalAssets: filteredAssets.length,
            selectedBranch: selectedBranch,
            onAddAsset: _addAsset,
            onExport: () {
              _exportList(
                filteredAssets,
                selectedBranch == null ? 'assets' : '${selectedBranch}_assets',
              );
            },
          ),
          const SizedBox(height: 16),

          _AssetRegistrySummaryStrip(
            totalAssets: filteredAssets.length,
            totalValue: totalAssetValue,
            locationsCount: locationsCount,
            categoriesCount: categoriesCount,
          ),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xffdfe7f2)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff1d3557).withValues(alpha: 0.055),
                  blurRadius: 28,
                  spreadRadius: -10,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
                    child: Row(
                      children: [
                        Container(
                          width: 5,
                          height: 34,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xff4263eb), Color(0xff15aabf)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        const SizedBox(width: 11),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Asset Directory',
                                style: TextStyle(
                                  color: Color(0xff17243b),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.25,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Browse, inspect and manage all active asset records',
                                style: TextStyle(
                                  color: Color(0xff8a97a9),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xfff1f5fb),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xffdfe6f0)),
                          ),
                          child: Text(
                            '${filteredAssets.length} records',
                            style: const TextStyle(
                              color: Color(0xff60718a),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xffe8edf4)),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 17, 22, 17),
                    child: _AssetRegistryToolbar(
                      searchController: searchController,
                      selectedStatus: selectedStatus,
                      statuses: statuses,
                      resultsCount: filteredAssets.length,
                      hasFilters: hasFilters,
                      onSearchChanged: (value) {
                        setState(() {
                          searchQuery = value;
                          _resetPage(WebAssetSection.assets);
                        });
                      },
                      onStatusChanged: (value) {
                        setState(() {
                          selectedStatus = value;
                          _resetPage(WebAssetSection.assets);
                        });
                      },
                      onClearFilters: () {
                        searchController.clear();

                        setState(() {
                          searchQuery = '';
                          selectedStatus = null;
                          _resetPage(WebAssetSection.assets);
                        });
                      },
                    ),
                  ),

                  Container(
                    width: double.infinity,
                    height: 1,
                    color: const Color(0xffedf1f6),
                  ),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final tableWidth = constraints.maxWidth < 1120
                          ? 1120.0
                          : constraints.maxWidth;

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: tableWidth,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                            child: Column(
                              children: [
                                const _AssetRegistryTableHeader(),

                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 260),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  child: filteredAssets.isEmpty
                                      ? _AssetRegistryEmptyState(
                                          key: ValueKey(
                                            'empty-${searchQuery.trim()}-${selectedStatus ?? 'all'}',
                                          ),
                                          hasFilters: hasFilters,
                                          onClearFilters: () {
                                            searchController.clear();

                                            setState(() {
                                              searchQuery = '';
                                              selectedStatus = null;
                                              _resetPage(
                                                WebAssetSection.assets,
                                              );
                                            });
                                          },
                                        )
                                      : Column(
                                          key: ValueKey(
                                            'asset-page-${pagedAssets.currentPage}'
                                            '-${searchQuery.trim()}'
                                            '-${selectedStatus ?? 'all'}',
                                          ),
                                          children: [
                                            const SizedBox(height: 8),
                                            for (
                                              var index = 0;
                                              index < pagedAssets.items.length;
                                              index++
                                            )
                                              _AssetRegistryRow(
                                                key: ValueKey(
                                                  pagedAssets
                                                      .items[index]
                                                      .itemCode,
                                                ),
                                                asset: pagedAssets.items[index],
                                                animationDelay: index * 22,
                                                onDetails: () =>
                                                    _showAssetDetails(
                                                      pagedAssets.items[index],
                                                    ),
                                                onTransfer: () =>
                                                    _transferAsset(
                                                      pagedAssets.items[index],
                                                    ),
                                                onMaintenance: () =>
                                                    _openMaintenanceDetailsDialog(
                                                      pagedAssets.items[index],
                                                    ),
                                                onDispose: () =>
                                                    _openDisposeDetailsDialog(
                                                      pagedAssets.items[index],
                                                    ),
                                              ),
                                          ],
                                        ),
                                ),

                                if (filteredAssets.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  _PaginationBar(
                                    currentPage: pagedAssets.currentPage,
                                    totalPages: pagedAssets.totalPages,
                                    totalItems: pagedAssets.totalItems,
                                    pageSize: _assetsPerPage,
                                    onPageChanged: (page) {
                                      _changePage(WebAssetSection.assets, page);
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inventoryPanel() {
    final inventoryAssets = visibleInventoryAssets;
    final pagedAssets = _paginate(inventoryAssets, WebAssetSection.inventory);

    return _Panel(
      title: 'Inventory',
      trailing: _ListToolbar(
        searchController: searchController,
        searchHint: 'Search Inventory',
        selectedStatus: selectedStatus,
        statuses: _statusesFor(assets.where(_isInventoryAsset)),
        onSearchChanged: (value) {
          setState(() {
            searchQuery = value;
            _resetPage(WebAssetSection.inventory);
          });
        },
        onStatusChanged: (value) {
          setState(() {
            selectedStatus = value;
            _resetPage(WebAssetSection.inventory);
          });
        },
        onExport: () => _exportList(
          inventoryAssets,
          selectedBranch == null
              ? 'inventory_assets'
              : '${selectedBranch}_inventory_assets',
        ),
      ),
      child: Column(
        children: [
          _AssetTableHeader(),
          if (inventoryAssets.isEmpty)
            const SizedBox(
              height: 180,
              child: Center(child: Text('No inventory items found')),
            )
          else
            ...pagedAssets.items.map((asset) {
              return _AssetTableRow(
                asset: asset,
                onDetails: () => _showAssetDetails(asset),
                onTransfer: () => _transferAsset(asset),
                onDispose: () => _openDisposeDetailsDialog(asset),
                onMaintenance: () => _openMaintenanceDetailsDialog(asset),
              );
            }),
          if (inventoryAssets.isNotEmpty) ...[
            const SizedBox(height: 14),
            _PaginationBar(
              currentPage: pagedAssets.currentPage,
              totalPages: pagedAssets.totalPages,
              totalItems: pagedAssets.totalItems,
              pageSize: _assetsPerPage,
              onPageChanged: (page) =>
                  _changePage(WebAssetSection.inventory, page),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openMaintenanceAssetPicker() async {
    final picked = await _showAssetSearchPicker(
      actionLabel: 'Continue to Maintenance',
    );

    if (picked == null || picked.isEmpty) return;
    for (final asset in picked) {
      if (!mounted) return;
      final completed = await _openMaintenanceDetailsDialog(asset);
      if (!completed) break;
    }
  }

  Future<bool> _openMaintenanceDetailsDialog(AssetStockModel asset) async {
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
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.settings_suggest_outlined,
                      color: AppColors.primaryColor,
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
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Add',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
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
    return saved == true;
  }

  Widget _alertsPanel() {
    final pagedAlerts = _paginate(maintenanceAlerts, WebAssetSection.alerts);
    final alertAssets = <AssetStockModel>[];
    for (final alert in maintenanceAlerts) {
      final itemCode = alert['item_code']?.toString() ?? '';
      final asset = _assetByItemCode(itemCode);
      if (asset != null) alertAssets.add(asset);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _AlertSummaryCard(
                icon: Icons.notifications_active_outlined,
                color: const Color(0xFFE53935),
                label: 'Active Alerts',
                value: alertCount.toString(),
                note: 'Requires attention',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AlertSummaryCard(
                icon: Icons.schedule_outlined,
                color: const Color(0xFFF59E0B),
                label: 'Due Soon',
                value: maintenanceAlerts.length.toString(),
                note: 'Within the next 3 days',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AlertSummaryCard(
                icon: Icons.location_on_outlined,
                color: AppColors.primaryColor,
                label: 'Location Scope',
                value: selectedBranch ?? 'All Branches',
                note: 'Current branch filter',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Panel(
          title: 'Maintenance Alerts',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$alertCount alerts',
                  style: const TextStyle(
                    color: Color(0xFFE53935),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: alertAssets.isEmpty
                    ? null
                    : () => _exportList(alertAssets, 'maintenance_alerts'),
                icon: const Icon(Icons.file_download_outlined, size: 18),
                label: const Text('Export'),
              ),
            ],
          ),
          child: maintenanceAlerts.isEmpty
              ? const _AlertEmptyState()
              : Column(
                  children: [
                    ...pagedAlerts.items.map((alert) {
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

                      return Container(
                        margin: const EdgeInsets.only(bottom: 9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBF2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(
                              0xFFF59E0B,
                            ).withValues(alpha: .22),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFF59E0B,
                              ).withValues(alpha: .13),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(
                              Icons.build_outlined,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                          title: Text(
                            '${alert['asset_name'] ?? itemCode} · $itemCode',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              'Due $date  •  ${alert['branch'] ?? '-'}',
                            ),
                          ),
                          trailing: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _AlertChip(
                                label: 'Due soon',
                                color: Color(0xFFF59E0B),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                          onTap: tappedAsset == null
                              ? null
                              : () => _showAssetDetails(tappedAsset),
                        ),
                      );
                    }),
                    if (pagedAlerts.totalPages > 1) ...[
                      const SizedBox(height: 8),
                      _PaginationBar(
                        currentPage: pagedAlerts.currentPage,
                        totalPages: pagedAlerts.totalPages,
                        totalItems: pagedAlerts.totalItems,
                        pageSize: _assetsPerPage,
                        onPageChanged: (page) =>
                            _changePage(WebAssetSection.alerts, page),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _disposePanel() {
    final search = searchQuery.trim().toLowerCase();

    final disposedAssets =
        assets.where((asset) {
          return _matchesBranchAndSearch(asset, search) &&
              asset.status.trim().toLowerCase() == 'disposed';
        }).toList()..sort(
          (first, second) =>
              first.name.toLowerCase().compareTo(second.name.toLowerCase()),
        );

    final pagedAssets = _paginate(disposedAssets, WebAssetSection.dispose);

    final affectedLocations = disposedAssets
        .map((asset) => asset.location.trim())
        .where((location) => location.isNotEmpty)
        .toSet()
        .length;

    final categoriesCount = disposedAssets
        .map((asset) => asset.category.trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .length;

    final disposedValue = disposedAssets.fold<double>(
      0,
      (sum, asset) => sum + asset.cost,
    );

    return TweenAnimationBuilder<double>(
      key: ValueKey(
        'disposed-${selectedBranch ?? 'all'}-${disposedAssets.length}',
      ),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, animationValue, child) {
        return Opacity(
          opacity: animationValue,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - animationValue)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DisposedHeroCard(
            totalAssets: disposedAssets.length,
            selectedBranch: selectedBranch,
            onExport: () {
              _exportList(
                disposedAssets,
                selectedBranch == null
                    ? 'disposed_assets'
                    : '${selectedBranch}_disposed_assets',
              );
            },
            onSelectAssets: _openDisposeAssetPicker,
          ),
          const SizedBox(height: 18),

          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              final cardWidth = width >= 1080
                  ? (width - 48) / 4
                  : width >= 720
                  ? (width - 16) / 2
                  : width;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _MaintenanceStatCard(
                      icon: Icons.delete_sweep_outlined,
                      color: const Color(0xffe5484d),
                      title: 'Disposed Assets',
                      value: disposedAssets.length.toString(),
                      subtitle: 'Archived assets in the register',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _MaintenanceStatCard(
                      icon: Icons.location_on_outlined,
                      color: const Color(0xfff08c46),
                      title: 'Affected Locations',
                      value: affectedLocations.toString(),
                      subtitle: 'Locations with disposed assets',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _MaintenanceStatCard(
                      icon: Icons.payments_outlined,
                      color: const Color(0xff4263eb),
                      title: 'Recorded Value',
                      value: disposedValue.toStringAsFixed(2),
                      subtitle: 'AED disposal asset value',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _MaintenanceStatCard(
                      icon: Icons.category_outlined,
                      color: const Color(0xff7950f2),
                      title: 'Asset Categories',
                      value: categoriesCount.toString(),
                      subtitle: selectedBranch ?? 'Across all branches',
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xffdfe7f2)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff1d3557).withValues(alpha: 0.055),
                  blurRadius: 28,
                  spreadRadius: -10,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 760;

                        final searchField = Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xfff8fafd),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xffdfe7f2)),
                          ),
                          child: TextField(
                            controller: searchController,
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value;
                                _resetPage(WebAssetSection.dispose);
                              });
                            },
                            decoration: InputDecoration(
                              hintText:
                                  'Search by asset name, tag ID, site or location',
                              hintStyle: const TextStyle(
                                color: Color(0xff8a97aa),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: Color(0xff5f6f86),
                                size: 21,
                              ),
                              suffixIcon: searchController.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Clear search',
                                      onPressed: () {
                                        searchController.clear();

                                        setState(() {
                                          searchQuery = '';
                                          _resetPage(WebAssetSection.dispose);
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 19,
                                      ),
                                    ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 15,
                              ),
                            ),
                          ),
                        );

                        final resultBadge = Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 17),
                          decoration: BoxDecoration(
                            color: const Color(0xfffff1f1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xffffc6c8)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 31,
                                height: 31,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xffe5484d,
                                  ).withValues(alpha: 0.11),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Color(0xffd9363e),
                                  size: 19,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${disposedAssets.length} disposed',
                                style: const TextStyle(
                                  color: Color(0xff8c1d22),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        );

                        if (compact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              searchField,
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: resultBadge,
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: searchField),
                            const SizedBox(width: 14),
                            resultBadge,
                          ],
                        );
                      },
                    ),
                  ),

                  Container(
                    margin: const EdgeInsets.fromLTRB(22, 0, 22, 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xfffff7f7), Color(0xfffffbfb)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xffffd8d9)),
                    ),
                    child: const Row(
                      children: [
                        _DisposedInformationIcon(),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Only assets currently marked as Disposed are shown '
                            'in this register. Open an asset to review or update '
                            'its disposal date, recipient and supporting notes.',
                            style: TextStyle(
                              color: Color(0xff6f6671),
                              fontSize: 12.5,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 5,
                          height: 27,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xffe5484d), Color(0xfff08c46)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        const SizedBox(width: 11),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Disposed Asset Register',
                                style: TextStyle(
                                  color: Color(0xff16243c),
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Review and manage assets removed from active operation',
                                style: TextStyle(
                                  color: Color(0xff8794a7),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xfff1f5fb),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xffdfe6f0)),
                          ),
                          child: Text(
                            '${disposedAssets.length} records',
                            style: const TextStyle(
                              color: Color(0xff60718a),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      children: [
                        const _ModernDisposedTableHeader(),

                        if (disposedAssets.isEmpty)
                          _DisposedEmptyState(
                            hasSearch: search.isNotEmpty,
                            onSelectAssets: _openDisposeAssetPicker,
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              children: [
                                for (
                                  var index = 0;
                                  index < pagedAssets.items.length;
                                  index++
                                )
                                  _ModernDisposedAssetRow(
                                    key: ValueKey(
                                      'disposed-${pagedAssets.items[index].itemCode}',
                                    ),
                                    asset: pagedAssets.items[index],
                                    animationDelay: index * 35,
                                    onDetails: () => _showAssetDetails(
                                      pagedAssets.items[index],
                                    ),
                                    onEdit: () => _openDisposeDetailsDialog(
                                      pagedAssets.items[index],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                        if (disposedAssets.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _PaginationBar(
                            currentPage: pagedAssets.currentPage,
                            totalPages: pagedAssets.totalPages,
                            totalItems: pagedAssets.totalItems,
                            pageSize: _assetsPerPage,
                            onPageChanged: (page) {
                              _changePage(WebAssetSection.dispose, page);
                            },
                          ),
                        ],

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _maintenancePanel() {
    final search = searchQuery.trim().toLowerCase();

    final maintenanceAssets =
        assets.where((asset) {
          return _matchesBranchAndSearch(asset, search) &&
              asset.status.trim().toLowerCase() == 'maintenance';
        }).toList()..sort(
          (first, second) =>
              first.name.toLowerCase().compareTo(second.name.toLowerCase()),
        );

    final pagedAssets = _paginate(
      maintenanceAssets,
      WebAssetSection.maintenance,
    );

    final locationsCount = maintenanceAssets
        .map((asset) => asset.location.trim())
        .where((location) => location.isNotEmpty)
        .toSet()
        .length;

    final scopedMaintenanceRecords = maintenanceRecords
        .where((record) {
          if (selectedBranch == null) return true;

          final recordBranch = record['branch']?.toString().trim() ?? '';
          return recordBranch == selectedBranch;
        })
        .toList(growable: false);

    final activeMaintenanceRecords = scopedMaintenanceRecords.where((record) {
      final status = record['status']?.toString().trim().toLowerCase() ?? '';

      return status != 'completed' && status != 'done' && status != 'closed';
    }).length;

    return TweenAnimationBuilder<double>(
      key: ValueKey(
        'maintenance-${selectedBranch ?? 'all'}-${maintenanceAssets.length}',
      ),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, animationValue, child) {
        return Opacity(
          opacity: animationValue,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - animationValue)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MaintenanceHeroCard(
            totalAssets: maintenanceAssets.length,
            selectedBranch: selectedBranch,
            onExport: () {
              _exportList(
                maintenanceAssets,
                selectedBranch == null
                    ? 'maintenance_assets'
                    : '${selectedBranch}_maintenance_assets',
              );
            },
            onSelectAssets: _openMaintenanceAssetPicker,
          ),
          const SizedBox(height: 18),

          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              final cardWidth = width >= 1080
                  ? (width - 48) / 4
                  : width >= 720
                  ? (width - 16) / 2
                  : width;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _MaintenanceStatCard(
                      icon: Icons.settings_suggest_rounded,
                      color: const Color(0xff4263eb),
                      title: 'Under Maintenance',
                      value: maintenanceAssets.length.toString(),
                      subtitle: 'Assets currently unavailable',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _MaintenanceStatCard(
                      icon: Icons.location_on_outlined,
                      color: const Color(0xff0f9f8f),
                      title: 'Affected Locations',
                      value: locationsCount.toString(),
                      subtitle: 'Locations with maintenance assets',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _MaintenanceStatCard(
                      icon: Icons.pending_actions_rounded,
                      color: const Color(0xfff59f00),
                      title: 'Active Work Orders',
                      value: activeMaintenanceRecords.toString(),
                      subtitle: 'Open maintenance records',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _MaintenanceStatCard(
                      icon: Icons.history_rounded,
                      color: const Color(0xff7950f2),
                      title: 'Maintenance Records',
                      value: scopedMaintenanceRecords.length.toString(),
                      subtitle: selectedBranch ?? 'Across all branches',
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xffdfe7f2)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff1d3557).withValues(alpha: 0.055),
                  blurRadius: 28,
                  spreadRadius: -10,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 760;

                        final searchField = Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xfff8fafd),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xffdfe7f2)),
                          ),
                          child: TextField(
                            controller: searchController,
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value;
                                _resetPage(WebAssetSection.maintenance);
                              });
                            },
                            decoration: InputDecoration(
                              hintText:
                                  'Search by asset name, tag ID, site or location',
                              hintStyle: const TextStyle(
                                color: Color(0xff8a97aa),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: Color(0xff5f6f86),
                                size: 21,
                              ),
                              suffixIcon: searchController.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Clear search',
                                      onPressed: () {
                                        searchController.clear();

                                        setState(() {
                                          searchQuery = '';
                                          _resetPage(
                                            WebAssetSection.maintenance,
                                          );
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 19,
                                      ),
                                    ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 15,
                              ),
                            ),
                          ),
                        );

                        final resultBadge = Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 17),
                          decoration: BoxDecoration(
                            color: const Color(0xfffff8e7),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xffffd88a)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 31,
                                height: 31,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xfff59f00,
                                  ).withValues(alpha: 0.13),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Icon(
                                  Icons.build_circle_outlined,
                                  color: Color(0xffe58b00),
                                  size: 19,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${maintenanceAssets.length} in maintenance',
                                style: const TextStyle(
                                  color: Color(0xff674900),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        );

                        if (compact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              searchField,
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: resultBadge,
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: searchField),
                            const SizedBox(width: 14),
                            resultBadge,
                          ],
                        );
                      },
                    ),
                  ),

                  Container(
                    margin: const EdgeInsets.fromLTRB(22, 0, 22, 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xfff4f8ff), Color(0xfff8fbff)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xffdbe7fa)),
                    ),
                    child: const Row(
                      children: [
                        _MaintenanceInformationIcon(),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Only assets currently marked as Maintenance are shown here. '
                            'Open an asset to update its maintenance details, cost, due date or completion status.',
                            style: TextStyle(
                              color: Color(0xff60718b),
                              fontSize: 12.5,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 5,
                          height: 27,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xff4169e1), Color(0xff19a7ce)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        const SizedBox(width: 11),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assets Pending Maintenance',
                                style: TextStyle(
                                  color: Color(0xff16243c),
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Review and manage all assets currently under service',
                                style: TextStyle(
                                  color: Color(0xff8794a7),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xfff1f5fb),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xffdfe6f0)),
                          ),
                          child: Text(
                            '${maintenanceAssets.length} records',
                            style: const TextStyle(
                              color: Color(0xff60718a),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      children: [
                        const _ModernMaintenanceTableHeader(),

                        if (maintenanceAssets.isEmpty)
                          _MaintenanceEmptyState(
                            hasSearch: search.isNotEmpty,
                            onSelectAssets: _openMaintenanceAssetPicker,
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              children: [
                                for (
                                  var index = 0;
                                  index < pagedAssets.items.length;
                                  index++
                                )
                                  _ModernMaintenanceAssetRow(
                                    key: ValueKey(
                                      pagedAssets.items[index].itemCode,
                                    ),
                                    asset: pagedAssets.items[index],
                                    animationDelay: index * 35,
                                    onDetails: () => _showAssetDetails(
                                      pagedAssets.items[index],
                                    ),
                                    onEdit: () => _openMaintenanceDetailsDialog(
                                      pagedAssets.items[index],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                        if (maintenanceAssets.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _PaginationBar(
                            currentPage: pagedAssets.currentPage,
                            totalPages: pagedAssets.totalPages,
                            totalItems: pagedAssets.totalItems,
                            pageSize: _assetsPerPage,
                            onPageChanged: (page) {
                              _changePage(WebAssetSection.maintenance, page);
                            },
                          ),
                        ],

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    final search = searchQuery.trim().toLowerCase();

    final filteredAssets =
        visibleAssets.where((asset) {
          return _matchesBranchAndSearch(asset, search);
        }).toList()..sort(
          (first, second) =>
              first.name.toLowerCase().compareTo(second.name.toLowerCase()),
        );

    final pagedAssets = _paginate(filteredAssets, WebAssetSection.transfer);

    final locationsCount = filteredAssets
        .map((asset) => asset.location.trim())
        .where((location) => location.isNotEmpty)
        .toSet()
        .length;

    final sitesCount = filteredAssets
        .map((asset) => asset.projectName.trim())
        .where((site) => site.isNotEmpty)
        .toSet()
        .length;

    final categoriesCount = filteredAssets
        .map((asset) => asset.category.trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .length;

    return TweenAnimationBuilder<double>(
      key: ValueKey(
        'transfer-${selectedBranch ?? 'all'}-${filteredAssets.length}',
      ),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, animationValue, child) {
        return Opacity(
          opacity: animationValue,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - animationValue)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TransferHeroCard(
            title: title,
            totalAssets: filteredAssets.length,
            selectedBranch: selectedBranch,
            onExport: () {
              _exportList(
                filteredAssets,
                selectedBranch == null
                    ? 'move_assets'
                    : '${selectedBranch}_move_assets',
              );
            },
          ),
          const SizedBox(height: 18),

          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              final cardWidth = width >= 1080
                  ? (width - 48) / 4
                  : width >= 720
                  ? (width - 16) / 2
                  : width;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _MaintenanceStatCard(
                      icon: Icons.swap_horiz_rounded,
                      color: const Color(0xff4263eb),
                      title: 'Transfer Ready',
                      value: filteredAssets.length.toString(),
                      subtitle: 'Assets available for transfer',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _MaintenanceStatCard(
                      icon: Icons.location_on_outlined,
                      color: const Color(0xff0f9f8f),
                      title: 'Locations',
                      value: locationsCount.toString(),
                      subtitle: 'Branches with transferable assets',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _MaintenanceStatCard(
                      icon: Icons.business_outlined,
                      color: const Color(0xfff59f00),
                      title: 'Sites Covered',
                      value: sitesCount.toString(),
                      subtitle: 'Distinct sites in current list',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _MaintenanceStatCard(
                      icon: Icons.category_outlined,
                      color: const Color(0xff7950f2),
                      title: 'Categories',
                      value: categoriesCount.toString(),
                      subtitle: selectedBranch ?? 'Across all branches',
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xffdfe7f2)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff1d3557).withValues(alpha: 0.055),
                  blurRadius: 28,
                  spreadRadius: -10,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 760;

                        final searchField = Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xfff8fafd),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xffdfe7f2)),
                          ),
                          child: TextField(
                            controller: searchController,
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value;
                                _resetPage(WebAssetSection.transfer);
                              });
                            },
                            decoration: InputDecoration(
                              hintText:
                                  'Search by asset name, tag ID, site or location',
                              hintStyle: const TextStyle(
                                color: Color(0xff8a97aa),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: Color(0xff5f6f86),
                                size: 21,
                              ),
                              suffixIcon: searchController.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Clear search',
                                      onPressed: () {
                                        searchController.clear();

                                        setState(() {
                                          searchQuery = '';
                                          _resetPage(WebAssetSection.transfer);
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 19,
                                      ),
                                    ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 15,
                              ),
                            ),
                          ),
                        );

                        final resultBadge = Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 17),
                          decoration: BoxDecoration(
                            color: const Color(0xffedf4ff),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xffcfe0ff)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 31,
                                height: 31,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xff4263eb,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Icon(
                                  Icons.compare_arrows_rounded,
                                  color: Color(0xff3156e8),
                                  size: 19,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${filteredAssets.length} ready to transfer',
                                style: const TextStyle(
                                  color: Color(0xff21418d),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        );

                        if (compact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              searchField,
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: resultBadge,
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: searchField),
                            const SizedBox(width: 14),
                            resultBadge,
                          ],
                        );
                      },
                    ),
                  ),

                  Container(
                    margin: const EdgeInsets.fromLTRB(22, 0, 22, 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xfff4f8ff), Color(0xfff8fbff)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xffdbe7fa)),
                    ),
                    child: Row(
                      children: [
                        const _TransferInformationIcon(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            description.isEmpty
                                ? 'Move assets between branches or sites directly from this panel. '
                                      'Select any asset below to start the transfer process and keep movement records organized.'
                                : description,
                            style: const TextStyle(
                              color: Color(0xff60718b),
                              fontSize: 12.5,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 5,
                          height: 27,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xff4169e1), Color(0xff19a7ce)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Asset For $title',
                                style: const TextStyle(
                                  color: Color(0xff16243c),
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'Choose an asset and begin the transfer workflow',
                                style: TextStyle(
                                  color: Color(0xff8794a7),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xfff1f5fb),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xffdfe6f0)),
                          ),
                          child: Text(
                            '${filteredAssets.length} records',
                            style: const TextStyle(
                              color: Color(0xff60718a),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      children: [
                        _ModernTransferTableHeader(operationLabel: actionLabel),

                        if (filteredAssets.isEmpty)
                          _TransferEmptyState(hasSearch: search.isNotEmpty)
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              children: [
                                for (
                                  var index = 0;
                                  index < pagedAssets.items.length;
                                  index++
                                )
                                  _ModernTransferAssetRow(
                                    key: ValueKey(
                                      'transfer-${pagedAssets.items[index].itemCode}',
                                    ),
                                    asset: pagedAssets.items[index],
                                    animationDelay: index * 35,
                                    actionLabel: actionLabel,
                                    actionIcon: actionIcon,
                                    onDetails: () => _showAssetDetails(
                                      pagedAssets.items[index],
                                    ),
                                    onOperation: () =>
                                        onAction(pagedAssets.items[index]),
                                  ),
                              ],
                            ),
                          ),

                        if (filteredAssets.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _PaginationBar(
                            currentPage: pagedAssets.currentPage,
                            totalPages: pagedAssets.totalPages,
                            totalItems: pagedAssets.totalItems,
                            pageSize: _assetsPerPage,
                            onPageChanged: (page) {
                              _changePage(WebAssetSection.transfer, page);
                            },
                          ),
                        ],

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _statusesFor(Iterable<AssetStockModel> source) {
    final values = source
        .map((asset) => asset.status.trim())
        .where((status) => status.isNotEmpty)
        .toSet()
        .toList();
    values.sort();
    return values;
  }
}

class _TopBar extends StatelessWidget {
  final WebAssetSection section;
  final String? selectedBranch;
  final List<String> branches;
  final ValueChanged<String?> onBranchChanged;
  final VoidCallback onAssets;
  final VoidCallback onAddAsset;
  final VoidCallback onPrint;
  final VoidCallback onRefresh;

  const _TopBar({
    required this.section,
    required this.selectedBranch,
    required this.branches,
    required this.onBranchChanged,
    required this.onAssets,
    required this.onAddAsset,
    required this.onPrint,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final branchValue = selectedBranch ?? '__all__';
    final branchItems = ['__all__', ...branches];

    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xF9FFFFFF),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu_rounded, color: AppColors.headerText),
          ),
          const SizedBox(width: 18),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _title,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: 3),
              Text(
                _subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.subText),
              ),
            ],
          ),
          const SizedBox(width: 24),
          _TopNavIcon(
            icon: Icons.inventory_2_outlined,
            label: 'Assets',
            onTap: onAssets,
          ),
          _TopNavIcon(
            icon: Icons.add_circle_outline,
            label: 'Add Asset',
            onTap: onAddAsset,
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
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Refresh',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: 22),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 34, color: AppColors.border),
          const SizedBox(width: 14),
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primaryColor, AppColors.cyan],
              ),
            ),
            child: const Icon(Icons.person_outline, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Al Ain Team',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                'Administrator',
                style: TextStyle(fontSize: 11, color: AppColors.subText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _title {
    switch (section) {
      case WebAssetSection.dashboard:
        return 'Dashboard';
      case WebAssetSection.alerts:
        return 'Alerts';
      case WebAssetSection.assets:
        return 'List of Assets';
      case WebAssetSection.inventory:
        return 'Inventory';
      case WebAssetSection.transfer:
        return 'Move Assets';
      case WebAssetSection.dispose:
        return 'Disposed Assets';
      case WebAssetSection.maintenance:
        return 'Maintenance';
    }
  }

  String get _subtitle {
    switch (section) {
      case WebAssetSection.dashboard:
        return 'Overview & statistics';
      case WebAssetSection.alerts:
        return 'Time-sensitive asset notifications';
      case WebAssetSection.assets:
        return 'Browse, filter and manage assets';
      case WebAssetSection.inventory:
        return 'Inventory asset register';
      case WebAssetSection.transfer:
        return 'Move assets between locations';
      case WebAssetSection.dispose:
        return 'Disposed asset register';
      case WebAssetSection.maintenance:
        return 'Assets currently under maintenance';
    }
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
      width: 270,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF06172F), Color(0xFF082B55), Color(0xFF061B36)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 25, 16, 25),
            child: Row(
              children: [
                _DashboardBrandMark(),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Al Ain Pharmacy',
                        maxLines: 1,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'ASSET',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  _SidebarItem(
                    icon: Icons.grid_view_rounded,
                    label: 'Dashboard',
                    selected: section == WebAssetSection.dashboard,
                    onTap: () => onSelected(WebAssetSection.dashboard),
                  ),
                  _SidebarItem(
                    icon: Icons.notifications_none_rounded,
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
                  const Padding(
                    padding: EdgeInsets.fromLTRB(15, 15, 15, 7),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'MANAGEMENT',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  _SidebarItem(
                    icon: Icons.bar_chart_rounded,
                    label: 'Reports',
                    selected: false,
                    onTap: () => onSelected(WebAssetSection.dashboard),
                  ),
                  _SidebarItem(
                    icon: Icons.tune_rounded,
                    label: 'Setup',
                    selected: false,
                    onTap: () => onSelected(WebAssetSection.dashboard),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardBrandMark extends StatelessWidget {
  const _DashboardBrandMark();

  @override
  Widget build(BuildContext context) => Container(
    width: 50,
    height: 50,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(15),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.cyan, AppColors.primaryColor],
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x5500C6F7),
          blurRadius: 18,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: const Icon(
      Icons.medication_liquid_outlined,
      color: Colors.white,
      size: 28,
    ),
  );
}

class _SidebarGroup extends StatefulWidget {
  final WebAssetSection selected;
  final ValueChanged<WebAssetSection> onSelected;

  const _SidebarGroup({required this.selected, required this.onSelected});

  @override
  State<_SidebarGroup> createState() => _SidebarGroupState();
}

class _SidebarGroupState extends State<_SidebarGroup> {
  late bool expanded;

  bool _isAssetSection(WebAssetSection section) =>
      section == WebAssetSection.assets ||
      section == WebAssetSection.transfer ||
      section == WebAssetSection.dispose ||
      section == WebAssetSection.maintenance;

  @override
  void initState() {
    super.initState();
    expanded = _isAssetSection(widget.selected);
  }

  @override
  void didUpdateWidget(covariant _SidebarGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isAssetSection(widget.selected) &&
        !_isAssetSection(oldWidget.selected)) {
      expanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SidebarItem(
          icon: Icons.extension_outlined,
          label: 'Assets',
          selected: false,
          onTap: () => setState(() => expanded = !expanded),
          trailing: AnimatedRotation(
            turns: expanded ? .25 : 0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: const Icon(
              Icons.chevron_right_rounded,
              size: 19,
              color: Colors.white70,
            ),
          ),
        ),
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expanded
                ? Column(
                    children: [
                      _SidebarSubItem(
                        icon: Icons.format_list_bulleted,
                        label: 'List of Assets',
                        selected: widget.selected == WebAssetSection.assets,
                        onTap: () => widget.onSelected(WebAssetSection.assets),
                      ),
                      _SidebarSubItem(
                        icon: Icons.open_with,
                        label: 'Move',
                        selected: widget.selected == WebAssetSection.transfer,
                        onTap: () =>
                            widget.onSelected(WebAssetSection.transfer),
                      ),
                      _SidebarSubItem(
                        icon: Icons.change_circle_outlined,
                        label: 'Dispose',
                        selected: widget.selected == WebAssetSection.dispose,
                        onTap: () => widget.onSelected(WebAssetSection.dispose),
                      ),
                      _SidebarSubItem(
                        icon: Icons.settings_suggest_outlined,
                        label: 'Maintenance',
                        selected:
                            widget.selected == WebAssetSection.maintenance,
                        onTap: () =>
                            widget.onSelected(WebAssetSection.maintenance),
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ),
      ],
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
    this.trailing,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 190),
          height: 48,
          margin: const EdgeInsets.only(bottom: 5),
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            gradient: widget.selected
                ? const LinearGradient(
                    colors: [Color(0xFF294AEF), Color(0xFF00BDEB)],
                  )
                : null,
            color: !widget.selected && hovered
                ? Colors.white.withValues(alpha: .075)
                : null,
            borderRadius: BorderRadius.circular(13),
            boxShadow: widget.selected
                ? const [
                    BoxShadow(
                      color: Color(0x552358FF),
                      blurRadius: 20,
                      offset: Offset(0, 7),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: widget.selected || hovered
                    ? Colors.white
                    : Colors.white70,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: widget.selected || hovered
                        ? Colors.white
                        : Colors.white70,
                    fontWeight: widget.selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
              if (widget.badge != null)
                CircleAvatar(
                  radius: 11,
                  backgroundColor: Colors.redAccent,
                  child: Text(
                    widget.badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
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
        margin: const EdgeInsets.only(bottom: 3),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: .1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.only(left: 40, right: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? AppColors.cyan : Colors.white54,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: selected ? Colors.white : Colors.white60,
              ),
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

class _MetricTile extends StatefulWidget {
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
  State<_MetricTile> createState() => _MetricTileState();
}

class _MetricTileState extends State<_MetricTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) {
        if (!_isHovered) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) {
        if (_isHovered) {
          setState(() => _isHovered = false);
        }
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: _isHovered ? 1 : 0),
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        builder: (context, animationValue, child) {
          final hoverValue = animationValue.clamp(0.0, 1.0);
          final rotationAngle = 0.785398 * hoverValue;

          final borderColor = Color.lerp(
            AppColors.border,
            widget.color.withValues(alpha: 0.48),
            hoverValue,
          )!;

          final cardColor = Color.lerp(
            Colors.white,
            widget.color.withValues(alpha: 0.035),
            hoverValue,
          )!;

          return Transform.translate(
            offset: Offset(0, -6 * hoverValue),
            child: Transform.scale(
              scale: 1 + (0.012 * hoverValue),
              alignment: Alignment.center,
              child: SizedBox(
                height: 112,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderColor, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: 0.045 + (0.025 * hoverValue),
                              ),
                              blurRadius: 12 + (10 * hoverValue),
                              offset: Offset(0, 5 + (5 * hoverValue)),
                            ),
                            BoxShadow(
                              color: widget.color.withValues(
                                alpha: 0.12 * hoverValue,
                              ),
                              blurRadius: 26,
                              spreadRadius: -5,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Positioned(
                      top: 0,
                      left: 28,
                      right: 28,
                      child: Opacity(
                        opacity: hoverValue,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.color.withValues(alpha: 0),
                                widget.color,
                                widget.color.withValues(alpha: 0),
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      right: -25,
                      bottom: -45,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: 0.025 + (0.035 * hoverValue),
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.color,
                            ),
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      left: 18,
                      top: 25 - (10 * hoverValue),
                      child: Transform.rotate(
                        angle: rotationAngle,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color.lerp(
                                  widget.color.withValues(alpha: 0.76),
                                  widget.color.withValues(alpha: 0.88),
                                  hoverValue,
                                )!,
                                widget.color,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              16 - (3 * hoverValue),
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.color.withValues(
                                  alpha: 0.25 + (0.12 * hoverValue),
                                ),
                                blurRadius: 15 + (7 * hoverValue),
                                offset: Offset(0, 7 + (3 * hoverValue)),
                              ),
                            ],
                          ),
                          child: Transform.rotate(
                            angle: -rotationAngle,
                            child: Icon(
                              widget.icon,
                              color: Colors.white,
                              size: 29 + (2 * hoverValue),
                            ),
                          ),
                        ),
                      ),
                    ),

                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(96, 15, 16, 15),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.1,
                                color: Color.lerp(
                                  AppColors.text,
                                  widget.color,
                                  hoverValue * 0.55,
                                ),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Flexible(
                                  flex: 0,
                                  child: Text(
                                    widget.value,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 23,
                                      height: 1,
                                      color: AppColors.text,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.35,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 1),
                                    child: Text(
                                      widget.subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        height: 1.2,
                                        color: AppColors.subText,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
}

class _WebLoadingView extends StatelessWidget {
  final String message;

  const _WebLoadingView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please wait a moment',
              style: TextStyle(color: AppColors.subText, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _MultiAssetSearchDialog extends StatefulWidget {
  final List<AssetStockModel> assets;
  final List<String> branches;
  final String? initialBranch;
  final String actionLabel;

  const _MultiAssetSearchDialog({
    required this.assets,
    required this.branches,
    required this.initialBranch,
    required this.actionLabel,
  });

  @override
  State<_MultiAssetSearchDialog> createState() =>
      _MultiAssetSearchDialogState();
}

class _MultiAssetSearchDialogState extends State<_MultiAssetSearchDialog> {
  final searchController = TextEditingController();
  final Map<String, AssetStockModel> selectedAssets = {};
  String search = '';
  String? selectedBranch;

  @override
  void initState() {
    super.initState();
    selectedBranch = widget.initialBranch;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<AssetStockModel> get suggestions {
    final query = search.trim().toLowerCase();
    if (query.isEmpty) return const [];

    return widget.assets
        .where((asset) {
          final matchesBranch =
              selectedBranch == null || asset.location == selectedBranch;
          final matchesSearch =
              asset.name.toLowerCase().contains(query) ||
              asset.itemCode.toLowerCase().contains(query) ||
              asset.assetCode.toLowerCase().contains(query) ||
              asset.description.toLowerCase().contains(query) ||
              asset.category.toLowerCase().contains(query) ||
              asset.subCategory.toLowerCase().contains(query) ||
              asset.brand.toLowerCase().contains(query) ||
              asset.location.toLowerCase().contains(query) ||
              asset.projectName.toLowerCase().contains(query);
          return matchesBranch && matchesSearch;
        })
        .toList(growable: false);
  }

  void _toggleAsset(AssetStockModel asset) {
    setState(() {
      if (selectedAssets.containsKey(asset.itemCode)) {
        selectedAssets.remove(asset.itemCode);
      } else {
        selectedAssets[asset.itemCode] = asset;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = suggestions;

    return AlertDialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Row(
        children: [
          const Expanded(child: Text('Select Assets')),
          if (selectedAssets.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${selectedAssets.length} selected',
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: 900,
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: searchController,
                    autofocus: true,
                    onChanged: (value) => setState(() => search = value),
                    decoration: InputDecoration(
                      hintText: 'Search by asset, tag ID, site or location...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: search.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                searchController.clear();
                                setState(() => search = '');
                              },
                              icon: const Icon(Icons.close, size: 19),
                            ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedBranch,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Locations'),
                      ),
                      ...widget.branches.map(
                        (branch) => DropdownMenuItem<String>(
                          value: branch,
                          child: Text(branch, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => selectedBranch = value),
                  ),
                ),
              ],
            ),
            if (selectedAssets.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedAssets.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final asset = selectedAssets.values.elementAt(index);
                    return InputChip(
                      label: Text('${asset.itemCode} · ${asset.location}'),
                      onDeleted: () => _toggleAsset(asset),
                      deleteIcon: const Icon(Icons.close, size: 17),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: search.trim().isEmpty
                    ? const _AssetSearchPrompt()
                    : results.isEmpty
                    ? const Center(child: Text('No matching assets found'))
                    : Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            color: AppColors.blueSoft,
                            child: Text(
                              '${results.length} matching assets',
                              style: const TextStyle(
                                color: AppColors.subText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              itemCount: results.length,
                              separatorBuilder: (_, _) => const Divider(
                                height: 1,
                                color: AppColors.border,
                              ),
                              itemBuilder: (context, index) {
                                final asset = results[index];
                                final isSelected = selectedAssets.containsKey(
                                  asset.itemCode,
                                );
                                return Material(
                                  color: isSelected
                                      ? const Color(0xfffff8de)
                                      : Colors.white,
                                  child: InkWell(
                                    onTap: () => _toggleAsset(asset),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      child: Row(
                                        children: [
                                          Checkbox(
                                            value: isSelected,
                                            onChanged: (_) =>
                                                _toggleAsset(asset),
                                          ),
                                          _AssetImage(path: asset.imagePath),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            flex: 2,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  asset.name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  asset.itemCode,
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.primaryColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: _SearchResultInfo(
                                              icon: Icons.location_on_outlined,
                                              label: 'Location',
                                              value: asset.location,
                                            ),
                                          ),
                                          Expanded(
                                            child: _SearchResultInfo(
                                              icon: Icons.business_outlined,
                                              label: 'Site',
                                              value: asset.projectName,
                                            ),
                                          ),
                                          _StatusPill(status: asset.status),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
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
        ElevatedButton.icon(
          onPressed: selectedAssets.isEmpty
              ? null
              : () => Navigator.pop(
                  context,
                  selectedAssets.values.toList(growable: false),
                ),
          icon: const Icon(Icons.arrow_forward, color: Colors.white),
          label: Text(
            selectedAssets.isEmpty
                ? widget.actionLabel
                : '${widget.actionLabel} (${selectedAssets.length})',
            style: const TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ],
    );
  }
}

class _AssetSearchPrompt extends StatelessWidget {
  const _AssetSearchPrompt();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.manage_search, size: 48, color: AppColors.subText),
          SizedBox(height: 10),
          Text(
            'Start typing to find assets',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 5),
          Text(
            'Suggestions will appear with their location and site',
            style: TextStyle(color: AppColors.subText),
          ),
        ],
      ),
    );
  }
}

class _SearchResultInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SearchResultInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.subText),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.subText),
              ),
              Text(
                value.trim().isEmpty ? '-' : value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PagedItems<T> {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;

  const _PagedItems({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
  });
}

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    var firstPage = currentPage - 2;
    if (firstPage < 0) firstPage = 0;
    var lastPage = firstPage + 4;
    if (lastPage >= totalPages) lastPage = totalPages - 1;
    firstPage = (lastPage - 4).clamp(0, totalPages - 1);

    final firstItem = currentPage * pageSize + 1;
    final lastItem = ((currentPage + 1) * pageSize).clamp(0, totalItems);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            'Showing $firstItem–$lastItem of $totalItems assets',
            style: const TextStyle(
              color: AppColors.subText,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _PaginationIconButton(
            tooltip: 'First page',
            icon: Icons.first_page,
            enabled: currentPage > 0,
            onPressed: () => onPageChanged(0),
          ),
          _PaginationIconButton(
            tooltip: 'Previous page',
            icon: Icons.chevron_left,
            enabled: currentPage > 0,
            onPressed: () => onPageChanged(currentPage - 1),
          ),
          const SizedBox(width: 6),
          for (var page = firstPage; page <= lastPage; page++) ...[
            _PaginationPageButton(
              page: page,
              selected: page == currentPage,
              onPressed: () => onPageChanged(page),
            ),
            if (page != lastPage) const SizedBox(width: 5),
          ],
          const SizedBox(width: 6),
          _PaginationIconButton(
            tooltip: 'Next page',
            icon: Icons.chevron_right,
            enabled: currentPage < totalPages - 1,
            onPressed: () => onPageChanged(currentPage + 1),
          ),
          _PaginationIconButton(
            tooltip: 'Last page',
            icon: Icons.last_page,
            enabled: currentPage < totalPages - 1,
            onPressed: () => onPageChanged(totalPages - 1),
          ),
        ],
      ),
    );
  }
}

class _PaginationIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _PaginationIconButton({
    required this.tooltip,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 20),
    );
  }
}

class _PaginationPageButton extends StatelessWidget {
  final int page;
  final bool selected;
  final VoidCallback onPressed;

  const _PaginationPageButton({
    required this.page,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: selected ? Colors.white : AppColors.headerText,
          backgroundColor: selected ? AppColors.primaryColor : Colors.white,
          side: BorderSide(
            color: selected ? AppColors.primaryColor : AppColors.border,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(
          '${page + 1}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
    return WebHoverSurface(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty || trailing != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 17, 20, 15),
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
                            fontSize: 16,
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
                            fontSize: 16,
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
          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }
}

class _ListToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final String searchHint;
  final String? selectedStatus;
  final List<String> statuses;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onExport;
  final bool showStatusAndExport;

  const _ListToolbar({
    required this.searchController,
    required this.searchHint,
    required this.selectedStatus,
    required this.statuses,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onExport,
    this.showStatusAndExport = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: showStatusAndExport ? 195 : 280,
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: searchHint,
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
            ),
          ),
        ),
        if (showStatusAndExport) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 135,
            child: DropdownButtonFormField<String>(
              key: ValueKey(selectedStatus),
              initialValue: selectedStatus ?? '__all__',
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Status',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(
                  value: '__all__',
                  child: Text('All Statuses'),
                ),
                ...statuses.map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _assetStatusColor(status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(status, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: (value) =>
                  onStatusChanged(value == '__all__' ? null : value),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onExport,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: const Text('Export'),
          ),
        ],
      ],
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
          color: AppColors.blueSoft,
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
          ? Image.network(
              path!,
              width: 38,
              height: 38,
              cacheWidth: 96,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              errorBuilder: (_, _, _) => const Icon(
                Icons.broken_image_outlined,
                color: AppColors.subText,
                size: 20,
              ),
            )
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
      color: AppColors.blueSoft,
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

Color _assetStatusColor(String status) {
  switch (status.trim().toLowerCase()) {
    case 'damaged':
    case 'bad':
    case 'disposed':
    case 'lost':
      return const Color(0xFFE53935);
    case 'maintenance':
    case 'in maintenance':
      return const Color(0xFFF59E0B);
    case 'new':
      return const Color(0xFF2563EB);
    case 'reserved':
      return const Color(0xFF7C3AED);
    case 'good':
    case 'active':
      return const Color(0xFF22A447);
    default:
      return AppColors.subText;
  }
}

class _AlertSummaryCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String note;

  const _AlertSummaryCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return WebHoverSurface(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertEmptyState extends StatelessWidget {
  const _AlertEmptyState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: const BoxDecoration(
                color: AppColors.blueSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 34,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Everything looks clear',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'There are no maintenance alerts due in the next 3 days.',
              style: TextStyle(color: AppColors.subText),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _assetStatusColor(status);

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

class _PrintClassificationOption extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final int count;
  final Color color;
  final VoidCallback onTap;
  final bool highlighted;
  final bool compact;

  const _PrintClassificationOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.count,
    required this.color,
    required this.onTap,
    this.highlighted = false,
    this.compact = false,
  });

  @override
  State<_PrintClassificationOption> createState() =>
      _PrintClassificationOptionState();
}

class _PrintClassificationOptionState
    extends State<_PrintClassificationOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!_hovered) {
          setState(() => _hovered = true);
        }
      },
      onExit: (_) {
        if (_hovered) {
          setState(() => _hovered = false);
        }
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: _hovered ? 1 : 0),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, -2.5 * value),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.compact ? 14 : 16,
                    vertical: widget.compact ? 14 : 15,
                  ),
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      Colors.white,
                      widget.color.withValues(alpha: 0.055),
                      value,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Color.lerp(
                        const Color(0xffe0e6ef),
                        widget.color.withValues(alpha: 0.48),
                        value,
                      )!,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.13 * value),
                        blurRadius: 20,
                        spreadRadius: -8,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: widget.compact ? 43 : 48,
                        height: widget.compact ? 43 : 48,
                        decoration: BoxDecoration(
                          color: widget.color.withValues(
                            alpha: widget.highlighted
                                ? 0.14
                                : 0.10 + (0.05 * value),
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          widget.icon,
                          size: widget.compact ? 21 : 23,
                          color: widget.color,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                height: 1.15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xff25324a),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              widget.description,
                              maxLines: widget.compact ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                                color: Color(0xff8190a6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: widget.color.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.count.toString(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: widget.color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          AnimatedSlide(
                            duration: const Duration(milliseconds: 220),
                            offset: _hovered
                                ? Offset.zero
                                : const Offset(-0.18, 0),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: Color.lerp(
                                const Color(0xffa1acbd),
                                widget.color,
                                value,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MaintenanceHeroCard extends StatelessWidget {
  final int totalAssets;
  final String? selectedBranch;
  final VoidCallback onExport;
  final VoidCallback onSelectAssets;

  const _MaintenanceHeroCard({
    required this.totalAssets,
    required this.selectedBranch,
    required this.onExport,
    required this.onSelectAssets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 178),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff102b50), Color(0xff174b82), Color(0xff2463a8)],
          stops: [0, 0.55, 1],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff174b82).withValues(alpha: 0.24),
            blurRadius: 34,
            spreadRadius: -10,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(
              right: -90,
              top: -130,
              child: Container(
                width: 310,
                height: 310,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.055),
                ),
              ),
            ),
            Positioned(
              right: 155,
              bottom: -115,
              child: Container(
                width: 245,
                height: 245,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xff59d5e0).withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              right: 45,
              top: 20,
              child: Transform.rotate(
                angle: -0.13,
                child: Icon(
                  Icons.settings_suggest_rounded,
                  size: 142,
                  color: Colors.white.withValues(alpha: 0.055),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 27),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 820;

                  final information = Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.17),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 18,
                              offset: const Offset(0, 9),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.engineering_rounded,
                          color: Colors.white,
                          size: 33,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  'Maintenance Center',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 27,
                                    height: 1.15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.7,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.16,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    '$totalAssets assets',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 9),
                            const Text(
                              'Track service activity, update maintenance details '
                              'and return assets to operation efficiently.',
                              style: TextStyle(
                                color: Color(0xffd9e8f8),
                                fontSize: 13,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 13),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: Color(0xff9fd8ff),
                                  size: 17,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    selectedBranch ?? 'All Branches',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xffd9e8f8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  final actions = Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.end,
                    children: [
                      _MaintenanceHeroButton(
                        icon: Icons.file_download_outlined,
                        label: 'Export',
                        filled: false,
                        onTap: onExport,
                      ),
                      _MaintenanceHeroButton(
                        icon: Icons.add_rounded,
                        label: 'Select Assets',
                        filled: true,
                        onTap: onSelectAssets,
                      ),
                    ],
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        information,
                        const SizedBox(height: 24),
                        actions,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: information),
                      const SizedBox(width: 24),
                      actions,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaintenanceHeroButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _MaintenanceHeroButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  State<_MaintenanceHeroButton> createState() => _MaintenanceHeroButtonState();
}

class _MaintenanceHeroButtonState extends State<_MaintenanceHeroButton> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: hovered ? 1 : 0),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, -3 * value),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(13),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  decoration: BoxDecoration(
                    color: widget.filled
                        ? Color.lerp(
                            Colors.white,
                            const Color(0xfff0f7ff),
                            value,
                          )
                        : Colors.white.withValues(alpha: 0.10 + (value * 0.06)),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: widget.filled
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.25),
                    ),
                    boxShadow: widget.filled
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: 0.08 + (0.05 * value),
                              ),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.icon,
                        size: 19,
                        color: widget.filled
                            ? const Color(0xff1d5c9e)
                            : Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: widget.filled
                              ? const Color(0xff1d5c9e)
                              : Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MaintenanceStatCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String subtitle;

  const _MaintenanceStatCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  State<_MaintenanceStatCard> createState() => _MaintenanceStatCardState();
}

class _MaintenanceStatCardState extends State<_MaintenanceStatCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: hovered ? 1 : 0),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        builder: (context, animationValue, child) {
          return Transform.translate(
            offset: Offset(0, -5 * animationValue),
            child: Container(
              height: 116,
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: Color.lerp(
                  Colors.white,
                  widget.color.withValues(alpha: 0.035),
                  animationValue,
                ),
                borderRadius: BorderRadius.circular(19),
                border: Border.all(
                  color: Color.lerp(
                    const Color(0xffdfe7f2),
                    widget.color.withValues(alpha: 0.38),
                    animationValue,
                  )!,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.035 + (0.025 * animationValue),
                    ),
                    blurRadius: 18 + (10 * animationValue),
                    spreadRadius: -7,
                    offset: Offset(0, 8 + (4 * animationValue)),
                  ),
                  BoxShadow(
                    color: widget.color.withValues(
                      alpha: 0.09 * animationValue,
                    ),
                    blurRadius: 28,
                    spreadRadius: -12,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    bottom: -35,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color.withValues(
                          alpha: 0.025 + (animationValue * 0.025),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: widget.color.withValues(
                            alpha: 0.10 + (animationValue * 0.05),
                          ),
                          borderRadius: BorderRadius.circular(
                            16 - (animationValue * 2),
                          ),
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.color,
                          size: 26 + (animationValue * 2),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xff75839a),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              widget.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xff16243c),
                                fontSize: 23,
                                height: 1,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xff9aa5b5),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MaintenanceInformationIcon extends StatelessWidget {
  const _MaintenanceInformationIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xff4169e1).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Icon(
        Icons.info_outline_rounded,
        color: Color(0xff4169e1),
        size: 20,
      ),
    );
  }
}

class _ModernMaintenanceTableHeader extends StatelessWidget {
  const _ModernMaintenanceTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xfff1f5fb),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xffdfe7f2)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 56, child: _ModernMaintenanceHeaderText('Photo')),
          Expanded(
            flex: 2,
            child: _ModernMaintenanceHeaderText('Asset Tag ID'),
          ),
          Expanded(
            flex: 3,
            child: _ModernMaintenanceHeaderText('Asset Details'),
          ),
          Expanded(flex: 2, child: _ModernMaintenanceHeaderText('Status')),
          Expanded(flex: 2, child: _ModernMaintenanceHeaderText('Site')),
          Expanded(flex: 2, child: _ModernMaintenanceHeaderText('Location')),
          SizedBox(
            width: 146,
            child: _ModernMaintenanceHeaderText(
              'Maintenance',
              alignment: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernMaintenanceHeaderText extends StatelessWidget {
  final String label;
  final TextAlign alignment;

  const _ModernMaintenanceHeaderText(
    this.label, {
    this.alignment = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: alignment,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xff53627a),
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.05,
      ),
    );
  }
}

class _ModernMaintenanceAssetRow extends StatefulWidget {
  final AssetStockModel asset;
  final int animationDelay;
  final VoidCallback onDetails;
  final VoidCallback onEdit;

  const _ModernMaintenanceAssetRow({
    super.key,
    required this.asset,
    required this.animationDelay,
    required this.onDetails,
    required this.onEdit,
  });

  @override
  State<_ModernMaintenanceAssetRow> createState() =>
      _ModernMaintenanceAssetRowState();
}

class _ModernMaintenanceAssetRowState
    extends State<_ModernMaintenanceAssetRow> {
  bool hovered = false;
  bool visible = false;

  @override
  void initState() {
    super.initState();

    Future<void>.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (!mounted) return;

      setState(() {
        visible = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.asset;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOut,
      opacity: visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        offset: visible ? Offset.zero : const Offset(0.025, 0),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => hovered = true),
          onExit: (_) => setState(() => hovered = false),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: hovered ? 1 : 0),
            duration: const Duration(milliseconds: 210),
            curve: Curves.easeOutCubic,
            builder: (context, hoverValue, child) {
              return Transform.translate(
                offset: Offset(4 * hoverValue, 0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onDetails,
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 210),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          Colors.white,
                          const Color(0xfff7faff),
                          hoverValue,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Color.lerp(
                            const Color(0xffedf1f6),
                            const Color(0xffb9ccef),
                            hoverValue,
                          )!,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xff294f87,
                            ).withValues(alpha: 0.065 * hoverValue),
                            blurRadius: 20,
                            spreadRadius: -8,
                            offset: const Offset(0, 9),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 56,
                            child: Hero(
                              tag: 'maintenance-image-${asset.itemCode}',
                              child: _AssetImage(path: asset.imagePath),
                            ),
                          ),

                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: WebAssetColors.classification(
                                      asset.classification,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: WebAssetColors.classification(
                                          asset.classification,
                                        ).withValues(alpha: 0.26),
                                        blurRadius: 7,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    asset.itemCode,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xff2664c7),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    asset.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xff24324a),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (asset.category.trim().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      asset.category,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xff96a1b1),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          Expanded(
                            flex: 2,
                            child: _StatusPill(status: asset.status),
                          ),

                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.business_outlined,
                                    size: 16,
                                    color: Color(0xff9aa6b7),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      asset.projectName.trim().isEmpty
                                          ? '-'
                                          : asset.projectName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xff46546b),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: Color(0xff9aa6b7),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      asset.location.trim().isEmpty
                                          ? '-'
                                          : asset.location,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xff46546b),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(
                            width: 146,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _MaintenanceEditButton(
                                onTap: widget.onEdit,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MaintenanceEditButton extends StatefulWidget {
  final VoidCallback onTap;

  const _MaintenanceEditButton({required this.onTap});

  @override
  State<_MaintenanceEditButton> createState() => _MaintenanceEditButtonState();
}

class _MaintenanceEditButtonState extends State<_MaintenanceEditButton> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: hovered ? 1 : 0),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 1 + (0.025 * value),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(11),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.lerp(
                          const Color(0xff4263eb),
                          const Color(0xff3451d1),
                          value,
                        )!,
                        Color.lerp(
                          const Color(0xff5475f5),
                          const Color(0xff4263eb),
                          value,
                        )!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xff4263eb,
                        ).withValues(alpha: 0.20 + (value * 0.10)),
                        blurRadius: 13 + (value * 5),
                        spreadRadius: -5,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 7),
                      Text(
                        'Edit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MaintenanceEmptyState extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onSelectAssets;

  const _MaintenanceEmptyState({
    required this.hasSearch,
    required this.onSelectAssets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 285),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: const Color(0xfffbfcfe),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xffe6ebf2)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 35),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xffedf3ff), Color(0xffe8f6fb)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xffd7e4fa)),
                ),
                child: Icon(
                  hasSearch
                      ? Icons.search_off_rounded
                      : Icons.engineering_outlined,
                  color: const Color(0xff4263eb),
                  size: 36,
                ),
              ),
              const SizedBox(height: 17),
              Text(
                hasSearch
                    ? 'No matching maintenance assets'
                    : 'No assets under maintenance',
                style: const TextStyle(
                  color: Color(0xff26354d),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                hasSearch
                    ? 'Try another asset name, tag ID, site or location.'
                    : 'Select an asset to create its first maintenance record.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xff8b98aa),
                  fontSize: 12.5,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (!hasSearch) ...[
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: onSelectAssets,
                  icon: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                  label: const Text(
                    'Select Assets',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff4263eb),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DisposedHeroCard extends StatelessWidget {
  final int totalAssets;
  final String? selectedBranch;
  final VoidCallback onExport;
  final VoidCallback onSelectAssets;

  const _DisposedHeroCard({
    required this.totalAssets,
    required this.selectedBranch,
    required this.onExport,
    required this.onSelectAssets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 178),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff102b50), Color(0xff174b82), Color(0xff2463a8)],
          stops: [0, 0.55, 1],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff174b82).withValues(alpha: 0.24),
            blurRadius: 34,
            spreadRadius: -10,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(
              right: -90,
              top: -130,
              child: Container(
                width: 310,
                height: 310,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.055),
                ),
              ),
            ),
            Positioned(
              right: 155,
              bottom: -115,
              child: Container(
                width: 245,
                height: 245,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xffff7b7f).withValues(alpha: 0.075),
                ),
              ),
            ),
            Positioned(
              right: 43,
              top: 18,
              child: Transform.rotate(
                angle: -0.10,
                child: Icon(
                  Icons.delete_sweep_outlined,
                  size: 145,
                  color: Colors.white.withValues(alpha: 0.055),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 27),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 820;

                  final information = Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.17),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 18,
                              offset: const Offset(0, 9),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  'Disposal Center',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 27,
                                    height: 1.15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.7,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xffff7b7f,
                                    ).withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(
                                        0xffffb6b8,
                                      ).withValues(alpha: 0.27),
                                    ),
                                  ),
                                  child: Text(
                                    '$totalAssets disposed',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 9),
                            const Text(
                              'Maintain a clear disposal register, document '
                              'asset retirement and preserve a complete audit trail.',
                              style: TextStyle(
                                color: Color(0xffd9e8f8),
                                fontSize: 13,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 13),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: Color(0xff9fd8ff),
                                  size: 17,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    selectedBranch ?? 'All Branches',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xffd9e8f8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  final actions = Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.end,
                    children: [
                      _MaintenanceHeroButton(
                        icon: Icons.file_download_outlined,
                        label: 'Export',
                        filled: false,
                        onTap: onExport,
                      ),
                      _MaintenanceHeroButton(
                        icon: Icons.add_rounded,
                        label: 'Select Assets',
                        filled: true,
                        onTap: onSelectAssets,
                      ),
                    ],
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        information,
                        const SizedBox(height: 24),
                        actions,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: information),
                      const SizedBox(width: 24),
                      actions,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisposedInformationIcon extends StatelessWidget {
  const _DisposedInformationIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xffe5484d).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Icon(
        Icons.info_outline_rounded,
        color: Color(0xffd9363e),
        size: 20,
      ),
    );
  }
}

class _ModernDisposedTableHeader extends StatelessWidget {
  const _ModernDisposedTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xfff1f5fb),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xffdfe7f2)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 56, child: _ModernDisposedHeaderText('Photo')),
          Expanded(flex: 2, child: _ModernDisposedHeaderText('Asset Tag ID')),
          Expanded(flex: 3, child: _ModernDisposedHeaderText('Asset Details')),
          Expanded(flex: 2, child: _ModernDisposedHeaderText('Status')),
          Expanded(flex: 2, child: _ModernDisposedHeaderText('Site')),
          Expanded(flex: 2, child: _ModernDisposedHeaderText('Location')),
          SizedBox(
            width: 146,
            child: _ModernDisposedHeaderText(
              'Disposal',
              alignment: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernDisposedHeaderText extends StatelessWidget {
  final String label;
  final TextAlign alignment;

  const _ModernDisposedHeaderText(
    this.label, {
    this.alignment = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: alignment,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xff53627a),
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.05,
      ),
    );
  }
}

class _ModernDisposedAssetRow extends StatefulWidget {
  final AssetStockModel asset;
  final int animationDelay;
  final VoidCallback onDetails;
  final VoidCallback onEdit;

  const _ModernDisposedAssetRow({
    super.key,
    required this.asset,
    required this.animationDelay,
    required this.onDetails,
    required this.onEdit,
  });

  @override
  State<_ModernDisposedAssetRow> createState() =>
      _ModernDisposedAssetRowState();
}

class _ModernDisposedAssetRowState extends State<_ModernDisposedAssetRow> {
  bool hovered = false;
  bool visible = false;

  @override
  void initState() {
    super.initState();

    Future<void>.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (!mounted) return;

      setState(() {
        visible = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.asset;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOut,
      opacity: visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        offset: visible ? Offset.zero : const Offset(0.025, 0),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => hovered = true),
          onExit: (_) => setState(() => hovered = false),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: hovered ? 1 : 0),
            duration: const Duration(milliseconds: 210),
            curve: Curves.easeOutCubic,
            builder: (context, hoverValue, child) {
              return Transform.translate(
                offset: Offset(4 * hoverValue, 0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onDetails,
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 210),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          Colors.white,
                          const Color(0xfffff9f9),
                          hoverValue,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Color.lerp(
                            const Color(0xffedf1f6),
                            const Color(0xffffc6c8),
                            hoverValue,
                          )!,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xffc9343b,
                            ).withValues(alpha: 0.06 * hoverValue),
                            blurRadius: 20,
                            spreadRadius: -8,
                            offset: const Offset(0, 9),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 56,
                            child: Hero(
                              tag: 'disposed-image-${asset.itemCode}',
                              child: _AssetImage(path: asset.imagePath),
                            ),
                          ),

                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: WebAssetColors.classification(
                                      asset.classification,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: WebAssetColors.classification(
                                          asset.classification,
                                        ).withValues(alpha: 0.26),
                                        blurRadius: 7,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    asset.itemCode,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xff2664c7),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    asset.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xff24324a),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (asset.category.trim().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      asset.category,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xff96a1b1),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          Expanded(
                            flex: 2,
                            child: _StatusPill(status: asset.status),
                          ),

                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.business_outlined,
                                    size: 16,
                                    color: Color(0xff9aa6b7),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      asset.projectName.trim().isEmpty
                                          ? '-'
                                          : asset.projectName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xff46546b),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: Color(0xff9aa6b7),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      asset.location.trim().isEmpty
                                          ? '-'
                                          : asset.location,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xff46546b),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(
                            width: 146,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _DisposedEditButton(onTap: widget.onEdit),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DisposedEditButton extends StatefulWidget {
  final VoidCallback onTap;

  const _DisposedEditButton({required this.onTap});

  @override
  State<_DisposedEditButton> createState() => _DisposedEditButtonState();
}

class _DisposedEditButtonState extends State<_DisposedEditButton> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: hovered ? 1 : 0),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 1 + (0.025 * value),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(11),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.lerp(
                          const Color(0xffe5484d),
                          const Color(0xffc9343b),
                          value,
                        )!,
                        Color.lerp(
                          const Color(0xfff05b61),
                          const Color(0xffe5484d),
                          value,
                        )!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xffe5484d,
                        ).withValues(alpha: 0.20 + (value * 0.10)),
                        blurRadius: 13 + (value * 5),
                        spreadRadius: -5,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 7),
                      Text(
                        'Edit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DisposedEmptyState extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onSelectAssets;

  const _DisposedEmptyState({
    required this.hasSearch,
    required this.onSelectAssets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 285),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: const Color(0xfffbfcfe),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xffe6ebf2)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 35),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xffffeeee), Color(0xfffff7f7)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xffffd6d8)),
                ),
                child: Icon(
                  hasSearch
                      ? Icons.search_off_rounded
                      : Icons.delete_outline_rounded,
                  color: const Color(0xffe5484d),
                  size: 36,
                ),
              ),
              const SizedBox(height: 17),
              Text(
                hasSearch
                    ? 'No matching disposed assets'
                    : 'No disposed assets found',
                style: const TextStyle(
                  color: Color(0xff26354d),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                hasSearch
                    ? 'Try another asset name, tag ID, site or location.'
                    : 'Select an asset to document its disposal details.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xff8b98aa),
                  fontSize: 12.5,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (!hasSearch) ...[
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: onSelectAssets,
                  icon: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                  label: const Text(
                    'Select Assets',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffe5484d),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TransferHeroCard extends StatelessWidget {
  final String title;
  final int totalAssets;
  final String? selectedBranch;
  final VoidCallback onExport;

  const _TransferHeroCard({
    required this.title,
    required this.totalAssets,
    required this.selectedBranch,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 178),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff102b50), Color(0xff174b82), Color(0xff2463a8)],
          stops: [0, 0.55, 1],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff174b82).withValues(alpha: 0.24),
            blurRadius: 34,
            spreadRadius: -10,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(
              right: -90,
              top: -130,
              child: Container(
                width: 310,
                height: 310,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.055),
                ),
              ),
            ),
            Positioned(
              right: 155,
              bottom: -115,
              child: Container(
                width: 245,
                height: 245,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xff59d5e0).withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              right: 42,
              top: 20,
              child: Transform.rotate(
                angle: -0.13,
                child: Icon(
                  Icons.swap_horiz_rounded,
                  size: 142,
                  color: Colors.white.withValues(alpha: 0.055),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 27),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 820;

                  final information = Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.17),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 18,
                              offset: const Offset(0, 9),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.compare_arrows_rounded,
                          color: Colors.white,
                          size: 33,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 27,
                                    height: 1.15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.7,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.16,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    '$totalAssets assets',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 9),
                            const Text(
                              'Move assets between branches and sites with a clear, '
                              'organized transfer workflow and better visibility.',
                              style: TextStyle(
                                color: Color(0xffd9e8f8),
                                fontSize: 13,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 13),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: Color(0xff9fd8ff),
                                  size: 17,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    selectedBranch ?? 'All Branches',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xffd9e8f8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  final actions = Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.end,
                    children: [
                      _MaintenanceHeroButton(
                        icon: Icons.file_download_outlined,
                        label: 'Export',
                        filled: false,
                        onTap: onExport,
                      ),
                    ],
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        information,
                        const SizedBox(height: 24),
                        actions,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: information),
                      const SizedBox(width: 24),
                      actions,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferInformationIcon extends StatelessWidget {
  const _TransferInformationIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xff4169e1).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Icon(
        Icons.info_outline_rounded,
        color: Color(0xff4169e1),
        size: 20,
      ),
    );
  }
}

class _ModernTransferTableHeader extends StatelessWidget {
  final String operationLabel;

  const _ModernTransferTableHeader({required this.operationLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xfff1f5fb),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xffdfe7f2)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 56, child: _ModernTransferHeaderText('Photo')),
          const Expanded(
            flex: 2,
            child: _ModernTransferHeaderText('Asset Tag ID'),
          ),
          const Expanded(
            flex: 3,
            child: _ModernTransferHeaderText('Asset Details'),
          ),
          const Expanded(flex: 2, child: _ModernTransferHeaderText('Status')),
          const Expanded(flex: 2, child: _ModernTransferHeaderText('Site')),
          const Expanded(flex: 2, child: _ModernTransferHeaderText('Location')),
          SizedBox(
            width: 146,
            child: _ModernTransferHeaderText(
              operationLabel,
              alignment: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernTransferHeaderText extends StatelessWidget {
  final String label;
  final TextAlign alignment;

  const _ModernTransferHeaderText(
    this.label, {
    this.alignment = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: alignment,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xff53627a),
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.05,
      ),
    );
  }
}

class _ModernTransferAssetRow extends StatefulWidget {
  final AssetStockModel asset;
  final int animationDelay;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onDetails;
  final VoidCallback onOperation;

  const _ModernTransferAssetRow({
    super.key,
    required this.asset,
    required this.animationDelay,
    required this.actionLabel,
    required this.actionIcon,
    required this.onDetails,
    required this.onOperation,
  });

  @override
  State<_ModernTransferAssetRow> createState() =>
      _ModernTransferAssetRowState();
}

class _ModernTransferAssetRowState extends State<_ModernTransferAssetRow> {
  bool hovered = false;
  bool visible = false;

  @override
  void initState() {
    super.initState();

    Future<void>.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (!mounted) return;
      setState(() {
        visible = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.asset;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOut,
      opacity: visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        offset: visible ? Offset.zero : const Offset(0.025, 0),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => hovered = true),
          onExit: (_) => setState(() => hovered = false),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: hovered ? 1 : 0),
            duration: const Duration(milliseconds: 210),
            curve: Curves.easeOutCubic,
            builder: (context, hoverValue, child) {
              return Transform.translate(
                offset: Offset(4 * hoverValue, 0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onDetails,
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 210),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          Colors.white,
                          const Color(0xfff7faff),
                          hoverValue,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Color.lerp(
                            const Color(0xffedf1f6),
                            const Color(0xffb9ccef),
                            hoverValue,
                          )!,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xff294f87,
                            ).withValues(alpha: 0.065 * hoverValue),
                            blurRadius: 20,
                            spreadRadius: -8,
                            offset: const Offset(0, 9),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 56,
                            child: Hero(
                              tag: 'transfer-image-${asset.itemCode}',
                              child: _AssetImage(path: asset.imagePath),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: WebAssetColors.classification(
                                      asset.classification,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: WebAssetColors.classification(
                                          asset.classification,
                                        ).withValues(alpha: 0.26),
                                        blurRadius: 7,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    asset.itemCode,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xff2664c7),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    asset.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xff24324a),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (asset.category.trim().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      asset.category,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xff96a1b1),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: _StatusPill(status: asset.status),
                          ),
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.business_outlined,
                                    size: 16,
                                    color: Color(0xff9aa6b7),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      asset.projectName.trim().isEmpty
                                          ? '-'
                                          : asset.projectName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xff46546b),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: Color(0xff9aa6b7),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      asset.location.trim().isEmpty
                                          ? '-'
                                          : asset.location,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xff46546b),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 146,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _TransferActionButton(
                                label: widget.actionLabel,
                                icon: widget.actionIcon,
                                onTap: widget.onOperation,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TransferActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _TransferActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_TransferActionButton> createState() => _TransferActionButtonState();
}

class _TransferActionButtonState extends State<_TransferActionButton> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: hovered ? 1 : 0),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 1 + (0.025 * value),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(11),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.lerp(
                          const Color(0xff4263eb),
                          const Color(0xff3451d1),
                          value,
                        )!,
                        Color.lerp(
                          const Color(0xff5475f5),
                          const Color(0xff4263eb),
                          value,
                        )!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xff4263eb,
                        ).withValues(alpha: 0.20 + (value * 0.10)),
                        blurRadius: 13 + (value * 5),
                        spreadRadius: -5,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon, color: Colors.white, size: 16),
                      const SizedBox(width: 7),
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TransferEmptyState extends StatelessWidget {
  final bool hasSearch;

  const _TransferEmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 285),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: const Color(0xfffbfcfe),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xffe6ebf2)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 35),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xffedf3ff), Color(0xffe8f6fb)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xffd7e4fa)),
                ),
                child: Icon(
                  hasSearch
                      ? Icons.search_off_rounded
                      : Icons.compare_arrows_rounded,
                  color: const Color(0xff4263eb),
                  size: 36,
                ),
              ),
              const SizedBox(height: 17),
              Text(
                hasSearch
                    ? 'No matching transferable assets'
                    : 'No assets available for transfer',
                style: const TextStyle(
                  color: Color(0xff26354d),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                hasSearch
                    ? 'Try another asset name, tag ID, site or location.'
                    : 'Assets will appear here once they are available to move between locations.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xff8b98aa),
                  fontSize: 12.5,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssetRegistryHeader extends StatelessWidget {
  final int totalAssets;
  final String? selectedBranch;
  final VoidCallback onAddAsset;
  final VoidCallback onExport;

  const _AssetRegistryHeader({
    required this.totalAssets,
    required this.selectedBranch,
    required this.onAddAsset,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 128),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffdfe7f2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff183b66).withValues(alpha: 0.06),
            blurRadius: 26,
            spreadRadius: -10,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 5,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xff4263eb),
                      Color(0xff2f80ed),
                      Color(0xff15aabf),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -36,
              top: -65,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xff4263eb).withValues(alpha: 0.035),
                ),
              ),
            ),
            Positioned(
              right: 110,
              bottom: -75,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xff15aabf).withValues(alpha: 0.025),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 780;

                  final information = Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xff4c6ef5),
                              Color(0xff2f80ed),
                              Color(0xff15aabf),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xff4263eb,
                              ).withValues(alpha: 0.25),
                              blurRadius: 20,
                              spreadRadius: -5,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.white,
                          size: 31,
                        ),
                      ),
                      const SizedBox(width: 17),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 10,
                              runSpacing: 7,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  'Asset Registry',
                                  style: TextStyle(
                                    color: Color(0xff17243b),
                                    fontSize: 25,
                                    height: 1.1,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.65,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffedf3ff),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xffd4e1ff),
                                    ),
                                  ),
                                  child: Text(
                                    '$totalAssets assets',
                                    style: const TextStyle(
                                      color: Color(0xff3156c8),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'A central workspace for searching, reviewing '
                              'and managing active company assets.',
                              style: TextStyle(
                                color: Color(0xff75839a),
                                fontSize: 12.5,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: Color(0xff6e7e95),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    selectedBranch ?? 'All Branches',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xff53627a),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  final actions = Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.end,
                    children: [
                      _AssetRegistryHeaderButton(
                        icon: Icons.file_download_outlined,
                        label: 'Export',
                        filled: false,
                        onTap: onExport,
                      ),
                      _AssetRegistryHeaderButton(
                        icon: Icons.add_rounded,
                        label: 'Add Asset',
                        filled: true,
                        onTap: onAddAsset,
                      ),
                    ],
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        information,
                        const SizedBox(height: 20),
                        actions,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: information),
                      const SizedBox(width: 24),
                      actions,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetRegistryHeaderButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _AssetRegistryHeaderButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  State<_AssetRegistryHeaderButton> createState() =>
      _AssetRegistryHeaderButtonState();
}

class _AssetRegistryHeaderButtonState
    extends State<_AssetRegistryHeaderButton> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: hovered ? 1 : 0),
        duration: const Duration(milliseconds: 190),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, -3 * value),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 190),
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: widget.filled
                        ? LinearGradient(
                            colors: [
                              Color.lerp(
                                const Color(0xff4263eb),
                                const Color(0xff3153d4),
                                value,
                              )!,
                              Color.lerp(
                                const Color(0xff2f80ed),
                                const Color(0xff4263eb),
                                value,
                              )!,
                            ],
                          )
                        : null,
                    color: widget.filled
                        ? null
                        : Color.lerp(
                            Colors.white,
                            const Color(0xfff4f7fc),
                            value,
                          ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.filled
                          ? const Color(0xff4263eb)
                          : Color.lerp(
                              const Color(0xffdce4ef),
                              const Color(0xffaebfe0),
                              value,
                            )!,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.filled
                            ? const Color(
                                0xff4263eb,
                              ).withValues(alpha: 0.18 + (0.09 * value))
                            : Colors.black.withValues(alpha: 0.025 * value),
                        blurRadius: 14 + (6 * value),
                        spreadRadius: -6,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.icon,
                        size: 18,
                        color: widget.filled
                            ? Colors.white
                            : const Color(0xff44536a),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: widget.filled
                              ? Colors.white
                              : const Color(0xff34435a),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AssetRegistrySummaryStrip extends StatelessWidget {
  final int totalAssets;
  final double totalValue;
  final int locationsCount;
  final int categoriesCount;

  const _AssetRegistrySummaryStrip({
    required this.totalAssets,
    required this.totalValue,
    required this.locationsCount,
    required this.categoriesCount,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _AssetRegistryMetricData(
        icon: Icons.widgets_outlined,
        color: const Color(0xff4263eb),
        label: 'Visible Assets',
        value: totalAssets.toString(),
        caption: 'Current filtered scope',
      ),
      _AssetRegistryMetricData(
        icon: Icons.payments_outlined,
        color: const Color(0xff0f9f8f),
        label: 'Asset Value',
        value: totalValue.toStringAsFixed(2),
        caption: 'Total value in AED',
      ),
      _AssetRegistryMetricData(
        icon: Icons.location_on_outlined,
        color: const Color(0xfff59f00),
        label: 'Locations',
        value: locationsCount.toString(),
        caption: 'Distinct asset locations',
      ),
      _AssetRegistryMetricData(
        icon: Icons.category_outlined,
        color: const Color(0xff7950f2),
        label: 'Categories',
        value: categoriesCount.toString(),
        caption: 'Asset category groups',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xfff9fbff), Color(0xfff7fafc)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffdfe7f2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff183b66).withValues(alpha: 0.035),
            blurRadius: 20,
            spreadRadius: -10,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) {
            return Row(
              children: [
                for (var index = 0; index < metrics.length; index++) ...[
                  Expanded(child: _AssetRegistryMetric(data: metrics[index])),
                  if (index != metrics.length - 1)
                    Container(
                      width: 1,
                      height: 54,
                      color: const Color(0xffe4eaf2),
                    ),
                ],
              ],
            );
          }

          final itemWidth = constraints.maxWidth >= 560
              ? (constraints.maxWidth - 8) / 2
              : constraints.maxWidth;

          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: metrics.map((metric) {
              return SizedBox(
                width: itemWidth,
                child: _AssetRegistryMetric(data: metric),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _AssetRegistryMetricData {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String caption;

  const _AssetRegistryMetricData({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.caption,
  });
}

class _AssetRegistryMetric extends StatefulWidget {
  final _AssetRegistryMetricData data;

  const _AssetRegistryMetric({required this.data});

  @override
  State<_AssetRegistryMetric> createState() => _AssetRegistryMetricState();
}

class _AssetRegistryMetricState extends State<_AssetRegistryMetric> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: hovered ? 1 : 0),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, -2.5 * value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 84,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              decoration: BoxDecoration(
                color: Color.lerp(
                  Colors.transparent,
                  data.color.withValues(alpha: 0.045),
                  value,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: data.color.withValues(
                        alpha: 0.10 + (0.04 * value),
                      ),
                      borderRadius: BorderRadius.circular(13 - (value * 1.5)),
                    ),
                    child: Icon(data.icon, color: data.color, size: 22 + value),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xff7d8a9e),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xff1a2940),
                            fontSize: 18,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xffa0aaba),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AssetRegistryToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final String? selectedStatus;
  final List<String> statuses;
  final int resultsCount;
  final bool hasFilters;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onClearFilters;

  const _AssetRegistryToolbar({
    required this.searchController,
    required this.selectedStatus,
    required this.statuses,
    required this.resultsCount,
    required this.hasFilters,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final searchField = Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xfff8fafd),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xffdfe7f2)),
      ),
      child: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        decoration: InputDecoration(
          hintText:
              'Search asset name, tag ID, category, brand, site or location',
          hintStyle: const TextStyle(
            color: Color(0xff909caf),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xff61718a),
            size: 21,
          ),
          suffixIcon: searchController.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    searchController.clear();
                    onSearchChanged('');
                  },
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
        ),
      ),
    );

    final statusFilter = Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafd),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xffdfe7f2)),
      ),
      child: DropdownButtonFormField<String>(
        key: ValueKey('registry-status-${selectedStatus ?? 'all'}'),
        initialValue: selectedStatus ?? '__all__',
        isExpanded: true,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Color(0xff63738b),
        ),
        decoration: const InputDecoration(
          labelText: 'Status',
          labelStyle: TextStyle(color: Color(0xff8794a7), fontSize: 11),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        items: [
          const DropdownMenuItem<String>(
            value: '__all__',
            child: Text(
              'All Statuses',
              style: TextStyle(
                color: Color(0xff34435a),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...statuses.map((status) {
            return DropdownMenuItem<String>(
              value: status,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _assetStatusColor(status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff34435a),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        onChanged: (value) {
          onStatusChanged(value == '__all__' ? null : value);
        },
      ),
    );

    final resultBox = Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xffedf4ff),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xffd4e1ff)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.filter_alt_outlined,
            color: Color(0xff4263eb),
            size: 18,
          ),
          const SizedBox(width: 7),
          Text(
            '$resultsCount results',
            style: const TextStyle(
              color: Color(0xff3156c8),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    final clearButton = Tooltip(
      message: 'Clear filters',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasFilters ? onClearFilters : null,
          borderRadius: BorderRadius.circular(13),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: hasFilters
                  ? const Color(0xfffff3f3)
                  : const Color(0xfff5f7fa),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: hasFilters
                    ? const Color(0xffffd3d5)
                    : const Color(0xffe3e8ef),
              ),
            ),
            child: Icon(
              Icons.filter_alt_off_rounded,
              size: 20,
              color: hasFilters
                  ? const Color(0xffd9485f)
                  : const Color(0xffb0b8c5),
            ),
          ),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 850) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchField,
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: statusFilter),
                  const SizedBox(width: 10),
                  resultBox,
                  const SizedBox(width: 10),
                  clearButton,
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: searchField),
            const SizedBox(width: 11),
            SizedBox(width: 190, child: statusFilter),
            const SizedBox(width: 11),
            resultBox,
            const SizedBox(width: 9),
            clearButton,
          ],
        );
      },
    );
  }
}

class _AssetRegistryTableHeader extends StatelessWidget {
  const _AssetRegistryTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xffedf3fc), Color(0xfff3f6fb)],
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xffdce5f1)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 62, child: _AssetRegistryHeaderText('Photo')),
          Expanded(flex: 2, child: _AssetRegistryHeaderText('Asset Tag ID')),
          Expanded(flex: 3, child: _AssetRegistryHeaderText('Asset Details')),
          Expanded(flex: 2, child: _AssetRegistryHeaderText('Status')),
          Expanded(flex: 2, child: _AssetRegistryHeaderText('Site')),
          Expanded(flex: 2, child: _AssetRegistryHeaderText('Location')),
          SizedBox(
            width: 188,
            child: _AssetRegistryHeaderText(
              'Quick Actions',
              alignment: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetRegistryHeaderText extends StatelessWidget {
  final String label;
  final TextAlign alignment;

  const _AssetRegistryHeaderText(this.label, {this.alignment = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: alignment,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xff4f5f77),
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.05,
      ),
    );
  }
}

class _AssetRegistryRow extends StatefulWidget {
  final AssetStockModel asset;
  final int animationDelay;
  final VoidCallback onDetails;
  final VoidCallback onTransfer;
  final VoidCallback onMaintenance;
  final VoidCallback onDispose;

  const _AssetRegistryRow({
    super.key,
    required this.asset,
    required this.animationDelay,
    required this.onDetails,
    required this.onTransfer,
    required this.onMaintenance,
    required this.onDispose,
  });

  @override
  State<_AssetRegistryRow> createState() => _AssetRegistryRowState();
}

class _AssetRegistryRowState extends State<_AssetRegistryRow> {
  bool hovered = false;
  bool visible = false;

  @override
  void initState() {
    super.initState();

    Future<void>.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (!mounted) return;

      setState(() {
        visible = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.asset;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 330),
      curve: Curves.easeOut,
      opacity: visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 390),
        curve: Curves.easeOutCubic,
        offset: visible ? Offset.zero : const Offset(0.018, 0),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => hovered = true),
          onExit: (_) => setState(() => hovered = false),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: hovered ? 1 : 0),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            builder: (context, hoverValue, child) {
              return Transform.translate(
                offset: Offset(3.5 * hoverValue, 0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onDetails,
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 7),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          Colors.white,
                          const Color(0xfff7faff),
                          hoverValue,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Color.lerp(
                            const Color(0xffedf1f6),
                            const Color(0xffb9cbed),
                            hoverValue,
                          )!,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xff294f87,
                            ).withValues(alpha: 0.06 * hoverValue),
                            blurRadius: 18,
                            spreadRadius: -8,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 62,
                            child: Hero(
                              tag: 'asset-registry-image-${asset.itemCode}',
                              child: _AssetImage(path: asset.imagePath),
                            ),
                          ),

                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: WebAssetColors.classification(
                                      asset.classification,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            WebAssetColors.classification(
                                              asset.classification,
                                            ).withValues(
                                              alpha: 0.25 + (0.10 * hoverValue),
                                            ),
                                        blurRadius: 6 + (2 * hoverValue),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    asset.itemCode,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Color.lerp(
                                        const Color(0xff2664c7),
                                        const Color(0xff194da5),
                                        hoverValue,
                                      ),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 13),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    asset.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xff26354c),
                                      fontSize: 12.8,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    asset.category.trim().isEmpty
                                        ? 'Uncategorized'
                                        : asset.category,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xff96a1b1),
                                      fontSize: 10.3,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          Expanded(
                            flex: 2,
                            child: _StatusPill(status: asset.status),
                          ),

                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.business_outlined,
                                    size: 15,
                                    color: Color(0xff9ba6b7),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      asset.projectName.trim().isEmpty
                                          ? '-'
                                          : asset.projectName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xff4b596f),
                                        fontSize: 11.7,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 15,
                                    color: Color(0xff9ba6b7),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      asset.location.trim().isEmpty
                                          ? '-'
                                          : asset.location,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xff4b596f),
                                        fontSize: 11.7,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(
                            width: 188,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _AssetRegistryActionButton(
                                  tooltip: 'View asset',
                                  icon: Icons.visibility_outlined,
                                  color: const Color(0xff60718a),
                                  onTap: widget.onDetails,
                                ),
                                const SizedBox(width: 6),
                                _AssetRegistryActionButton(
                                  tooltip: 'Transfer asset',
                                  icon: Icons.swap_horiz_rounded,
                                  color: const Color(0xff4263eb),
                                  onTap: widget.onTransfer,
                                ),
                                const SizedBox(width: 6),
                                _AssetRegistryActionButton(
                                  tooltip: 'Add maintenance',
                                  icon: Icons.build_circle_outlined,
                                  color: const Color(0xffe58b00),
                                  onTap: widget.onMaintenance,
                                ),
                                const SizedBox(width: 6),
                                _AssetRegistryActionButton(
                                  tooltip: 'Dispose asset',
                                  icon: Icons.delete_outline_rounded,
                                  color: const Color(0xffd9485f),
                                  onTap: widget.onDispose,
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
            },
          ),
        ),
      ),
    );
  }
}

class _AssetRegistryActionButton extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AssetRegistryActionButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_AssetRegistryActionButton> createState() =>
      _AssetRegistryActionButtonState();
}

class _AssetRegistryActionButtonState
    extends State<_AssetRegistryActionButton> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => hovered = true),
        onExit: (_) => setState(() => hovered = false),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: hovered ? 1 : 0),
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, -2.5 * value),
              child: Transform.scale(
                scale: 1 + (0.045 * value),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 170),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: widget.color.withValues(
                          alpha: 0.07 + (0.07 * value),
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: widget.color.withValues(
                            alpha: 0.12 + (0.18 * value),
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.12 * value),
                            blurRadius: 12,
                            spreadRadius: -5,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(widget.icon, size: 18, color: widget.color),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AssetRegistryEmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClearFilters;

  const _AssetRegistryEmptyState({
    super.key,
    required this.hasFilters,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 280),
      margin: const EdgeInsets.only(top: 9),
      decoration: BoxDecoration(
        color: const Color(0xfffbfcfe),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe6ebf2)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xffedf3ff), Color(0xffe9f7fb)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xffd6e4fa)),
                ),
                child: Icon(
                  hasFilters
                      ? Icons.search_off_rounded
                      : Icons.inventory_2_outlined,
                  color: const Color(0xff4263eb),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                hasFilters ? 'No matching assets found' : 'No assets available',
                style: const TextStyle(
                  color: Color(0xff26354d),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                hasFilters
                    ? 'Change your search terms or clear the current filters.'
                    : 'New asset records will appear in this directory.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xff8b98aa),
                  fontSize: 12.5,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (hasFilters) ...[
                const SizedBox(height: 17),
                OutlinedButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                  label: const Text(
                    'Clear Filters',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xff4263eb),
                    side: const BorderSide(color: Color(0xffbdccef)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AssetRegistryRecentPanel extends StatelessWidget {
  final List<AssetStockModel> assets;
  final Future<void> Function(AssetStockModel asset) onDetails;
  final Future<void> Function(AssetStockModel asset) onTransfer;
  final Future<bool> Function(AssetStockModel asset) onMaintenance;
  final Future<bool> Function(AssetStockModel asset) onDispose;

  const _AssetRegistryRecentPanel({
    required this.assets,
    required this.onDetails,
    required this.onTransfer,
    required this.onMaintenance,
    required this.onDispose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffdfe7f2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff1d3557).withValues(alpha: 0.045),
            blurRadius: 24,
            spreadRadius: -10,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 17, 20, 15),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xff4263eb).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: Color(0xff4263eb),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Assets',
                          style: TextStyle(
                            color: Color(0xff17243b),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Recently created active asset records',
                          style: TextStyle(
                            color: Color(0xff8a97a9),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xfff1f5fb),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      '${assets.length} records',
                      style: const TextStyle(
                        color: Color(0xff60718a),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xffe8edf4)),
            LayoutBuilder(
              builder: (context, constraints) {
                final tableWidth = constraints.maxWidth < 1120
                    ? 1120.0
                    : constraints.maxWidth;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          const _AssetRegistryTableHeader(),
                          if (assets.isEmpty)
                            const SizedBox(
                              height: 150,
                              child: Center(
                                child: Text(
                                  'No recent assets found',
                                  style: TextStyle(
                                    color: Color(0xff8794a7),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                          else ...[
                            const SizedBox(height: 8),
                            for (var index = 0; index < assets.length; index++)
                              _AssetRegistryRow(
                                key: ValueKey(
                                  'recent-${assets[index].itemCode}',
                                ),
                                asset: assets[index],
                                animationDelay: index * 28,
                                onDetails: () {
                                  onDetails(assets[index]);
                                },
                                onTransfer: () {
                                  onTransfer(assets[index]);
                                },
                                onMaintenance: () {
                                  onMaintenance(assets[index]);
                                },
                                onDispose: () {
                                  onDispose(assets[index]);
                                },
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
