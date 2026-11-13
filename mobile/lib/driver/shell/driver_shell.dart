import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../console/core/formatters.dart';
import '../../console/state/theme_controller.dart';
import '../../console/theme/console_theme.dart';
import '../../console/widgets/layout.dart';
import '../../console/widgets/toast.dart';
import '../models/driver_models.dart';
import '../screens/costs_screen.dart';
import '../screens/documents_screen.dart';
import '../screens/home_screen.dart';
import '../screens/map_screen.dart';
import '../screens/messages_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/trips_screen.dart';
import '../state/driver_controller.dart';

IconData pageIcon(DriverPage page) {
  switch (page) {
    case DriverPage.home:
      return Icons.home_outlined;
    case DriverPage.trips:
      return Icons.local_shipping_outlined;
    case DriverPage.map:
      return Icons.navigation_outlined;
    case DriverPage.documents:
      return Icons.description_outlined;
    case DriverPage.costs:
      return Icons.local_gas_station_outlined;
    case DriverPage.messages:
      return Icons.mail_outline;
    case DriverPage.profile:
      return Icons.person_outline;
  }
}

/// The five destinations of the phone bottom bar. Fuel opens from Home and
/// messages from the bell in the top bar.
const List<DriverPage> phonePages = [
  DriverPage.home,
  DriverPage.trips,
  DriverPage.map,
  DriverPage.documents,
  DriverPage.profile,
];

/// Frame of the driver app: sidebar on wide screens, bottom bar on phones.
class DriverShell extends StatelessWidget {
  const DriverShell({super.key, required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final driver = context.watch<DriverController>();
    final c = context.cc;
    final width = MediaQuery.sizeOf(context).width;
    final phone = width < Breakpoints.phone;
    final pad = phone ? 16.0 : 28.0;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: !phone,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!phone) _Sidebar(driver: driver, expanded: width >= Breakpoints.wide),
            Expanded(
              child: Column(
                children: [
                  _TopBar(driver: driver, phone: phone),
                  Expanded(
                    child: SingleChildScrollView(
                      key: ValueKey(driver.page.name),
                      padding: EdgeInsets.fromLTRB(pad, 22, pad, 40),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: SizedBox(
                            width: double.infinity,
                            child: _PageSwitcher(page: driver.page, onSignOut: onSignOut),
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
      bottomNavigationBar: phone ? _PhoneNav(driver: driver) : null,
    );
  }
}

class _PageSwitcher extends StatelessWidget {
  const _PageSwitcher({required this.page, required this.onSignOut});

  final DriverPage page;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    switch (page) {
      case DriverPage.home:
        return const HomeScreen();
      case DriverPage.trips:
        return const DriverTripsScreen();
      case DriverPage.map:
        return const DriverMapScreen();
      case DriverPage.documents:
        return const DriverDocumentsScreen();
      case DriverPage.costs:
        return const DriverCostsScreen();
      case DriverPage.messages:
        return const DriverMessagesScreen();
      case DriverPage.profile:
        return DriverProfileScreen(onSignOut: onSignOut);
    }
  }
}

/// Shows [builder] with the loaded snapshot, or [orElse] while it is not ready.
class _WithSnapshot extends StatelessWidget {
  const _WithSnapshot({required this.driver, required this.builder});

  final DriverController driver;
  final Widget Function(DriverSnapshot snapshot) builder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DriverSnapshot>(
      future: driver.snapshot,
      builder: (context, snap) {
        final data = snap.data;
        return data == null ? const SizedBox.shrink() : builder(data);
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.driver, required this.expanded});

  final DriverController driver;
  final bool expanded;

  static const List<DriverPage> _main = [
    DriverPage.home,
    DriverPage.trips,
    DriverPage.map,
    DriverPage.documents,
    DriverPage.costs,
    DriverPage.messages,
  ];

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
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: c.text),
                        ),
                        Text('Driver workspace', style: TextStyle(fontSize: 10.5, color: c.muted)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 10),
              children: [
                for (final page in _main)
                  _NavItem(
                    page: page,
                    selected: page == driver.page,
                    expanded: expanded,
                    badge: page == DriverPage.messages
                        ? _WithSnapshot(
                            driver: driver,
                            builder: (s) => s.unreadMessages == 0
                                ? const SizedBox.shrink()
                                : _Count(count: s.unreadMessages),
                          )
                        : null,
                    onTap: () => driver.go(page),
                  ),
                const SizedBox(height: 14),
                _NavItem(
                  page: DriverPage.profile,
                  selected: driver.page == DriverPage.profile,
                  expanded: expanded,
                  onTap: () => driver.go(DriverPage.profile),
                ),
              ],
            ),
          ),
          if (expanded)
            _WithSnapshot(
              driver: driver,
              builder: (s) => Container(
                margin: const EdgeInsets.all(14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.line),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: c.blue,
                      child: Text(
                        initialsOf(s.profile.name),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.profile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.text),
                          ),
                          Text(
                            'Driver · ${s.profile.driverId}',
                            style: TextStyle(fontSize: 10.5, color: c.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: c.red, borderRadius: BorderRadius.circular(20)),
      child: Text(
        '$count',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF)),
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
      decoration: BoxDecoration(color: c.blue, borderRadius: BorderRadius.circular(10)),
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
    required this.page,
    required this.selected,
    required this.expanded,
    required this.onTap,
    this.badge,
  });

  final DriverPage page;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    final color = selected ? c.blue : c.muted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Tooltip(
        message: expanded ? '' : page.label,
        child: Semantics(
          button: true,
          selected: selected,
          label: page.label,
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
                    Icon(pageIcon(page), size: 19, color: color),
                    if (expanded) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          page.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ),
                      if (badge != null) badge!,
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.driver, required this.phone});

  final DriverController driver;
  final bool phone;

  @override
  Widget build(BuildContext context) {
    final c = context.cc;
    final theme = context.watch<ThemeController>();
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
                  if (!phone) TextSpan(text: 'Driver workspace  /  ', style: TextStyle(color: c.muted)),
                  TextSpan(
                    text: driver.page.label,
                    style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (!phone) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: c.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 7),
                Text(driver.repository.sourceLabel, style: TextStyle(fontSize: 11.5, color: c.muted)),
              ],
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              driver.refresh();
              showToast(context, 'Refreshed');
            },
          ),
          _WithSnapshot(
            driver: driver,
            builder: (s) => IconButton(
              tooltip: 'Messages',
              icon: Badge(
                isLabelVisible: s.unreadMessages > 0,
                label: Text('${s.unreadMessages}'),
                child: const Icon(Icons.notifications_none),
              ),
              onPressed: () => driver.go(DriverPage.messages),
            ),
          ),
          IconButton(
            tooltip: theme.dark ? 'Switch to light theme' : 'Switch to dark theme',
            icon: Icon(theme.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: theme.toggle,
          ),
        ],
      ),
    );
  }
}

class _PhoneNav extends StatelessWidget {
  const _PhoneNav({required this.driver});

  final DriverController driver;

  @override
  Widget build(BuildContext context) {
    var selected = phonePages.indexOf(driver.page);
    // Fuel and Messages have no tab; keep Home highlighted for them.
    if (selected < 0) selected = 0;
    return NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: (index) => driver.go(phonePages[index]),
      destinations: [
        for (final page in phonePages)
          NavigationDestination(icon: Icon(pageIcon(page)), label: page.shortLabel),
      ],
    );
  }
}
