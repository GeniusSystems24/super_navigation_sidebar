# super_navigation_sidebar — professional examples

Realistic, copy-ready recipes. Each assumes the import +
`NavigationSidebarThemeData` registration from AGENTS.md.

---

## 1 · Full responsive app shell

```dart
class _AppShellState extends State<AppShell> {
  final _nav = NavigationSidebarController<String>(
    sections: kNavSections, active: 'dashboard',
  );
  String _screen = 'dashboard';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final mode = const NavSidebarBreakpoints().modeFor(c.maxWidth);
      final sidebar = NavigationSidebar<String>(
        controller: _nav, mode: mode,
        header: (ctx, collapsed) => _Brand(collapsed: collapsed),
        footer: (ctx, collapsed) => _HelpCard(collapsed: collapsed),
        onNavigate: (node) => setState(() => _screen = node.value!),
      );
      if (mode == NavSidebarMode.drawer) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(icon: const Icon(Icons.menu), onPressed: _nav.openDrawer),
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

## 2 · Deep-link navigation from page content

```dart
TextButton(
  onPressed: () =>
      NavigationSidebarController.of<String>(context)?.navigate('journals'),
  child: const Text('Go to Journals'),
);

// Breadcrumb:
final ancestors = NavOps.ancestorsOf<String>(_nav.sections, _nav.active ?? '');
```

---

## 3 · Live badge updates + collapse toggle

```dart
// Hot-swap sections to update badge counts:
_nav.replaceSections(updatedSections);

// Hamburger toggle:
IconButton(icon: const Icon(Icons.view_sidebar_outlined), onPressed: _nav.toggleCollapsed);
```

---

## 4 · Custom theme + RTL

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
    child: NavigationSidebar<String>(controller: nav, mode: NavSidebarMode.expanded),
  ),
)
```
