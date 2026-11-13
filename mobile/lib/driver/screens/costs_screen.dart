import 'package:material_ui/material_ui.dart';

import '../../console/core/formatters.dart';
import '../../console/widgets/action_button.dart';
import '../../console/widgets/async_view.dart';
import '../../console/widgets/console_table.dart';
import '../../console/widgets/layout.dart';
import '../../console/widgets/page_header.dart';
import '../../console/widgets/section_card.dart';
import '../../console/widgets/status_chip.dart';
import '../../console/widgets/toast.dart';
import '../widgets/driver_forms.dart';
import '../widgets/driver_widgets.dart';
import 'driver_support.dart';

class DriverCostsScreen extends StatelessWidget {
  const DriverCostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SnapshotView(
      builder: (context, snapshot, driver) {
        final s = snapshot.summary;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              eyebrow: 'Trip expense records',
              title: 'Fuel & expenses',
              subtitle: 'Submit fuel fills and approved trip expenses.',
              actions: [
                ActionButton(
                  label: 'Log fuel',
                  icon: Icons.add,
                  primary: true,
                  onPressed: () => withActiveTrip(context, snapshot, (t) => showFuelForm(context, driver, t)),
                ),
              ],
            ),
            ResponsiveRow(
              leftFlex: 1,
              rightFlex: 1,
              breakpoint: 820,
              left: SectionCard(
                title: 'Fuel summary',
                subtitle: 'Current trip',
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: AdaptiveGrid(
                  minTileWidth: 110,
                  maxColumns: 3,
                  spacing: 10,
                  children: [
                    SummaryTile(
                      icon: Icons.local_gas_station_outlined,
                      value: s.fuelLitres == null ? '—' : litresLabel(s.fuelLitres!),
                      label: 'Fuel logged',
                    ),
                    SummaryTile(
                      icon: Icons.payments_outlined,
                      value: s.fuelCostUgx == null ? '—' : ugxCompact(s.fuelCostUgx!),
                      label: 'Fuel cost',
                    ),
                    SummaryTile(
                      icon: Icons.speed,
                      value: s.kmPerLitre == null ? '—' : s.kmPerLitre!.toStringAsFixed(2),
                      label: 'km per litre',
                    ),
                  ],
                ),
              ),
              right: SectionCard(
                title: 'Expense policy',
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const NoticeBanner(
                      title: 'Keep every receipt',
                      body: 'Record actual litres, odometer reading and station. Submit tolls and border fees '
                          'with supporting receipts.',
                    ),
                    const SizedBox(height: 12),
                    ActionButton(
                      label: 'View expense policy',
                      expand: true,
                      onPressed: () => showToast(context, 'Expense policy opened (demo).'),
                    ),
                  ],
                ),
              ),
            ),
            gap16,
            SectionCard(
              title: 'Recent fuel entries',
              subtitle: 'UGX · No decimals',
              child: snapshot.fuel.isEmpty
                  ? const EmptyState(
                      title: 'No fuel entries yet',
                      message: 'Log a fill-up and it appears here.',
                      icon: Icons.local_gas_station_outlined,
                    )
                  : ConsoleTable(
                      columns: const [
                        TableCol('Date / time', 130),
                        TableCol('Station', 150),
                        TableCol('Litres', 80),
                        TableCol('Amount', 130),
                        TableCol('Odometer', 120),
                        TableCol('Review', 120),
                      ],
                      rows: [
                        for (final f in snapshot.fuel)
                          [
                            CellText(f.when),
                            CellText(f.station),
                            CellText(litresLabel(f.litres)),
                            CellText('UGX ${thousands(f.amountUgx)}'),
                            CellText(f.odometerKm == null ? '—' : '${thousands(f.odometerKm!)} km'),
                            StatusChip(label: f.review, tone: f.reviewTone),
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
