import 'package:hive/hive.dart';

import '../../models/asset_stock_model.dart';

class LocalAssetDatasource {
  final box = Hive.box('asset_box');

  /// =========================
  /// SAVE
  /// =========================
  Future<void> saveAsset(AssetStockModel model) async {
    final data = box.get('assets', defaultValue: []);

    final List<Map<String, dynamic>> current = (data as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    /// REMOVE SAME ASSET CODE
    current.removeWhere((e) => e['asset_code'] == model.assetCode);

    /// ADD NEW
    current.add(model.copyWith(isSynced: false, isDeleted: false).toJson());

    await box.put('assets', current);
  }

  /// =========================
  /// GET ASSETS
  /// =========================
  List<AssetStockModel> getAssets({
    required String branch,
    required String project,
  }) {
    final data = box.get('assets', defaultValue: []);

    return (data as List)
        .where(
          (e) =>
              e['location'] == branch &&
              e['project_name'] == project &&
              !(e['is_deleted'] ?? false),
        )
        .map((e) {
          final item = Map<String, dynamic>.from(e);

          return AssetStockModel(
            name: item['name'],

            assetCode: item['asset_code'],

            itemCode: item['item_code'],

            category: item['category'],

            subCategory: item['sub_category'],

            classification: item['classification'],

            location: item['location'],

            projectName: item['project_name'],

            status: item['status'],

            brand: item['brand'],

            model: item['model'],

            serialNo: item['serial_no'],

            isSynced: item['is_synced'] ?? false,

            isDeleted: item['is_deleted'] ?? false,
            imagePath: item['image_path'],
          );
        })
        .toList();
  }

  /// =========================
  /// CLEAR PROJECT
  /// =========================
  Future<void> clear({required String branch, required String project}) async {
    final data = box.get('assets', defaultValue: []);

    final filtered = (data as List)
        .where(
          (e) => !(e['location'] == branch && e['project_name'] == project),
        )
        .toList();

    await box.put('assets', filtered);
  }

  /// =========================
  /// DELETE ASSET
  /// =========================
  Future<void> deleteAsset({
    required String assetCode,
    required String branch,
    required String project,
  }) async {
    final data = box.get('assets', defaultValue: []);

    final List<Map<String, dynamic>> assets = (data as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    /// FIND ITEM
    final deleted = assets.firstWhere((e) => e['asset_code'] == assetCode);

    final itemCode = deleted['item_code'];

    /// REMOVE DELETED ITEM
    assets.removeWhere((e) => e['asset_code'] == assetCode);

    /// SAME ITEMS
    final sameItems = assets.where((e) {
      return e['location'] == branch &&
          e['project_name'] == project &&
          e['item_code'] == itemCode;
    }).toList();

    /// SORT
    sameItems.sort((a, b) {
      return a['asset_code'].toString().compareTo(b['asset_code'].toString());
    });

    /// REMOVE OLD SAME ITEMS
    assets.removeWhere((e) {
      return e['location'] == branch &&
          e['project_name'] == project &&
          e['item_code'] == itemCode;
    });

    /// REGENERATE SERIALS
    for (int i = 0; i < sameItems.length; i++) {
      final serial = (i + 1).toString().padLeft(2, '0');

      final newCode = '$itemCode-$serial';

      sameItems[i]['asset_code'] = newCode;

      sameItems[i]['is_synced'] = false;

      sameItems[i]['is_deleted'] = false;
    }

    /// ADD AGAIN
    assets.addAll(sameItems);

    /// SAVE
    await box.put('assets', assets);
  }

  /// =========================
  /// MARK SYNCED
  /// =========================
  Future<void> markAllAsSynced({
    required String branch,
    required String project,
  }) async {
    final data = box.get('assets', defaultValue: []);

    final List<Map<String, dynamic>> current = (data as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    /// MARK ALL AS SYNCED
    for (int i = 0; i < current.length; i++) {
      if (current[i]['location'] == branch &&
          current[i]['project_name'] == project) {
        current[i]['is_synced'] = true;

        current[i]['is_deleted'] = false;
      }
    }

    await box.put('assets', current);
  }
}
