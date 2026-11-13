/// What the console needs from a back end. Screens only ever talk to this
/// interface, so the demo data and the live API are interchangeable.
library;

import '../models/ops_models.dart';

class PickOption {
  const PickOption({required this.id, required this.label});

  final String id;
  final String label;
}

class NewTripOptions {
  const NewTripOptions({
    required this.clients,
    required this.cargoTypes,
    required this.origins,
    required this.destinations,
    required this.drivers,
    required this.vehicles,
  });

  final List<String> clients;
  final List<String> cargoTypes;
  final List<String> origins;
  final List<String> destinations;
  final List<PickOption> drivers;
  final List<PickOption> vehicles;
}

class NewTripRequest {
  const NewTripRequest({
    required this.client,
    required this.cargoType,
    required this.origin,
    required this.destination,
    required this.driver,
    required this.vehicle,
    required this.departure,
    this.weightTonnes,
    this.notes = '',
  });

  final String client;
  final String cargoType;
  final String origin;
  final String destination;
  final PickOption driver;
  final PickOption vehicle;
  final DateTime departure;
  final double? weightTonnes;
  final String notes;

  /// "FMCG pallets · 18.5T" (or just the cargo type when no weight was given).
  String get cargoLabel {
    final weight = weightTonnes;
    if (weight == null) return cargoType;
    final text = weight == weight.roundToDouble()
        ? weight.round().toString()
        : weight.toStringAsFixed(1);
    return '$cargoType · ${text}T';
  }
}

abstract class ConsoleRepository {
  /// Short name shown in Settings, e.g. "Demo data".
  String get sourceLabel;

  Future<OverviewData> overview();
  Future<List<OpsTrip>> trips();
  Future<TripDetailData> tripDetail(String ref);
  Future<FleetData> fleet();
  Future<DriversData> drivers();
  Future<FuelData> fuel();
  Future<IncidentsData> incidents();
  Future<WarehouseData> warehouse();
  Future<ReportsData> reports();
  Future<ErpData> erp();
  Future<NewTripOptions> newTripOptions();
  Future<OpsTrip> createTrip(NewTripRequest request);
}
