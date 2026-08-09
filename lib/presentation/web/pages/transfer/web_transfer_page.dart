part of '../../../pages/web_asset_dashboard_page.dart';

extension _TransferPageExtension on _WebAssetDashboardPageState {
  Widget _transferPanel() {
    final query = searchQuery.trim().toLowerCase();
    final assetByCode = <String, AssetStockModel>{
      for (final asset in assets) asset.itemCode: asset,
    };

    final records = transferRecords
        .where((record) {
          final itemCode = record['item_code']?.toString() ?? '';
          final from = record['from_branch']?.toString() ?? '';
          final to = record['to_branch']?.toString() ?? '';
          final description = record['description']?.toString() ?? '';
          final asset = assetByCode[itemCode];
          final matchesBranch =
              selectedBranch == null ||
              from == selectedBranch ||
              to == selectedBranch;
          final matchesSearch =
              query.isEmpty ||
              itemCode.toLowerCase().contains(query) ||
              from.toLowerCase().contains(query) ||
              to.toLowerCase().contains(query) ||
              description.toLowerCase().contains(query) ||
              (asset?.name.toLowerCase().contains(query) ?? false);
          return matchesBranch && matchesSearch;
        })
        .toList(growable: false);

    final pagedRecords = _paginate(records, WebAssetSection.transfer);
    final movedAssets = records
        .map((record) => record['item_code']?.toString() ?? '')
        .where((code) => code.isNotEmpty)
        .toSet();
    final affectedLocations = <String>{
      for (final record in records)
        if ((record['from_branch']?.toString().trim() ?? '').isNotEmpty)
          record['from_branch'].toString().trim(),
      for (final record in records)
        if ((record['to_branch']?.toString().trim() ?? '').isNotEmpty)
          record['to_branch'].toString().trim(),
    };
    final latestDate = records.isEmpty
        ? '-'
        : _transferDateLabel(records.first['created_at']);

    return TweenAnimationBuilder<double>(
      key: ValueKey('transfer-history-${selectedBranch ?? 'all'}'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: child,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TransferHeroCard(
            title: 'Move Assets',
            totalAssets: records.length,
            selectedBranch: selectedBranch,
            onSelectAssets: _openTransferAssetPicker,
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
                      title: 'Completed Moves',
                      value: records.length.toString(),
                      subtitle: 'Recorded transfer operations',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _MaintenanceStatCard(
                      icon: Icons.inventory_2_outlined,
                      color: const Color(0xff0f9f8f),
                      title: 'Moved Assets',
                      value: movedAssets.length.toString(),
                      subtitle: 'Unique assets transferred',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _MaintenanceStatCard(
                      icon: Icons.location_on_outlined,
                      color: const Color(0xfff59f00),
                      title: 'Locations',
                      value: affectedLocations.length.toString(),
                      subtitle: 'Branches in movement history',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _MaintenanceStatCard(
                      icon: Icons.schedule_rounded,
                      color: const Color(0xff7950f2),
                      title: 'Latest Move',
                      value: latestDate,
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
                  color: const Color(0xff1d3557).withValues(alpha: .055),
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
                                'Transfer History',
                                style: TextStyle(
                                  color: Color(0xff17243b),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Only completed movements from one branch to another',
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
                            '${records.length} movements',
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
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) => _updateWebState(() {
                        searchQuery = value;
                        _resetPage(WebAssetSection.transfer);
                      }),
                      decoration: InputDecoration(
                        hintText: 'Search movement by asset, tag ID or branch',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: searchController.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  searchController.clear();
                                  _updateWebState(() {
                                    searchQuery = '';
                                    _resetPage(WebAssetSection.transfer);
                                  });
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
                    child: Column(
                      children: [
                        const _TransferHistoryTableHeader(),
                        if (records.isEmpty)
                          _TransferHistoryEmptyState(
                            hasSearch: query.isNotEmpty,
                            onSelectAsset: _openTransferAssetPicker,
                          )
                        else ...[
                          const SizedBox(height: 8),
                          for (
                            var index = 0;
                            index < pagedRecords.items.length;
                            index++
                          )
                            _TransferHistoryRow(
                              record: pagedRecords.items[index],
                              asset:
                                  assetByCode[pagedRecords
                                      .items[index]['item_code']],
                            ),
                          const SizedBox(height: 12),
                          _PaginationBar(
                            currentPage: pagedRecords.currentPage,
                            totalPages: pagedRecords.totalPages,
                            totalItems: pagedRecords.totalItems,
                            pageSize:
                                _WebAssetDashboardPageState._assetsPerPage,
                            onPageChanged: (page) =>
                                _changePage(WebAssetSection.transfer, page),
                          ),
                        ],
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

  String _transferDateLabel(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
