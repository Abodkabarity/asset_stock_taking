import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:printing/printing.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/asset_excel_service.dart';
import '../../core/services/barcode_print_service.dart';
import '../../core/utils/asset_classification_utils.dart';
import '../../data/models/asset_stock_model.dart';
import '../web/data/web_asset_repository.dart';
import '../web/pages/web_asset_add_page.dart';
import '../web/pages/web_asset_edit_page.dart';
import '../web/pages/web_asset_view_page.dart';
import '../web/utils/web_asset_colors.dart';
import '../web/utils/web_dropdown_options.dart';
import '../web/widgets/web_asset_quick_view_dialog.dart';
import '../web/widgets/web_hover_surface.dart';
import '../web/widgets/common/web_single_date_picker.dart';

part '../web/pages/dispose/web_dispose_page.dart';
part '../web/pages/alerts/web_alerts_page.dart';
part '../web/pages/assets/web_assets_page.dart';
part '../web/pages/dashboard/web_dashboard_overview.dart';
part '../web/pages/inventory/web_inventory_page.dart';
part '../web/pages/maintenance/web_maintenance_page.dart';
part '../web/pages/transfer/web_transfer_page.dart';
part '../web/pages/checkout/web_checkout_page.dart';
part '../web/pages/reserve/web_reserve_page.dart';
part '../web/pages/setup/web_setup_page.dart';
part '../web/widgets/assets/asset_registry_empty_state.dart';
part '../web/widgets/assets/asset_registry_header.dart';
part '../web/widgets/assets/asset_registry_recent.dart';
part '../web/widgets/assets/asset_registry_summary.dart';
part '../web/widgets/assets/asset_registry_table.dart';
part '../web/widgets/assets/asset_registry_toolbar.dart';
part '../web/widgets/assets/asset_picker_widgets.dart';
part '../web/widgets/assets/list_toolbar.dart';
part '../web/widgets/assets/web_date_range_picker.dart';
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
part '../web/widgets/setup/setup_widgets.dart';

enum WebAssetSection {
  dashboard,
  alerts,
  assets,
  inventory,
  transfer,
  dispose,
  maintenance,
  checkout,
  checkin,
  reserve,
  setupAssets,
  setupBranches,
  setupClassifications,
  setupCategories,
  setupSubCategories,
}

enum WebAlertView {
  checkoutDue,
  maintenanceDue,
  maintenanceOverdue,
  warrantyExpiry,
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
  final alertSearchController = TextEditingController();
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
  List<Map<String, dynamic>> activeCheckouts = [];
  List<Map<String, dynamic>> checkoutPeople = [];
  List<Map<String, dynamic>> activeReservations = [];
  List<Map<String, dynamic>> transferRecords = [];
  List<Map<String, dynamic>> masterAssetRows = [];
  List<Map<String, dynamic>> branchRows = [];
  List<Map<String, dynamic>> setupOptionRows = [];
  List<String> departments = [];
  String? selectedBranch;
  String searchQuery = '';
  String? selectedStatus;
  DateTimeRange? selectedDateRange;
  String alertSearchQuery = '';
  String alertUrgencyFilter = 'All';
  WebAlertView selectedAlertView = WebAlertView.maintenanceDue;
  final Set<String> _seenAlertKeys = <String>{};
  DateTime alertMonth = DateTime(DateTime.now().year, DateTime.now().month);
  AssetStockModel? selectedMaintenanceAsset;
  AssetStockModel? selectedDetailAsset;
  AssetStockModel? editingAsset;
  AssetStockModel? detailReturnAfterEdit;
  bool addingAsset = false;
  bool addingInventory = false;
  String maintenanceStatus = 'Open';
  bool maintenanceRepeating = false;
  bool loading = true;
  bool sectionLoading = false;
  WebAssetSection? pendingSection;
  final Map<WebAssetSection, int> _sectionPages = {};
  Timer? _registrySearchDebounce;

  void _updateWebState(VoidCallback update) => setState(update);

