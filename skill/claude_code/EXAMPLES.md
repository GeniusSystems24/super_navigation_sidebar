# super_navigation_sidebar — professional examples

Realistic, copy-ready recipes. Each assumes the import +
`NavigationSidebarThemeData` registration from SKILL.md.

---

## 1 · NavigationShell — recommended full-app wrapper

```dart
class _AppShellState extends State<AppShell> {
  final _nav = NavigationSidebarController<String>(
    sections: kNavSections, active: 'dashboard',
    canGoBack: false,
  );
  String _screen = 'dashboard';

  @override
  Widget build(BuildContext context) {
    return NavigationShell<String>(
      controller: _nav,
      headerLayout: NavShellHeaderLayout.spanning,
      paneBehavior: NavPaneBehavior.push,
      appBarBuilder: (ctx, mode) => NavigationSidebarAppBar(
        controller: _nav,
        mode: mode,
        showBackButton: true,
        onBack: () => Navigator.of(ctx).maybePop(),
        pageTitle: NavBreadcrumb<String>(controller: _nav),
        globalSearch: NavigationSidebarSearchField(controller: _nav),
        actions: [_NotificationBell(), _UserAvatar()],
      ),
      sidebarBuilder: (ctx, mode) => NavigationSidebar<String>(
        controller: _nav,
        mode: mode,
        searchable: true,
        favoritable: true,
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

## 2 · Full responsive app shell — manual Row/Column (no NavigationShell)

```dart
class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _nav = NavigationSidebarController<String>(
    sections: kNavSections, active: 'dashboard',
    canGoBack: false,
  );
  String _screen = 'dashboard';
  NavSidebarMode? _prevMode;

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
    return LayoutBuilder(builder: (context, c) {
      final mode = const NavSidebarBreakpoints().modeFor(c.maxWidth);
      _syncMode(mode);

      final sidebar = NavigationSidebar<String>(
        controller: _nav,
        mode: mode,
        header: (ctx, collapsed) => _Brand(collapsed: collapsed),
        footer: (ctx, collapsed) => _HelpCard(collapsed: collapsed),
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
        Expanded(
          child: Column(children: [
            NavigationSidebarAppBar(
              controller: _nav,
              mode: mode,
              showCollapseToggle: true,
              pageTitle: NavBreadcrumb<String>(controller: _nav),
            ),
            Expanded(child: _PageFor(screen: _screen)),
          ]),
        ),
      ]);
    });
  }

  @override
  void dispose() { _nav.dispose(); super.dispose(); }
}
```

---

## 3 · AppBar with global search, back button, workspace switcher, user info

```dart
NavigationSidebarAppBar(
  controller: nav,
  mode: mode,
  showCollapseToggle: true,
  showBackButton: true,          // enabled while nav.canGoBack == true
  onBack: () => router.pop(),

  // Breadcrumb reads ancestor path from the controller live:
  pageTitle: NavBreadcrumb<String>(
    controller: nav,
    separator: '  ›  ',
  ),

  // Global search drives the sidebar filter:
  globalSearch: NavigationSidebarSearchField(
    controller: nav,
    hint: 'Search accounts, journals, reports…',
  ),

  // Middle slot: workspace switcher, env badge, etc.
  middle: _WorkspaceSwitcher(),

  // Trailing actions:
  actions: [
    _NotificationBell(count: 4),
    const SizedBox(width: 4),
    _UserAvatar(initials: 'AR'),
  ],
)
```

---

## 4 · Deep-link navigation from inside page content

`navigate(id)` auto-expands every ancestor module and closes the drawer.
`NavigationSidebarController.of<T>(context)` makes it available anywhere
in the subtree. `navigate()` returns `bool` — use it to guard callbacks:

```dart
// From a page widget inside the shell:
TextButton(
  onPressed: () {
    final ok = NavigationSidebarController
        .of<String>(context)
        ?.navigate('journals');
    if (ok == true) {
      // navigation applied — safe to update local state
    }
  },
  child: const Text('Go to Journals'),
);

// From a router / push notification handler (outside the tree):
_nav.navigate('accountTree');  // expands ancestors, highlights leaf

// Breadcrumb from ancestors:
final ancestors = NavOps.ancestorsOf<String>(_nav.sections, _nav.active ?? '');
final labels = ancestors.map((id) => _nav.node(id)?.label ?? id).join(' › ');
```

---

## 5 · Live badge updates + collapse toggle

```dart
// Badges carry a tone — pill on expanded rows, dot on rail/collapsed icons:
NavNode(id: 'inbox',  label: 'Inbox',  icon: Icons.inbox_outlined, value: 'inbox',
        badge: NavBadge('9+', tone: NavBadgeTone.danger));
NavNode(id: 'sync',   label: 'Sync',   icon: Icons.sync, value: 'sync',
        badge: NavBadge('Live', tone: NavBadgeTone.success));

// Hot-swap sections (e.g. after an API call updates badge counts):
_nav.replaceSections(updatedSections);

// Collapse toggle in an AppBar:
NavigationSidebarAppBar(
  controller: _nav,
  mode: NavSidebarMode.expanded,
  showCollapseToggle: true,
)
// Or manually:
IconButton(icon: const Icon(Icons.view_sidebar_outlined), onPressed: _nav.toggleCollapsed);
```

---

## 6 · Footer sections (Settings / Help pinned to pane bottom)

```dart
// NavSectionPlacement.footer pins the section below the scroll area:
NavSection(
  title: '',
  placement: NavSectionPlacement.footer,
  items: [
    NavNode(id: 'help',     label: 'Help & Docs', icon: Icons.help_outline,     value: 'help'),
    NavNode(id: 'settings', label: 'Settings',    icon: Icons.settings_outlined, value: 'settings',
            shortcut: ['g', 's']),
  ],
);

