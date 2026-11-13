import 'package:material_ui/material_ui.dart';

import '../models/ops_models.dart';
import '../theme/console_theme.dart';

class TimelineList extends StatelessWidget {
  const TimelineList({super.key, required this.entries});

  final List<TimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    if (entries.isEmpty) {
      return Text('No events yet.', style: TextStyle(fontSize: 12, color: c.muted));
    }
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 12,
                  child: Column(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(color: c.blue2, shape: BoxShape.circle),
                      ),
                      if (i < entries.length - 1)
                        Expanded(
                          child: Container(
                            width: 1,
                            margin: const EdgeInsets.only(top: 4),
                            color: c.line,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entries[i].title,
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.text),
                        ),
                        if (entries[i].detail.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            entries[i].detail,
                            style: TextStyle(fontSize: 11, color: c.muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
