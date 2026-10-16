// Run: flutter test tool/capture_branch_dropdown.dart
// Captures the real widget with sample branches into build/branch_dropdown/.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:asset_stock_taking/core/constants/app_colors.dart';
import 'package:asset_stock_taking/presentation/widgets/branch_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('capture branch dropdown preview', (tester) async {
    debugDisableShadows = false;
    // Use an installed font so text is readable outside a golden-test runner.
    const fontPath = String.fromEnvironment(
      'PREVIEW_FONT',
      defaultValue: 'C:/Windows/Fonts/segoeui.ttf',
    );
    final font = FontLoader('PreviewFont')
      ..addFont(
        Future.value(ByteData.sublistView(File(fontPath).readAsBytesSync())),
      );
    await font.load();
    final iconFont = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await iconFont.load();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(860, 820);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundaryKey = GlobalKey();
    const branches = [
      'Abu Dhabi - Al Khalidiyah',
      'Abu Dhabi - Al Reem Island',
      'Ajman - Al Nuaimiya',
      'Dubai - Al Barsha',
      'Dubai - Business Bay',
      'Dubai - Downtown',
      'Dubai - Jumeirah',
      'Dubai - Marina',
      'Fujairah - City Centre',
      'Ras Al Khaimah - Al Nakheel',
      'Sharjah - Al Majaz',
      'Sharjah - Al Nahda',
    ];
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'PreviewFont',
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryColor,
            ),
            scaffoldBackgroundColor: AppColors.bg,
          ),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 100,
                vertical: 42,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.primaryColor,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'ASSET STOCK TAKING',
                        style: TextStyle(
                          color: AppColors.secondaryColor,
                          fontSize: 12,
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  const Text(
                    'Find your branch',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Search your locations and select a branch to continue.',
                    style: TextStyle(fontSize: 14, color: AppColors.subText),
                  ),
                  const SizedBox(height: 26),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: BranchDropdown(
                      branches: branches,
                      value: 'Dubai - Al Barsha',
                      includeAllBranches: true,
                      onChanged: (_) {},
                      decoration: InputDecoration(
                        labelText: 'Branch',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Component preview · Sample branch names',
                    style: TextStyle(color: AppColors.subText, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(BranchDropdown));
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final rendered = await boundary.toImage(pixelRatio: 1.5);
        final data = await rendered.toByteData(format: ui.ImageByteFormat.png);
        final output = File('build/branch_dropdown/$name.png');
        await output.parent.create(recursive: true);
        await output.writeAsBytes(data!.buffer.asUint8List());
        rendered.dispose();
      });
    }

    await capture('branch_dropdown_open');
    await tester.enterText(find.byType(TextField), 'Dubai');
    await tester.pumpAndSettle();
    expect(find.text('5 of 12 branches'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capture('branch_dropdown_search');
    debugDisableShadows = true;
  });
}
