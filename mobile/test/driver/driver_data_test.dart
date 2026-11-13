import 'package:flutter_test/flutter_test.dart';
import 'package:klan_fleet_mobile/console/models/ops_models.dart';
import 'package:klan_fleet_mobile/driver/data/demo_driver_repository.dart';
import 'package:klan_fleet_mobile/driver/data/driver_repository.dart';
import 'package:klan_fleet_mobile/driver/models/driver_models.dart';
import 'package:klan_fleet_mobile/driver/state/driver_controller.dart';

DemoDriverRepository _repo() => DemoDriverRepository(latency: Duration.zero);

void main() {
  test('driver id label pads the API id', () {
    expect(DriverProfile.idLabel(4), 'DRV-004');
    expect(DriverProfile.idLabel(123), 'DRV-123');
  });

  test('DriverTrip round-trips through JSON', () {
    const trip = DriverTrip(
      ref: 'TRP-1',
      origin: 'Kampala',
      destination: 'Mombasa',
      cargo: 'Cement',
      status: TripStatus.inTransit,
      vehiclePlate: 'UAZ 739R',
      apiId: 9,
    );
    final copy = DriverTrip.fromJson(trip.toJson());
    expect(copy.ref, 'TRP-1');
    expect(copy.status, TripStatus.inTransit);
    expect(copy.apiId, 9);
    expect(copy.route, 'Kampala → Mombasa');
    expect(copy.isClosed, isFalse);
    expect(copy.copyWith(status: TripStatus.delivered).isClosed, isTrue);
  });

  test('progress grows with the trip status', () {
    DriverTrip at(TripStatus s) => DriverTrip(
          ref: 'r',
          origin: 'a',
          destination: 'b',
          cargo: 'c',
          status: s,
          vehiclePlate: 'p',
        );
    expect(at(TripStatus.assigned).progress, lessThan(at(TripStatus.pickedUp).progress));
    expect(at(TripStatus.pickedUp).progress, lessThan(at(TripStatus.inTransit).progress));
    expect(at(TripStatus.delivered).progress, 1);
  });

  test('demo snapshot has an active trip and sample content', () async {
    final snapshot = await _repo().load();
    expect(snapshot.activeTrip, isNotNull);
    expect(snapshot.history.first.ref, snapshot.activeTrip!.ref);
    expect(snapshot.unreadMessages, 2);
    expect(snapshot.readyDocuments, 2);
    expect(snapshot.summary.fuelLitres, 341);
    expect(snapshot.summary.fuelCostUgx, 1620000);
  });

  test('logging fuel adds an entry and updates the totals', () async {
    final repo = _repo();
    final trip = (await repo.load()).activeTrip!;
    await repo.logFuel(trip, const FuelRequest(station: 'Total Malaba', litres: 100, amountUgx: 480000));
    final snapshot = await repo.load();
    expect(snapshot.fuel.first.station, 'Total Malaba');
    expect(snapshot.summary.fuelLitres, 441);
    expect(snapshot.summary.fuelCostUgx, 2100000);
  });

  test('marking the trip delivered closes it', () async {
    final repo = _repo();
    final trip = (await repo.load()).activeTrip!;
    final delivered = repo.statusChoices(trip).firstWhere((c) => c.target == TripStatus.delivered);
    await repo.updateStatus(trip, StatusUpdate(choice: delivered));
    final snapshot = await repo.load();
    expect(snapshot.activeTrip, isNull);
    expect(snapshot.history.first.status, TripStatus.delivered);
  });

  test('proof of delivery also closes the trip', () async {
    final repo = _repo();
    final trip = (await repo.load()).activeTrip!;
    await repo.submitProof(
      trip,
      const DeliveryProof(receiver: 'J. Okello', confirmation: DeliveryConfirmation.full),
    );
    expect((await repo.load()).activeTrip, isNull);
  });

  test('reporting an issue adds a message', () async {
    final repo = _repo();
    final before = (await repo.load()).messages.length;
    await repo.reportIssue(
      null,
      const IssueRequest(
        category: IssueCategory.roadHazard,
        severity: IssueSeverity.medium,
        description: 'Fallen tree',
      ),
    );
    expect((await repo.load()).messages.length, before + 1);
  });

  test('request texts carry the details the API cannot store separately', () {
    const update = StatusUpdate(
      choice: StatusChoice(id: 'x', label: 'x'),
      location: ' Malaba ',
      notes: 'Queue',
    );
    expect(update.noteText, 'Location: Malaba. Queue');
    const issue = IssueRequest(
      category: IssueCategory.accident,
      severity: IssueSeverity.high,
      description: 'Minor collision',
      location: 'Jinja road',
    );
    expect(issue.noteText, '[HIGH] Location: Jinja road. Minor collision');
    expect(IssueCategory.cargoDamage.apiValue, 'cargo_damage');
    expect(IssueCategory.roadHazard.apiValue, 'other');
    const proof = DeliveryProof(
      receiver: 'J. Okello',
      confirmation: DeliveryConfirmation.partial,
      notes: '2 pallets short',
    );
    expect(proof.noteText, contains('J. Okello'));
    expect(proof.noteText, contains('2 pallets short'));
  });

  test('controller shares one snapshot until refreshed', () async {
    final controller = DriverController(
      userName: 'Alex',
      demoRepository: _repo(),
      liveRepository: _repo(),
    );
    final first = controller.snapshot;
    expect(identical(controller.snapshot, first), isTrue);
    controller.refresh();
    expect(identical(controller.snapshot, first), isFalse);
    expect(controller.refreshTick, 1);
    controller.go(DriverPage.costs);
    expect(controller.page, DriverPage.costs);
    controller.setSource(DriverSource.live);
    expect(controller.source, DriverSource.live);
    expect(controller.refreshTick, 2);
  });
}
