/// UI state of the driver app: which page is open, where data comes from and
/// the loaded snapshot. Holds no widgets, so it is easy to test.
library;

import 'package:flutter/foundation.dart';

import '../data/driver_repository.dart';
import '../models/driver_models.dart';

enum DriverPage {
  home('Home', 'Home'),
  trips('My trips', 'Trips'),
  map('Trip navigation', 'Map'),
  documents('Documents', 'Docs'),
  costs('Fuel & expenses', 'Fuel'),
  messages('Messages', 'Messages'),
  profile('My profile', 'Profile');

  const DriverPage(this.label, this.shortLabel);

  final String label;
  final String shortLabel;
}

enum DriverSource {
  demo('Demo data'),
  live('Live API');

  const DriverSource(this.label);

  final String label;
}

class DriverController extends ChangeNotifier {
  DriverController({
    required this.userName,
    required DriverRepository demoRepository,
    required DriverRepository liveRepository,
  })  : _demo = demoRepository,
        _live = liveRepository;

  final String userName;

  final DriverRepository _demo;
  final DriverRepository _live;

  DriverPage _page = DriverPage.home;
  DriverSource _source = DriverSource.demo;
  int _refreshTick = 0;
  Future<DriverSnapshot>? _snapshot;

  DriverPage get page => _page;
  DriverSource get source => _source;
  int get refreshTick => _refreshTick;

  DriverRepository get repository => _source == DriverSource.live ? _live : _demo;

  /// One load shared by every page; a new one starts after [refresh].
  Future<DriverSnapshot> get snapshot => _snapshot ??= repository.load();

  void go(DriverPage target) {
    if (target == _page) return;
    _page = target;
    notifyListeners();
  }

  void setSource(DriverSource value) {
    if (value == _source) return;
    _source = value;
    refresh();
  }

  /// Makes every page load its data again.
  void refresh() {
    _snapshot = null;
    _refreshTick++;
    notifyListeners();
  }
}
