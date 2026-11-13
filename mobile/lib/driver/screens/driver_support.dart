import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../console/widgets/async_view.dart';
import '../../console/widgets/toast.dart';
import '../models/driver_models.dart';
import '../state/driver_controller.dart';

extension DriverContext on BuildContext {
  /// The driver state; rebuilds the caller when it changes.
  DriverController get driver => watch<DriverController>();
}

/// Loads the shared snapshot and shows it, with a skeleton and retry.
class SnapshotView extends StatelessWidget {
  const SnapshotView({super.key, required this.builder});

  final Widget Function(BuildContext context, DriverSnapshot snapshot, DriverController driver) builder;

  @override
  Widget build(BuildContext context) {
    final driver = context.driver;
    return DataLoader<DriverSnapshot>(
      load: () => driver.snapshot,
      reloadKey: driver.refreshTick,
      builder: (context, snapshot) => builder(context, snapshot, driver),
    );
  }
}

/// Opens [open] with the active trip, or says there is none.
void withActiveTrip(
  BuildContext context,
  DriverSnapshot snapshot,
  void Function(DriverTrip trip) open,
) {
  final trip = snapshot.activeTrip;
  if (trip == null) {
    showToast(context, 'You have no active trip right now.');
  } else {
    open(trip);
  }
}

const SizedBox gap16 = SizedBox(height: 16);
