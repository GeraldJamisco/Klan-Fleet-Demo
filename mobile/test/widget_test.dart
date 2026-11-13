import 'package:flutter_test/flutter_test.dart';
import 'package:klan_fleet_mobile/core/session.dart';
import 'package:klan_fleet_mobile/main.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows the login screen when nobody is signed in', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SessionController()..load(),
        child: const KlanFleetApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Klan Fleet'), findsWidgets);
    expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);
    expect(find.text('Server address'), findsWidgets);
  });
}
