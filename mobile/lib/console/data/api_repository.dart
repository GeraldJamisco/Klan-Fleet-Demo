/// Live data from the Klan Fleet REST API for the parts it already serves
/// (trips, dashboard totals, ERP queue, new-trip options). Everything the API
/// does not have yet falls back to the demo data, and the screens say so.
library;

import '../../core/api_client.dart';
import '../../core/format.dart' as fmt;
import '../../core/models.dart' as api;
import '../core/formatters.dart';
import '../models/ops_models.dart';
import 'console_repository.dart';
import 'demo_data.dart';
import 'demo_repository.dart';

class ApiConsoleRepository extends DemoConsoleRepository {
  ApiConsoleRepository(this._client) : super(latency: Duration.zero);

  /// A factory, because the session builds a client with the current token.
  final ApiClient Function() _client;

  final Map<String, int> _ids = {};

  @override
  String get sourceLabel => 'Live API';

  OpsTrip _mapTrip(api.Trip t) => OpsTrip(
        apiId: t.id,
        ref: t.ref,
        client: '—',
        origin: t.origin,
        destination: t.destination,
        cargo: t.cargo,
        driverName: t.driverName,
        vehiclePlate: t.vehiclePlate,
        status: TripStatus.fromApi(t.status),
        eta: t.deliveredAt != null
            ? 'Delivered ${fmt.friendlyTime(t.deliveredAt)}'
            : 'Updated ${fmt.friendlyTime(t.updatedAt)}',
      );

  @override
  Future<List<OpsTrip>> trips() async {
    final trips = await _client().trips();
    _ids
      ..clear()
      ..addAll({for (final t in trips) t.ref: t.id});
    return [for (final t in trips) _mapTrip(t)];
  }

  @override
  Future<TripDetailData> tripDetail(String ref) async {
    var id = _ids[ref];
    if (id == null) {
      await trips();
      id = _ids[ref];
    }
    if (id == null) throw const ApiException('That trip no longer exists.');

    final detail = await _client().tripDetail(id);
    return TripDetailData(
      trip: _mapTrip(detail.trip),
      timeline: [
        for (final e in detail.events)
          TimelineEntry(
            title: fmt.humanize(e.status),
            detail: [
              fmt.friendlyTime(e.createdAt),
              if (e.note != null && e.note!.isNotEmpty) e.note!,
            ].join(' · '),
          ),
      ],
      costs: [
        for (final f in detail.fuelLogs)
          CostLine(label: 'Fuel · ${f.liters.toStringAsFixed(0)} L', amountUgx: f.costUgx),
      ],
    );
  }

  @override
  Future<OverviewData> overview() async {
    final base = await super.overview();
    final d = await _client().dashboard();
    final byStatus = d.tripsByStatus;
    final totalTrips = byStatus.values.fold<int>(0, (sum, v) => sum + v);

    return OverviewData(
      kpis: [
        KpiStat(label: 'Trips', value: '$totalTrips', trend: '${byStatus['in_transit'] ?? 0} in transit', icon: 'trips'),
        KpiStat(label: 'Delivered', value: '${byStatus['delivered'] ?? 0}', trend: 'Completed trips', icon: 'check'),
        KpiStat(label: 'Vehicles available', value: '${d.fleetAvailable} / ${d.fleetTotal}', trend: 'Ready to assign', icon: 'truck'),
        KpiStat(label: 'Fuel spend', value: ugxCompact(d.fuelCostUgx), trend: '${thousands(d.fuelLiters)} L logged', icon: 'fuel', positive: false),
        KpiStat(label: 'Incidents reported', value: '${d.incidents}', trend: 'All time', icon: 'flag', positive: false),
        KpiStat(label: 'Pending ERP syncs', value: '${d.erpPending}', trend: '${d.erpFailed} failed', icon: 'sync', positive: d.erpFailed == 0),
      ],
      fleet: base.fleet,
      attention: base.attention,
      statusCounts: [
        for (final entry in byStatus.entries)
          StatusCount(status: TripStatus.fromApi(entry.key), count: entry.value),
      ],
      deliveries: base.deliveries,
      note: 'Live: KPIs and trips by status come from the API. '
          'The map, alerts and 7-day chart are still sample data.',
    );
  }

  @override
  Future<ErpData> erp() async {
    final (counts, items) = await _client().erpStatus();
    return ErpData(
      connected: true,
      lastSync: items.isEmpty ? 'No events yet' : fmt.friendlyTime(items.first.createdAt),
      latency: '—',
      pending: counts['pending'] ?? 0,
      synced: counts['synced'] ?? 0,
      failed: counts['failed'] ?? 0,
      events: [
        for (final item in items)
          ErpEvent(
            id: 'EVT-${item.id}',
            type: item.eventType,
            reference: '—',
            created: fmt.friendlyTime(item.createdAt),
            attempts: item.attempts,
            status: ErpEventStatus.fromApi(item.status),
            message: item.lastError ??
                (item.status == 'synced' ? 'Accepted by ERP' : 'Waiting for the connector'),
          ),
      ],
      mappings: DemoData.erp().mappings,
    );
  }

  @override
  Future<NewTripOptions> newTripOptions() async {
    final client = _client();
    final drivers = await client.driverOptions();
    final vehicles = await client.vehicleOptions();
    return NewTripOptions(
      clients: DemoData.clients,
      cargoTypes: DemoData.cargoTypes,
      origins: DemoData.origins,
      destinations: DemoData.destinations,
      drivers: [for (final d in drivers) PickOption(id: '${d.id}', label: d.label)],
      vehicles: [
        for (final v in vehicles)
          if (v.available) PickOption(id: '${v.id}', label: v.label),
      ],
    );
  }

  @override
  Future<OpsTrip> createTrip(NewTripRequest request) async {
    final driverId = int.tryParse(request.driver.id);
    final vehicleId = int.tryParse(request.vehicle.id);
    if (driverId == null || vehicleId == null) {
      throw const ApiException('Pick a driver and a vehicle first.');
    }
    await _client().createTrip(
      origin: request.origin,
      destination: request.destination,
      cargo: request.cargoLabel,
      driverId: driverId,
      vehicleId: vehicleId,
    );
    return OpsTrip(
      ref: 'New trip',
      client: request.client,
      origin: request.origin,
      destination: request.destination,
      cargo: request.cargoLabel,
      driverName: request.driver.label,
      vehiclePlate: request.vehicle.label,
      status: TripStatus.assigned,
      eta: dayAndTime(request.departure),
    );
  }
}
