import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/access.dart';
import '../state/console_controller.dart';
import '../widgets/toast.dart';

/// Shortcuts shared by every screen.
extension ConsoleContext on BuildContext {
  /// The console state; rebuilds the caller when it changes.
  ConsoleController get console => watch<ConsoleController>();

  /// The console state without listening (for button handlers).
  ConsoleController get consoleNow => read<ConsoleController>();
}

/// Actions that only make sense for roles that can change data.
bool canChange(AccessLevel level) => level.canManage;

/// Used by buttons whose back end action is not built yet.
VoidCallback notYet(BuildContext context, String message) =>
    () => showToast(context, message);

const SizedBox gap8 = SizedBox(height: 8);
const SizedBox gap16 = SizedBox(height: 16);
