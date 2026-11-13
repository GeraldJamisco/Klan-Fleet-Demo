import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/console_theme.dart';

class BarGroup {
  const BarGroup(this.label, this.values);

  final String label;

  /// One value per series.
  final List<double> values;
}

String _plain(double value) =>
    value == value.roundToDouble() ? value.round().toString() : value.toStringAsFixed(1);

/// Simple grouped bar chart. Every bar has a tooltip with its exact value.
class BarChartView extends StatelessWidget {
  const BarChartView({
    super.key,
    required this.groups,
    required this.colors,
    this.seriesNames = const [],
    this.unit = '',
    this.height = 170,
  });

  final List<BarGroup> groups;
  final List<Color> colors;
  final List<String> seriesNames;
  final String unit;
  final double height;

  String _tip(BarGroup group, int i) {
    final series = i < seriesNames.length ? ' · ${seriesNames[i]}' : '';
    return '${group.label}$series: ${_plain(group.values[i])}$unit';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    final maxValue = groups.expand((g) => g.values).fold<double>(0, math.max);
    final plotHeight = height - 26;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final group in groups)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < group.values.length; i++)
                        Tooltip(
                          message: _tip(group, i),
                          child: Container(
                            width: 13,
                            height: maxValue == 0 ? 0 : group.values[i] / maxValue * plotHeight,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: colors[i % colors.length],
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    group.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5, color: c.muted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class LegendDot extends StatelessWidget {
  const LegendDot({super.key, required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, color: context.cc.muted)),
      ],
    );
  }
}

class ProgressRowData {
  const ProgressRowData({
    required this.label,
    required this.trailing,
    required this.fraction,
    required this.color,
  });

  final String label;
  final String trailing;

  /// 0 to 1.
  final double fraction;
  final Color color;
}

/// Label, bar and number on one line, repeated for each row.
class ProgressRows extends StatelessWidget {
  const ProgressRows({super.key, required this.rows, this.labelWidth = 100});

  final List<ProgressRowData> rows;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Semantics(
              label: '${row.label}: ${row.trailing}',
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    SizedBox(
                      width: labelWidth,
                      child: Text(
                        row.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          children: [
                            Container(height: 7, color: c.surface2),
                            FractionallySizedBox(
                              widthFactor: row.fraction.clamp(0.0, 1.0),
                              child: Container(height: 7, color: row.color),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 34,
                      child: Text(
                        row.trailing,
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: c.text),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
