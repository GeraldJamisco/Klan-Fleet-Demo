/// Serves the prototype's sample data. Created trips live in memory for the
/// session so the "New trip" flow can be demonstrated without a server.
library;

import '../core/formatters.dart';
import '../models/ops_models.dart';
import 'console_repository.dart';
import 'demo_data.dart';

class DemoConsoleRepository implements ConsoleRepository {
  DemoConsoleRepository({this.latency = const Duration(milliseconds: 350)});

  /// Small artificial delay so loading states are visible.
  final Duration latency;

  final List<OpsTrip> _trips = DemoData.trips();
  int _nextRef = 2626;

  Future<T> _after<T>(T Function() produce) =>
      Future<T>.delayed(latency, produce);

  @override
  String get sourceLabel => 'Demo data';

  @override
  Future<OverviewData> overview() => _after(DemoData.overview);

  @override
  Future<List<OpsTrip>> trips() => _after(() => List<OpsTrip>.of(_trips));

  @override
  Future<TripDetailData> tripDetail(String ref) => _after(() {
        final trip = _trips.firstWhere(
          (t) => t.ref == ref,
          orElse: () => throw StateError('Trip $ref was not found.'),
        );
        return DemoData.tripDetail(trip);
      });

  @override
  Future<FleetData> fleet() => _after(DemoData.fleet);

  @override
  Future<DriversData> drivers() => _after(() => DemoData.driversData(_trips));

  @override
  Future<FuelData> fuel() => _after(DemoData.fuel);

  @override
  Future<IncidentsData> incidents() => _after(DemoData.incidents);

  @override
  Future<WarehouseData> warehouse() => _after(DemoData.warehouse);

  @override
  Future<ReportsData> reports() =>
      _after(() => DemoData.reports(DemoData.vehicles()));

  @override
  Future<ErpData> erp() => _after(DemoData.erp);

  @override
  Future<NewTripOptions> newTripOptions() => _after(DemoData.newTripOptions);

  @override
  Future<OpsTrip> createTrip(NewTripRequest request) => _after(() {
        final trip = OpsTrip(
          ref: 'TRP-${_nextRef++}',
          client: request.client,
          origin: request.origin,
          destination: request.destination,
          cargo: request.cargoLabel,
          driverName: request.driver.label.split(' · ').first,
          vehiclePlate: request.vehicle.label.split(' · ').first,
          status: TripStatus.assigned,
          eta: dayAndTime(request.departure),
        );
        _trips.insert(0, trip);
        return trip;
      });
}
