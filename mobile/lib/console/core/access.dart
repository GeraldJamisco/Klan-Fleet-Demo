/// Roles, modules and the permission matrix for the manager console.
/// Pure Dart (no Flutter imports) so the rules are easy to unit test.
library;

enum ConsoleRole {
  manager('Manager'),
  dispatcher('Dispatcher'),
  fleet('Fleet / Maintenance officer'),
  finance('Finance officer'),
  warehouse('Warehouse officer'),
  driver('Driver');

  const ConsoleRole(this.label);

  final String label;

  /// Maps the role string the API sends. Anything unknown is treated as the
  /// most restricted role.
  static ConsoleRole fromApi(String? value) {
    switch (value) {
      case 'manager':
        return ConsoleRole.manager;
      case 'dispatcher':
        return ConsoleRole.dispatcher;
      case 'fleet':
        return ConsoleRole.fleet;
      case 'finance':
        return ConsoleRole.finance;
      case 'warehouse':
        return ConsoleRole.warehouse;
      default:
        return ConsoleRole.driver;
    }
  }
}

enum ConsoleModule {
  overview('Overview', 'Overview'),
  trips('Trips & Dispatch', 'Trips'),
  fleet('Fleet', 'Fleet'),
  drivers('Drivers', 'Drivers'),
  fuel('Fuel & Costs', 'Fuel'),
  incidents('Incidents & Safety', 'Safety'),
  warehouse('Warehouse', 'Depot'),
  reports('Reports', 'Reports'),
  erp('ERP Sync', 'ERP'),
  settings('Settings & Roles', 'Settings');

  const ConsoleModule(this.label, this.shortLabel);

  final String label;
  final String shortLabel;
}

enum AccessLevel {
  none('—'),
  view('View'),
  limited('Limited'),
  personal('Personal'),
  assigned('Assigned'),
  submit('Submit'),
  report('Report'),
  full('Full');

  const AccessLevel(this.label);

  final String label;

  bool get hasAccess => this != AccessLevel.none;

  /// Only full access may create or change records.
  bool get canManage => this == AccessLevel.full;
}

class AccessMatrix {
  const AccessMatrix._();

  /// Column order of every row in [_levels]: the same as [ConsoleRole.values].
  static const Map<ConsoleModule, List<AccessLevel>> _levels = {
    ConsoleModule.overview: [
      AccessLevel.full, AccessLevel.full, AccessLevel.full,
      AccessLevel.full, AccessLevel.limited, AccessLevel.personal,
    ],
    ConsoleModule.trips: [
      AccessLevel.full, AccessLevel.full, AccessLevel.view,
      AccessLevel.view, AccessLevel.limited, AccessLevel.assigned,
    ],
    ConsoleModule.fleet: [
      AccessLevel.full, AccessLevel.view, AccessLevel.full,
      AccessLevel.view, AccessLevel.none, AccessLevel.assigned,
    ],
    ConsoleModule.drivers: [
      AccessLevel.full, AccessLevel.full, AccessLevel.full,
      AccessLevel.view, AccessLevel.none, AccessLevel.personal,
    ],
    ConsoleModule.fuel: [
      AccessLevel.full, AccessLevel.limited, AccessLevel.view,
      AccessLevel.full, AccessLevel.none, AccessLevel.submit,
    ],
    ConsoleModule.incidents: [
      AccessLevel.full, AccessLevel.full, AccessLevel.full,
      AccessLevel.view, AccessLevel.limited, AccessLevel.report,
    ],
    ConsoleModule.warehouse: [
      AccessLevel.full, AccessLevel.limited, AccessLevel.view,
      AccessLevel.view, AccessLevel.full, AccessLevel.none,
    ],
    ConsoleModule.reports: [
      AccessLevel.full, AccessLevel.limited, AccessLevel.limited,
      AccessLevel.full, AccessLevel.limited, AccessLevel.none,
    ],
    ConsoleModule.erp: [
      AccessLevel.full, AccessLevel.none, AccessLevel.view,
      AccessLevel.view, AccessLevel.none, AccessLevel.none,
    ],
    ConsoleModule.settings: [
      AccessLevel.full, AccessLevel.none, AccessLevel.none,
      AccessLevel.none, AccessLevel.none, AccessLevel.none,
    ],
  };

  static AccessLevel levelFor(ConsoleRole role, ConsoleModule module) =>
      _levels[module]![role.index];

  /// Modules the role can open, in navigation order.
  static List<ConsoleModule> modulesFor(ConsoleRole role) => [
        for (final module in ConsoleModule.values)
          if (levelFor(role, module).hasAccess) module,
      ];

  /// Order used to pick the first destinations of the phone navigation bar.
  static const List<ConsoleModule> phonePriority = [
    ConsoleModule.overview,
    ConsoleModule.trips,
    ConsoleModule.fleet,
    ConsoleModule.reports,
    ConsoleModule.erp,
    ConsoleModule.drivers,
    ConsoleModule.fuel,
    ConsoleModule.incidents,
    ConsoleModule.warehouse,
    ConsoleModule.settings,
  ];

  static List<ConsoleModule> phoneModulesFor(ConsoleRole role) {
    final allowed = modulesFor(role).toSet();
    return [for (final m in phonePriority) if (allowed.contains(m)) m];
  }
}
