import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

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
    emit(
      state.copyWith(
        syncingMaster: true,
        masterMessage: 'Downloading Master...',
      ),
    );

    /// MASTER
    final items = await repository.syncMaster();

    /// BRANCHES
    final branches = await repository.getBranches();

    /// ONLINE
    final online = await repository.getProjectAssets(
      branch: event.branch,
      project: event.project,
    );

    /// LOCAL
    final local = repository.getLocalAssets(
      branch: event.branch,
      project: event.project,
    );

    /// MERGE
    final merged = _mergeAssets(online: online, local: local);

    emit(
      state.copyWith(
        items: items,
        branches: branches,
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
    print('======================');
    print('LOCAL ORDER');
    print('======================');

    for (final e in local) {
      print(
        '${e.itemCode} | '
        '${e.createdAt} | '
        'SYNCED: ${e.isSynced}',
      );
    }
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

      /// RELOAD ONLINE
      final online = await repository.getProjectAssets(
        branch: event.branch,
        project: event.project,
      );

      /// RELOAD LOCAL
      final local = repository.getLocalAssets(
        branch: event.branch,
        project: event.project,
      );

      /// MERGE
      final merged = _mergeAssets(online: online, local: local);

      emit(state.copyWith(loading: false, localAssets: merged));
    } catch (e, stack) {
      print('DELETE ERROR');
      print(e);
      print(stack);

      emit(state.copyWith(loading: false));
    }
  }
}
