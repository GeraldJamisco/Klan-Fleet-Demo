import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/access.dart';
import '../state/console_controller.dart';
import '../state/theme_controller.dart';
import '../theme/console_theme.dart';
import '../widgets/action_button.dart';
import '../widgets/console_table.dart';
import '../widgets/inputs.dart';
import '../widgets/page_header.dart';
import '../widgets/section_card.dart';
import '../widgets/toast.dart';
import 'screen_support.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final console = context.console;
    final theme = context.watch<ThemeController>();
    final c = context.cc;
    final level = console.levelFor(ConsoleModule.settings);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          eyebrow: 'Administration',
          title: 'Settings & roles',
          subtitle: 'Manage access and preview each team experience.',
          actions: [
            if (canChange(level))
              ActionButton(
                label: 'Invite user',
                icon: Icons.add,
                primary: true,
                onPressed: () => showToast(context, 'Invite user flow opened'),
              ),
          ],
        ),
        SectionCard(
          title: 'Team access',
          subtitle: 'Role-based permissions',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (console.canPreviewRoles) ...[
                      ConsoleDropdown<ConsoleRole>(
                        label: 'View as',
                        value: console.role,
                        items: ConsoleRole.values,
                        labelOf: (r) => r.label,
                        onChanged: (role) {
                          console.previewAs(role);
                          showToast(context, 'Previewing ${role.label} experience');
                        },
                        width: 240,
                      ),
                      Text(
                        'Preview permissions without changing your account',
                        style: TextStyle(fontSize: 11, color: c.muted),
                      ),
                    ] else
                      Text(
                        'You are signed in as ${console.actualRole.label}.',
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                  ],
                ),
              ),
              ConsoleTable(
                rowHeight: 46,
                columns: [
                  const TableCol('Module', 170),
                  for (final role in ConsoleRole.values)
                    TableCol(role == ConsoleRole.fleet ? 'Fleet' : role.label.split(' ').first, 90),
                ],
                rows: [
                  for (final module in ConsoleModule.values)
                    [
                      CellText(module.label, bold: true),
                      for (final role in ConsoleRole.values)
                        _LevelCell(
                          level: AccessMatrix.levelFor(role, module),
                          highlighted: role == console.role,
                        ),
                    ],
                ],
              ),
            ],
          ),
        ),
        gap16,
        SectionCard(
          title: 'Data source',
          subtitle: 'Where the console reads its data from',
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  for (final source in DataSource.values)
                    ChoiceChip(
                      label: Text(source.label),
                      selected: console.source == source,
                      onSelected: (_) {
                        console.setSource(source);
                        showToast(context, 'Now using ${source.label.toLowerCase()}');
                      },
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                console.source == DataSource.demo
                    ? 'Demo data works offline and is the same every time. New trips stay in memory until you close the app.'
                    : 'Trips, dashboard totals, ERP events and new-trip options come from the Klan Fleet API. '
                        'Fleet, drivers, fuel, safety, depots and reports still show sample data.',
                style: TextStyle(fontSize: 12, height: 1.45, color: c.muted),
              ),
            ],
          ),
        ),
        gap16,
        SectionCard(
          title: 'Appearance',
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
          child: Material(
            type: MaterialType.transparency,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Dark theme', style: TextStyle(fontSize: 13, color: c.text)),
              value: theme.dark,
              onChanged: theme.setDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _LevelCell extends StatelessWidget {
  const _LevelCell({required this.level, required this.highlighted});

  final AccessLevel level;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    if (level == AccessLevel.none) {
      return Text('—', style: TextStyle(fontSize: 12, color: c.muted));
    }
    final full = level == AccessLevel.full;
    return Text(
      full ? '● ${level.label}' : level.label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: full || highlighted ? FontWeight.w700 : FontWeight.w400,
        color: full ? c.green : c.text,
      ),
    );
  }
}
