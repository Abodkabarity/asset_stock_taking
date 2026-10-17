// Renders actual status widgets with sample configuration, without user data.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:asset_stock_taking/core/constants/app_colors.dart';
import 'package:asset_stock_taking/data/models/asset_status_option.dart';
import 'package:asset_stock_taking/presentation/web/data/web_asset_repository.dart';
import 'package:asset_stock_taking/presentation/web/pages/setup/web_status_setup_page.dart';
import 'package:asset_stock_taking/presentation/widgets/asset_status_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late SupabaseClient client;
  setUp(() {
    final rows = AssetStatusOption.defaults
        .map(
          (option) => {
            'value': option.value,
            'label': option.label,
            'kind': 'condition',
            'is_active': true,
            'sort_order': option.sortOrder,
          },
        )
        .toList();
    client = SupabaseClient(
      'https://test.supabase.co',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient(
        (request) async => http.Response(
          jsonEncode(rows),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        ),
      ),
    );
  });
  tearDown(() => client.dispose());
  testWidgets('capture status setup and configured dropdown', (tester) async {
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
    tester.view.physicalSize = const Size(1120, 1150);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    Widget frame(Widget body) => RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'PreviewFont',
          scaffoldBackgroundColor: AppColors.bg,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: body,
          ),
        ),
      ),
    );
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1.25);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/status_catalog/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await tester.pumpWidget(
      frame(
        WebStatusSetupPage(repository: WebAssetRepository(supabase: client)),
      ),
    );
    await capture('setup_statuses');
    tester.view.physicalSize = const Size(900, 740);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Edit Assigned'));
    await tester.tap(find.byTooltip('Edit Assigned'));
    await tester.pumpAndSettle();
    expect(find.text('Type'), findsNothing);
    expect(find.text('Operation'), findsNothing);
    await capture('status_edit_dialog');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(900, 740);
    await tester.pumpWidget(
      frame(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Asset',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose an asset status',
              style: TextStyle(color: AppColors.subText),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: AssetStatusSelector(
                value: 'New',
                options: AssetStatusOption.defaults,
                onChanged: (_) {},
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await capture('status_dropdown');
  });
}
