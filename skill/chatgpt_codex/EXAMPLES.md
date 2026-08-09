# super_navigation_sidebar — professional examples

Realistic, copy-ready recipes. Each assumes the import +
theme setup from AGENTS.md. With `super_core` 3.3.0, construct
`SuperMaterialThemeData.light/dark` with required `SuperTextTheme` values for
`textTheme` and `primaryTextTheme`; do not read typography from `SuperThemeData`.

---

## 1 · NavigationShell — recommended full-app wrapper

```dart
class _AppShellState extends State<AppShell> {
  final _nav = NavigationSidebarController<String>(
    sections: kNavSections, active: 'dashboard', canGoBack: false,
  );
  String _screen = 'dashboard';

  @override
  Widget build(BuildContext context) {
    return NavigationShell<String>(
      controller: _nav,
      headerLayout: NavShellHeaderLayout.spanning,
      paneBehavior: NavPaneBehavior.push,
      appBarBuilder: (ctx, mode) => NavigationSidebarAppBar(
        controller: _nav, mode: mode,
        showBackButton: true,
        onBack: () => Navigator.of(ctx).maybePop(),
        pageTitle: NavBreadcrumb<String>(controller: _nav),
        globalSearch: NavigationSidebarSearchField(controller: _nav),
        actions: [_NotificationBell(), _UserAvatar()],
      ),
      sidebarBuilder: (ctx, mode) => NavigationSidebar<String>(
        controller: _nav, mode: mode,
        searchable: true, favoritable: true,
        onNavigate: (n) => setState(() => _screen = n.value!),
      ),
      body: _PageFor(screen: _screen),
    );
  }

  @override
  void dispose() { _nav.dispose(); super.dispose(); }
}
```

---

## 2 · Full responsive shell — manual Row/Column (no NavigationShell)

```dart
class _AppShellState extends State<AppShell> {
  final _nav = NavigationSidebarController<String>(
    sections: kNavSections, active: 'dashboard', canGoBack: false,
  );
  String _screen = 'dashboard';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final mode = const NavSidebarBreakpoints().modeFor(c.maxWidth);
      final sidebar = NavigationSidebar<String>(
        controller: _nav, mode: mode,
        header: (ctx, collapsed) => _Brand(collapsed: collapsed),
        onNavigate: (node) => setState(() => _screen = node.value!),
      );

      if (mode == NavSidebarMode.drawer) {
        return Scaffold(
          appBar: NavigationSidebarAppBar(
            controller: _nav,
            mode: NavSidebarMode.drawer,
            pageTitle: NavBreadcrumb<String>(controller: _nav),
          ),
          body: Stack(children: [
            Positioned.fill(child: _PageFor(screen: _screen)),
            Positioned.fill(child: sidebar),
          ]),
        );
      }

      return Row(children: [
        sidebar,
        Expanded(child: Column(children: [
          NavigationSidebarAppBar(
            controller: _nav,
            mode: mode,
            showCollapseToggle: true,
            pageTitle: NavBreadcrumb<String>(controller: _nav),
            globalSearch: NavigationSidebarSearchField(controller: _nav,
                hint: 'Search…'),
            actions: [_NotificationBell(), _UserAvatar()],
          ),
          Expanded(child: _PageFor(screen: _screen)),
        ])),
      ]);
    });
  }

  @override
  void dispose() { _nav.dispose(); super.dispose(); }
}
```

---

## 3 · Footer sections + Fluent selection indicator

```dart
// Footer section (Settings / Help pinned to pane bottom):
NavSection(
  title: '',
  placement: NavSectionPlacement.footer,
  items: [
    NavNode(id: 'help',     label: 'Help',     icon: Icons.help_outline,     value: 'help'),
    NavNode(id: 'settings', label: 'Settings', icon: Icons.settings_outlined, value: 'settings'),
  ],
);

// Fluent bar indicator — leading accent pill over tinted row:
ThemeData(
  extensions: [
    NavigationSidebarThemeData.dark.copyWith(
      selectionIndicator: NavSelectionIndicator.bar,
      indicatorThickness: 3,
      indicatorInset: 9,
    ),
  ],
)
```

---

## 4 · Localization — Arabic RTL

```dart
Directionality(
  textDirection: TextDirection.rtl,
  child: NavigationSidebar<String>(
    controller: nav,
    mode: mode,
    localizations: NavigationSidebarLocalizations.arabic,
  ),
)

// Custom partial override:
NavigationSidebar<String>(
  controller: nav, mode: mode,
  localizations: const NavigationSidebarLocalizations(
    searchHint: 'Buscar navegación…',
    lockedDefault: 'Acceso restringido',
  ),
)
```

---

## 5 · Navigation safety — locked/disabled nodes

