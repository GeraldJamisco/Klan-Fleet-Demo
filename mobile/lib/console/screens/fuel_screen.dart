import 'package:material_ui/material_ui.dart';

import '../core/access.dart';
import '../core/formatters.dart';
import '../models/ops_models.dart';
import '../theme/console_theme.dart';
import '../widgets/access_banner.dart';
import '../widgets/action_button.dart';
import '../widgets/async_view.dart';
import '../widgets/charts.dart';
import '../widgets/console_table.dart';
import '../widgets/kpi_card.dart';
import '../widgets/layout.dart';
import '../widgets/page_header.dart';
import '../widgets/section_card.dart';
import '../widgets/status_chip.dart';
import '../widgets/toast.dart';
import 'screen_support.dart';

class FuelScreen extends StatelessWidget {
  const FuelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final console = context.console;
    final level = console.levelFor(ConsoleModule.fuel);
    return DataLoader<FuelData>(
      load: console.repository.fuel,
      reloadKey: console.refreshTick,
      builder: (context, data) => _FuelBody(data: data, level: level),
    );
  }
}

class _FuelBody extends StatelessWidget {
  const _FuelBody({required this.data, required this.level});

  final FuelData data;
  final AccessLevel level;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    final canReview = canChange(level);
    final maxShare = data.costShare.fold<double>(0, (m, e) => e.value > m ? e.value : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          eyebrow: 'Finance',
          title: 'Fuel & Costs',
          subtitle: 'Fuel efficiency, trip economics and finance visibility.',
          actions: [
            if (level != AccessLevel.submit)
              ActionButton(
                label: 'Export',
                onPressed: () => showToast(context, 'Cost report exported'),
              ),
            if (level == AccessLevel.submit)
              ActionButton(
                label: 'Log fuel',
                icon: Icons.add,
                primary: true,
                onPressed: () => showToast(context, 'Fuel entry form opened'),
              ),
          ],
        ),
        AccessBanner(level: level),
        KpiGrid(stats: data.kpis),
        gap16,
        ResponsiveRow(
          leftFlex: 1,
          rightFlex: 1,
          left: SectionCard(
            title: 'Fuel spend by route',
            subtitle: 'Month to date · UGX millions',
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
            child: BarChartView(
              groups: [for (final r in data.routeSpend) BarGroup(r.label, [r.value])],
              colors: [c.blue2],
              seriesNames: const ['Spend'],
              unit: 'M',
            ),
          ),
          right: SectionCard(
            title: 'Cost breakdown',
            subtitle: 'Share of operating cost',
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            child: ProgressRows(
              labelWidth: 120,
              rows: [
                for (final s in data.costShare)
                  ProgressRowData(
                    label: s.label,
                    trailing: '${s.value.round()}%',
                    fraction: maxShare == 0 ? 0 : s.value / maxShare,
                    color: c.blue2,
                  ),
              ],
            ),
          ),
        ),
        gap16,
        SectionCard(
          title: 'Fuel transaction exceptions',
          subtitle: 'Automated anomaly rules · Review before approval',
          child: data.exceptions.isEmpty
              ? const EmptyState(
                  title: 'No exceptions',
                  message: 'Every fuel transaction is within its expected range.',
                  icon: Icons.check_circle_outline,
                )
              : ConsoleTable(
                  columns: [
                    const TableCol('Vehicle', 110),
                    const TableCol('Route', 170),
                    const TableCol('Litres', 80),
                    const TableCol('Amount', 140),
                    const TableCol('Variance', 90),
                    const TableCol('Flag', 120),
                    if (canReview) const TableCol('Action', 100),
                  ],
                  rows: [
                    for (final e in data.exceptions)
                      [
                        CellText(e.vehicle, bold: true),
                        CellText(e.route),
                        CellText('${e.litres} L'),
                        CellText('UGX ${thousands(e.amountUgx)}'),
                        CellText('+${e.variancePercent}%', bold: true),
                        StatusChip(
                          label: e.flag,
                          tone: e.variancePercent >= 30 ? Tone.red : Tone.amber,
                        ),
                        if (canReview)
                          ActionButton(
                            label: 'Review',
                            compact: true,
                            onPressed: () => showToast(context, 'Fuel record sent for review'),
                          ),
                      ],
                  ],
                ),
        ),
      ],
    );
  }
}
