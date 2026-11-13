import 'package:material_ui/material_ui.dart';

import '../core/access.dart';
import '../models/ops_models.dart';
import '../state/console_controller.dart';
import '../theme/console_theme.dart';
import '../widgets/access_banner.dart';
import '../widgets/action_button.dart';
import '../widgets/async_view.dart';
import '../widgets/console_table.dart';
import '../widgets/inputs.dart';
import '../widgets/layout.dart';
import '../widgets/page_header.dart';
import '../widgets/section_card.dart';
import '../widgets/status_chip.dart';
import '../widgets/toast.dart';
import 'new_trip_dialog.dart';
import 'screen_support.dart';

const String _allStatuses = 'All statuses';
const String _allRoutes = 'All routes';
const String _allDrivers = 'All drivers';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final console = context.console;
    return DataLoader<List<OpsTrip>>(
      load: console.repository.trips,
      reloadKey: console.refreshTick,
      builder: (context, trips) => _TripsBody(trips: trips, console: console),
    );
  }
}

class _TripsBody extends StatefulWidget {
  const _TripsBody({required this.trips, required this.console});

  final List<OpsTrip> trips;
  final ConsoleController console;

  @override
  State<_TripsBody> createState() => _TripsBodyState();
}

class _TripsBodyState extends State<_TripsBody> {
  String _status = _allStatuses;
  String _route = _allRoutes;
  String _driver = _allDrivers;

  @override
  void didUpdateWidget(_TripsBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Fresh data may no longer contain the chosen route or driver.
    if (_route != _allRoutes && !widget.trips.any((t) => t.route == _route)) {
      _route = _allRoutes;
    }
    if (_driver != _allDrivers && !widget.trips.any((t) => t.driverName == _driver)) {
      _driver = _allDrivers;
    }
  }

  List<OpsTrip> get _filtered {
    final query = widget.console.tripQuery.trim().toLowerCase();
    return [
      for (final t in widget.trips)
        if ((query.isEmpty || t.searchText.contains(query)) &&
            (_status == _allStatuses || t.status.label == _status) &&
            (_route == _allRoutes || t.route == _route) &&
            (_driver == _allDrivers || t.driverName == _driver))
          t,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final console = widget.console;
    final c = context.cc;
    final level = console.levelFor(ConsoleModule.trips);
    final routes = <String>{for (final t in widget.trips) t.route}.toList()..sort();
    final drivers = <String>{for (final t in widget.trips) t.driverName}.toList()..sort();
    final shown = _filtered;
    final phone = isPhoneWidth(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          eyebrow: 'Operations',
          title: 'Trips & Dispatch',
          subtitle: 'Plan, assign and monitor every movement across your network.',
          actions: [
            ActionButton(
              label: console.kanban ? 'List view' : 'Kanban view',
              icon: console.kanban ? Icons.view_list_outlined : Icons.view_kanban_outlined,
              onPressed: console.toggleKanban,
            ),
            if (canChange(level))
              ActionButton(
                label: 'New trip',
                icon: Icons.add,
                primary: true,
                onPressed: () => showNewTripDialog(context, console),
              ),
          ],
        ),
        AccessBanner(level: level),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ConsoleSearchField(
                      value: console.tripQuery,
                      onChanged: console.setTripQuery,
                      hint: 'Search trip, client, route…',
                      width: phone ? double.infinity : 260,
                    ),
                    ConsoleDropdown<String>(
                      value: _status,
                      items: [_allStatuses, for (final s in TripStatus.values) s.label],
                      labelOf: (v) => v,
                      onChanged: (v) => setState(() => _status = v),
                      width: phone ? 150 : 160,
                    ),
                    ConsoleDropdown<String>(
                      value: _route,
                      items: [_allRoutes, ...routes],
                      labelOf: (v) => v,
                      onChanged: (v) => setState(() => _route = v),
                      width: phone ? 170 : 200,
                    ),
                    ConsoleDropdown<String>(
                      value: _driver,
                      items: [_allDrivers, ...drivers],
                      labelOf: (v) => v,
                      onChanged: (v) => setState(() => _driver = v),
                      width: phone ? 150 : 170,
                    ),
                    ActionButton(
                      label: 'Save view',
                      icon: Icons.star_outline,
                      onPressed: () => showToast(context, 'Filters saved as “My active trips”'),
                    ),
                  ],
                ),
              ),
              if (shown.isEmpty)
                const EmptyState(
                  title: 'No trips match',
                  message: 'Try a different search or clear the filters.',
                  icon: Icons.search_off,
                )
              else if (console.kanban)
                _Kanban(trips: shown, onOpen: console.openTrip)
              else if (phone)
                _MobileList(trips: shown, onOpen: console.openTrip)
              else
                _TripTable(trips: shown, onOpen: console.openTrip),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
                child: Text(
                  'Showing ${shown.length} of ${widget.trips.length} trips',
                  style: TextStyle(fontSize: 11, color: c.muted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TripTable extends StatelessWidget {
  const _TripTable({required this.trips, required this.onOpen});

  final List<OpsTrip> trips;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return ConsoleTable(
      columns: const [
        TableCol('Trip reference', 112),
        TableCol('Client', 160),
        TableCol('Route', 190),
        TableCol('Cargo', 140),
        TableCol('Driver / vehicle', 150),
        TableCol('Status', 120),
        TableCol('ETA', 130),
        TableCol('', 90),
      ],
      rows: [
        for (final t in trips)
          [
            CellText(t.ref, bold: true),
            CellText(t.client),
            CellText(t.route),
            CellText(t.cargo),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CellText(t.driverName),
                CellText(t.vehiclePlate, muted: true),
              ],
            ),
            StatusChip.trip(t.status),
            CellText(t.eta),
            ActionButton(label: 'Open', compact: true, onPressed: () => onOpen(t.ref)),
          ],
      ],
    );
  }
}

