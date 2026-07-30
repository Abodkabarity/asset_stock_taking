import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/asset_item_model.dart';
import '../../data/models/asset_stock_model.dart';
import '../../domain/repositories/asset_repository.dart';

part 'asset_event.dart';
part 'asset_state.dart';

class AssetBloc extends Bloc<AssetEvent, AssetState> {
  final AssetRepository repository;

  AssetBloc({required this.repository})
    : super(const AssetState(syncingMaster: false, masterDownloaded: false)) {
    on<LoadInitialData>(_load);

    on<SaveAssetEvent>(_save);

    on<UploadAssetsEvent>(_upload);

    on<DeleteAssetEvent>(_delete);
  }

  /// =========================================================
  /// MERGE ONLINE + LOCAL
  /// =========================================================
  static String assetKey(AssetStockModel item) {
    return item.itemCode.trim().isNotEmpty
        ? item.itemCode
        : item.id?.toString() ?? item.createdAt.toIso8601String();
  }

  static List<AssetStockModel> sortNewestFirst(List<AssetStockModel> items) {
    final active = items.where((e) => !e.isDeleted).toList();

    active.sort((a, b) {
      final dateCompare = b.createdAt.compareTo(a.createdAt);

      if (dateCompare != 0) {
        return dateCompare;
      }

      if (!a.isSynced && b.isSynced) {
        return -1;
      }

      if (a.isSynced && !b.isSynced) {
        return 1;
      }

      return b.itemCode.compareTo(a.itemCode);
    });

    return active;
  }

  static List<AssetStockModel> mergeAndSortAssets({
    required List<AssetStockModel> base,
    required List<AssetStockModel> override,
  }) {
    final mergedMap = <String, AssetStockModel>{};

    for (final item in base) {
      mergedMap[assetKey(item)] = item;
    }

    for (final item in override) {
      mergedMap[assetKey(item)] = item;
    }

    return sortNewestFirst(mergedMap.values.toList());
  }

  List<AssetStockModel> _mergeAssets({
    required List<AssetStockModel> online,
    required List<AssetStockModel> local,
  }) {
    final Map<String, AssetStockModel> mergedMap = {};

    /// =========================
    /// ONLINE FIRST
    /// =========================
    for (final item in online) {
      final key = assetKey(item);

      mergedMap[key] = item;
    }

    /// =========================
    /// LOCAL OVERRIDE
    /// =========================
    for (final item in local) {
      final key = assetKey(item);

      final existing = mergedMap[key];

      /// NEW LOCAL
      if (existing == null) {
        mergedMap[key] = item;
        continue;
      }

      /// LOCAL MODIFIED
      if (!item.isSynced || item.isDeleted) {
        mergedMap[key] = item;
      }
    }

    return sortNewestFirst(mergedMap.values.toList());
  }

  /// =========================================================
  /// LOAD
  /// =========================================================
  Future<void> _load(LoadInitialData event, Emitter<AssetState> emit) async {
    final isProjectLoad =
        event.branch.trim().isNotEmpty && event.project.trim().isNotEmpty;

    emit(
      state.copyWith(
        syncingMaster: true,
        masterMessage: isProjectLoad
            ? 'Refreshing Assets...'
            : 'Downloading Master...',
      ),
    );

    if (!isProjectLoad) {
      final masterFuture = repository.syncMaster();
      final branchesFuture = repository.getBranches();
      final items = await masterFuture;
      final branches = await branchesFuture;

      emit(
        state.copyWith(
          items: items,
          branches: branches,
          syncingMaster: false,
          masterDownloaded: true,
          masterMessage: 'Download Successfully',
        ),
      );
      return;
    }

    final local = repository.getLocalAssets(
      branch: event.branch,
      project: event.project,
    );

    // Make cached assets visible immediately instead of blocking the first
    // frame on network and master-data refreshes.
    emit(state.copyWith(localAssets: sortNewestFirst(local)));

    final masterFuture = repository.getMasterItems();
    final onlineFuture = repository.getProjectAssets(
      branch: event.branch,
      project: event.project,
    );
    final items = await masterFuture;
    final online = await onlineFuture;
    final merged = sortNewestFirst(online);

    emit(
      state.copyWith(
        items: items,
        localAssets: merged,
        syncingMaster: false,
        masterDownloaded: true,
        masterMessage: 'Download Successfully',
      ),
    );
  }

  /// =========================================================
  /// SAVE / EDIT
  /// =========================================================
  Future<void> _save(SaveAssetEvent event, Emitter<AssetState> emit) async {
    emit(state.copyWith(saving: true));

    /// SAVE LOCAL
    await repository.saveLocalAsset(event.model.copyWith(isSynced: false));

    /// RELOAD LOCAL ONLY
    final local = repository.getLocalAssets(
      branch: event.branch,
      project: event.project,
    );
    final merged = mergeAndSortAssets(base: state.localAssets, override: local);

    emit(state.copyWith(localAssets: merged, saving: false));
  }

  /// =========================================================
  /// UPLOAD
  /// =========================================================
  Future<void> _upload(
    UploadAssetsEvent event,
    Emitter<AssetState> emit,
  ) async {
    emit(state.copyWith(loading: true));

    /// UPLOAD
    final first = state.localAssets.first;

    final pendingUploads = repository.getPendingUploads(
      branch: first.location,
      project: first.projectName,
    );

    await repository.uploadAssets(pendingUploads);

    /// RELOAD ONLINE
    /// FIRST PROJECT

    /// IMPORTANT
    /// CLEAR LOCAL PROJECT
    /// RELOAD ONLINE AFTER UPLOAD
    final online = await repository.getProjectAssets(
      branch: first.location,
      project: first.projectName,
    );

    /// RELOAD LOCAL
    final local = repository.getLocalAssets(
      branch: first.location,
      project: first.projectName,
    );

    /// MERGE
    final merged = _mergeAssets(online: online, local: local);

    emit(state.copyWith(loading: false, localAssets: merged));
  }

  /// =========================================================
  /// DELETE
  /// =========================================================
  Future<void> _delete(DeleteAssetEvent event, Emitter<AssetState> emit) async {
    emit(state.copyWith(loading: true));

    try {
      final current = state.localAssets.firstWhere(
        (e) => e.itemCode == event.itemCode,
      );

      /// MARK AS DELETED ONLY
      await repository.saveLocalAsset(
        current.copyWith(isDeleted: true, isSynced: false),
      );

      final local = repository.getLocalAssets(
        branch: event.branch,
        project: event.project,
      );
      final merged = mergeAndSortAssets(
        base: state.localAssets,
        override: local,
      );

      emit(state.copyWith(loading: false, localAssets: merged));
    } catch (_) {
      emit(state.copyWith(loading: false));
    }
  }
}
