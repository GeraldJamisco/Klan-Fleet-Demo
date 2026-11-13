import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../core/session.dart';

MaterialColor statusColor(String status) {
  switch (status) {
    case 'assigned':
      return Colors.blue;
    case 'picked_up':
      return Colors.orange;
    case 'in_transit':
      return Colors.deepPurple;
    case 'delivered':
      return Colors.green;
    case 'cancelled':
      return Colors.grey;
    default:
      return Colors.blueGrey;
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade300),
      ),
      child: Text(
        statusLabel(status),
        style: TextStyle(color: color.shade800, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Shows a SnackBar with an error message.
void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(error.toString())));
}

void showInfo(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Runs [action]; if the server says our session expired, sign out locally.
Future<T?> guarded<T>(BuildContext context, Future<T> Function() action) async {
  try {
    return await action();
  } on ApiException catch (e) {
    if (e.status == 401 && context.mounted) {
      await context.read<SessionController>().clearLocal();
    } else if (context.mounted) {
      showError(context, e);
    }
  } catch (e) {
    if (context.mounted) showError(context, e);
  }
  return null;
}

/// Loads data once, shows a spinner / error with retry, and supports
/// pull-to-refresh. Reload from outside by changing [refreshToken].
class LoadView<T> extends StatefulWidget {
  const LoadView({
    super.key,
    required this.load,
    required this.builder,
    this.refreshToken = 0,
  });

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;
  final int refreshToken;

  @override
  State<LoadView<T>> createState() => _LoadViewState<T>();
}

class _LoadViewState<T> extends State<LoadView<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  @override
  void didUpdateWidget(covariant LoadView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) _reload();
  }

  void _reload() {
    setState(() => _future = widget.load());
  }

  Future<void> _pullToRefresh() async {
    final next = widget.load();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {
      // The error is shown by the FutureBuilder below.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          if (error is ApiException && error.status == 401) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.read<SessionController>().clearLocal();
            });
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _reload, child: const Text('Try again')),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _pullToRefresh,
          child: widget.builder(context, snapshot.data as T),
        );
      },
    );
  }
}
