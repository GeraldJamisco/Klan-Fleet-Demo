import 'package:material_ui/material_ui.dart';

import '../theme/console_theme.dart';

/// Shared look of every text field and dropdown in the console.
InputDecoration consoleDecoration(
  BuildContext context, {
  String? label,
  String? hint,
  IconData? prefixIcon,
  String? errorText,
}) {
  final c = context.cc;
  OutlineInputBorder border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    errorText: errorText,
    isDense: true,
    filled: true,
    fillColor: c.surface,
    prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 18),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: border(c.line),
    enabledBorder: border(c.line),
    focusedBorder: border(c.blue2),
    errorBorder: border(c.red),
    focusedErrorBorder: border(c.red),
  );
}

/// A dropdown that looks like the other fields. [value] must be one of [items].
class ConsoleDropdown<T> extends StatelessWidget {
  const ConsoleDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.label,
    this.errorText,
    this.width,
  });

  final T value;
  final List<T> items;
  final String Function(T item) labelOf;
  final ValueChanged<T> onChanged;
  final String? label;
  final String? errorText;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    final field = InputDecorator(
      decoration: consoleDecoration(context, label: label, errorText: errorText),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          borderRadius: BorderRadius.circular(10),
          dropdownColor: c.surface,
          style: TextStyle(fontSize: 12.5, color: c.text),
          items: [
            for (final item in items)
              DropdownMenuItem<T>(
                value: item,
                child: Text(labelOf(item), overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (selected) {
            if (selected != null) onChanged(selected);
          },
        ),
      ),
    );
    return width == null ? field : SizedBox(width: width, child: field);
  }
}

/// Search box that stays in sync with a value owned by someone else.
class ConsoleSearchField extends StatefulWidget {
  const ConsoleSearchField({
    super.key,
    required this.value,
    required this.onChanged,
    this.hint = 'Search…',
    this.width,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String hint;
  final double? width;

  @override
  State<ConsoleSearchField> createState() => _ConsoleSearchFieldState();
}

class _ConsoleSearchFieldState extends State<ConsoleSearchField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(ConsoleSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      style: const TextStyle(fontSize: 12.5),
      decoration: consoleDecoration(
        context,
        hint: widget.hint,
        prefixIcon: Icons.search,
      ),
    );
    return widget.width == null ? field : SizedBox(width: widget.width, child: field);
  }
}
