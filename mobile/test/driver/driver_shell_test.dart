import 'package:flutter_test/flutter_test.dart';
import 'package:klan_fleet_mobile/console/state/theme_controller.dart';
import 'package:klan_fleet_mobile/console/theme/console_theme.dart';
import 'package:klan_fleet_mobile/driver/data/demo_driver_repository.dart';
import 'package:klan_fleet_mobile/driver/shell/driver_shell.dart';
import 'package:klan_fleet_mobile/driver/state/driver_controller.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

Future<DriverController> _pump(WidgetTester tester, {required Size size}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final controller = DriverController(
    userName: 'Alex Mugisha',
    demoRepository: DemoDriverRepository(latency: Duration.zero),
    liveRepository: DemoDriverRepository(latency: Duration.zero),
  );
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<DriverController>.value(value: controller),
        ChangeNotifierProvider<ThemeController>(create: (_) => ThemeController()),
      ],
      child: MaterialApp(
        theme: buildConsoleTheme(Brightness.light),
        home: DriverShell(onSignOut: () {}),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  testWidgets('home shows the greeting and the active trip', (tester) async {
    await _pump(tester, size: const Size(1280, 1000));
    expect(find.textContaining('Alex'), findsWidgets);
    expect(find.text('TRP-2026-0148'), findsWidgets);
    expect(find.text('Quick actions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every page renders without errors', (tester) async {
    final controller = await _pump(tester, size: const Size(1280, 1000));
    for (final page in DriverPage.values) {
      controller.go(page);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: page.name);
    }
  });

  testWidgets('the fuel form saves an entry', (tester) async {
    final controller = await _pump(tester, size: const Size(1280, 1000));
    controller.go(DriverPage.costs);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Log fuel').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Fuel station'), 'Total Malaba');
    await tester.enterText(find.widgetWithText(TextField, 'Litres'), '100');
    await tester.enterText(find.widgetWithText(TextField, 'Total amount (UGX)'), '480000');
    await tester.tap(find.text('Submit update'));
    await tester.pumpAndSettle();

    expect(find.text('Total Malaba'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone layout uses a five-tab bottom bar', (tester) async {
    await _pump(tester, size: const Size(390, 844));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Profile'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
