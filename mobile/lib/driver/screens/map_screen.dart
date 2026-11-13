import 'package:material_ui/material_ui.dart';

import '../../console/models/ops_models.dart' show MapPin, PinState;
import '../../console/widgets/action_button.dart';
import '../../console/widgets/async_view.dart';
import '../../console/widgets/fleet_map.dart';
import '../../console/widgets/page_header.dart';
import '../../console/widgets/section_card.dart';
import '../../console/widgets/status_chip.dart';
import '../widgets/driver_forms.dart';
import '../widgets/driver_widgets.dart';
import 'driver_support.dart';

class DriverMapScreen extends StatelessWidget {
  const DriverMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SnapshotView(
      builder: (context, snapshot, driver) {
        final trip = snapshot.activeTrip;
        if (trip == null) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                eyebrow: 'Live route guidance',
                title: 'Trip navigation',
                subtitle: 'Your route appears here when a trip is active.',
              ),
              SectionCard(
                child: EmptyState(
                  title: 'No active trip',
                  message: 'There is no route to show right now.',
                  icon: Icons.map_outlined,
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              eyebrow: 'Live route guidance',
              title: 'Trip navigation',
              subtitle: '${trip.ref} · ${trip.origin} to ${trip.destination}',
              actions: [StatusChip.trip(trip.status)],
            ),
            SectionCard(
              title: 'Route overview',
              subtitle: 'Reported trip position (illustrative)',
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FleetMapView(
                    height: 280,
                    showRoute: true,
                    places: [
                      MapPlace(trip.origin.toUpperCase(), 0.12, 0.62),
                      MapPlace(trip.destination.toUpperCase(), 0.72, 0.18),
                    ],
                    pins: const [
                      MapPin(dx: 0.15, dy: 0.63, state: PinState.available, label: 'Start'),
                      MapPin(dx: 0.45, dy: 0.42, state: PinState.moving, label: 'Your reported position'),
                      MapPin(dx: 0.79, dy: 0.30, state: PinState.stopped, label: 'Destination'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  StatGrid(
                    stats: [
                      ('Total distance', kmLabel(trip.distanceKm)),
                      ('Estimated arrival', trip.eta),
                      ('Status', trip.status.label),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const NoticeBanner(
                    title: 'Route guidance is illustrative',
                    body: 'Follow approved road signs and dispatch instructions. This demo does not provide '
                        'turn-by-turn navigation or live GPS tracking.',
                  ),
                ],
              ),
            ),
            gap16,
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ActionButton(
                  label: 'Update location / status',
                  primary: true,
                  onPressed: () => showStatusForm(context, driver, trip),
                ),
                ActionButton(
                  label: 'Report route issue',
                  onPressed: () => showIssueForm(context, driver, trip),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
