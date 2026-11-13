import 'package:flutter/foundation.dart';

/// Light or dark appearance, shared by the whole app.
class ThemeController extends ChangeNotifier {
  bool _dark = false;

  bool get dark => _dark;

  void toggle() {
    _dark = !_dark;
    notifyListeners();
  }

  void setDark(bool value) {
    if (value == _dark) return;
    _dark = value;
    notifyListeners();
  }
}
