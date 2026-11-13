/// What the driver app needs from a back end. Screens only talk to this
/// interface, so demo data and the live API are interchangeable.
library;

import '../../console/models/ops_models.dart' show TripStatus;
import '../models/driver_models.dart';

/// One option in the "Update trip status" form.
class StatusChoice {
  const StatusChoice({required this.id, required this.label, this.target, this.isDelay = false});

  final String id;
  final String label;

  /// The trip status this option moves the trip to. Null means "location
  /// update only" (the status stays the same).
  final TripStatus? target;

  /// Reports a delay to dispatch instead of changing the status.
  final bool isDelay;
}

class StatusUpdate {
  const StatusUpdate({required this.choice, this.location = '', this.notes = ''});

  final StatusChoice choice;
  final String location;
  final String notes;

  /// "Location: Malaba. Queue at the border." (empty when both are empty).
  String get noteText {
    final parts = <String>[
      if (location.trim().isNotEmpty) 'Location: ${location.trim()}.',
      if (notes.trim().isNotEmpty) notes.trim(),
    ];
    return parts.join(' ');
  }
}

class FuelRequest {
  const FuelRequest({
    required this.station,
    required this.litres,
    required this.amountUgx,
    this.odometerKm,
    this.receipt = '',
  });

  final String station;
  final double litres;
  final int amountUgx;
  final int? odometerKm;
  final String receipt;
}

enum IssueCategory {
  breakdown('Vehicle breakdown', 'breakdown'),
  roadHazard('Road hazard', 'other'),
  accident('Accident', 'accident'),
  cargoDamage('Cargo damage', 'cargo_damage'),
  delay('Delay / border queue', 'delay'),
  other('Other', 'other');

  const IssueCategory(this.label, this.apiValue);

  final String label;

  /// One of the categories the API accepts.
  final String apiValue;
}

enum IssueSeverity {
  low('Low'),
  medium('Medium'),
  high('High · Needs urgent attention');

  const IssueSeverity(this.label);

  final String label;
}

class IssueRequest {
  const IssueRequest({
    required this.category,
    required this.severity,
    required this.description,
    this.location = '',
  });

  final IssueCategory category;
  final IssueSeverity severity;
  final String description;
  final String location;

  /// The API stores one free-text note, so severity and place go into it.
  String get noteText {
    final parts = <String>[
      '[${severity.name.toUpperCase()}]',
      if (location.trim().isNotEmpty) 'Location: ${location.trim()}.',
      description.trim(),
    ];
    return parts.join(' ');
  }
}

enum DeliveryConfirmation {
  full('Receiver accepted full delivery'),
  partial('Partial delivery / discrepancy reported');

  const DeliveryConfirmation(this.label);

  final String label;
}

class DeliveryProof {
  const DeliveryProof({required this.receiver, required this.confirmation, this.notes = ''});

  final String receiver;
  final DeliveryConfirmation confirmation;
  final String notes;

  String get noteText {
    final parts = <String>[
      'Proof of delivery. Received by ${receiver.trim()}.',
      confirmation.label,
      if (notes.trim().isNotEmpty) notes.trim(),
    ];
    return '${parts.join('. ')}.';
  }
}

abstract class DriverRepository {
  /// Short name shown on the profile page, e.g. "Demo data".
  String get sourceLabel;

  Future<DriverSnapshot> load();

  /// The options the status form offers for [trip].
  List<StatusChoice> statusChoices(DriverTrip trip);

  Future<void> updateStatus(DriverTrip trip, StatusUpdate update);
  Future<void> logFuel(DriverTrip trip, FuelRequest request);
  Future<void> reportIssue(DriverTrip? trip, IssueRequest request);
  Future<void> submitProof(DriverTrip trip, DeliveryProof proof);
}
