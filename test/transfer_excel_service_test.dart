import 'package:asset_stock_taking/core/services/transfer_excel_service.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'exports each movement including repeated assets and historical branches',
    () {
      final bytes = TransferExcelService.buildExcelBytes(
        records: [
          {
            'item_code': '00017',
            'from_branch': 'Dubai',
            'to_branch': 'Sharjah',
            'created_at': DateTime(2026, 10, 16, 10, 30).toIso8601String(),
            'description': 'Move to service desk',
            'user_name': 'Operator',
          },
          {
            'item_code': '00017',
            'from_branch': 'Sharjah',
            'to_branch': 'Ajman',
          },
          {
            'item_code': 'deleted-asset',
            'from_branch': 'أبوظبي',
            'to_branch': 'دبي',
            'created_at': 'unknown',
          },
        ],
        assetNames: {'00017': 'Laptop'},
      );
      final workbook = Excel.decodeBytes(bytes);
      expect(workbook.sheets.keys, ['Moves']);
      final rows = workbook['Moves'].rows;
      expect(rows.length, 4);
      expect(rows.first.map((cell) => cell?.value.toString()).toList(), [
        'Asset Name',
        'Item Code',
        'From Branch',
        'To Branch',
        'Moved On',
        'Movement',
        'Performed By',
      ]);
      expect(rows[1].map((cell) => cell?.value.toString()).toList(), [
        'Laptop',
        '00017',
        'Dubai',
        'Sharjah',
        '16/10/2026 10:30',
        'Move to service desk',
        'Operator',
      ]);
      expect(rows[1][1]!.value, isA<TextCellValue>());
      expect(rows[2][0]!.value.toString(), 'Laptop');
      expect(rows[2][5]!.value.toString(), 'Transferred from Sharjah to Ajman');
      expect(rows[2][6]!.value.toString(), 'System');
      expect(rows[3][0]!.value.toString(), 'Asset');
      expect(rows[3][2]!.value.toString(), 'أبوظبي');
      expect(rows[3][4]!.value.toString(), 'unknown');
    },
  );

  test(
    'produces a valid workbook for an empty result without blank sheets',
    () {
      final workbook = Excel.decodeBytes(
        TransferExcelService.buildExcelBytes(records: [], assetNames: {}),
      );
      expect(workbook.sheets.keys, ['Moves']);
      expect(workbook['Moves'].rows.length, 1);
    },
  );
}