// Footer items participate in the selection model normally:
nav.navigate('settings'); // highlights the footer row, breadcrumb updates
```

---

## 7 · Fluent bar selection indicator

```dart
// In your ThemeData:
ThemeData(
  extensions: [
    NavigationSidebarThemeData.dark.copyWith(
      selectionIndicator: NavSelectionIndicator.bar,
      indicatorThickness: 3,
      indicatorInset: 9,
    ),
  ],
)
// Works in expanded, rail, and drawer modes simultaneously.
```

---

## 8 · Localization — Arabic RTL

```dart
Directionality(
  textDirection: TextDirection.rtl,
  child: NavigationSidebar<String>(
    controller: nav,
    mode: NavSidebarMode.expanded,
    localizations: NavigationSidebarLocalizations.arabic,
  ),
)

// AppBar also localizes its semantic labels:
NavigationSidebarAppBar(
  controller: nav,
  mode: NavSidebarMode.drawer,
  localizations: NavigationSidebarLocalizations.arabic,
)
```

---

## 9 · Custom localization (partial override)

```dart
// Only override the strings you need — the rest stay English:
const myL10n = NavigationSidebarLocalizations(
  searchHint: 'Buscar navegación…',
  searchEmpty: 'Sin resultados para «{query}»',
  quickAccessTitle: 'Acceso Rápido',
  addToQuickAccess: 'Agregar a Acceso Rápido',
  removeFromQuickAccess: 'Quitar de Acceso Rápido',
  lockedDefault: 'Acceso restringido',
);

NavigationSidebar<String>(
  controller: nav,
  mode: mode,
  localizations: myL10n,
  searchable: true,
  favoritable: true,
)
```

---

## 10 · Permission-gated + status-dotted nodes (ERP)

```dart
// Locked node — dimmed, lock glyph, navigation refused, onNavigate never fires:
NavNode(id: 'wire', label: 'Wire / SWIFT', icon: Icons.bolt_outlined, value: 'wire',
        locked: true, lockMessage: 'Requires Treasury Approver role');

// Disabled node — shown but not clickable, onNavigate never fires:
NavNode(id: 'beta', label: 'Beta Feature', value: 'beta', enabled: false);

// Status dot — purely informational, does not block navigation:
NavNode(id: 'fy25q3', label: 'FY2025 · Q3', value: 'fy25q3',
        status: NavNodeStatus.open);      // green
NavNode(id: 'fy25q2', label: 'FY2025 · Q2', value: 'fy25q2',
        status: NavNodeStatus.closed);    // grey
NavNode(id: 'fy25q1', label: 'FY2025 · Q1', value: 'fy25q1',
        status: NavNodeStatus.locked);    // red
NavNode(id: 'recon',  label: 'Reconciliation', value: 'recon',
        status: NavNodeStatus.attention); // amber

// onNavigate is only called when navigation succeeds:
NavigationSidebar<String>(
  controller: nav,
  mode: mode,
  onNavigate: (node) {
    // Safe — this is NEVER called for locked or disabled nodes.
    setState(() => _screen = node.value!);
  },
)
```

---

## 11 · Deep immutability + duplicate ID validation

```dart
// Children and items are unmodifiable after construction.
// External mutation throws UnsupportedError:
final node = NavNode(id: 'parent', label: 'Parent', children: [
  NavNode(id: 'child', label: 'Child'),
]);
node.children.add(NavNode(id: 'x', label: 'X')); // throws!

// Debug-build duplicate ID assertion fires automatically in the controller.
// For explicit validation in tests or before constructing the controller:
final dups = NavOps.findDuplicateIds<String>(mySections);
assert(dups.isEmpty, 'Duplicate nav ids: $dups');

// IMPORTANT: constructors are no longer const (1.2+).
// Replace:  const NavNode(...)   with:  NavNode(...)
// Replace:  const NavSection(...)  with:  NavSection(...)
```

---

## 12 · Custom theme + RTL + branded colours

```dart
// Warm sidebar — every copyWith field explained:
final warmTheme = NavigationSidebarThemeData.light.copyWith(
  bg:           const Color(0xFFF7F3EE),
  surface:      const Color(0xFFFFFFFF),
  inputBg:      const Color(0xFFEEE9E2),
  hover:        const Color(0xFFEAE4DB),
  border:       const Color(0xFFDDD7CE),
  borderStrong: const Color(0xFFBBB4A8),
  guide:        const Color(0xFFCEC8C0),
  fg1:          const Color(0xFF1A1714),
  fg2:          const Color(0xFF3D3830),
  fg3:          const Color(0xFF7A7268),
  fg4:          const Color(0xFFBBB4A8),
);

Theme(
  data: Theme.of(context).copyWith(extensions: [warmTheme]),
  child: Directionality(
    textDirection: TextDirection.rtl,
    child: NavigationSidebar<String>(
      controller: nav,
      mode: NavSidebarMode.expanded,
      showGuides: true,
      localizations: NavigationSidebarLocalizations.arabic,
    ),
  ),
)
```

---

## 13 · Quick Access favorites

```dart
// Pre-seed favorites in the controller:
NavigationSidebarController<String>(
  sections: sections,
  active: 'dashboard',
  favorites: {'journalEntry', 'trialBalance', 'approvals'},
);

// Enable the UI (star toggles + Quick Access band at top):
NavigationSidebar<String>(
  controller: nav,
  mode: mode,
  favoritable: true,
  quickAccessTitle: 'Quick Access', // or via localizations
);

// Persist favorites by listening and saving the id set:
nav.addListener(() {
  prefs.setStringList('favorites', nav.favorites.toList());
});

// Restore on startup:
nav.setFavorites(prefs.getStringList('favorites') ?? []);
```
