---
name: super-navigation-sidebar
description: >
  How to use the super_navigation_sidebar Flutter package — a themeable,
  responsive app navigation sidebar with expanded / rail / drawer modes, typed
  NavNode<T> tree, badges, shortcuts, header/footer slots, RTL. Use when
  building or modifying a Flutter app's left-nav.
---

# super_navigation_sidebar · NavigationSidebar

A themeable, responsive **app navigation sidebar**. One data model (titled
**sections** of a **node tree**) renders in three modes the host picks from
the available width: a full **expanded** labelled tree with `│ ├ └`
connectors, an icon-only **rail** whose modules open hover flyouts, and an
off-canvas **drawer** with a scrim.

## Import & theme

```dart
import 'package:super_navigation_sidebar/super_navigation_sidebar.dart';

// Register on MaterialApp (falls back to dark if omitted):
ThemeData(extensions: const [NavigationSidebarThemeData.light]); // + .dark
```

## Quick start

```dart
// Self-contained (no external controller):
NavigationSidebar<String>(
  sections: mySections,
  active: 'dashboard',
  mode: NavSidebarMode.expanded,
  onNavigate: (node) => openScreen(node.value!),
);

// Responsive shell (host derives mode from width):
LayoutBuilder(builder: (context, c) {
  final mode = const NavSidebarBreakpoints().modeFor(c.maxWidth);
  // expanded ≥ 1200 · rail ≥ 768 · drawer below

  if (mode == NavSidebarMode.drawer) {
    return Stack(children: [
      Positioned.fill(child: page),
      Positioned.fill(
        child: NavigationSidebar<String>(controller: nav, mode: NavSidebarMode.drawer),
      ),
    ]);
  }
  return Row(children: [
    NavigationSidebar<String>(controller: nav, mode: mode),
    Expanded(child: page),
  ]);
});
```

## Data model

```dart
NavSection(title: 'Finance', items: [
  NavNode(id: 'accountsHub', label: 'Accounts',
          icon: Icons.menu_book_outlined, children: [
    NavNode(id: 'coa', label: 'Chart of Accounts', children: [
      NavNode(id: 'accounts', label: 'Chart of Accounts',
              icon: Icons.menu_book_outlined, value: 'accounts'),
      NavNode(id: 'accountTree', label: 'Account Tree',
              icon: Icons.account_tree_outlined, value: 'accountTree',
              badge: NavBadge('3'), shortcut: ['g', 't']),
    ]),
  ]),
]);
```

### Role derivation (positional — no explicit field)

| Position | Role | Visual |
|---|---|---|
| Depth-0 leaf | `direct` | Accent pill when active. |
| Depth-0 branch | `module` | Icon + chevron + accent tint when owning active. |
| Depth-≥1 branch | `group` | Uppercase bullet header. |
| Depth-≥1 leaf | `item` | Boxed icon + label. |

## Options & slots

```dart
NavigationSidebar<T>(
  controller: nav,                 // or sections + active
  mode: NavSidebarMode.expanded,
  showGuides: true,                // │ ├ └ connectors
  railFlyouts: true,               // module hover flyouts in rail
  shortcutMode: NavShortcutMode.onHover, // onHover / always / hidden
  drawerTitle: 'Navigation',
  header: (ctx, collapsed) => MyLogo(collapsed: collapsed),
  footer: (ctx, collapsed) => HelpCard(collapsed: collapsed),
  onNavigate: (node) {},
);
```

### Shortcut hints

A leaf's `shortcut: ['g', 'd']` renders as `G › D` keycaps. `shortcutMode`
controls inline visibility — `onHover` (default), `always`, or `hidden`. In
all modes the chord is still surfaced through the row tooltip
(`Shortcut · G then D`).

### ERP / banking extras

```dart
NavigationSidebar<String>(
  controller: nav,
  searchable: true,       // built-in filter field + match highlight
  favoritable: true,      // per-row star + synthesized Quick Access band
);

// Permission-gated + status-dotted nodes:
NavNode(id: 'wire', label: 'Wire / SWIFT', value: 'wire',
        locked: true, lockMessage: 'Requires Treasury Approver role');
NavNode(id: 'fy25q3', label: 'FY2025 · Q3', value: 'fy25q3',
        status: NavNodeStatus.open); // open/closed/locked/attention

// Controller favorites: favorites · favoriteNodes · isFavorite ·
// toggleFavorite · setFavorites (seed via the `favorites:` constructor arg).
```

Locked nodes are dimmed, show a lock glyph, can't be navigated to (the
controller refuses), and reveal `lockMessage` as a tooltip.

## `NavigationSidebarController<T>` API

```dart
final nav = NavigationSidebarController<String>(
  sections: sections, active: 'dashboard',
);

// Navigation:
nav.navigate('settingsHub'); // sets active + opens ancestors + closes drawer

// Expansion:
nav.toggleNode(id); nav.expandAll(); nav.collapseAll();

// Rail / drawer:
nav.toggleCollapsed();  // expanded ↔ rail
nav.openDrawer();       // mobile

// Data:
nav.replaceSections(newSections); // hot-swap after a role change

// From inside page content:
NavigationSidebarController.of<String>(context)?.navigate('dashboard');
```

## Badges

```dart
NavBadge('3')                                 // accent (default)
NavBadge('Live', tone: NavBadgeTone.success)  // green pill / dot
NavBadge('9+',   tone: NavBadgeTone.danger)   // red
NavBadge('12',   tone: NavBadgeTone.muted)    // grey
```

Pill on expanded rows; dot on collapsed modules and rail icons.

## Theming

```dart
NavigationSidebarThemeData.light.copyWith(
  bg:      const Color(0xFFF5F3EF),
  surface: const Color(0xFFFFFFFF),
  border:  const Color(0xFFDDD7CE),
)
```

Brand constants: `accent #4A7CFF` · `success #1DB88A` · `warning #F97316` ·
`danger #EF4444`.

## RTL

```dart
Directionality(textDirection: TextDirection.rtl, child: NavigationSidebar(...))
```

## Gotchas

1. **Host derives `mode`** — use `LayoutBuilder` + `NavSidebarBreakpoints`.
2. **Role is positional** — depth determines visual treatment, not a field.
3. **`value` vs `id`** — `value` is your screen key; `id` is the nav identity.
4. **Drawer must overlay** — place in `Stack + Positioned.fill`.
5. **Register the theme** — without it the dark preset is used.

## Reference

- **Examples (read first):** `EXAMPLES.md` in this folder.
- Source: `lib/src/` (models · theme · controller · sidebar)
- README: `../../README.md`
- Example app: `../../example/lib/`
