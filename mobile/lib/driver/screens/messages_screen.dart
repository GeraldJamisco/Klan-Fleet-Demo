import 'package:material_ui/material_ui.dart';

import '../../console/models/ops_models.dart' show Tone;
import '../../console/theme/console_theme.dart';
import '../../console/widgets/async_view.dart';
import '../../console/widgets/page_header.dart';
import '../../console/widgets/section_card.dart';
import '../../console/widgets/status_chip.dart';
import '../widgets/driver_widgets.dart';
import 'driver_support.dart';

class DriverMessagesScreen extends StatelessWidget {
  const DriverMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SnapshotView(
      builder: (context, snapshot, driver) {
        final c = context.cc;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              eyebrow: 'Operations communication',
              title: 'Messages',
              subtitle: 'Updates from dispatch and the operations team.',
            ),
            SectionCard(
              title: 'Inbox',
              trailing: Text(
                '${snapshot.unreadMessages} unread',
                style: TextStyle(fontSize: 11, color: c.muted),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: snapshot.messages.isEmpty
                  ? const EmptyState(
                      title: 'No messages',
                      message: 'Dispatch updates appear here.',
                      icon: Icons.mail_outline,
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < snapshot.messages.length; i++) ...[
                          if (i > 0) Divider(color: c.line),
                          InfoRow(
                            icon: messageIcon(snapshot.messages[i].kind),
                            title: Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                boldTitle(context, '${snapshot.messages[i].sender} · ${snapshot.messages[i].title}'),
                                if (snapshot.messages[i].unread)
                                  const StatusChip(label: 'New', tone: Tone.blue),
                              ],
                            ),
                            detail: snapshot.messages[i].body,
                            time: snapshot.messages[i].time,
                          ),
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
