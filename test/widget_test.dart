import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rivnet/main.dart';

void main() {
  testWidgets('Home offline dapat membuat turnamen lokal', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('RivNet'), findsOneWidget);

    await tester.tap(find.text('Buat Turnamen').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Turnamen Kampus');
    await tester.enterText(find.byType(TextFormField).at(1), 'Mobile Legends');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Turnamen Kampus'), findsOneWidget);
    expect(find.textContaining('Mobile Legends'), findsOneWidget);
  });

  testWidgets('Daftar turnamen menyesuaikan lebar layar', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Buat Turnamen').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Responsive Cup');
    await tester.enterText(find.byType(TextFormField).at(1), 'Game');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.byType(ListView), findsOneWidget);

    tester.view.physicalSize = const Size(800, 900);
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);

    tester.view.physicalSize = const Size(1100, 900);
    await tester.pumpAndSettle();
    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 3);
  });
}
