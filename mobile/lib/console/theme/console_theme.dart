import 'package:material_ui/material_ui.dart';

import '../models/ops_models.dart' show Tone;

/// Semantic colours of the console, taken from the Nexora prototype.
/// Read them with `context.cc`.
@immutable
class ConsoleColors extends ThemeExtension<ConsoleColors> {
  const ConsoleColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.text,
    required this.muted,
    required this.line,
    required this.blue,
    required this.blue2,
    required this.blueWash,
    required this.green,
    required this.greenBg,
    required this.amber,
    required this.amberBg,
    required this.red,
    required this.redBg,
  });

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color text;
  final Color muted;
  final Color line;
  final Color blue;
  final Color blue2;
  final Color blueWash;
  final Color green;
  final Color greenBg;
  final Color amber;
  final Color amberBg;
  final Color red;
  final Color redBg;

  static const ConsoleColors light = ConsoleColors(
    bg: Color(0xFFF4F6FA),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF8FAFC),
    text: Color(0xFF172338),
    muted: Color(0xFF63728A),
    line: Color(0xFFE5EAF1),
    blue: Color(0xFF173F78),
    blue2: Color(0xFF245DA5),
    blueWash: Color(0xFFEAF1FB),
    green: Color(0xFF16845B),
    greenBg: Color(0xFFE8F6EF),
    amber: Color(0xFFA96A0A),
    amberBg: Color(0xFFFFF4DF),
    red: Color(0xFFBD4545),
    redBg: Color(0xFFFFF0EF),
  );

  static const ConsoleColors dark = ConsoleColors(
    bg: Color(0xFF0D1522),
    surface: Color(0xFF141F30),
    surface2: Color(0xFF192638),
    text: Color(0xFFE8EEF7),
    muted: Color(0xFF9AABC0),
    line: Color(0xFF28364A),
    blue: Color(0xFF6D9FE5),
    blue2: Color(0xFF8AB5F3),
    blueWash: Color(0xFF20324A),
    green: Color(0xFF65C99B),
    greenBg: Color(0xFF17392E),
    amber: Color(0xFFF0BD67),
    amberBg: Color(0xFF3B2E1C),
    red: Color(0xFFFF8983),
    redBg: Color(0xFF3C2427),
  );

  /// Foreground and background for a chip or icon tile of the given [tone].
  ({Color fg, Color bg}) tone(Tone tone) {
    switch (tone) {
      case Tone.green:
        return (fg: green, bg: greenBg);
      case Tone.blue:
        return (fg: blue, bg: blueWash);
      case Tone.amber:
        return (fg: amber, bg: amberBg);
      case Tone.red:
        return (fg: red, bg: redBg);
      case Tone.gray:
        return (fg: muted, bg: surface2);
    }
  }

  @override
  ConsoleColors copyWith() => this;

  @override
  ConsoleColors lerp(ThemeExtension<ConsoleColors>? other, double t) {
    if (other is! ConsoleColors) return this;
    return t < 0.5 ? this : other;
  }
}

extension ConsoleColorsOnContext on BuildContext {
  ConsoleColors get cc => Theme.of(this).extension<ConsoleColors>() ?? ConsoleColors.light;
}

ThemeData buildConsoleTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final c = isDark ? ConsoleColors.dark : ConsoleColors.light;

  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF173F78),
    brightness: brightness,
  ).copyWith(
    primary: c.blue,
    onPrimary: isDark ? const Color(0xFF0D1522) : const Color(0xFFFFFFFF),
    surface: c.surface,
    onSurface: c.text,
    outline: c.line,
    outlineVariant: c.line,
    error: c.red,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
  );

  return base.copyWith(
    scaffoldBackgroundColor: c.bg,
    textTheme: base.textTheme.apply(bodyColor: c.text, displayColor: c.text),
    dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
    extensions: <ThemeExtension<dynamic>>[c],
  );
}
