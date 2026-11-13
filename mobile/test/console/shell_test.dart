import 'package:flutter_test/flutter_test.dart';
import 'package:klan_fleet_mobile/console/core/access.dart';
import 'package:klan_fleet_mobile/console/data/demo_repository.dart';
import 'package:klan_fleet_mobile/console/shell/console_shell.dart';
import 'package:klan_fleet_mobile/console/state/console_controller.dart';
import 'package:klan_fleet_mobile/console/state/theme_controller.dart';
import 'package:klan_fleet_mobile/console/theme/console_theme.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

Future<ConsoleController> _pump(WidgetTester tester, {required Size size}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final controller = ConsoleController(
    actualRole: ConsoleRole.manager,
    userName: 'Gerald Jamisco',
    demoRepository: DemoConsoleRepository(latency: Duration.zero),
    liveRepository: DemoConsoleRepository(latency: Duration.zero),
  );
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ConsoleController>.value(value: controller),
        ChangeNotifierProvider<ThemeController>(create: (_) => ThemeController()),
      ],
      child: MaterialApp(
        theme: buildConsoleTheme(Brightness.light),
        home: ConsoleShell(onSignOut: () {}),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  testWidgets('wide layout shows the sidebar and the overview', (tester) async {
    await _pump(tester, size: const Size(1440, 1000));
    expect(find.text('Trips & Dispatch'), findsOneWidget);
    expect(find.text('Settings & Roles'), findsOneWidget);
    expect(find.text('Needs attention'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opening Trips shows the trip list', (tester) async {
    final controller = await _pump(tester, size: const Size(1440, 1000));
    controller.go(ConsoleModule.trips);
    await tester.pumpAndSettle();
    expect(find.textContaining('Plan, assign and monitor'), findsOneWidget);
    expect(find.text('TRP-2601'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('previewing a restricted role removes modules from the sidebar',
      (tester) async {
    final controller = await _pump(tester, size: const Size(1440, 1000));
    controller.previewAs(ConsoleRole.warehouse);
    await tester.pumpAndSettle();
    expect(find.text('Settings & Roles'), findsNothing);
    expect(find.text('ERP Sync'), findsNothing);
    expect(find.textContaining('Previewing as Warehouse officer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone layout uses the bottom navigation bar', (tester) async {
    await _pump(tester, size: const Size(390, 844));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
