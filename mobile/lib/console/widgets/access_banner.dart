import 'package:material_ui/material_ui.dart';

import '../core/access.dart';
import '../theme/console_theme.dart';

/// Tells the user why some actions are missing for their role.
class AccessBanner extends StatelessWidget {
  const AccessBanner({super.key, required this.level});

  final AccessLevel level;

  String? get _message {
    switch (level) {
      case AccessLevel.view:
        return 'View only: you can look at this page but not change anything.';
      case AccessLevel.limited:
        return 'Limited view: some figures and actions are hidden for your role.';
      case AccessLevel.personal:
        return 'Personal view: you only see your own work here.';
      case AccessLevel.assigned:
        return 'Assigned view: you only see work assigned to you.';
      case AccessLevel.submit:
        return 'You can submit entries here, but not review other people’s.';
      case AccessLevel.report:
        return 'You can report new entries here, but not manage them.';
      case AccessLevel.none:
      case AccessLevel.full:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = _message;
    if (message == null) return const SizedBox.shrink();
    final c = context.cc;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.blueWash,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: c.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(fontSize: 12, color: c.blue)),
          ),
        ],
      ),
    );
  }
}
