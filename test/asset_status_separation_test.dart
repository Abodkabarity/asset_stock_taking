import 'package:asset_stock_taking/core/services/asset_excel_service.dart';
import 'package:asset_stock_taking/data/models/asset_stock_model.dart';
import 'package:asset_stock_taking/presentation/widgets/asset_state_badges.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'physical condition survives every workflow and JSON/copy round trips',
    () {
      for (final condition in ['Good', 'Damaged', 'Very Good', 'Refurbished']) {
        for (final state in [
          'Available',
          'Maintenance',
          'Checked Out',
          'Reserved',
          'Disposed',
        ]) {
          final asset = AssetStockModel.fromJson({
            'item_code': 'A-001',
            'status': condition,
            'operational_status': state,
            'condition_revision': 7,
          });
          final restored = AssetStockModel.fromJson(
            asset.toJson(),
          ).copyWith(isSynced: true);
          expect(restored.status, condition);
          expect(restored.operationalStatus, state);
          expect(restored.conditionRevision, 7);
          expect(restored.isAvailable, state == 'Available');
        }
      }
    },
  );

  test(
    'legacy workflow markers become Unknown condition without fabricating Good',
    () {
      for (final legacy in [
        'Maintenance',
        'Under Maintenance',
        'Disposed',
        'Reserved',
        'Checked Out',
      ]) {
        final asset = AssetStockModel.fromJson({'status': legacy});
        expect(asset.status, 'Unknown');
        expect(asset.needsConditionReview, isTrue);
        expect(asset.isAvailable, isFalse);
      }
      final asset = AssetStockModel.fromJson({'status': 'Good'});
      expect(asset.status, 'Good');
      expect(asset.operationalStatus, 'Available');
      expect(asset.copyWith(operationalStatus: 'Maintenance').status, 'Good');
    },
  );

  test('unknown workflow values never grant availability', () {
    final asset = AssetStockModel.fromJson({
      'status': 'Damaged',
      'operational_status': 'Quarantined',
    });
    expect(asset.isAvailable, isFalse);
    expect(asset.status, 'Damaged');
  });

  test('repeated offline condition edits retain one server revision', () {
    final online = AssetStockModel.fromJson({
      'status': 'Good',
      'condition_revision': 7,
    });
    final firstEdit = online.copyWith(
      status: 'Damaged',
      hasPendingConditionChange: true,
    );
    final secondEdit = AssetStockModel.fromJson(
      firstEdit.toJson(),
    ).copyWith(status: 'Bad');
    expect(secondEdit.conditionRevision, 7);
    expect(secondEdit.conditionRevisionForUpload, 8);
    expect(online.conditionRevisionForUpload, 7);
  });

  test(
    'Excel exports condition and availability as separate columns',
    () async {
      final asset = AssetStockModel.fromJson({
        'status': 'Damaged',
        'operational_status': 'Maintenance',
        'item_code': 'A-001',
      });
      final workbook = Excel.decodeBytes(
        await AssetExcelService.buildExcelBytes(assets: [asset]),
      );
      final rows = workbook['Assets'].rows;
      final columns = rows.first.map((cell) => cell?.value.toString()).toList();
      expect(rows[1][columns.indexOf('status')]!.value.toString(), 'Damaged');
      expect(
        rows[1][columns.indexOf('operational_status')]!.value.toString(),
        'Maintenance',
      );
    },
  );

  testWidgets(
    'badges identify both dimensions and unknown conditions need review',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AssetStateBadges(
                  asset: AssetStockModel.fromJson({
                    'status': 'Damaged',
                    'operational_status': 'Maintenance',
                  }),
                ),
                AssetStateBadges(
                  asset: AssetStockModel.fromJson({
                    'status': 'Unknown',
                    'operational_status': 'Disposed',
                  }),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byTooltip('Condition: Damaged'), findsOneWidget);
      expect(find.byTooltip('Availability: Maintenance'), findsOneWidget);
      expect(find.text('Needs review'), findsOneWidget);
      expect(find.text('Disposed'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
