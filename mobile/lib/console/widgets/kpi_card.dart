import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../models/ops_models.dart';
import '../theme/console_theme.dart';
import 'layout.dart';

/// Resolves the icon keys used by the models (`KpiStat.icon`, `AttentionItem.icon`).
IconData kpiIcon(String key) {
  switch (key) {
    case 'trips':
      return Icons.swap_horiz;
    case 'clock':
      return Icons.schedule;
    case 'truck':
      return Icons.local_shipping_outlined;
    case 'fuel':
      return Icons.local_gas_station_outlined;
    case 'flag':
      return Icons.flag_outlined;
    case 'sync':
      return Icons.sync;
    case 'check':
      return Icons.check_circle_outline;
    case 'wrench':
      return Icons.build_outlined;
    case 'people':
      return Icons.badge_outlined;
    case 'invoice':
      return Icons.receipt_long_outlined;
    case 'pallet':
      return Icons.inventory_2_outlined;
    case 'pin':
      return Icons.place_outlined;
    case 'return':
      return Icons.undo;
    case 'shield':
      return Icons.shield_outlined;
    case 'dashboard':
      return Icons.dashboard_outlined;
    case 'chart':
      return Icons.bar_chart;
    case 'alert':
    default:
      return Icons.error_outline;
  }
}

class KpiCard extends StatelessWidget {
  const KpiCard({super.key, required this.stat});

  final KpiStat stat;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    final trendColor = stat.positive ? c.green : c.red;
    return Semantics(
      label: '${stat.label}: ${stat.value}. ${stat.trend}',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 13),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      stat.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.muted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 27,
                    height: 27,
                    decoration: BoxDecoration(
                      color: c.blueWash,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(kpiIcon(stat.icon), size: 15, color: c.blue),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  stat.value,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                    color: c.text,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      stat.trend,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: trendColor),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Sparkline(series: stat.series, color: trendColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.series, required this.color});

  final List<double> series;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(60, 20),
      painter: _SparkPainter(series, color),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.series, this.color);

  final List<double> series;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.length < 2) return;
    final minValue = series.reduce(math.min);
    final maxValue = series.reduce(math.max);
    final range = maxValue - minValue == 0 ? 1.0 : maxValue - minValue;
    final path = Path();
    for (var i = 0; i < series.length; i++) {
      final x = size.width * i / (series.length - 1);
      final y = size.height - 2 - (series[i] - minValue) / range * (size.height - 4);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparkPainter oldDelegate) =>
      oldDelegate.series != series || oldDelegate.color != color;
}

/// A responsive grid of KPI cards: 6 across on desktop, 2 on a phone.
class KpiGrid extends StatelessWidget {
  const KpiGrid({super.key, required this.stats});

  final List<KpiStat> stats;

  @override
  Widget build(BuildContext context) {
    return AdaptiveGrid(
      minTileWidth: 150,
      maxColumns: 6,
      spacing: 14,
      children: [for (final stat in stats) KpiCard(stat: stat)],
    );
  }
}
