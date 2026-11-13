/// API-ready data models for the manager console.
///
/// Every entity has `fromJson` / `toJson` so a real endpoint can replace the
/// demo data without touching a screen. Timestamps are kept as display strings
/// here because the demo data and the current API both format them server side.
library;

import '../core/access.dart';

/// Semantic colour of a chip, bar or icon. The theme decides the actual colours.
enum Tone { green, blue, amber, red, gray }

// ---------------------------------------------------------------- trips

enum TripStatus {
  assigned('assigned', 'Assigned', Tone.gray),
  pickedUp('picked_up', 'Picked up', Tone.gray),
  inTransit('in_transit', 'In transit', Tone.blue),
  delayed('delayed', 'Delayed', Tone.amber),
  delivered('delivered', 'Delivered', Tone.green),
  cancelled('cancelled', 'Cancelled', Tone.gray);

  const TripStatus(this.apiValue, this.label, this.tone);

  final String apiValue;
  final String label;
  final Tone tone;

  static TripStatus fromApi(String? value) {
    for (final status in TripStatus.values) {
      if (status.apiValue == value) return status;
    }
    return TripStatus.assigned;
  }

  static TripStatus fromLabel(String label) {
    for (final status in TripStatus.values) {
      if (status.label == label) return status;
    }
    return TripStatus.assigned;
  }
}

class OpsTrip {
  const OpsTrip({
    required this.ref,
    required this.client,
    required this.origin,
    required this.destination,
    required this.cargo,
    required this.driverName,
    required this.vehiclePlate,
    required this.status,
    required this.eta,
    this.apiId,
  });

  final String ref;
  final String client;
  final String origin;
  final String destination;
  final String cargo;
  final String driverName;
  final String vehiclePlate;
  final TripStatus status;
  final String eta;

  /// Numeric id on the live API, when the trip came from there.
  final int? apiId;

  String get route => '$origin → $destination';

  String get searchText =>
      '$ref $client $route $cargo $driverName $vehiclePlate ${status.label}'.toLowerCase();

