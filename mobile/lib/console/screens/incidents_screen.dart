import 'package:material_ui/material_ui.dart';

import '../core/access.dart';
import '../models/ops_models.dart';
import '../theme/console_theme.dart';
import '../widgets/access_banner.dart';
import '../widgets/action_button.dart';
import '../widgets/async_view.dart';
import '../widgets/kpi_card.dart';
import '../widgets/page_header.dart';
import '../widgets/section_card.dart';
import '../widgets/status_chip.dart';
import '../widgets/toast.dart';
import 'screen_support.dart';

class IncidentsScreen extends StatelessWidget {
  const IncidentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final console = context.console;
    final level = console.levelFor(ConsoleModule.incidents);
    return DataLoader<IncidentsData>(
      load: console.repository.incidents,
      reloadKey: console.refreshTick,
      builder: (context, data) => _IncidentsBody(data: data, level: level),
    );
  }
}

class _IncidentsBody extends StatelessWidget {
  const _IncidentsBody({required this.data, required this.level});

  final IncidentsData data;
  final AccessLevel level;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    final canReport = level.canManage || level == AccessLevel.report;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          eyebrow: 'Safety',
          title: 'Incidents & Safety',
          subtitle: 'Investigate operational disruptions and protect people and cargo.',
          actions: [
            if (canReport)
              ActionButton(
                label: 'Report incident',
                icon: Icons.add,
                primary: true,
                onPressed: () => showToast(context, 'Incident report form opened'),
              ),
          ],
        ),
        AccessBanner(level: level),
        KpiGrid(stats: data.kpis),
        gap16,
        SectionCard(
          title: 'Incident feed',
          subtitle: 'Latest safety and service exceptions',
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: data.incidents.isEmpty
              ? const EmptyState(
                  title: 'No incidents',
                  message: 'Nothing has been reported.',
                  icon: Icons.verified_outlined,
                )
              : Column(
                  children: [
                    for (var i = 0; i < data.incidents.length; i++) ...[
                      if (i > 0) Divider(color: c.line),
                      _IncidentRow(incident: data.incidents[i]),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _IncidentRow extends StatelessWidget {
  const _IncidentRow({required this.incident});

  final SafetyIncident incident;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    final colors = c.tone(incident.critical ? Tone.red : Tone.amber);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: colors.bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.flag_outlined, size: 16, color: colors.fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${incident.ref} · ${incident.title}',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.text),
                ),
                const SizedBox(height: 3),
                Text(incident.where, style: TextStyle(fontSize: 11, color: c.muted)),
                if (incident.detail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(incident.detail, style: TextStyle(fontSize: 11, color: c.muted)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          StatusChip(label: incident.status.label, tone: incident.status.tone),
        ],
      ),
    );
  }
}
