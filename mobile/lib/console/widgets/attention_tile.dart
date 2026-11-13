import 'package:material_ui/material_ui.dart';

import '../models/ops_models.dart';
import '../theme/console_theme.dart';
import 'action_button.dart';
import 'kpi_card.dart';

/// One "needs attention" row: icon, text and a single action.
class AttentionTile extends StatelessWidget {
  const AttentionTile({super.key, required this.item, required this.onAction});

  final AttentionItem item;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    final colors = c.tone(item.critical ? Tone.red : Tone.amber);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: colors.bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(kpiIcon(item.icon), size: 16, color: colors.fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.text),
                ),
                const SizedBox(height: 3),
                Text(item.detail, style: TextStyle(fontSize: 11, color: c.muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ActionButton(label: item.actionLabel, onPressed: onAction, compact: true),
        ],
      ),
    );
  }
}
