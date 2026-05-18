import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/asset_item_model.dart';
import '../models/asset_stock_model.dart';

class AssetRemoteDatasource {
  final supabase = Supabase.instance.client;

  Future<List<AssetItemModel>> getMasterItems() async {
    final response = await supabase.from('asset_master').select().order('name');

    return response
        .map<AssetItemModel>((e) => AssetItemModel.fromJson(e))
        .toList();
  }

  Future<void> uploadAssets(List<AssetStockModel> items) async {
    if (items.isEmpty) {
      return;
    }

    /// =========================
    /// DELETE ITEMS
    /// =========================
    /// =========================
    /// DELETE ITEMS
    /// =========================
    final deletedItems = items.where((e) => e.isDeleted).toList();

    for (final item in deletedItems) {
      /// =========================
      /// MOVE TO DELETED TABLE
      /// =========================
      await supabase.from('asset_stock_taking_deleted').insert({
        'name': item.name,
        'asset_code': item.assetCode,
        'item_code': item.itemCode,
        'category': item.category,
        'sub_category': item.subCategory,
        'classification': item.classification,
        'location': item.location,
        'project_name': item.projectName,
        'status': item.status,
        'brand': item.brand,
        'model': item.model,
        'serial_no': item.serialNo,
        'image_path': item.imagePath,
        'cost': item.cost,
        'created_at': item.createdAt.toIso8601String(),
        'deleted_at': DateTime.now().toIso8601String(),
      });

      /// =========================
      /// DELETE FROM MAIN TABLE
      /// =========================
      await supabase
          .from('asset_stock_taking')
          .delete()
          .eq('item_code', item.itemCode);

      /// =========================
      /// RESEQUENCE
      /// =========================
      await supabase.rpc(
        'resequence_asset_codes',
        params: {'p_asset_code': item.assetCode},
      );
    }
    await Future.delayed(const Duration(milliseconds: 800));

    /// =========================
    /// BUILD UPLOAD LIST
    /// =========================
    final List<Map<String, dynamic>> uploadItems = [];

    for (final e in items.where((e) => !e.isDeleted)) {
      String? imageUrl = e.imagePath;

      /// =========================
      /// UPLOAD LOCAL IMAGE
      /// =========================
      if (e.localImagePath != null &&
          e.localImagePath!.isNotEmpty &&
          !e.localImagePath!.startsWith('http')) {
        try {
          final file = File(e.localImagePath!);

          if (file.existsSync()) {
            final fileName =
                '${DateTime.now().millisecondsSinceEpoch}_${e.itemCode}.jpg';

            final storagePath = 'assets/$fileName';

            /// UPLOAD TO STORAGE
            await supabase.storage
                .from('asset-images')
                .upload(
                  storagePath,
                  file,
                  fileOptions: const FileOptions(upsert: true),
                );

            /// GET PUBLIC URL
            imageUrl = supabase.storage
                .from('asset-images')
                .getPublicUrl(storagePath);

            print('IMAGE UPLOADED: $imageUrl');
          }
        } catch (err) {
          print('IMAGE UPLOAD ERROR');
          print(err);
        }
      }

      /// =========================
      /// ADD TO UPSERT LIST
      /// =========================
      uploadItems.add({
        'id': e.id,
        'asset_code': e.assetCode,
        'name': e.name,
        'category': e.category,
        'sub_category': e.subCategory,
        'classification': e.classification,
        'location': e.location,
        'project_name': e.projectName,
        'status': e.status,
        'brand': e.brand,
        'model': e.model,
        'serial_no': e.serialNo,
        'image_path': imageUrl,
        'cost': e.cost,
        'created_at': e.createdAt.toIso8601String(),
      });
    }

    /// =========================
    /// UPSERT
    /// =========================
    if (uploadItems.isNotEmpty) {
      await supabase
          .from('asset_stock_taking')
          .upsert(uploadItems, onConflict: 'id');

      print('UPLOAD SUCCESS');
    }
  }

  Future<int> getItemCount({required String itemCode}) async {
    final response = await supabase
        .from('asset_stock_taking')
        .select('item_code')
        .like('item_code', '$itemCode-%');

    return response.length;
  }

  Future<List<String>> getBranches() async {
    final response = await supabase.from('branches').select('branch_name');

    return response.map<String>((e) => e['branch_name'] as String).toList();
  }

  Future<List<String>> getProjects(String branch) async {
    final response = await supabase
        .from('projects')
        .select('project_name')
        .eq('branch_name', branch)
        .order('project_name');

    return response.map<String>((e) => e['project_name'] as String).toList();
  }

  Future<void> addProject({
    required String branch,
    required String project,
  }) async {
    await supabase.from('projects').insert({
      'branch_name': branch,
      'project_name': project,
    });
  }

  Future<void> deleteProject({
    required String branch,
    required String project,
  }) async {
    await supabase
        .from('projects')
        .delete()
        .eq('branch_name', branch)
        .eq('project_name', project);
  }

  Future<List<AssetItemModel>> getUpdatedMaster(String? lastSync) async {
    dynamic response;

    if (lastSync == null) {
      response = await supabase.from('asset_master').select();
    } else {
      response = await supabase
          .from('asset_master')
          .select()
          .gt('updated_at', lastSync);
    }

    return response
        .map<AssetItemModel>((e) => AssetItemModel.fromJson(e))
        .toList();
  }

  Future<List<String>> getClassifications(String branch) async {
    final response = await supabase
        .from('asset_stock_taking')
        .select('classification')
        .eq('location', branch);

    final list = response
        .map<String>((e) => e['classification'].toString())
        .toSet()
        .toList();

    list.sort();

    return list;
  }

  Future<List<AssetStockModel>> getAssetsForPrint({
    required String branch,
    required String classification,
  }) async {
    final response = await supabase
        .from('asset_stock_taking')
        .select()
        .eq('location', branch)
        .eq('classification', classification)
        .order('item_code');

    return response
        .map<AssetStockModel>((e) => AssetStockModel.fromJson(e))
        .toList();
  }

  Future<List<AssetStockModel>> getProjectAssets({
    required String branch,
    required String project,
  }) async {
    final response = await supabase
        .from('asset_stock_taking')
        .select()
        .eq('location', branch)
        .eq('project_name', project)
        .order('item_code');

    return response
        .map<AssetStockModel>((e) => AssetStockModel.fromJson(e))
        .toList();
  }

  Future<List<AssetStockModel>> getAssetsForBranch({
    required String branch,
  }) async {
    final response = await supabase
        .from('asset_stock_taking')
        .select()
        .eq('location', branch)
        .order('created_at', ascending: false);

    return response
        .map<AssetStockModel>((e) => AssetStockModel.fromJson(e))
        .toList();
  }

  Future<String?> uploadImage({
    required String itemCode,
    required String? localPath,
  }) async {
    try {
      if (localPath == null || localPath.isEmpty) {
        return null;
      }

      final file = File(localPath);

      if (!file.existsSync()) {
        return null;
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$itemCode.jpg';

      final path = 'assets/$fileName';

      await supabase.storage
          .from('asset-images')
          .upload(path, file, fileOptions: const FileOptions(upsert: true));

      final publicUrl = supabase.storage
          .from('asset-images')
          .getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      print(e);
      return null;
    }
  }
}
