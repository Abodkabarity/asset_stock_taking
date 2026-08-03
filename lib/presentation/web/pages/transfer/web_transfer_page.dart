part of '../../../pages/web_asset_dashboard_page.dart';

extension _TransferPageExtension on _WebAssetDashboardPageState {
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

    final assetValue = filteredAssets.fold<double>(
      0,
      (total, asset) => total + asset.cost,
    );

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
                      icon: Icons.payments_outlined,
                      color: const Color(0xfff59f00),
                      title: 'Asset Value',
                      value: assetValue.toStringAsFixed(2),
                      subtitle: 'Total value in AED',
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
                              _updateWebState(() {
                                searchQuery = value;
                                _resetPage(WebAssetSection.transfer);
                              });
                            },
                            decoration: InputDecoration(
                              hintText:
                                  'Search by asset name, tag ID or location',
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

                                        _updateWebState(() {
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
                            pageSize:
                                _WebAssetDashboardPageState._assetsPerPage,
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
}
