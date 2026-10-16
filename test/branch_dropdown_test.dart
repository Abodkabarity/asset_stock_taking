import 'package:asset_stock_taking/presentation/widgets/branch_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('reflects parent value changes and refreshed branch data', (
    tester,
  ) async {
    String? selected = 'Dubai';
    var branches = ['Dubai', 'Sharjah'];
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 300,
                  child: BranchDropdown(
                    branches: branches,
                    value: selected,
                    includeAllBranches: true,
                    onChanged: (value) => setState(() => selected = value),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byType(BranchDropdown));
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(find.text('Sharjah')));
    await tester.pumpAndSettle();
    expect(selected, 'Sharjah');
    expect(find.text('Sharjah'), findsOneWidget);
    update(() {
      selected = null;
      branches = ['Ajman'];
    });
    await tester.pumpAndSettle();
    expect(find.text('All Branches'), findsOneWidget);
    await tester.tap(find.byType(BranchDropdown));
    await tester.pumpAndSettle();
    expect(find.text('Ajman'), findsOneWidget);
    expect(find.text('Sharjah'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  Future<void> mount(
    WidgetTester tester, {
    List<String> branches = const ['Dubai Marina', 'Abu Dhabi', 'Dubai Mall'],
    String? value,
    bool includeAll = false,
    String? allValue,
    ValueChanged<String?>? onChanged,
    TextDirection direction = TextDirection.ltr,
    double width = 1000,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: direction,
          child: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: 320,
                  child: BranchDropdown(
                    branches: branches,
                    value: value,
                    includeAllBranches: includeAll,
                    allBranchesValue: allValue,
                    onChanged: onChanged ?? (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(BranchDropdown));
    await tester.pumpAndSettle();
  }

  testWidgets('searches immediately, trims query and matches all words', (
    tester,
  ) async {
    String? result;
    await mount(tester, onChanged: (value) => result = value);
    await tester.enterText(find.byType(TextField), '  MALL dubai  ');
    await tester.pumpAndSettle();
    expect(find.text('Dubai Mall'), findsOneWidget);
    expect(find.text('Dubai Marina'), findsNothing);
    expect(find.text('Abu Dhabi'), findsNothing);
    expect(find.text('1 of 3 branches'), findsOneWidget);
    await tester.tapAt(tester.getCenter(find.text('Dubai Mall')));
    await tester.pumpAndSettle();
    expect(result, 'Dubai Mall');
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('empty results can be cleared and query resets on reopen', (
    tester,
  ) async {
    await mount(tester);
    await tester.enterText(find.byType(TextField), 'missing branch');
    await tester.pumpAndSettle();
    expect(find.text('No branches found'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('3 of 3 branches'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Marina');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BranchDropdown));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(find.text('3 of 3 branches'), findsOneWidget);
  });

  testWidgets('all branches returns null to clear the filter', (tester) async {
    String? result = 'Dubai Mall';
    await mount(
      tester,
      value: result,
      includeAll: true,
      onChanged: (value) => result = value,
    );
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    await tester.tapAt(tester.getCenter(find.text('All Branches')));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('header all-branches sentinel retains its existing value', (
    tester,
  ) async {
    String? result;
    await mount(
      tester,
      includeAll: true,
      allValue: '__all__',
      onChanged: (value) => result = value,
    );
    await tester.tapAt(tester.getCenter(find.text('All Branches')));
    await tester.pumpAndSettle();
    expect(result, '__all__');
  });

  testWidgets('Arabic search ignores diacritics and alef variants in RTL', (
    tester,
  ) async {
    await mount(
      tester,
      direction: TextDirection.rtl,
      branches: const ['أبوظبي', 'دُبَي', 'الشارقة'],
    );
    expect(find.text('اختر الفرع'), findsWidgets);
    await tester.enterText(find.byType(TextField), 'ابوظبي');
    await tester.pumpAndSettle();
    expect(find.text('أبوظبي'), findsOneWidget);
    expect(find.text('دُبَي'), findsNothing);
    expect(find.text('1 من 3 فرع'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'دبي');
    await tester.pumpAndSettle();
    expect(find.text('دُبَي'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile sheet fits with keyboard and long branch names', (
    tester,
  ) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(tester.view.resetViewInsets);
    await mount(
      tester,
      width: 390,
      branches: const [
        'Dubai branch with a very long location name that wraps across multiple lines',
        'Sharjah',
      ],
    );
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Dubai');
    await tester.pumpAndSettle();
    expect(find.text('1 of 2 branches'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large lists are searchable and duplicate branches are removed', (
    tester,
  ) async {
    await mount(
      tester,
      branches: [
        ...List.generate(2000, (i) => 'Branch ${i.toString().padLeft(4, '0')}'),
        'Branch 1999',
        '  ',
      ],
    );
    await tester.enterText(find.byType(TextField), '1999');
    await tester.pumpAndSettle();
    expect(find.text('Branch 1999'), findsOneWidget);
    expect(find.text('1 of 2000 branches'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
