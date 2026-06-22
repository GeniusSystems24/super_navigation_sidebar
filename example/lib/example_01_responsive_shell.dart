// super_navigation_sidebar · Example 01 — Responsive app shell
// ─────────────────────────────────────────────────────────────────
// Goal: demonstrate all three modes live via a device-width simulator.
//
//   A workbench bar at the top shows 4 device presets:
//     Fill · Desktop 1280 · Tablet 900 · Mobile 390
//
//   Selecting a preset changes the simulated width → LayoutBuilder +
//   NavSidebarBreakpoints derives the mode:
//     expanded ≥ 1200  ·  rail ≥ 768  ·  drawer below
//
//   The sidebar has a real header (logo mark), a real footer (theme
//   toggle + help card), and a faux page that shows a breadcrumb built
//   from NavOps.ancestorsOf.
//
//   A hamburger button in the mock app bar opens the drawer on mobile.

import 'package:flutter/material.dart';
import 'package:super_navigation_sidebar/super_navigation_sidebar.dart';

// ── Minimal section tree for this demo ───────────────────────────
final _sections = <NavSection<String>>[
  NavSection(title: 'Overview', items: [
    NavNode(id: 'dashboard',    label: 'Dashboard',
            icon: Icons.dashboard_outlined,  value: 'dashboard',
            shortcut: ['g', 'd']),
    NavNode(id: 'invDashboard', label: 'Inventory Dashboard',
            icon: Icons.qr_code_scanner,     value: 'invDashboard'),
  ]),
  NavSection(title: 'Finance', items: [
    NavNode(id: 'accountsHub', label: 'Accounts',
            icon: Icons.menu_book_outlined, children: [
      NavNode(id: 'coaGroup', label: 'Chart of Accounts', children: [
        NavNode(id: 'accounts',    label: 'Chart of Accounts',
                icon: Icons.menu_book_outlined, value: 'accounts'),
        NavNode(id: 'accountTree', label: 'Account Tree',
                icon: Icons.account_tree_outlined, value: 'accountTree',
                badge: NavBadge('3'), shortcut: ['g', 't']),
      ]),
    ]),
    NavNode(id: 'ledgerHub', label: 'Ledger',
            icon: Icons.receipt_long_outlined, children: [
      NavNode(id: 'jeGroup', label: 'Journal Entries', children: [
        NavNode(id: 'journals',      label: 'Journal Entries',
                icon: Icons.receipt_long_outlined, value: 'journals',
                badge: NavBadge('3')),
        NavNode(id: 'createJournal', label: 'Create Journal Entry',
                icon: Icons.add, value: 'createJournal'),
      ]),
    ]),
  ]),
  NavSection(title: 'Administration', items: [
    NavNode(id: 'settingsHub', label: 'Settings',
            icon: Icons.settings_outlined, children: [
      NavNode(id: 'wsGroup', label: 'Workspace', children: [
        NavNode(id: 'settingsGeneral',  label: 'General',
                icon: Icons.settings_outlined,  value: 'settingsGeneral'),
        NavNode(id: 'settingsPlatform', label: 'Platform',
                icon: Icons.explore_outlined,   value: 'settingsPlatform'),
      ]),
    ]),
  ]),
];

class ResponsiveShellExample extends StatefulWidget {
  const ResponsiveShellExample({super.key});
  @override
  State<ResponsiveShellExample> createState() =>
      _ResponsiveShellExampleState();
}

enum _Device { fill, desktop, tablet, mobile }

const _devices = <(_Device, String, double?)>[
  (_Device.fill,    'Fill',           null),
  (_Device.desktop, 'Desktop · 1280', 1280),
  (_Device.tablet,  'Tablet · 900',   900),
  (_Device.mobile,  'Mobile · 390',   390),
];

