// super_navigation_sidebar · Example app launcher
//
// A polished launcher: hero header + responsive card grid, each card carrying
// a live token-driven mini-preview of the sidebar mode it opens. Every example
// is pushed with a floating "back to demos" button.

import 'package:flutter/material.dart';
import 'package:super_navigation_sidebar/super_navigation_sidebar.dart';

import 'example_01_responsive_shell.dart';
import 'example_02_admin_dashboard.dart';
import 'example_03_theme_rtl.dart';
import 'example_04_erp_banking.dart';
import 'example_05_appbar_integration.dart';
import 'example_06_navigation_shell.dart';
import 'navigation_sidebar_demo.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});
  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  bool _dark = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'super_navigation_sidebar examples',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A7CFF)),
        fontFamily: NavigationSidebarThemeData.bodyFont,
        scaffoldBackgroundColor: NavigationSidebarThemeData.light.bg,
        extensions: const [NavigationSidebarThemeData.light],
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4A7CFF), brightness: Brightness.dark),
        fontFamily: NavigationSidebarThemeData.bodyFont,
        scaffoldBackgroundColor: NavigationSidebarThemeData.dark.bg,
        extensions: const [NavigationSidebarThemeData.dark],
      ),
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      home: LauncherScreen(
        dark: _dark,
        onToggleTheme: (v) => setState(() => _dark = v),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// LAUNCHER
// ════════════════════════════════════════════════════════════
class LauncherScreen extends StatelessWidget {
  final bool dark;
  final ValueChanged<bool> onToggleTheme;
  const LauncherScreen(
      {super.key, required this.dark, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    final s = NavigationSidebarThemeData.of(context);

    final demos = <_Demo>[
      _Demo(
        title: 'Responsive app shell',
        subtitle:
            'A device-width simulator (Fill · Desktop · Tablet · Mobile) drives '
            'NavSidebarBreakpoints — watch the same controller flip between '
            'expanded, rail and drawer modes.',
        badge: 'expanded · rail · drawer',
        preview: const _SidebarThumb(mode: _Mode.expanded, activeIndex: 1),
        screen: const ResponsiveShellExample(),
      ),
      _Demo(
        title: 'Admin dashboard',
        subtitle:
            '15+ nodes across 4 sections with badge tones and shortcut hints. '
            'Deep-link from page content via of(context), and live badge updates '
            'through replaceSections.',
        badge: 'badges · shortcuts · of(context)',
        preview: const _SidebarThumb(
            mode: _Mode.expanded, activeIndex: 2, badges: true),
        screen: const AdminDashboardExample(),
      ),
      _Demo(
        title: 'Custom theme + RTL',
        subtitle:
            'Three themes (Dark / Light / Warm) built with copyWith, an LTR/RTL '
            'toggle, plus showGuides and railFlyouts switches.',
        badge: 'theming · RTL',
        preview: const _SidebarThumb(
            mode: _Mode.expanded, activeIndex: 0, warm: true),
        screen: const ThemeRtlExample(),
      ),
      _Demo(
        title: 'Banking / accounting ERP',
        subtitle:
            'The ERP capability set — built-in search & filter, Quick Access '
            'favorites, permission-locked screens, and fiscal-period status '
            'dots on a deep banking tree.',
        badge: 'search · favorites · locked · status',
        preview: const _SidebarThumb(
            mode: _Mode.expanded, activeIndex: 2, badges: true, erp: true),
        screen: const ErpBankingExample(),
      ),
      _Demo(
        title: 'AppBar integration',
        subtitle: 'NavigationSidebarAppBar connected to the same controller — '
            'breadcrumb, global search, collapse toggle, workspace switcher, '
            'notifications and user avatar. Toggle between drawer and desktop layouts.',
        badge: 'appbar · breadcrumb · search',
        preview: const _SidebarThumb(mode: _Mode.expanded, activeIndex: 0),
        screen: const AppBarIntegrationExample(),
      ),
      _Demo(
        title: 'Integrated NavigationShell',
        subtitle:
            'The 2.0 shell composes app bar + pane + content in one widget. '
            'Live toggles for header layout (spanning · inset), pane behavior '
            '(push · overlay), Fluent bar indicator, a working back button and '
            'pinned footer nav items.',
        badge: 'shell · back · overlay · footer',
        preview: const _SidebarThumb(mode: _Mode.expanded, activeIndex: 1),
        screen: const NavigationShellExample(),
      ),
      _Demo(
        title: 'Full component workbench',
        subtitle:
            'The original showcase — device simulator, all three modes, live '
            'Light/Dark, LTR/RTL, command palette, and workspace + user menus.',
        badge: 'Original',
        preview: const _SidebarThumb(mode: _Mode.rail, activeIndex: 1),
        screen: const NavigationSidebarDemo(),
      ),
    ];

    return Scaffold(
      backgroundColor: s.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 44),
              children: [
                // ── hero ──────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            _Mark(),
                            const SizedBox(width: 12),
                            Text('SUPER_NAVIGATION_SIDEBAR',
                                style: TextStyle(
                                    fontFamily:
                                        NavigationSidebarThemeData.monoFont,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.6,
                                    color: NavigationSidebarThemeData.accent)),
                            const SizedBox(width: 10),
                            _VersionPill(),
                          ]),
                          const SizedBox(height: 16),
                          Text('Responsive app navigation',
                              style: TextStyle(
                                  fontFamily:
                                      NavigationSidebarThemeData.displayFont,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                  height: 1.05,
                                  color: s.fg1)),
                          const SizedBox(height: 12),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 640),
                            child: Text(
                              'One typed NavNode<T> tree renders as an expanded '
                              'tree, an icon rail with flyouts, or an off-canvas '
                              'drawer. Badges, shortcut hints, header/footer slots '
                              'and RTL included. Open any example to try it live.',
                              style: TextStyle(
                                  fontFamily:
                                      NavigationSidebarThemeData.bodyFont,
                                  fontSize: 14.5,
                                  height: 1.6,
                                  color: s.fg3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ThemeToggle(dark: dark, onToggle: onToggleTheme),
                  ],
                ),
                const SizedBox(height: 36),
                // ── grid ──────────────────────────────────────
                LayoutBuilder(builder: (context, c) {
                  final cols = c.maxWidth > 720 ? 2 : 1;
                  return GridView.count(
                    crossAxisCount: cols,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                    childAspectRatio: 1.42,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (var i = 0; i < demos.length; i++)
                        _DemoCard(
                          index: i + 1,
                          demo: demos[i],
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    _BackScaffold(child: demos[i].screen)),
                          ),
                        ),
                    ],
                  );
                }),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                      'MIT © GeniusLink · pure Flutter, zero dependencies',
                      style: TextStyle(
                          fontFamily: NavigationSidebarThemeData.monoFont,
                          fontSize: 11,
                          color: s.fg4)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Demo {
  final String title, subtitle, badge;
  final Widget preview;
  final Widget screen;
  const _Demo({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.preview,
    required this.screen,
  });
}

