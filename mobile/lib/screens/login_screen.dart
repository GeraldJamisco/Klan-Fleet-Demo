import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/session.dart';
import '../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _server;
  final _phone = TextEditingController();
  final _pin = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _server = TextEditingController(text: context.read<SessionController>().baseUrl);
  }

  @override
  void dispose() {
    _server.dispose();
    _phone.dispose();
    _pin.dispose();
    super.dispose();
  }

  void _fill(String phone, String pin) {
    setState(() {
      _phone.text = phone;
      _pin.text = pin;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<SessionController>().login(
            serverUrl: _server.text,
            phone: _phone.text,
            pin: _pin.text,
          );
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.local_shipping_outlined,
                        size: 56, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 12),
                    Text('Klan Fleet',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium),
                    Text('Demo app: drivers and fleet managers',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _server,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Server address',
                        helperText: 'Phone on Wi-Fi: use the laptop IP, e.g. http://192.168.1.20:3000',
                        border: OutlineInputBorder(),
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        border: OutlineInputBorder(),
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pin,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'PIN',
                        border: OutlineInputBorder(),
                      ),
                      validator: _required,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Log in'),
                    ),
                    const SizedBox(height: 16),
                    Text('Demo accounts (fake data)',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('Driver'),
                          onPressed: () => _fill('0700000012', '2222'),
                        ),
                        ActionChip(
                          label: const Text('Manager'),
                          onPressed: () => _fill('0700000001', '1234'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
