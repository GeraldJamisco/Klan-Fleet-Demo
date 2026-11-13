import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'models.dart';

/// Holds who is logged in and which server we talk to. Persisted so the driver
/// does not have to log in again every time the app is opened.
class SessionController extends ChangeNotifier {
  static const _kBaseUrl = 'baseUrl';
  static const _kToken = 'token';
  static const _kUser = 'user';

  bool ready = false;
  String baseUrl = defaultBaseUrl();
  String? _token;
  AppUser? user;

  bool get loggedIn => _token != null && user != null;

  final http.Client _http = http.Client();

  ApiClient get api => ApiClient(baseUrl: baseUrl, token: _token, client: _http);

  @override
  void dispose() {
    _http.close();
    super.dispose();
  }

  /// Android emulators reach the host computer at 10.0.2.2; everything else
  /// (Windows, web) can use localhost. A real phone needs the laptop's Wi-Fi IP,
  /// which the user types on the login screen.
  static String defaultBaseUrl() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    baseUrl = prefs.getString(_kBaseUrl) ?? baseUrl;
    _token = prefs.getString(_kToken);
    final rawUser = prefs.getString(_kUser);
    if (rawUser != null) {
      try {
        user = AppUser.fromJson(jsonDecode(rawUser) as Map<String, dynamic>);
      } catch (_) {
        _token = null;
        user = null;
      }
    }
    ready = true;
    notifyListeners();
  }

  Future<void> login({
    required String serverUrl,
    required String phone,
    required String pin,
  }) async {
    final client = ApiClient(baseUrl: serverUrl);
    final json = await client.post('/api/auth/login', {'phone': phone.trim(), 'pin': pin});
    baseUrl = client.baseUrl;
    _token = json['token'] as String;
    user = AppUser.fromJson(json['user'] as Map<String, dynamic>);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBaseUrl, baseUrl);
    await prefs.setString(_kToken, _token!);
    await prefs.setString(_kUser, jsonEncode(user!.toJson()));
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await api.post('/api/auth/logout');
    } catch (_) {
      // Best effort: even if the server is unreachable we still sign out locally.
    }
    await clearLocal();
  }

  /// Also used when the server says our token is no longer valid.
  Future<void> clearLocal() async {
    _token = null;
    user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUser);
    notifyListeners();
  }
}