// ── Demo card ─────────────────────────────────────────────────────
class _DemoCard extends StatefulWidget {
  final int index;
  final _Demo demo;
  final VoidCallback onTap;
  const _DemoCard(
      {required this.index, required this.demo, required this.onTap});
  @override
  State<_DemoCard> createState() => _DemoCardState();
}

class _DemoCardState extends State<_DemoCard> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final s = NavigationSidebarThemeData.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: NavigationSidebarThemeData.durFast,
          curve: NavigationSidebarThemeData.curveStandard,
          transform: _h
              ? (Matrix4.identity()..translate(0.0, -4.0))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: s.surface,
            border: Border.all(
                color: _h
                    ? NavigationSidebarThemeData.accent.withOpacity(0.55)
                    : s.border),
            borderRadius: BorderRadius.circular(s.radiusXl),
            boxShadow: _h ? NavigationSidebarThemeData.popShadow : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(children: [
                  Positioned.fill(child: widget.demo.preview),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: s.bg.withOpacity(0.82),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: s.border),
                      ),
                      child: Text('0${widget.index}',
                          style: TextStyle(
                              fontFamily: NavigationSidebarThemeData.monoFont,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: s.fg2)),
                    ),
                  ),
                ]),
              ),
              Container(
                decoration: BoxDecoration(
                  color: s.surface,
                  border: Border(top: BorderSide(color: s.border)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(widget.demo.title,
                            style: TextStyle(
                                fontFamily:
                                    NavigationSidebarThemeData.displayFont,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                                color: s.fg1)),
                      ),
                      Icon(Icons.arrow_outward,
                          size: 16,
                          color:
                              _h ? NavigationSidebarThemeData.accent : s.fg3),
                    ]),
                    const SizedBox(height: 6),
                    Text(widget.demo.subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontFamily: NavigationSidebarThemeData.bodyFont,
                            fontSize: 12.5,
                            height: 1.5,
                            color: s.fg3)),
                    const SizedBox(height: 10),
                    _TagPill(widget.demo.badge),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// MINI SIDEBAR PREVIEW (token-driven; reflects dark/light)
// ════════════════════════════════════════════════════════════
enum _Mode { expanded, rail }

class _SidebarThumb extends StatelessWidget {
  final _Mode mode;
  final int activeIndex;
  final bool badges;
  final bool warm;
  final bool erp;
  const _SidebarThumb({
    required this.mode,
    required this.activeIndex,
    this.badges = false,
    this.warm = false,
    this.erp = false,
  });

