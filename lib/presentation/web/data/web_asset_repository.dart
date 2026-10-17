import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/asset_status.dart';
import '../../../core/services/asset_status_catalog.dart';
import '../../../data/models/asset_status_option.dart';
import '../../../data/models/asset_item_model.dart';
import '../../../data/models/asset_stock_model.dart';
import '../auth/web_auth_session.dart';

class WebAssetRepository {
  final SupabaseClient supabase;

  WebAssetRepository({SupabaseClient? supabase})
    : supabase = supabase ?? Supabase.instance.client;

  bool _separatedSchemaVerified = false;

  Future<void> _requireOperationalSchema() async {
    if (_separatedSchemaVerified) return;
    try {
      await supabase
          .from('asset_stock_taking')
          .select('operational_status')
          .limit(1);
      _separatedSchemaVerified = true;
    } on PostgrestException catch (error) {
      if (error.code != '42703' && error.code != 'PGRST204') rethrow;
      throw StateError(
        'The asset condition migration must be applied before using asset workflows.',
      );
    }
  }

  Map<String, dynamic> get _activityActor {
    final actor = WebAuthSession.currentUser.value;
    return {
      'user_id': actor?.id,
      'user_name': actor?.userName ?? 'System',
      'user_role': actor?.role ?? 'system',
    };
  }

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

