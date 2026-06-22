// super_navigation_sidebar · Example 03 — Custom theme + RTL + branded colours
// ─────────────────────────────────────────────────────────────────────────────
// Goal: demonstrate the theming API, RTL mirror, and every chrome toggle.
//
//   Three themes (segmented control):
//     Default Dark  — NavigationSidebarThemeData.dark
//     Default Light — NavigationSidebarThemeData.light
//     Warm ✦        — light.copyWith(...) with annotated fields
//
//   LTR / RTL toggle — wraps the sidebar in Directionality
//
//   showGuides toggle — hides the │ ├ └ connector lines
//   railFlyouts toggle — disables module hover flyouts in rail mode
//   Mode toggle — expanded / rail
//
//   Annotated comments explain every copyWith field.

import 'package:flutter/material.dart';
import 'package:super_navigation_sidebar/super_navigation_sidebar.dart';

final _sections = <NavSection<String>>[
  NavSection(title: 'Overview', items: [
    NavNode(id: 'dashboard', label: 'Dashboard',
            icon: Icons.dashboard_outlined, value: 'dashboard',
            shortcut: ['g', 'd']),
    NavNode(id: 'reports',   label: 'Reports',
            icon: Icons.description_outlined, value: 'reports'),
  ]),
  NavSection(title: 'Finance', items: [
    NavNode(id: 'accountsHub', label: 'Accounts',
            icon: Icons.menu_book_outlined, children: [
      NavNode(id: 'coaGroup', label: 'Chart of Accounts', children: [
        NavNode(id: 'accounts',    label: 'Chart of Accounts',
                icon: Icons.menu_book_outlined, value: 'accounts'),
        NavNode(id: 'accountTree', label: 'Account Tree',
                icon: Icons.account_tree_outlined, value: 'accountTree',
                badge: NavBadge('3')),
      ]),
    ]),
    NavNode(id: 'journals', label: 'Journals',
            icon: Icons.receipt_long_outlined, value: 'journals',
            badge: NavBadge('Live', tone: NavBadgeTone.success)),
  ]),
  NavSection(title: 'Administration', items: [
    NavNode(id: 'settings', label: 'Settings',
            icon: Icons.settings_outlined, value: 'settings'),
  ]),
];

enum _ThemeChoice { dark, light, warm }

class ThemeRtlExample extends StatefulWidget {
  const ThemeRtlExample({super.key});
  @override
  State<ThemeRtlExample> createState() => _ThemeRtlExampleState();
}

class _ThemeRtlExampleState extends State<ThemeRtlExample> {
  _ThemeChoice _theme = _ThemeChoice.dark;
  bool _rtl = false;
  bool _showGuides = true;
  bool _railFlyouts = true;
  bool _railMode = false;
  String _screen = 'dashboard';

  final _nav = NavigationSidebarController<String>(
    sections: _sections,
    active: 'dashboard',
  );

  @override
  void dispose() {
    _nav.dispose();
    super.dispose();
  }

