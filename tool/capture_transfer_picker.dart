// Run: flutter test tool/capture_transfer_picker.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:asset_stock_taking/core/constants/app_colors.dart';
import 'package:asset_stock_taking/data/models/asset_stock_model.dart';
import 'package:asset_stock_taking/presentation/web/widgets/transfer/transfer_asset_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('capture transfer methods', (tester) async {
    const fontPath = String.fromEnvironment(
      'PREVIEW_FONT',
      defaultValue: 'C:/Windows/Fonts/segoeui.ttf',
    );
    await (FontLoader('PreviewFont')..addFont(
          Future.value(ByteData.sublistView(File(fontPath).readAsBytesSync())),
        ))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    final assets = <AssetStockModel>[];
    for (final (index, name) in [
      'Below Sink Cabinet',
      'Branding Signage',
      'Control Medicine Cabinet',
      'Cube Storage Cabinet',
      'Display Shelving',
      'Office Chair',
    ].indexed) {
      final code = index == 0 ? '104-002' : '104-00${index + 2}';
      for (var number = 1; number <= (index == 0 ? 15 : index + 1); number++) {
        assets.add(
          AssetStockModel.fromJson({
            'name': name,
            'asset_code': code,
            'item_code': '$code-${number.toString().padLeft(4, '0')}',
            'location': 'Assets Store',
            'serial_no': 'CAB-${number.toString().padLeft(4, '0')}',
          }),
        );
      }
    }
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'PreviewFont',
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryColor,
            ),
            scaffoldBackgroundColor: AppColors.bg,
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Move Assets',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'Preview with sample assets',
                      style: TextStyle(color: AppColors.subText),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => showDialog<TransferMoveRequest>(
                        context: context,
                        builder: (_) => TransferAssetPickerDialog(
                          assets: assets,
                          locations: const [
                            'Assets Store',
                            'Adnoc 999 Branch',
                            'Dubai Marina',
                          ],
                          initialLocation: 'Assets Store',
                        ),
                      ),
                      child: const Text('Select assets'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Select assets'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('product-asset:104-002')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('transfer-quantity')),
      '3',
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      debugDisableShadows = false;
      await tester.pump();
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final rendered = await boundary.toImage(pixelRatio: 1.25);
        final data = await rendered.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/transfer_picker/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data!.buffer.asUint8List());
        rendered.dispose();
      });
      debugDisableShadows = true;
    }

    await capture('by_quantity');
    await tester.tap(find.text('Specific codes'));
    await tester.pumpAndSettle();
    final search = find.byKey(const ValueKey('item-code-search'));
    for (final code in ['0002', '0004']) {
      await tester.enterText(search, code);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('item-code-104-002-$code')));
      await tester.pumpAndSettle();
    }
    await tester.enterText(search, '');
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capture('specific_codes');
  });
}
