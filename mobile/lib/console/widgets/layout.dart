import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

class Breakpoints {
  const Breakpoints._();

  /// Below this width the console uses the phone layout (bottom navigation).
  static const double phone = 760;

  /// From this width the sidebar shows labels, below it only icons.
  static const double wide = 1100;
}

bool isPhoneWidth(BuildContext context) =>
    MediaQuery.sizeOf(context).width < Breakpoints.phone;

/// Lays children out in as many equal columns as fit.
class AdaptiveGrid extends StatelessWidget {
  const AdaptiveGrid({
    super.key,
    required this.children,
    this.minTileWidth = 150,
    this.maxColumns = 6,
    this.spacing = 16,
  });

  final List<Widget> children;
  final double minTileWidth;
  final int maxColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final fit = ((width + spacing) / (minTileWidth + spacing)).floor();
        final columns = math.max(1, math.min(maxColumns, fit));
        final tileWidth = (width - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: tileWidth, child: child),
          ],
        );
      },
    );
  }
}

/// Two blocks side by side on wide screens, stacked on narrow ones.
class ResponsiveRow extends StatelessWidget {
  const ResponsiveRow({
    super.key,
    required this.left,
    required this.right,
    this.leftFlex = 3,
    this.rightFlex = 2,
    this.breakpoint = 900,
    this.spacing = 16,
  });

  final Widget left;
  final Widget right;
  final int leftFlex;
  final int rightFlex;
  final double breakpoint;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: leftFlex, child: left),
              SizedBox(width: spacing),
              Expanded(flex: rightFlex, child: right),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            left,
            SizedBox(height: spacing),
            right,
          ],
        );
      },
    );
  }
}
