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
  AssetRepositoryImpl({
    required this.remoteDatasource,
    required this.localDatasource,
    required this.localMasterDatasource,
  });

  @override
  @override
  Future<List<AssetItemModel>> getMasterItems() async {
    final local = localMasterDatasource.getMaster();

    if (local.isNotEmpty) {
      return local;
    }

    return await syncMaster();
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

    /// MARK AS SYNCED
    for (final item in changedItems) {
      await localDatasource.saveAsset(
        item.copyWith(isSynced: true, isDeleted: false),
      );
    }
  }

  @override
  Future<String> generateAssetCode(
    String itemCode, {

    required String branch,

    required String project,
  }) async {
    /// LOCAL
    final localItems = localDatasource
        .getAssets(branch: branch, project: project)
        .where((e) => e.itemCode == itemCode)
        .toList();

    /// SERVER
    final serverCount = await remoteDatasource.getItemCount(
      itemCode: itemCode,
      branch: branch,
    );

    int maxSerial = 0;

    /// LOCAL SERIALS
    for (final item in localItems) {
      final parts = item.itemCode.split('-');

      if (parts.length >= 3) {
        final serial = int.tryParse(parts.last) ?? 0;

        if (serial > maxSerial) {
          maxSerial = serial;
        }
      }
    }

    /// SERVER COUNT
    if (serverCount > maxSerial) {
      maxSerial = serverCount;
    }

    final next = maxSerial + 1;

    final serial = next.toString().padLeft(4, '0');

    return '$itemCode-$serial';
  }

  @override
  Future<List<String>> getBranches() {
    return remoteDatasource.getBranches();
  }

  @override
  Future<int> getItemCount({required String itemCode, required String branch}) {
    return remoteDatasource.getItemCount(itemCode: itemCode, branch: branch);
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
    final lastSync = localMasterDatasource.getLastSync();

    final updated = await remoteDatasource.getUpdatedMaster(lastSync);

    final current = localMasterDatasource.getMaster();

    final map = {for (var e in current) e.itemCode: e};

    for (final item in updated) {
      map[item.itemCode] = item;
    }

    final merged = map.values.toList();

    await localMasterDatasource.saveMaster(merged);

    await localMasterDatasource.saveLastSync(DateTime.now().toIso8601String());

    return merged;
  }

  @override
  Future<void> deleteLocalAsset({
    required String assetCode,

    required String branch,

    required String project,
  }) {
    return localDatasource.deleteAsset(
      assetCode: assetCode,

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
  }) {
    return remoteDatasource.getProjectAssets(branch: branch, project: project);
  }
}
