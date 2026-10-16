import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

/// Exports movement records, including repeated moves of the same asset.
class TransferExcelService {
  static Uint8List buildExcelBytes({
    required List<Map<String, dynamic>> records,
    required Map<String, String> assetNames,
  }) {
    final excel = Excel.createExcel();
    final sheet = excel['Moves'];
    const headers = [
      'Asset Name',
      'Item Code',
      'From Branch',
      'To Branch',
      'Moved On',
      'Movement',
      'Performed By',
    ];
    sheet.appendRow(headers.map(TextCellValue.new).toList());
    for (final record in records) {
      String value(String key) => record[key]?.toString().trim() ?? '';
      final code = value('item_code');
      final from = value('from_branch');
      final to = value('to_branch');
      final date = DateTime.tryParse(value('created_at'))?.toLocal();
      String two(int number) => number.toString().padLeft(2, '0');
      final dateLabel = date == null
          ? value('created_at')
          : '${two(date.day)}/${two(date.month)}/${date.year} '
                '${two(date.hour)}:${two(date.minute)}';
      final name = assetNames[code]?.trim() ?? '';
      sheet.appendRow([
        TextCellValue(name.isEmpty ? 'Asset' : name),
        TextCellValue(code),
        TextCellValue(from),
        TextCellValue(to),
        TextCellValue(dateLabel),
        TextCellValue(
          value('description').isEmpty
              ? 'Transferred from $from to $to'
              : value('description'),
        ),
        TextCellValue(
          value('user_name').isEmpty ? 'System' : value('user_name'),
        ),
      ]);
    }
    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.fromHexString('#FF1E4E8C'),
      textWrapping: TextWrapping.WrapText,
      verticalAlign: VerticalAlign.Center,
    );
    for (var column = 0; column < headers.length; column++) {
      sheet.setColumnWidth(column, column == 5 ? 48 : 26);
      sheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 0),
              )
              .cellStyle =
          headerStyle;
    }
    for (var row = 1; row <= records.length; row++) {
      final style = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString(
          row.isEven ? '#FFF5F9FF' : '#FFFFFFFF',
        ),
        verticalAlign: VerticalAlign.Center,
        textWrapping: TextWrapping.WrapText,
      );
      for (var column = 0; column < headers.length; column++) {
        sheet
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: column,
                    rowIndex: row,
                  ),
                )
                .cellStyle =
            style;
      }
    }
    excel.delete('Sheet1');
    excel.setDefaultSheet('Moves');
    final bytes = excel.encode();
    if (bytes == null) throw StateError('Unable to create movement export');
    return Uint8List.fromList(bytes);
  }

  static Future<void> exportTransfers({
    required List<Map<String, dynamic>> records,
    required Map<String, String> assetNames,
    required String fileName,
  }) async {
    final bytes = buildExcelBytes(records: records, assetNames: assetNames);
    final safeName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    await FilePicker.saveFile(
      dialogTitle: 'Save Excel File',
      fileName: '$safeName.xlsx',
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      bytes: bytes,
    );
  }
}
