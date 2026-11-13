import 'package:material_ui/material_ui.dart';

import '../models/ops_models.dart';
import '../theme/console_theme.dart';

/// Small pill with a dot and a label. Never relies on colour alone.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.tone});

  factory StatusChip.trip(TripStatus status, {Key? key}) =>
      StatusChip(key: key, label: status.label, tone: status.tone);

  final String label;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.cc.tone(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: colors.fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.fg),
            ),
          ),
        ],
      ),
    );
  }
}
