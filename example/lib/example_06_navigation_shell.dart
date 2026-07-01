// super_navigation_sidebar · Example 06 — NavigationShell (integrated)
// ────────────────────────────────────────────────────────────
// The 2.0 integrated shell. A single NavigationShell composes the app bar, the
// navigation pane and the content in the Microsoft-NavigationView arrangement —
// no hand-wired Row / Column / Stack. Live toggles exercise every new axis:
//
//   • Header layout   — spanning (full-width bar over the pane) ↔ inset
//   • Pane behavior    — push (reflow content) ↔ overlay (float + scrim)
//   • Selection style  — Fluent bar indicator ↔ original fill
//   • Back button       — enabled from controller.canGoBack + a real history
//   • Footer nav items  — Settings / Help pinned to the pane bottom
//
// Resize the window to watch the shell adapt: expanded ≥ 1200 · rail ≥ 768 ·
// drawer below (hamburger in the bar).

import 'package:flutter/material.dart';
import 'package:super_navigation_sidebar/super_navigation_sidebar.dart';

List<NavSection<String>> _sections() => [
      NavSection(title: 'Overview', items: [
        NavNode(
          id: 'dashboard',
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          value: 'dashboard',
          shortcut: ['g', 'd'],
        ),
        NavNode(
          id: 'analytics',
          label: 'Analytics',
          icon: Icons.insights_outlined,
          value: 'analytics',
        ),
      ]),
      NavSection(title: 'Workspace', items: [
        NavNode(
          id: 'projects',
          label: 'Projects',
          icon: Icons.folder_outlined,
          children: [
            NavNode(
              id: 'active',
              label: 'Active',
              icon: Icons.play_circle_outline,
              value: 'active',
              badge: NavBadge('12', tone: NavBadgeTone.accent),
            ),
            NavNode(
              id: 'archived',
              label: 'Archived',
              icon: Icons.inventory_2_outlined,
              value: 'archived',
            ),
          ],
        ),
        NavNode(
          id: 'team',
          label: 'Team',
          icon: Icons.groups_outlined,
          value: 'team',
          badge: NavBadge('New', tone: NavBadgeTone.success),
        ),
      ]),
      // Pinned to the pane bottom — shares the one selection model.
      NavSection(
        title: '',
        placement: NavSectionPlacement.footer,
        items: [
          NavNode(
            id: 'help',
            label: 'Help & feedback',
            icon: Icons.help_outline,
            value: 'help',
          ),
          NavNode(
            id: 'settings',
            label: 'Settings',
            icon: Icons.settings_outlined,
            value: 'settings',
          ),
        ],
      ),
    ];

class NavigationShellExample extends StatefulWidget {
  const NavigationShellExample({super.key});

  @override
  State<NavigationShellExample> createState() => _NavigationShellExampleState();
}

class _NavigationShellExampleState extends State<NavigationShellExample> {
  late final NavigationSidebarController<String> _nav;
  final List<String> _history = [];
  String _screen = 'dashboard';
  bool _dark = true;
  bool _bar = true; // Fluent bar indicator
  NavShellHeaderLayout _header = NavShellHeaderLayout.spanning;
  NavPaneBehavior _behavior = NavPaneBehavior.push;

  @override
  void initState() {
    super.initState();
    _nav = NavigationSidebarController<String>(
      sections: _sections(),
      active: 'dashboard',
    );
  }

  @override
  void dispose() {
    _nav.dispose();
    super.dispose();
  }

  void _onNavigate(NavNode<String> n) {
    if (n.value == null || n.value == _screen) return;
    setState(() {
      _history.add(_screen);
      _screen = n.value!;
      _nav.canGoBack = _history.isNotEmpty;
    });
  }

  void _goBack() {
    if (_history.isEmpty) return;
    final prev = _history.removeLast();
    setState(() {
      _screen = prev;
      _nav.navigate(prev);
      _nav.canGoBack = _history.isNotEmpty;
    });
  }

  void _setBehavior(NavPaneBehavior b) {
    setState(() {
      _behavior = b;
      // Overlay opens as a flyout — start it closed.
      _nav.collapsed = b == NavPaneBehavior.overlay;
    });
  }

