import 'package:material_ui/material_ui.dart';

import '../core/access.dart';
import '../core/formatters.dart';
import '../models/ops_models.dart';
import '../state/console_controller.dart';
import '../theme/console_theme.dart';
import '../widgets/access_banner.dart';
import '../widgets/action_button.dart';
import '../widgets/async_view.dart';
import '../widgets/attention_tile.dart';
import '../widgets/charts.dart';
import '../widgets/fleet_map.dart';
import '../widgets/kpi_card.dart';
import '../widgets/layout.dart';
import '../widgets/page_header.dart';
import '../widgets/section_card.dart';
import '../widgets/status_chip.dart';
import '../widgets/toast.dart';
import 'new_trip_dialog.dart';
import 'screen_support.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final console = context.console;
    return DataLoader<OverviewData>(
      load: console.repository.overview,
      reloadKey: console.refreshTick,
      builder: (context, data) => _OverviewBody(data: data, console: console),
    );
  }
}

class _OverviewBody extends StatelessWidget {
  const _OverviewBody({required this.data, required this.console});

  final OverviewData data;
  final ConsoleController console;

  void _openAttention(BuildContext context, AttentionItem item) {
    if (console.levelFor(item.target).hasAccess) {
      console.go(item.target);
    } else {
      showToast(context, 'Your role cannot open ${item.target.label}.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    final level = console.levelFor(ConsoleModule.overview);
    final canCreate = canChange(console.levelFor(ConsoleModule.trips));
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          eyebrow: longDate(now),
          title: '${greetingFor(now)}, ${firstNameOf(console.userName)}',
          subtitle: 'Here is your operational pulse across Uganda and regional routes.',
          actions: [
            ActionButton(
              label: 'Refresh',
              icon: Icons.refresh,
              onPressed: () {
                console.refresh();
                showToast(context, 'Dashboard refreshed');
              },
            ),
            if (canCreate)
              ActionButton(
                label: 'New trip',
                icon: Icons.add,
                primary: true,
                onPressed: () => showNewTripDialog(context, console),
              ),
          ],
        ),
        AccessBanner(level: level),
        if (data.note != null) _NoteBanner(text: data.note!),
        KpiGrid(stats: data.kpis),
        gap16,
        ResponsiveRow(
          left: SectionCard(
            title: 'Live fleet overview',
            subtitle: 'Vehicle positions · Last GPS update ${data.fleet.lastUpdate}',
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: Column(
              children: [
                FleetMapView(
                  pins: data.fleet.pins,
                  counts: data.fleet.counts,
                  onPinTap: (pin) => showToast(context, '${pin.label} selected · live GPS details loaded'),
                ),
                const SizedBox(height: 12),
                for (final v in data.fleet.highlights)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: v.plate,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                TextSpan(text: ' · ${v.driver}'),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: c.text),
                          ),
                        ),
                        StatusChip(label: v.status.label, tone: v.status.tone),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          right: SectionCard(
            title: 'Needs attention',
            subtitle: '${data.attention.length} items require a manager decision',
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                for (var i = 0; i < data.attention.length; i++) ...[
                  if (i > 0) Divider(color: c.line),
                  AttentionTile(
                    item: data.attention[i],
                    onAction: () => _openAttention(context, data.attention[i]),
                  ),
                ],
              ],
            ),
          ),
        ),
        gap16,
        ResponsiveRow(
          leftFlex: 1,
          rightFlex: 1,
          left: SectionCard(
            title: 'Trips by status',
            subtitle: 'Current operating day · ${data.totalTrips} total trips',
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            child: ProgressRows(
              rows: [
                for (final s in data.statusCounts)
                  ProgressRowData(
                    label: s.status.label,
                    trailing: '${s.count}',
                    fraction: data.totalTrips == 0 ? 0 : s.count / data.totalTrips,
                    color: c.tone(s.status.tone).fg,
                  ),
              ],
            ),
          ),
          right: SectionCard(
            title: 'Deliveries · 7 days',
            subtitle: 'Completed deliveries per day',
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
            child: Column(
              children: [
                BarChartView(
                  groups: [
                    for (final d in data.deliveries) BarGroup(d.label, [d.delivered, d.target]),
                  ],
                  colors: [c.blue2, c.line],
                  seriesNames: const ['Delivered', 'Target'],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LegendDot(color: c.blue2, label: 'Delivered'),
                    const SizedBox(width: 16),
                    LegendDot(color: c.line, label: 'Target'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NoteBanner extends StatelessWidget {
  const _NoteBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.amberBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: c.amber),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: c.amber))),
        ],
      ),
    );
  }
}