  @override
  Widget build(BuildContext context) {
    final base = NavigationSidebarThemeData.of(context);
    final s = warm
        ? base.copyWith(
            bg: const Color(0xFFF3EEE7),
            surface: const Color(0xFFFFFFFF),
            inputBg: const Color(0xFFEAE3D9),
            hover: const Color(0xFFEAE3D9),
            border: const Color(0xFFDED7CB),
            guide: const Color(0xFFCEC6B9),
            fg1: const Color(0xFF231F1A),
            fg3: const Color(0xFF8A8175),
            fg4: const Color(0xFFB4A99A),
          )
        : base;
    const accent = NavigationSidebarThemeData.accent;

    final rows = erp
        ? <(IconData, String, NavBadgeTone?)>[
            (Icons.fact_check_outlined, 'Approvals', NavBadgeTone.danger),
            (Icons.event_available_outlined, 'FY25 · Q3', null),
            (Icons.edit_note_outlined, 'Journal Entry', null),
            (Icons.bolt_outlined, 'Wire / SWIFT', null),
            (Icons.balance, 'Trial Balance', null),
          ]
        : <(IconData, String, NavBadgeTone?)>[
            (Icons.dashboard_outlined, 'Dashboard', null),
            (
              Icons.menu_book_outlined,
              'Accounts',
              badges ? NavBadgeTone.success : null
            ),
            (
              Icons.receipt_long_outlined,
              'Journals',
              badges ? NavBadgeTone.danger : null
            ),
            (Icons.storefront_outlined, 'Inventory', null),
            (Icons.settings_outlined, 'Settings', null),
          ];

    Color toneColor(NavBadgeTone t) {
      switch (t) {
        case NavBadgeTone.success:
          return NavigationSidebarThemeData.success;
        case NavBadgeTone.danger:
          return NavigationSidebarThemeData.danger;
        case NavBadgeTone.warning:
          return NavigationSidebarThemeData.warning;
        case NavBadgeTone.muted:
          return s.fg3;
        case NavBadgeTone.accent:
          return accent;
      }
    }

    final isRail = mode == _Mode.rail;
    final panelW = isRail ? 52.0 : 132.0;

    Widget railIcon(int i) {
      final (icon, _, tone) = rows[i];
      final active = i == activeIndex;
      return Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.symmetric(vertical: 3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? accent.withOpacity(0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: active ? Border.all(color: accent.withOpacity(0.5)) : null,
        ),
        child: Stack(clipBehavior: Clip.none, children: [
          Icon(icon, size: 15, color: active ? accent : s.fg3),
          if (tone != null)
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                    color: toneColor(tone), shape: BoxShape.circle),
              ),
            ),
        ]),
      );
    }

    Widget expandedRow(int i) {
      final (icon, label, tone) = rows[i];
      final active = i == activeIndex;
      final locked = erp && i == 3;
      final statusOpen = erp && i == 1;
      final star = erp && (i == 2 || i == 4);
      return Opacity(
        opacity: locked ? 0.5 : 1,
        child: Container(
          height: 26,
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: active ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(children: [
            Icon(icon, size: 12, color: active ? Colors.white : s.fg3),
            const SizedBox(width: 7),
            if (statusOpen) ...[
              Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: NavigationSidebarThemeData.success,
                      shape: BoxShape.circle)),
              const SizedBox(width: 5),
            ],
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontFamily: NavigationSidebarThemeData.bodyFont,
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? Colors.white : s.fg2)),
            ),
            if (tone != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white.withOpacity(0.25)
                      : toneColor(tone).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(tone == NavBadgeTone.success ? 'Live' : '9+',
                    style: TextStyle(
                        fontFamily: NavigationSidebarThemeData.monoFont,
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : toneColor(tone))),
              ),
            if (star)
              Icon(Icons.star_rounded,
                  size: 11,
                  color: active
                      ? Colors.white
                      : NavigationSidebarThemeData.accent),
            if (locked) Icon(Icons.lock_outline, size: 10, color: s.fg3),
          ]),
        ),
      );
    }

    return Container(
      color: s.bg,
      child: Row(children: [
        // panel
        Container(
          width: panelW,
          decoration: BoxDecoration(
            color: s.surface,
            border: Border(right: BorderSide(color: s.border)),
          ),
          padding:
              EdgeInsets.symmetric(horizontal: isRail ? 9 : 10, vertical: 10),
          child: Column(
            crossAxisAlignment:
                isRail ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              // header
              if (isRail)
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: accent, borderRadius: BorderRadius.circular(7)),
                  child: const Text('GL',
                      style: TextStyle(
                          fontFamily: NavigationSidebarThemeData.displayFont,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                )
              else
                Row(children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: accent, borderRadius: BorderRadius.circular(6)),
                    child: const Text('GL',
                        style: TextStyle(
                            fontFamily: NavigationSidebarThemeData.displayFont,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                  const SizedBox(width: 7),
                  Text('GeniusLink',
                      style: TextStyle(
                          fontFamily: NavigationSidebarThemeData.displayFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: s.fg1)),
                ]),
              const SizedBox(height: 12),
              if (erp && !isRail) ...[
                Container(
                  height: 22,
                  padding: const EdgeInsetsDirectional.only(start: 7, end: 4),
                  decoration: BoxDecoration(
                    color: s.inputBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: s.border),
                  ),
                  child: Row(children: [
                    Icon(Icons.search, size: 10, color: s.fg3),
                    const SizedBox(width: 5),
                    Text('Search…',
                        style: TextStyle(
                            fontFamily: NavigationSidebarThemeData.bodyFont,
                            fontSize: 8.5,
                            color: s.fg4)),
                  ]),
                ),
                const SizedBox(height: 8),
              ],
              if (!isRail)
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 6),
                  child: Text(erp ? 'GENERAL LEDGER' : 'OVERVIEW',
                      style: TextStyle(
                          fontFamily: NavigationSidebarThemeData.monoFont,
                          fontSize: 7,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                          color: s.fg4)),
                ),
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < rows.length; i++)
                      isRail ? railIcon(i) : expandedRow(i),
                  ],
                ),
              ),
              // footer help
              if (!isRail)
                Container(
                  height: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: s.inputBg,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: s.border),
                  ),
                  child: Row(children: [
                    Icon(Icons.info_outline, size: 11, color: accent),
                    const SizedBox(width: 6),
                    Text('Need help?',
                        style: TextStyle(
                            fontFamily: NavigationSidebarThemeData.bodyFont,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: s.fg2)),
                  ]),
                )
              else
                Container(
                  width: 32,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: s.inputBg,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: s.border),
                  ),
                  child: Icon(Icons.info_outline, size: 12, color: accent),
                ),
            ],
          ),
        ),
        // faux page
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    width: 80,
                    height: 8,
                    decoration: BoxDecoration(
                        color: s.fg1.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(3))),
                const SizedBox(height: 10),
                Row(children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        height: 30,
                        decoration: BoxDecoration(
                          color: s.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: s.border),
                        ),
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: s.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: s.border),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// ── small shared bits ─────────────────────────────────────────────
class _Mark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: NavigationSidebarThemeData.accent,
        borderRadius: BorderRadius.circular(8),
      ),
      child:
          const Icon(Icons.view_sidebar_rounded, size: 16, color: Colors.white),
    );
  }
}

