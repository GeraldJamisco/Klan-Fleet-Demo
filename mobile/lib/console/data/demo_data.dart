/// Sample data copied from the Nexora prototype. All names, plates and
/// amounts are invented.
library;

import '../core/access.dart';
import '../models/ops_models.dart';
import 'console_repository.dart';

class DemoData {
  const DemoData._();

  static const List<String> clients = [
    'Rwenzori Beverages',
    'Lake Cement Uganda',
    'Eastline FMCG',
    'Fresh Harvest Co-op',
    'BluePeak Energy',
    'Meridian Imports',
    'Jubilee Supermarkets',
    'AgroLink Uganda',
  ];

  static const List<String> cargoTypes = [
    'FMCG pallets',
    'Cement',
    'Beverages',
    'Container',
    'Agricultural produce',
    'Fuel',
  ];

  static const List<String> origins = [
    'Kampala', 'Jinja', 'Mombasa', 'Nairobi', 'Gulu', 'Mbarara',
  ];

  static const List<String> destinations = [
    'Mombasa', 'Nairobi', 'Kigali', 'Juba', 'Malaba',
    'Busia', 'Gulu', 'Mbarara', 'Jinja', 'Arua',
  ];

  static const List<String> driverNames = [
    'Sarah Nakato',
    'Peter Okello',
    'David Mugisha',
    'Grace Atim',
    'John Ssemanda',
    'Mary Achieng',
    'Robert Ouma',
    'Isaac Kato',
    'Lydia Nansubuga',
    'Emmanuel Turyasingura',
  ];

  static OpsTrip _trip(
    String ref,
    String client,
    String route,
    String cargo,
    String driver,
    String plate,
    String status,
    String eta,
  ) {
    final parts = route.split(' → ');
    return OpsTrip(
      ref: ref,
      client: client,
      origin: parts.first,
      destination: parts.last,
      cargo: cargo,
      driverName: driver,
      vehiclePlate: plate,
      status: TripStatus.fromLabel(status),
      eta: eta,
    );
  }

