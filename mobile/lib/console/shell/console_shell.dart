import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/access.dart';
import '../core/formatters.dart';
import '../models/ops_models.dart';
import '../screens/drivers_screen.dart';
import '../screens/erp_screen.dart';
import '../screens/fleet_screen.dart';
import '../screens/fuel_screen.dart';
import '../screens/incidents_screen.dart';
import '../screens/overview_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/trip_detail_screen.dart';
import '../screens/trips_screen.dart';
import '../screens/warehouse_screen.dart';
import '../state/console_controller.dart';
import '../state/theme_controller.dart';
import '../theme/console_theme.dart';
import '../widgets/action_button.dart';
import '../widgets/inputs.dart';
import '../widgets/layout.dart';
import '../widgets/status_chip.dart';
import '../widgets/toast.dart';
import 'module_icons.dart';

/// The manager console frame: navigation, top bar and the open page.
/// Navigation adapts: sidebar with labels, icon rail, or bottom bar on phones.
class ConsoleShell extends StatelessWidget {
  const ConsoleShell({super.key, required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final console = context.watch<ConsoleController>();
    final c = context.cc;
    final width = MediaQuery.sizeOf(context).width;
    final phone = width < Breakpoints.phone;
    final wide = width >= Breakpoints.wide;
    final sidePadding = phone ? 16.0 : 28.0;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: !phone,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!phone) _Sidebar(console: console, expanded: wide),
            Expanded(
              child: Column(
                children: [
                  _TopBar(console: console, phone: phone, wide: wide, onSignOut: onSignOut),
                  if (console.isPreviewing) _PreviewBanner(console: console),
                  Expanded(
                    child: SingleChildScrollView(
                      key: ValueKey('${console.module.name}/${console.openTripRef}'),
                      padding: EdgeInsets.fromLTRB(sidePadding, 22, sidePadding, 40),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1320),
                          child: SizedBox(
                            width: double.infinity,
                            child: _PageSwitcher(console: console),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: phone ? _PhoneNav(console: console, onSignOut: onSignOut) : null,
    );
  }
}

class _PageSwitcher extends StatelessWidget {
  const _PageSwitcher({required this.console});

  final ConsoleController console;

  @override
  Widget build(BuildContext context) {
    switch (console.module) {
      case ConsoleModule.overview:
        return const OverviewScreen();
      case ConsoleModule.trips:
        final ref = console.openTripRef;
        return ref == null ? const TripsScreen() : TripDetailScreen(tripRef: ref);
      case ConsoleModule.fleet:
        return const FleetScreen();
      case ConsoleModule.drivers:
        return const DriversScreen();
      case ConsoleModule.fuel:
        return const FuelScreen();
      case ConsoleModule.incidents:
        return const IncidentsScreen();
      case ConsoleModule.warehouse:
        return const WarehouseScreen();
      case ConsoleModule.reports:
        return const ReportsScreen();
      case ConsoleModule.erp:
        return const ErpScreen();
      case ConsoleModule.settings:
        return const SettingsScreen();
    }
  }
}

// ---------------------------------------------------------------- sidebar

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.console, required this.expanded});

  final ConsoleController console;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    return Container(
      width: expanded ? 248 : 74,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(right: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(expanded ? 20 : 0, 20, expanded ? 20 : 0, 18),
            child: Row(
              mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                const _BrandMark(),
                if (expanded) ...[
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NEXORA',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: c.text,
                          ),
                        ),
                        Text(
                          'Logistics operations',
                          style: TextStyle(fontSize: 10.5, color: c.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 8),
              child: Text(
                'WORKSPACE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: c.muted,
                ),
              ),
            ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 10),
              children: [
                for (final module in console.modules)
                  _NavItem(
                    module: module,
                    selected: module == console.module,
                    expanded: expanded,
                    onTap: () => console.go(module),
                  ),
              ],
            ),
          ),
          if (expanded) _ErpMini(console: console),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.blue,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'N',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.module,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final ConsoleModule module;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    final color = selected ? c.blue : c.muted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Tooltip(
        message: expanded ? '' : module.label,
        child: Semantics(
          button: true,
          selected: selected,
          label: module.label,
          child: Material(
            color: selected ? c.blueWash : const Color(0x00000000),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 0, vertical: 11),
                child: Row(
                  mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                  children: [
                    Icon(moduleIcon(module), size: 19, color: color),
                    if (expanded) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          module.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ),
                    ],
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

/// Small ERP status block at the bottom of the sidebar. Hidden if it cannot load.
class _ErpMini extends StatefulWidget {
  const _ErpMini({required this.console});

  final ConsoleController console;

  @override
  State<_ErpMini> createState() => _ErpMiniState();
}

class _ErpMiniState extends State<_ErpMini> {
  late Future<ErpData> _future = widget.console.repository.erp();
  int _tick = 0;

  @override
  void didUpdateWidget(_ErpMini oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_tick != widget.console.refreshTick) {
      _tick = widget.console.refreshTick;
      _future = widget.console.repository.erp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    return FutureBuilder<ErpData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();
        final colors = c.tone(data.connected ? Tone.green : Tone.red);
        return Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: colors.fg, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data.connected ? 'ERP connection healthy' : 'ERP not responding',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: c.text),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Last sync ${data.lastSync}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, color: c.muted),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: data.syncedFraction.clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: c.line,
                  color: colors.fg,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${(data.syncedFraction * 100).round()}% of events synced',
                style: TextStyle(fontSize: 10.5, color: c.muted),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ----------------------------------------------------------------- top bar

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.console,
    required this.phone,
    required this.wide,
    required this.onSignOut,
  });

