import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/session.dart';
import 'core/access.dart';
import 'data/api_repository.dart';
import 'data/demo_repository.dart';
import 'shell/console_shell.dart';
import 'state/console_controller.dart';

/// Entry point used by `main.dart` for signed-in managers. Builds the console
/// state from the session and shows the shell.
class ConsoleEntry extends StatefulWidget {
  const ConsoleEntry({super.key});

  @override
  State<ConsoleEntry> createState() => _ConsoleEntryState();
}

class _ConsoleEntryState extends State<ConsoleEntry> {
  late final ConsoleController _controller;

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionController>();
    final user = session.user!;
    _controller = ConsoleController(
      actualRole: ConsoleRole.fromApi(user.role),
      userName: user.name,
      demoRepository: DemoConsoleRepository(),
      liveRepository: ApiConsoleRepository(() => session.api),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ConsoleController>.value(
      value: _controller,
      child: ConsoleShell(
        onSignOut: () => context.read<SessionController>().logout(),
      ),
    );
  }
}
