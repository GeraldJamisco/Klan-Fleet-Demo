import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'console/console_entry.dart';
import 'console/state/theme_controller.dart';
import 'console/theme/console_theme.dart';
import 'core/session.dart';
import 'driver/driver_entry.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => SessionController()..load(),
      child: const KlanFleetApp(),
    ),
  );
}

class KlanFleetApp extends StatelessWidget {
  const KlanFleetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeController>(
      create: (_) => ThemeController(),
      child: Builder(
        builder: (context) {
          final dark = context.watch<ThemeController>().dark;
          return MaterialApp(
            title: 'Klan Fleet (demo)',
            debugShowCheckedModeBanner: false,
            theme: buildConsoleTheme(Brightness.light),
            darkTheme: buildConsoleTheme(Brightness.dark),
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            home: const _Root(),
          );
        },
      ),
    );
  }
}

/// Chooses the screen from the session: login, driver app or manager console.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    if (!session.ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!session.loggedIn) return const LoginScreen();
    return session.user!.isManager ? const ConsoleEntry() : const DriverEntry();
  }
}
