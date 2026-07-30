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

    /// =========================
    /// EXISTING SERVER ITEM
    /// =========================
    if (model.id != null) {
      current.removeWhere((e) => e['id'] == model.id);
    }
    /// =========================
    /// NEW LOCAL ITEM
    /// =========================
    else {
      current.removeWhere((e) => e['item_code'] == model.itemCode);
    }

    /// =========================
    /// ADD NEW
    /// =========================
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

    final items = (data as List)
        .where((e) => e['location'] == branch && e['project_name'] == project)
        .map((e) {
          final item = Map<String, dynamic>.from(e);

          return AssetStockModel(
            id: item['id'],

            name: item['name'],

            assetCode: item['asset_code'],

            itemCode: item['item_code'],

            category: item['category'],

            subCategory: item['sub_category'],

            classification: item['classification'],

            assetClassification: item['asset_classification'] ?? '',

            assetInventory: item['asset_inventory'] ?? '',

            location: item['location'],

            projectName: item['project_name'],

            status: item['status'],

            brand: item['brand'],

            model: item['model'],

            serialNo: item['serial_no'],

            description: item['description'] ?? '',

            hasWarranty: item['has_warranty'] ?? false,

            warrantyDescription: item['warranty_description'] ?? '',

            warrantyImagePath: item['warranty_image_path'],

            localWarrantyImagePath: item['local_warranty_image_path'],

            isSynced: item['is_synced'] ?? false,

            isDeleted: item['is_deleted'] ?? false,

            imagePath: item['image_path'],

            localImagePath: item['local_image_path'],

            createdAt:
                (DateTime.tryParse(item['created_at']?.toString() ?? '') ??
                        DateTime.now())
                    .toLocal(),

            cost: (item['cost'] ?? 0).toDouble(),
          );
        })
        .toList();

    /// =========================
    /// SORT NEWEST FIRST
    /// =========================
    items.sort((a, b) {
      final compare = b.createdAt.millisecondsSinceEpoch.compareTo(
        a.createdAt.millisecondsSinceEpoch,
      );

      if (compare != 0) {
        return compare;
      }

      /// LOCAL FIRST
      if (!a.isSynced && b.isSynced) {
        return -1;
      }

      if (a.isSynced && !b.isSynced) {
        return 1;
      }

      /// FALLBACK
      return b.itemCode.compareTo(a.itemCode);
    });

    return items;
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

      if (item['item_code'] == itemCode) {
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
  /// SAVE SYNCED SERVER DATA IN A SINGLE HIVE WRITE
  /// =========================
  Future<void> saveSyncedAssets(List<AssetStockModel> models) async {
    if (models.isEmpty) {
      return;
    }

    final data = box.get('assets', defaultValue: []);

    final List<Map<String, dynamic>> current = (data as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    for (final model in models) {
      bool matches(Map<String, dynamic> item) {
        return item['item_code'] == model.itemCode ||
            (model.id != null && item['id'] == model.id);
      }

      final hasPendingLocalChange = current.any(
        (item) =>
            matches(item) &&
            (!(item['is_synced'] ?? false) || (item['is_deleted'] ?? false)),
      );

      if (hasPendingLocalChange) {
        continue;
      }

      current.removeWhere(matches);
      current.add(model.copyWith(isSynced: true, isDeleted: false).toJson());
    }

    await box.put('assets', current);
  }

  /// Applies a completed upload with one read and one write.
  Future<void> applyUploadedAssets(List<AssetStockModel> models) async {
    if (models.isEmpty) {
      return;
    }

    final data = box.get('assets', defaultValue: []);
    final current = (data as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    for (final model in models) {
      current.removeWhere(
        (item) =>
            item['item_code'] == model.itemCode ||
            (model.id != null && item['id'] == model.id),
      );

      if (!model.isDeleted) {
        current.add(model.copyWith(isSynced: true, isDeleted: false).toJson());
      }
    }

    await box.put('assets', current);
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

  Future<void> removeAssetPermanently({required String itemCode}) async {
    final data = box.get('assets', defaultValue: []);

    final List<Map<String, dynamic>> assets = (data as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    assets.removeWhere((e) => e['item_code'] == itemCode);

    await box.put('assets', assets);
  }
}
