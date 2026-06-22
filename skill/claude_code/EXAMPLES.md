# super_navigation_sidebar — professional examples

Realistic, copy-ready recipes. Each assumes the import +
`NavigationSidebarThemeData` registration from SKILL.md.

---

## 1 · Full responsive app shell (expanded / rail / drawer from width)

```dart
class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _nav = NavigationSidebarController<String>(
    sections: kNavSections, active: 'dashboard',
  );
  String _screen = 'dashboard';
  NavSidebarMode? _prevMode;

  // Sync the controller's collapsed flag with the mode ONLY when the
  // breakpoint changes — so an explicit user toggle within a breakpoint
  // is preserved.
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
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: _nav.openDrawer,
            ),
          ),
          body: Stack(children: [
            Positioned.fill(child: _PageFor(screen: _screen)),
            Positioned.fill(child: sidebar),
          ]),
        );
      }
      return Row(children: [sidebar, Expanded(child: _PageFor(screen: _screen))]);
    });
  }

  @override
  void dispose() { _nav.dispose(); super.dispose(); }
}
```

---

## 2 · Deep-link navigation from inside page content

`navigate(id)` auto-expands every ancestor module and closes the drawer.
`NavigationSidebarController.of<T>(context)` makes it available anywhere
in the subtree:

```dart
// From a page widget inside the shell:
TextButton(
  onPressed: () =>
      NavigationSidebarController.of<String>(context)?.navigate('journals'),
  child: const Text('Go to Journals'),
);

// From a router / push notification handler (outside the tree):
_nav.navigate('accountTree');  // expands Accounts ▸ Chart of Accounts, highlights leaf

// Breadcrumb from ancestors:
final ancestors = NavOps.ancestorsOf<String>(_nav.sections, _nav.active ?? '');
final labels = ancestors.map((id) => _nav.node(id)?.label ?? id).join(' › ');
```

---

## 3 · Live badge updates + collapse toggle

```dart
// Badges carry a tone — pill on expanded rows, dot on rail/collapsed icons:
NavNode(id: 'inbox',  label: 'Inbox',  icon: Icons.inbox_outlined, value: 'inbox',
        badge: NavBadge('9+', tone: NavBadgeTone.danger));
NavNode(id: 'sync',   label: 'Sync',   icon: Icons.sync, value: 'sync',
        badge: NavBadge('Live', tone: NavBadgeTone.success));
NavNode(id: 'audit',  label: 'Audit Log', icon: Icons.lock_outline, value: 'audit',
        badge: NavBadge('12', tone: NavBadgeTone.muted));

// Hot-swap sections (e.g. after an API call updates badge counts):
_nav.replaceSections(updatedSections);

// Hamburger / rail toggle in the app bar:
IconButton(
  icon: const Icon(Icons.view_sidebar_outlined),
  onPressed: _nav.toggleCollapsed,
);
```

---

## 4 · Custom theme + RTL + branded colours

```dart
// Warm sidebar — every copyWith field explained:
final warmTheme = NavigationSidebarThemeData.light.copyWith(
  bg:           const Color(0xFFF7F3EE), // page backdrop — parchment
  surface:      const Color(0xFFFFFFFF), // sidebar panel
  inputBg:      const Color(0xFFEEE9E2), // boxed-icon fill / chip bg
  hover:        const Color(0xFFEAE4DB), // row hover tint
  border:       const Color(0xFFDDD7CE), // hairline
  borderStrong: const Color(0xFFBBB4A8), // flyout edge
  guide:        const Color(0xFFCEC8C0), // │ ├ └ connectors
  fg1:          const Color(0xFF1A1714), // active label
  fg2:          const Color(0xFF3D3830), // row label
  fg3:          const Color(0xFF7A7268), // icons / group labels
  fg4:          const Color(0xFFBBB4A8), // section eyebrows
);

// Apply via Theme override:
Theme(
  data: Theme.of(context).copyWith(extensions: [warmTheme]),
  child: Directionality(             // RTL wraps the whole sidebar
    textDirection: TextDirection.rtl,
    child: NavigationSidebar<String>(
      controller: nav,
      mode: NavSidebarMode.expanded,
      showGuides: true,
      railFlyouts: false,            // disable flyouts in warm brand
    ),
  ),
)
```
