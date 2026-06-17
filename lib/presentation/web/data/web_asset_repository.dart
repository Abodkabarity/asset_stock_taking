import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/asset_item_model.dart';
import '../../../data/models/asset_stock_model.dart';

class WebAssetRepository {
  final SupabaseClient supabase;

  WebAssetRepository({SupabaseClient? supabase})
    : supabase = supabase ?? Supabase.instance.client;

  Future<List<String>> getBranches() async {
    final response = await supabase
        .from('branches')
        .select('branch_name')
        .order('branch_name');

    return response
        .map<String>((e) => e['branch_name']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<List<String>> getProjects(String branch) async {
    final response = await supabase
        .from('projects')
        .select('project_name')
        .eq('branch_name', branch)
        .order('project_name');

    return response
        .map<String>((e) => e['project_name']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<List<AssetStockModel>> getAssets() async {
    final response = await supabase
        .from('asset_stock_taking')
        .select()
        .order('created_at', ascending: false);

    return response
        .map<AssetStockModel>((e) => AssetStockModel.fromJson(e))
        .toList();
  }

  Future<List<AssetItemModel>> getMasterItems() async {
    final response = await supabase.from('asset_master').select().order('name');

    return response
        .map<AssetItemModel>((e) => AssetItemModel.fromJson(e))
        .toList();
  }

  Future<String> generateAssetCode(String assetCode) async {
    final response = await supabase
        .from('asset_stock_taking')
        .select('item_code')
        .eq('asset_code', assetCode);

    final usedSerials = <int>{};

    for (final row in response) {
      final itemCode = row['item_code']?.toString() ?? '';
      final serial = int.tryParse(itemCode.split('-').last);

      if (serial != null) {
        usedSerials.add(serial);
      }
    }

    var nextSerial = 1;
    while (usedSerials.contains(nextSerial)) {
      nextSerial++;
    }

    return '$assetCode-${nextSerial.toString().padLeft(4, '0')}';
  }

  Future<void> addAsset(Map<String, dynamic> row) async {
    await supabase.from('asset_stock_taking').insert(row);
  }

  Future<void> transferAsset({
    required String itemCode,
    required String branch,
    required String project,
  }) async {
    await supabase
        .from('asset_stock_taking')
        .update({'location': branch, 'project_name': project})
        .eq('item_code', itemCode);
  }

  Future<void> updateStatus({
    required String itemCode,
    required String status,
  }) async {
    await supabase
        .from('asset_stock_taking')
        .update({'status': status})
        .eq('item_code', itemCode);
  }

  Future<void> updateAsset({
    required String itemCode,
    required Map<String, dynamic> values,
  }) async {
    await supabase
        .from('asset_stock_taking')
        .update(values)
        .eq('item_code', itemCode);
  }

  Future<String> uploadWebImage({
    required String itemCode,
    required Uint8List bytes,
    required String fileName,
    required bool warranty,
  }) async {
    final extension = fileName.split('.').last.toLowerCase();
    final safeExtension = extension.isEmpty ? 'jpg' : extension;
    final prefix = warranty ? 'warranty' : 'asset';
    final storagePath =
        'assets/${DateTime.now().millisecondsSinceEpoch}_${itemCode}_$prefix.$safeExtension';

    await supabase.storage
        .from('asset-images')
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _contentType(safeExtension),
          ),
        );

    return supabase.storage.from('asset-images').getPublicUrl(storagePath);
  }

  String _contentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}
