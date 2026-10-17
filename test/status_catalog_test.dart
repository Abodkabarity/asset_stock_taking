import 'dart:convert';
import 'package:asset_stock_taking/core/services/asset_status_catalog.dart';
import 'package:asset_stock_taking/data/models/asset_status_option.dart';
import 'package:asset_stock_taking/data/models/asset_stock_model.dart';
import 'package:asset_stock_taking/presentation/widgets/asset_status_selector.dart';
import 'package:asset_stock_taking/presentation/widgets/asset_state_badges.dart';
import 'package:asset_stock_taking/presentation/web/data/web_asset_repository.dart';
import 'package:asset_stock_taking/presentation/web/pages/setup/web_status_setup_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late SupabaseClient client;
  late WebAssetRepository repository;
  late List<Map<String, dynamic>> rows;
  late List<http.Request> requests;
  setUp(() {
    requests = [];
    AssetStatusCatalog.options.value = AssetStatusOption.defaults;
    rows = AssetStatusOption.defaults
        .map(
          (option) => <String, dynamic>{
            'value': option.value,
            'label': option.label,
            'kind': 'condition',
            'sort_order': option.sortOrder,
            'is_active': option.isActive,
          },
        )
        .toList();
    client = SupabaseClient(
      'https://test.supabase.co',
      'test-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        dynamic response = rows;
        if (request.url.path.endsWith('/asset_status_options')) {
          if (request.method == 'POST') {
            final row = Map<String, dynamic>.from(
              jsonDecode(request.body) as Map,
            );
            row['is_active'] ??= true;
            rows.add(row);
            response = [row];
          } else if (request.method == 'PATCH') {
            final value = request.url.queryParameters['value']!.substring(3);
            final row = rows.singleWhere((row) => row['value'] == value);
            row.addAll(
              Map<String, dynamic>.from(jsonDecode(request.body) as Map),
            );
            response = [row];
          }
        } else {
          response = [
            {'item_code': 'A-001'},
          ];
        }
        return http.Response(
          jsonEncode(response),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    repository = WebAssetRepository(supabase: client);
  });
  tearDown(() => client.dispose());

  test('catalog matches requested choices and keeps condition independent', () {
    expect(AssetStatusOption.defaults.map((option) => option.label), [
      'Under Maintenance',
      'Damaged',
      'Lost',
      'Disposed',
      'Sold',
      'New',
      'Good',
      'Assigned',
    ]);
    for (final option in AssetStatusOption.defaults) {
      for (final operation in [
        'Available',
        'Maintenance',
        'Checked Out',
        'Reserved',
        'Disposed',
      ]) {
        final asset = AssetStockModel.fromJson({
          'status': option.value,
          'operational_status': operation,
        });
        final restored = AssetStockModel.fromJson(
          asset.toJson(),
        ).copyWith(isSynced: true);
        expect(restored.status, option.value);
        expect(restored.operationalStatus, operation);
      }
    }
  });

  test(
    'rename and retirement preserve stable meanings and can be undone',
    () async {
      final good = (await repository.getStatusOptions()).firstWhere(
        (option) => option.value == 'Good',
      );
      await repository.saveStatusOption(original: good, label: 'Excellent');
      await repository.setStatusOptionActive('Good', false);
      final retired = await repository.getStatusOptions();
      expect(
        retired.singleWhere((option) => option.value == 'Good').label,
        'Excellent',
      );
      expect(
        AssetStatusCatalog.active.any((option) => option.value == 'Good'),
        isFalse,
      );
      expect(AssetStatusCatalog.label('Good'), 'Excellent');
      await repository.saveStatusOption(label: 'Refurbished');
      // A new label is a new meaning; the original Good history stays intact.
      expect(
        rows.singleWhere((row) => row['value'] == 'Good')['is_active'],
        isFalse,
      );
      await repository.setStatusOptionActive('Good', true);
      expect(
        rows.singleWhere((row) => row['value'] == 'Good')['value'],
        'Good',
      );
    },
  );

  test(
    'status names are validated and new names always remain physical',
    () async {
      await expectLater(
        repository.saveStatusOption(label: 'good'),
        throwsStateError,
      );
      await expectLater(
        repository.saveStatusOption(label: ''),
        throwsArgumentError,
      );
      await repository.saveStatusOption(label: 'Checked Out');
      final created = rows.singleWhere((row) => row['value'] == 'Checked Out');
      expect(created['kind'], 'condition');
    },
  );

  test(
    'batch creation retains the selected workflow and physical condition',
    () async {
      final codes = await repository.addAssetsBatch(
        assetCode: 'A',
        quantity: 2,
        template: {'status': 'Damaged', 'operational_status': 'Maintenance'},
      );
      expect(codes, hasLength(2));
      expect(
        requests.any((request) => request.url.path.contains('/rpc/')),
        isFalse,
      );
      final inserted =
          jsonDecode(
                requests
                    .singleWhere((request) => request.method == 'POST')
                    .body,
              )
              as List;
      expect(inserted, hasLength(2));
      for (final row in inserted) {
        expect(row['status'], 'Damaged');
        expect(row['operational_status'], 'Maintenance');
      }
    },
  );

  test(
    'editing cannot replace a busy operation or omit its expected state',
    () async {
      await expectLater(
        repository.updateAsset(
          itemCode: 'A-001',
          values: {'operational_status': 'Lost'},
          expectedOperationalStatus: 'Maintenance',
        ),
        throwsStateError,
      );
      await expectLater(
        repository.updateAsset(
          itemCode: 'A-001',
          values: {'operational_status': 'Sold'},
        ),
        throwsStateError,
      );
    },
  );

  testWidgets(
    'selector uses one physical field even for workflow-like status names',
    (tester) async {
      var selected = 'Good';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: StatefulBuilder(
                builder: (context, setState) => AssetStatusSelector(
                  value: selected,
                  options: AssetStatusOption.defaults,
                  onChanged: (value) => setState(() => selected = value),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      expect(find.text('Bad'), findsNothing);
      expect(find.text('Very Good'), findsNothing);
      await tester.tap(find.text('Under Maintenance').last);
      await tester.pumpAndSettle();
      expect(selected, 'Maintenance');
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(find.text('Physical condition'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('physical label edits never rename workflow availability', (
    tester,
  ) async {
    rows.singleWhere((row) => row['value'] == 'Maintenance')['label'] =
        'Needs repair';
    await repository.getStatusOptions();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AssetStateBadges(
            asset: AssetStockModel.fromJson({
              'status': 'Maintenance',
              'operational_status': 'Maintenance',
            }),
          ),
        ),
      ),
    );
    expect(find.byTooltip('Condition: Needs repair'), findsOneWidget);
    expect(find.byTooltip('Availability: Under Maintenance'), findsOneWidget);
  });

  testWidgets(
    'deleted statuses stay out of new selections and legacy values remain editable',
    (tester) async {
      rows.singleWhere((row) => row['value'] == 'Good')['is_active'] = false;
      final options = await repository.getStatusOptions();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssetStatusSelector(
              value: 'New',
              options: options,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      expect(find.text('Good'), findsNothing);
      await tester.tap(find.text('New').last);
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssetStatusSelector(
              value: 'Very Good',
              options: options,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('Very Good'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Setup adds, renames, deletes and restores status choices', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1150);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: WebStatusSetupPage(repository: repository),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('8 statuses'), findsOneWidget);
    await tester.tap(find.text('Add Status'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Refurbished');
    await tester.tap(find.text('Save Status'));
    await tester.pumpAndSettle();
    expect(find.text('Refurbished'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Edit Refurbished'));
    await tester.tap(find.byTooltip('Edit Refurbished'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Restored');
    await tester.tap(find.text('Save Status'));
    await tester.pumpAndSettle();
    expect(
      rows.singleWhere((row) => row['value'] == 'Refurbished')['label'],
      'Restored',
    );
    await tester.ensureVisible(find.byTooltip('Delete Restored'));
    await tester.tap(find.byTooltip('Delete Restored'));
    await tester.pumpAndSettle();
    expect(find.text('Restored'), findsNothing);
    expect(
      rows.singleWhere((row) => row['value'] == 'Refurbished')['is_active'],
      isFalse,
    );
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(
      rows.singleWhere((row) => row['value'] == 'Refurbished')['is_active'],
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
