// super_navigation_sidebar · Example 05 — AppBar Integration
// ────────────────────────────────────────────────────────────
// Demonstrates NavigationSidebarAppBar connected to the same controller as
// the sidebar. Shows two scenarios side-by-side via a toggle:
//
//   • Drawer mode   — AppBar shows a hamburger; tapping it opens the sidebar
//                     drawer. NavBreadcrumb shows the current screen path.
//   • Desktop mode  — AppBar shows a collapse toggle aligned with the sidebar.
//                     Global search field, user avatar, notification bell,
//                     workspace switcher, and a theme toggle live in the bar.
//
// Key APIs exercised:
//   NavigationSidebarAppBar  — leading, title, pageTitle, globalSearch,
//                              middle, actions, showCollapseToggle, builder
//   NavBreadcrumb<T>         — reads ancestor path from controller
//   NavigationSidebarSearchField — drives controller.setQuery

import 'package:flutter/material.dart';
import 'package:super_navigation_sidebar/super_navigation_sidebar.dart';

// ── Sample navigation tree ────────────────────────────────────────
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
          icon: Icons.bar_chart_outlined,
          value: 'analytics',
        ),
      ]),
      NavSection(title: 'Finance', items: [
        NavNode(
          id: 'financeHub',
          label: 'Finance',
          icon: Icons.account_balance_outlined,
          children: [
            NavNode(id: 'glGroup', label: 'General Ledger', children: [
              NavNode(
                id: 'journalEntry',
                label: 'Journal Entry',
                icon: Icons.edit_note_outlined,
                value: 'journalEntry',
                shortcut: ['g', 'j'],
              ),
              NavNode(
                id: 'trialBalance',
                label: 'Trial Balance',
                icon: Icons.balance,
                value: 'trialBalance',
                shortcut: ['g', 'b'],
              ),
            ]),
            NavNode(id: 'bankGroup', label: 'Banking', children: [
              NavNode(
                id: 'cashPos',
                label: 'Cash Positions',
                icon: Icons.account_balance_wallet_outlined,
                value: 'cashPos',
                badge: NavBadge('Live', tone: NavBadgeTone.success),
              ),
              NavNode(
                id: 'wire',
                label: 'Wire / SWIFT',
                icon: Icons.bolt_outlined,
                value: 'wire',
                locked: true,
                lockMessage: 'Requires Treasury Approver role',
              ),
            ]),
          ],
        ),
      ]),
      NavSection(title: 'Reports', items: [
        NavNode(
          id: 'reportsHub',
          label: 'Reports',
          icon: Icons.insert_chart_outlined,
          children: [
            NavNode(id: 'statementsGroup', label: 'Statements', children: [
              NavNode(
                id: 'incomeStmt',
                label: 'Income Statement',
                icon: Icons.trending_up,
                value: 'incomeStmt',
              ),
              NavNode(
                id: 'balanceSheet',
                label: 'Balance Sheet',
                icon: Icons.table_chart_outlined,
                value: 'balanceSheet',
              ),
            ]),
          ],
        ),
      ]),
      NavSection(title: 'Settings', items: [
        NavNode(
          id: 'settings',
          label: 'Settings',
          icon: Icons.settings_outlined,
          value: 'settings',
        ),
      ]),
    ];

// ── Example root ──────────────────────────────────────────────────
class AppBarIntegrationExample extends StatefulWidget {
  const AppBarIntegrationExample({super.key});

  @override
  State<AppBarIntegrationExample> createState() =>
      _AppBarIntegrationExampleState();
}

