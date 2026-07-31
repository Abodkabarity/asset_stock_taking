part of '../../../pages/web_asset_dashboard_page.dart';

extension _AlertsPageExtension on _WebAssetDashboardPageState {
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
                        pageSize: _WebAssetDashboardPageState._assetsPerPage,
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
}
