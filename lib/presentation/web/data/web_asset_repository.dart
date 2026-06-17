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
    String? project,
  }) async {
    await supabase
        .from('asset_stock_taking')
        .update({'location': branch, 'project_name': project ?? branch})
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

  Future<void> addActivityLog({
    required String itemCode,
    required String action,
    required String description,
    String? fromBranch,
    String? toBranch,
    Map<String, dynamic>? metadata,
  }) async {
    await supabase.from('asset_activity_log').insert({
      'item_code': itemCode,
      'action': action,
      'description': description,
      'from_branch': fromBranch,
      'to_branch': toBranch,
      'metadata': metadata ?? {},
    });
  }

  Future<void> addMaintenanceRecord({
    required AssetStockModel asset,
    required String title,
    required String details,
    required String maintenanceStatus,
    required String dueDate,
    required String completedDate,
    required String maintenanceBy,
    required double cost,
    required bool repeating,
  }) async {
    await supabase.from('asset_maintenance').insert({
      'item_code': asset.itemCode,
      'asset_name': asset.name,
      'status': maintenanceStatus,
      'title': title,
      'details': details,
      'due_date': _dateOrNull(dueDate),
      'completed_date': _dateOrNull(completedDate),
      'maintenance_by': maintenanceBy,
      'cost': cost,
      'repeating': repeating,
      'branch': asset.location,
      'project_name': asset.projectName,
    });
  }

  Future<List<Map<String, dynamic>>> getMaintenanceAlertsWithinDays({
    int days = 3,
  }) async {
    try {
      final response = await supabase
          .from('asset_maintenance')
          .select()
          .order('completed_date', ascending: true);

      final today = DateTime.now();
      final start = DateTime(today.year, today.month, today.day);
      final end = start.add(Duration(days: days));

      return response
          .where((row) {
            final status = row['status']?.toString().toLowerCase() ?? '';
            if (status == 'completed' || status == 'closed') return false;

            final dateText =
                row['completed_date']?.toString() ??
                row['due_date']?.toString();
            final date = _parseDate(dateText);
            if (date == null) return false;

            final cleanDate = DateTime(date.year, date.month, date.day);
            return !cleanDate.isBefore(start) && !cleanDate.isAfter(end);
          })
          .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMaintenanceRecords() async {
    try {
      final response = await supabase
          .from('asset_maintenance')
          .select()
          .order('created_at', ascending: false);

      return response
          .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
          .toList();
    } catch (_) {
      return [];
    }
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

  String? _dateOrNull(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final slashParts = trimmed.split('/');
    if (slashParts.length == 3) {
      final day = int.tryParse(slashParts[0]);
      final month = int.tryParse(slashParts[1]);
      final year = int.tryParse(slashParts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day).toIso8601String().split('T').first;
      }
    }

    final parsed = DateTime.tryParse(trimmed);
    return parsed?.toIso8601String().split('T').first ?? trimmed;
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
