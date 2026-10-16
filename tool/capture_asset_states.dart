// Run: flutter test tool/capture_asset_states.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:asset_stock_taking/core/constants/app_colors.dart';
import 'package:asset_stock_taking/data/models/asset_stock_model.dart';
import 'package:asset_stock_taking/presentation/widgets/asset_state_badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('preview separate physical condition and availability', (
    tester,
  ) async {
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
    tester.view.physicalSize = const Size(1060, 880);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    final examples = [
      ('Good', 'Available'),
      ('Damaged', 'Maintenance'),
      ('Damaged', 'Checked Out'),
      ('Damaged', 'Reserved'),
      ('Damaged', 'Disposed'),
      ('Unknown', 'Maintenance'),
    ];
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'PreviewFont',
            scaffoldBackgroundColor: AppColors.bg,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryColor,
            ),
          ),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ASSET STOCK TAKING',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Condition & Availability',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Physical condition stays independent from daily operations.',
                    style: TextStyle(color: AppColors.subText, fontSize: 14),
                  ),
                  const SizedBox(height: 26),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 18,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.blueSoft,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(18),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'ASSET',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'CONDITION / AVAILABILITY',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'PHYSICAL CONDITION',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        for (final (index, example) in examples.indexed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 13,
                            ),
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: AppColors.border),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.inventory_2_outlined,
                                        color: AppColors.primaryColor,
                                        size: 27,
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Below Sink Cabinet',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '104-002-000${index + 1}',
                                            style: const TextStyle(
                                              color: AppColors.subText,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: AssetStateBadges(
                                    asset: AssetStockModel.fromJson({
                                      'status': example.$1,
                                      'operational_status': example.$2,
                                    }),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    index == 5
                                        ? 'Inspect asset to confirm its condition.'
                                        : 'Preserved when the operation changes.',
                                    style: const TextStyle(
                                      color: AppColors.subText,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Component preview · Sample assets',
                    style: TextStyle(color: AppColors.subText, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final rendered = await boundary.toImage(pixelRatio: 1.25);
      final data = await rendered.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/asset_states/condition_and_availability.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data!.buffer.asUint8List());
      rendered.dispose();
    });
  });
}
