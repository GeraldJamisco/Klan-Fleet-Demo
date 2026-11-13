import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../console/core/formatters.dart';
import '../../console/models/ops_models.dart' show Tone;
import '../../console/state/theme_controller.dart';
import '../../console/theme/console_theme.dart';
import '../../console/widgets/action_button.dart';
import '../../console/widgets/page_header.dart';
import '../../console/widgets/section_card.dart';
import '../../console/widgets/status_chip.dart';
import '../../console/widgets/toast.dart';
import '../state/driver_controller.dart';
import '../widgets/driver_widgets.dart';
import 'driver_support.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key, required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    return SnapshotView(
      builder: (context, snapshot, driver) {
        final c = context.cc;
        final p = snapshot.profile;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              eyebrow: 'Your account',
              title: 'My profile',
              subtitle: 'Personal details and driving credentials.',
            ),
            SectionCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: c.blue,
                    child: Text(
                      initialsOf(p.name),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.text),
                        ),
                        const SizedBox(height: 4),
                        Text('Driver ID · ${p.driverId}', style: TextStyle(fontSize: 12, color: c.muted)),
                        const SizedBox(height: 8),
                        const StatusChip(label: 'Active driver', tone: Tone.green),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            gap16,
            SectionCard(
              title: 'Driving credentials',
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StatGrid(
                    stats: [
                      ('Licence class', p.licenceClass),
                      ('Licence expiry', p.licenceExpiry),
                      ('Safety score', '${p.safetyScore} / 100'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  InfoRow(
                    icon: Icons.phone_outlined,
                    title: boldTitle(context, 'Phone'),
                    detail: p.phone.isEmpty ? '—' : p.phone,
                  ),
                  InfoRow(
                    icon: Icons.place_outlined,
                    title: boldTitle(context, 'Home base'),
                    detail: p.base,
                  ),
                  InfoRow(
                    icon: Icons.local_shipping_outlined,
                    title: boldTitle(context, 'Assigned vehicle'),
                    detail: p.vehicleLabel ?? 'None assigned',
                  ),
                ],
              ),
            ),
            gap16,
            SectionCard(
              title: 'App settings',
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Data source', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.text)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final source in DriverSource.values)
                        ChoiceChip(
                          label: Text(source.label),
                          selected: driver.source == source,
                          onSelected: (_) {
                            driver.setSource(source);
                            showToast(context, 'Now using ${source.label.toLowerCase()}');
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    driver.source == DriverSource.demo
                        ? 'Demo data works offline. Updates you make stay in memory until you close the app.'
                        : 'Your trips, status updates, fuel and incident reports use the Klan Fleet API.',
                    style: TextStyle(fontSize: 11.5, height: 1.4, color: c.muted),
                  ),
                  // The card paints a background, so the tile needs its own Material for ink.
                  Material(
                    type: MaterialType.transparency,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Dark theme', style: TextStyle(fontSize: 13, color: c.text)),
                      value: theme.dark,
                      onChanged: theme.setDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ActionButton(label: 'Sign out', icon: Icons.logout, onPressed: onSignOut),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
