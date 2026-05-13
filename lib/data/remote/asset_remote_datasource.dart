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

    /// DELETE ITEMS
    final deletedItems = items.where((e) => e.isDeleted).toList();

    for (final item in deletedItems) {
      await supabase
          .from('asset_stock_taking')
          .delete()
          .eq('item_code', item.itemCode);
    }

    /// UPSERT ITEMS
    final uploadItems = items
        .where((e) => !e.isDeleted)
        .map(
          (e) => {
            'asset_code': e.assetCode,
            'name': e.name,
            'item_code': e.itemCode,
            'category': e.category,
            'sub_category': e.subCategory,
            'classification': e.classification,
            'location': e.location,
            'project_name': e.projectName,
            'status': e.status,
            'brand': e.brand,
            'model': e.model,
            'serial_no': e.serialNo,
            'image_path': e.imagePath,
          },
        )
        .toList();

    if (uploadItems.isNotEmpty) {
      await supabase
          .from('asset_stock_taking')
          .upsert(uploadItems, onConflict: 'asset_code');
    }
  }

  Future<int> getItemCount({
    required String itemCode,
    required String branch,
  }) async {
    final response = await supabase
        .from('asset_stock_taking')
        .select('asset_code')
        .eq('location', branch)
        .like('asset_code', '$itemCode-%');

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
}