class _AppBarIntegrationExampleState
    extends State<AppBarIntegrationExample> {
  late final NavigationSidebarController<String> _nav;
  String _screen = 'dashboard';
  bool _dark = true;
  bool _mobileMode = false; // toggle between drawer and desktop layout

  @override
  void initState() {
    super.initState();
    _nav = NavigationSidebarController<String>(
      sections: _sections(),
      active: 'dashboard',
      favorites: {'journalEntry', 'trialBalance'},
    );
  }

  @override
  void dispose() {
    _nav.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: NavigationSidebarThemeData.bodyFont,
        extensions: [NavigationSidebarThemeData.light],
        scaffoldBackgroundColor: NavigationSidebarThemeData.light.bg,
      ),
      darkTheme: ThemeData(
        fontFamily: NavigationSidebarThemeData.bodyFont,
        extensions: [NavigationSidebarThemeData.dark],
        scaffoldBackgroundColor: NavigationSidebarThemeData.dark.bg,
      ),
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      home: _mobileMode ? _drawerLayout() : _desktopLayout(),
    );
  }

  // ── Drawer layout (mobile) ────────────────────────────────────
  Widget _drawerLayout() {
    return Scaffold(
      appBar: NavigationSidebarAppBar(
        controller: _nav,
        mode: NavSidebarMode.drawer,
        // pageTitle uses NavBreadcrumb — reads the live active path
        pageTitle: NavBreadcrumb<String>(controller: _nav),
        actions: [
          _NotificationBell(count: 4),
          const SizedBox(width: 4),
          _UserAvatar(name: 'AR'),
          const SizedBox(width: 4),
          _ModeToggle(
            mobile: _mobileMode,
            onTap: () => setState(() => _mobileMode = !_mobileMode),
          ),
          _ThemeToggleBtn(
            dark: _dark,
            onTap: () => setState(() => _dark = !_dark),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _PageBody(nav: _nav, screen: _screen)),
          Positioned.fill(
            child: NavigationSidebar<String>(
              controller: _nav,
              mode: NavSidebarMode.drawer,
              searchable: true,
              favoritable: true,
              header: (ctx, _) => _Brand(),
              onNavigate: (n) => setState(() => _screen = n.value!),
            ),
          ),
        ],
      ),
    );
  }

  // ── Desktop layout (expanded / rail) ─────────────────────────
  Widget _desktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          NavigationSidebar<String>(
            controller: _nav,
            mode: NavSidebarMode.expanded,
            searchable: true,
            favoritable: true,
            header: (ctx, collapsed) => _Brand(collapsed: collapsed),
            onNavigate: (n) => setState(() => _screen = n.value!),
          ),
          Expanded(
            child: Column(
              children: [
                NavigationSidebarAppBar(
                  controller: _nav,
                  mode: NavSidebarMode.expanded,
                  showCollapseToggle: true,
                  // Breadcrumb shows active path (Finance › General Ledger › Journal Entry)
                  pageTitle: NavBreadcrumb<String>(controller: _nav),
                  // Global search drives the sidebar filter
                  globalSearch: NavigationSidebarSearchField(
                    controller: _nav,
                    hint: 'Search accounts, journals, reports…',
                  ),
                  // Middle: workspace switcher
                  middle: _WorkspaceSwitcher(),
                  actions: [
                    _NotificationBell(count: 4),
                    const SizedBox(width: 4),
                    _UserAvatar(name: 'AR'),
                    const SizedBox(width: 4),
                    _ModeToggle(
                      mobile: _mobileMode,
                      onTap: () =>
                          setState(() => _mobileMode = !_mobileMode),
                    ),
                    _ThemeToggleBtn(
                      dark: _dark,
                      onTap: () => setState(() => _dark = !_dark),
                    ),
                  ],
                ),
                Expanded(child: _PageBody(nav: _nav, screen: _screen)),
              ],
            ),
          ),
        ],
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
      height: 36,
      child: Row(children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: NavigationSidebarThemeData.accent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.account_balance,
              size: 15, color: Colors.white),
        ),
        if (!collapsed) ...[
          const SizedBox(width: 10),
          Text('Meridian',
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

// ── Notification bell ──────────────────────────────────────────────
class _NotificationBell extends StatelessWidget {
  final int count;
  const _NotificationBell({required this.count});

  @override
  Widget build(BuildContext context) {
    final s = NavigationSidebarThemeData.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: s.inputBg,
            borderRadius:
                BorderRadius.circular(s.radiusMd),
            border: Border.all(color: s.border),
          ),
          child: Icon(Icons.notifications_outlined,
              size: 18, color: s.fg2),
        ),
        if (count > 0)
          PositionedDirectional(
            end: -3,
            top: -3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: NavigationSidebarThemeData.danger,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontFamily: NavigationSidebarThemeData.monoFont,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── User avatar ────────────────────────────────────────────────────
class _UserAvatar extends StatelessWidget {
  final String name;
  const _UserAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: NavigationSidebarThemeData.accent.withOpacity(0.18),
        borderRadius:
            BorderRadius.circular(NavigationSidebarThemeData.of(context).radiusMd),
        border: Border.all(
            color: NavigationSidebarThemeData.accent.withOpacity(0.38)),
      ),
      child: Text(
        name,
        style: const TextStyle(
          fontFamily: NavigationSidebarThemeData.displayFont,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: NavigationSidebarThemeData.accent,
        ),
      ),
    );
  }
}

