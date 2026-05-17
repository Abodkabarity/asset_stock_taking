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
    current.removeWhere(
      (e) =>
          e['asset_code'] == model.assetCode &&
          e['created_at'] == model.createdAt.toIso8601String(),
    );

    /// ADD NEW
    current.add(model.toJson());
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
        .where((e) => e['location'] == branch && e['project_name'] == project)
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

            /// IMPORTANT
            imagePath: item['image_path'],

            /// IMPORTANT
            localImagePath: item['local_image_path'],

            createdAt:
                DateTime.tryParse(item['created_at']?.toString() ?? '') ??
                DateTime.now(),

            cost: (item['cost'] ?? 0).toDouble(),
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
    required String itemCode,
    required String branch,
    required String project,
  }) async {
    final data = box.get('assets', defaultValue: []);

    final List<Map<String, dynamic>> assets = (data as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    /// MARK AS DELETED
    for (int i = 0; i < assets.length; i++) {
      final item = assets[i];

      if (item['item_code'] == itemCode &&
          item['location'] == branch &&
          item['project_name'] == project) {
        assets[i]['is_deleted'] = true;
        assets[i]['is_synced'] = false;

        break;
      }
    }

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

  /// =========================
  /// SAVE SYNCED SERVER DATA
  /// =========================
  Future<void> saveSyncedAsset(AssetStockModel model) async {
    final data = box.get('assets', defaultValue: []);

    final List<Map<String, dynamic>> current = (data as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    /// REMOVE SAME ITEM
    current.removeWhere(
      (e) =>
          e['asset_code'] == model.assetCode &&
          e['created_at'] == model.createdAt.toIso8601String(),
    );

    /// ADD AS SYNCED
    current.add(model.copyWith(isSynced: true, isDeleted: false).toJson());

    await box.put('assets', current);
  }

  /// =========================
  /// RESEQUENCE LOCAL
  /// =========================
  /// =========================
  /// RESEQUENCE LOCAL
  /// =========================
  Future<void> resequenceLocalAssets({
    required String assetCode,
    required String branch,
    required String project,
  }) async {
    final data = box.get('assets', defaultValue: []);

    final List<Map<String, dynamic>> assets = (data as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    /// =========================
    /// ACTIVE ITEMS ONLY
    /// =========================
    final activeItems = assets
        .where(
          (e) =>
              e['asset_code'] == assetCode &&
              e['location'] == branch &&
              e['project_name'] == project &&
              !(e['is_deleted'] ?? false),
        )
        .toList();

    /// =========================
    /// SORT BY CREATED DATE
    /// =========================
    activeItems.sort((a, b) {
      final aDate =
          DateTime.tryParse(a['created_at']?.toString() ?? '') ??
          DateTime.now();

      final bDate =
          DateTime.tryParse(b['created_at']?.toString() ?? '') ??
          DateTime.now();

      return aDate.compareTo(bDate);
    });

    /// =========================
    /// RESEQUENCE
    /// =========================
    for (int i = 0; i < activeItems.length; i++) {
      final newCode = '$assetCode-${(i + 1).toString().padLeft(4, '0')}';

      activeItems[i]['item_code'] = newCode;
    }

    /// =========================
    /// REMOVE OLD ACTIVE ITEMS
    /// =========================
    assets.removeWhere(
      (e) =>
          e['asset_code'] == assetCode &&
          e['location'] == branch &&
          e['project_name'] == project &&
          !(e['is_deleted'] ?? false),
    );

    /// =========================
    /// ADD RESEQUENCED ITEMS
    /// =========================
    assets.addAll(activeItems);

    /// =========================
    /// SAVE
    /// =========================
    await box.put('assets', assets);
  }

  /// =========================
  /// GET PENDING UPLOADS
  /// =========================
  List<AssetStockModel> getPendingUploads({
    required String branch,
    required String project,
  }) {
    final data = box.get('assets', defaultValue: []);

    return (data as List)
        .where(
          (e) =>
              e['location'] == branch &&
              e['project_name'] == project &&
              (!(e['is_synced'] ?? false) || (e['is_deleted'] ?? false)),
        )
        .map((e) => AssetStockModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
