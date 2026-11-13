/// Sample data from the Nexora driver prototype. Updates are kept in memory
/// for the session, so every form can be demonstrated without a server.
library;

import '../../console/core/formatters.dart';
import '../../console/models/ops_models.dart' show Tone, TripStatus;
import '../models/driver_models.dart';
import 'driver_repository.dart';

class DemoDriverRepository implements DriverRepository {
  DemoDriverRepository({
    this.latency = const Duration(milliseconds: 300),
    DriverProfile? profile,
  }) : _profile = profile ?? sampleProfile;

  /// Small artificial delay so loading states are visible.
  final Duration latency;

  final DriverProfile _profile;

  static const DriverProfile sampleProfile = DriverProfile(
    name: 'Alex Mugisha',
    driverId: 'DRV-004',
    phone: '+256 772 123 456',
    licenceClass: 'CM',
    licenceExpiry: '18 Mar 2027',
    safetyScore: 96,
    base: 'Kampala, Uganda',
    vehicleLabel: 'UAZ 739R · Isuzu FXZ 360',
  );

  DriverTrip? _active = const DriverTrip(
    ref: 'TRP-2026-0148',
    origin: 'Kampala',
    destination: 'Mombasa',
    cargo: 'Cement (bagged) · 28 MT',
    status: TripStatus.inTransit,
    vehiclePlate: 'UAZ 739R',
    vehicleModel: 'Isuzu FXZ 360',
    client: 'Eastline Building Supplies',
    scheduled: '05:00 EAT',
    eta: '19:45 today',
    distanceKm: 1187,
    dateLabel: '24 Oct',
  );

  final List<DriverTrip> _past = [
    const DriverTrip(
      ref: 'TRP-2026-0131',
      origin: 'Kampala',
      destination: 'Nairobi',
      cargo: 'FMCG pallets',
      status: TripStatus.delivered,
      vehiclePlate: 'UAZ 739R',
      dateLabel: '21 Oct',
    ),
    const DriverTrip(
      ref: 'TRP-2026-0119',
      origin: 'Jinja',
      destination: 'Kampala',
      cargo: 'Beverages',
      status: TripStatus.delivered,
      vehiclePlate: 'UAZ 739R',
      dateLabel: '17 Oct',
    ),
    const DriverTrip(
      ref: 'TRP-2026-0104',
      origin: 'Kampala',
      destination: 'Gulu',
      cargo: 'Agricultural produce',
      status: TripStatus.delivered,
      vehiclePlate: 'UAZ 739R',
      dateLabel: '12 Oct',
    ),
  ];

  final List<DriverFuelEntry> _fuel = [
    const DriverFuelEntry(
      when: '24 Oct · 05:08',
      station: 'Total Nakawa',
      litres: 180,
      amountUgx: 855000,
      odometerKm: 184220,
      review: 'Approved',
      reviewTone: Tone.green,
    ),
    const DriverFuelEntry(
      when: '23 Oct · 18:40',
      station: 'Shell Iganga',
      litres: 161,
      amountUgx: 765000,
      odometerKm: 184748,
      review: 'Approved',
      reviewTone: Tone.green,
    ),
  ];

  final List<DriverMessage> _messages = [
    const DriverMessage(
      sender: 'Dispatch',
      title: 'Route update',
      body: 'Use Malaba border crossing. Keep your customs documents ready and call dispatch if queues exceed two hours.',
      time: 'Today · 09:42',
      unread: true,
    ),
    const DriverMessage(
      sender: 'Operations',
      title: 'Safety check',
      body: 'Remember to complete your scheduled rest break before continuing the long-haul leg.',
      time: 'Today · 08:15',
      unread: true,
      kind: 'warning',
    ),
    const DriverMessage(
      sender: 'Fleet',
      title: 'Vehicle inspection',
      body: 'Your pre-trip vehicle inspection for UAZ 739R was approved.',
      time: 'Today · 05:12',
      kind: 'check',
    ),
  ];

  static const List<DriverDocument> _documents = [
    DriverDocument(
      title: 'Electronic waybill',
      detail: 'WB-0148-UG · Issued 24 Oct 2026',
      state: DocumentState.available,
    ),
    DriverDocument(
      title: 'Commercial invoice',
      detail: 'INV-88214 · Eastline Building Supplies',
      state: DocumentState.available,
    ),
    DriverDocument(
      title: 'Border clearance',
      detail: 'Required at Malaba / Busia crossing',
      state: DocumentState.pending,
    ),
  ];

  Future<T> _after<T>(T Function() produce) => Future<T>.delayed(latency, produce);

  @override
  String get sourceLabel => 'Demo data';

  DriverSummary _summary() {
    final litres = _fuel.fold<double>(0, (sum, f) => sum + f.litres);
    final cost = _fuel.fold<int>(0, (sum, f) => sum + f.amountUgx);
    return DriverSummary(
      distanceKm: _active?.distanceKm,
      fuelLitres: litres,
      drivingTime: '14h 54m',
      fuelCostUgx: cost,
      kmPerLitre: 3.48,
    );
  }

  @override
  Future<DriverSnapshot> load() => _after(
        () => DriverSnapshot(
          profile: _profile,
          activeTrip: _active,
          history: [if (_active != null) _active!, ..._past],
          fuel: List<DriverFuelEntry>.of(_fuel),
          documents: _documents,
          messages: List<DriverMessage>.of(_messages),
          summary: _summary(),
        ),
      );

  @override
  List<StatusChoice> statusChoices(DriverTrip trip) => const [
        StatusChoice(id: 'in_transit', label: 'In transit', target: TripStatus.inTransit),
        StatusChoice(id: 'checkpoint', label: 'Arrived at checkpoint'),
        StatusChoice(id: 'border', label: 'At border crossing'),
        StatusChoice(id: 'delayed', label: 'Delayed', target: TripStatus.delayed),
        StatusChoice(id: 'delivered', label: 'Delivered', target: TripStatus.delivered),
      ];

  void _finishIfDelivered(TripStatus status) {
    if (status == TripStatus.delivered && _active != null) {
      _past.insert(0, _active!.copyWith(status: TripStatus.delivered));
      _active = null;
    }
  }

  @override
  Future<void> updateStatus(DriverTrip trip, StatusUpdate update) => _after(() {
        final target = update.choice.target;
        if (target != null && _active != null) {
          _active = _active!.copyWith(status: target);
          _finishIfDelivered(target);
        }
      });

  @override
  Future<void> logFuel(DriverTrip trip, FuelRequest request) => _after(() {
        _fuel.insert(
          0,
          DriverFuelEntry(
            when: dayAndTime(DateTime.now()),
            station: request.station.isEmpty ? '—' : request.station,
            litres: request.litres,
            amountUgx: request.amountUgx,
            odometerKm: request.odometerKm,
            review: 'Submitted',
          ),
        );
      });

  @override
  Future<void> reportIssue(DriverTrip? trip, IssueRequest request) => _after(() {
        _messages.insert(
          0,
          DriverMessage(
            sender: 'Operations',
            title: 'Issue received',
            body: '${request.category.label} was reported and sent to the operations team.',
            time: dayAndTime(DateTime.now()),
            kind: 'check',
          ),
        );
      });

  @override
  Future<void> submitProof(DriverTrip trip, DeliveryProof proof) => _after(() {
        if (_active != null) {
          _active = _active!.copyWith(status: TripStatus.delivered);
          _finishIfDelivered(TripStatus.delivered);
        }
      });
}