  factory OpsTrip.fromJson(Map<String, dynamic> json) => OpsTrip(
        ref: json['ref'] as String,
        client: (json['client'] as String?) ?? '—',
        origin: json['origin'] as String,
        destination: json['destination'] as String,
        cargo: json['cargo'] as String,
        driverName: json['driverName'] as String,
        vehiclePlate: json['vehiclePlate'] as String,
        status: TripStatus.fromApi(json['status'] as String?),
        eta: (json['eta'] as String?) ?? '—',
        apiId: (json['id'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        if (apiId != null) 'id': apiId,
        'ref': ref,
        'client': client,
        'origin': origin,
        'destination': destination,
        'cargo': cargo,
        'driverName': driverName,
        'vehiclePlate': vehiclePlate,
        'status': status.apiValue,
        'eta': eta,
      };
}

class TimelineEntry {
  const TimelineEntry({required this.title, required this.detail});

  final String title;
  final String detail;

  factory TimelineEntry.fromJson(Map<String, dynamic> json) => TimelineEntry(
        title: json['title'] as String,
        detail: (json['detail'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {'title': title, 'detail': detail};
}

class CostLine {
  const CostLine({required this.label, required this.amountUgx, this.isRevenue = false});

  final String label;
  final int amountUgx;
  final bool isRevenue;

  factory CostLine.fromJson(Map<String, dynamic> json) => CostLine(
        label: json['label'] as String,
        amountUgx: (json['amountUgx'] as num).toInt(),
        isRevenue: (json['isRevenue'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() =>
      {'label': label, 'amountUgx': amountUgx, 'isRevenue': isRevenue};
}

class TripDetailData {
  const TripDetailData({
    required this.trip,
    required this.timeline,
    required this.costs,
    this.distanceKm,
    this.documents = const [],
  });

  final OpsTrip trip;
  final List<TimelineEntry> timeline;
  final List<CostLine> costs;
  final int? distanceKm;
  final List<String> documents;

  bool get hasRevenue => costs.any((c) => c.isRevenue);

  int get revenue =>
      costs.where((c) => c.isRevenue).fold<int>(0, (sum, c) => sum + c.amountUgx);

  int get expenses =>
      costs.where((c) => !c.isRevenue).fold<int>(0, (sum, c) => sum + c.amountUgx);

  int get margin => revenue - expenses;
}

// ------------------------------------------------------------- dashboard

class KpiStat {
  const KpiStat({
    required this.label,
    required this.value,
    required this.trend,
    this.icon = 'trips',
    this.positive = true,
    this.series = defaultSeries,
  });

  /// Shape of the little sparkline when the API sends no history.
  static const List<double> defaultSeries = [5, 8, 6, 13, 10, 15, 12, 17, 15];

  final String label;
  final String value;
  final String trend;

  /// Key resolved to an icon by the UI (see `kpiIcon`).
  final String icon;

  /// Green when true, red when false.
  final bool positive;
  final List<double> series;

  factory KpiStat.fromJson(Map<String, dynamic> json) => KpiStat(
        label: json['label'] as String,
        value: json['value'] as String,
        trend: (json['trend'] as String?) ?? '',
        icon: (json['icon'] as String?) ?? 'trips',
        positive: (json['positive'] as bool?) ?? true,
        series: (json['series'] as List<dynamic>?)
                ?.map((e) => (e as num).toDouble())
                .toList() ??
            defaultSeries,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'value': value,
        'trend': trend,
        'icon': icon,
        'positive': positive,
        'series': series,
      };
}

class AttentionItem {
  const AttentionItem({
    required this.title,
    required this.detail,
    required this.actionLabel,
    required this.target,
    this.critical = false,
    this.icon = 'alert',
  });

  final String title;
  final String detail;
  final String actionLabel;

  /// Module the action button opens.
  final ConsoleModule target;
  final bool critical;
  final String icon;

  factory AttentionItem.fromJson(Map<String, dynamic> json) => AttentionItem(
        title: json['title'] as String,
        detail: (json['detail'] as String?) ?? '',
        actionLabel: json['actionLabel'] as String,
        target: ConsoleModule.values.firstWhere(
          (m) => m.name == json['target'],
          orElse: () => ConsoleModule.overview,
        ),
        critical: (json['critical'] as bool?) ?? false,
        icon: (json['icon'] as String?) ?? 'alert',
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'detail': detail,
        'actionLabel': actionLabel,
        'target': target.name,
        'critical': critical,
        'icon': icon,
      };
}

class StatusCount {
  const StatusCount({required this.status, required this.count});

  final TripStatus status;
  final int count;
}

class DayPoint {
  const DayPoint({required this.label, required this.delivered, required this.target});

  final String label;
  final double delivered;
  final double target;
}

enum PinState {
  moving('Moving', Tone.blue),
  available('Available', Tone.green),
  idle('Idle', Tone.amber),
  stopped('Stopped', Tone.red),
  offline('Offline', Tone.gray);

  const PinState(this.label, this.tone);

  final String label;
  final Tone tone;
}

/// A vehicle on the map. [dx] and [dy] are fractions (0 to 1) of the map area.
class MapPin {
  const MapPin({required this.dx, required this.dy, required this.state, required this.label});

  final double dx;
  final double dy;
  final PinState state;
  final String label;
}

class VehicleMini {
  const VehicleMini({required this.plate, required this.driver, required this.status});

  final String plate;
  final String driver;
  final VehicleStatus status;
}

class FleetSnapshot {
  const FleetSnapshot({
    required this.pins,
    required this.counts,
    required this.highlights,
    required this.lastUpdate,
  });

  final List<MapPin> pins;
  final Map<PinState, int> counts;
  final List<VehicleMini> highlights;
  final String lastUpdate;
}

class OverviewData {
  const OverviewData({
    required this.kpis,
    required this.fleet,
    required this.attention,
    required this.statusCounts,
    required this.deliveries,
    this.note,
  });

  final List<KpiStat> kpis;
  final FleetSnapshot fleet;
  final List<AttentionItem> attention;
  final List<StatusCount> statusCounts;
  final List<DayPoint> deliveries;

  /// Shown above the page when part of it is sample data.
  final String? note;

  int get totalTrips => statusCounts.fold<int>(0, (sum, s) => sum + s.count);
}

// ----------------------------------------------------------------- fleet

enum VehicleStatus {
  moving('Moving', Tone.blue),
  delayed('Delayed', Tone.amber),
  available('Available', Tone.green),
  maintenance('Maintenance', Tone.amber),
  offline('Offline', Tone.gray);

  const VehicleStatus(this.label, this.tone);

  final String label;
  final Tone tone;

  static VehicleStatus fromApi(String? value) {
    for (final status in VehicleStatus.values) {
      if (status.name == value) return status;
    }
    return VehicleStatus.available;
  }
}

class FleetVehicle {
  const FleetVehicle({
    required this.plate,
    required this.model,
    required this.type,
    required this.status,
    required this.odometerKm,
    required this.nextService,
    required this.kmPerLitre,
    this.driverName,
  });

  final String plate;
  final String model;
  final String type;
  final VehicleStatus status;
  final int odometerKm;
  final String nextService;
  final double kmPerLitre;
  final String? driverName;

  String get searchText => '$plate $model $type ${status.label}'.toLowerCase();

  factory FleetVehicle.fromJson(Map<String, dynamic> json) => FleetVehicle(
        plate: json['plate'] as String,
        model: json['model'] as String,
        type: (json['type'] as String?) ?? 'Heavy goods vehicle',
        status: VehicleStatus.fromApi(json['status'] as String?),
        odometerKm: (json['odometerKm'] as num?)?.toInt() ?? 0,
        nextService: (json['nextService'] as String?) ?? '—',
        kmPerLitre: (json['kmPerLitre'] as num?)?.toDouble() ?? 0,
        driverName: json['driverName'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'plate': plate,
        'model': model,
        'type': type,
        'status': status.name,
        'odometerKm': odometerKm,
        'nextService': nextService,
        'kmPerLitre': kmPerLitre,
        'driverName': driverName,
      };
}

class FleetData {
  const FleetData({required this.kpis, required this.vehicles});

  final List<KpiStat> kpis;
  final List<FleetVehicle> vehicles;
}

// --------------------------------------------------------------- drivers

class FleetDriver {
  const FleetDriver({
    required this.name,
    required this.phone,
    required this.licenceClass,
    required this.licenceExpiry,
    required this.safetyScore,
    required this.onTimePercent,
    required this.tripsThisMonth,
    required this.incidents,
    this.currentTripRef,
  });

  final String name;
  final String phone;
  final String licenceClass;
  final String licenceExpiry;
  final int safetyScore;
  final int onTimePercent;
  final int tripsThisMonth;
  final int incidents;
  final String? currentTripRef;

  String get availability => currentTripRef == null ? 'Available' : 'On trip';

  String get searchText => '$name $phone'.toLowerCase();

  factory FleetDriver.fromJson(Map<String, dynamic> json) => FleetDriver(
        name: json['name'] as String,
        phone: (json['phone'] as String?) ?? '',
        licenceClass: (json['licenceClass'] as String?) ?? 'C',
        licenceExpiry: (json['licenceExpiry'] as String?) ?? '—',
        safetyScore: (json['safetyScore'] as num?)?.toInt() ?? 0,
        onTimePercent: (json['onTimePercent'] as num?)?.toInt() ?? 0,
        tripsThisMonth: (json['tripsThisMonth'] as num?)?.toInt() ?? 0,
        incidents: (json['incidents'] as num?)?.toInt() ?? 0,
        currentTripRef: json['currentTripRef'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'licenceClass': licenceClass,
        'licenceExpiry': licenceExpiry,
        'safetyScore': safetyScore,
        'onTimePercent': onTimePercent,
        'tripsThisMonth': tripsThisMonth,
        'incidents': incidents,
        'currentTripRef': currentTripRef,
      };
}

class DriversData {
  const DriversData({required this.kpis, required this.drivers});

  final List<KpiStat> kpis;
  final List<FleetDriver> drivers;
}

// ------------------------------------------------------------------ fuel

class LabelValue {
  const LabelValue({required this.label, required this.value});

  final String label;
  final double value;
}

class FuelException {
  const FuelException({
    required this.vehicle,
    required this.route,
    required this.litres,
    required this.amountUgx,
    required this.variancePercent,
    required this.flag,
  });

  final String vehicle;
  final String route;
  final int litres;
  final int amountUgx;
  final int variancePercent;
  final String flag;

  factory FuelException.fromJson(Map<String, dynamic> json) => FuelException(
        vehicle: json['vehicle'] as String,
        route: json['route'] as String,
        litres: (json['litres'] as num).toInt(),
        amountUgx: (json['amountUgx'] as num).toInt(),
        variancePercent: (json['variancePercent'] as num).toInt(),
        flag: json['flag'] as String,
      );

  Map<String, dynamic> toJson() => {
        'vehicle': vehicle,
        'route': route,
        'litres': litres,
        'amountUgx': amountUgx,
        'variancePercent': variancePercent,
        'flag': flag,
      };
}

class FuelData {
  const FuelData({
    required this.kpis,
    required this.routeSpend,
    required this.costShare,
    required this.exceptions,
  });

  final List<KpiStat> kpis;

  /// UGX millions per route.
  final List<LabelValue> routeSpend;

  /// Percent share per cost type.
  final List<LabelValue> costShare;
  final List<FuelException> exceptions;
}

// ------------------------------------------------------------- incidents

enum IncidentStatus {
  open('Open', Tone.red),
  assigned('Assigned', Tone.amber),
  resolved('Resolved', Tone.green);

  const IncidentStatus(this.label, this.tone);

  final String label;
  final Tone tone;
}

class SafetyIncident {
  const SafetyIncident({
    required this.ref,
    required this.title,
    required this.where,
    required this.detail,
    required this.status,
    this.critical = false,
  });

  final String ref;
  final String title;
  final String where;
  final String detail;
  final IncidentStatus status;
  final bool critical;

  factory SafetyIncident.fromJson(Map<String, dynamic> json) => SafetyIncident(
        ref: json['ref'] as String,
        title: json['title'] as String,
        where: (json['where'] as String?) ?? '',
        detail: (json['detail'] as String?) ?? '',
        status: IncidentStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => IncidentStatus.open,
        ),
        critical: (json['critical'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
        'ref': ref,
        'title': title,
        'where': where,
        'detail': detail,
        'status': status.name,
        'critical': critical,
      };
}

class IncidentsData {
  const IncidentsData({required this.kpis, required this.incidents});

  final List<KpiStat> kpis;
  final List<SafetyIncident> incidents;
}

// ------------------------------------------------------------- warehouse

class DispatchItem {
  const DispatchItem({
    required this.ref,
    required this.warehouse,
    required this.client,
    required this.destination,
    required this.load,
    required this.readySince,
    required this.highPriority,
  });

  final String ref;
  final String warehouse;
  final String client;
  final String destination;
  final String load;
  final String readySince;
  final bool highPriority;

  factory DispatchItem.fromJson(Map<String, dynamic> json) => DispatchItem(
        ref: json['ref'] as String,
        warehouse: json['warehouse'] as String,
        client: json['client'] as String,
        destination: json['destination'] as String,
        load: json['load'] as String,
        readySince: json['readySince'] as String,
        highPriority: (json['highPriority'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
        'ref': ref,
        'warehouse': warehouse,
        'client': client,
        'destination': destination,
        'load': load,
        'readySince': readySince,
        'highPriority': highPriority,
      };
}

class WarehouseData {
  const WarehouseData({required this.kpis, required this.queue});

  final List<KpiStat> kpis;
  final List<DispatchItem> queue;
}

// --------------------------------------------------------------- reports

class ReportDef {
  const ReportDef({required this.title, required this.description, required this.icon});

  final String title;
  final String description;
  final String icon;
}

class ReportsData {
  const ReportsData({
    required this.reports,
    required this.ranges,
    required this.clients,
    required this.routes,
    required this.vehicles,
  });

  final List<ReportDef> reports;
  final List<String> ranges;
  final List<String> clients;
  final List<String> routes;
  final List<String> vehicles;
}

// ------------------------------------------------------------------- ERP

enum ErpEventStatus {
  synced('Synced', Tone.green),
  pending('Pending', Tone.amber),
  failed('Failed', Tone.red);

  const ErpEventStatus(this.label, this.tone);

  final String label;
  final Tone tone;

  static ErpEventStatus fromApi(String? value) {
    for (final status in ErpEventStatus.values) {
      if (status.name == value) return status;
    }
    return ErpEventStatus.pending;
  }
}

class ErpEvent {
  const ErpEvent({
    required this.id,
    required this.type,
    required this.reference,
    required this.created,
    required this.attempts,
    required this.status,
    required this.message,
  });

  final String id;
  final String type;
  final String reference;
  final String created;
  final int attempts;
  final ErpEventStatus status;
  final String message;

  factory ErpEvent.fromJson(Map<String, dynamic> json) => ErpEvent(
        id: json['id'] as String,
        type: json['type'] as String,
        reference: (json['reference'] as String?) ?? '—',
        created: (json['created'] as String?) ?? '',
        attempts: (json['attempts'] as num?)?.toInt() ?? 1,
        status: ErpEventStatus.fromApi(json['status'] as String?),
        message: (json['message'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'reference': reference,
        'created': created,
        'attempts': attempts,
        'status': status.name,
        'message': message,
      };
}

class FieldMapping {
  const FieldMapping({required this.from, required this.to});

  final String from;
  final String to;
}

class ErpData {
  const ErpData({
    required this.connected,
    required this.lastSync,
    required this.latency,
    required this.pending,
    required this.synced,
    required this.failed,
    required this.events,
    required this.mappings,
  });

  final bool connected;
  final String lastSync;
  final String latency;
  final int pending;
  final int synced;
  final int failed;
  final List<ErpEvent> events;
  final List<FieldMapping> mappings;

  int get total => pending + synced + failed;

  /// Share of events already synced, from 0 to 1.
  double get syncedFraction => total == 0 ? 1 : synced / total;
}
