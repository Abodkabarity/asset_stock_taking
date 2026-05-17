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
  List<AssetStockModel> _mergeAssets({
    required List<AssetStockModel> online,
    required List<AssetStockModel> local,
  }) {
    final Map<String, AssetStockModel> mergedMap = {};

    /// =========================
    /// ONLINE FIRST
    /// =========================
    for (final item in online) {
      final key = '${item.assetCode}_${item.createdAt.toIso8601String()}';

      mergedMap[key] = item;
    }

    /// =========================
    /// LOCAL OVERRIDE
    /// =========================
    for (final item in local) {
      final key = '${item.assetCode}_${item.createdAt.toIso8601String()}';

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

    final merged = mergedMap.values.toList();

    /// =========================
    /// ACTIVE ONLY
    /// =========================

    /// =========================
    /// GROUP BY ASSET CODE
    /// =========================
    final Map<String, List<AssetStockModel>> grouped = {};

    for (final item in merged) {
      grouped.putIfAbsent(item.assetCode, () => []);

      grouped[item.assetCode]!.add(item);
    }

    /// =========================
    /// UI RESEQUENCE
    /// =========================
    final List<AssetStockModel> resequenced = [];

    for (final entry in grouped.entries) {
      final assetCode = entry.key;

      final items = entry.value.where((e) => !e.isDeleted).toList();

      items.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      for (int i = 0; i < items.length; i++) {
        final newCode = '$assetCode-${(i + 1).toString().padLeft(4, '0')}';

        resequenced.add(items[i].copyWith(itemCode: newCode));
      }
    }

    resequenced.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return resequenced;
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
    await repository.clearLocalProject(
      branch: first.location,
      project: first.projectName,
    );

    /// RELOAD ONLINE FRESH
    final online = await repository.getProjectAssets(
      branch: first.location,
      project: first.projectName,
    );

    emit(state.copyWith(loading: false, localAssets: online));
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

      /// IMPORTANT
      /// MARK AS DELETED ONLY
      await repository.saveLocalAsset(
        current.copyWith(isDeleted: true, isSynced: false),
      );

      /// RESEQUENCE LOCAL
      await repository.resequenceLocalAssets(
        assetCode: current.assetCode,
        branch: current.location,
        project: current.projectName,
      );

      /// IMPORTANT
      /// RELOAD LOCAL AFTER RESEQUENCE
      final localAfterResequence = repository.getLocalAssets(
        branch: event.branch,
        project: event.project,
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
      final merged = _mergeAssets(online: online, local: localAfterResequence);

      emit(state.copyWith(loading: false, localAssets: merged));
    } catch (e, stack) {
      print('DELETE ERROR');
      print(e);
      print(stack);

      emit(state.copyWith(loading: false));
    }
  }
}
