import 'dart:convert';

import 'package:asset_stock_taking/data/models/asset_stock_model.dart';
import 'package:asset_stock_taking/data/remote/asset_remote_datasource.dart';
import 'package:asset_stock_taking/presentation/web/data/web_asset_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late List<http.Request> requests;
  late WebAssetRepository repository;
  late SupabaseClient client;
  final damaged = AssetStockModel.fromJson({
    'item_code': 'A-001',
    'status': 'Damaged',
    'name': 'Cabinet',
    'location': 'Store',
  });

  setUp(() {
    requests = [];
    client = SupabaseClient(
      'https://test.supabase.co',
      'test-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode(
            request.method == 'GET'
                ? [
                    {
                      'item_code': 'A-001',
                      'status': 'Damaged',
                      'operational_status': 'Maintenance',
                    },
                  ]
                : [
                    {'item_code': 'A-001'},
                  ],
          ),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    repository = WebAssetRepository(supabase: client);
  });
  tearDown(() => client.dispose());

  test(
    'mobile sync separates unknown rows and uploads one pending revision',
    () async {
      final remote = AssetRemoteDatasource(supabase: client);
      await remote.uploadAssets([
        AssetStockModel.fromJson({
          'id': 1,
          'item_code': 'known',
          'status': 'Damaged',
          'condition_revision': 7,
          'has_pending_condition_change': true,
          'operational_status': 'Reserved',
        }),
        AssetStockModel.fromJson({
          'id': 2,
          'item_code': 'unknown',
          'status': 'Maintenance',
        }),
      ]);
      final posts = requests.where((r) => r.method == 'POST').toList();
      expect(posts, hasLength(2));
      final known = (jsonDecode(posts[0].body) as List).single as Map;
      final unknown = (jsonDecode(posts[1].body) as List).single as Map;
      expect(known['status'], 'Damaged');
      expect(known['condition_revision'], 8);
      expect(unknown.containsKey('status'), isFalse);
      for (final row in [known, unknown]) {
        expect(row.containsKey('operational_status'), isFalse);
        expect(row.containsKey('has_pending_condition_change'), isFalse);
      }
    },
  );

  test('checkout and check-in never replace physical condition', () async {
    await repository.checkOutAsset(
      asset: damaged,
      assignedTo: 'Person',
      checkoutDate: '2026-10-16',
      checkoutToType: 'Person',
    );
    final inserted =
        jsonDecode(requests.singleWhere((r) => r.method == 'POST').body) as Map;
    expect(inserted['original_status'], 'Damaged');
    await repository.checkInAsset(
      checkout: {'id': 1, 'item_code': 'A-001', 'original_status': 'Good'},
      returnDate: '2026-10-16',
    );
    expect(
      requests.where(
        (r) =>
            r.method == 'PATCH' && r.url.path.endsWith('/asset_stock_taking'),
      ),
      isEmpty,
    );
  });

  test(
    'reservation, release and reserved transfer preserve condition',
    () async {
      await repository.reserveAsset(
        asset: damaged,
        reserveForType: 'Location',
        reservedFor: 'Dubai',
        targetLocation: 'Dubai',
        startDate: '2026-10-16',
        endDate: '2026-10-17',
      );
      await repository.unreserveAsset(
        reservation: {'id': 1, 'item_code': 'A-001', 'original_status': 'Good'},
      );
      await repository.transferReservedAsset(
        reservation: {
          'id': 2,
          'item_code': 'A-001',
          'target_location': 'Dubai',
          'original_status': 'Good',
        },
      );
      for (final request in requests.where(
        (r) =>
            r.method == 'PATCH' && r.url.path.endsWith('/asset_stock_taking'),
      )) {
        expect(
          (jsonDecode(request.body) as Map).containsKey('status'),
          isFalse,
        );
      }
    },
  );

  test(
    'disposal changes availability while maintenance updates only its work record',
    () async {
      await repository.disposeAsset(
        itemCode: 'A-001',
        disposedDate: '2026-10-16',
        disposedTo: 'Recycler',
        notes: 'Disposed',
      );
      final patch = jsonDecode(requests.last.body) as Map;
      expect(requests.last.url.queryParameters['select'], 'item_code');
      expect(patch['operational_status'], 'Disposed');
      expect(patch.containsKey('status'), isFalse);
      await repository.addMaintenanceRecord(
        asset: damaged,
        title: 'Repair',
        details: '',
        maintenanceStatus: 'Completed',
        dueDate: '',
        completedDate: '2026-10-16',
        maintenanceBy: 'Engineer',
        cost: 0,
        repeating: false,
      );
      await repository.updateMaintenanceRecord(
        recordId: 1,
        values: {'status': 'Completed'},
      );
      expect(
        requests.where(
          (r) =>
              r.method == 'PATCH' && r.url.path.endsWith('/asset_stock_taking'),
        ),
        hasLength(1),
      );
    },
  );

  test(
    'condition API accepts physical names independently of workflows',
    () async {
      await expectLater(
        repository.updateCondition(
          itemCode: 'A-001',
          condition: '',
          expectedRevision: 0,
        ),
        throwsArgumentError,
      );
      expect(requests, isEmpty);
      await repository.updateCondition(
        itemCode: 'A-001',
        condition: 'Disposed',
        expectedRevision: 0,
      );
      expect(jsonDecode(requests.single.body), {
        'status': 'Disposed',
        'condition_revision': 1,
      });
    },
  );

  test('legacy database is rejected before any workflow mutation', () async {
    final oldClient = SupabaseClient(
      'https://test.supabase.co',
      'test-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({
            'code': '42703',
            'message': 'column operational_status does not exist',
          }),
          400,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    final oldRepository = WebAssetRepository(supabase: oldClient);
    await expectLater(
      oldRepository.checkOutAsset(
        asset: damaged,
        assignedTo: 'Person',
        checkoutDate: '2026-10-16',
        checkoutToType: 'Person',
      ),
      throwsStateError,
    );
    expect(requests, hasLength(1));
    expect(requests.single.method, 'GET');
    await oldClient.dispose();
  });
}
