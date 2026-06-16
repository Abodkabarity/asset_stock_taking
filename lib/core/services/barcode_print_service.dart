import 'dart:typed_data';

import 'package:barcode/barcode.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../utils/asset_classification_utils.dart';
import '../../data/models/asset_stock_model.dart';

class BarcodePrintService {
  static Future<Uint8List> generateBarcodePdf({
    required List<AssetStockModel> assets,
  }) async {
    final pdf = pw.Document();
    final barcode = Barcode.code128();
    final printableAssets = assets.where((asset) {
      return AssetClassificationUtils.canPrintBarcode(
        asset.assetClassification,
      );
    }).toList();

    if (printableAssets.isEmpty) {
      throw ArgumentError('No printable assets found.');
    }

    const double width = 5.0 * PdfPageFormat.cm;
    const double height = 2.5 * PdfPageFormat.cm;

    final customFormat = PdfPageFormat(width, height, marginAll: 0);

    for (final asset in printableAssets) {
      final svg = barcode.toSvg(asset.itemCode, drawText: false);

      pdf.addPage(
        pw.Page(
          pageFormat: customFormat,
          margin: pw.EdgeInsets.zero,
          build: (context) {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Center(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.SizedBox(
                      width: 4.0 * PdfPageFormat.cm,
                      height: 0.8 * PdfPageFormat.cm,
                      child: pw.SvgImage(svg: svg, fit: pw.BoxFit.fill),
                    ),

                    pw.SizedBox(height: 2),

                    pw.Text(
                      asset.name,
                      maxLines: 1,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),

                    pw.Text(
                      asset.itemCode,
                      style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return pdf.save();
  }
}
