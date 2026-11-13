import 'package:material_ui/material_ui.dart';

import '../core/access.dart';
import '../core/formatters.dart';
import '../models/ops_models.dart';
import '../theme/console_theme.dart';
import '../widgets/access_banner.dart';
import '../widgets/action_button.dart';
import '../widgets/async_view.dart';
import '../widgets/inputs.dart';
import '../widgets/kpi_card.dart';
import '../widgets/layout.dart';
import '../widgets/page_header.dart';
import '../widgets/status_chip.dart';
import '../widgets/toast.dart';
import 'screen_support.dart';

const String _allStatuses = 'All statuses';
const String _allTypes = 'All vehicle types';

class FleetScreen extends StatelessWidget {
  const FleetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final console = context.console;
    final level = console.levelFor(ConsoleModule.fleet);
    return DataLoader<FleetData>(
      load: console.repository.fleet,
      reloadKey: console.refreshTick,
      builder: (context, data) => _FleetBody(data: data, level: level),
    );
  }
}

class _FleetBody extends StatefulWidget {
  const _FleetBody({required this.data, required this.level});

  final FleetData data;
  final AccessLevel level;

  @override
  State<_FleetBody> createState() => _FleetBodyState();
}

class _FleetBodyState extends State<_FleetBody> {
  String _query = '';
  String _status = _allStatuses;
  String _type = _allTypes;

  @override
  void didUpdateWidget(_FleetBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_type != _allTypes && !widget.data.vehicles.any((v) => v.type == _type)) {
      _type = _allTypes;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    final types = <String>{for (final v in widget.data.vehicles) v.type}.toList()..sort();
    final query = _query.trim().toLowerCase();
    final shown = [
      for (final v in widget.data.vehicles)
        if ((query.isEmpty || v.searchText.contains(query)) &&
            (_status == _allStatuses || v.status.label == _status) &&
            (_type == _allTypes || v.type == _type))
          v,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          eyebrow: 'Assets',
          title: 'Fleet',
          subtitle: 'Vehicle readiness, utilisation and maintenance control.',
          actions: [
            ActionButton(
              label: 'Export',
              onPressed: () => showToast(context, 'Vehicle report generated'),
            ),
            if (canChange(widget.level))
              ActionButton(
                label: 'Add vehicle',
                icon: Icons.add,
                primary: true,
                onPressed: () => showToast(context, 'Vehicle registration form opened'),
              ),
          ],
        ),
        AccessBanner(level: widget.level),
        KpiGrid(stats: widget.data.kpis),
        gap16,
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ConsoleSearchField(
              value: _query,
              onChanged: (v) => setState(() => _query = v),
              hint: 'Search plate or model…',
              width: 260,
            ),
            ConsoleDropdown<String>(
              value: _status,
              items: [_allStatuses, for (final s in VehicleStatus.values) s.label],
              labelOf: (v) => v,
              onChanged: (v) => setState(() => _status = v),
              width: 170,
            ),
            ConsoleDropdown<String>(
              value: _type,
              items: [_allTypes, ...types],
              labelOf: (v) => v,
              onChanged: (v) => setState(() => _type = v),
              width: 200,
            ),
          ],
        ),
        gap16,
        if (shown.isEmpty)
          const EmptyState(
            title: 'No vehicles match',
            message: 'Try a different search or clear the filters.',
            icon: Icons.search_off,
          )
        else
          AdaptiveGrid(
            minTileWidth: 300,
            maxColumns: 3,
            spacing: 14,
            children: [
              for (final v in shown) _VehicleCard(vehicle: v, color: c),
            ],
          ),
      ],
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle, required this.color});

  final FleetVehicle vehicle;
  final ConsoleColors color;

  @override
  Widget build(BuildContext context) {
    final c = color;
    Widget stat(String label, String value) => Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10.5, color: c.muted)),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.text),
                ),
              ],
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: c.blueWash,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.local_shipping_outlined, size: 20, color: c.blue),
              ),
              const Spacer(),
              StatusChip(label: vehicle.status.label, tone: vehicle.status.tone),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            vehicle.plate,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: c.text),
          ),
          const SizedBox(height: 3),
          Text('${vehicle.model} · ${vehicle.type}', style: TextStyle(fontSize: 11.5, color: c.muted)),
          Row(
            children: [
              stat('Assigned driver', vehicle.driverName ?? 'Unassigned'),
              stat('Odometer', '${thousands(vehicle.odometerKm)} km'),
            ],
          ),
          Row(
            children: [
              stat('Next service', vehicle.nextService),
              stat('Fuel efficiency', '${vehicle.kmPerLitre.toStringAsFixed(1)} km/L'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Insurance valid · Inspection valid',
                  style: TextStyle(fontSize: 10.5, color: c.muted),
                ),
              ),
              ActionButton(
                label: 'Details',
                compact: true,
                onPressed: () => showToast(context, 'Vehicle ${vehicle.plate} details opened'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
