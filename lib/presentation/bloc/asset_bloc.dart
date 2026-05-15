import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

    /// =========================================================
    /// FIRST ADD ONLINE
    /// =========================================================
    for (final item in online) {
      mergedMap[item.itemCode] = item;
    }

    /// =========================================================
    /// LOCAL OVERRIDES ONLINE ONLY IF:
    /// - NOT SYNCED
    /// - DELETED
    /// =========================================================
    for (final item in local) {
      final existing = mergedMap[item.itemCode];

      /// LOCAL NEW ITEM
      if (existing == null) {
        mergedMap[item.itemCode] = item;

        continue;
      }

      /// LOCAL MODIFIED
      if (!item.isSynced || item.isDeleted) {
        mergedMap[item.itemCode] = item;
      }
    }

    final merged = mergedMap.values.toList();

    /// =========================================================
    /// REMOVE DELETED
    /// =========================================================
    merged.removeWhere((e) => e.isDeleted);

    /// =========================================================
    /// SORT NEWEST FIRST
    /// =========================================================
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return merged;
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
    await repository.uploadAssets(state.localAssets);

    /// RELOAD ONLINE
    final first = state.localAssets.first;

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
      /// =========================
      /// FIND CURRENT ITEM
      /// =========================
      final current = state.localAssets.firstWhere(
        (e) => e.itemCode == event.itemCode,
      );

      /// =========================
      /// SUPABASE
      /// =========================
      final supabase = Supabase.instance.client;

      /// =========================
      /// DELETE IMAGE FROM STORAGE
      /// =========================
      if (current.imagePath != null &&
          current.imagePath!.contains('asset-images')) {
        try {
          final uri = Uri.parse(current.imagePath!);

          final segments = uri.pathSegments;

          final bucketIndex = segments.indexOf('asset-images');

          if (bucketIndex != -1 && bucketIndex + 1 < segments.length) {
            final storagePath = segments.sublist(bucketIndex + 1).join('/');

            await supabase.storage.from('asset-images').remove([storagePath]);

            print('IMAGE DELETED');
            print(storagePath);
          }
        } catch (e) {
          print('IMAGE DELETE ERROR');
          print(e);
        }
      }

      /// =========================
      /// DELETE FROM SERVER
      /// =========================
      await supabase
          .from('asset_stock_taking')
          .delete()
          .eq('item_code', event.itemCode);

      /// =========================
      /// DELETE LOCAL
      /// =========================
      await repository.deleteLocalAsset(
        itemCode: event.itemCode,
        branch: event.branch,
        project: event.project,
      );

      /// =========================
      /// RELOAD ONLINE
      /// =========================
      final online = await repository.getProjectAssets(
        branch: event.branch,
        project: event.project,
      );

      /// =========================
      /// RELOAD LOCAL
      /// =========================
      final local = repository.getLocalAssets(
        branch: event.branch,
        project: event.project,
      );

      /// =========================
      /// MERGE
      /// =========================
      final merged = _mergeAssets(online: online, local: local);

      emit(state.copyWith(loading: false, localAssets: merged));
    } catch (e, stack) {
      print('================ DELETE ERROR ================');
      print(e);
      print(stack);
      print('==============================================');

      emit(state.copyWith(loading: false));
    }
  }
}
