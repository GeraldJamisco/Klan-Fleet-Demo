import 'package:flutter_test/flutter_test.dart';
import 'package:klan_fleet_mobile/console/core/access.dart';
import 'package:klan_fleet_mobile/console/models/ops_models.dart';

void main() {
  test('OpsTrip round-trips through JSON', () {
    const trip = OpsTrip(
      ref: 'TRP-1',
      client: 'Eastline FMCG',
      origin: 'Kampala',
      destination: 'Gulu',
      cargo: 'FMCG · 18T',
      driverName: 'David Mugisha',
      vehiclePlate: 'UBF 663M',
      status: TripStatus.delayed,
      eta: 'Today, 17:40',
      apiId: 7,
    );
    final copy = OpsTrip.fromJson(trip.toJson());
    expect(copy.ref, 'TRP-1');
    expect(copy.status, TripStatus.delayed);
    expect(copy.apiId, 7);
    expect(copy.route, 'Kampala → Gulu');
    expect(copy.searchText, contains('david mugisha'));
  });

  test('unknown trip status falls back to assigned', () {
    expect(TripStatus.fromApi('???'), TripStatus.assigned);
    expect(TripStatus.fromApi('in_transit'), TripStatus.inTransit);
    expect(TripStatus.fromLabel('Delivered'), TripStatus.delivered);
  });

  test('KpiStat uses a default sparkline when the API sends none', () {
    final stat = KpiStat.fromJson({'label': 'Trips', 'value': '38', 'trend': '+12%'});
    expect(stat.series, KpiStat.defaultSeries);
    expect(stat.positive, isTrue);
  });

  test('AttentionItem resolves its target module', () {
    final item = AttentionItem.fromJson({
      'title': 'Late',
      'actionLabel': 'Track',
      'target': 'trips',
    });
    expect(item.target, ConsoleModule.trips);
    final unknown = AttentionItem.fromJson({
      'title': 'x',
      'actionLabel': 'y',
      'target': 'nowhere',
    });
    expect(unknown.target, ConsoleModule.overview);
  });

  test('TripDetailData adds up revenue, expenses and margin', () {
    const trip = OpsTrip(
      ref: 'TRP-1',
      client: 'c',
      origin: 'a',
      destination: 'b',
      cargo: 'x',
      driverName: 'd',
      vehiclePlate: 'p',
      status: TripStatus.assigned,
      eta: '-',
    );
    const data = TripDetailData(
      trip: trip,
      timeline: [],
      costs: [
        CostLine(label: 'Revenue', amountUgx: 4850000, isRevenue: true),
        CostLine(label: 'Fuel', amountUgx: 1120000),
        CostLine(label: 'Tolls', amountUgx: 165000),
      ],
    );
    expect(data.revenue, 4850000);
    expect(data.expenses, 1285000);
    expect(data.margin, 3565000);
    expect(data.hasRevenue, isTrue);
  });

  test('ErpData fractions', () {
    const erp = ErpData(
      connected: true,
      lastSync: '-',
      latency: '-',
      pending: 10,
      synced: 80,
      failed: 10,
      events: [],
      mappings: [],
    );
    expect(erp.total, 100);
    expect(erp.syncedFraction, 0.8);
  });

  test('FleetVehicle round-trips through JSON', () {
    const vehicle = FleetVehicle(
      plate: 'UAX 482K',
      model: 'Isuzu Giga',
      type: 'Tractor head',
      status: VehicleStatus.moving,
      odometerKm: 482190,
      nextService: '12 Dec',
      kmPerLitre: 2.8,
      driverName: 'Sarah Nakato',
    );
    final copy = FleetVehicle.fromJson(vehicle.toJson());
    expect(copy.status, VehicleStatus.moving);
    expect(copy.odometerKm, 482190);
    expect(copy.driverName, 'Sarah Nakato');
  });
}