  static List<OpsTrip> trips() => [
        _trip('TRP-2601', 'Rwenzori Beverages', 'Kampala → Mombasa', 'Beverages · 24T', 'Sarah Nakato', 'UAX 482K', 'In transit', '14 Nov, 08:30'),
        _trip('TRP-2602', 'Lake Cement Uganda', 'Tororo → Kampala', 'Cement · 30T', 'Peter Okello', 'UAZ 219P', 'In transit', 'Today, 18:10'),
        _trip('TRP-2603', 'Eastline FMCG', 'Kampala → Gulu', 'FMCG · 18T', 'David Mugisha', 'UBF 663M', 'Delayed', 'Today, 17:40'),
        _trip('TRP-2604', 'Meridian Imports', 'Mombasa → Kampala', 'Container · 28T', 'Grace Atim', 'UAX 905B', 'In transit', '15 Nov, 11:00'),
        _trip('TRP-2605', 'Fresh Harvest Co-op', 'Mbarara → Kampala', 'Produce · 12T', 'John Ssemanda', 'UAZ 441D', 'Delivered', 'Today, 13:20'),
        _trip('TRP-2606', 'BluePeak Energy', 'Kampala → Jinja', 'Fuel · 32KL', 'Mary Achieng', 'UAY 770C', 'Picked up', 'Today, 19:00'),
        _trip('TRP-2607', 'AgroLink Uganda', 'Gulu → Kampala', 'Produce · 16T', 'Robert Ouma', 'UBF 210K', 'Assigned', '13 Nov, 06:00'),
        _trip('TRP-2608', 'Jubilee Supermarkets', 'Kampala → Kigali', 'FMCG · 20T', 'Sarah Nakato', 'UAX 482K', 'In transit', '14 Nov, 15:30'),
        _trip('TRP-2609', 'Meridian Imports', 'Nairobi → Kampala', 'Container · 26T', 'Peter Okello', 'UAZ 219P', 'Delivered', 'Today, 10:15'),
        _trip('TRP-2610', 'Lake Cement Uganda', 'Hima → Arua', 'Cement · 28T', 'David Mugisha', 'UBF 663M', 'Assigned', '13 Nov, 07:30'),
        _trip('TRP-2611', 'Eastline FMCG', 'Kampala → Mbarara', 'FMCG · 14T', 'Grace Atim', 'UAX 905B', 'Picked up', 'Today, 16:50'),
        _trip('TRP-2612', 'Fresh Harvest Co-op', 'Jinja → Nairobi', 'Produce · 18T', 'John Ssemanda', 'UAZ 441D', 'In transit', '15 Nov, 09:00'),
        _trip('TRP-2613', 'BluePeak Energy', 'Kampala → Malaba', 'Fuel · 30KL', 'Mary Achieng', 'UAY 770C', 'Delayed', 'Today, 20:00'),
        _trip('TRP-2614', 'AgroLink Uganda', 'Arua → Kampala', 'Produce · 15T', 'Robert Ouma', 'UBF 210K', 'Delivered', 'Today, 12:00'),
        _trip('TRP-2615', 'Jubilee Supermarkets', 'Kampala → Juba', 'FMCG · 19T', 'Sarah Nakato', 'UAX 482K', 'In transit', '16 Nov, 14:00'),
        _trip('TRP-2616', 'Rwenzori Beverages', 'Kampala → Jinja', 'Beverages · 16T', 'Peter Okello', 'UAZ 219P', 'Delivered', 'Today, 09:40'),
        _trip('TRP-2617', 'Meridian Imports', 'Busia → Kampala', 'Container · 25T', 'Grace Atim', 'UAX 905B', 'Assigned', '13 Nov, 08:00'),
        _trip('TRP-2618', 'Lake Cement Uganda', 'Kampala → Mbarara', 'Cement · 28T', 'David Mugisha', 'UBF 663M', 'In transit', 'Today, 21:00'),
        _trip('TRP-2619', 'Eastline FMCG', 'Kampala → Nairobi', 'FMCG · 21T', 'John Ssemanda', 'UAZ 441D', 'Cancelled', '—'),
        _trip('TRP-2620', 'Fresh Harvest Co-op', 'Mbarara → Gulu', 'Produce · 13T', 'Mary Achieng', 'UAY 770C', 'Assigned', '13 Nov, 06:30'),
        _trip('TRP-2621', 'BluePeak Energy', 'Jinja → Kampala', 'Fuel · 28KL', 'Robert Ouma', 'UBF 210K', 'Delivered', 'Today, 11:25'),
        _trip('TRP-2622', 'AgroLink Uganda', 'Kampala → Kigali', 'Produce · 17T', 'Sarah Nakato', 'UAX 482K', 'Picked up', '14 Nov, 06:00'),
        _trip('TRP-2623', 'Jubilee Supermarkets', 'Kampala → Gulu', 'FMCG · 15T', 'Peter Okello', 'UAZ 219P', 'In transit', 'Today, 19:30'),
        _trip('TRP-2624', 'Rwenzori Beverages', 'Kampala → Mombasa', 'Beverages · 22T', 'Grace Atim', 'UAX 905B', 'Assigned', '13 Nov, 05:30'),
        _trip('TRP-2625', 'Meridian Imports', 'Nairobi → Jinja', 'Container · 24T', 'John Ssemanda', 'UAZ 441D', 'Delivered', 'Today, 14:10'),
      ];

  static FleetVehicle _vehicle(
    String plate,
    String model,
    String type,
    VehicleStatus status,
    String? driver,
    int odometer,
    String service,
    double kmPerLitre,
  ) =>
      FleetVehicle(
        plate: plate,
        model: model,
        type: type,
        status: status,
        driverName: driver,
        odometerKm: odometer,
        nextService: service,
        kmPerLitre: kmPerLitre,
      );

