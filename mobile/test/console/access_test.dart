import 'package:flutter_test/flutter_test.dart';
import 'package:klan_fleet_mobile/console/core/access.dart';

void main() {
  test('manager can open every module with full access', () {
    for (final module in ConsoleModule.values) {
      expect(AccessMatrix.levelFor(ConsoleRole.manager, module), AccessLevel.full);
    }
  });

  test('settings and ERP are closed to drivers and warehouse officers', () {
    for (final role in [ConsoleRole.driver, ConsoleRole.warehouse]) {
      expect(AccessMatrix.levelFor(role, ConsoleModule.settings).hasAccess, isFalse);
      expect(AccessMatrix.levelFor(role, ConsoleModule.erp).hasAccess, isFalse);
    }
  });

  test('finance sees fuel in full but trips read-only', () {
    expect(AccessMatrix.levelFor(ConsoleRole.finance, ConsoleModule.fuel).canManage, isTrue);
    expect(AccessMatrix.levelFor(ConsoleRole.finance, ConsoleModule.trips), AccessLevel.view);
    expect(AccessMatrix.levelFor(ConsoleRole.finance, ConsoleModule.trips).canManage, isFalse);
  });

  test('modulesFor keeps navigation order and drops closed modules', () {
    final modules = AccessMatrix.modulesFor(ConsoleRole.warehouse);
    expect(modules, [
      ConsoleModule.overview,
      ConsoleModule.trips,
      ConsoleModule.incidents,
      ConsoleModule.warehouse,
      ConsoleModule.reports,
    ]);
  });

  test('every role can open the overview', () {
    for (final role in ConsoleRole.values) {
      expect(AccessMatrix.levelFor(role, ConsoleModule.overview).hasAccess, isTrue);
    }
  });

  test('phone navigation only lists modules the role can open', () {
    for (final role in ConsoleRole.values) {
      final allowed = AccessMatrix.modulesFor(role).toSet();
      expect(AccessMatrix.phoneModulesFor(role).toSet(), allowed);
    }
  });

  test('unknown API roles fall back to the most restricted role', () {
    expect(ConsoleRole.fromApi('manager'), ConsoleRole.manager);
    expect(ConsoleRole.fromApi('astronaut'), ConsoleRole.driver);
    expect(ConsoleRole.fromApi(null), ConsoleRole.driver);
  });
}