```dart
// navigate() returns bool — false means refused:
final ok = nav.navigate('wire'); // false if locked

// onNavigate is NEVER fired for locked or disabled nodes:
NavigationSidebar<String>(
  controller: nav,
  mode: mode,
  onNavigate: (node) {
    // Safe — guaranteed not locked/disabled here.
    setState(() => _screen = node.value!);
  },
)

// Locked node definition:
NavNode(id: 'wire', label: 'Wire/SWIFT', value: 'wire',
        locked: true, lockMessage: 'Requires Treasury Approver role');

// Disabled node:
NavNode(id: 'beta', label: 'Beta', value: 'beta', enabled: false);
```

---

## 6 · Deep immutability + duplicate ID validation

```dart
// Children/items are List.unmodifiable — mutation throws:
final node = NavNode(id: 'p', label: 'Parent',
    children: [NavNode(id: 'c', label: 'Child')]);
node.children.add(NavNode(id: 'x', label: 'X')); // UnsupportedError!

// Validate IDs before building the controller:
final dups = NavOps.findDuplicateIds<String>(sections);
assert(dups.isEmpty, 'Duplicate nav ids: $dups');

// NOTE: No const NavNode / const NavSection in 1.2+
// Replace: const NavNode(...) → NavNode(...)
```

---

## 7 · Live badge updates + collapse toggle

```dart
// Hot-swap sections to update badge counts:
_nav.replaceSections(updatedSections);

// AppBar collapse toggle (built-in):
NavigationSidebarAppBar(
  controller: _nav,
  mode: NavSidebarMode.expanded,
  showCollapseToggle: true,
)
// Or manually:
IconButton(icon: const Icon(Icons.view_sidebar_outlined),
           onPressed: _nav.toggleCollapsed);
```

---

## 8 · Custom theme + RTL

```dart
final warmTheme = NavigationSidebarThemeData.light.copyWith(
  bg:      const Color(0xFFF7F3EE),
  surface: const Color(0xFFFFFFFF),
  border:  const Color(0xFFDDD7CE),
  guide:   const Color(0xFFCEC8C0),
);

Theme(
  data: Theme.of(context).copyWith(extensions: [warmTheme]),
  child: Directionality(
    textDirection: TextDirection.rtl,
    child: NavigationSidebar<String>(
      controller: nav,
      mode: NavSidebarMode.expanded,
      localizations: NavigationSidebarLocalizations.arabic,
    ),
  ),
)
```

---

## 9 · Working shortcut chords — `NavShortcutBinder` (2.2)

```dart
// Chords declared on leaves become working keystrokes inside the binder:
NavNode(id: 'dashboard', label: 'Dashboard', value: 'dashboard',
        shortcut: ['ctrl', 'shift', 'd']); // combo (or ['g','d'] for a sequence)

NavShortcutBinder<String>(
  controller: _nav,
  onNavigate: (n) => setState(() => _screen = n.value!),
  chordTimeout: const Duration(milliseconds: 1200),
  child: NavigationShell<String>(…),
);
// Two styles, chosen per node from its key list:
//   ['ctrl','shift','d'] → Ctrl+Shift+D together (combo)
//   ['g', 'd']           → g then d (sequence)
// Suspended while text fields have focus; refuses locked/disabled nodes;
// rebuilds on replaceSections().
```

---

## 10 · Screen codes + keyword search (2.2)

```dart
// SAP-style codes + hidden bilingual aliases — both searchable everywhere:
NavNode(id: 'journalEntry', label: 'Journal Entry', value: 'journalEntry',
        code: 'JE01', keywords: ['قيد يومية', 'voucher', 'GL entry']);

// Inline filter and command palette match label + code + keywords.
// The palette renders the code as a mono chip and supports ↑↓ / ↵ / esc.
NavigationSidebar<String>(
  controller: nav, mode: mode,
  allowSearchDialog: true,
);
```

---

## 11 · Recents + state persistence (2.2)

```dart
// Recents fill automatically on successful navigation (MRU, max 8):
_nav.recents; _nav.recentNodes; _nav.clearRecents();
// Palette shows a "Recent" band while the query is empty
// (localizations.recentsTitle — Arabic preset: 'الأخيرة').

// Persist the whole user-owned state in one snapshot:
_nav.addListener(() =>
    prefs.setString('nav', jsonEncode(_nav.snapshot().toJson())));

// Restore on launch — stale ids dropped, ancestors re-expanded, one notify:
final raw = prefs.getString('nav');
if (raw != null) {
  _nav.restore(NavSidebarStateSnapshot.fromJson(jsonDecode(raw)));
}
```

---

## 12 · Badge roll-up on collapsed modules (2.2)

```dart
NavNode(id: 'finance', label: 'Finance', icon: Icons.paid_outlined, children: [
  NavNode(id: 'approvals', label: 'Approvals', value: 'approvals',
          badge: NavBadge('3', tone: NavBadgeTone.danger)),
  NavNode(id: 'drafts', label: 'Draft Journals', value: 'drafts',
          badge: NavBadge('9')),
]);

NavigationSidebar<String>(
  controller: nav, mode: mode,
  aggregateBadges: true, // closed "Finance" row shows a "12" chip
);
// Non-numeric badges ('New') don't count; NavOps.subtreeBadgeSum(node) for hosts.
```
