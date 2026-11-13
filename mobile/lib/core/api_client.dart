import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.status = 0, this.code = 'error'});

  final String message;
  final int status;
  final String code;

  @override
  String toString() => message;
}

/// Thin wrapper over the fleet REST API: adds the bearer token, a timeout and
/// turns every failure into an [ApiException] with a message fit for the UI.
class ApiClient {
  ApiClient({required String baseUrl, this.token, http.Client? client})
      : baseUrl = baseUrl.trim().endsWith('/')
            ? baseUrl.trim().substring(0, baseUrl.trim().length - 1)
            : baseUrl.trim(),
        _client = client ?? http.Client();

  final String baseUrl;
  final String? token;
  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 10);

  Future<Map<String, dynamic>> get(String path) => _send('GET', path);

  Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]) =>
      _send('POST', path, body);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final Uri uri;
    try {
      uri = Uri.parse('$baseUrl$path');
    } on FormatException {
      throw const ApiException('The server address looks wrong.');
    }
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    http.Response response;
    try {
      if (method == 'GET') {
        response = await _client.get(uri, headers: headers).timeout(_timeout);
      } else {
        response = await _client
            .post(uri, headers: headers, body: jsonEncode(body ?? <String, dynamic>{}))
            .timeout(_timeout);
      }
    } on TimeoutException {
      throw const ApiException('The server took too long to answer. Check the address and your connection.');
    } catch (_) {
      throw const ApiException('Could not reach the server. Check the address and that you are on the same network.');
    }

    Map<String, dynamic> decoded = <String, dynamic>{};
    if (response.body.isNotEmpty) {
      try {
        final parsed = jsonDecode(response.body);
        if (parsed is Map<String, dynamic>) decoded = parsed;
      } catch (_) {
        throw ApiException('Unexpected reply from the server (${response.statusCode}).',
            status: response.statusCode);
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) return decoded;

    final error = decoded['error'];
    if (error is Map<String, dynamic>) {
      throw ApiException(
        (error['message'] as String?) ?? 'Request failed (${response.statusCode}).',
        status: response.statusCode,
        code: (error['code'] as String?) ?? 'error',
      );
    }
    throw ApiException('Request failed (${response.statusCode}).', status: response.statusCode);
  }

  // ---------- typed calls used by the screens ----------

  Future<List<Trip>> trips({String? status}) async {
    final query = status == null ? '' : '?status=$status';
    final json = await get('/api/trips$query');
    return (json['trips'] as List<dynamic>)
        .map((e) => Trip.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TripDetail> tripDetail(int id) async =>
      TripDetail.fromJson(await get('/api/trips/$id'));

  Future<void> setStatus(int tripId, String status, {String? note}) async {
    await post('/api/trips/$tripId/status', {
      'status': status,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  Future<void> logFuel(int tripId, {required double liters, required int costUgx, int? odometerKm}) async {
    await post('/api/trips/$tripId/fuel', {
      'liters': liters,
      'costUgx': costUgx,
      if (odometerKm != null) 'odometerKm': odometerKm,
    });
  }

  Future<void> reportIncident(int tripId, {required String category, required String note}) async {
    await post('/api/trips/$tripId/incidents', {'category': category, 'note': note});
  }

  Future<Dashboard> dashboard() async => Dashboard.fromJson(await get('/api/dashboard'));

  Future<(Map<String, int>, List<ErpItem>)> erpStatus() async {
    final json = await get('/api/erp/status');
    final counts = (json['counts'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as num).toInt()));
    final items = (json['recent'] as List<dynamic>)
        .map((e) => ErpItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return (counts, items);
  }

  Future<List<Option>> driverOptions() async {
    final json = await get('/api/drivers');
    return (json['drivers'] as List<dynamic>)
        .map((e) => Option(id: (e['id'] as num).toInt(), label: e['name'] as String))
        .toList();
  }

  Future<List<Option>> vehicleOptions() async {
    final json = await get('/api/vehicles');
    return (json['vehicles'] as List<dynamic>).map((e) {
      final available = e['status'] == 'available';
      return Option(
        id: (e['id'] as num).toInt(),
        label: '${e['plate']} · ${e['model']}${available ? '' : ' (${e['status']})'}',
        available: available,
      );
    }).toList();
  }

  Future<void> createTrip({
    required String origin,
    required String destination,
    required String cargo,
    required int driverId,
    required int vehicleId,
  }) async {
    await post('/api/trips', {
      'origin': origin,
      'destination': destination,
      'cargo': cargo,
      'driverId': driverId,
      'vehicleId': vehicleId,
    });
  }
}
