part of '../../../pages/web_asset_dashboard_page.dart';

extension _SetupPageExtension on _WebAssetDashboardPageState {
  Widget _setupAssetsPanel() {
    final query = searchQuery.trim().toLowerCase();
    final rows = masterAssetRows
        .where((row) {
          if (query.isEmpty) return true;
          return [
            'name',
            'item_code',
            'category',
            'sub_category',
            'classification',
            'department',
            'asset_classification',
            'asset_inventory',
          ].any(
            (key) => (row[key]?.toString().toLowerCase() ?? '').contains(query),
          );
        })
        .toList(growable: false);
    final paged = _paginate(rows, WebAssetSection.setupAssets);
    final categories = rows
        .map((row) => row['category']?.toString().trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet();
    final departmentsSet = rows
        .map((row) => row['department']?.toString().trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet();
    final inventoryCount = rows.where((row) {
      return row['asset_inventory']?.toString().toLowerCase() == 'inventory';
    }).length;

    return _setupPageFrame(
      branchesMode: false,
      count: rows.length,
      onAdd: () => _openMasterAssetDialog(),
      stats: [
        _MaintenanceStatCard(
          icon: Icons.category_outlined,
          color: const Color(0xff4263eb),
          title: 'Master Assets',
          value: rows.length.toString(),
          subtitle: 'Available product definitions',
        ),
        _MaintenanceStatCard(
          icon: Icons.account_tree_outlined,
          color: const Color(0xff0f9f8f),
          title: 'Categories',
          value: categories.length.toString(),
          subtitle: 'Distinct asset categories',
        ),
        _MaintenanceStatCard(
          icon: Icons.apartment_outlined,
          color: const Color(0xfff59f00),
          title: 'Departments',
          value: departmentsSet.length.toString(),
          subtitle: 'Operational departments',
        ),
        _MaintenanceStatCard(
          icon: Icons.inventory_2_outlined,
          color: const Color(0xff7950f2),
          title: 'Inventory Definitions',
          value: inventoryCount.toString(),
          subtitle: 'Items configured as inventory',
        ),
      ],
      directoryTitle: 'Asset Master Directory',
      directorySubtitle:
          'Review, add and edit the definitions used by Add Asset and Add Inventory',
      searchHint: 'Search name, item code, category or department',
      recordsCount: rows.length,
      child: rows.isEmpty
          ? _SetupEmptyState(
              label: 'Asset',
              hasSearch: query.isNotEmpty,
              onAdd: () => _openMasterAssetDialog(),
            )
          : Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xfff1f5fb),
                    ),
                    headingTextStyle: const TextStyle(
                      color: Color(0xff53627a),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                    dataTextStyle: const TextStyle(
                      color: Color(0xff34435a),
                      fontSize: 11.5,
                    ),
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Item Code')),
                      DataColumn(label: Text('Category')),
                      DataColumn(label: Text('Sub Category')),
                      DataColumn(label: Text('Classification')),
                      DataColumn(label: Text('Department')),
                      DataColumn(label: Text('Asset Classification')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Updated')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: paged.items.map((row) {
                      return DataRow(
                        cells: [
                          DataCell(Text(row['id']?.toString() ?? '-')),
                          DataCell(
                            SizedBox(
                              width: 155,
                              child: Text(
                                row['name']?.toString() ?? '-',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xff24324a),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              row['item_code']?.toString() ?? '-',
                              style: const TextStyle(
                                color: Color(0xff2664c7),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          DataCell(_setupCell(row['category'])),
                          DataCell(_setupCell(row['sub_category'])),
                          DataCell(_setupCell(row['classification'])),
                          DataCell(_setupCell(row['department'])),
                          DataCell(_setupCell(row['asset_classification'])),
                          DataCell(
                            _SetupTypePill(
                              value: row['asset_inventory']?.toString() ?? '',
                            ),
                          ),
                          DataCell(_setupCell(_setupDate(row['updated_at']))),
                          DataCell(
                            IconButton(
                              tooltip: 'Edit asset master',
                              onPressed: () => _openMasterAssetDialog(row: row),
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Color(0xff4263eb),
                                size: 19,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                _PaginationBar(
                  currentPage: paged.currentPage,
                  totalPages: paged.totalPages,
                  totalItems: paged.totalItems,
                  pageSize: _WebAssetDashboardPageState._assetsPerPage,
                  onPageChanged: (page) =>
                      _changePage(WebAssetSection.setupAssets, page),
                ),
              ],
            ),
    );
  }

  Widget _setupBranchesPanel() {
    final query = searchQuery.trim().toLowerCase();
    final rows = branchRows
        .where((row) {
          return query.isEmpty ||
              (row['branch_name']?.toString().toLowerCase() ?? '').contains(
                query,
              ) ||
              (row['id']?.toString() ?? '').contains(query);
        })
        .toList(growable: false);
    final paged = _paginate(rows, WebAssetSection.setupBranches);

    return _setupPageFrame(
      branchesMode: true,
      count: rows.length,
      onAdd: () => _openBranchDialog(),
      stats: [
        _MaintenanceStatCard(
          icon: Icons.account_balance_outlined,
          color: const Color(0xff4263eb),
          title: 'Total Branches',
          value: rows.length.toString(),
          subtitle: 'Configured pharmacy locations',
        ),
        _MaintenanceStatCard(
          icon: Icons.location_city_outlined,
          color: const Color(0xff0f9f8f),
          title: 'Active Directory',
          value: branches.length.toString(),
          subtitle: 'Locations available in forms',
        ),
      ],
      directoryTitle: 'Branch Directory',
      directorySubtitle: 'Add new branches or update existing branch names',
      searchHint: 'Search branch name or ID',
      recordsCount: rows.length,
      child: rows.isEmpty
          ? _SetupEmptyState(
              label: 'Branch',
              hasSearch: query.isNotEmpty,
              onAdd: () => _openBranchDialog(),
            )
          : Column(
              children: [
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xfff1f5fb),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: const Color(0xffdfe7f2)),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 90, child: Text('ID')),
                      Expanded(child: Text('Branch Name')),
                      SizedBox(width: 90, child: Text('Actions')),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...paged.items.map(
                  (row) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: const Color(0xffe8edf4)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text(row['id']?.toString() ?? '-'),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xffedf4ff),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: const Icon(
                                  Icons.location_on_outlined,
                                  color: Color(0xff4263eb),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 11),
                              Text(
                                row['branch_name']?.toString() ?? '-',
                                style: const TextStyle(
                                  color: Color(0xff24324a),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 90,
                          child: IconButton(
                            tooltip: 'Edit branch',
                            onPressed: () => _openBranchDialog(row: row),
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Color(0xff4263eb),
                              size: 19,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _PaginationBar(
                  currentPage: paged.currentPage,
                  totalPages: paged.totalPages,
                  totalItems: paged.totalItems,
                  pageSize: _WebAssetDashboardPageState._assetsPerPage,
                  onPageChanged: (page) =>
                      _changePage(WebAssetSection.setupBranches, page),
                ),
              ],
            ),
    );
  }

  Widget _setupOptionPanel({
    required String optionType,
    required String title,
    required String singular,
    required IconData icon,
  }) {
    final query = searchQuery.trim().toLowerCase();
    final rows = _mergedSetupOptionRows(optionType)
        .where((row) {
          final matchesSearch =
              query.isEmpty ||
              (row['value']?.toString().toLowerCase() ?? '').contains(query);
          return matchesSearch;
        })
        .toList(growable: false);
    final paged = _paginate(rows, selectedSection);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SetupOptionHero(
          title: title,
          singular: singular,
          icon: icon,
          count: rows.length,
          onAdd: () => _openSetupOptionDialog(
            optionType: optionType,
            singular: singular,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xffdfe7f2)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff1d3557).withValues(alpha: .055),
                blurRadius: 28,
                spreadRadius: -10,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) => _updateWebState(() {
                        searchQuery = value;
                        _resetPage(selectedSection);
                      }),
                      decoration: InputDecoration(
                        hintText: 'Search $title',
                        prefixIcon: const Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffedf4ff),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xffd4e1ff)),
                    ),
                    child: Text(
                      '${rows.length} options',
                      style: const TextStyle(
                        color: Color(0xff3156c8),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (rows.isEmpty)
                _SetupEmptyState(
                  label: singular,
                  hasSearch: query.isNotEmpty,
                  onAdd: () => _openSetupOptionDialog(
                    optionType: optionType,
                    singular: singular,
                  ),
                )
              else ...[
                Container(
                  height: 47,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xfff1f5fb),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 70, child: Text('No.')),
                      Expanded(child: Text('Value')),
                      SizedBox(width: 80, child: Text('Edit')),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...paged.items.asMap().entries.map((entry) {
                  final row = entry.value;
                  final number =
                      (paged.currentPage *
                          _WebAssetDashboardPageState._assetsPerPage) +
                      entry.key +
                      1;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: const Color(0xffe8edf4)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 70,
                          child: Text(
                            number.toString().padLeft(2, '0'),
                            style: const TextStyle(
                              color: Color(0xff71809a),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 35,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: const Color(0xffedf4ff),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  icon,
                                  color: const Color(0xff4263eb),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 11),
                              Text(
                                row['value']?.toString() ?? '-',
                                style: const TextStyle(
                                  color: Color(0xff24324a),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: IconButton(
                            tooltip: 'Edit $singular',
                            onPressed: () => _openSetupOptionDialog(
                              optionType: optionType,
                              singular: singular,
                              row: row,
                            ),
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Color(0xff4263eb),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
                _PaginationBar(
                  currentPage: paged.currentPage,
                  totalPages: paged.totalPages,
                  totalItems: paged.totalItems,
                  pageSize: _WebAssetDashboardPageState._assetsPerPage,
                  onPageChanged: (page) => _changePage(selectedSection, page),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<String> _setupOptionValues(String optionType, String currentValue) {
    final defaults = switch (optionType) {
      'classification' => ['Public', 'Restricted', 'Confidential'],
      'category' => [
        'Advertising & Signage Equipment',
        'Climate Control',
        'Environmental Protection',
        'Facility Tools And Equipment',
        'Furniture And Fixtures',
        'Health Assessment Equipment',
        'IT Equipment And Accessories',
      ],
      'sub_category' => [
        'Sinage',
        'Screen',
        'Air Conditioning Units',
        'Air Quality Device',
        'Refrigeration Equipment',
        'Ventilation Equipment',
        'Temperature Control Device',
        'Environmental Protection Control',
        'Ladder',
        'Door',
        'Cabinets',
        'Chair',
        'Tables',
        'Kitchen Supplies',
        'Desks And Work Stations',
        'Diagnostic Devices',
        'Surveillance And Security',
        'Printing & Scanning Devices',
        'Networking Equipment',
        'Communication Devices',
        'Access Control Device',
        'Time Attendance Devices',
        'Additional Devices',
        'Computers & Accessories',
        'Laminating Machine',
        'Servers & Storage',
      ],
      _ => <String>[],
    };
    final assetKey = optionType;
    final values = <String, String>{};
    for (final value in defaults) {
      values[value.toLowerCase()] = value;
    }
    for (final row in setupOptionRows.where(
      (row) => row['option_type']?.toString() == optionType,
    )) {
      final value = row['value']?.toString().trim() ?? '';
      if (value.isNotEmpty) values[value.toLowerCase()] = value;
    }
    for (final row in masterAssetRows) {
      final value = row[assetKey]?.toString().trim() ?? '';
      if (value.isNotEmpty) values[value.toLowerCase()] = value;
    }
    if (currentValue.trim().isNotEmpty) {
      values[currentValue.toLowerCase()] = currentValue;
    }
    final result = values.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return result;
  }

  List<Map<String, dynamic>> _mergedSetupOptionRows(String optionType) {
    final merged = <String, Map<String, dynamic>>{};
    for (final value in _setupOptionValues(optionType, '')) {
      merged[value.toLowerCase()] = {
        'id': null,
        'option_type': optionType,
        'value': value,
        'updated_at': null,
        'source': 'asset_master',
      };
    }
    for (final row in setupOptionRows.where(
      (row) => row['option_type']?.toString() == optionType,
    )) {
      final value = row['value']?.toString().trim() ?? '';
      if (value.isEmpty) continue;
      merged[value.toLowerCase()] = {...row, 'source': 'setup'};
    }
    final result = merged.values.toList()
      ..sort(
        (first, second) => (first['value']?.toString().toLowerCase() ?? '')
            .compareTo(second['value']?.toString().toLowerCase() ?? ''),
      );
    return result;
  }

  Widget _setupPageFrame({
    required bool branchesMode,
    required int count,
    required VoidCallback onAdd,
    required List<Widget> stats,
    required String directoryTitle,
    required String directorySubtitle,
    required String searchHint,
    required int recordsCount,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SetupHero(branchesMode: branchesMode, count: count, onAdd: onAdd),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth >= 1080
                ? (constraints.maxWidth - ((stats.length - 1) * 16)) /
                      stats.length
                : constraints.maxWidth >= 720
                ? (constraints.maxWidth - 16) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: stats
                  .map((card) => SizedBox(width: cardWidth, child: card))
                  .toList(),
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
                color: const Color(0xff1d3557).withValues(alpha: .055),
                blurRadius: 28,
                spreadRadius: -10,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xff4263eb), Color(0xff15aabf)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
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
                            directoryTitle,
                            style: const TextStyle(
                              color: Color(0xff17243b),
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            directorySubtitle,
                            style: const TextStyle(
                              color: Color(0xff8a97a9),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$recordsCount records',
                      style: const TextStyle(
                        color: Color(0xff60718a),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: searchController,
                  onChanged: (value) => _updateWebState(() {
                    searchQuery = value;
                    _resetPage(selectedSection);
                  }),
                  decoration: InputDecoration(
                    hintText: searchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              searchController.clear();
                              _updateWebState(() {
                                searchQuery = '';
                                _resetPage(selectedSection);
                              });
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
                const SizedBox(height: 17),
                child,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _setupCell(dynamic value) => SizedBox(
    width: 120,
    child: Text(
      value?.toString().trim().isNotEmpty == true ? value.toString() : '-',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ),
  );

  String _setupDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _openSetupOptionDialog({
    required String optionType,
    required String singular,
    Map<String, dynamic>? row,
  }) async {
    final editing = row != null;
    final controller = TextEditingController(
      text: row?['value']?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xffedf4ff),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tune_rounded, color: Color(0xff1769ff)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(editing ? 'Edit $singular' : 'Add $singular')),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: '$singular Name *',
                prefixIcon: const Icon(Icons.label_outline_rounded),
                border: const OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? '$singular is required'
                  : null,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.pop(context, controller.text.trim());
            },
            icon: Icon(
              editing ? Icons.save_outlined : Icons.add_rounded,
              color: Colors.white,
            ),
            label: Text(
              editing ? 'Save Changes' : 'Add $singular',
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff1769ff),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;
    try {
      if (editing) {
        if (row['id'] == null) {
          await webRepository.renameMasterOption(
            optionType: optionType,
            oldValue: row['value']?.toString() ?? '',
            newValue: result,
          );
        } else {
          await webRepository.updateSetupOption(
            id: row['id'],
            optionType: optionType,
            oldValue: row['value']?.toString() ?? '',
            value: result,
          );
        }
      } else {
        await webRepository.addSetupOption(
          optionType: optionType,
          value: result,
        );
      }
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            editing
                ? '$singular updated successfully'
                : '$singular added successfully',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save $singular: $error')),
      );
    }
  }

  Future<void> _openMasterAssetDialog({Map<String, dynamic>? row}) async {
    final editing = row != null;
    final controllers = <String, TextEditingController>{
      for (final key in ['name', 'item_code', 'department'])
        key: TextEditingController(text: row?[key]?.toString() ?? ''),
    };
    final classificationOptions = _setupOptionValues(
      'classification',
      row?['classification']?.toString() ?? '',
    );
    final categoryOptions = _setupOptionValues(
      'category',
      row?['category']?.toString() ?? '',
    );
    final subCategoryOptions = _setupOptionValues(
      'sub_category',
      row?['sub_category']?.toString() ?? '',
    );
    var classification = row?['classification']?.toString().trim() ?? '';
    var category = row?['category']?.toString().trim() ?? '';
    var subCategory = row?['sub_category']?.toString().trim() ?? '';
    if (classification.isEmpty) classification = classificationOptions.first;
    if (category.isEmpty) category = categoryOptions.first;
    if (subCategory.isEmpty) subCategory = subCategoryOptions.first;
    var assetClassification =
        row?['asset_classification']?.toString().trim() ?? '';
    if (!const [
      'Trackable Asset',
      'Low-Value Asset',
    ].contains(assetClassification)) {
      assetClassification = 'Trackable Asset';
    }
    var assetInventory = row?['asset_inventory']?.toString() ?? 'Asset';
    if (!const ['Asset', 'Inventory'].contains(assetInventory)) {
      assetInventory = 'Asset';
    }
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 34,
            vertical: 26,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: const Color(0xffedf4ff),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.category_outlined,
                  color: Color(0xff1769ff),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(editing ? 'Edit Asset Master' : 'Add Asset Master'),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          content: SizedBox(
            width: 820,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _setupDialogField(
                      controllers['name']!,
                      'Name *',
                      required: true,
                    ),
                    _setupDialogField(
                      controllers['item_code']!,
                      'Item Code *',
                      required: true,
                    ),
                    _setupDropdownField(
                      label: 'Category',
                      value: category,
                      items: categoryOptions,
                      onChanged: (value) =>
                          setDialogState(() => category = value ?? category),
                    ),
                    _setupDropdownField(
                      label: 'Sub Category',
                      value: subCategory,
                      items: subCategoryOptions,
                      onChanged: (value) => setDialogState(
                        () => subCategory = value ?? subCategory,
                      ),
                    ),
                    _setupDropdownField(
                      label: 'Classification',
                      value: classification,
                      items: classificationOptions,
                      onChanged: (value) => setDialogState(
                        () => classification = value ?? classification,
                      ),
                    ),
                    _setupDialogField(controllers['department']!, 'Department'),
                    _setupDropdownField(
                      label: 'Asset Classification',
                      value: assetClassification,
                      items: const ['Low-Value Asset', 'Trackable Asset'],
                      onChanged: (value) => setDialogState(
                        () =>
                            assetClassification = value ?? assetClassification,
                      ),
                    ),
                    SizedBox(
                      width: 392,
                      child: DropdownButtonFormField<String>(
                        initialValue: assetInventory,
                        decoration: const InputDecoration(
                          labelText: 'Asset / Inventory',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Asset',
                            child: Text('Asset'),
                          ),
                          DropdownMenuItem(
                            value: 'Inventory',
                            child: Text('Inventory'),
                          ),
                        ],
                        onChanged: (value) => setDialogState(
                          () => assetInventory = value ?? 'Asset',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                Navigator.pop(context, {
                  for (final entry in controllers.entries)
                    entry.key: entry.value.text.trim(),
                  'category': category,
                  'sub_category': subCategory,
                  'classification': classification,
                  'asset_classification': assetClassification,
                  'asset_inventory': assetInventory,
                  'updated_at': DateTime.now().toUtc().toIso8601String(),
                });
              },
              icon: Icon(
                editing ? Icons.save_outlined : Icons.add_rounded,
                color: Colors.white,
              ),
              label: Text(
                editing ? 'Save Changes' : 'Add Asset',
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff1769ff),
              ),
            ),
          ],
        ),
      ),
    );
    for (final controller in controllers.values) {
      controller.dispose();
    }
    if (result == null) return;
    try {
      if (editing) {
        await webRepository.updateMasterAsset(id: row['id'], values: result);
      } else {
        await webRepository.addMasterAsset(result);
      }
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            editing
                ? 'Asset master updated successfully'
                : 'Asset master added successfully',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save asset master: $error')),
      );
    }
  }

  Widget _setupDialogField(
    TextEditingController controller,
    String label, {
    bool required = false,
  }) => SizedBox(
    width: 392,
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (value) => value == null || value.trim().isEmpty
                ? 'This field is required'
                : null
          : null,
    ),
  );

  Widget _setupDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) => SizedBox(
    width: 392,
    child: DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: alphabetizedWebOptions(items)
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    ),
  );

  Future<void> _openBranchDialog({Map<String, dynamic>? row}) async {
    final editing = row != null;
    final controller = TextEditingController(
      text: row?['branch_name']?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xffedf4ff),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_business_outlined,
                color: Color(0xff1769ff),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(editing ? 'Edit Branch' : 'Add Branch')),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Branch Name *',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Branch name is required'
                  : null,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.pop(context, controller.text.trim());
            },
            icon: Icon(
              editing ? Icons.save_outlined : Icons.add_rounded,
              color: Colors.white,
            ),
            label: Text(
              editing ? 'Save Changes' : 'Add Branch',
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff1769ff),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;
    try {
      if (editing) {
        final oldName = row['branch_name']?.toString() ?? '';
        await webRepository.updateBranch(
          id: row['id'],
          oldBranchName: oldName,
          branchName: result,
        );
        if (selectedBranch == oldName) {
          selectedBranch = result;
        }
      } else {
        await webRepository.addBranch(result);
      }
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            editing
                ? 'Branch updated successfully'
                : 'Branch added successfully',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save branch: $error')));
    }
  }
}
