class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
  });

  final int id;
  final String name;
  final String phone;
  final String role;

  bool get isManager => role == 'manager';

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        phone: json['phone'] as String,
        role: json['role'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'role': role,
      };
}

class Trip {
  const Trip({
    required this.id,
    required this.ref,
    required this.origin,
    required this.destination,
    required this.cargo,
    required this.status,
    required this.driverId,
    required this.driverName,
    required this.vehiclePlate,
    required this.vehicleModel,
    required this.updatedAt,
    this.deliveredAt,
  });

  final int id;
  final String ref;
  final String origin;
  final String destination;
  final String cargo;
  final String status;
  final int driverId;
  final String driverName;
  final String vehiclePlate;
  final String vehicleModel;
  final String updatedAt;
  final String? deliveredAt;

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        id: (json['id'] as num).toInt(),
        ref: json['ref'] as String,
        origin: json['origin'] as String,
        destination: json['destination'] as String,
        cargo: json['cargo'] as String,
        status: json['status'] as String,
        driverId: (json['driverId'] as num).toInt(),
        driverName: json['driverName'] as String,
        vehiclePlate: json['vehiclePlate'] as String,
        vehicleModel: json['vehicleModel'] as String,
        updatedAt: json['updatedAt'] as String,
        deliveredAt: json['deliveredAt'] as String?,
      );
}

class TripEvent {
  const TripEvent({required this.status, required this.createdAt, this.note});

  final String status;
  final String createdAt;
  final String? note;

  factory TripEvent.fromJson(Map<String, dynamic> json) => TripEvent(
        status: json['status'] as String,
        createdAt: json['createdAt'] as String,
        note: json['note'] as String?,
      );
}

class FuelLog {
  const FuelLog({
    required this.id,
    required this.liters,
    required this.costUgx,
    this.odometerKm,
  });

  final int id;
  final double liters;
  final int costUgx;
  final int? odometerKm;

  factory FuelLog.fromJson(Map<String, dynamic> json) => FuelLog(
        id: (json['id'] as num).toInt(),
        liters: (json['liters'] as num).toDouble(),
        costUgx: (json['costUgx'] as num).toInt(),
        odometerKm: (json['odometerKm'] as num?)?.toInt(),
      );
}

class Incident {
  const Incident({
    required this.id,
    required this.category,
    required this.note,
    required this.createdAt,
  });

  final int id;
  final String category;
  final String note;
  final String createdAt;

  factory Incident.fromJson(Map<String, dynamic> json) => Incident(
        id: (json['id'] as num).toInt(),
        category: json['category'] as String,
        note: json['note'] as String,
        createdAt: json['createdAt'] as String,
      );
}

class TripDetail {
  const TripDetail({
    required this.trip,
    required this.events,
    required this.fuelLogs,
    required this.incidents,
  });

  final Trip trip;
  final List<TripEvent> events;
  final List<FuelLog> fuelLogs;
  final List<Incident> incidents;

  factory TripDetail.fromJson(Map<String, dynamic> json) => TripDetail(
        trip: Trip.fromJson(json['trip'] as Map<String, dynamic>),
        events: (json['events'] as List<dynamic>)
            .map((e) => TripEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
        fuelLogs: (json['fuelLogs'] as List<dynamic>)
            .map((e) => FuelLog.fromJson(e as Map<String, dynamic>))
            .toList(),
        incidents: (json['incidents'] as List<dynamic>)
            .map((e) => Incident.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// A driver or vehicle choice for the "new trip" form.
class Option {
  const Option({required this.id, required this.label, this.available = true});

  final int id;
  final String label;
  final bool available;
}

class Dashboard {
  const Dashboard({
    required this.tripsByStatus,
    required this.fuelCostUgx,
    required this.fuelLiters,
    required this.incidents,
    required this.fleetTotal,
    required this.fleetAvailable,
    required this.erpPending,
    required this.erpSynced,
    required this.erpFailed,
  });

  final Map<String, int> tripsByStatus;
  final int fuelCostUgx;
  final double fuelLiters;
  final int incidents;
  final int fleetTotal;
  final int fleetAvailable;
  final int erpPending;
  final int erpSynced;
  final int erpFailed;

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    final trips = (json['trips'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as num).toInt()));
    final fuel = json['fuel'] as Map<String, dynamic>;
    final fleet = json['fleet'] as Map<String, dynamic>;
    final erp = json['erp'] as Map<String, dynamic>;
    return Dashboard(
      tripsByStatus: trips,
      fuelCostUgx: (fuel['totalCostUgx'] as num).toInt(),
      fuelLiters: (fuel['totalLiters'] as num).toDouble(),
      incidents: (json['incidents'] as num).toInt(),
      fleetTotal: (fleet['total'] as num).toInt(),
      fleetAvailable: (fleet['available'] as num).toInt(),
      erpPending: (erp['pending'] as num).toInt(),
      erpSynced: (erp['synced'] as num).toInt(),
      erpFailed: (erp['failed'] as num).toInt(),
    );
  }
}

class ErpItem {
  const ErpItem({
    required this.id,
    required this.eventType,
    required this.status,
    required this.attempts,
    required this.createdAt,
    this.lastError,
  });

  final int id;
  final String eventType;
  final String status;
  final int attempts;
  final String createdAt;
  final String? lastError;

  factory ErpItem.fromJson(Map<String, dynamic> json) => ErpItem(
        id: (json['id'] as num).toInt(),
        eventType: json['eventType'] as String,
        status: json['status'] as String,
        attempts: (json['attempts'] as num).toInt(),
        createdAt: json['createdAt'] as String,
        lastError: json['lastError'] as String?,
      );
}