  static List<FleetVehicle> vehicles() => [
        _vehicle('UAX 482K', 'Isuzu Giga', 'Rigid truck', VehicleStatus.moving, 'Sarah Nakato', 482190, '18 Nov 2026', 6.8),
        _vehicle('UAZ 219P', 'Mercedes Actros', 'Tractor head', VehicleStatus.moving, 'Peter Okello', 391440, '02 Dec 2026', 7.2),
        _vehicle('UBF 663M', 'Scania R450', 'Tractor head', VehicleStatus.delayed, 'David Mugisha', 518220, '14 Nov 2026', 6.4),
        _vehicle('UAX 905B', 'Volvo FH', 'Tractor head', VehicleStatus.available, 'Grace Atim', 284100, '21 Dec 2026', 7.6),
        _vehicle('UAZ 441D', 'Mitsubishi Fuso', 'Rigid truck', VehicleStatus.moving, 'John Ssemanda', 198760, '08 Jan 2027', 8.1),
        _vehicle('UAY 770C', 'MAN TGS Tanker', 'Tanker', VehicleStatus.moving, 'Mary Achieng', 336820, '19 Nov 2026', 3.2),
        _vehicle('UBF 210K', 'Isuzu FTR', 'Rigid truck', VehicleStatus.available, 'Robert Ouma', 176330, '12 Feb 2027', 7.9),
        _vehicle('UAX 118R', 'Scania P410', 'Rigid truck', VehicleStatus.maintenance, null, 620500, '30 Nov 2026', 6.1),
        _vehicle('UAZ 772L', 'Hino 500', 'Rigid truck', VehicleStatus.available, null, 143880, '16 Mar 2027', 7.4),
        _vehicle('UBG 309A', 'Volvo FM', 'Tractor head', VehicleStatus.offline, null, 402110, '09 Dec 2026', 6.9),
        _vehicle('UAT 551E', 'Mercedes Axor', 'Tractor head', VehicleStatus.available, null, 229400, '03 Jan 2027', 7.7),
        _vehicle('UBH 881F', 'Isuzu FVR', 'Rigid truck', VehicleStatus.maintenance, null, 311600, '27 Nov 2026', 7.1),
      ];

  static List<FleetDriver> drivers(List<OpsTrip> trips) => [
        for (var i = 0; i < driverNames.length; i++)
          FleetDriver(
            name: driverNames[i],
            phone: '+256 7${12 + i} 4${i}8 2${i}0',
            licenceClass: i % 3 == 0 ? 'CE' : 'C',
            licenceExpiry: i == 1 ? '18 Nov 2026' : 'Aug 2027',
            currentTripRef: trips[i % trips.length].ref,
            safetyScore: 96 - i * 2,
            onTimePercent: (98 - i * 1.7).floor(),
            tripsThisMonth: 18 - i,
            incidents: i % 4 == 0 ? 2 : 0,
          ),
      ];

