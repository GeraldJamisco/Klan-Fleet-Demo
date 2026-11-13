import 'package:material_ui/material_ui.dart';

import '../theme/console_theme.dart';

/// Eyebrow, title, subtitle and action buttons at the top of a page.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.actions = const [],
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    final narrow = MediaQuery.sizeOf(context).width < 700;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: c.muted,
          ),
        ),
        const SizedBox(height: 5),
        Semantics(
          header: true,
          child: Text(
            title,
            style: TextStyle(
              fontSize: narrow ? 22 : 25,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
              color: c.text,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 12.5, color: c.muted)),
      ],
    );

    final buttons = Wrap(spacing: 8, runSpacing: 8, children: actions);

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: narrow || actions.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text,
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  buttons,
                ],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: text),
                const SizedBox(width: 16),
                Flexible(child: Align(alignment: Alignment.topRight, child: buttons)),
              ],
            ),
    );
  }
}
