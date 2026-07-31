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

part '../web/pages/dispose/web_dispose_page.dart';
part '../web/pages/alerts/web_alerts_page.dart';
part '../web/pages/assets/web_assets_page.dart';
part '../web/pages/dashboard/web_dashboard_overview.dart';
part '../web/pages/inventory/web_inventory_page.dart';
part '../web/pages/maintenance/web_maintenance_page.dart';
part '../web/pages/transfer/web_transfer_page.dart';
part '../web/widgets/assets/asset_registry_empty_state.dart';
part '../web/widgets/assets/asset_registry_header.dart';
part '../web/widgets/assets/asset_registry_recent.dart';
part '../web/widgets/assets/asset_registry_summary.dart';
part '../web/widgets/assets/asset_registry_table.dart';
part '../web/widgets/assets/asset_registry_toolbar.dart';
part '../web/widgets/assets/asset_picker_widgets.dart';
part '../web/widgets/assets/list_toolbar.dart';
part '../web/widgets/alerts/alert_widgets.dart';
part '../web/widgets/common/asset_table_widgets.dart';
part '../web/widgets/common/detail_widgets.dart';
part '../web/widgets/common/dialog_asset_header.dart';
part '../web/widgets/common/panel_widget.dart';
part '../web/widgets/common/pagination_widgets.dart';
part '../web/widgets/common/print_widgets.dart';
part '../web/widgets/common/status_color.dart';
part '../web/widgets/common/status_pill.dart';
part '../web/widgets/common/web_loading_view.dart';
part '../web/widgets/dashboard/calendar_widgets.dart';
part '../web/widgets/dashboard/dashboard_metric_widgets.dart';
part '../web/widgets/dispose/dispose_widgets.dart';
part '../web/widgets/maintenance/maintenance_widgets.dart';
part '../web/widgets/shell/dashboard_shell_widgets.dart';
part '../web/widgets/transfer/transfer_widgets.dart';

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

  void _updateWebState(VoidCallback update) => setState(update);

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
