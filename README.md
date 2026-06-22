# super_navigation_sidebar

[![pub package](https://img.shields.io/badge/pub-v1.1.0-4A7CFF.svg)](https://pub.dev/packages/super_navigation_sidebar)
[![flutter](https://img.shields.io/badge/Flutter-%E2%89%A53.10-1DB88A.svg)](https://flutter.dev)
[![style](https://img.shields.io/badge/style-MVC-F97316.svg)](#architecture)
[![license](https://img.shields.io/badge/license-MIT-64748B.svg)](#license)

A themeable, responsive app navigation sidebar for Flutter. One data model
renders in three modes the host picks from the available width: a full
**expanded** labelled tree with `│ ├ └` connectors, an icon-only **rail** with
hover flyouts, and an off-canvas **drawer** with a scrim. Typed `NavNode<T>`
tree, badges, shortcut hints, header/footer slots, RTL. Zero third-party
dependencies.

<!-- TODO: add demo GIF -->

---

## Features

- 🗂 **Three layout modes** — `expanded` (full labelled tree + connectors),
  `rail` (icon-only, hover flyouts), `drawer` (off-canvas, scrim) — one
  controller drives all three.
- 📐 **Auto breakpoints** — `NavSidebarBreakpoints().modeFor(width)` maps an
  available width to the right mode: expanded ≥ 1200 px · rail ≥ 768 px ·
  drawer below.
- 🌳 **Typed `NavNode<T>` tree** — each node carries a strongly-typed `value`
  (route, screen enum, …); `node.value` reads with no casting. `id` is the
  stable nav identity.
- 🎭 **Role derived from position** — depth-0 leaf = *direct* destination;
  depth-0 branch = collapsible *module*; nested branch = *group* header;
  nested leaf = *item* (boxed icon). No explicit role field needed.
- ✅ **Active-screen highlight + ancestor auto-expand** — `navigate(id)` sets
  the active row, opens every ancestor module, and (in drawer mode) dismisses
  the drawer.
- 🔴 **Badges** — `NavBadge(text, tone: NavBadgeTone.success/danger/muted)`;
  renders as a pill on rows, a dot on collapsed modules / rail icons.
- ⌨ **Shortcut hints** — two-key `['g', 'd']`-style keycaps shown on hover by
  default; switch with `shortcutMode` (`onHover` · `always` · `hidden`). Hidden
  hints stay discoverable through the row's tooltip.
- 🔎 **Built-in search & filter** — `searchable: true` adds a filter field that
  matches every level, auto-expands hits, and highlights the matched run.
- ⭐ **Quick Access favorites** — `favoritable: true` adds per-row star toggles
  and a synthesized favorites band pinned at the top.
- 🔒 **Permission-gated nodes** — `NavNode.locked` + `lockMessage` dim a row,
  add a lock glyph, block navigation, and surface the reason as a tooltip —
  built for banking segregation-of-duties.
- 🟢 **Status dots** — `NavNode.status` (`open` · `closed` · `locked` ·
  `attention`) marks fiscal-period / ledger state before the label.
- 🔲 **Header / footer slots** — builder `(ctx, collapsed) → Widget` for logo,
  theme toggle, help card, etc.
- 🔭 **`of(context)` scope** — `NavigationSidebarController.of<T>(context)`
  from any descendant page; both `navigate` and structural ops available.
- 🌍 **RTL** — connectors, flyouts, drawer slide direction, and all row
  padding mirror under `Directionality(textDirection: TextDirection.rtl, …)`.
- 🔌 **Zero dependencies** — pure Flutter + Material.

---

## Installation

```yaml
dependencies:
  super_navigation_sidebar: ^1.0.0
```

```bash
flutter pub get
```

---

## Setup

Register `NavigationSidebarThemeData` on your `MaterialApp`. Falls back to
the dark preset if nothing is registered:

```dart
import 'package:super_navigation_sidebar/super_navigation_sidebar.dart';

MaterialApp(
  theme: ThemeData(
    extensions: const [NavigationSidebarThemeData.light],
  ),
  darkTheme: ThemeData(
    extensions: const [NavigationSidebarThemeData.dark],
  ),
  home: const MyApp(),
);
```

---

## Quick start

### 1 · Self-contained (no external controller)

```dart
NavigationSidebar<String>(
  sections: [
    NavSection(title: 'Overview', items: [
      NavNode(id: 'dashboard', label: 'Dashboard',
              icon: Icons.dashboard_outlined, value: 'dashboard',
              shortcut: ['g', 'd']),
    ]),
    NavSection(title: 'Finance', items: [
      NavNode(id: 'accounts', label: 'Accounts',
              icon: Icons.menu_book_outlined, children: [
        NavNode(id: 'coa', label: 'Chart of Accounts', children: [
          NavNode(id: 'accounts_list', label: 'Chart of Accounts',
                  icon: Icons.menu_book_outlined, value: 'accounts_list'),
        ]),
      ]),
    ]),
  ],
  active: 'dashboard',
  mode: NavSidebarMode.expanded,
  onNavigate: (node) => openScreen(node.value!),
);
```

### 2 · Responsive shell (LayoutBuilder + breakpoints)

```dart
class _AppShellState extends State<AppShell> {
  final _nav = NavigationSidebarController<String>(
    sections: mySections,
    active: 'dashboard',
  );
  String _screen = 'dashboard';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final mode = const NavSidebarBreakpoints().modeFor(c.maxWidth);

      final sidebar = NavigationSidebar<String>(
        controller: _nav,
        mode: mode,
        header: (ctx, collapsed) => MyLogo(collapsed: collapsed),
        footer: (ctx, collapsed) => HelpCard(collapsed: collapsed),
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
            Positioned.fill(child: PageFor(screen: _screen)),
            Positioned.fill(child: sidebar),
          ]),
        );
      }

      return Row(children: [
        sidebar,
        Expanded(child: PageFor(screen: _screen)),
      ]);
    });
  }

  @override
  void dispose() { _nav.dispose(); super.dispose(); }
}
```

---

## Data model

### `NavSection<T>`

```dart
NavSection<String>(
  title: 'Finance',       // uppercase eyebrow above the section
  items: [...],           // List<NavNode<T>> — top-level nodes
)
```

### `NavNode<T>`

| Field | Type | Description |
|---|---|---|
| `id` | `NavNodeId` (String) | **Required.** Stable, unique identity across the whole sidebar. |
| `label` | `String` | **Required.** Display text; search matches against this. |
| `icon` | `IconData?` | Leading icon. Required in spirit for modules and items. |
| `children` | `List<NavNode<T>>` | Child nodes. Empty = leaf. |
| `value` | `T?` | Strongly-typed host payload (`node.value` — no casting). |
| `badge` | `NavBadge?` | Trailing badge pill. |
| `shortcut` | `List<String>?` | Two-key hint shown on hover, e.g. `['g', 'd']`. |
| `locked` | `bool` | Permission-gate: dim, lock glyph, block navigation, tooltip. Default `false`. |
| `lockMessage` | `String?` | Tooltip shown on a locked row, e.g. `'Requires Approver role'`. |
| `status` | `NavNodeStatus` | State dot before the label — `none`/`open`/`closed`/`locked`/`attention`. |
| `enabled` | `bool` | When `false`, row is shown but not activatable. Default `true`. |

### Role derivation

Role is **positional** — no explicit field needed:

| Position | Role | Visual |
|---|---|---|
| Depth-0 leaf | `direct` | Accent-filled pill when active. |
| Depth-0 branch | `module` | Icon + label + chevron; accent-tinted when it owns the active screen. |
| Depth-≥1 branch | `group` | Uppercase bullet header. |
| Depth-≥1 leaf | `item` | Boxed icon + label. |

### `NavBadge`

```dart
NavBadge('3')                                  // default accent tone
NavBadge('Live',  tone: NavBadgeTone.success)  // green
NavBadge('9+',    tone: NavBadgeTone.danger)   // red
NavBadge('12',    tone: NavBadgeTone.muted)    // grey
```

Renders as a pill on expanded rows; collapses to a dot on collapsed modules
and rail icons.

### Shortcut hints

Give a leaf a two-key chord and it renders as keycaps (`G › D`) on the row:

```dart
NavNode(id: 'dashboard', label: 'Dashboard', icon: Icons.dashboard_outlined,
        value: 'dashboard', shortcut: ['g', 'd']);
```

Control visibility per sidebar with `shortcutMode`:

```dart
NavigationSidebar<String>(
  controller: nav,
  shortcutMode: NavShortcutMode.onHover, // default — reveal on row hover
  // NavShortcutMode.always  → keycaps always visible
  // NavShortcutMode.hidden  → no inline keycaps
);
```

In **every** mode the chord stays discoverable: hovering the row shows a
`Shortcut · G then D` tooltip (suppressed only in `always`, where the keycaps
are already on screen). On an active direct row the keycaps switch to a
light-on-accent treatment automatically.

---

## ERP / banking features

Purpose-built for deep finance & accounting navigation.

### Built-in search & filter

```dart
NavigationSidebar<String>(
  controller: nav,
  searchable: true,
  searchHint: 'Search accounts, journals, reports…',
);
```

A filter field appears above the tree. Typing drives the controller's query;
the tree collapses to matching nodes (plus their ancestors so they stay
reachable), auto-expands them, and highlights the matched run in accent. A
`No matches` state shows when nothing matches. Drive it yourself with
`controller.setQuery(q)` / `controller.matchSet()` if you supply your own field.

### Quick Access (favorites)

```dart
NavigationSidebarController<String>(
  sections: sections,
  favorites: {'journalEntry', 'trialBalance'}, // pre-pinned
);

NavigationSidebar<String>(controller: nav, favoritable: true);
```

Hovering any destination reveals a star; tapping it calls
`controller.toggleFavorite(id)`. Favorited destinations are listed in a
synthesized **Quick Access** band at the very top. Controller API:
`favorites` · `favoriteNodes` · `isFavorite(id)` · `toggleFavorite(id)` ·
`setFavorites(ids)`. Persist by listening to the controller and storing the id
set.

### Permission-gated nodes

```dart
NavNode(id: 'wire', label: 'Wire / SWIFT', icon: Icons.bolt_outlined,
        value: 'wire', locked: true,
        lockMessage: 'Requires Treasury Approver role');
```

A locked row is dimmed, shows a lock glyph, can't be activated (and
`controller.navigate` refuses it), and reveals its `lockMessage` on hover —
the standard segregation-of-duties pattern.

### Status dots

```dart
NavNode(id: 'fy25q3', label: 'FY2025 · Q3', value: 'fy25q3',
        status: NavNodeStatus.open);     // open · closed · locked · attention
```

A small colored dot before the label reflects fiscal-period or ledger state:
`open` (green) · `closed` (grey) · `locked` (red) · `attention` (amber).

---

## Three modes

### `expanded` — full tree

```dart
NavigationSidebar<String>(controller: nav, mode: NavSidebarMode.expanded);
```

Width: 248 px. Full labelled tree with `│ ├ └` connectors (toggle with
`showGuides`), disclosure chevrons, badges and shortcut hints.

### `rail` — icon column

```dart
NavigationSidebar<String>(controller: nav, mode: NavSidebarMode.rail);
```

Width: 76 px. Icon-only column; hovering a module opens a grouped flyout
(toggle with `railFlyouts`). Badge dot on the icon when any descendant has
a badge.

### `drawer` — off-canvas overlay

```dart
// Place in a Stack + Positioned.fill; open via nav.openDrawer():
Stack(children: [
  Positioned.fill(child: MyPage()),
  Positioned.fill(
    child: NavigationSidebar<String>(
      controller: nav,
      mode: NavSidebarMode.drawer,
    ),
  ),
])
```

Width: 280 px. Slides in from the start edge with an animated scrim.
Tapping a destination navigates **and** dismisses the drawer automatically.

---

## Options & slots

| Property | Type | Default | Description |
|---|---|---|---|
| `controller` | `NavigationSidebarController<T>?` | — | External controller. Provide `sections` OR `controller`. |
| `sections` | `List<NavSection<T>>?` | — | Seed when the widget owns the controller. |
| `active` | `NavNodeId?` | — | Initial active id (ignored when `controller` is supplied). |
| `mode` | `NavSidebarMode` | `expanded` | Layout mode. |
| `showGuides` | `bool` | `true` | `│ ├ └` connector lines. |
| `railFlyouts` | `bool` | `true` | Module hover flyouts in rail mode. |
| `shortcutMode` | `NavShortcutMode` | `onHover` | Keycap hint visibility — `onHover` / `always` / `hidden`. Always available as a row tooltip. |
| `searchable` | `bool` | `false` | Built-in filter field above the tree. |
| `searchHint` | `String` | `'Search navigation…'` | Placeholder for the search field. |
| `favoritable` | `bool` | `false` | Per-row star toggles + synthesized Quick Access band. |
| `quickAccessTitle` | `String` | `'Quick Access'` | Eyebrow for the favorites band. |
| `drawerTitle` | `String` | `'Navigation'` | Label above the drawer close button. |
| `header` | `NavSidebarSlotBuilder?` | `null` | `(ctx, collapsed) → Widget`. |
| `footer` | `NavSidebarSlotBuilder?` | `null` | `(ctx, collapsed) → Widget`. |
| `onNavigate` | `ValueChanged<NavNode<T>>?` | `null` | Called alongside `controller.navigate`. |

---

## `NavigationSidebarController<T>` API

```dart
final nav = NavigationSidebarController<String>(
  sections: sections,
  active: 'dashboard',
);
```

### Navigation

| Method | Description |
|---|---|
| `navigate(id)` | Set active, auto-open ancestors, close the drawer. |

### Expansion

| Method | Description |
|---|---|
| `expand(id)` | Open a module. |
| `collapse(id)` | Close a module. |
| `toggleNode(id)` | Flip open/closed. |
| `expandAll()` | Open every branch. |
| `collapseAll()` | Close every branch. |

### Rail / drawer

| Method / setter | Description |
|---|---|
| `toggleCollapsed()` | Flip expanded ↔ rail. |
| `collapsed = bool` | Set directly. |
| `openDrawer()` · `closeDrawer()` · `toggleDrawer()` | Drawer state. |

### Data

| Method | Description |
|---|---|
| `replaceSections(sections)` | Hot-swap the entire section forest (e.g. after a role change). |
| `setQuery(q)` | Set the search filter (drives `matchSet()`). |
| `toggleFavorite(id)` · `setFavorites(ids)` | Manage the Quick Access set. |

### Reads

| Property / Method | Description |
|---|---|
| `sections` | `List<NavSection<T>>` |
| `active` | `NavNodeId?` |
| `activeValue` | `T?` — the typed value behind the active node. |
| `collapsed` | `bool` |
| `drawerOpen` | `bool` |
| `isActive(id)` | `bool` |
| `isExpanded(id)` | `bool` |
| `ownsActive(id)` | `bool` — `id` is an ancestor of the active node. |
| `node(id)` | `NavNode<T>?` |
| `matchSet()` | `Set<NavNodeId>` — matching ids + ancestors for the current query. |
| `favorites` · `favoriteNodes` | The Quick Access id set / nodes (tree order). |
| `isFavorite(id)` | `bool` |

### `of(context)` scope

```dart
// Listening — rebuilds on change. Use in build():
NavigationSidebarController.of<String>(context)?.navigate('dashboard');
```

Returns `null` when called outside a `NavigationSidebar`. The scope is
`NavigationSidebarScope<T>` — an `InheritedNotifier`.

### `NavOps` utilities

```dart
NavOps.ancestorsOf<String>(sections, 'accounts_list'); // ['accounts', 'coa']
NavOps.find<String>(sections, 'accounts_list');         // NavNode<String>?
NavOps.subtreeHasBadge(node);                           // bool
NavOps.leafIds(node);                                   // List<NavNodeId>
```

---

## Theming

```dart
ThemeData(
  extensions: [
    NavigationSidebarThemeData.light.copyWith(
      surface: const Color(0xFFFFFFFF),
      bg:      const Color(0xFFF5F3EF),   // warm off-white
      border:  const Color(0xFFDDD7CE),
    ),
  ],
)
```

### Instance fields (lerped between dark & light)

| Field | Description |
|---|---|
| `bg` | Page backdrop the sidebar floats over. |
| `surface` | Sidebar panel fill. |
| `inputBg` | Boxed-icon fill / chip backgrounds. |
| `hover` | Row hover tint. |
| `border` | Hairline dividers. |
| `borderStrong` | Outer frame / flyout edge. |
| `guide` | `│ ├ └` connector line colour. |
| `fg1` – `fg4` | Text ramp — active → disabled. |

### Brand constants

| Constant | Value | Usage |
|---|---|---|
| `accent` | `#4A7CFF` | Active row, module tint, boxed icon border. |
| `success` | `#1DB88A` | Badge success tone. |
| `warning` | `#F97316` | Badge warning tone. |
| `danger` | `#EF4444` | Badge danger tone. |

---

## RTL

```dart
Directionality(
  textDirection: TextDirection.rtl,
  child: NavigationSidebar<String>(controller: nav, mode: mode),
)
```

What mirrors: connector lines draw on the correct side, boxed icons align
to the end edge, the drawer slides in from the start edge (right in RTL),
flyouts open to the left of the rail, and all row padding uses
`EdgeInsetsDirectional`.

---

## Architecture

```
lib/
├── super_navigation_sidebar.dart   public barrel
└── src/
    ├── models.dart     NavSection · NavNode · NavBadge · NavBadgeTone
    │                   NavNodeRole · NavNodeId · NavSidebarMode
    │                   NavSidebarBreakpoints · NavOps
    ├── theme.dart      NavigationSidebarThemeData (ThemeExtension)
    ├── controller.dart NavigationSidebarController (ChangeNotifier)
    │                   NavigationSidebarScope (InheritedNotifier)
    └── sidebar.dart    NavigationSidebar<T> widget
                        _NavRow · _RailItem · _RailFlyout
                        _NavBadgeChip · _ShortcutHint
```

**MVC:** immutable `NavNode<T>` models → `NavigationSidebarController<T>`
(ChangeNotifier, single source of truth) → thin `NavigationSidebar<T>` view →
`NavigationSidebarThemeData` (ThemeExtension). The controller is exposed to
descendant pages via `NavigationSidebarScope<T>` (InheritedNotifier).

---

## Gotchas

1. **The host derives `mode`.** The widget doesn't auto-detect width — use
   `LayoutBuilder` + `NavSidebarBreakpoints().modeFor(width)`.
2. **Role is positional.** Nest nodes at the correct depth to get the intended
   visual treatment. A depth-0 branch is always a module; a depth-1 branch is
   always a group header.
3. **`value` vs `id`.** `value` is the strongly-typed host payload you switch
   screens on. `id` is the stable nav identity used by expansion, active state
   and `navigate()`. They can differ.
4. **Drawer must overlay.** Place `NavigationSidebar` with `mode: drawer` in a
   `Stack` + `Positioned.fill` so it can cover the content with a scrim.
   A destination tap navigates and dismisses automatically.
5. **Register the theme extension.** Without it the widget uses the dark
   preset regardless of the app theme.

---

## Additional information

- **Changelog:** [CHANGELOG.md](CHANGELOG.md)
- **Repository:** https://github.com/geniuslink/super_navigation_sidebar
- **Issues:** https://github.com/geniuslink/super_navigation_sidebar/issues
- **License:** MIT — see [LICENSE](LICENSE)
