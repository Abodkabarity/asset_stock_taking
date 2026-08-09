part of '../../../pages/web_asset_dashboard_page.dart';

extension _InventoryPageExtension on _WebAssetDashboardPageState {
  Widget _inventoryPanel() => _assetRegistryPanel(inventoryMode: true);
}
