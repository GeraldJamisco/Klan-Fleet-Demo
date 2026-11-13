/// UI state of the manager console: who is looking, which module is open and
/// where the data comes from. Holds no Flutter widgets, so it is easy to test.
library;

import 'package:flutter/foundation.dart';

import '../core/access.dart';
import '../data/console_repository.dart';

enum DataSource {
  demo('Demo data'),
  live('Live API');

  const DataSource(this.label);

  final String label;
}

class ConsoleController extends ChangeNotifier {
  ConsoleController({
    required this.actualRole,
    required this.userName,
    required ConsoleRepository demoRepository,
    required ConsoleRepository liveRepository,
  })  : _demo = demoRepository,
        _live = liveRepository;

  /// The signed-in user's real role.
  final ConsoleRole actualRole;
  final String userName;

  final ConsoleRepository _demo;
  final ConsoleRepository _live;

  ConsoleRole? _previewRole;
  ConsoleModule _module = ConsoleModule.overview;
  String? _openTripRef;
  DataSource _source = DataSource.demo;
  int _refreshTick = 0;
  bool _kanban = false;
  String _tripQuery = '';

  /// The role the console currently behaves as. Managers can preview others.
  ConsoleRole get role => _previewRole ?? actualRole;

  bool get isPreviewing => _previewRole != null && _previewRole != actualRole;
  bool get canPreviewRoles => actualRole == ConsoleRole.manager;

  ConsoleModule get module => _module;
  String? get openTripRef => _openTripRef;
  DataSource get source => _source;
  int get refreshTick => _refreshTick;
  bool get kanban => _kanban;
  String get tripQuery => _tripQuery;

  ConsoleRepository get repository => _source == DataSource.live ? _live : _demo;

  List<ConsoleModule> get modules => AccessMatrix.modulesFor(role);

  AccessLevel levelFor(ConsoleModule module) => AccessMatrix.levelFor(role, module);

  /// Changes the open module. Ignored when the current role has no access.
  void go(ConsoleModule target) {
    if (!levelFor(target).hasAccess) return;
    _module = target;
    _openTripRef = null;
    notifyListeners();
  }

  void openTrip(String ref) {
    if (!levelFor(ConsoleModule.trips).hasAccess) return;
    _module = ConsoleModule.trips;
    _openTripRef = ref;
    notifyListeners();
  }

  void closeTrip() {
    _openTripRef = null;
    notifyListeners();
  }

  /// Global search: jumps to the trip list filtered by [query].
  void searchTrips(String query) {
    _tripQuery = query.trim();
    if (levelFor(ConsoleModule.trips).hasAccess) {
      _module = ConsoleModule.trips;
      _openTripRef = null;
    }
    notifyListeners();
  }

  void setTripQuery(String query) {
    if (query == _tripQuery) return;
    _tripQuery = query;
    notifyListeners();
  }

  void toggleKanban() {
    _kanban = !_kanban;
    notifyListeners();
  }

  /// Managers only. Passing null (or their own role) ends the preview.
  void previewAs(ConsoleRole? target) {
    if (!canPreviewRoles) return;
    _previewRole = (target == null || target == actualRole) ? null : target;
    if (!levelFor(_module).hasAccess) {
      _module = ConsoleModule.overview;
      _openTripRef = null;
    }
    notifyListeners();
  }

  void setSource(DataSource value) {
    if (value == _source) return;
    _source = value;
    _refreshTick++;
    notifyListeners();
  }

  /// Makes every screen load its data again.
  void refresh() {
    _refreshTick++;
    notifyListeners();
  }
}
