import 'package:material_ui/material_ui.dart';

import '../../core/api_client.dart';
import '../theme/console_theme.dart';
import 'action_button.dart';

String describeError(Object? error) {
  if (error is ApiException) return error.message;
  if (error is StateError) return error.message;
  return 'Something went wrong. Please try again.';
}

/// Loads data once, shows a skeleton while waiting and a retry on failure.
/// Loads again when [reloadKey] changes.
class DataLoader<T> extends StatefulWidget {
  const DataLoader({
    super.key,
    required this.load,
    required this.builder,
    this.reloadKey,
  });

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;
  final Object? reloadKey;

  @override
  State<DataLoader<T>> createState() => _DataLoaderState<T>();
}

class _DataLoaderState<T> extends State<DataLoader<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  @override
  void didUpdateWidget(DataLoader<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadKey != widget.reloadKey) {
      _future = widget.load();
    }
  }

  void _retry() {
    setState(() {
      _future = widget.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorState(message: describeError(snapshot.error), onRetry: _retry);
        }
        if (snapshot.connectionState != ConnectionState.done || !snapshot.hasData) {
          return const LoadingSkeleton();
        }
        return widget.builder(context, snapshot.requireData);
      },
    );
  }
}

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    Widget block(double height) => Container(
          height: height,
          decoration: BoxDecoration(
            color: c.line,
            borderRadius: BorderRadius.circular(14),
          ),
        );
    return Semantics(
      label: 'Loading',
      child: Column(
        children: [
          block(96),
          const SizedBox(height: 16),
          block(220),
          const SizedBox(height: 16),
          block(160),
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_outlined, size: 32, color: c.red),
          const SizedBox(height: 10),
          Text(
            'Could not load this page',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: c.muted),
          ),
          const SizedBox(height: 16),
          ActionButton(label: 'Try again', icon: Icons.refresh, onPressed: onRetry, primary: true),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.message, this.icon = Icons.inbox_outlined});

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30, color: c.muted),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}