  // ── Theme factory ─────────────────────────────────────────────
  static NavigationSidebarThemeData _themeData(_ThemeChoice c) {
    switch (c) {
      case _ThemeChoice.dark:
        return NavigationSidebarThemeData.dark;

      case _ThemeChoice.light:
        return NavigationSidebarThemeData.light;

      case _ThemeChoice.warm:
        // Warm sidebar — every copyWith field annotated:
        return NavigationSidebarThemeData.light.copyWith(
          // bg: page backdrop behind the sidebar — warm parchment
          bg:           const Color(0xFFF7F3EE),
          // surface: the sidebar panel fill
          surface:      const Color(0xFFFFFFFF),
          // inputBg: boxed-icon fill + chip backgrounds
          inputBg:      const Color(0xFFEEE9E2),
          // hover: row hover tint
          hover:        const Color(0xFFEAE4DB),
          // border: hairline dividers between rows
          border:       const Color(0xFFDDD7CE),
          // borderStrong: outer panel edge + flyout card border
          borderStrong: const Color(0xFFBBB4A8),
          // guide: the │ ├ └ connector lines
          guide:        const Color(0xFFCEC8C0),
          // fg1: active label / primary text
          fg1:          const Color(0xFF1A1714),
          // fg2: row labels (inactive)
          fg2:          const Color(0xFF3D3830),
          // fg3: icons, group eyebrows, chevrons
          fg3:          const Color(0xFF7A7268),
          // fg4: section eyebrows (uppercase muted)
          fg4:          const Color(0xFFBBB4A8),
          // NOTE: accent, success, warning, danger are static consts —
          // they cannot be overridden via copyWith.
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = _themeData(_theme);

    return Theme(
      data: Theme.of(context).copyWith(extensions: [themeData]),
      child: Builder(builder: (ctx) {
        final s = NavigationSidebarThemeData.of(ctx);
        return Scaffold(
          backgroundColor: s.bg,
          body: Column(children: [
            // ── controls bar ──────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: s.surface,
                border: Border(bottom: BorderSide(color: s.border)),
              ),
              child: Row(children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: s.fg1),
                  onPressed: () => Navigator.pop(ctx),
                ),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Theme picker
                      _Seg(
                        options: const ['Dark', 'Light', 'Warm ✦'],
                        selected: _theme.index,
                        onChanged: (i) => setState(
                            () => _theme = _ThemeChoice.values[i]),
                      ),
                      // LTR / RTL
                      _Seg(
                        options: const ['LTR', 'RTL'],
                        selected: _rtl ? 1 : 0,
                        onChanged: (i) =>
                            setState(() => _rtl = i == 1),
                      ),
                      // Expanded / Rail
                      _Seg(
                        options: const ['Expanded', 'Rail'],
                        selected: _railMode ? 1 : 0,
                        onChanged: (i) =>
                            setState(() => _railMode = i == 1),
                      ),
                      // Guides toggle
                      _Toggle(
                        label: 'Guides',
                        value: _showGuides,
                        onChanged: (v) =>
                            setState(() => _showGuides = v),
                      ),
                      // Rail flyouts toggle
                      _Toggle(
                        label: 'Flyouts',
                        value: _railFlyouts,
                        onChanged: (v) =>
                            setState(() => _railFlyouts = v),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
            // ── warm theme legend ─────────────────────────
            if (_theme == _ThemeChoice.warm)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                color: s.surface,
                child: Text(
                  '✦ Warm — bg #F7F3EE · surface #FFF · '
                  'inputBg #EEE9E2 · border #DDD7CE · '
                  'guide #CEC8C0 · fg1 #1A1714',
                  style: TextStyle(
                      fontFamily: NavigationSidebarThemeData.monoFont,
                      fontSize: 11,
                      color: s.fg3),
                ),
              ),
            // ── sidebar + faux page ───────────────────────
            Expanded(
              child: Row(children: [
                Directionality(
                  textDirection:
                      _rtl ? TextDirection.rtl : TextDirection.ltr,
                  child: NavigationSidebar<String>(
                    controller: _nav,
                    mode: _railMode
                        ? NavSidebarMode.rail
                        : NavSidebarMode.expanded,
                    showGuides: _showGuides,
                    railFlyouts: _railFlyouts,
                    header: (c, collapsed) =>
                        _Header(collapsed: collapsed),
                    footer: (c, collapsed) =>
                        _FooterHelp(collapsed: collapsed),
                    onNavigate: (n) =>
                        setState(() => _screen = n.value!),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: s.bg,
                    padding: const EdgeInsets.all(28),
                    child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(_screen.toUpperCase(),
                              style: TextStyle(
                                  fontFamily:
                                      NavigationSidebarThemeData
                                          .monoFont,
                                  fontSize: 10.5,
                                  letterSpacing: 1.6,
                                  color: s.fg4)),
                          const SizedBox(height: 8),
                          Text(
                              _nav.node(_screen)?.label ??
                                  'Screen',
                              style: TextStyle(
                                  fontFamily:
                                      NavigationSidebarThemeData
                                          .displayFont,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: s.fg1)),
                        ]),
                  ),
                ),
              ]),
            ),
          ]),
        );
      }),
    );
  }
}

// ── Header slot ───────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final bool collapsed;
  const _Header({required this.collapsed});
  @override
  Widget build(BuildContext context) {
    final s = NavigationSidebarThemeData.of(context);
    return SizedBox(
      height: 36,
      child: Row(children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: NavigationSidebarThemeData.accent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Text('GL',
              style: TextStyle(
                  fontFamily: NavigationSidebarThemeData.displayFont,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ),
        if (!collapsed) ...[
          const SizedBox(width: 10),
          Text('GeniusLink',
              style: TextStyle(
                  fontFamily: NavigationSidebarThemeData.displayFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: s.fg1)),
        ],
      ]),
    );
  }
}

// ── Footer help card ──────────────────────────────────────────────
class _FooterHelp extends StatelessWidget {
  final bool collapsed;
  const _FooterHelp({required this.collapsed});
  @override
  Widget build(BuildContext context) {
    final s = NavigationSidebarThemeData.of(context);
    if (collapsed) {
      return Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: s.inputBg,
          border: Border.all(color: s.border),
          borderRadius: BorderRadius.circular(
              NavigationSidebarThemeData.radiusMd),
        ),
        child: const Icon(Icons.info_outline,
            size: 18, color: NavigationSidebarThemeData.accent),
      );
    }
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: s.inputBg,
        border: Border.all(color: s.border),
        borderRadius: BorderRadius.circular(
            NavigationSidebarThemeData.radiusLg),
      ),
      child: Row(children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: NavigationSidebarThemeData.accent.withOpacity(0.14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.info_outline,
              size: 15, color: NavigationSidebarThemeData.accent),
        ),
        const SizedBox(width: 10),
        Text('Need help?',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: s.fg1)),
      ]),
    );
  }
}

// ── Segmented control ─────────────────────────────────────────────
class _Seg extends StatelessWidget {
  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;
  const _Seg(
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
        borderRadius:
            BorderRadius.circular(NavigationSidebarThemeData.radiusMd),
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
                borderRadius: BorderRadius.circular(
                    NavigationSidebarThemeData.radiusSm),
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

// ── Simple on/off toggle ──────────────────────────────────────────
class _Toggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle(
      {required this.label,
      required this.value,
      required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final s = NavigationSidebarThemeData.of(context);
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: value
              ? NavigationSidebarThemeData.accent.withOpacity(0.12)
              : s.inputBg,
          border: Border.all(
              color: value
                  ? NavigationSidebarThemeData.accent.withOpacity(0.4)
                  : s.border),
          borderRadius: BorderRadius.circular(
              NavigationSidebarThemeData.radiusMd),
        ),
        child: Text(label,
            style: TextStyle(
                fontFamily: NavigationSidebarThemeData.bodyFont,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: value
                    ? NavigationSidebarThemeData.accent
                    : s.fg2)),
      ),
    );
  }
}