  Future<List<AssetStockModel>> getAssets() async {
    final response = await supabase
        .from('asset_stock_taking')
        .select()
        .order('created_at', ascending: false);

    return response
        .map<AssetStockModel>(
          (e) => AssetStockModel.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> getTransferActivityLogs() async {
    try {
      final response = await supabase
          .from('asset_activity_log')
          .select()
          .inFilter('action', const ['transfer', 'reserve_transfer'])
          .order('created_at', ascending: false);
      return response
          .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<Map<String, dynamic>>> getAssetActivityLogs(
    String itemCode,
  ) async {
    try {
      final response = await supabase
          .from('asset_activity_log')
          .select()
          .eq('item_code', itemCode)
          .order('created_at', ascending: false);
      return response
          .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<AssetItemModel>> getMasterItems() async {
    final response = await supabase.from('asset_master').select().order('name');

    return response
        .map<AssetItemModel>((e) => AssetItemModel.fromJson(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getMasterAssetRows() async {
    final response = await supabase.from('asset_master').select().order('name');
    return response
        .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> getBranchRows() async {
    final response = await supabase
        .from('branches')
        .select('id, branch_name')
        .order('branch_name');
    return response
        .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> getSetupOptionRows() async {
    try {
      final response = await supabase
          .from('asset_setup_options')
          .select()
          .order('value');
      return response
          .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<AssetStatusOption>> getStatusOptions() async {
    final rows = await supabase
        .from('asset_status_options')
        .select()
        .order('sort_order')
        .order('label');
    final options = rows
        .map(AssetStatusOption.fromJson)
        .toList(growable: false);
    AssetStatusCatalog.options.value = options;
    return options;
  }

  Future<void> saveStatusOption({
    AssetStatusOption? original,
    required String label,
  }) async {
    final clean = label.trim();
    if (clean.isEmpty || clean.length > 80) {
      throw ArgumentError('Enter a status name between 1 and 80 characters.');
    }
    final value = original?.value ?? clean;
    final existing = await getStatusOptions();
    if (existing.any(
      (row) =>
          row.isActive &&
          row.value != original?.value &&
          row.label.toLowerCase() == clean.toLowerCase(),
    )) {
      throw StateError('A status with this name already exists.');
    }
    final sameValue = existing
        .where((row) => row.value.toLowerCase() == value.toLowerCase())
        .firstOrNull;
    if (original == null && sameValue?.isActive == true) {
      throw StateError('This status already exists. Edit its name instead.');
    }
    if (original != null || sameValue != null) {
      final updated = await supabase
          .from('asset_status_options')
          .update({
            'label': clean,
            'is_active': true,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('value', original?.value ?? sameValue!.value)
          .select('value');
      if (updated.isEmpty) throw StateError('The status could not be saved.');
    } else {
      await supabase.from('asset_status_options').insert({
        'value': value,
        'label': clean,
        'kind': 'condition',
        'sort_order':
            existing.fold<int>(
              0,
              (max, row) => row.sortOrder > max ? row.sortOrder : max,
            ) +
            1,
      });
    }
  }

  Future<void> setStatusOptionActive(String value, bool active) async {
    final updated = await supabase
        .from('asset_status_options')
        .update({
          'is_active': active,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('value', value)
        .select('value');
    if (updated.isEmpty) throw StateError('The status could not be updated.');
  }

  Future<void> addSetupOption({
    required String optionType,
    required String value,
  }) async {
    await supabase.from('asset_setup_options').insert({
      'option_type': optionType,
      'value': value.trim(),
    });
  }

  Future<void> updateSetupOption({
    required dynamic id,
    required String optionType,
    required String oldValue,
    required String value,
  }) async {
    final updatedValue = value.trim();
    await supabase
        .from('asset_setup_options')
        .update({
          'value': updatedValue,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
    if (oldValue.trim().isNotEmpty && oldValue != updatedValue) {
      await supabase
          .from('asset_master')
          .update({
            optionType: updatedValue,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq(optionType, oldValue);
    }
  }

  Future<void> renameMasterOption({
    required String optionType,
    required String oldValue,
    required String newValue,
  }) async {
    final updatedValue = newValue.trim();
    if (oldValue.trim().isNotEmpty && oldValue != updatedValue) {
      await supabase
          .from('asset_master')
          .update({
            optionType: updatedValue,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq(optionType, oldValue);
    }
    try {
      await addSetupOption(optionType: optionType, value: updatedValue);
    } catch (_) {
      // It may already exist, or the setup migration may not yet be installed.
    }
  }

  Future<void> addMasterAsset(Map<String, dynamic> values) async {
    await supabase.from('asset_master').insert(values);
  }

  Future<void> updateMasterAsset({
    required dynamic id,
    required Map<String, dynamic> values,
  }) async {
    await supabase.from('asset_master').update(values).eq('id', id);
  }

  Future<void> addBranch(String branchName) async {
    await supabase.from('branches').insert({'branch_name': branchName.trim()});
  }

  Future<void> updateBranch({
    required dynamic id,
    required String oldBranchName,
    required String branchName,
  }) async {
    final updatedName = branchName.trim();
    await supabase
        .from('branches')
        .update({'branch_name': updatedName})
        .eq('id', id);

    if (oldBranchName.trim().isEmpty || oldBranchName == updatedName) return;

    await supabase
        .from('asset_stock_taking')
        .update({'location': updatedName})
        .eq('location', oldBranchName);

    final optionalUpdates = <Future<void> Function()>[
      () async => await supabase
          .from('asset_maintenance')
          .update({'branch': updatedName})
          .eq('branch', oldBranchName),
      () async => await supabase
          .from('asset_checkouts')
          .update({'location': updatedName})
          .eq('location', oldBranchName),
      () async => await supabase
          .from('asset_checkouts')
          .update({'assigned_location': updatedName})
          .eq('assigned_location', oldBranchName),
      () async => await supabase
          .from('asset_reservations')
          .update({'source_location': updatedName})
          .eq('source_location', oldBranchName),
      () async => await supabase
          .from('asset_reservations')
          .update({'target_location': updatedName})
          .eq('target_location', oldBranchName),
      () async => await supabase
          .from('asset_activity_log')
          .update({'from_branch': updatedName})
          .eq('from_branch', oldBranchName),
      () async => await supabase
          .from('asset_activity_log')
          .update({'to_branch': updatedName})
          .eq('to_branch', oldBranchName),
    ];
    for (final update in optionalUpdates) {
      try {
        await update();
      } catch (_) {
        // Older installations may not have every optional web workflow table.
      }
    }
  }

  Future<List<String>> getDepartments() async {
    final response = await supabase.from('asset_master').select('department');
    final unique = <String, String>{};
    for (final row in response) {
      final department = row['department']?.toString().trim() ?? '';
      if (department.isNotEmpty) {
        unique.putIfAbsent(department.toLowerCase(), () => department);
      }
    }
    final departments = unique.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return departments;
  }

  Future<String> generateAssetCode(String assetCode) async {
    final codes = await generateAssetCodes(assetCode, 1);
    return codes.single;
  }

  Future<List<String>> generateAssetCodes(
    String assetCode,
    int quantity,
  ) async {
    if (quantity < 1) return const [];
    final response = await supabase
        .from('asset_stock_taking')
        .select('item_code')
        .eq('asset_code', assetCode);

    var lastSerial = 0;

    for (final row in response) {
      final itemCode = row['item_code']?.toString() ?? '';
      final serial = int.tryParse(itemCode.split('-').last);

      if (serial != null && serial > lastSerial) lastSerial = serial;
    }

    return List<String>.generate(quantity, (index) {
      final serial = (lastSerial + index + 1).toString().padLeft(4, '0');
      return '$assetCode-$serial';
    }, growable: false);
  }

  Future<void> addAsset(Map<String, dynamic> row) async {
    await supabase.from('asset_stock_taking').insert(row);
  }

  /// Reserves sequential item codes and creates all records in one server-side
  /// transaction. The fallback keeps older Supabase projects functional until
  /// [supabase_web_bulk_asset_creation.sql] is installed.
  Future<List<String>> addAssetsBatch({
    required String assetCode,
    required int quantity,
    required Map<String, dynamic> template,
  }) async {
    if (quantity < 1 || quantity > 500) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be from 1 to 500');
    }

    // Older batch RPCs omit operational_status from their INSERT columns.
    // A workflow selection uses the atomic row insert below to preserve it.
    if (template['operational_status'] == null ||
        template['operational_status'] == AssetStatus.available) {
      try {
        final response = await supabase.rpc(
          'create_asset_stock_batch',
          params: {
            'p_asset_code': assetCode,
            'p_quantity': quantity,
            'p_template': template,
          },
        );
        return (response as List)
            .map((row) => (row as Map)['item_code']?.toString() ?? '')
            .where((code) => code.isNotEmpty)
            .toList(growable: false);
      } on PostgrestException catch (error) {
        final missingFunction =
            error.code == 'PGRST202' ||
            error.code == '42883' ||
            error.message.toLowerCase().contains('create_asset_stock_batch');
        if (!missingFunction) rethrow;
      }
    }

    // Backward-compatible path. A unique item_code constraint protects this
    // batch from concurrent users; on conflict the complete insert is retried.
    for (var attempt = 0; attempt < 3; attempt++) {
      final codes = await generateAssetCodes(assetCode, quantity);
      final createdAt = DateTime.now().toUtc();
      final rows = List<Map<String, dynamic>>.generate(quantity, (index) {
        return {
          ...template,
          'asset_code': assetCode,
          'item_code': codes[index],
          'created_at': createdAt
              .add(Duration(microseconds: index))
              .toIso8601String(),
        };
      }, growable: false);

      try {
        await supabase.from('asset_stock_taking').insert(rows);
        return codes;
      } on PostgrestException catch (error) {
        if (error.code != '23505' || attempt == 2) rethrow;
      }
    }

    throw StateError('Unable to reserve unique item codes');
  }

  Future<void> transferAsset({
    required String itemCode,
    required String branch,
  }) async {
    await _requireOperationalSchema();
    final updated = await supabase
        .from('asset_stock_taking')
        .update({'location': branch, 'project_name': ''})
        .eq('operational_status', AssetStatus.available)
        .eq('item_code', itemCode)
        .select('item_code');
    if (updated.isEmpty) {
      throw StateError('This asset is no longer available for transfer.');
    }
  }

  Future<void> transferAssetBatch({
    required List<AssetStockModel> assets,
    required String branch,
  }) async {
    await _requireOperationalSchema();
    if (assets.isEmpty) return;

    final destination = branch.trim();
    if (destination.isEmpty) {
      throw ArgumentError.value(branch, 'branch', 'Destination is required');
    }

    final itemCodes = assets
        .map((asset) => asset.itemCode.trim())
        .where((code) => code.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (itemCodes.isEmpty) return;

    final normalizedSources = assets
        .map((asset) => asset.location.trim().toLowerCase())
        .toSet();
    if (normalizedSources.length != 1) {
      throw StateError('All selected assets must share the same location.');
    }
    final source = assets.first.location.trim();
    if (source.toLowerCase() == destination.toLowerCase()) {
      throw StateError('Source and destination locations must be different.');
    }

    final sourceLocations = <String, List<String>>{};
    for (final asset in assets) {
      sourceLocations
          .putIfAbsent(asset.location, () => <String>[])
          .add(asset.itemCode);
    }

    final batchId =
        'move-${DateTime.now().toUtc().microsecondsSinceEpoch.toString()}';
    final movedAt = DateTime.now().toUtc().toIso8601String();

    final updatedRows = await supabase
        .from('asset_stock_taking')
        .update({'location': destination, 'project_name': ''})
        .eq('location', source)
        .eq('operational_status', AssetStatus.available)
        .inFilter('item_code', itemCodes)
        .select('item_code');
    final updatedCodes = updatedRows
        .map<String>((row) => row['item_code']?.toString() ?? '')
        .where((code) => code.isNotEmpty)
        .toSet();
    if (updatedCodes.length != itemCodes.length) {
      if (updatedCodes.isNotEmpty) {
        await supabase
            .from('asset_stock_taking')
            .update({'location': source, 'project_name': ''})
            .inFilter('item_code', updatedCodes.toList(growable: false));
      }
      throw StateError(
        'Some assets changed before the transfer. Refresh and try again.',
      );
    }

    try {
      await supabase
          .from('asset_activity_log')
          .insert(
            assets
                .map(
                  (asset) => {
                    ..._activityActor,
                    'item_code': asset.itemCode,
                    'action': 'transfer',
                    'description':
                        'Transferred from ${asset.location} to $destination',
                    'from_branch': asset.location,
                    'to_branch': destination,
                    'metadata': {
                      'batch_id': batchId,
                      'batch_quantity': itemCodes.length,
                      'batch_item_codes': itemCodes,
                      'asset_code': asset.assetCode,
                      'moved_at': movedAt,
                    },
                  },
                )
                .toList(growable: false),
          );
    } catch (error) {
      // Compensating rollback keeps the registry consistent when logging fails.
      for (final entry in sourceLocations.entries) {
        await supabase
            .from('asset_stock_taking')
            .update({'location': entry.key, 'project_name': ''})
            .inFilter('item_code', entry.value);
      }
      rethrow;
    }
  }

  Future<void> updateCondition({
    required String itemCode,
    required String condition,
    required int expectedRevision,
  }) async {
    if (condition.trim().isEmpty) {
      throw ArgumentError('Enter a physical status.');
    }
    final updated = await supabase
        .from('asset_stock_taking')
        .update({
          'status': condition,
          'condition_revision': expectedRevision + 1,
        })
        .eq('item_code', itemCode)
        .eq('condition_revision', expectedRevision)
        .select('item_code');
    if (updated.isEmpty) {
      throw StateError(
        'The condition changed on another device. Refresh and try again.',
      );
    }
  }

  Future<void> updateOperationalStatus({
    required String itemCode,
    required String operationalStatus,
  }) async {
    await _requireOperationalSchema();
    final updated = await supabase
        .from('asset_stock_taking')
        .update({'operational_status': operationalStatus})
        .eq('item_code', itemCode)
        .eq('operational_status', AssetStatus.available)
        .select('item_code');
    if (updated.isEmpty) {
      throw StateError(
        'This asset is no longer available. Refresh and try again.',
      );
    }
  }

  Future<void> disposeAsset({
    required String itemCode,
    required String disposedDate,
    required String disposedTo,
    required String notes,
    String? afterImageUrl,
  }) async {
    await _requireOperationalSchema();
    final updated = await supabase
        .from('asset_stock_taking')
        .update({
          'operational_status': AssetStatus.disposed,
          'disposed_date': _dateOrNull(disposedDate),
          'disposed_to': disposedTo.trim(),
          'disposed_notes': notes.trim(),
          'disposed_image_path': afterImageUrl,
        })
        .eq('item_code', itemCode)
        .inFilter('operational_status', [
          AssetStatus.available,
          AssetStatus.disposed,
        ])
        .select('item_code');
    if (updated.isEmpty) {
      throw StateError('This asset is no longer available for disposal.');
    }
  }

  Future<void> updateAsset({
    required String itemCode,
    required Map<String, dynamic> values,
    int? expectedConditionRevision,
    String? expectedOperationalStatus,
  }) async {
    if (values.containsKey('status') &&
        (expectedConditionRevision == null ||
            (values['status']?.toString().trim().isEmpty ?? true))) {
      throw ArgumentError(
        'An explicit physical condition and its revision are required.',
      );
    }
    var request = supabase
        .from('asset_stock_taking')
        .update(values)
        .eq('item_code', itemCode);
    if (expectedConditionRevision != null) {
      request = request.eq('condition_revision', expectedConditionRevision);
    }
    if (values.containsKey('operational_status')) {
      if (expectedOperationalStatus == null ||
          (expectedOperationalStatus != AssetStatus.available &&
              expectedOperationalStatus != values['operational_status'])) {
        throw StateError(
          'Complete the current operation before choosing another operational status.',
        );
      }
      request = request.eq('operational_status', expectedOperationalStatus);
    }
    final updated = await request.select('item_code');
    if (updated.isEmpty) {
      throw StateError(
        'The asset changed on another device. Refresh before saving.',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getActiveCheckouts() async {
    try {
      final response = await supabase
          .from('asset_checkouts')
          .select()
          .eq('is_checked_in', false)
          .order('checked_out_at', ascending: false);
      return response
          .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPeople() async {
    try {
      final response = await supabase
          .from('asset_people')
          .select()
          .order('full_name');
      return response
          .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> addPerson({
    required String fullName,
    String employeeId = '',
    String title = '',
    String phone = '',
    String email = '',
  }) async {
    final row = await supabase
        .from('asset_people')
        .insert({
          'full_name': fullName.trim(),
          'employee_id': employeeId.trim(),
          'title': title.trim(),
          'phone': phone.trim(),
          'email': email.trim(),
        })
        .select()
        .single();
    return Map<String, dynamic>.from(row);
  }

  Future<void> checkOutAsset({
    required AssetStockModel asset,
    required String assignedTo,
    String? personId,
    required String checkoutDate,
    String dueDate = '',
    String notes = '',
    required String checkoutToType,
    String assignedLocation = '',
    String department = '',
  }) async {
    await _requireOperationalSchema();
    await supabase.from('asset_checkouts').insert({
      'item_code': asset.itemCode,
      'asset_name': asset.name,
      'assigned_to': assignedTo.trim(),
      'person_id': personId,
      'checkout_to_type': checkoutToType,
      'assigned_location': assignedLocation.trim(),
      'department': department.trim(),
      'checkout_date': _dateOrNull(checkoutDate),
      'due_date': _dateOrNull(dueDate),
      'notes': notes.trim(),
      'original_status': asset.status,
      'location': asset.location,
    });
  }

  Future<List<Map<String, dynamic>>> getActiveReservations() async {
    try {
      final response = await supabase
          .from('asset_reservations')
          .select()
          .eq('is_active', true)
          .order('reserved_at', ascending: false);
      return response
          .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> reserveAsset({
    required AssetStockModel asset,
    required String reserveForType,
    required String reservedFor,
    String? personId,
    required String targetLocation,
    String department = '',
    required String startDate,
    required String endDate,
    String notes = '',
  }) async {
    await _requireOperationalSchema();
    await supabase.from('asset_reservations').insert({
      'item_code': asset.itemCode,
      'asset_name': asset.name,
      'reserve_for_type': reserveForType,
      'reserved_for': reservedFor.trim(),
      'person_id': personId,
      'target_location': targetLocation.trim(),
      'department': department.trim(),
      'start_date': _dateOrNull(startDate),
      'end_date': _dateOrNull(endDate),
      'notes': notes.trim(),
      'original_status': asset.status,
      'source_location': asset.location,
    });
  }

  Future<void> unreserveAsset({
    required Map<String, dynamic> reservation,
  }) async {
    await _requireOperationalSchema();
    await supabase
        .from('asset_reservations')
        .update({
          'is_active': false,
          'released_at': DateTime.now().toIso8601String(),
          'resolution': 'unreserved',
        })
        .eq('id', reservation['id']);
  }

  Future<void> transferReservedAsset({
    required Map<String, dynamic> reservation,
  }) async {
    await _requireOperationalSchema();
    await supabase.rpc(
      'asset_transfer_reservation',
      params: {'p_reservation_id': reservation['id']},
    );
  }

  Future<void> checkInAsset({
    required Map<String, dynamic> checkout,
    required String returnDate,
    String notes = '',
  }) async {
    await _requireOperationalSchema();
    final checkoutId = checkout['id'];
    await supabase
        .from('asset_checkouts')
        .update({
          'is_checked_in': true,
          'checked_in_at': _dateOrNull(returnDate),
          'checkin_notes': notes.trim(),
        })
        .eq('id', checkoutId);
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
      ..._activityActor,
      'item_code': itemCode,
      'action': action,
      'description': description,
      'from_branch': fromBranch,
      'to_branch': toBranch,
      'metadata': metadata ?? {},
    });
  }

  Future<void> addActivityLogs({
    required List<String> itemCodes,
    required String action,
    required String description,
    String? fromBranch,
    String? toBranch,
    Map<String, dynamic>? metadata,
  }) async {
    final uniqueCodes = itemCodes
        .map((code) => code.trim())
        .where((code) => code.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (uniqueCodes.isEmpty) return;

    await supabase
        .from('asset_activity_log')
        .insert(
          uniqueCodes
              .map(
                (itemCode) => {
                  ..._activityActor,
                  'item_code': itemCode,
                  'action': action,
                  'description': description,
                  'from_branch': fromBranch,
                  'to_branch': toBranch,
                  'metadata': metadata ?? const <String, dynamic>{},
                },
              )
              .toList(growable: false),
        );
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
    await _requireOperationalSchema();
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
      'project_name': '',
    });
  }

  Future<void> updateMaintenanceRecord({
    required Object recordId,
    required Map<String, dynamic> values,
  }) async {
    await _requireOperationalSchema();
    await supabase.from('asset_maintenance').update(values).eq('id', recordId);
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

  Future<String> uploadDisposalImage({
    required String itemCode,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final extension = fileName.split('.').last.toLowerCase();
    final safeExtension = extension.isEmpty ? 'jpg' : extension;
    final safeItemCode = itemCode.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final storagePath =
        'disposals/${DateTime.now().millisecondsSinceEpoch}_${safeItemCode}_after.$safeExtension';

    await supabase.storage
        .from('asset-images')
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            upsert: false,
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
