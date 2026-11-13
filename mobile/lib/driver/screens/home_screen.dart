import 'package:material_ui/material_ui.dart';

import '../../console/core/formatters.dart';
import '../../console/theme/console_theme.dart';
import '../../console/widgets/action_button.dart';
import '../../console/widgets/async_view.dart';
import '../../console/widgets/layout.dart';
import '../../console/widgets/page_header.dart';
import '../../console/widgets/section_card.dart';
import '../../console/widgets/status_chip.dart';
import '../../console/widgets/toast.dart';
import '../models/driver_models.dart';
import '../state/driver_controller.dart';
import '../widgets/driver_forms.dart';
import '../widgets/driver_widgets.dart';
import 'driver_support.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SnapshotView(
      builder: (context, snapshot, driver) => _HomeBody(snapshot: snapshot, driver: driver),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.snapshot, required this.driver});

  final DriverSnapshot snapshot;
  final DriverController driver;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final trip = snapshot.activeTrip;
    final profile = snapshot.profile;

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActiveTripCard(trip: trip, onDetails: () => driver.go(DriverPage.trips)),
        gap16,
        _QuickActions(snapshot: snapshot, driver: driver),
        gap16,
        SectionCard(
          title: 'Today’s summary',
          subtitle: 'Live trip totals',
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: AdaptiveGrid(
            minTileWidth: 120,
            maxColumns: 3,
            spacing: 10,
            children: [
              SummaryTile(
                icon: Icons.place_outlined,
                value: kmLabel(snapshot.summary.distanceKm),
                label: 'Trip distance',
              ),
              SummaryTile(
                icon: Icons.local_gas_station_outlined,
                value: snapshot.summary.fuelLitres == null
                    ? '—'
                    : litresLabel(snapshot.summary.fuelLitres!),
                label: 'Fuel used',
              ),
              SummaryTile(
                icon: Icons.schedule,
                value: orDash(snapshot.summary.drivingTime),
                label: 'Driving time',
              ),
            ],
          ),
        ),
      ],
    );

    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (trip != null) ...[
          SectionCard(
            title: 'Trip progress',
            subtitle: '${(trip.progress * 100).round()}% complete',
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        trip.route,
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: context.cc.text),
                      ),
                    ),
                    Text(
                      trip.status.label,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.cc.blue),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ProgressLine(
                  fraction: trip.progress,
                  left: trip.scheduled == '—' ? '' : 'Scheduled ${trip.scheduled}',
                  right: 'ETA ${trip.eta}',
                ),
                const SizedBox(height: 14),
                ActionButton(
                  label: 'Open trip map',
                  icon: Icons.north_east,
                  expand: true,
                  onPressed: () => driver.go(DriverPage.map),
                ),
              ],
            ),
          ),
          gap16,
        ],
        SectionCard(
          title: 'Dispatch messages',
          padding: const EdgeInsets.symmetric(horizontal: 18),
          trailing: TextButton(
            onPressed: () => driver.go(DriverPage.messages),
            child: const Text('View all'),
          ),
          child: Column(
            children: [
              for (final m in snapshot.messages.take(2))
                InfoRow(
                  icon: messageIcon(m.kind),
                  title: boldTitle(context, '${m.sender} · ${m.title}'),
                  detail: m.body,
                  time: m.time,
                ),
            ],
          ),
        ),
        gap16,
        const NoticeBanner(
          title: 'Driver safety reminder',
          body: 'Take your scheduled rest breaks. Report delays or route hazards to dispatch as soon as it is safe to do so.',
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          eyebrow: '${longDate(now)} · EAT',
          title: '${greetingFor(now)}, ${profile.firstName}',
          subtitle: 'Here’s your driving schedule and today’s activity.',
        ),
        if (snapshot.note != null) _SampleNote(text: snapshot.note!),
        _Welcome(profile: profile, trip: trip),
        gap16,
        ResponsiveRow(left: left, right: right, leftFlex: 3, rightFlex: 2, breakpoint: 880),
      ],
    );
  }
}

