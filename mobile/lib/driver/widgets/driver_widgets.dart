import 'package:material_ui/material_ui.dart';

import '../../console/core/formatters.dart';
import '../../console/theme/console_theme.dart';
import '../../console/widgets/layout.dart';
import '../models/driver_models.dart';

/// Small labelled value inside a trip card.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10.5, color: c.muted)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text),
          ),
        ],
      ),
    );
  }
}

class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.stats});

  /// Pairs of label and value.
  final List<(String, String)> stats;

  @override
  Widget build(BuildContext context) {
    return AdaptiveGrid(
      minTileWidth: 110,
      maxColumns: 3,
      spacing: 10,
      children: [for (final s in stats) StatTile(label: s.$1, value: s.$2)],
    );
  }
}

/// Origin → destination, the heart of every trip card.
class RouteBlock extends StatelessWidget {
  const RouteBlock({super.key, required this.origin, required this.destination});

  final String origin;
  final String destination;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    Widget place(String label, String name, CrossAxisAlignment align) => Expanded(
          child: Column(
            crossAxisAlignment: align,
            children: [
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: c.muted)),
              const SizedBox(height: 4),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: c.text),
              ),
            ],
          ),
        );
    return Row(
      children: [
        place('ORIGIN', origin, CrossAxisAlignment.start),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.arrow_forward, size: 20, color: c.blue2),
        ),
        place('DESTINATION', destination, CrossAxisAlignment.end),
      ],
    );
  }
}

class CargoLine extends StatelessWidget {
  const CargoLine({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.blueWash, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(Icons.inventory_2_outlined, size: 18, color: c.blue),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12.5, color: c.text))),
        ],
      ),
    );
  }
}

class ProgressLine extends StatelessWidget {
  const ProgressLine({super.key, required this.fraction, required this.left, required this.right});

  final double fraction;
  final String left;
  final String right;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    return Column(
      children: [
        Semantics(
          label: 'Trip progress ${(fraction * 100).round()} percent',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: c.line,
              color: c.blue2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: Text(left, style: TextStyle(fontSize: 11, color: c.muted))),
            Text(right, style: TextStyle(fontSize: 11, color: c.muted)),
          ],
        ),
      ],
    );
  }
}

class SummaryTile extends StatelessWidget {
  const SummaryTile({super.key, required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: c.blue),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: c.text),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10.5, color: c.muted)),
        ],
      ),
    );
  }
}

class NoticeBanner extends StatelessWidget {
  const NoticeBanner({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.blueWash, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 19, color: c.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.blue)),
                const SizedBox(height: 3),
                Text(body, style: TextStyle(fontSize: 11.5, height: 1.4, color: c.blue)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData messageIcon(String kind) {
  switch (kind) {
    case 'warning':
      return Icons.warning_amber_outlined;
    case 'check':
      return Icons.check_circle_outline;
    case 'mail':
    default:
      return Icons.mail_outline;
  }
}

/// Icon tile + title + detail + optional trailing widget.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    this.time,
    this.trailing,
  });

  final IconData icon;
  final Widget title;
  final String detail;
  final String? time;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: c.blueWash, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 16, color: c.blue),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 3),
                Text(detail, style: TextStyle(fontSize: 11.5, height: 1.4, color: c.muted)),
                if (time != null) ...[
                  const SizedBox(height: 5),
                  Text(time!, style: TextStyle(fontSize: 10.5, color: c.muted)),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}

Widget boldTitle(BuildContext context, String text) =>
    Text(text, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: context.cc.text));

/// "—" when a value is missing.
String orDash(Object? value) => value == null ? '—' : '$value';

String kmLabel(int? km) => km == null ? '—' : '${thousands(km)} km';

String assignedLabel(DriverTrip trip) => '${trip.ref} · ${trip.route}';

/// "180 L" or "45.5 L".
String litresLabel(double litres) {
  final whole = litres == litres.roundToDouble();
  return '${whole ? thousands(litres) : litres.toStringAsFixed(1)} L';
}
