import 'package:material_ui/material_ui.dart';

import '../core/access.dart';
import '../core/formatters.dart';
import '../models/ops_models.dart';
import '../theme/console_theme.dart';
import '../widgets/access_banner.dart';
import '../widgets/action_button.dart';
import '../widgets/async_view.dart';
import '../widgets/console_table.dart';
import '../widgets/layout.dart';
import '../widgets/page_header.dart';
import '../widgets/section_card.dart';
import '../widgets/status_chip.dart';
import '../widgets/toast.dart';
import 'screen_support.dart';

class ErpScreen extends StatelessWidget {
  const ErpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final console = context.console;
    final level = console.levelFor(ConsoleModule.erp);
    return DataLoader<ErpData>(
      load: console.repository.erp,
      reloadKey: console.refreshTick,
      builder: (context, data) => _ErpBody(data: data, level: level),
    );
  }
}

class _ErpBody extends StatelessWidget {
  const _ErpBody({required this.data, required this.level});

  final ErpData data;
  final AccessLevel level;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    final canAct = canChange(level);
    final healthy = data.connected;
    final banner = c.tone(healthy ? Tone.green : Tone.red);
    final successRate = data.total == 0 ? 100.0 : data.syncedFraction * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          eyebrow: 'Integrations',
          title: 'ERP integration',
          subtitle: 'Monitor data exchange between Nexora and your back-office ERP.',
          actions: [
            if (canAct)
              ActionButton(
                label: 'Export log',
                onPressed: () => showToast(context, 'Sync history downloaded'),
              ),
            if (canAct)
              ActionButton(
                label: 'Sync now',
                icon: Icons.sync,
                primary: true,
                onPressed: () => showToast(context, 'Sync cycle started'),
              ),
          ],
        ),
        AccessBanner(level: level),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: banner.bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      healthy
                          ? 'Connection healthy · ERP endpoint responding'
                          : 'ERP endpoint is not responding',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: banner.fg),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last successful sync: ${data.lastSync} · Average latency ${data.latency}',
                      style: TextStyle(fontSize: 11, color: banner.fg),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              StatusChip(
                label: healthy ? 'Connected' : 'Offline',
                tone: healthy ? Tone.green : Tone.red,
              ),
            ],
          ),
        ),
        gap16,
        AdaptiveGrid(
          minTileWidth: 200,
          maxColumns: 3,
          spacing: 14,
          children: [
            _SyncStat(
              label: 'Pending events',
              value: thousands(data.pending),
              note: 'Awaiting processing',
            ),
            _SyncStat(
              label: 'Successfully synced',
              value: thousands(data.synced),
              note: '${successRate.toStringAsFixed(1)}% success',
            ),
            _SyncStat(
              label: 'Failed events',
              value: data.failed.toString().padLeft(2, '0'),
              note: 'Require review',
              warn: data.failed > 0,
            ),
          ],
        ),
        gap16,
        SectionCard(
          title: 'Recent integration events',
          subtitle: 'Event queue · Newest first',
          child: data.events.isEmpty
              ? const EmptyState(
                  title: 'No events yet',
                  message: 'Events appear here as trips, fuel and incidents sync.',
                  icon: Icons.sync_disabled,
                )
              : ConsoleTable(
                  columns: [
                    const TableCol('Event ID', 100),
                    const TableCol('Event type', 160),
                    const TableCol('Reference', 100),
                    const TableCol('Created', 100),
                    const TableCol('Attempts', 80),
                    const TableCol('Status', 110),
                    const TableCol('Error / response', 230),
                    if (canAct) const TableCol('', 90),
                  ],
                  rows: [
                    for (final e in data.events)
                      [
                        CellText(e.id, bold: true),
                        CellText(e.type),
                        CellText(e.reference),
                        CellText(e.created),
                        CellText('${e.attempts}'),
                        StatusChip(label: e.status.label, tone: e.status.tone),
                        CellText(e.message, muted: true),
                        if (canAct)
                          e.status == ErpEventStatus.synced
                              ? const SizedBox.shrink()
                              : ActionButton(
                                  label: 'Retry',
                                  compact: true,
                                  onPressed: () => showToast(context, 'Retry queued for ${e.id}'),
                                ),
                      ],
                  ],
                ),
        ),
        gap16,
        SectionCard(
          title: 'Field mapping preview',
          subtitle: 'Nexora application field → ERP destination field',
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
          child: Column(
            children: [
              for (final m in data.mappings)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          m.from,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.text),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.arrow_forward, size: 15, color: c.muted),
                      ),
                      Expanded(
                        child: Text(
                          m.to,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.blue),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SyncStat extends StatelessWidget {
  const _SyncStat({
    required this.label,
    required this.value,
    required this.note,
    this.warn = false,
  });

  final String label;
  final String value;
  final String note;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    return Semantics(
      label: '$label: $value. $note',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.muted)),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                  color: warn ? c.red : c.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(note, style: TextStyle(fontSize: 10.5, color: c.muted)),
            ],
          ),
        ),
      ),
    );
  }
}
