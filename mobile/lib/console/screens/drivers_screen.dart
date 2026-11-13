import 'package:material_ui/material_ui.dart';

import '../core/access.dart';
import '../models/ops_models.dart';
import '../widgets/access_banner.dart';
import '../widgets/action_button.dart';
import '../widgets/async_view.dart';
import '../widgets/console_table.dart';
import '../widgets/inputs.dart';
import '../widgets/kpi_card.dart';
import '../widgets/page_header.dart';
import '../widgets/section_card.dart';
import '../widgets/toast.dart';
import 'screen_support.dart';

const String _allClasses = 'All licence classes';
const String _allStatuses = 'All statuses';

class DriversScreen extends StatelessWidget {
  const DriversScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final console = context.console;
    final level = console.levelFor(ConsoleModule.drivers);
    return DataLoader<DriversData>(
      load: console.repository.drivers,
      reloadKey: console.refreshTick,
      builder: (context, data) => _DriversBody(data: data, level: level),
    );
  }
}

class _DriversBody extends StatefulWidget {
  const _DriversBody({required this.data, required this.level});

  final DriversData data;
  final AccessLevel level;

  @override
  State<_DriversBody> createState() => _DriversBodyState();
}

class _DriversBodyState extends State<_DriversBody> {
  String _query = '';
  String _licence = _allClasses;
  String _status = _allStatuses;

  @override
  void didUpdateWidget(_DriversBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_licence != _allClasses &&
        !widget.data.drivers.any((d) => d.licenceClass == _licence)) {
      _licence = _allClasses;
    }
  }

  @override
  Widget build(BuildContext context) {
    final classes = <String>{for (final d in widget.data.drivers) d.licenceClass}.toList()..sort();
    final query = _query.trim().toLowerCase();
    final shown = [
      for (final d in widget.data.drivers)
        if ((query.isEmpty || d.searchText.contains(query)) &&
            (_licence == _allClasses || d.licenceClass == _licence) &&
            (_status == _allStatuses || d.availability == _status))
          d,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          eyebrow: 'People',
          title: 'Drivers',
          subtitle: 'People, licences and driving performance.',
          actions: [
            if (canChange(widget.level))
              ActionButton(
                label: 'Add driver',
                icon: Icons.add,
                primary: true,
                onPressed: () => showToast(context, 'Driver invitation form opened'),
              ),
          ],
        ),
        AccessBanner(level: widget.level),
        KpiGrid(stats: widget.data.kpis),
        gap16,
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
                      value: _query,
                      onChanged: (v) => setState(() => _query = v),
                      hint: 'Search driver name or phone…',
                      width: 260,
                    ),
                    ConsoleDropdown<String>(
                      value: _licence,
                      items: [_allClasses, ...classes],
                      labelOf: (v) => v,
                      onChanged: (v) => setState(() => _licence = v),
                      width: 190,
                    ),
                    ConsoleDropdown<String>(
                      value: _status,
                      items: const [_allStatuses, 'On trip', 'Available'],
                      labelOf: (v) => v,
                      onChanged: (v) => setState(() => _status = v),
                      width: 160,
                    ),
                  ],
                ),
              ),
              if (shown.isEmpty)
                const EmptyState(
                  title: 'No drivers match',
                  message: 'Try a different search or clear the filters.',
                  icon: Icons.search_off,
                )
              else
                ConsoleTable(
                  columns: const [
                    TableCol('Driver', 150),
                    TableCol('Phone', 140),
                    TableCol('Licence', 150),
                    TableCol('Current trip', 110),
                    TableCol('Safety score', 100),
                    TableCol('On-time', 80),
                    TableCol('Trips this month', 120),
                    TableCol('Incidents', 90),
                  ],
                  rows: [
                    for (final d in shown)
                      [
                        CellText(d.name, bold: true),
                        CellText(d.phone),
                        CellText('${d.licenceClass} · ${d.licenceExpiry}'),
                        CellText(d.currentTripRef ?? '—', muted: d.currentTripRef == null),
                        CellText('${d.safetyScore}/100', bold: true),
                        CellText('${d.onTimePercent}%'),
                        CellText('${d.tripsThisMonth}'),
                        CellText('${d.incidents}'),
                      ],
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
