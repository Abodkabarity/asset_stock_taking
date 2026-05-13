import '../../data/models/asset_item_model.dart';
import '../../data/models/asset_stock_model.dart';

abstract class AssetRepository {
  Future<List<AssetItemModel>> getMasterItems();

  Future<void> saveLocalAsset(AssetStockModel model);

  List<AssetStockModel> getLocalAssets({
    required String branch,
    required String project,
  });

  Future<void> uploadAssets(List<AssetStockModel> items);

  Future<String> generateAssetCode(
    String itemCode, {
    required String branch,
    required String project,
  });

  Future<List<String>> getBranches();

  Future<int> getItemCount({required String itemCode, required String branch});
  Future<List<String>> getProjects(String branch);

  Future<void> addProject({required String branch, required String project});

  Future<void> deleteProject({required String branch, required String project});
  Future<List<AssetItemModel>> syncMaster();
  Future<void> deleteLocalAsset({
    required String assetCode,

    required String branch,

    required String project,
  });
  List<AssetStockModel> getAssetsByClassification({
    required String branch,
    required String project,
    required String classification,
  });
  Future<List<String>> getClassifications(String branch);
  Future<List<AssetStockModel>> getAssetsForPrint({
    required String branch,
    required String classification,
  });
  Future<List<AssetStockModel>> getProjectAssets({
    required String branch,
    required String project,
  });
}
