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

  /// =========================
  /// LOAD
  /// =========================
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

    /// =========================
    /// ONLINE
    /// =========================
    final online = await repository.getProjectAssets(
      branch: event.branch,
      project: event.project,
    );

    /// =========================
    /// LOCAL UNSYNCED
    /// =========================
    final local = repository.getLocalAssets(
      branch: event.branch,
      project: event.project,
    );

    /// =========================
    /// MERGE
    /// item_code = UNIQUE
    /// =========================
    final merged = [...online];

    for (final localItem in local) {
      final index = merged.indexWhere((e) => e.itemCode == localItem.itemCode);

      /// REPLACE ONLINE
      if (index >= 0) {
        merged[index] = localItem;
      }
      /// ADD NEW LOCAL
      else {
        merged.add(localItem);
      }
    }

    /// REMOVE DELETED
    merged.removeWhere((e) => e.isDeleted);

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

  /// =========================
  /// SAVE / EDIT
  /// =========================
  Future<void> _save(SaveAssetEvent event, Emitter<AssetState> emit) async {
    emit(state.copyWith(saving: true));

    /// SAVE LOCAL AS UNSYNCED
    await repository.saveLocalAsset(event.model.copyWith(isSynced: false));

    /// RELOAD
    final online = await repository.getProjectAssets(
      branch: event.branch,
      project: event.project,
    );

    final local = repository.getLocalAssets(
      branch: event.branch,
      project: event.project,
    );

    final merged = [...online];

    for (final localItem in local) {
      final index = merged.indexWhere((e) => e.itemCode == localItem.itemCode);

      if (index >= 0) {
        merged[index] = localItem;
      } else {
        merged.add(localItem);
      }
    }

    merged.removeWhere((e) => e.isDeleted);

    emit(state.copyWith(localAssets: merged, saving: false));
  }

  /// =========================
  /// UPLOAD
  /// =========================
  Future<void> _upload(
    UploadAssetsEvent event,
    Emitter<AssetState> emit,
  ) async {
    emit(state.copyWith(loading: true));

    /// UPLOAD UNSYNCED
    await repository.uploadAssets(state.localAssets);

    /// RELOAD ONLINE
    final first = state.localAssets.first;

    final online = await repository.getProjectAssets(
      branch: first.location,
      project: first.projectName,
    );

    emit(state.copyWith(loading: false, localAssets: online));
  }

  /// =========================
  /// DELETE
  /// =========================
  Future<void> _delete(DeleteAssetEvent event, Emitter<AssetState> emit) async {
    /// FIND CURRENT
    final current = state.localAssets.firstWhere(
      (e) => e.itemCode == event.itemCode,
    );

    /// MARK DELETED LOCALLY
    await repository.saveLocalAsset(
      current.copyWith(isDeleted: true, isSynced: false),
    );

    /// RELOAD
    final online = await repository.getProjectAssets(
      branch: event.branch,
      project: event.project,
    );

    final local = repository.getLocalAssets(
      branch: event.branch,
      project: event.project,
    );

    final merged = [...online];

    for (final localItem in local) {
      final index = merged.indexWhere((e) => e.itemCode == localItem.itemCode);

      if (index >= 0) {
        merged[index] = localItem;
      } else {
        merged.add(localItem);
      }
    }

    merged.removeWhere((e) => e.isDeleted);

    emit(state.copyWith(localAssets: merged));
  }
}
