/// Live data from the Klan Fleet REST API for what it already serves (the
/// driver's trips, status updates, fuel logs and incidents). Documents,
/// messages and licence details are still sample data, and the app says so.
library;

import '../../core/api_client.dart';
import '../../core/format.dart' as fmt;
import '../../core/models.dart' as api;
import '../../console/models/ops_models.dart' show Tone, TripStatus;
import '../models/driver_models.dart';
import 'demo_driver_repository.dart';
import 'driver_repository.dart';

class ApiDriverRepository extends DemoDriverRepository {
  // The named parameters cannot be private, so initializing formals are not an option here.
  // ignore: prefer_initializing_formals
  ApiDriverRepository({required ApiClient Function() client, required api.AppUser Function() user})
      // ignore: prefer_initializing_formals
      : _client = client,
        // ignore: prefer_initializing_formals
        _user = user,
        super(latency: Duration.zero);

  /// A factory, because the session builds a client with the current token.
  final ApiClient Function() _client;
  final api.AppUser Function() _user;

  @override
  String get sourceLabel => 'Live API';

  DriverTrip _mapTrip(api.Trip t) {
    final label = t.deliveredAt != null
        ? 'Delivered ${fmt.friendlyTime(t.deliveredAt)}'
        : 'Updated ${fmt.friendlyTime(t.updatedAt)}';
    return DriverTrip(
      apiId: t.id,
      ref: t.ref,
      origin: t.origin,
      destination: t.destination,
      cargo: t.cargo,
      status: TripStatus.fromApi(t.status),
      vehiclePlate: t.vehiclePlate,
      vehicleModel: t.vehicleModel,
      eta: label,
      dateLabel: fmt.friendlyTime(t.updatedAt).split(',').first,
    );
  }

  int _idOf(DriverTrip trip) {
    final id = trip.apiId;
    if (id == null) throw const ApiException('That trip is not on the server.');
    return id;
  }

  @override
  Future<DriverSnapshot> load() async {
    final sample = await super.load();
    final client = _client();
    final user = _user();

    final trips = [for (final t in await client.trips()) _mapTrip(t)];
    DriverTrip? active;
    for (final t in trips) {
      if (t.isClosed) continue;
      if (active == null || t.status == TripStatus.inTransit) active = t;
    }

    var fuel = <DriverFuelEntry>[];
    var summary = const DriverSummary();
    if (active != null) {
      final detail = await client.tripDetail(_idOf(active));
      fuel = [
        for (final f in detail.fuelLogs)
          DriverFuelEntry(
            when: 'Entry #${f.id}',
            station: '—',
            litres: f.liters,
            amountUgx: f.costUgx,
            odometerKm: f.odometerKm,
            review: 'Submitted',
            reviewTone: Tone.gray,
          ),
      ];
      summary = DriverSummary(
        fuelLitres: fuel.fold<double>(0, (sum, f) => sum + f.litres),
        fuelCostUgx: fuel.fold<int>(0, (sum, f) => sum + f.amountUgx),
      );
    }

    return DriverSnapshot(
      profile: DriverProfile(
        name: user.name,
        driverId: DriverProfile.idLabel(user.id),
        phone: user.phone,
        licenceClass: sample.profile.licenceClass,
        licenceExpiry: sample.profile.licenceExpiry,
        safetyScore: sample.profile.safetyScore,
        base: sample.profile.base,
        vehicleLabel: active == null ? null : '${active.vehiclePlate} · ${active.vehicleModel}',
      ),
      activeTrip: active,
      history: trips,
      fuel: fuel,
      documents: sample.documents,
      messages: sample.messages,
      summary: summary,
      note: 'Live: your trips, status updates, fuel and incident reports use the API. '
          'Documents, messages, licence details and the map are sample data.',
    );
  }

  @override
  List<StatusChoice> statusChoices(DriverTrip trip) {
    final next = fmt.nextStatus(trip.status.apiValue);
    return [
      if (next != null)
        StatusChoice(
          id: next,
          label: fmt.nextStepLabels[trip.status.apiValue] ?? fmt.humanize(next),
          target: TripStatus.fromApi(next),
        ),
      if (!trip.isClosed) const StatusChoice(id: 'delay', label: 'Report a delay', isDelay: true),
    ];
  }

  @override
  Future<void> updateStatus(DriverTrip trip, StatusUpdate update) async {
    final id = _idOf(trip);
    final note = update.noteText;
    if (update.choice.isDelay) {
      await _client().reportIncident(
        id,
        category: 'delay',
        note: note.isEmpty ? 'Delay reported by the driver.' : note,
      );
      return;
    }
    await _client().setStatus(id, update.choice.id, note: note);
  }

  @override
  Future<void> logFuel(DriverTrip trip, FuelRequest request) async {
    await _client().logFuel(
      _idOf(trip),
      liters: request.litres,
      costUgx: request.amountUgx,
      odometerKm: request.odometerKm,
    );
  }

  @override
  Future<void> reportIssue(DriverTrip? trip, IssueRequest request) async {
    if (trip == null) {
      throw const ApiException('There is no active trip to attach this report to.');
    }
    await _client().reportIncident(
      _idOf(trip),
      category: request.category.apiValue,
      note: request.noteText,
    );
  }

  @override
  Future<void> submitProof(DriverTrip trip, DeliveryProof proof) async {
    await _client().setStatus(_idOf(trip), 'delivered', note: proof.noteText);
  }
}
