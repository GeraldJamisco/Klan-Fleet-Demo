/// API-ready data models for the driver app. Pure Dart, so they are easy to
/// unit test. Every entity has `fromJson` / `toJson`.
library;

import '../../console/models/ops_models.dart' show Tone, TripStatus;

class DriverProfile {
  const DriverProfile({
    required this.name,
    required this.driverId,
    required this.phone,
    required this.licenceClass,
    required this.licenceExpiry,
    required this.safetyScore,
    required this.base,
    this.vehicleLabel,
  });

  final String name;
  final String driverId;
  final String phone;
  final String licenceClass;
  final String licenceExpiry;
  final int safetyScore;
  final String base;
  final String? vehicleLabel;

  String get firstName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.first.isEmpty ? name : parts.first;
  }

  /// "DRV-004" from the numeric API id 4.
  static String idLabel(int id) => 'DRV-${id.toString().padLeft(3, '0')}';

  factory DriverProfile.fromJson(Map<String, dynamic> json) => DriverProfile(
        name: json['name'] as String,
        driverId: json['driverId'] as String,
        phone: (json['phone'] as String?) ?? '',
        licenceClass: (json['licenceClass'] as String?) ?? '—',
        licenceExpiry: (json['licenceExpiry'] as String?) ?? '—',
        safetyScore: (json['safetyScore'] as num?)?.toInt() ?? 0,
        base: (json['base'] as String?) ?? '—',
        vehicleLabel: json['vehicleLabel'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'driverId': driverId,
        'phone': phone,
        'licenceClass': licenceClass,
        'licenceExpiry': licenceExpiry,
        'safetyScore': safetyScore,
        'base': base,
        'vehicleLabel': vehicleLabel,
      };
}

class DriverTrip {
  const DriverTrip({
    required this.ref,
    required this.origin,
    required this.destination,
    required this.cargo,
    required this.status,
    required this.vehiclePlate,
    this.client = '—',
    this.scheduled = '—',
    this.eta = '—',
    this.distanceKm,
    this.vehicleModel = '',
    this.dateLabel = '',
    this.apiId,
  });

  final String ref;
  final String origin;
  final String destination;
  final String cargo;
  final TripStatus status;
  final String vehiclePlate;
  final String client;
  final String scheduled;
  final String eta;
  final int? distanceKm;
  final String vehicleModel;

  /// "24 Oct", shown in the history table.
  final String dateLabel;

  /// Numeric id on the live API, when the trip came from there.
  final int? apiId;

  String get route => '$origin → $destination';

  bool get isClosed => status == TripStatus.delivered || status == TripStatus.cancelled;

  /// Rough share of the journey done, used by the progress bar.
  double get progress {
    switch (status) {
      case TripStatus.assigned:
        return 0.03;
      case TripStatus.pickedUp:
        return 0.15;
      case TripStatus.inTransit:
      case TripStatus.delayed:
        return 0.63;
      case TripStatus.delivered:
        return 1;
      case TripStatus.cancelled:
        return 0;
    }
  }

  DriverTrip copyWith({TripStatus? status, String? eta}) => DriverTrip(
        ref: ref,
        origin: origin,
        destination: destination,
        cargo: cargo,
        status: status ?? this.status,
        vehiclePlate: vehiclePlate,
        client: client,
        scheduled: scheduled,
        eta: eta ?? this.eta,
        distanceKm: distanceKm,
        vehicleModel: vehicleModel,
        dateLabel: dateLabel,
        apiId: apiId,
      );

