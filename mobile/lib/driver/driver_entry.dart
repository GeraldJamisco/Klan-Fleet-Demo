import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/session.dart';
import 'data/api_driver_repository.dart';
import 'data/demo_driver_repository.dart';
import 'models/driver_models.dart';
import 'shell/driver_shell.dart';
import 'state/driver_controller.dart';

/// Entry point used by `main.dart` for signed-in drivers.
class DriverEntry extends StatefulWidget {
  const DriverEntry({super.key});

  @override
  State<DriverEntry> createState() => _DriverEntryState();
}

class _DriverEntryState extends State<DriverEntry> {
  late final DriverController _controller;

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionController>();
    final user = session.user!;
    const sample = DemoDriverRepository.sampleProfile;

    // Demo data is shown under the signed-in driver's own name.
    final profile = DriverProfile(
      name: user.name,
      driverId: DriverProfile.idLabel(user.id),
      phone: user.phone,
      licenceClass: sample.licenceClass,
      licenceExpiry: sample.licenceExpiry,
      safetyScore: sample.safetyScore,
      base: sample.base,
      vehicleLabel: sample.vehicleLabel,
    );

    _controller = DriverController(
      userName: user.name,
      demoRepository: DemoDriverRepository(profile: profile),
      liveRepository: ApiDriverRepository(
        client: () => session.api,
        user: () => session.user!,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DriverController>.value(
      value: _controller,
      child: DriverShell(
        onSignOut: () => context.read<SessionController>().logout(),
      ),
    );
  }
}
