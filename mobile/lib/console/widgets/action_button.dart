import 'package:material_ui/material_ui.dart';

import '../theme/console_theme.dart';

/// Primary (filled) or secondary (outlined) button in the console's style.
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.primary = false,
    this.compact = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool primary;
  final bool compact;

  /// Stretches the button to the full available width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(9));
    final padding = EdgeInsets.symmetric(
      horizontal: compact ? 10 : 14,
      vertical: compact ? 6 : 10,
    );
    final minimum = Size(expand ? double.infinity : 0, compact ? 34 : 42);
    final textStyle = TextStyle(
      fontSize: compact ? 11.5 : 12.5,
      fontWeight: FontWeight.w600,
    );

    final Widget button;
    if (primary) {
      final style = FilledButton.styleFrom(
        shape: shape,
        padding: padding,
        minimumSize: minimum,
        textStyle: textStyle,
      );
      button = icon == null
          ? FilledButton(onPressed: onPressed, style: style, child: Text(label))
          : FilledButton.icon(
              onPressed: onPressed,
              style: style,
              icon: Icon(icon, size: 16),
              label: Text(label),
            );
    } else {
      final style = OutlinedButton.styleFrom(
        shape: shape,
        padding: padding,
        minimumSize: minimum,
        textStyle: textStyle,
        foregroundColor: c.text,
        side: BorderSide(color: c.line),
        backgroundColor: c.surface,
      );
      button = icon == null
          ? OutlinedButton(onPressed: onPressed, style: style, child: Text(label))
          : OutlinedButton.icon(
              onPressed: onPressed,
              style: style,
              icon: Icon(icon, size: 16),
              label: Text(label),
            );
    }
    return button;
  }
}