  factory DriverTrip.fromJson(Map<String, dynamic> json) => DriverTrip(
        ref: json['ref'] as String,
        origin: json['origin'] as String,
        destination: json['destination'] as String,
        cargo: json['cargo'] as String,
        status: TripStatus.fromApi(json['status'] as String?),
        vehiclePlate: json['vehiclePlate'] as String,
        client: (json['client'] as String?) ?? '—',
        scheduled: (json['scheduled'] as String?) ?? '—',
        eta: (json['eta'] as String?) ?? '—',
        distanceKm: (json['distanceKm'] as num?)?.toInt(),
        vehicleModel: (json['vehicleModel'] as String?) ?? '',
        dateLabel: (json['dateLabel'] as String?) ?? '',
        apiId: (json['id'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        if (apiId != null) 'id': apiId,
        'ref': ref,
        'origin': origin,
        'destination': destination,
        'cargo': cargo,
        'status': status.apiValue,
        'vehiclePlate': vehiclePlate,
        'client': client,
        'scheduled': scheduled,
        'eta': eta,
        'distanceKm': distanceKm,
        'vehicleModel': vehicleModel,
        'dateLabel': dateLabel,
      };
}

class DriverFuelEntry {
  const DriverFuelEntry({
    required this.when,
    required this.station,
    required this.litres,
    required this.amountUgx,
    required this.review,
    this.odometerKm,
    this.reviewTone = Tone.gray,
  });

  final String when;
  final String station;
  final double litres;
  final int amountUgx;
  final int? odometerKm;

  /// "Approved", "Submitted"…
  final String review;
  final Tone reviewTone;

  factory DriverFuelEntry.fromJson(Map<String, dynamic> json) => DriverFuelEntry(
        when: (json['when'] as String?) ?? '—',
        station: (json['station'] as String?) ?? '—',
        litres: (json['litres'] as num).toDouble(),
        amountUgx: (json['amountUgx'] as num).toInt(),
        odometerKm: (json['odometerKm'] as num?)?.toInt(),
        review: (json['review'] as String?) ?? 'Submitted',
        reviewTone: json['review'] == 'Approved' ? Tone.green : Tone.gray,
      );

  Map<String, dynamic> toJson() => {
        'when': when,
        'station': station,
        'litres': litres,
        'amountUgx': amountUgx,
        'odometerKm': odometerKm,
        'review': review,
      };
}

enum DocumentState {
  available('Available', Tone.green),
  pending('Pending', Tone.amber);

  const DocumentState(this.label, this.tone);

  final String label;
  final Tone tone;
}

class DriverDocument {
  const DriverDocument({required this.title, required this.detail, required this.state});

  final String title;
  final String detail;
  final DocumentState state;

  factory DriverDocument.fromJson(Map<String, dynamic> json) => DriverDocument(
        title: json['title'] as String,
        detail: (json['detail'] as String?) ?? '',
        state: json['state'] == 'pending' ? DocumentState.pending : DocumentState.available,
      );

  Map<String, dynamic> toJson() => {'title': title, 'detail': detail, 'state': state.name};
}

class DriverMessage {
  const DriverMessage({
    required this.sender,
    required this.title,
    required this.body,
    required this.time,
    this.unread = false,
    this.kind = 'mail',
  });

  final String sender;
  final String title;
  final String body;
  final String time;
  final bool unread;

  /// `mail`, `warning` or `check`; resolved to an icon by the UI.
  final String kind;

  factory DriverMessage.fromJson(Map<String, dynamic> json) => DriverMessage(
        sender: json['sender'] as String,
        title: json['title'] as String,
        body: (json['body'] as String?) ?? '',
        time: (json['time'] as String?) ?? '',
        unread: (json['unread'] as bool?) ?? false,
        kind: (json['kind'] as String?) ?? 'mail',
      );

  Map<String, dynamic> toJson() => {
        'sender': sender,
        'title': title,
        'body': body,
        'time': time,
        'unread': unread,
        'kind': kind,
      };
}

class DriverSummary {
  const DriverSummary({this.distanceKm, this.fuelLitres, this.drivingTime, this.fuelCostUgx, this.kmPerLitre});

  final int? distanceKm;
  final double? fuelLitres;
  final String? drivingTime;
  final int? fuelCostUgx;
  final double? kmPerLitre;
}

class DriverSnapshot {
  const DriverSnapshot({
    required this.profile,
    required this.history,
    required this.fuel,
    required this.documents,
    required this.messages,
    required this.summary,
    this.activeTrip,
    this.note,
  });

  final DriverProfile profile;

  /// The trip being driven now, if any.
  final DriverTrip? activeTrip;

  /// Every trip, newest first (includes the active one).
  final List<DriverTrip> history;
  final List<DriverFuelEntry> fuel;
  final List<DriverDocument> documents;
  final List<DriverMessage> messages;
  final DriverSummary summary;

  /// Shown above the pages when part of the data is sample data.
  final String? note;

  int get unreadMessages => messages.where((m) => m.unread).length;

  int get readyDocuments => documents.where((d) => d.state == DocumentState.available).length;
}
