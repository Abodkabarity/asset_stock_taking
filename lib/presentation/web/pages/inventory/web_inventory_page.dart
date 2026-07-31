part of '../../../pages/web_asset_dashboard_page.dart';

extension _InventoryPageExtension on _WebAssetDashboardPageState {
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
          _updateWebState(() {
            searchQuery = value;
            _resetPage(WebAssetSection.inventory);
          });
        },
        onStatusChanged: (value) {
          _updateWebState(() {
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
              pageSize: _WebAssetDashboardPageState._assetsPerPage,
              onPageChanged: (page) =>
                  _changePage(WebAssetSection.inventory, page),
            ),
          ],
        ],
      ),
    );
  }
}