class _MobileList extends StatelessWidget {
  const _MobileList({required this.trips, required this.onOpen});

  final List<OpsTrip> trips;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    return Column(
      children: [
        for (final t in trips)
          InkWell(
            onTap: () => onOpen(t.ref),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.ref,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text),
                        ),
                      ),
                      StatusChip.trip(t.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('${t.route} · ${t.cargo}', style: TextStyle(fontSize: 12, color: c.text)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(t.client, style: TextStyle(fontSize: 11, color: c.muted)),
                      ),
                      Text(t.eta, style: TextStyle(fontSize: 11, color: c.muted)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${t.driverName} · ${t.vehiclePlate}',
                    style: TextStyle(fontSize: 11, color: c.muted),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Kanban extends StatelessWidget {
  const _Kanban({required this.trips, required this.onOpen});

  final List<OpsTrip> trips;
  final ValueChanged<String> onOpen;

  static const List<TripStatus> _columns = [
    TripStatus.assigned,
    TripStatus.pickedUp,
    TripStatus.inTransit,
    TripStatus.delayed,
    TripStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final status in _columns)
            Container(
              width: 245,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            status.label,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.text),
                          ),
                        ),
                        Text(
                          '${trips.where((t) => t.status == status).length}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.muted),
                        ),
                      ],
                    ),
                  ),
                  for (final t in trips.where((t) => t.status == status).take(6))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => onOpen(t.ref),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: c.line),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.ref,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.text),
                                ),
                                const SizedBox(height: 4),
                                Text(t.client, style: TextStyle(fontSize: 11.5, color: c.text)),
                                const SizedBox(height: 2),
                                Text(t.route, style: TextStyle(fontSize: 11, color: c.muted)),
                                const SizedBox(height: 6),
                                Text(
                                  '${t.driverName} · ${t.vehiclePlate}',
                                  style: TextStyle(fontSize: 11, color: c.muted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