class _ResponsiveShellExampleState
    extends State<ResponsiveShellExample> {
  bool _light = false;
  _Device _device = _Device.fill;
  String _screen = 'dashboard';
  NavSidebarMode? _prevMode;

  late final NavigationSidebarController<String> _nav =
      NavigationSidebarController<String>(
    sections: _sections,
    active: 'dashboard',
  );

  @override
  void dispose() {
    _nav.dispose();
    super.dispose();
  }

  // Sync collapsed only when the breakpoint CHANGES — preserves explicit
  // user toggles within a breakpoint.
  void _syncMode(NavSidebarMode mode) {
    if (mode == _prevMode) return;
    _prevMode = mode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (mode == NavSidebarMode.expanded) _nav.collapsed = false;
      else if (mode == NavSidebarMode.rail) _nav.collapsed = true;
      else _nav.closeDrawer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = _light
        ? NavigationSidebarThemeData.light
        : NavigationSidebarThemeData.dark;

    return Theme(
      data: Theme.of(context).copyWith(extensions: [theme]),
      child: Builder(builder: (ctx) {
        final s = NavigationSidebarThemeData.of(ctx);
        final dev = _devices.firstWhere((d) => d.$1 == _device);

        return Scaffold(
          backgroundColor: s.bg,
          // outer workbench appBar
          appBar: AppBar(
            backgroundColor: s.surface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: s.fg1),
              onPressed: () => Navigator.pop(ctx),
            ),
            title: Text('01 · Responsive shell',
                style: TextStyle(
                    fontFamily: NavigationSidebarThemeData.displayFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: s.fg1)),
          ),
          body: Column(children: [
            // ── device picker bar ─────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: s.surface,
                border: Border(bottom: BorderSide(color: s.border)),
              ),
              child: Row(children: [
                _SegCtrl(
                  options: [for (final d in _devices) d.$2],
                  selected:
                      _devices.indexWhere((d) => d.$1 == _device),
                  onChanged: (i) =>
                      setState(() => _device = _devices[i].$1),
                ),
                const Spacer(),
                _SegCtrl(
                  options: const ['Dark', 'Light'],
                  selected: _light ? 1 : 0,
                  onChanged: (i) => setState(() => _light = i == 1),
                ),
              ]),
            ),
            // ── simulated device frame ────────────────────
            Expanded(
              child: Container(
                color: s.bg,
                padding:
                    EdgeInsets.all(dev.$3 != null ? 20.0 : 0.0),
                alignment: Alignment.center,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                      dev.$3 != null ? 14.0 : 0.0),
                  child: Container(
                    width: dev.$3,
                    decoration: BoxDecoration(
                      color: s.bg,
                      border: dev.$3 != null
                          ? Border.all(color: s.borderStrong)
                          : null,
                      borderRadius: BorderRadius.circular(
                          dev.$3 != null ? 14.0 : 0.0),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: LayoutBuilder(builder: (ctx2, c) {
                      // ← this is the key: mode derived from width
                      final mode = const NavSidebarBreakpoints()
                          .modeFor(c.maxWidth);
                      _syncMode(mode);

                      final sidebar = NavigationSidebar<String>(
                        controller: _nav,
                        mode: mode,
                        header: (c, collapsed) =>
                            _Logo(collapsed: collapsed),
                        footer: (c, collapsed) => _Footer(
                          collapsed: collapsed,
                          light: _light,
                          onToggle: (v) =>
                              setState(() => _light = v),
                        ),
                        onNavigate: (n) =>
                            setState(() => _screen = n.value!),
                      );

                      final page = _FauxPage(
                          nav: _nav, screen: _screen);

                      if (mode == NavSidebarMode.drawer) {
                        return Column(children: [
                          // mock app bar with hamburger
                          Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12),
                            decoration: BoxDecoration(
                              color: s.surface,
                              border: Border(
                                  bottom: BorderSide(
                                      color: s.border)),
                            ),
                            child: Row(children: [
                              GestureDetector(
                                onTap: _nav.openDrawer,
                                child: Icon(Icons.menu,
                                    color: s.fg1),
                              ),
                              const SizedBox(width: 14),
                              Text('GeniusLink',
                                  style: TextStyle(
                                      fontFamily:
                                          NavigationSidebarThemeData
                                              .displayFont,
                                      fontWeight:
                                          FontWeight.w700,
                                      color: s.fg1)),
                            ]),
                          ),
                          Expanded(
                            child: Stack(children: [
                              Positioned.fill(child: page),
                              Positioned.fill(child: sidebar),
                            ]),
                          ),
                        ]);
                      }

                      return Row(children: [
                        sidebar,
                        Expanded(child: page),
                      ]);
                    }),
                  ),
                ),
              ),
            ),
          ]),
        );
      }),
    );
  }
}

// ── Logo header slot ──────────────────────────────────────────────
class _Logo extends StatelessWidget {
  final bool collapsed;
  const _Logo({required this.collapsed});
  @override
  Widget build(BuildContext context) {
    final s = NavigationSidebarThemeData.of(context);
    return SizedBox(
      height: 40,
      child: Row(children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: NavigationSidebarThemeData.accent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('GL',
              style: TextStyle(
                  fontFamily: NavigationSidebarThemeData.displayFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ),
        if (!collapsed) ...[
          const SizedBox(width: 10),
          Text('GeniusLink',
              style: TextStyle(
                  fontFamily: NavigationSidebarThemeData.displayFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: s.fg1)),
        ],
      ]),
    );
  }
}

