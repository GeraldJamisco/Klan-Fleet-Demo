import 'package:material_ui/material_ui.dart';

import '../core/access.dart';
import '../core/formatters.dart';
import '../data/console_repository.dart';
import '../state/console_controller.dart';
import '../theme/console_theme.dart';
import '../widgets/action_button.dart';
import '../widgets/async_view.dart';
import '../widgets/inputs.dart';
import '../widgets/toast.dart';

/// Opens the "New trip" form. [host] must stay mounted (it shows the result).
Future<void> showNewTripDialog(BuildContext host, ConsoleController console) {
  return showDialog<void>(
    context: host,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: _NewTripForm(host: host, console: console),
      ),
    ),
  );
}

class _NewTripForm extends StatefulWidget {
  const _NewTripForm({required this.host, required this.console});

  final BuildContext host;
  final ConsoleController console;

  @override
  State<_NewTripForm> createState() => _NewTripFormState();
}

class _NewTripFormState extends State<_NewTripForm> {
  late final Future<NewTripOptions> _options =
      widget.console.repository.newTripOptions();

  final _weight = TextEditingController();
  final _notes = TextEditingController();

  String? _client;
  String? _cargo;
  String? _origin;
  String? _destination;
  PickOption? _driver;
  PickOption? _vehicle;
  DateTime _departure = _defaultDeparture();

  static DateTime _defaultDeparture() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 7);
  }

  String? _weightError;
  String? _formError;
  bool _saving = false;

  @override
  void dispose() {
    _weight.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDeparture() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _departure,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_departure),
    );
    if (time == null || !mounted) return;
    setState(() {
      _departure = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit(NewTripOptions options) async {
    final weightText = _weight.text.trim();
    double? weight;
    String? weightError;
    if (weightText.isNotEmpty) {
      weight = double.tryParse(weightText);
      if (weight == null || weight <= 0) weightError = 'Enter a weight above 0';
    }
    final origin = _origin ?? options.origins.first;
    final destination = _destination ?? options.destinations.first;
    String? formError;
    if (origin == destination) {
      formError = 'Origin and destination must be different.';
    } else if (options.drivers.isEmpty || options.vehicles.isEmpty) {
      formError = 'There is no available driver or vehicle right now.';
    }

    if (weightError != null || formError != null) {
      setState(() {
        _weightError = weightError;
        _formError = formError;
      });
      return;
    }

    final request = NewTripRequest(
      client: _client ?? options.clients.first,
      cargoType: _cargo ?? options.cargoTypes.first,
      origin: origin,
      destination: destination,
      driver: _driver ?? options.drivers.first,
      vehicle: _vehicle ?? options.vehicles.first,
      departure: _departure,
      weightTonnes: weight,
      notes: _notes.text.trim(),
    );

    setState(() {
      _saving = true;
      _weightError = null;
      _formError = null;
    });
    try {
      final trip = await widget.console.repository.createTrip(request);
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.console
        ..go(ConsoleModule.trips)
        ..refresh();
      if (widget.host.mounted) {
        showToast(widget.host, 'Trip ${trip.ref} created successfully');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _formError = describeError(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    return Padding(
      padding: const EdgeInsets.all(22),
      child: FutureBuilder<NewTripOptions>(
        future: _options,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ErrorState(
                  message: describeError(snapshot.error),
                  onRetry: () => Navigator.of(context).pop(),
                ),
              ],
            );
          }
          final options = snapshot.data;
          if (options == null) {
            return const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'New trip',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: c.text,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'TRIP DETAILS',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: c.muted,
                  ),
                ),
                const SizedBox(height: 14),
                _FormGrid(
                  children: [
                    ConsoleDropdown<String>(
                      label: 'Client',
                      value: _client ?? options.clients.first,
                      items: options.clients,
                      labelOf: (v) => v,
                      onChanged: (v) => setState(() => _client = v),
                    ),
                    ConsoleDropdown<String>(
                      label: 'Cargo type',
                      value: _cargo ?? options.cargoTypes.first,
                      items: options.cargoTypes,
                      labelOf: (v) => v,
                      onChanged: (v) => setState(() => _cargo = v),
                    ),
                    ConsoleDropdown<String>(
                      label: 'Origin',
                      value: _origin ?? options.origins.first,
                      items: options.origins,
                      labelOf: (v) => v,
                      onChanged: (v) => setState(() => _origin = v),
                    ),
                    ConsoleDropdown<String>(
                      label: 'Destination',
                      value: _destination ?? options.destinations.first,
                      items: options.destinations,
                      labelOf: (v) => v,
                      onChanged: (v) => setState(() => _destination = v),
                    ),
                    TextField(
                      controller: _weight,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 12.5),
                      decoration: consoleDecoration(
                        context,
                        label: 'Weight (tonnes)',
                        hint: 'e.g. 18.5',
                        errorText: _weightError,
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _pickDeparture,
                      child: InputDecorator(
                        decoration: consoleDecoration(context, label: 'Scheduled departure'),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                dayAndTime(_departure),
                                style: TextStyle(fontSize: 12.5, color: c.text),
                              ),
                            ),
                            Icon(Icons.event_outlined, size: 18, color: c.muted),
                          ],
                        ),
                      ),
                    ),
                    if (options.drivers.isEmpty)
                      const _EmptyPick(label: 'Available driver')
                    else
                      ConsoleDropdown<PickOption>(
                        label: 'Available driver',
                        value: _driver ?? options.drivers.first,
                        items: options.drivers,
                        labelOf: (v) => v.label,
                        onChanged: (v) => setState(() => _driver = v),
                      ),
                    if (options.vehicles.isEmpty)
                      const _EmptyPick(label: 'Available vehicle')
                    else
                      ConsoleDropdown<PickOption>(
                        label: 'Available vehicle',
                        value: _vehicle ?? options.vehicles.first,
                        items: options.vehicles,
                        labelOf: (v) => v.label,
                        onChanged: (v) => setState(() => _vehicle = v),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _notes,
                  minLines: 2,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 12.5),
                  decoration: consoleDecoration(
                    context,
                    label: 'Dispatch notes',
                    hint: 'Loading instructions, delivery requirements…',
                  ),
                ),
                if (_formError != null) ...[
                  const SizedBox(height: 12),
                  Text(_formError!, style: TextStyle(fontSize: 12, color: c.red)),
                ],
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionButton(
                      label: 'Cancel',
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    ),
                    ActionButton(
                      label: _saving ? 'Creating…' : 'Create trip',
                      primary: true,
                      icon: Icons.arrow_forward,
                      onPressed: _saving ? null : () => _submit(options),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FormGrid extends StatelessWidget {
  const _FormGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 460;
        final width = twoColumns ? (constraints.maxWidth - 14) / 2 : constraints.maxWidth;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [for (final child in children) SizedBox(width: width, child: child)],
        );
      },
    );
  }
}

class _EmptyPick extends StatelessWidget {
  const _EmptyPick({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: consoleDecoration(context, label: label, errorText: 'None available'),
      child: const Text('—'),
    );
  }
}
