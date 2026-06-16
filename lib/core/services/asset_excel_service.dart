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
      TextCellValue('warranty_image_url'),
      TextCellValue('cost'),
      TextCellValue('created_at'),
      TextCellValue('project_name'),
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
        FormulaCellValue(
          'HYPERLINK("${item.warrantyImagePath ?? ''}", "Open Warranty")',
        ),
        TextCellValue(item.cost.toString()),
        TextCellValue(item.createdAt.toString()),
        TextCellValue(item.projectName),
        FormulaCellValue('HYPERLINK("${item.imagePath ?? ''}", "Open Image")'),
      ]);
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
  }) async {
    try {
      /// BUILD EXCEL
      final bytes = await buildExcelBytes(assets: assets);

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
