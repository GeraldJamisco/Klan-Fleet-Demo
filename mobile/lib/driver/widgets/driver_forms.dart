import 'package:material_ui/material_ui.dart';

import '../../console/theme/console_theme.dart';
import '../../console/widgets/action_button.dart';
import '../../console/widgets/async_view.dart' show describeError;
import '../../console/widgets/inputs.dart';
import '../../console/widgets/toast.dart';
import '../data/driver_repository.dart';
import '../models/driver_models.dart';
import '../state/driver_controller.dart';

/// Shared frame of the four driver forms: title, fields, error and buttons.
class _FormFrame extends StatelessWidget {
  const _FormFrame({
    required this.title,
    required this.children,
    required this.submitLabel,
    required this.saving,
    required this.onSubmit,
    required this.onCancel,
    this.error,
  });

  final String title;
  final List<Widget> children;
  final String submitLabel;
  final bool saving;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    return Padding(
      padding: const EdgeInsets.all(22),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: c.text),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: saving ? null : onCancel,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final child in children) ...[child, const SizedBox(height: 14)],
            if (error != null) ...[
              Text(error!, style: TextStyle(fontSize: 12, color: c.red)),
              const SizedBox(height: 12),
            ],
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionButton(label: 'Cancel', onPressed: saving ? null : onCancel),
                ActionButton(
                  label: saving ? 'Sending…' : submitLabel,
                  primary: true,
                  onPressed: saving ? null : onSubmit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _open(BuildContext host, Widget form) {
  return showDialog<void>(
    context: host,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: form),
    ),
  );
}

/// Runs [action], then closes the dialog, reloads the app data and confirms.
Future<void> _run({
  required State state,
  required BuildContext host,
  required DriverController driver,
  required Future<void> Function() action,
  required String done,
  required void Function(bool saving, String? error) setSaving,
}) async {
  setSaving(true, null);
  final navigator = Navigator.of(state.context);
  try {
    await action();
    if (!state.mounted) return;
    navigator.pop();
    driver.refresh();
    if (host.mounted) showToast(host, done);
  } catch (error) {
    if (!state.mounted) return;
    setSaving(false, describeError(error));
  }
}

// ----------------------------------------------------------------- status

Future<void> showStatusForm(BuildContext host, DriverController driver, DriverTrip trip) =>
    _open(host, _StatusForm(host: host, driver: driver, trip: trip));

class _StatusForm extends StatefulWidget {
  const _StatusForm({required this.host, required this.driver, required this.trip});

  final BuildContext host;
  final DriverController driver;
  final DriverTrip trip;

  @override
  State<_StatusForm> createState() => _StatusFormState();
}

