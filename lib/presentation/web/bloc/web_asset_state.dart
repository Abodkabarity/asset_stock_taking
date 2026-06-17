import '../../../data/models/asset_item_model.dart';
import '../../../data/models/asset_stock_model.dart';

class WebAssetState {
  final List<AssetStockModel> assets;
  final List<AssetItemModel> masterItems;
  final List<String> branches;
  final bool loading;

  const WebAssetState({
    this.assets = const [],
    this.masterItems = const [],
    this.branches = const [],
    this.loading = false,
  });

  WebAssetState copyWith({
    List<AssetStockModel>? assets,
    List<AssetItemModel>? masterItems,
    List<String>? branches,
    bool? loading,
  }) {
    return WebAssetState(
      assets: assets ?? this.assets,
      masterItems: masterItems ?? this.masterItems,
      branches: branches ?? this.branches,
      loading: loading ?? this.loading,
    );
  }
}
