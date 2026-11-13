import 'package:material_ui/material_ui.dart';

import '../core/access.dart';
import '../models/ops_models.dart';
import '../theme/console_theme.dart';
import '../widgets/access_banner.dart';
import '../widgets/action_button.dart';
import '../widgets/async_view.dart';
import '../widgets/inputs.dart';
import '../widgets/kpi_card.dart';
import '../widgets/layout.dart';
import '../widgets/page_header.dart';
import '../widgets/toast.dart';
import 'screen_support.dart';

const String _allClients = 'All clients';
const String _allRoutes = 'All routes';
const String _allVehicles = 'All vehicles';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final console = context.console;
    final level = console.levelFor(ConsoleModule.reports);
    return DataLoader<ReportsData>(
      load: console.repository.reports,
      reloadKey: console.refreshTick,
      builder: (context, data) => _ReportsBody(data: data, level: level),
    );
  }
}

class _ReportsBody extends StatefulWidget {
  const _ReportsBody({required this.data, required this.level});

  final ReportsData data;
  final AccessLevel level;

  @override
  State<_ReportsBody> createState() => _ReportsBodyState();
}

class _ReportsBodyState extends State<_ReportsBody> {
  late String _range = widget.data.ranges.first;
  String _client = _allClients;
  String _route = _allRoutes;
  String _vehicle = _allVehicles;

  String get _scope {
    final parts = <String>[_range];
    if (_client != _allClients) parts.add(_client);
    if (_route != _allRoutes) parts.add(_route);
    if (_vehicle != _allVehicles) parts.add(_vehicle);
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    final data = widget.data;
    // Limited roles can read reports but not export them.
    final canExport = widget.level != AccessLevel.limited;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          eyebrow: 'Insights',
          title: 'Reports & insights',
          subtitle: 'Operational reporting built for daily decisions and weekly reviews.',
          actions: [
            ActionButton(
              label: 'Scheduled reports',
              icon: Icons.schedule,
              onPressed: () => showToast(context, 'Report schedule settings opened'),
            ),
          ],
        ),
        AccessBanner(level: widget.level),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ConsoleDropdown<String>(
              value: _range,
              items: data.ranges,
              labelOf: (v) => v,
              onChanged: (v) => setState(() => _range = v),
              width: 170,
            ),
            ConsoleDropdown<String>(
              value: _client,
              items: [_allClients, ...data.clients],
              labelOf: (v) => v,
              onChanged: (v) => setState(() => _client = v),
              width: 200,
            ),
            ConsoleDropdown<String>(
              value: _route,
              items: [_allRoutes, ...data.routes],
              labelOf: (v) => v,
              onChanged: (v) => setState(() => _route = v),
              width: 210,
            ),
            ConsoleDropdown<String>(
              value: _vehicle,
              items: [_allVehicles, ...data.vehicles],
              labelOf: (v) => v,
              onChanged: (v) => setState(() => _vehicle = v),
              width: 170,
            ),
          ],
        ),
        gap16,
        AdaptiveGrid(
          minTileWidth: 280,
          maxColumns: 4,
          spacing: 14,
          children: [
            for (final report in data.reports)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c.blueWash,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(kpiIcon(report.icon), size: 19, color: c.blue),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      report.title,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      report.description,
                      style: TextStyle(fontSize: 11.5, height: 1.4, color: c.muted),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        ActionButton(
                          label: 'Preview',
                          compact: true,
                          primary: true,
                          onPressed: () => showToast(
                            context,
                            '${report.title} preview generated ($_scope)',
                          ),
                        ),
                        if (canExport) ...[
                          ActionButton(
                            label: 'Excel',
                            icon: Icons.download,
                            compact: true,
                            onPressed: () => showToast(context, 'Excel export prepared'),
                          ),
                          ActionButton(
                            label: 'PDF',
                            icon: Icons.download,
                            compact: true,
                            onPressed: () => showToast(context, 'PDF export prepared'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
