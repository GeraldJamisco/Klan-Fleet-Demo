import 'package:material_ui/material_ui.dart';

import '../core/access.dart';

IconData moduleIcon(ConsoleModule module) {
  switch (module) {
    case ConsoleModule.overview:
      return Icons.dashboard_outlined;
    case ConsoleModule.trips:
      return Icons.swap_horiz;
    case ConsoleModule.fleet:
      return Icons.local_shipping_outlined;
    case ConsoleModule.drivers:
      return Icons.badge_outlined;
    case ConsoleModule.fuel:
      return Icons.local_gas_station_outlined;
    case ConsoleModule.incidents:
      return Icons.flag_outlined;
    case ConsoleModule.warehouse:
      return Icons.warehouse_outlined;
    case ConsoleModule.reports:
      return Icons.bar_chart;
    case ConsoleModule.erp:
      return Icons.sync;
    case ConsoleModule.settings:
      return Icons.settings_outlined;
  }
}