class _SampleNote extends StatelessWidget {
  const _SampleNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: c.amberBg, borderRadius: BorderRadius.circular(10)),
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

class _Welcome extends StatelessWidget {
  const _Welcome({required this.profile, required this.trip});

  final DriverProfile profile;
  final DriverTrip? trip;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    final onBlue = Theme.of(context).colorScheme.onPrimary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: c.blue, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stay safe out there, ${profile.firstName}.',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: onBlue),
                ),
                const SizedBox(height: 5),
                Text(
                  trip == null
                      ? 'You have no active trip right now.'
                      : 'You’re assigned to ${trip!.route} today.',
                  style: TextStyle(fontSize: 12.5, color: onBlue),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    for (final line in ['● On duty', 'Driver ID: ${profile.driverId}', 'Base: ${profile.base}'])
                      Text(line, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: onBlue)),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.local_shipping, size: 54, color: onBlue),
        ],
      ),
    );
  }
}

class _ActiveTripCard extends StatelessWidget {
  const _ActiveTripCard({required this.trip, required this.onDetails});

  final DriverTrip? trip;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    final t = trip;
    if (t == null) {
      return const SectionCard(
        title: 'Active trip',
        child: EmptyState(
          title: 'No active trip',
          message: 'New assignments from dispatch appear here.',
          icon: Icons.local_shipping_outlined,
        ),
      );
    }
    return SectionCard(
      title: 'Active trip',
      trailing: StatusChip.trip(t.status),
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  t.ref,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c.blue),
                ),
              ),
              const Spacer(),
              if (t.scheduled != '—')
                Flexible(
                  child: Text(
                    'Scheduled ${t.scheduled}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5, color: c.muted),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          RouteBlock(origin: t.origin, destination: t.destination),
          const SizedBox(height: 14),
          CargoLine(text: t.cargo),
          const SizedBox(height: 12),
          StatGrid(
            stats: [
              ('ETA', t.eta),
              ('Distance', kmLabel(t.distanceKm)),
              ('Vehicle', t.vehiclePlate),
            ],
          ),
          const SizedBox(height: 14),
          ActionButton(
            label: 'View trip details',
            icon: Icons.arrow_forward,
            primary: true,
            expand: true,
            onPressed: onDetails,
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.snapshot, required this.driver});

  final DriverSnapshot snapshot;
  final DriverController driver;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    Widget tile(IconData icon, String label, VoidCallback onTap) => Material(
          color: c.surface2,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.line),
              ),
              child: Column(
                children: [
                  Icon(icon, size: 22, color: c.blue),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: c.text),
                  ),
                ],
              ),
            ),
          ),
        );

    return SectionCard(
      title: 'Quick actions',
      subtitle: 'Keep records up to date',
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: AdaptiveGrid(
        minTileWidth: 120,
        maxColumns: 3,
        spacing: 10,
        children: [
          tile(Icons.check_circle_outline, 'Update status',
              () => withActiveTrip(context, snapshot, (t) => showStatusForm(context, driver, t))),
          tile(Icons.local_gas_station_outlined, 'Log fuel',
              () => withActiveTrip(context, snapshot, (t) => showFuelForm(context, driver, t))),
          tile(Icons.warning_amber_outlined, 'Report issue',
              () => showIssueForm(context, driver, snapshot.activeTrip)),
          tile(Icons.assignment_turned_in_outlined, 'Proof of delivery',
              () => withActiveTrip(context, snapshot, (t) => showProofForm(context, driver, t))),
          tile(Icons.description_outlined, 'Trip documents', () => driver.go(DriverPage.documents)),
          tile(Icons.phone_outlined, 'Contact dispatch',
              () => showToast(context, 'Dispatch calling: +256 700 123 456')),
        ],
      ),
    );
  }
}
