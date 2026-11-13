import 'package:material_ui/material_ui.dart';

import '../core/access.dart';
import '../core/formatters.dart';
import '../models/ops_models.dart';
import '../state/console_controller.dart';
import '../theme/console_theme.dart';
import '../widgets/action_button.dart';
import '../widgets/async_view.dart';
import '../widgets/fleet_map.dart';
import '../widgets/layout.dart';
import '../widgets/page_header.dart';
import '../widgets/section_card.dart';
import '../widgets/status_chip.dart';
import '../widgets/timeline.dart';
import '../widgets/toast.dart';
import 'screen_support.dart';

class TripDetailScreen extends StatelessWidget {
  const TripDetailScreen({super.key, required this.tripRef});

  final String tripRef;

  @override
  Widget build(BuildContext context) {
    final console = context.console;
    return DataLoader<TripDetailData>(
      load: () => console.repository.tripDetail(tripRef),
      reloadKey: '$tripRef-${console.refreshTick}',
      builder: (context, data) => _DetailBody(data: data, console: console),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.data, required this.console});

  final TripDetailData data;
  final ConsoleController console;

  @override
  Widget build(BuildContext context) {
    final trip = data.trip;
    final level = console.levelFor(ConsoleModule.trips);
    final showCosts = level != AccessLevel.limited && level != AccessLevel.assigned;

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'Trip progress',
          subtitle: 'Live journey timeline · All times EAT',
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
          child: TimelineList(entries: data.timeline),
        ),
        gap16,
        SectionCard(
          title: 'Route & documents',
          subtitle: data.distanceKm == null
              ? 'Planned route'
              : 'Planned route · ${thousands(data.distanceKm!)} km',
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FleetMapView(
                height: 145,
                showRoute: true,
                places: [
                  MapPlace(trip.origin.toUpperCase(), 0.15, 0.55),
                  MapPlace(trip.destination.toUpperCase(), 0.70, 0.25),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final doc in data.documents)
                    ActionButton(
                      label: doc,
                      icon: Icons.description_outlined,
                      compact: true,
                      onPressed: () => showToast(context, '$doc preview opened'),
                    ),
                  if (canChange(level))
                    ActionButton(
                      label: 'Proof of delivery',
                      icon: Icons.add,
                      compact: true,
                      onPressed: () => showToast(context, 'Proof of delivery not yet uploaded'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'Trip assignment',
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Field(label: 'Driver', child: _Value(trip.driverName)),
              _Field(label: 'Vehicle', child: _Value(trip.vehiclePlate)),
              _Field(label: 'Cargo', child: _Value(trip.cargo)),
              _Field(label: 'Current status', child: StatusChip.trip(trip.status)),
              _Field(label: 'Expected arrival', child: _Value(trip.eta)),
            ],
          ),
        ),
        if (showCosts) ...[
          gap16,
          _CostCard(data: data),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          eyebrow: 'Trip details',
          title: 'Trip ${trip.ref}',
          subtitle: '${trip.client} · ${trip.route}',
          actions: [
            ActionButton(
              label: 'Back to trips',
              icon: Icons.arrow_back,
              onPressed: console.closeTrip,
            ),
            if (canChange(level))
              ActionButton(
                label: 'Edit trip',
                primary: true,
                onPressed: () => showToast(context, 'Trip update saved'),
              ),
          ],
        ),
        ResponsiveRow(left: left, right: right, leftFlex: 3, rightFlex: 2, breakpoint: 860),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: context.cc.muted,
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.cc.text),
      );
}

class _CostCard extends StatelessWidget {
  const _CostCard({required this.data});

  final TripDetailData data;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    Widget line(String label, String value, {Color? color, bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: c.muted))),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
                  color: color ?? c.text,
                ),
              ),
            ],
          ),
        );

    return SectionCard(
      title: 'Trip cost summary',
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: data.costs.isEmpty
          ? Text('No costs recorded yet.', style: TextStyle(fontSize: 12, color: c.muted))
          : Column(
              children: [
                for (final cost in data.costs) line(cost.label, 'UGX ${thousands(cost.amountUgx)}'),
                if (data.hasRevenue) ...[
                  Divider(color: c.line),
                  line(
                    'Estimated margin',
                    'UGX ${thousands(data.margin)}',
                    color: data.margin >= 0 ? c.green : c.red,
                    bold: true,
                  ),
                ],
              ],
            ),
    );
  }
}