  static OverviewData overview() => const OverviewData(
        kpis: [
          KpiStat(label: 'Trips today', value: '38', trend: '12% vs last week', icon: 'trips'),
          KpiStat(label: 'On-time delivery', value: '94.2%', trend: '3.4 pts vs last week', icon: 'clock'),
          KpiStat(label: 'Vehicles active', value: '28 / 36', trend: '4 more active', icon: 'truck'),
          KpiStat(label: 'Fuel spend · today', value: 'UGX 8.4M', trend: '6% vs last week', icon: 'fuel', positive: false),
          KpiStat(label: 'Open incidents', value: '06', trend: '2 resolved today', icon: 'flag', positive: false),
          KpiStat(label: 'Pending ERP syncs', value: '12', trend: '8 fewer than yesterday', icon: 'sync'),
        ],
        fleet: FleetSnapshot(
          lastUpdate: 'Vehicle positions · Last GPS update 16:44 EAT',
          pins: [
            MapPin(dx: 0.44, dy: 0.50, state: PinState.available, label: 'UAX 905B'),
            MapPin(dx: 0.55, dy: 0.40, state: PinState.moving, label: 'UAX 482K'),
            MapPin(dx: 0.70, dy: 0.24, state: PinState.moving, label: 'UAZ 219P'),
            MapPin(dx: 0.29, dy: 0.28, state: PinState.idle, label: 'UBF 663M'),
            MapPin(dx: 0.26, dy: 0.76, state: PinState.available, label: 'UAZ 772L'),
            MapPin(dx: 0.82, dy: 0.68, state: PinState.offline, label: 'UBG 309A'),
            MapPin(dx: 0.61, dy: 0.67, state: PinState.moving, label: 'UAZ 441D'),
            MapPin(dx: 0.48, dy: 0.33, state: PinState.available, label: 'UBF 210K'),
            MapPin(dx: 0.17, dy: 0.52, state: PinState.idle, label: 'UAT 551E'),
            MapPin(dx: 0.75, dy: 0.48, state: PinState.offline, label: 'UBH 881F'),
          ],
          counts: {
            PinState.moving: 18,
            PinState.idle: 5,
            PinState.stopped: 3,
            PinState.offline: 2,
          },
          highlights: [
            VehicleMini(plate: 'UAX 482K', driver: 'Sarah N.', status: VehicleStatus.moving),
            VehicleMini(plate: 'UBF 663M', driver: 'David M.', status: VehicleStatus.delayed),
            VehicleMini(plate: 'UAZ 219P', driver: 'Peter O.', status: VehicleStatus.moving),
            VehicleMini(plate: 'UBG 309A', driver: 'Unassigned', status: VehicleStatus.offline),
          ],
        ),
        attention: [
          AttentionItem(
            title: 'TRP-2603 · Gulu delivery is 1h 25m late',
            detail: 'David Mugisha · ETA revised to 17:40',
            actionLabel: 'Track trip',
            target: ConsoleModule.trips,
            critical: true,
            icon: 'alert',
          ),
          AttentionItem(
            title: 'UAX 118R · Service overdue by 3 days',
            detail: 'Scania P410 · 620,500 km',
            actionLabel: 'Schedule',
            target: ConsoleModule.fleet,
            icon: 'wrench',
          ),
          AttentionItem(
            title: '2 driver licences expire this month',
            detail: 'Grace Atim · 21 Nov, Isaac Kato · 29 Nov',
            actionLabel: 'Review',
            target: ConsoleModule.drivers,
            icon: 'people',
          ),
          AttentionItem(
            title: 'UBF 663M · Engine temperature alert',
            detail: 'Driver reported warning near Luwero',
            actionLabel: 'Open',
            target: ConsoleModule.incidents,
            critical: true,
            icon: 'flag',
          ),
          AttentionItem(
            title: 'Mary Achieng · Driving hours threshold',
            detail: '10h 15m logged today',
            actionLabel: 'Contact',
            target: ConsoleModule.drivers,
            icon: 'clock',
          ),
          AttentionItem(
            title: 'ERP event failed · fuel.recorded',
            detail: 'Event EVT-8891 · 3 retry attempts',
            actionLabel: 'Retry',
            target: ConsoleModule.erp,
            critical: true,
            icon: 'sync',
          ),
        ],
        statusCounts: [
          StatusCount(status: TripStatus.assigned, count: 7),
          StatusCount(status: TripStatus.pickedUp, count: 5),
          StatusCount(status: TripStatus.inTransit, count: 18),
          StatusCount(status: TripStatus.delivered, count: 6),
          StatusCount(status: TripStatus.cancelled, count: 2),
        ],
        deliveries: [
          DayPoint(label: 'Fri', delivered: 22, target: 17),
          DayPoint(label: 'Sat', delivered: 28, target: 23),
          DayPoint(label: 'Sun', delivered: 25, target: 20),
          DayPoint(label: 'Mon', delivered: 34, target: 29),
          DayPoint(label: 'Tue', delivered: 31, target: 26),
          DayPoint(label: 'Wed', delivered: 39, target: 34),
          DayPoint(label: 'Thu', delivered: 36, target: 31),
        ],
      );

  static FleetData fleet() => FleetData(
        kpis: const [
          KpiStat(label: 'Total vehicles', value: '36', trend: '2 added this quarter', icon: 'truck'),
          KpiStat(label: 'Available', value: '08', trend: '2 more than yesterday', icon: 'check'),
          KpiStat(label: 'On the road', value: '24', trend: '67% utilisation', icon: 'trips'),
          KpiStat(label: 'In maintenance', value: '04', trend: '1 awaiting parts', icon: 'wrench'),
          KpiStat(label: 'Fleet utilisation', value: '78.4%', trend: '5.2% vs last month', icon: 'clock'),
          KpiStat(label: 'Maintenance due', value: '03', trend: 'Next 14 days', icon: 'flag', positive: false),
        ],
        vehicles: vehicles(),
      );