  final ConsoleController console;
  final bool phone;
  final bool wide;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    final theme = context.watch<ThemeController>();
    final crumb = console.openTripRef != null ? 'Trip details' : console.module.label;

    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: phone ? 12 : 24),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          if (phone) ...[
            const _BrandMark(),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  if (!phone)
                    TextSpan(text: 'Workspace  /  ', style: TextStyle(color: c.muted)),
                  TextSpan(
                    text: crumb,
                    style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (!phone)
            _GlobalSearch(onSubmit: (q) => _search(context, q))
          else
            IconButton(
              tooltip: 'Search trips',
              icon: const Icon(Icons.search),
              onPressed: () => _openSearchDialog(context),
            ),
          if (wide) ...[
            const SizedBox(width: 10),
            _Pill(label: shortDate(DateTime.now()), icon: Icons.calendar_today_outlined),
            const SizedBox(width: 10),
            const StatusChip(label: 'ERP connected', tone: Tone.green),
          ],
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Notifications',
            icon: const Badge(label: Text('3'), child: Icon(Icons.notifications_none)),
            onPressed: () => showToast(context, 'You are all caught up'),
          ),
          IconButton(
            tooltip: theme.dark ? 'Switch to light theme' : 'Switch to dark theme',
            icon: Icon(theme.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: theme.toggle,
          ),
          const SizedBox(width: 4),
          _AccountMenu(console: console, onSignOut: onSignOut),
        ],
      ),
    );
  }

  void _search(BuildContext context, String query) {
    if (!console.levelFor(ConsoleModule.trips).hasAccess) {
      showToast(context, 'Your role cannot search trips.');
      return;
    }
    console.searchTrips(query);
  }

  Future<void> _openSearchDialog(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Search trips'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: consoleDecoration(
            dialogContext,
            hint: 'Trip, plate, driver, client…',
            prefixIcon: Icons.search,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (value) {
            Navigator.of(dialogContext).pop();
            _search(context, value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _search(context, controller.text);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }
}

class _GlobalSearch extends StatefulWidget {
  const _GlobalSearch({required this.onSubmit});

  final ValueChanged<String> onSubmit;

  @override
  State<_GlobalSearch> createState() => _GlobalSearchState();
}

class _GlobalSearchState extends State<_GlobalSearch> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: TextField(
        controller: _controller,
        style: const TextStyle(fontSize: 12.5),
        textInputAction: TextInputAction.search,
        onSubmitted: widget.onSubmit,
        decoration: consoleDecoration(
          context,
          hint: 'Search trips, plates, drivers…',
          prefixIcon: Icons.search,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: c.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c.muted),
          const SizedBox(width: 7),
          Text(label, style: TextStyle(fontSize: 11.5, color: c.text)),
        ],
      ),
    );
  }
}

class _AccountMenu extends StatelessWidget {
  const _AccountMenu({required this.console, required this.onSignOut});

  final ConsoleController console;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    return PopupMenuButton<int>(
      tooltip: 'Account',
      offset: const Offset(0, 46),
      onSelected: (_) => onSignOut(),
      itemBuilder: (context) => [
        PopupMenuItem<int>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                console.userName,
                style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
              ),
              Text(
                console.actualRole.label,
                style: TextStyle(fontSize: 12, color: c.muted),
              ),
            ],
          ),
        ),
        const PopupMenuItem<int>(value: 1, child: Text('Sign out')),
      ],
      child: Semantics(
        label: 'Account menu for ${console.userName}',
        child: CircleAvatar(
          radius: 17,
          backgroundColor: c.blue,
          child: Text(
            initialsOf(console.userName),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewBanner extends StatelessWidget {
  const _PreviewBanner({required this.console});

  final ConsoleController console;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    return Container(
      width: double.infinity,
      color: c.amberBg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(Icons.visibility_outlined, size: 16, color: c.amber),
          Text(
            'Previewing as ${console.role.label}. You see what this role sees.',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.amber),
          ),
          ActionButton(
            label: 'Exit preview',
            compact: true,
            onPressed: () => console.previewAs(null),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- phone nav

class _PhoneNav extends StatelessWidget {
  const _PhoneNav({required this.console, required this.onSignOut});

  final ConsoleController console;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final all = AccessMatrix.phoneModulesFor(console.role);
    final needsMore = all.length > 5;
    final shown = needsMore ? all.take(4).toList() : all;
    final rest = needsMore ? all.skip(4).toList() : <ConsoleModule>[];

    var selected = shown.indexOf(console.module);
    if (selected < 0) selected = needsMore ? shown.length : 0;

    return NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: (index) {
        if (index < shown.length) {
          console.go(shown[index]);
        } else {
          _openMore(context, rest);
        }
      },
      destinations: [
        for (final module in shown)
          NavigationDestination(
            icon: Icon(moduleIcon(module)),
            label: module.shortLabel,
          ),
        if (needsMore)
          const NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
      ],
    );
  }

  void _openMore(BuildContext context, List<ConsoleModule> modules) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final module in modules)
              ListTile(
                leading: Icon(moduleIcon(module)),
                title: Text(module.label),
                selected: module == console.module,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  console.go(module);
                },
              ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onSignOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}
