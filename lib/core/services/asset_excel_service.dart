import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

import '../../data/models/asset_stock_model.dart';

class AssetExcelService {
  /// =========================
  /// BUILD EXCEL
  /// =========================
  static Future<Uint8List> buildExcelBytes({
    required List<AssetStockModel> assets,
    bool includeProject = true,
  }) async {
    final excel = Excel.createExcel();

    final sheet = excel['Assets'];

    /// =========================
    /// HEADER
    /// =========================
    sheet.appendRow([
      TextCellValue('name'),
      TextCellValue('asset_code'),
      TextCellValue('item_code'),
      TextCellValue('category'),
      TextCellValue('sub_category'),
      TextCellValue('classification'),
      TextCellValue('asset_classification'),
      TextCellValue('location'),
      TextCellValue('status'),
      TextCellValue('brand'),
      TextCellValue('model'),
      TextCellValue('serial_no'),
      TextCellValue('description'),
      TextCellValue('has_warranty'),
      TextCellValue('warranty_description'),
      TextCellValue('warranty_start_date'),
      TextCellValue('warranty_end_date'),
      TextCellValue('warranty_serial_no'),
      TextCellValue('warranty_image_url'),
      TextCellValue('cost'),
      TextCellValue('created_at'),
      if (includeProject) TextCellValue('project_name'),
      TextCellValue('image_url'),
    ]);

    /// =========================
    /// DATA
    /// =========================
    for (final item in assets) {
      sheet.appendRow([
        TextCellValue(item.name),
        TextCellValue(item.assetCode),
        TextCellValue(item.itemCode),
        TextCellValue(item.category),
        TextCellValue(item.subCategory),
        TextCellValue(item.classification),
        TextCellValue(item.assetClassification),
        TextCellValue(item.location),
        TextCellValue(item.status),
        TextCellValue(item.brand),
        TextCellValue(item.model),
        TextCellValue(item.serialNo),
        TextCellValue(item.description),
        TextCellValue(item.hasWarranty.toString()),
        TextCellValue(item.warrantyDescription),
        TextCellValue(item.warrantyStartDate),
        TextCellValue(item.warrantyEndDate),
        TextCellValue(item.warrantySerialNo),
        FormulaCellValue(
          'HYPERLINK("${item.warrantyImagePath ?? ''}", "Open Warranty")',
        ),
        TextCellValue(item.cost.toString()),
        TextCellValue(item.createdAt.toString()),
        if (includeProject) TextCellValue(item.projectName),
        FormulaCellValue('HYPERLINK("${item.imagePath ?? ''}", "Open Image")'),
      ]);
    }

    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#FFFFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#FF1E4E8C'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      bottomBorder: Border(
        borderColorHex: ExcelColor.fromHexString('#FF163A69'),
        borderStyle: BorderStyle.Medium,
      ),
    );
    final bodyBorder = Border(
      borderColorHex: ExcelColor.fromHexString('#FFD9E2F0'),
      borderStyle: BorderStyle.Thin,
    );
    final columnCount = includeProject ? 23 : 22;
    for (var column = 0; column < columnCount; column++) {
      sheet.setColumnWidth(column, column == 0 || column == 12 ? 28 : 18);
      sheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 0),
              )
              .cellStyle =
          headerStyle;
    }
    for (var row = 1; row <= assets.length; row++) {
      final isAlternate = row.isEven;
      for (var column = 0; column < columnCount; column++) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row),
            )
            .cellStyle = CellStyle(
          backgroundColorHex: ExcelColor.fromHexString(
            isAlternate ? '#FFF5F9FF' : '#FFFFFFFF',
          ),
          topBorder: bodyBorder,
          bottomBorder: bodyBorder,
          leftBorder: bodyBorder,
          rightBorder: bodyBorder,
          verticalAlign: VerticalAlign.Center,
          textWrapping: TextWrapping.WrapText,
        );
      }
    }

    /// =========================
    /// REMOVE DEFAULT SHEET
    /// =========================
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    excel.setDefaultSheet('Assets');

    final bytes = excel.encode();

    if (bytes == null) {
      throw Exception('Excel Encode Failed');
    }

    return Uint8List.fromList(bytes);
  }

  /// =========================
  /// EXPORT
  /// =========================
  /// =========================
  /// EXPORT
  /// =========================
  static Future<void> exportAssets({
    required List<AssetStockModel> assets,
    required String fileName,
    bool includeProject = true,
  }) async {
    try {
      /// BUILD EXCEL
      final bytes = await buildExcelBytes(
        assets: assets,
        includeProject: includeProject,
      );

      /// PICK SAVE LOCATION
      String? outputPath = await FilePicker.saveFile(
        dialogTitle: 'Save Excel File',
        fileName: '$fileName.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: bytes,
      );

      if (outputPath == null) {
        print('USER CANCELLED');
        return;
      }

      print('================ EXPORT SUCCESS ================');
      print(outputPath);
      print('================================================');
    } catch (e, stack) {
      print('================ EXPORT ERROR ================');
      print(e);
      print(stack);
      print('==============================================');
    }
  }
}