// ── Footer slot ───────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  final bool collapsed, light;
  final ValueChanged<bool> onToggle;
  const _Footer(
      {required this.collapsed,
      required this.light,
      required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final s = NavigationSidebarThemeData.of(context);
    if (collapsed) {
      return GestureDetector(
        onTap: () => onToggle(!light),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: s.inputBg,
            borderRadius: BorderRadius.circular(
                NavigationSidebarThemeData.radiusMd),
            border: Border.all(color: s.border),
          ),
          child: Icon(
              light
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              size: 18,
              color: s.fg2),
        ),
      );
    }
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // theme toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: s.inputBg,
              border: Border.all(color: s.border),
              borderRadius: BorderRadius.circular(
                  NavigationSidebarThemeData.radiusMd),
            ),
            child: Row(children: [
              for (final opt in const [(false, 'DARK'), (true, 'LIGHT')])
                Expanded(
                  child: GestureDetector(
                    onTap: () => onToggle(opt.$1),
                    child: AnimatedContainer(
                      duration: NavigationSidebarThemeData.durFast,
                      padding:
                          const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: light == opt.$1
                            ? s.surface
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(opt.$2,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              letterSpacing: 1.0,
                              color: light == opt.$1
                                  ? s.fg1
                                  : s.fg3)),
                    ),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 10),
          // help card
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: s.inputBg,
              border: Border.all(color: s.border),
              borderRadius: BorderRadius.circular(
                  NavigationSidebarThemeData.radiusLg),
            ),
            child: Row(children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: NavigationSidebarThemeData.accent
                      .withOpacity(0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.info_outline,
                    size: 16,
                    color: NavigationSidebarThemeData.accent),
              ),
              const SizedBox(width: 10),
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Need help?',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: s.fg1)),
                    Text('Go to Help Center →',
                        style:
                            TextStyle(fontSize: 11, color: s.fg3)),
                  ]),
            ]),
          ),
        ]);
  }
}

// ── Faux page ─────────────────────────────────────────────────────
class _FauxPage extends StatelessWidget {
  final NavigationSidebarController<String> nav;
  final String screen;
  const _FauxPage({required this.nav, required this.screen});

  @override
  Widget build(BuildContext context) {
    final s = NavigationSidebarThemeData.of(context);
    final ancestors = NavOps.ancestorsOf<String>(nav.sections, screen)
        .map((id) => nav.node(id)?.label ?? id)
        .toList();
    final node = nav.node(screen);
    final crumb = [...ancestors, if (node != null) node.label].join(' › ');
    final muted = BoxDecoration(
      color: s.surface,
      borderRadius: BorderRadius.circular(
          NavigationSidebarThemeData.radiusMd),
      border: Border.all(color: s.border),
    );

    return Container(
      color: s.bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(crumb.toUpperCase(),
                  style: TextStyle(
                      fontFamily: NavigationSidebarThemeData.monoFont,
                      fontSize: 10.5,
                      letterSpacing: 1.6,
                      color: s.fg4)),
              const SizedBox(height: 12),
              Opacity(
                  opacity: 0.5,
                  child: Container(
                      height: 26, width: 240, decoration: muted)),
              const SizedBox(height: 20),
              LayoutBuilder(builder: (ctx, c) {
                final cols = c.maxWidth > 600 ? 3 : 2;
                final w =
                    (c.maxWidth - (cols - 1) * 16) / cols;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (int i = 0; i < cols; i++)
                      Opacity(
                          opacity: 0.5,
                          child: SizedBox(
                              width: w,
                              height: 100,
                              child: DecoratedBox(
                                  decoration: muted))),
                  ],
                );
              }),
              const SizedBox(height: 18),
              Opacity(
                  opacity: 0.5,
                  child: Container(
                      height: 260, decoration: muted)),
            ]),
      ),
    );
  }
}

// ── Segmented control ─────────────────────────────────────────────
class _SegCtrl extends StatelessWidget {
  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;
  const _SegCtrl(
      {required this.options,
      required this.selected,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = NavigationSidebarThemeData.of(context);
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: s.inputBg,
        border: Border.all(color: s.border),
        borderRadius: BorderRadius.circular(
            NavigationSidebarThemeData.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(options.length, (i) {
          final active = i == selected;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: NavigationSidebarThemeData.durFast,
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: active
                    ? NavigationSidebarThemeData.accent
                    : Colors.transparent,
                borderRadius:
                    BorderRadius.circular(NavigationSidebarThemeData.radiusSm),
              ),
              child: Text(options[i],
                  style: TextStyle(
                      fontFamily: NavigationSidebarThemeData.monoFont,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : s.fg2)),
            ),
          );
        }),
      ),
    );
  }
}