  static DriversData driversData(List<OpsTrip> trips) => DriversData(
        kpis: const [
          KpiStat(label: 'Active drivers', value: '32', trend: '3 on leave', icon: 'people'),
          KpiStat(label: 'Licence alerts', value: '02', trend: 'Expiring in 30 days', icon: 'people', positive: false),
          KpiStat(label: 'Average safety score', value: '92 / 100', trend: '2 pts vs last month', icon: 'shield'),
          KpiStat(label: 'On-time rate', value: '94.2%', trend: '3.4 pts vs last week', icon: 'clock'),
        ],
        drivers: drivers(trips),
      );

  static FuelData fuel() => const FuelData(
        kpis: [
          KpiStat(label: 'Fuel spend today', value: 'UGX 8.4M', trend: '6% vs last week', icon: 'fuel', positive: false),
          KpiStat(label: 'Month to date', value: 'UGX 184.6M', trend: '8% vs October', icon: 'trips', positive: false),
          KpiStat(label: 'Fuel issued', value: '24,680 L', trend: '4% vs last week', icon: 'fuel'),
          KpiStat(label: 'Average cost / km', value: 'UGX 1,840', trend: '2.1% improvement', icon: 'invoice'),
          KpiStat(label: 'Spend anomalies', value: '03', trend: '2 require review', icon: 'flag', positive: false),
          KpiStat(label: 'Outstanding invoices', value: 'UGX 42.8M', trend: '11 invoices', icon: 'invoice', positive: false),
        ],
        routeSpend: [
          LabelValue(label: 'Mombasa', value: 82),
          LabelValue(label: 'Nairobi', value: 68),
          LabelValue(label: 'Juba', value: 52),
          LabelValue(label: 'Kigali', value: 44),
          LabelValue(label: 'Gulu', value: 34),
          LabelValue(label: 'Jinja', value: 25),
        ],
        costShare: [
          LabelValue(label: 'Fuel', value: 52),
          LabelValue(label: 'Maintenance', value: 18),
          LabelValue(label: 'Tolls & border fees', value: 12),
          LabelValue(label: 'Driver allowances', value: 11),
          LabelValue(label: 'Other', value: 7),
        ],
        exceptions: [
          FuelException(vehicle: 'UBF 663M', route: 'Kampala – Gulu', litres: 310, amountUgx: 1612000, variancePercent: 38, flag: 'High fill'),
          FuelException(vehicle: 'UAX 482K', route: 'Kampala – Mombasa', litres: 280, amountUgx: 1456000, variancePercent: 21, flag: 'Variance'),
        ],
      );

  static IncidentsData incidents() => const IncidentsData(
        kpis: [
          KpiStat(label: 'Open incidents', value: '06', trend: '2 new today', icon: 'flag', positive: false),
          KpiStat(label: 'Critical', value: '01', trend: 'Immediate action', icon: 'alert', positive: false),
          KpiStat(label: 'Resolved this month', value: '42', trend: '12% improvement', icon: 'check'),
          KpiStat(label: 'Average resolution', value: '3.4 hrs', trend: '0.8h faster', icon: 'clock'),
        ],
        incidents: [
          SafetyIncident(
            ref: 'INC-0441',
            title: 'Vehicle breakdown',
            where: 'UBF 663M · Luwero highway · 16:38',
            detail: 'Engine temperature warning · Assigned: Fleet desk',
            status: IncidentStatus.open,
            critical: true,
          ),
          SafetyIncident(
            ref: 'INC-0440',
            title: 'Delivery delay',
            where: 'TRP-2603 · Gulu route · 15:52',
            detail: 'Roadworks at Karuma bridge · Assigned: Dispatch',
            status: IncidentStatus.assigned,
          ),
          SafetyIncident(
            ref: 'INC-0439',
            title: 'Cargo damage',
            where: 'TRP-2588 · Kampala warehouse · 11:24',
            detail: '4 beverage pallets damaged · Assigned: Claims',
            status: IncidentStatus.open,
            critical: true,
          ),
          SafetyIncident(
            ref: 'INC-0438',
            title: 'Minor collision',
            where: 'UAZ 772L · Jinja road · Yesterday 17:10',
            detail: 'No injuries reported · Assigned: Safety officer',
            status: IncidentStatus.resolved,
          ),
        ],
      );