class _VersionPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: NavigationSidebarThemeData.accent.withOpacity(0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: NavigationSidebarThemeData.accent.withOpacity(0.35)),
      ),
      child: const Text('v2.0.0',
          style: TextStyle(
              fontFamily: NavigationSidebarThemeData.monoFont,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: NavigationSidebarThemeData.accent)),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String text;
  const _TagPill(this.text);
  @override
  Widget build(BuildContext context) {
    final s = NavigationSidebarThemeData.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: s.inputBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: s.border),
      ),
      child: Text(text,
          style: TextStyle(
              fontFamily: NavigationSidebarThemeData.monoFont,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: s.fg3)),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  final bool dark;
  final ValueChanged<bool> onToggle;
  const _ThemeToggle({required this.dark, required this.onToggle});
  @override
  Widget build(BuildContext context) {
    final s = NavigationSidebarThemeData.of(context);
    return GestureDetector(
      onTap: () => onToggle(!dark),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: s.surface,
            border: Border.all(color: s.borderStrong),
            borderRadius: BorderRadius.circular(s.radiusMd),
          ),
          child: Row(children: [
            Icon(dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                size: 15, color: s.fg2),
            const SizedBox(width: 8),
            Text(dark ? 'Dark' : 'Light',
                style: TextStyle(
                    fontFamily: NavigationSidebarThemeData.bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: s.fg1)),
          ]),
        ),
      ),
    );
  }
}

// ── floating "back to demos" wrapper for a pushed screen ──────────
class _BackScaffold extends StatelessWidget {
  final Widget child;
  const _BackScaffold({required this.child});
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned.fill(child: child),
      Positioned(
        left: 16,
        bottom: 16,
        child: SafeArea(
          child: Material(
            color: Colors.black.withOpacity(0.62),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => Navigator.of(context).maybePop(),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.arrow_back, size: 16, color: Colors.white),
                  SizedBox(width: 7),
                  Text('Demos',
                      style: TextStyle(
                          fontFamily: NavigationSidebarThemeData.bodyFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ]),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}
