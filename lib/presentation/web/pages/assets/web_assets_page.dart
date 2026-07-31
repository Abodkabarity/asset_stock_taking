part of '../../../pages/web_asset_dashboard_page.dart';

extension _AssetsPageExtension on _WebAssetDashboardPageState {
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
                        _updateWebState(() {
                          searchQuery = value;
                          _resetPage(WebAssetSection.assets);
                        });
                      },
                      onStatusChanged: (value) {
                        _updateWebState(() {
                          selectedStatus = value;
                          _resetPage(WebAssetSection.assets);
                        });
                      },
                      onClearFilters: () {
                        searchController.clear();

                        _updateWebState(() {
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

                                            _updateWebState(() {
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
                                    pageSize: _WebAssetDashboardPageState
                                        ._assetsPerPage,
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
}