// ── Workspace switcher ─────────────────────────────────────────────
class _WorkspaceSwitcher extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = NavigationSidebarThemeData.of(context);
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: s.inputBg,
        borderRadius:
            BorderRadius.circular(s.radiusMd),
        border: Border.all(color: s.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.corporate_fare_outlined, size: 14, color: s.fg3),
        const SizedBox(width: 7),
        Text('Meridian HQ',
            style: TextStyle(
              fontFamily: NavigationSidebarThemeData.bodyFont,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: s.fg2,
            )),
        const SizedBox(width: 6),
        Icon(Icons.unfold_more, size: 14, color: s.fg3),
      ]),
    );
  }
}

// ── Mode & theme toggle buttons ────────────────────────────────────
class _ModeToggle extends StatelessWidget {
  final bool mobile;
  final VoidCallback onTap;
  const _ModeToggle({required this.mobile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = NavigationSidebarThemeData.of(context);
    return Tooltip(
      message: mobile ? 'Switch to desktop layout' : 'Switch to mobile layout',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: s.inputBg,
            borderRadius:
                BorderRadius.circular(s.radiusMd),
            border: Border.all(color: s.border),
          ),
          child: Icon(
            mobile
                ? Icons.desktop_windows_outlined
                : Icons.phone_android_outlined,
            size: 16,
            color: s.fg2,
          ),
        ),
      ),
    );
  }
}

class _ThemeToggleBtn extends StatelessWidget {
  final bool dark;
  final VoidCallback onTap;
  const _ThemeToggleBtn({required this.dark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = NavigationSidebarThemeData.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: s.inputBg,
          borderRadius:
              BorderRadius.circular(s.radiusMd),
          border: Border.all(color: s.border),
        ),
        child: Icon(
          dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          size: 16,
          color: s.fg2,
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
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          node?.label ?? 'Workspace',
          style: TextStyle(
            fontFamily: NavigationSidebarThemeData.displayFont,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: s.fg1,
          ),
        ),
        const SizedBox(height: 20),
        // Capability callout card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: s.surface,
            border: Border.all(color: s.border),
            borderRadius:
                BorderRadius.circular(s.radiusLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('05 · AppBar Integration',
                  style: TextStyle(
                    fontFamily: NavigationSidebarThemeData.displayFont,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: s.fg1,
                  )),
              const SizedBox(height: 12),
              _item(s, Icons.view_sidebar_outlined, 'Connected controller',
                  'The AppBar and the sidebar share the same NavigationSidebarController — '
                  'breadcrumb, collapse toggle, and hamburger all react to the same state.'),
              _item(s, Icons.menu_rounded, 'Drawer mode (mobile)',
                  'Tap the phone icon (top-right) to switch to drawer layout. '
                  'The hamburger in the AppBar opens the drawer via controller.openDrawer().'),
              _item(s, Icons.search, 'Global search',
                  'The search field in the AppBar drives controller.setQuery() — '
                  'the sidebar tree filters live as you type.'),
              _item(s, Icons.route_outlined, 'NavBreadcrumb',
                  'NavBreadcrumb<T> reads ancestor labels from the controller '
                  'and renders a › separated trail. Navigate to Journal Entry to see depth-3 crumbs.'),
              _item(s, Icons.corporate_fare_outlined, 'Slots',
                  'title, pageTitle, globalSearch, middle, and actions are all '
                  'independent slots — use as many or as few as your layout needs.'),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _item(NavigationSidebarThemeData s, IconData icon, String title,
      String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: NavigationSidebarThemeData.accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              size: 15, color: NavigationSidebarThemeData.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(
                  fontFamily: NavigationSidebarThemeData.bodyFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: s.fg1,
                )),
            const SizedBox(height: 2),
            Text(body,
                style: TextStyle(
                  fontFamily: NavigationSidebarThemeData.bodyFont,
                  fontSize: 12.5,
                  height: 1.5,
                  color: s.fg3,
                )),
          ]),
        ),
      ]),
    );
  }
}