  static WarehouseData warehouse() => const WarehouseData(
        kpis: [
          KpiStat(label: 'Stock-in today', value: '1,248 pallets', trend: '8% vs yesterday', icon: 'pallet'),
          KpiStat(label: 'Stock-out today', value: '986 pallets', trend: '5% vs yesterday', icon: 'pallet'),
          KpiStat(label: 'Dispatches waiting', value: '14', trend: '4 high priority', icon: 'invoice', positive: false),
          KpiStat(label: 'Delivery points', value: '38', trend: 'Across 9 routes', icon: 'pin'),
          KpiStat(label: 'Returns today', value: '12', trend: '3 awaiting inspection', icon: 'return', positive: false),
          KpiStat(label: 'Damaged goods', value: '04', trend: 'UGX 1.8M estimated', icon: 'flag', positive: false),
        ],
        queue: [
          DispatchItem(ref: 'DSP-1044', warehouse: 'Namanve DC', client: 'Jubilee Supermarkets', destination: 'Gulu', load: '18 pallets', readySince: '09:10', highPriority: true),
          DispatchItem(ref: 'DSP-1043', warehouse: 'Nakawa Hub', client: 'Eastline FMCG', destination: 'Mbarara', load: '22 pallets', readySince: '10:25', highPriority: false),
          DispatchItem(ref: 'DSP-1042', warehouse: 'Luzira Depot', client: 'Rwenzori Beverages', destination: 'Jinja', load: '16 pallets', readySince: '11:40', highPriority: false),
          DispatchItem(ref: 'DSP-1041', warehouse: 'Namanve DC', client: 'AgroLink Uganda', destination: 'Arua', load: '12 tonnes', readySince: '12:05', highPriority: true),
        ],
      );

  static ReportsData reports(List<FleetVehicle> vehicles) => ReportsData(
        reports: const [
          ReportDef(title: 'Daily operations', description: 'Trips, fleet status, delivery exceptions and dispatch activity.', icon: 'dashboard'),
          ReportDef(title: 'Weekly KPI pack', description: 'Operational performance, service levels and trend indicators.', icon: 'chart'),
          ReportDef(title: 'Fuel and cost', description: 'Fuel consumption, cost per km and spend anomalies.', icon: 'fuel'),
          ReportDef(title: 'Driver performance', description: 'Safety, punctuality, utilisation and driver scorecards.', icon: 'people'),
          ReportDef(title: 'Vehicle utilisation', description: 'Vehicle availability, downtime and maintenance trends.', icon: 'truck'),
          ReportDef(title: 'Client delivery performance', description: 'On-time delivery, exceptions and client-level service.', icon: 'check'),
          ReportDef(title: 'Incident log', description: 'Incident register, severity, resolution and route hotspots.', icon: 'flag'),
          ReportDef(title: 'ERP reconciliation', description: 'Integration event totals, failed records and field mismatches.', icon: 'sync'),
        ],
        ranges: const ['Last 7 days', 'Today', 'This month', 'Custom range'],
        clients: clients,
        routes: const ['Kampala → Mombasa', 'Kampala → Nairobi', 'Kampala → Gulu'],
        vehicles: [for (final v in vehicles.take(4)) v.plate],
      );

