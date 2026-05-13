part of 'asset_bloc.dart';

class AssetState extends Equatable {
  final List<AssetItemModel> items;

  final List<AssetStockModel> localAssets;

  final List<String> branches;

  final bool loading;

  final bool saving;

  final bool syncingMaster;

  final bool masterDownloaded;

  final String? masterMessage;

  const AssetState({
    this.items = const [],

    this.localAssets = const [],

    this.branches = const [],

    this.loading = false,

    this.saving = false,

    this.syncingMaster = false,

    this.masterDownloaded = false,

    this.masterMessage,
  });

  AssetState copyWith({
    List<AssetItemModel>? items,

    List<AssetStockModel>? localAssets,

    List<String>? branches,

    bool? loading,

    bool? saving,

    bool? syncingMaster,

    bool? masterDownloaded,

    String? masterMessage,
  }) {
    return AssetState(
      items: items ?? this.items,

      localAssets: localAssets ?? this.localAssets,

      branches: branches ?? this.branches,

      loading: loading ?? this.loading,

      saving: saving ?? this.saving,

      syncingMaster: syncingMaster ?? this.syncingMaster,

      masterDownloaded: masterDownloaded ?? this.masterDownloaded,

      masterMessage: masterMessage ?? this.masterMessage,
    );
  }

  @override
  List<Object?> get props => [
    items,
    localAssets,
    branches,
    loading,
    saving,
    syncingMaster,
    masterDownloaded,
    masterMessage,
  ];
}
