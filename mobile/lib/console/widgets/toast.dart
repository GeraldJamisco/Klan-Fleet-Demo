import 'package:material_ui/material_ui.dart';

/// Short confirmation message at the bottom of the screen.
void showToast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  final wide = MediaQuery.sizeOf(context).width > 480;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        width: wide ? 400 : null,
        duration: const Duration(milliseconds: 2800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
}
