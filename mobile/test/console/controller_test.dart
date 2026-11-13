import 'package:flutter_test/flutter_test.dart';
import 'package:klan_fleet_mobile/console/core/access.dart';
import 'package:klan_fleet_mobile/console/data/demo_repository.dart';
import 'package:klan_fleet_mobile/console/state/console_controller.dart';

ConsoleController _make({ConsoleRole role = ConsoleRole.manager}) => ConsoleController(
      actualRole: role,
      userName: 'Gerald Jamisco',
      demoRepository: DemoConsoleRepository(latency: Duration.zero),
      liveRepository: DemoConsoleRepository(latency: Duration.zero),
    );

void main() {
  test('starts on the overview with the demo data source', () {
    final c = _make();
    expect(c.module, ConsoleModule.overview);
    expect(c.source, DataSource.demo);
    expect(c.isPreviewing, isFalse);
  });

  test('go ignores modules the role cannot open', () {
    final c = _make(role: ConsoleRole.warehouse);
    c.go(ConsoleModule.settings);
    expect(c.module, ConsoleModule.overview);
    c.go(ConsoleModule.warehouse);
    expect(c.module, ConsoleModule.warehouse);
  });

  test('only managers can preview another role', () {
    final dispatcher = _make(role: ConsoleRole.dispatcher);
    dispatcher.previewAs(ConsoleRole.manager);
    expect(dispatcher.role, ConsoleRole.dispatcher);

    final manager = _make();
    manager.previewAs(ConsoleRole.finance);
    expect(manager.role, ConsoleRole.finance);
    expect(manager.isPreviewing, isTrue);
    manager.previewAs(null);
    expect(manager.role, ConsoleRole.manager);
    expect(manager.isPreviewing, isFalse);
  });

  test('previewing a role that cannot see the open page returns to overview', () {
    final c = _make();
    c.go(ConsoleModule.settings);
    c.previewAs(ConsoleRole.dispatcher);
    expect(c.module, ConsoleModule.overview);
  });

  test('openTrip and closeTrip', () {
    final c = _make();
    c.openTrip('TRP-2601');
    expect(c.module, ConsoleModule.trips);
    expect(c.openTripRef, 'TRP-2601');
    c.closeTrip();
    expect(c.openTripRef, isNull);
    expect(c.module, ConsoleModule.trips);
  });

  test('searchTrips jumps to the trip list with the query', () {
    final c = _make();
    c.searchTrips('  gulu ');
    expect(c.module, ConsoleModule.trips);
    expect(c.tripQuery, 'gulu');
  });

  test('changing the data source reloads every screen', () {
    final c = _make();
    final tick = c.refreshTick;
    c.setSource(DataSource.live);
    expect(c.source, DataSource.live);
    expect(c.refreshTick, tick + 1);
    c.setSource(DataSource.live);
    expect(c.refreshTick, tick + 1);
  });
}