  @override
  void initState() {
    super.initState();
    selectedSection = widget.initialSection;
    final storedSeenAlerts = Hive.box(
      'settings_box',
    ).get('web_seen_alert_keys');
    if (storedSeenAlerts is List) {
      _seenAlertKeys.addAll(storedSeenAlerts.map((key) => key.toString()));
    }
    _loadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    alertSearchController.dispose();
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
    _registrySearchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      loading = true;
    });

    final branchesFuture = webRepository.getBranches();
    final assetsFuture = webRepository.getAssets();

    final loadedBranches = await branchesFuture;
    final loadedAssets = await assetsFuture;

    if (!mounted) return;

    setState(() {
      branches = loadedBranches;
      assets = loadedAssets;
      _sectionPages.clear();
      loading = false;
    });

    // Load workflow and setup data after the critical registry payload. This
    // keeps Supabase connection slots free for the first meaningful paint.
    final alertsFuture = webRepository.getMaintenanceAlertsWithinDays();
    final recordsFuture = webRepository.getMaintenanceRecords();
    final checkoutsFuture = webRepository.getActiveCheckouts();
    final peopleFuture = webRepository.getPeople();
    final reservationsFuture = webRepository.getActiveReservations();
    final departmentsFuture = webRepository.getDepartments();
    final transferRecordsFuture = webRepository.getTransferActivityLogs();
    final masterAssetRowsFuture = webRepository.getMasterAssetRows();
    final branchRowsFuture = webRepository.getBranchRows();
    final setupOptionRowsFuture = webRepository.getSetupOptionRows();

    final loadedAlerts = await alertsFuture;
    final loadedRecords = await recordsFuture;
    final loadedCheckouts = await checkoutsFuture;
    final loadedPeople = await peopleFuture;
    final loadedReservations = await reservationsFuture;
    final loadedDepartments = await departmentsFuture;
    final loadedTransferRecords = await transferRecordsFuture;
    final loadedMasterAssetRows = await masterAssetRowsFuture;
    final loadedBranchRows = await branchRowsFuture;
    final loadedSetupOptionRows = await setupOptionRowsFuture;

    if (!mounted) return;
    setState(() {
      maintenanceAlerts = loadedAlerts;
      maintenanceRecords = loadedRecords;
      activeCheckouts = loadedCheckouts;
      checkoutPeople = loadedPeople;
      activeReservations = loadedReservations;
      departments = loadedDepartments;
      transferRecords = loadedTransferRecords;
      masterAssetRows = loadedMasterAssetRows;
      branchRows = loadedBranchRows;
      setupOptionRows = loadedSetupOptionRows;
    });
    if (selectedSection == WebAssetSection.alerts) {
      final keys = _alertEntriesFor(selectedAlertView)
          .where((entry) => _alertDaysFromToday(entry.date) <= 7)
          .map(_alertEntryKey)
          .toSet();
      setState(() => _seenAlertKeys.addAll(keys));
      unawaited(
        Hive.box(
          'settings_box',
        ).put('web_seen_alert_keys', _seenAlertKeys.toList(growable: false)),
      );
    }
  }

  void _selectSection(WebAssetSection section) {
    if (sectionLoading) return;
    if (section == WebAssetSection.alerts) {
      _selectAlertView(selectedAlertView);
      return;
    }
    if (section == selectedSection) {
      if (selectedDetailAsset != null ||
          addingAsset ||
          addingInventory ||
          editingAsset != null) {
        setState(() {
          selectedDetailAsset = null;
          addingAsset = false;
          addingInventory = false;
          editingAsset = null;
          detailReturnAfterEdit = null;
        });
        _scrollContentToTop();
      }
      return;
    }

    setState(() {
      selectedSection = section;
      sectionLoading = false;
      pendingSection = null;
      selectedStatus = null;
      selectedDateRange = null;
      selectedDetailAsset = null;
      editingAsset = null;
      detailReturnAfterEdit = null;
      addingAsset = false;
      addingInventory = false;
      searchQuery = '';
      searchController.clear();
      _sectionPages[section] = 0;
    });
    _scrollContentToTop();
  }

  void _queueRegistrySearch(String value, WebAssetSection section) {
    _registrySearchDebounce?.cancel();
    if (value.isEmpty) {
      _updateWebState(() {
        searchQuery = '';
        _resetPage(section);
      });
      return;
    }
    _registrySearchDebounce = Timer(const Duration(milliseconds: 140), () {
      if (!mounted) return;
      _updateWebState(() {
        searchQuery = value;
        _resetPage(section);
      });
    });
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
      for (final position in contentScrollController.positions) {
        position.animateTo(
          position.minScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  List<AssetStockModel> get visibleAssets {
    final search = searchQuery.trim().toLowerCase();

    return assets.where((asset) {
      return _matchesBranchAndSearch(asset, search) &&
          _matchesSelectedStatus(asset) &&
          _matchesSelectedDateRange(asset) &&
          _isRegularAsset(asset);
    }).toList();
  }

  List<AssetStockModel> get visibleInventoryAssets {
    final search = searchQuery.trim().toLowerCase();

    return assets.where((asset) {
      return _matchesBranchAndSearch(asset, search) &&
          _matchesSelectedStatus(asset) &&
          _matchesSelectedDateRange(asset) &&
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

  bool _matchesSelectedDateRange(AssetStockModel asset) {
    final range = selectedDateRange;
    if (range == null) return true;
    final date = DateTime(
      asset.createdAt.year,
      asset.createdAt.month,
      asset.createdAt.day,
    );
    final start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    return !date.isBefore(start) && !date.isAfter(end);
  }

  Future<void> _pickAssetDateRange() async {
    final result = await showWebDateRangePicker(
      context: context,
      initialRange: selectedDateRange,
    );
    if (result == null || !mounted) return;
    _updateWebState(() {
      selectedDateRange = result;
      _resetPage(selectedSection);
    });
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
        asset.assetInventory.toLowerCase().contains(search);
  }

  bool _isInventoryAsset(AssetStockModel asset) {
    return asset.assetInventory.trim().toLowerCase() == 'inventory';
  }

  bool _isRegularAsset(AssetStockModel asset) {
    final status = asset.status.trim().toLowerCase();
    final registerType = asset.assetInventory.trim().toLowerCase();
    return status != 'disposed' &&
        status != 'maintenance' &&
        registerType == 'asset';
  }

  bool _isOperationallyAvailable(AssetStockModel asset) {
    final status = asset.status.trim().toLowerCase();
    return _isRegularAsset(asset) &&
        status != 'checked out' &&
        status != 'reserved';
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
    return _alertUnreadCounts.values.fold<int>(0, (sum, count) => sum + count);
  }

  void _selectAlertView(WebAlertView view) {
    final keys = _alertEntriesFor(view)
        .where((entry) => _alertDaysFromToday(entry.date) <= 7)
        .map(_alertEntryKey)
        .toSet();
    setState(() {
      selectedSection = WebAssetSection.alerts;
      selectedAlertView = view;
      selectedDetailAsset = null;
      editingAsset = null;
      addingAsset = false;
      addingInventory = false;
      alertSearchQuery = '';
      alertSearchController.clear();
      _sectionPages[WebAssetSection.alerts] = 0;
      _seenAlertKeys.addAll(keys);
    });
    unawaited(
      Hive.box(
        'settings_box',
      ).put('web_seen_alert_keys', _seenAlertKeys.toList(growable: false)),
    );
    _scrollContentToTop();
  }

  void _addAsset() {
    setState(() {
      selectedSection = WebAssetSection.assets;
      selectedDetailAsset = null;
      editingAsset = null;
      detailReturnAfterEdit = null;
      addingAsset = true;
      addingInventory = false;
    });
    _scrollContentToTop();
  }

  void _addInventory() {
    setState(() {
      selectedSection = WebAssetSection.inventory;
      selectedDetailAsset = null;
      editingAsset = null;
      detailReturnAfterEdit = null;
      addingAsset = false;
      addingInventory = true;
    });
    _scrollContentToTop();
  }

  Future<void> _exportList(List<AssetStockModel> items, String fileName) async {
    if (items.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No assets available to export')),
      );
      return;
    }
    await AssetExcelService.exportAssets(
      assets: items,
      fileName: fileName,
      includeProject: false,
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
      builder: (context) => WebAssetQuickViewDialog(
        asset: asset,
        onMoreDetails: () => _openAssetDetails(asset),
        onEdit: () => _openAssetEditor(asset),
      ),
    );
  }

  void _openAssetDetails(AssetStockModel asset) {
    setState(() {
      selectedSection = _isInventoryAsset(asset)
          ? WebAssetSection.inventory
          : WebAssetSection.assets;
      addingAsset = false;
      addingInventory = false;
      editingAsset = null;
      detailReturnAfterEdit = null;
      selectedDetailAsset = asset;
    });
    _scrollContentToTop();
  }

  void _closeAssetDetails() {
    setState(() => selectedDetailAsset = null);
    _scrollContentToTop();
  }

  void _openAssetEditor(AssetStockModel asset, {bool returnToDetails = false}) {
    setState(() {
      selectedSection = _isInventoryAsset(asset)
          ? WebAssetSection.inventory
          : WebAssetSection.assets;
      addingAsset = false;
      addingInventory = false;
      editingAsset = asset;
      detailReturnAfterEdit = returnToDetails ? asset : null;
      selectedDetailAsset = null;
    });
    _scrollContentToTop();
  }

  void _cancelAssetForm() {
    setState(() {
      addingAsset = false;
      addingInventory = false;
      editingAsset = null;
      selectedDetailAsset = detailReturnAfterEdit;
      detailReturnAfterEdit = null;
    });
    _scrollContentToTop();
  }

  Future<void> _completeAssetForm() async {
    final editedCode = editingAsset?.itemCode;
    final shouldReturnToDetails = detailReturnAfterEdit != null;
    setState(() {
      addingAsset = false;
      addingInventory = false;
      editingAsset = null;
      detailReturnAfterEdit = null;
    });
    await _loadData();
    if (!mounted || !shouldReturnToDetails || editedCode == null) return;
    final updatedIndex = assets.indexWhere(
      (asset) => asset.itemCode == editedCode,
    );
    if (updatedIndex < 0) return;
    setState(() => selectedDetailAsset = assets[updatedIndex]);
    _scrollContentToTop();
  }

  void _showAdjacentAsset(int offset) {
    final current = selectedDetailAsset;
    if (current == null || visibleAssets.isEmpty) return;
    final index = visibleAssets.indexWhere(
      (asset) => asset.itemCode == current.itemCode,
    );
    if (index < 0) return;
    final nextIndex = index + offset;
    if (nextIndex < 0 || nextIndex >= visibleAssets.length) return;
    setState(() => selectedDetailAsset = visibleAssets[nextIndex]);
    _scrollContentToTop();
  }

  Future<void> _transferAsset(AssetStockModel asset) async {
    if (asset.status.trim().toLowerCase() == 'reserved') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This asset is reserved. Use Reserve > Transfer or Unreserve first.',
            ),
          ),
        );
      }
      return;
    }
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
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      initialValue: branch,
                      decoration: _inputDecoration('Branch'),
                      items: alphabetizedWebOptions(branches).map((item) {
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

    await webRepository.transferAsset(itemCode: asset.itemCode, branch: branch);
    await webRepository.addActivityLog(
      itemCode: asset.itemCode,
      action: 'transfer',
      description: 'Transferred from ${asset.location} to $branch',
      fromBranch: asset.location,
      toBranch: branch,
      metadata: const {},
    );

    await _loadData();
  }

  Future<void> _openTransferAssetPicker() async {
    final picked = await _showAssetSearchPicker(
      actionLabel: 'Continue to Transfer',
    );
    if (picked == null || picked.isEmpty) return;
    for (final asset in picked) {
      if (!mounted) return;
      await _transferAsset(asset);
    }
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
        assets: assets.where(_isOperationallyAvailable).toList(growable: false),
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
    var initialDate = DateTime.tryParse(controller.text);
    if (initialDate == null) {
      final parts = controller.text.trim().split('/');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          initialDate = DateTime(year, month, day);
        }
      }
    }
    final picked = await showWebSingleDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 20),
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

  bool get _assetFormOpen =>
      addingAsset || addingInventory || editingAsset != null;

  String? get _workspaceTitle {
    if (addingAsset) return 'Add Asset';
    if (addingInventory) return 'Add Inventory';
    if (editingAsset != null) return 'Edit Asset';
    if (selectedDetailAsset != null) return 'Asset Details';
    return null;
  }

  String? get _workspaceSubtitle {
    if (addingAsset) return 'Create a new asset record';
    if (addingInventory) return 'Create a new inventory record';
    if (editingAsset != null) return editingAsset!.itemCode;
    return selectedDetailAsset?.itemCode;
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
                selectedAlertView: selectedAlertView,
                alertUnreadCounts: _alertUnreadCounts,
                onAlertSelected: _selectAlertView,
                onSelected: _selectSection,
                onAddAsset: _addAsset,
                onAddInventory: _addInventory,
                addingAsset: addingAsset,
                addingInventory: addingInventory,
              ),
              Expanded(
                child: Column(
                  children: [
                    _TopBar(
                      section: selectedSection,
                      titleOverride: _workspaceTitle,
                      subtitleOverride: _workspaceSubtitle,
                      selectedBranch: selectedBranch,
                      branches: branches,
                      onBranchChanged: (value) {
                        setState(() {
                          selectedBranch = value;
                          selectedDetailAsset = null;
                          addingAsset = false;
                          addingInventory = false;
                          editingAsset = null;
                          detailReturnAfterEdit = null;
                          _sectionPages.clear();
                        });
                      },
                      onAssets: () => _selectSection(WebAssetSection.assets),
                      onAddAsset: _addAsset,
                      onAddInventory: _addInventory,
                      onPrint: _printAssets,
                      onRefresh: _loadData,
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        // Do not retain the outgoing scroll view: both pages
                        // share the dashboard controller and attaching it to
                        // two scrollables causes ScrollController.position to
                        // assert during fast section transitions.
                        layoutBuilder: (currentChild, previousChildren) =>
                            Align(
                              alignment: Alignment.topLeft,
                              child: currentChild ?? const SizedBox.shrink(),
                            ),
                        child: loading || sectionLoading
                            ? _WebLoadingView(
                                key: const ValueKey('web-loading'),
                                message: loading
                                    ? 'Loading asset data...'
                                    : 'Opening ${_sectionLabel(pendingSection ?? selectedSection)}...',
                              )
                            : _assetFormOpen
                            ? KeyedSubtree(
                                key: ValueKey(
                                  addingAsset
                                      ? 'asset-add'
                                      : addingInventory
                                      ? 'inventory-add'
                                      : 'asset-edit-${editingAsset!.itemCode}',
                                ),
                                child: _content(),
                              )
                            : SingleChildScrollView(
                                key: ValueKey(
                                  '${selectedSection.name}-${selectedDetailAsset?.itemCode ?? 'list'}',
                                ),
                                controller: contentScrollController,
                                padding: const EdgeInsets.fromLTRB(
                                  26,
                                  20,
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
        return 'List of Inventory';
      case WebAssetSection.transfer:
        return 'Move Assets';
      case WebAssetSection.dispose:
        return 'Disposed Assets';
      case WebAssetSection.maintenance:
        return 'Maintenance';
      case WebAssetSection.checkout:
        return 'Check Out';
      case WebAssetSection.checkin:
        return 'Check In';
      case WebAssetSection.reserve:
        return 'Reserve';
      case WebAssetSection.setupAssets:
        return 'Asset Master';
      case WebAssetSection.setupBranches:
        return 'Branches';
      case WebAssetSection.setupClassifications:
        return 'Classifications';
      case WebAssetSection.setupCategories:
        return 'Categories';
      case WebAssetSection.setupSubCategories:
        return 'Sub Categories';
    }
  }

  Widget _content() {
    if (selectedSection == WebAssetSection.assets && addingAsset) {
      return WebAssetAddPage(
        key: ValueKey('add-${selectedBranch ?? 'all'}'),
        initialBranch: selectedBranch,
        embedded: true,
        onCancel: _cancelAssetForm,
        onSaved: () => _completeAssetForm(),
      );
    }
    if (selectedSection == WebAssetSection.inventory && addingInventory) {
      return WebAssetAddPage(
        key: ValueKey('inventory-add-${selectedBranch ?? 'all'}'),
        initialBranch: selectedBranch,
        inventoryMode: true,
        embedded: true,
        onCancel: _cancelAssetForm,
        onSaved: () => _completeAssetForm(),
      );
    }
    if ((selectedSection == WebAssetSection.assets ||
            selectedSection == WebAssetSection.inventory) &&
        editingAsset != null) {
      final asset = editingAsset!;
      return WebAssetEditPage(
        key: ValueKey('edit-${asset.itemCode}'),
        asset: asset,
        embedded: true,
        onCancel: _cancelAssetForm,
        onSaved: () => _completeAssetForm(),
      );
    }
    if ((selectedSection == WebAssetSection.assets ||
            selectedSection == WebAssetSection.inventory) &&
        selectedDetailAsset != null) {
      final asset = selectedDetailAsset!;
      final index = visibleAssets.indexWhere(
        (item) => item.itemCode == asset.itemCode,
      );
      return WebAssetDetailsContent(
        asset: asset,
        onBack: _closeAssetDetails,
        onPrevious: index > 0 ? () => _showAdjacentAsset(-1) : null,
        onNext: index >= 0 && index < visibleAssets.length - 1
            ? () => _showAdjacentAsset(1)
            : null,
        onEdit: () => _openAssetEditor(asset, returnToDetails: true),
      );
    }
    switch (selectedSection) {
      case WebAssetSection.assets:
        return _assetsPanel();
      case WebAssetSection.inventory:
        return _inventoryPanel();
      case WebAssetSection.alerts:
        return _alertsPanel();
      case WebAssetSection.transfer:
        return _transferPanel();
      case WebAssetSection.dispose:
        return _disposePanel();
      case WebAssetSection.maintenance:
        return _maintenancePanel();
      case WebAssetSection.checkout:
        return _checkoutPanel();
      case WebAssetSection.checkin:
        return _checkinPanel();
      case WebAssetSection.reserve:
        return _reservePanel();
      case WebAssetSection.setupAssets:
        return _setupAssetsPanel();
      case WebAssetSection.setupBranches:
        return _setupBranchesPanel();
      case WebAssetSection.setupClassifications:
        return _setupOptionPanel(
          optionType: 'classification',
          title: 'Classifications',
          singular: 'Classification',
          icon: Icons.security_outlined,
        );
      case WebAssetSection.setupCategories:
        return _setupOptionPanel(
          optionType: 'category',
          title: 'Categories',
          singular: 'Category',
          icon: Icons.category_outlined,
        );
      case WebAssetSection.setupSubCategories:
        return _setupOptionPanel(
          optionType: 'sub_category',
          title: 'Sub Categories',
          singular: 'Sub Category',
          icon: Icons.account_tree_outlined,
        );
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
                                    value: 'Completed',
                                    child: Text('Completed'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'In Progress',
                                    child: Text('In Progress'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Open',
                                    child: Text('Open'),
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