  static ErpData erp() => const ErpData(
        connected: true,
        lastSync: '12 Nov 2026, 16:42:18 EAT',
        latency: '1.4s',
        pending: 12,
        synced: 1284,
        failed: 3,
        events: [
          ErpEvent(id: 'EVT-8914', type: 'trip.delivered', reference: 'TRP-2598', created: '16:42:18', attempts: 1, status: ErpEventStatus.synced, message: '200 · Accepted'),
          ErpEvent(id: 'EVT-8913', type: 'fuel.recorded', reference: 'UAX 482K', created: '16:41:02', attempts: 2, status: ErpEventStatus.pending, message: 'Awaiting ERP acknowledgement'),
          ErpEvent(id: 'EVT-8912', type: 'incident.reported', reference: 'INC-0441', created: '16:38:49', attempts: 3, status: ErpEventStatus.failed, message: 'Validation: missing cost_center'),
          ErpEvent(id: 'EVT-8911', type: 'trip.updated', reference: 'TRP-2603', created: '16:35:11', attempts: 1, status: ErpEventStatus.synced, message: '200 · Accepted'),
          ErpEvent(id: 'EVT-8910', type: 'vehicle.service_logged', reference: 'UAX 118R', created: '16:31:04', attempts: 1, status: ErpEventStatus.synced, message: '200 · Accepted'),
          ErpEvent(id: 'EVT-8909', type: 'trip.delivered', reference: 'TRP-2592', created: '16:28:22', attempts: 3, status: ErpEventStatus.failed, message: 'ERP timeout after 30s'),
          ErpEvent(id: 'EVT-8908', type: 'fuel.recorded', reference: 'UAZ 219P', created: '16:25:40', attempts: 1, status: ErpEventStatus.synced, message: '200 · Accepted'),
        ],
        mappings: [
          FieldMapping(from: 'trip.reference', to: 'transport_order.order_no'),
          FieldMapping(from: 'trip.actual_delivery_at', to: 'delivery.confirmed_at'),
          FieldMapping(from: 'fuel.quantity_litres', to: 'fleet_fuel.volume_l'),
          FieldMapping(from: 'incident.severity', to: 'safety_event.priority'),
          FieldMapping(from: 'vehicle.registration', to: 'fleet_asset.plate_number'),
        ],
      );

  static TripDetailData tripDetail(OpsTrip trip) => TripDetailData(
        trip: trip,
        distanceKm: 1160,
        documents: const ['Waybill.pdf', 'Invoice.pdf'],
        timeline: const [
          TimelineEntry(title: 'Trip assigned', detail: '12 Nov · 06:10 · Kampala dispatch yard'),
          TimelineEntry(title: 'Vehicle arrived for loading', detail: '12 Nov · 06:42 · Namanve Industrial Park'),
          TimelineEntry(title: 'Cargo loaded & sealed', detail: '12 Nov · 07:35 · Seal no. NX-88291'),
          TimelineEntry(title: 'Departed origin', detail: '12 Nov · 08:05 · Kampala weighbridge'),
          TimelineEntry(title: 'GPS checkpoint', detail: '12 Nov · 13:20 · Jinja – Iganga highway'),
        ],
        costs: const [
          CostLine(label: 'Revenue', amountUgx: 4850000, isRevenue: true),
          CostLine(label: 'Fuel', amountUgx: 1120000),
          CostLine(label: 'Driver allowance', amountUgx: 280000),
          CostLine(label: 'Border & toll fees', amountUgx: 165000),
          CostLine(label: 'Other costs', amountUgx: 95000),
        ],
      );

  static NewTripOptions newTripOptions() => const NewTripOptions(
        clients: clients,
        cargoTypes: cargoTypes,
        origins: origins,
        destinations: destinations,
        drivers: [
          PickOption(id: 'd1', label: 'Sarah Nakato · Class C'),
          PickOption(id: 'd2', label: 'Peter Okello · Class CE'),
          PickOption(id: 'd3', label: 'David Mugisha · Class C'),
          PickOption(id: 'd4', label: 'Grace Atim · Class CE'),
        ],
        vehicles: [
          PickOption(id: 'v1', label: 'UAX 482K · Isuzu Giga'),
          PickOption(id: 'v2', label: 'UAZ 219P · Mercedes Actros'),
          PickOption(id: 'v3', label: 'UBF 663M · Scania R450'),
        ],
      );
}
