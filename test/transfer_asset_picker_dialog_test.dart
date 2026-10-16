import 'package:asset_stock_taking/data/models/asset_stock_model.dart';
import 'package:asset_stock_taking/presentation/web/widgets/transfer/transfer_asset_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AssetStockModel sampleAsset(
  String code, {
  String location = 'Assets Store',
  String product = '104-002',
  String name = 'Below Sink Cabinet',
}) => AssetStockModel.fromJson({
  'name': name,
  'item_code': '$product-$code',
  'asset_code': product,
  'location': location,
  'serial_no': 'SN-$code',
  'category': 'Furniture',
});

List<AssetStockModel> sampleTransferAssets() => [
  for (final code in ['0004', '0002', '0001', '0003']) sampleAsset(code),
  sampleAsset('0001', product: '100-001', name: 'Branding Signage'),
  sampleAsset('0005', location: 'Dubai'),
  sampleAsset('0006', location: 'Dubai'),
];

Future<void> selectCode(WidgetTester tester, String code) async {
  final row = find.byKey(ValueKey('item-code-104-002-$code'));
  await tester.scrollUntilVisible(
    row,
    50,
    scrollable: find
        .descendant(
          of: find.byKey(const ValueKey('transfer-item-codes')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  await tester.tap(row);
  await tester.pumpAndSettle();
}

void main() {
  final confirm = find.byKey(const ValueKey('confirm-transfer'));
  final product = find.byKey(const ValueKey('product-asset:104-002'));
  final quantity = find.byKey(const ValueKey('transfer-quantity'));
  final codeSearch = find.byKey(const ValueKey('item-code-search'));
  TransferMoveRequest? result;

  Future<void> open(WidgetTester tester, {double width = 1280}) async {
    result = null;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDialog<TransferMoveRequest>(
                  context: context,
                  builder: (_) => TransferAssetPickerDialog(
                    assets: sampleTransferAssets(),
                    locations: const ['Assets Store', 'Dubai', 'Sharjah'],
                    initialLocation: 'Assets Store',
                  ),
                );
              },
              child: const Text('Open transfer'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open transfer'));
    await tester.pumpAndSettle();
    await tester.tap(product);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'quantity mode previews and submits deterministic available codes',
    (tester) async {
      await open(tester);
      await tester.enterText(quantity, '2');
      await tester.pumpAndSettle();
      expect(find.text('104-002-0001'), findsOneWidget);
      expect(find.text('104-002-0002'), findsOneWidget);
      expect(find.text('104-002-0003'), findsNothing);
      final check = find.byIcon(Icons.check_circle_rounded);
      expect(check, findsOneWidget);
      expect(
        find.ancestor(of: check, matching: find.byType(AnimatedRotation)),
        findsNothing,
      );
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(result!.destination, 'Dubai');
      expect(result!.assets.map((a) => a.itemCode), [
        '104-002-0001',
        '104-002-0002',
      ]);
    },
  );

  testWidgets(
    'specific codes mode sends only explicitly checked nonconsecutive codes',
    (tester) async {
      await open(tester);
      await tester.tap(find.text('Specific codes'));
      await tester.pumpAndSettle();
      expect(tester.widget<ElevatedButton>(confirm).onPressed, isNull);
      expect(find.text('0 selected'), findsOneWidget);
      for (final code in ['0002', '0004']) {
        await selectCode(tester, code);
      }
      await tester.pumpAndSettle();
      expect(find.text('2 selected'), findsOneWidget);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(result!.assets.map((a) => a.itemCode), [
        '104-002-0002',
        '104-002-0004',
      ]);
    },
  );

  testWidgets('code search and select visible preserve hidden selections', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Specific codes'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('item-code-104-002-0002')));
    await tester.enterText(codeSearch, 'SN-0004');
    await tester.pumpAndSettle();
    expect(find.text('104-002-0002'), findsNothing);
    await tester.tap(find.text('Select visible'));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(result!.assets.map((a) => a.itemCode), [
      '104-002-0002',
      '104-002-0004',
    ]);
  });

  testWidgets(
    'switching modes preserves each method and product search preserves choices',
    (tester) async {
      await open(tester);
      await tester.enterText(quantity, '3');
      await tester.tap(find.text('Specific codes'));
      await tester.pumpAndSettle();
      await selectCode(tester, '0004');
      await tester.tap(find.text('By quantity'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(quantity).controller!.text, '3');
      await tester.tap(find.text('Specific codes'));
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('product-search')),
        'Branding',
      );
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(result!.assets.single.itemCode, '104-002-0004');
    },
  );

  testWidgets(
    'invalid quantities cannot submit and changing product clears manual choices',
    (tester) async {
      await open(tester);
      for (final value in ['0', '5', '']) {
        await tester.enterText(quantity, value);
        await tester.pumpAndSettle();
        expect(tester.widget<ElevatedButton>(confirm).onPressed, isNull);
      }
      await tester.tap(find.text('Specific codes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select all'));
      await tester.pumpAndSettle();
      expect(find.text('4 selected'), findsOneWidget);
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(find.text('0 selected'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('item-code-104-002-0002')));
      await tester.tap(find.byKey(const ValueKey('product-asset:100-001')));
      await tester.pumpAndSettle();
      expect(find.text('0 selected'), findsOneWidget);
      expect(tester.widget<ElevatedButton>(confirm).onPressed, isNull);
    },
  );

  testWidgets(
    'changing source resets selection and supports both modes in branches',
    (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const ValueKey('transfer-source')));
      await tester.pumpAndSettle();
      await tester.tapAt(tester.getCenter(find.text('Dubai').last));
      await tester.pumpAndSettle();
      expect(find.text('Choose a product'), findsOneWidget);
      expect(tester.widget<ElevatedButton>(confirm).onPressed, isNull);
      await tester.tap(product);
      await tester.pumpAndSettle();
      expect(find.text('2 available at Dubai'), findsOneWidget);
      await tester.tap(find.text('Specific codes'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('item-code-104-002-0006')));
      await tester.pumpAndSettle();
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(result!.assets.single.itemCode, '104-002-0006');
      expect(result!.destination, isNot('Dubai'));
    },
  );

  testWidgets('searching an item code keeps the full product inventory', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(
      find.byKey(const ValueKey('product-search')),
      '104-002-0004',
    );
    await tester.pumpAndSettle();
    expect(find.text('4 available at Assets Store'), findsOneWidget);
    expect(find.text('4 units will move'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'small screens scroll both product and code selectors without overflow',
    (tester) async {
      await open(tester, width: 430);
      await tester.ensureVisible(find.text('Specific codes'));
      await tester.tap(find.text('Specific codes'));
      await tester.pumpAndSettle();
      expect(find.byType(CheckboxListTile), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
