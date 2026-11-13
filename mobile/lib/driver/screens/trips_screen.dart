import 'package:material_ui/material_ui.dart';

import '../../console/theme/console_theme.dart';
import '../../console/widgets/action_button.dart';
import '../../console/widgets/async_view.dart';
import '../../console/widgets/console_table.dart';
import '../../console/widgets/page_header.dart';
import '../../console/widgets/section_card.dart';
import '../../console/widgets/status_chip.dart';
import '../widgets/driver_forms.dart';
import '../widgets/driver_widgets.dart';
import 'driver_support.dart';

class DriverTripsScreen extends StatelessWidget {
  const DriverTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SnapshotView(
      builder: (context, snapshot, driver) {
        final trip = snapshot.activeTrip;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              eyebrow: 'Your assignments',
              title: 'My trips',
              subtitle: 'Current and recent trips assigned to you.',
            ),
            if (trip == null)
              const SectionCard(
                title: 'Current assignment',
                child: EmptyState(
                  title: 'No active trip',
                  message: 'New assignments from dispatch appear here.',
                  icon: Icons.local_shipping_outlined,
                ),
              )
            else
              SectionCard(
                title: 'Current assignment',
                trailing: StatusChip.trip(trip.status),
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${trip.ref} · ${trip.dateLabel.isEmpty ? 'TODAY' : trip.dateLabel.toUpperCase()}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: context.cc.blue),
                    ),
                    const SizedBox(height: 14),
                    RouteBlock(origin: trip.origin, destination: trip.destination),
                    const SizedBox(height: 14),
                    CargoLine(text: trip.client == '—' ? trip.cargo : '${trip.cargo} · Client: ${trip.client}'),
                    const SizedBox(height: 12),
                    StatGrid(
                      stats: [
                        ('Scheduled', trip.scheduled),
                        ('ETA', trip.eta),
                        ('Vehicle', trip.vehiclePlate),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ActionButton(
                      label: 'Update trip status',
                      primary: true,
                      expand: true,
                      onPressed: () => showStatusForm(context, driver, trip),
                    ),
                  ],
                ),
              ),
            gap16,
            SectionCard(
              title: 'Trip history',
              subtitle: 'Most recent first',
              child: snapshot.history.isEmpty
                  ? const EmptyState(title: 'No trips yet', message: 'Your completed trips are listed here.')
                  : ConsoleTable(
                      columns: const [
                        TableCol('Trip ref', 150),
                        TableCol('Route', 190),
                        TableCol('Cargo', 170),
                        TableCol('Date', 90),
                        TableCol('Status', 120),
                      ],
                      rows: [
                        for (final t in snapshot.history)
                          [
                            CellText(t.ref, bold: true),
                            CellText(t.route),
                            CellText(t.cargo),
                            CellText(t.dateLabel.isEmpty ? '—' : t.dateLabel),
                            StatusChip.trip(t.status),
                          ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}
