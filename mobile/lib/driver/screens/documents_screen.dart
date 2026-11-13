import 'package:material_ui/material_ui.dart';

import '../../console/theme/console_theme.dart';
import '../../console/widgets/action_button.dart';
import '../../console/widgets/async_view.dart';
import '../../console/widgets/page_header.dart';
import '../../console/widgets/section_card.dart';
import '../../console/widgets/status_chip.dart';
import '../../console/widgets/toast.dart';
import '../widgets/driver_widgets.dart';
import 'driver_support.dart';

class DriverDocumentsScreen extends StatelessWidget {
  const DriverDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SnapshotView(
      builder: (context, snapshot, driver) {
        final c = context.cc;
        final trip = snapshot.activeTrip;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              eyebrow: 'Trip paperwork',
              title: 'Documents',
              subtitle: 'Documents attached to your current assignment.',
            ),
            SectionCard(
              title: trip == null ? 'Required documents' : '${trip.ref} · Required documents',
              trailing: Text(
                '${snapshot.readyDocuments} of ${snapshot.documents.length} ready',
                style: TextStyle(fontSize: 11, color: c.muted),
              ),
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: snapshot.documents.isEmpty
                  ? const EmptyState(
                      title: 'No documents yet',
                      message: 'Paperwork for your trip appears here.',
                      icon: Icons.description_outlined,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < snapshot.documents.length; i++) ...[
                          if (i > 0) Divider(color: c.line),
                          InfoRow(
                            icon: Icons.description_outlined,
                            title: boldTitle(context, snapshot.documents[i].title),
                            detail: snapshot.documents[i].detail,
                            trailing: StatusChip(
                              label: snapshot.documents[i].state.label,
                              tone: snapshot.documents[i].state.tone,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        ActionButton(
                          label: 'Open selected document',
                          expand: true,
                          onPressed: () => showToast(context, 'Document preview is simulated in this prototype.'),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}
