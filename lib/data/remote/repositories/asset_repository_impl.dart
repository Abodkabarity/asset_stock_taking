import '../../../domain/repositories/asset_repository.dart';
import '../../datasource/local/local_asset_datasource.dart';
import '../../datasource/local/local_master_datasource.dart';
import '../../models/asset_item_model.dart';
import '../../models/asset_stock_model.dart';
import '../asset_remote_datasource.dart';

class AssetRepositoryImpl implements AssetRepository {
  final AssetRemoteDatasource remoteDatasource;

  final LocalAssetDatasource localDatasource;
  final LocalMasterDatasource localMasterDatasource;
  List<AssetItemModel>? _masterCache;
  AssetRepositoryImpl({
    required this.remoteDatasource,
    required this.localDatasource,
    required this.localMasterDatasource,
  });

  @override
  @override
  Future<List<AssetItemModel>> getMasterItems() async {
    final cached = _masterCache;
    if (cached != null) {
      return cached;
    }

    final local = localMasterDatasource.getMaster();

    if (local.isNotEmpty) {
      _masterCache = local;
      return local;
    }

    return syncMaster();
  }

  @override
  Future<void> saveLocalAsset(AssetStockModel model) {
    return localDatasource.saveAsset(model);
  }

  @override
  List<AssetStockModel> getLocalAssets({
    required String branch,
    required String project,
  }) {
    return localDatasource.getAssets(branch: branch, project: project);
  }

  @override
  Future<void> uploadAssets(List<AssetStockModel> items) async {
    final changedItems = items
        .where((e) => !e.isSynced || e.isDeleted)
        .toList();

    if (changedItems.isEmpty) {
      return;
    }

    /// SERVER
    await remoteDatasource.uploadAssets(changedItems);

    await localDatasource.applyUploadedAssets(changedItems);
  }

  @override
  Future<String> generateAssetCode(
    String assetCode, {
    required String branch,
    required String project,
  }) async {
    /// =========================
    /// LOCAL ITEMS
    /// =========================
    final localItems = localDatasource
        .getAssets(branch: branch, project: project)
        .where((e) => e.assetCode == assetCode)
        .toList();

    /// =========================
    /// SERVER ITEMS
    /// IMPORTANT:
    /// GLOBAL NOT PROJECT
    /// =========================
    final serverItems = await remoteDatasource.getAllAssetsByAssetCode(
      assetCode,
    );

    /// =========================
    /// USED SERIALS
    /// =========================
    final Set<int> usedSerials = {};

    /// LOCAL
    for (final item in localItems) {
      final parts = item.itemCode.split('-');

      final serial = int.tryParse(parts.last);

      if (serial != null) {
        usedSerials.add(serial);
      }
    }

    /// SERVER
    for (final item in serverItems) {
      final parts = item.itemCode.split('-');

      final serial = int.tryParse(parts.last);

      if (serial != null) {
        usedSerials.add(serial);
      }
    }

    /// =========================
    /// FIND NEXT EMPTY
    /// =========================
    int nextSerial = 1;

    while (usedSerials.contains(nextSerial)) {
      nextSerial++;
    }

    final serial = nextSerial.toString().padLeft(4, '0');

    return '$assetCode-$serial';
  }

  @override
  Future<List<String>> getBranches() {
    return remoteDatasource.getBranches();
  }

  @override
  Future<int> getItemCount({required String itemCode}) {
    return remoteDatasource.getItemCount(itemCode: itemCode);
  }

  @override
  Future<List<String>> getProjects(String branch) {
    return remoteDatasource.getProjects(branch);
  }

  @override
  Future<void> addProject({required String branch, required String project}) {
    return remoteDatasource.addProject(branch: branch, project: project);
  }

  @override
  Future<void> deleteProject({
    required String branch,
    required String project,
  }) {
    return remoteDatasource.deleteProject(branch: branch, project: project);
  }

  @override
  Future<List<AssetItemModel>> syncMaster() async {
    final current = localMasterDatasource.getMaster();
    final needsAssetClassificationRefresh = current.any(
      (e) =>
          e.assetClassification.trim().isEmpty ||
          e.assetInventory.trim().isEmpty,
    );
    final lastSync = needsAssetClassificationRefresh
        ? null
        : localMasterDatasource.getLastSync();

    final updated = await remoteDatasource.getUpdatedMaster(lastSync);

    final map = {for (var e in current) e.itemCode: e};

    for (final item in updated) {
      map[item.itemCode] = item;
    }

    final merged = map.values.toList();
    _masterCache = merged;

    await localMasterDatasource.saveMaster(merged);

    await localMasterDatasource.saveLastSync(DateTime.now().toIso8601String());

    return merged;
  }

  @override
  Future<void> deleteLocalAsset({
    required String itemCode,

    required String branch,

    required String project,
  }) {
    return localDatasource.deleteAsset(
      itemCode: itemCode,

      branch: branch,

      project: project,
    );
  }

  @override
  List<AssetStockModel> getAssetsByClassification({
    required String branch,
    required String project,
    required String classification,
  }) {
    return localDatasource
        .getAssets(branch: branch, project: project)
        .where(
          (e) => e.classification.toLowerCase() == classification.toLowerCase(),
        )
        .toList();
  }

  @override
  Future<List<String>> getClassifications(String branch) {
    return remoteDatasource.getClassifications(branch);
  }

  @override
  Future<List<AssetStockModel>> getAssetsForPrint({
    required String branch,
    required String classification,
  }) {
    return remoteDatasource.getAssetsForPrint(
      branch: branch,
      classification: classification,
    );
  }

  @override
  Future<List<AssetStockModel>> getProjectAssets({
    required String branch,
    required String project,
  }) async {
    /// GET ONLINE
    final online = await remoteDatasource.getProjectAssets(
      branch: branch,
      project: project,
    );

    /// Persist the server snapshot in one Hive transaction. Pending local
    /// changes are preserved by the datasource.
    await localDatasource.saveSyncedAssets(online);

    /// IMPORTANT
    /// RETURN LOCAL AFTER SAVING
    return localDatasource.getAssets(branch: branch, project: project);
  }

  @override
  Future<void> clearLocalProject({
    required String branch,
    required String project,
  }) {
    return localDatasource.clear(branch: branch, project: project);
  }

  @override
  Future<List<AssetStockModel>> getAssetsForBranch({required String branch}) {
    return remoteDatasource.getAssetsForBranch(branch: branch);
  }

  @override
  List<AssetStockModel> getPendingUploads({
    required String branch,
    required String project,
  }) {
    return localDatasource.getPendingUploads(branch: branch, project: project);
  }

  @override
  Future<void> removeAssetPermanently({required String itemCode}) {
    return localDatasource.removeAssetPermanently(itemCode: itemCode);
  }
}
