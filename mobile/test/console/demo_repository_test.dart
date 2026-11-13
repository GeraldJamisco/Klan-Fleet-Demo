import 'package:flutter_test/flutter_test.dart';
import 'package:klan_fleet_mobile/console/data/console_repository.dart';
import 'package:klan_fleet_mobile/console/data/demo_repository.dart';
import 'package:klan_fleet_mobile/console/models/ops_models.dart';

void main() {
  final repo = DemoConsoleRepository(latency: Duration.zero);

  test('every screen has demo data', () async {
    expect((await repo.overview()).kpis, isNotEmpty);
    expect((await repo.trips()), isNotEmpty);
    expect((await repo.fleet()).vehicles, isNotEmpty);
    expect((await repo.drivers()).drivers, isNotEmpty);
    expect((await repo.fuel()).routeSpend, isNotEmpty);
    expect((await repo.incidents()).incidents, isNotEmpty);
    expect((await repo.warehouse()).queue, isNotEmpty);
    expect((await repo.reports()).reports, isNotEmpty);
    expect((await repo.erp()).events, isNotEmpty);
  });

  test('trip detail exists for every demo trip', () async {
    for (final trip in await repo.trips()) {
      final detail = await repo.tripDetail(trip.ref);
      expect(detail.trip.ref, trip.ref);
    }
  });

  test('unknown trip throws a readable error', () async {
    expect(repo.tripDetail('TRP-0000'), throwsStateError);
  });

  test('createTrip puts the new trip first with status assigned', () async {
    final fresh = DemoConsoleRepository(latency: Duration.zero);
    final before = (await fresh.trips()).length;
    final options = await fresh.newTripOptions();
    final created = await fresh.createTrip(
      NewTripRequest(
        client: options.clients.first,
        cargoType: options.cargoTypes.first,
        origin: 'Kampala',
        destination: 'Mombasa',
        driver: options.drivers.first,
        vehicle: options.vehicles.first,
        departure: DateTime(2026, 11, 13, 7),
        weightTonnes: 18.5,
      ),
    );
    final after = await fresh.trips();
    expect(after.length, before + 1);
    expect(after.first.ref, created.ref);
    expect(created.status, TripStatus.assigned);
    expect(created.cargo, endsWith('18.5T'));
  });

  test('cargoLabel drops the weight when none was given', () {
    final request = NewTripRequest(
      client: 'c',
      cargoType: 'Cement',
      origin: 'a',
      destination: 'b',
      driver: const PickOption(id: '1', label: 'd'),
      vehicle: const PickOption(id: '2', label: 'v'),
      departure: DateTime(2026, 11, 13, 7),
    );
    expect(request.cargoLabel, 'Cement');
  });
}