class _StatusFormState extends State<_StatusForm> {
  late final List<StatusChoice> _choices = widget.driver.repository.statusChoices(widget.trip);
  late StatusChoice? _choice = _choices.isEmpty ? null : _choices.first;
  final _location = TextEditingController();
  final _notes = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final choice = _choice;
    return _FormFrame(
      title: 'Update trip status',
      submitLabel: 'Submit update',
      saving: _saving,
      error: _error,
      onCancel: () => Navigator.of(context).pop(),
      onSubmit: () {
        if (choice == null) {
          setState(() => _error = 'This trip has no further steps.');
          return;
        }
        _run(
          state: this,
          host: widget.host,
          driver: widget.driver,
          action: () => widget.driver.repository.updateStatus(
            widget.trip,
            StatusUpdate(choice: choice, location: _location.text, notes: _notes.text),
          ),
          done: 'Trip update queued for dispatch and ERP sync.',
          setSaving: (saving, error) => setState(() {
            _saving = saving;
            _error = error;
          }),
        );
      },
      children: [
        if (choice == null)
          Text('This trip is closed, so there is nothing to update.', style: TextStyle(fontSize: 12.5, color: context.cc.muted))
        else
          ConsoleDropdown<StatusChoice>(
            label: 'New trip status',
            value: choice,
            items: _choices,
            labelOf: (v) => v.label,
            onChanged: (v) => setState(() => _choice = v),
          ),
        TextField(
          controller: _location,
          style: const TextStyle(fontSize: 12.5),
          decoration: consoleDecoration(
            context,
            label: 'Current location / checkpoint',
            hint: 'Enter your location',
          ),
        ),
        TextField(
          controller: _notes,
          minLines: 3,
          maxLines: 4,
          style: const TextStyle(fontSize: 12.5),
          decoration: consoleDecoration(
            context,
            label: 'Notes for dispatch',
            hint: 'Add an optional update',
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------- fuel

Future<void> showFuelForm(BuildContext host, DriverController driver, DriverTrip trip) =>
    _open(host, _FuelForm(host: host, driver: driver, trip: trip));

class _FuelForm extends StatefulWidget {
  const _FuelForm({required this.host, required this.driver, required this.trip});

  final BuildContext host;
  final DriverController driver;
  final DriverTrip trip;

  @override
  State<_FuelForm> createState() => _FuelFormState();
}

class _FuelFormState extends State<_FuelForm> {
  final _station = TextEditingController();
  final _litres = TextEditingController();
  final _amount = TextEditingController();
  final _odometer = TextEditingController();
  final _receipt = TextEditingController();
  String? _litresError;
  String? _amountError;
  String? _odometerError;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _station.dispose();
    _litres.dispose();
    _amount.dispose();
    _odometer.dispose();
    _receipt.dispose();
    super.dispose();
  }

  void _submit() {
    final litres = double.tryParse(_litres.text.trim());
    final amount = int.tryParse(_amount.text.trim().replaceAll(',', ''));
    final odometerText = _odometer.text.trim();
    final odometer = odometerText.isEmpty ? null : int.tryParse(odometerText);

    final litresError = litres == null || litres <= 0 ? 'Enter the litres' : null;
    final amountError = amount == null || amount <= 0 ? 'Enter the amount in UGX' : null;
    final odometerError = odometerText.isNotEmpty && odometer == null ? 'Numbers only' : null;
    if (litresError != null || amountError != null || odometerError != null) {
      setState(() {
        _litresError = litresError;
        _amountError = amountError;
        _odometerError = odometerError;
      });
      return;
    }

    _run(
      state: this,
      host: widget.host,
      driver: widget.driver,
      action: () => widget.driver.repository.logFuel(
        widget.trip,
        FuelRequest(
          station: _station.text.trim(),
          litres: litres!,
          amountUgx: amount!,
          odometerKm: odometer,
          receipt: _receipt.text.trim(),
        ),
      ),
      done: 'Fuel entry saved and queued for finance review.',
      setSaving: (saving, error) => setState(() {
        _saving = saving;
        _error = error;
        _litresError = null;
        _amountError = null;
        _odometerError = null;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    TextField field(
      TextEditingController controller,
      String label,
      String hint, {
      String? error,
      bool numeric = false,
    }) =>
        TextField(
          controller: controller,
          keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          style: const TextStyle(fontSize: 12.5),
          decoration: consoleDecoration(context, label: label, hint: hint, errorText: error),
        );

    return _FormFrame(
      title: 'Log fuel',
      submitLabel: 'Submit update',
      saving: _saving,
      error: _error,
      onCancel: () => Navigator.of(context).pop(),
      onSubmit: _submit,
      children: [
        field(_station, 'Fuel station', 'e.g. Total Malaba'),
        field(_litres, 'Litres', '0', error: _litresError, numeric: true),
        field(_amount, 'Total amount (UGX)', 'e.g. 450000', error: _amountError, numeric: true),
        field(_odometer, 'Odometer (km)', 'e.g. 184900', error: _odometerError, numeric: true),
        field(_receipt, 'Receipt reference', 'Receipt number / reference'),
      ],
    );
  }
}

// ------------------------------------------------------------------ issue

Future<void> showIssueForm(BuildContext host, DriverController driver, DriverTrip? trip) =>
    _open(host, _IssueForm(host: host, driver: driver, trip: trip));

class _IssueForm extends StatefulWidget {
  const _IssueForm({required this.host, required this.driver, required this.trip});

  final BuildContext host;
  final DriverController driver;
  final DriverTrip? trip;

  @override
  State<_IssueForm> createState() => _IssueFormState();
}

class _IssueFormState extends State<_IssueForm> {
  IssueCategory _category = IssueCategory.breakdown;
  IssueSeverity _severity = IssueSeverity.low;
  final _location = TextEditingController();
  final _description = TextEditingController();
  String? _descriptionError;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (_description.text.trim().isEmpty) {
      setState(() => _descriptionError = 'Describe what happened');
      return;
    }
    _run(
      state: this,
      host: widget.host,
      driver: widget.driver,
      action: () => widget.driver.repository.reportIssue(
        widget.trip,
        IssueRequest(
          category: _category,
          severity: _severity,
          location: _location.text,
          description: _description.text,
        ),
      ),
      done: 'Issue report sent to the operations team.',
      setSaving: (saving, error) => setState(() {
        _saving = saving;
        _error = error;
        _descriptionError = null;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FormFrame(
      title: 'Report an issue',
      submitLabel: 'Submit report',
      saving: _saving,
      error: _error,
      onCancel: () => Navigator.of(context).pop(),
      onSubmit: _submit,
      children: [
        ConsoleDropdown<IssueCategory>(
          label: 'Issue category',
          value: _category,
          items: IssueCategory.values,
          labelOf: (v) => v.label,
          onChanged: (v) => setState(() => _category = v),
        ),
        ConsoleDropdown<IssueSeverity>(
          label: 'Severity',
          value: _severity,
          items: IssueSeverity.values,
          labelOf: (v) => v.label,
          onChanged: (v) => setState(() => _severity = v),
        ),
        TextField(
          controller: _location,
          style: const TextStyle(fontSize: 12.5),
          decoration: consoleDecoration(context, label: 'Location', hint: 'Where did this happen?'),
        ),
        TextField(
          controller: _description,
          minLines: 3,
          maxLines: 4,
          style: const TextStyle(fontSize: 12.5),
          decoration: consoleDecoration(
            context,
            label: 'Description',
            hint: 'Describe what happened and whether anyone needs assistance.',
            errorText: _descriptionError,
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ proof

Future<void> showProofForm(BuildContext host, DriverController driver, DriverTrip trip) =>
    _open(host, _ProofForm(host: host, driver: driver, trip: trip));

class _ProofForm extends StatefulWidget {
  const _ProofForm({required this.host, required this.driver, required this.trip});

  final BuildContext host;
  final DriverController driver;
  final DriverTrip trip;

  @override
  State<_ProofForm> createState() => _ProofFormState();
}

class _ProofFormState extends State<_ProofForm> {
  final _receiver = TextEditingController();
  final _notes = TextEditingController();
  DeliveryConfirmation? _confirmation;
  String? _receiverError;
  String? _confirmationError;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _receiver.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    final confirmation = _confirmation;
    final receiverError = _receiver.text.trim().isEmpty ? 'Enter the receiver’s name' : null;
    final confirmationError = confirmation == null ? 'Select a confirmation' : null;
    if (receiverError != null || confirmationError != null) {
      setState(() {
        _receiverError = receiverError;
        _confirmationError = confirmationError;
      });
      return;
    }
    _run(
      state: this,
      host: widget.host,
      driver: widget.driver,
      action: () => widget.driver.repository.submitProof(
        widget.trip,
        DeliveryProof(
          receiver: _receiver.text,
          confirmation: confirmation!,
          notes: _notes.text,
        ),
      ),
      done: 'Proof of delivery submitted for verification.',
      setSaving: (saving, error) => setState(() {
        _saving = saving;
        _error = error;
        _receiverError = null;
        _confirmationError = null;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FormFrame(
      title: 'Proof of delivery',
      submitLabel: 'Submit proof',
      saving: _saving,
      error: _error,
      onCancel: () => Navigator.of(context).pop(),
      onSubmit: _submit,
      children: [
        const _Notice(
          title: 'Delivery confirmation',
          body: 'Only submit proof after the receiver has accepted the cargo and the documents are complete. '
              'Photo upload arrives with the phone build.',
        ),
        TextField(
          controller: _receiver,
          style: const TextStyle(fontSize: 12.5),
          decoration: consoleDecoration(
            context,
            label: 'Receiver name',
            hint: 'Full name of receiving person',
            errorText: _receiverError,
          ),
        ),
        TextField(
          controller: _notes,
          minLines: 2,
          maxLines: 3,
          style: const TextStyle(fontSize: 12.5),
          decoration: consoleDecoration(
            context,
            label: 'Delivery notes',
            hint: 'Condition of cargo, quantities, exceptions',
          ),
        ),
        ConsoleDropdown<DeliveryConfirmation?>(
          label: 'Confirmation',
          value: _confirmation,
          items: const [null, DeliveryConfirmation.full, DeliveryConfirmation.partial],
          labelOf: (v) => v?.label ?? 'Select confirmation',
          errorText: _confirmationError,
          onChanged: (v) => setState(() => _confirmation = v),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.blueWash, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.blue)),
          const SizedBox(height: 3),
          Text(body, style: TextStyle(fontSize: 11.5, height: 1.4, color: c.blue)),
        ],
      ),
    );
  }
}
