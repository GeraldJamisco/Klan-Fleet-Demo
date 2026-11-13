import 'package:material_ui/material_ui.dart';

import '../models/ops_models.dart';
import '../theme/console_theme.dart';

/// A stylised map (no map provider needed) with labelled places and vehicle
/// pins. Positions are fractions of the map area, so real coordinates can be
/// projected into it later.
class FleetMapView extends StatelessWidget {
  const FleetMapView({
    super.key,
    this.pins = const [],
    this.counts = const {},
    this.places = defaultPlaces,
    this.height = 245,
    this.showRoute = false,
    this.onPinTap,
  });

  static const List<MapPlace> defaultPlaces = [
    MapPlace('KAMPALA', 0.43, 0.47),
    MapPlace('JINJA', 0.70, 0.21),
    MapPlace('GULU', 0.15, 0.22),
    MapPlace('MALABA', 0.78, 0.75),
    MapPlace('MBARARA', 0.25, 0.78),
  ];

  final List<MapPin> pins;
  final Map<PinState, int> counts;
  final List<MapPlace> places;
  final double height;
  final bool showRoute;
  final ValueChanged<MapPin>? onPinTap;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _MapPainter(dark: dark, route: showRoute, accent: c.blue2)),
                ),
                for (final place in places)
                  Positioned(
                    left: w * place.dx,
                    top: h * place.dy,
                    child: Text(
                      place.name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: dark ? const Color(0xFFBDC9D6) : const Color(0xFF4F6275),
                      ),
                    ),
                  ),
                for (final pin in pins)
                  Positioned(
                    left: w * pin.dx - 16,
                    top: h * pin.dy - 16,
                    child: Semantics(
                      button: true,
                      label: '${pin.label}, ${pin.state.label}',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onPinTap == null ? null : () => onPinTap!(pin),
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: Center(
                            child: Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                color: c.tone(pin.state.tone).fg,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFFFFFFF), width: 2),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x44000000), blurRadius: 4, offset: Offset(0, 1)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (counts.isNotEmpty)
                  Positioned(
                    left: 12,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Wrap(
                        spacing: 12,
                        children: [
                          for (final entry in counts.entries)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: c.tone(entry.key.tone).fg,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${entry.key.label} ${entry.value}',
                                  style: TextStyle(fontSize: 10, color: c.muted),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class MapPlace {
  const MapPlace(this.name, this.dx, this.dy);

  final String name;
  final double dx;
  final double dy;
}

class _MapPainter extends CustomPainter {
  _MapPainter({required this.dark, required this.route, required this.accent});

  final bool dark;
  final bool route;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final background = dark ? const Color(0xFF243447) : const Color(0xFFEAF0F4);
    final road = dark ? const Color(0xFF35495D) : const Color(0xFFFFFFFF);
    final park = dark ? const Color(0xFF294638) : const Color(0xFFDCE8DF);

    canvas.drawRect(Offset.zero & size, Paint()..color = background);

    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.66, size.width, size.height * 0.1),
      Paint()..color = park,
    );

    final roadPaint = Paint()
      ..color = road
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    const segments = [
      [0.0, 0.35, 1.0, 0.15],
      [0.0, 0.92, 0.72, 0.0],
      [0.2, 0.0, 0.36, 1.0],
      [0.0, 0.6, 1.0, 0.55],
      [0.55, 0.0, 0.92, 1.0],
    ];
    for (final s in segments) {
      canvas.drawLine(
        Offset(size.width * s[0], size.height * s[1]),
        Offset(size.width * s[2], size.height * s[3]),
        roadPaint,
      );
    }

    if (route) {
      canvas.drawLine(
        Offset(size.width * 0.15, size.height * 0.63),
        Offset(size.width * 0.79, size.height * 0.30),
        Paint()
          ..color = accent
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_MapPainter oldDelegate) =>
      oldDelegate.dark != dark || oldDelegate.route != route || oldDelegate.accent != accent;
}