  NavigationSidebarThemeData _themeExt() {
    final base = _dark
        ? NavigationSidebarThemeData.dark
        : NavigationSidebarThemeData.light;
    return base.copyWith(
      selectionIndicator:
          _bar ? NavSelectionIndicator.bar : NavSelectionIndicator.fill,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ext = _themeExt();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: NavigationSidebarThemeData.bodyFont,
        extensions: [ext],
        scaffoldBackgroundColor: ext.bg,
      ),
      home: NavigationShell<String>(
        controller: _nav,
        headerLayout: _header,
        paneBehavior: _behavior,
        appBarBuilder: (ctx, mode) => NavigationSidebarAppBar(
          controller: _nav,
          mode: mode,
          showBackButton: true,
          onBack: _goBack,
          // inset layout carries its own pane toggle, so only the spanning
          // bar needs the collapse toggle
          showCollapseToggle: _header == NavShellHeaderLayout.spanning &&
              mode != NavSidebarMode.drawer,
          title: mode == NavSidebarMode.drawer ? const Text('Northwind') : null,
          pageTitle: NavBreadcrumb<String>(controller: _nav),
          globalSearch: mode == NavSidebarMode.drawer
              ? null
              : NavigationSidebarSearchField(
                  controller: _nav,
                  hint: 'Search…',
                ),
          actions: [
            _Segmented(
              icon: Icons.vertical_split_outlined,
              on: _header == NavShellHeaderLayout.inset,
              tooltip: 'Header: spanning ↔ inset',
              onTap: () => setState(() => _header =
                  _header == NavShellHeaderLayout.spanning
                      ? NavShellHeaderLayout.inset
                      : NavShellHeaderLayout.spanning),
            ),
            _Segmented(
              icon: Icons.layers_outlined,
              on: _behavior == NavPaneBehavior.overlay,
              tooltip: 'Pane: push ↔ overlay',
              onTap: () => _setBehavior(_behavior == NavPaneBehavior.push
                  ? NavPaneBehavior.overlay
                  : NavPaneBehavior.push),
            ),
            _Segmented(
              icon: Icons.chrome_reader_mode_outlined,
              on: _bar,
              tooltip: 'Indicator: bar ↔ fill',
              onTap: () => setState(() => _bar = !_bar),
            ),
            _Segmented(
              icon: _dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              on: false,
              tooltip: 'Theme',
              onTap: () => setState(() => _dark = !_dark),
            ),
          ],
        ),
        sidebarBuilder: (ctx, mode) => NavigationSidebar<String>(
          controller: _nav,
          mode: mode,
          searchable: mode == NavSidebarMode.drawer,
          // inset pane owns the menu button (no bar toggle over it)
          showPaneToggle: _header == NavShellHeaderLayout.inset &&
              mode != NavSidebarMode.drawer,
          header: (c, collapsed) => _Brand(collapsed: collapsed),
          onNavigate: _onNavigate,
        ),
        body: _PageBody(nav: _nav, screen: _screen),
      ),
    );
  }
}

// ── Brand header ───────────────────────────────────────────────────
class _Brand extends StatelessWidget {
  final bool collapsed;
  const _Brand({this.collapsed = false});

  @override
  Widget build(BuildContext context) {
    final s = NavigationSidebarThemeData.of(context);
    return SizedBox(
      height: 34,
      child: Row(children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: NavigationSidebarThemeData.accent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.hub_outlined, size: 16, color: Colors.white),
        ),
        if (!collapsed) ...[
          const SizedBox(width: 10),
          Text('Northwind',
              style: TextStyle(
                fontFamily: NavigationSidebarThemeData.displayFont,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: s.fg1,
              )),
        ],
      ]),
    );
  }
}

// ── AppBar toggle button ───────────────────────────────────────────
class _Segmented extends StatelessWidget {
  final IconData icon;
  final bool on;
  final String tooltip;
  final VoidCallback onTap;
  const _Segmented(
      {required this.icon,
      required this.on,
      required this.tooltip,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = NavigationSidebarThemeData.of(context);
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on
                  ? NavigationSidebarThemeData.accent.withOpacity(0.15)
                  : s.inputBg,
              borderRadius:
                  BorderRadius.circular(s.radiusMd),
              border: Border.all(
                  color: on
                      ? NavigationSidebarThemeData.accent.withOpacity(0.4)
                      : s.border),
            ),
            child: Icon(icon,
                size: 17,
                color: on ? NavigationSidebarThemeData.accent : s.fg2),
          ),
        ),
      ),
    );
  }
}

// ── Page content ───────────────────────────────────────────────────
class _PageBody extends StatelessWidget {
  final NavigationSidebarController<String> nav;
  final String screen;
  const _PageBody({required this.nav, required this.screen});

  @override
  Widget build(BuildContext context) {
    final s = NavigationSidebarThemeData.of(context);
    final node = nav.node(screen);
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(node?.label ?? 'Workspace',
            style: TextStyle(
              fontFamily: NavigationSidebarThemeData.displayFont,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: s.fg1,
            )),
        const SizedBox(height: 6),
        Text('One NavigationShell lays out the bar, pane and this content.',
            style: TextStyle(
              fontFamily: NavigationSidebarThemeData.bodyFont,
              fontSize: 13.5,
              color: s.fg3,
            )),
        const SizedBox(height: 22),
        Wrap(spacing: 14, runSpacing: 14, children: [
          for (final m in const [
            ('Header', 'spanning · inset', Icons.vertical_split_outlined),
            ('Pane', 'push · overlay', Icons.layers_outlined),
            ('Indicator', 'bar · fill', Icons.chrome_reader_mode_outlined),
            ('Back', 'canGoBack history', Icons.arrow_back),
          ])
            Container(
              width: 220,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: s.surface,
                border: Border.all(color: s.border),
                borderRadius:
                    BorderRadius.circular(s.radiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(m.$3,
                      size: 20, color: NavigationSidebarThemeData.accent),
                  const SizedBox(height: 12),
                  Text(m.$1,
                      style: TextStyle(
                        fontFamily: NavigationSidebarThemeData.displayFont,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: s.fg1,
                      )),
                  const SizedBox(height: 3),
                  Text(m.$2,
                      style: TextStyle(
                        fontFamily: NavigationSidebarThemeData.monoFont,
                        fontSize: 11.5,
                        color: s.fg3,
                      )),
                ],
              ),
            ),
        ]),
      ]),
    );
  }
}
