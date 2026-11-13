import 'package:material_ui/material_ui.dart';

import '../core/access.dart';
import '../models/ops_models.dart';
import '../widgets/access_banner.dart';
import '../widgets/action_button.dart';
import '../widgets/async_view.dart';
import '../widgets/console_table.dart';
import '../widgets/kpi_card.dart';
import '../widgets/page_header.dart';
import '../widgets/section_card.dart';
import '../widgets/status_chip.dart';
import '../widgets/toast.dart';
import 'screen_support.dart';

class WarehouseScreen extends StatelessWidget {
  const WarehouseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final console = context.console;
    final level = console.levelFor(ConsoleModule.warehouse);
    return DataLoader<WarehouseData>(
      load: console.repository.warehouse,
      reloadKey: console.refreshTick,
      builder: (context, data) => _WarehouseBody(data: data, level: level),
    );
  }
}

class _WarehouseBody extends StatelessWidget {
  const _WarehouseBody({required this.data, required this.level});

  final WarehouseData data;
  final AccessLevel level;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          eyebrow: 'Depots',
          title: 'Warehouse & Distribution',
          subtitle: 'Daily stock movement and dispatch readiness across depots.',
          actions: [
            ActionButton(
              label: 'Export summary',
              onPressed: () => showToast(context, 'Warehouse summary exported'),
            ),
          ],
        ),
        AccessBanner(level: level),
        KpiGrid(stats: data.kpis),
        gap16,
        SectionCard(
          title: 'Dispatch queue',
          subtitle: 'Warehouse releases awaiting vehicle assignment',
          child: data.queue.isEmpty
              ? const EmptyState(
                  title: 'Queue is empty',
                  message: 'Nothing is waiting for a vehicle.',
                )
              : ConsoleTable(
                  columns: const [
                    TableCol('Dispatch ref', 110),
                    TableCol('Warehouse', 130),
                    TableCol('Client', 170),
                    TableCol('Destination', 110),
                    TableCol('Load', 110),
                    TableCol('Ready since', 100),
                    TableCol('Priority', 120),
                  ],
                  rows: [
                    for (final d in data.queue)
                      [
                        CellText(d.ref, bold: true),
                        CellText(d.warehouse),
                        CellText(d.client),
                        CellText(d.destination),
                        CellText(d.load),
                        CellText(d.readySince),
                        StatusChip(
                          label: d.highPriority ? 'High priority' : 'Normal',
                          tone: d.highPriority ? Tone.amber : Tone.gray,
                        ),
                      ],
                  ],
                ),
        ),
      ],
    );
  }
}
