# super_navigation_sidebar

[![pub package](https://img.shields.io/badge/pub-v2.0.0-4A7CFF.svg)](https://pub.dev/packages/super_navigation_sidebar)
[![flutter](https://img.shields.io/badge/Flutter-%E2%89%A53.10-1DB88A.svg)](https://flutter.dev)
[![style](https://img.shields.io/badge/style-MVC-F97316.svg)](#architecture)
[![license](https://img.shields.io/badge/license-MIT-64748B.svg)](#license)

A themeable, responsive app navigation sidebar for Flutter. One data model
renders in three modes the host picks from the available width: a full
**expanded** labelled tree with `│ ├ └` connectors, an icon-only **rail** with
hover flyouts, and an off-canvas **drawer** with a scrim. Typed `NavNode<T>`
tree, badges, shortcut hints, header/footer slots, AppBar integration,
localization, accessibility, RTL. Zero third-party dependencies.

---

## Features

- 🗂 **Three layout modes** — `expanded` (full labelled tree + connectors),
  `rail` (icon-only, hover flyouts), `drawer` (off-canvas, scrim) — one
  controller drives all three.
- 📐 **Auto breakpoints** — `NavSidebarBreakpoints().modeFor(width)` maps an
  available width to the right mode: expanded ≥ 1200 px · rail ≥ 768 px ·
  drawer below.
- 🧭 **AppBar integration** — `NavigationSidebarAppBar` connects directly to
  the controller. Drawer mode inserts a hamburger; desktop mode adds a collapse
  toggle. Slots: `title`, `pageTitle`, `globalSearch`, `middle`, `actions`,
  custom `builder`. `NavBreadcrumb<T>` and `NavigationSidebarSearchField` are
  ready-made slot widgets.
- 🧱 **Integrated `NavigationShell`** — one widget composes the app bar, pane
  and content in the Microsoft NavigationView arrangement: full-width spanning
  header or inset, push or overlay pane behavior, adaptive by width, and correct
  content margins — no hand-wired Row/Column/Stack.
- ⬅️ **Back button** — `NavigationSidebarAppBar.showBackButton` + `onBack`,
  enabled from `controller.canGoBack` (à la `IsBackEnabled`), in the top-left
  corner mirroring RTL.
- 📌 **Footer nav items** — `NavSection.placement: NavSectionPlacement.footer`
  pins Settings / Help to the pane bottom, sharing the one selection model
  (NavigationView's `FooterMenuItems`).
- 🎯 **Fluent selection indicator** — `selectionIndicator: NavSelectionIndicator.bar`
  swaps the fill for a leading accent pill in the tree **and** the rail.
- 🌳 **Typed `NavNode<T>` tree** — each node carries a strongly-typed `value`
  (route, screen enum, …); `node.value` reads with no casting.
- 🎭 **Role derived from position** — depth-0 leaf = *direct*; depth-0 branch
  = *module*; nested branch = *group*; nested leaf = *item*.
- ✅ **Active-screen highlight + ancestor auto-expand** — `navigate(id)` sets
  the active row, opens every ancestor module, and (in drawer mode) dismisses
  the drawer.
- 🔴 **Badges** — `NavBadge(text, tone: NavBadgeTone.success/danger/muted)`.
- ⌨ **Shortcut hints** — two-key `['g', 'd']`-style keycaps shown on hover.
  Visual hints only — wiring the keystroke is the host app's responsibility.
- 🔎 **Built-in search & filter** — `searchable: true` adds a filter field that
  matches every level, auto-expands hits, and highlights the matched run.
- ⭐ **Quick Access favorites** — `favoritable: true` adds per-row star toggles
  and a synthesized favorites band pinned at the top.
- 🔒 **Permission-gated nodes** — `NavNode.locked` + `lockMessage` dim a row,
  add a lock glyph, block navigation, and surface the reason as a tooltip.
- 🟢 **Status dots** — `NavNode.status` (`open` · `closed` · `locked` ·
  `attention`) marks fiscal-period / ledger state before the label.
- ♿ **Accessibility** — every interactive row is wrapped in `Semantics`
  (button role, selected, expanded/collapsed state, lock/disable hints) and a
  `Focus` with `onKeyEvent` for keyboard activation (Enter / Space). The drawer
  close button has an accessible label.
- 🌐 **Localization** — `NavigationSidebarLocalizations` puts every user-facing
  string in one immutable class. English default; Arabic preset included.
- 🔐 **Deep immutability** — `NavNode.children` and `NavSection.items` are
  wrapped in `List.unmodifiable()` at construction.
- 🆔 **Duplicate ID validation** — debug-build assertion detects duplicate
  `NavNode.id` values with a clear error message.
- 🛡 **Navigation safety** — `navigate()` returns `bool`; `onNavigate` is only
  fired when navigation is actually applied (locked/disabled nodes are always
  refused).
- 🌍 **RTL** — connectors, flyouts, drawer slide direction, and all row
  padding mirror under `Directionality(textDirection: TextDirection.rtl, …)`.
- 🔌 **Zero dependencies** — pure Flutter + Material.

---

## Installation

```yaml
dependencies:
  super_navigation_sidebar: ^2.0.0
```

```bash
flutter pub get
```

---

## Setup

Register `NavigationSidebarThemeData` on your `MaterialApp`:

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
          NavNode(id: 'accounts_list', label: 'Account List',
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

> **Note (1.2+):** `NavNode` and `NavSection` constructors are no longer `const`
> (children/items are wrapped in `List.unmodifiable`). Remove the `const` keyword
> from any `const NavNode(…)` or `const NavSection(…)` call sites.

### 2 · Responsive shell with AppBar

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
            Positioned.fill(child: PageFor(screen: _screen)),
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
              globalSearch: NavigationSidebarSearchField(controller: _nav),
              actions: [NotificationBell(), UserAvatar()],
            ),
            Expanded(child: PageFor(screen: _screen)),
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

## Integrated shell (`NavigationShell`)

`NavigationShell<T>` composes the app bar, the navigation pane and the page
content in the Microsoft NavigationView arrangement — so you stop hand-wiring
`Row` / `Column` / `Stack` and getting the alignment subtly wrong. The bar's
leading zone (back button + pane toggle) lines up directly over the pane.

```
┌────────────────────────────────────┐
│  App bar  (full width)              │   spanning: back + toggle
├──────────┬────────────────────────┤   sit over the pane
│  Pane    │  Content (padded)        │
└──────────┴────────────────────────┘
```

```dart
NavigationShell<String>(
  controller: _nav,
  headerLayout: NavShellHeaderLayout.spanning, // or .inset
  paneBehavior: NavPaneBehavior.push,          // or .overlay
  appBarBuilder: (ctx, mode) => NavigationSidebarAppBar(
    controller: _nav,
    mode: mode,
    showBackButton: true,
    onBack: _goBack,
    pageTitle: NavBreadcrumb<String>(controller: _nav),
    globalSearch: NavigationSidebarSearchField(controller: _nav),
    actions: [NotificationBell(), UserAvatar()],
  ),
  sidebarBuilder: (ctx, mode) => NavigationSidebar<String>(
    controller: _nav,
    mode: mode,
    onNavigate: (n) => setState(() => _screen = n.value!),
  ),
  body: PageFor(screen: _screen),
)
```

| Property | Type | Description |
|---|---|---|
| `controller` | `NavigationSidebarController<T>` | **Required.** Shared by bar + pane. |
| `sidebarBuilder` | `NavShellSlotBuilder` | **Required.** Builds the pane for the resolved mode. |
| `body` | `Widget` | **Required.** Page content. |
| `appBarBuilder` | `NavShellSlotBuilder?` | Builds the app bar; omit for none. |
| `mode` | `NavSidebarMode?` | Force a mode; `null` = adaptive from width. |
| `breakpoints` | `NavSidebarBreakpoints` | Width thresholds when adaptive. |
| `headerLayout` | `NavShellHeaderLayout` | `spanning` (default) or `inset`. |
| `paneBehavior` | `NavPaneBehavior` | `push` (default) or `overlay`. |
| `contentPadding` | `EdgeInsetsGeometry?` | Content margins (24 / 12 px default). |

> **Overlay tip:** with `paneBehavior: NavPaneBehavior.overlay`, construct the
> controller with `collapsed: true` so the pane starts closed and opens as a
> flyout over the content.

### Back button

```dart
// Bind can-pop to the controller (à la NavigationView IsBackEnabled):
_nav.canGoBack = router.canPop();

NavigationSidebarAppBar(
  controller: _nav, mode: mode,
  showBackButton: true,
  onBack: () => router.pop(),
)
```

### Footer navigation items

```dart
NavSection(
  title: '',
  placement: NavSectionPlacement.footer, // pinned to the pane bottom
  items: [
    NavNode(id: 'help', label: 'Help', icon: Icons.help_outline, value: 'help'),
    NavNode(id: 'settings', label: 'Settings',
            icon: Icons.settings_outlined, value: 'settings'),
  ],
)
```

### Fluent selection indicator

```dart
ThemeData(extensions: [
  NavigationSidebarThemeData.dark.copyWith(
    selectionIndicator: NavSelectionIndicator.bar, // leading accent pill
  ),
]);
```

---

## AppBar integration

### `NavigationSidebarAppBar`

A `PreferredSizeWidget` connected to the controller. Rebuilds automatically
when the controller notifies (drawer open, collapsed flag, etc.).

| Property | Type | Description |
|---|---|---|
| `controller` | `NavigationSidebarController` | **Required.** |
| `mode` | `NavSidebarMode` | **Required.** Determines leading controls. |
| `leading` | `Widget?` | Custom leading. Null → hamburger in drawer mode. |
| `title` | `Widget?` | App / product name. |
| `pageTitle` | `Widget?` | Breadcrumb or screen subtitle. |
| `globalSearch` | `Widget?` | A `NavigationSidebarSearchField` or custom widget. |
| `middle` | `Widget?` | Workspace switcher, env badge, etc. |
| `actions` | `List<Widget>?` | Trailing action buttons. |
| `showCollapseToggle` | `bool?` | Collapse ↔ expand toggle (default true in expanded/rail). |
| `builder` | `Function?` | Full custom content — overrides all slots. |
| `backgroundColor` | `Color?` | Falls back to `NavigationSidebarThemeData.surface`. |
| `showBorder` | `bool` | Bottom hairline border. Default `true`. |
| `height` | `double?` | Bar height. Default `kToolbarHeight` (56 px). |
| `localizations` | `NavigationSidebarLocalizations` | Semantic labels for built-in controls. |

### `NavBreadcrumb<T>`

Reads `controller.active` and renders a `›`-separated ancestor trail:

```dart
NavBreadcrumb<String>(
  controller: nav,
  separator: '  ›  ',       // default
  // style / activeStyle for custom TextStyles
)
```

### `NavigationSidebarSearchField`

A compact themed search field that drives `controller.setQuery`:

```dart
NavigationSidebarSearchField(
  controller: nav,
  hint: 'Search accounts, journals, reports…',
)
```

---

## Localization

All user-facing strings are in `NavigationSidebarLocalizations`. Pass a
custom instance via `NavigationSidebar.localizations` and
`NavigationSidebarAppBar.localizations`:

```dart
// English (default — no configuration needed):
NavigationSidebar<String>(controller: nav, mode: mode)

// Arabic (pair with RTL Directionality):
Directionality(
  textDirection: TextDirection.rtl,
  child: NavigationSidebar<String>(
    controller: nav,
    mode: mode,
    localizations: NavigationSidebarLocalizations.arabic,
  ),
)

// Partial override — only change what you need:
NavigationSidebar<String>(
  controller: nav, mode: mode,
  localizations: const NavigationSidebarLocalizations(
    searchHint: 'Buscar navegación…',
    lockedDefault: 'Acceso restringido',
  ),
)
```

### Available strings

| Field | Default (English) |
|---|---|
| `searchHint` | `'Search navigation…'` |
| `searchEmpty` | `'No matches for "{query}"'` |
| `drawerTitle` | `'Navigation'` |
| `drawerCloseLabel` | `'Close navigation'` |
| `quickAccessTitle` | `'Quick Access'` |
| `addToQuickAccess` | `'Add to Quick Access'` |
| `removeFromQuickAccess` | `'Remove from Quick Access'` |
| `lockedDefault` | `"Locked — you don't have access"` |
| `shortcutPrefix` | `'Shortcut · '` |
| `shortcutSeparator` | `' then '` |
| `semanticExpanded` | `'expanded'` |
| `semanticCollapsed` | `'collapsed'` |
| `semanticLocked` | `'locked'` |
| `semanticDisabled` | `'disabled'` |
| `semanticToggleSidebar` | `'Toggle sidebar'` |
| `semanticOpenDrawer` | `'Open navigation'` |

---

## Data model

### `NavSection<T>`

```dart
NavSection<String>(
  title: 'Finance',
  items: [...],           // List<NavNode<T>> — unmodifiable after construction
)
```

### `NavNode<T>`

| Field | Type | Description |
|---|---|---|
| `id` | `NavNodeId` (String) | **Required.** Unique across the whole sidebar (validated in debug builds). |
| `label` | `String` | **Required.** Display text; search matches against this. |
| `icon` | `IconData?` | Leading icon. |
| `children` | `List<NavNode<T>>` | Child nodes. Unmodifiable after construction. |
| `value` | `T?` | Strongly-typed host payload. |
| `badge` | `NavBadge?` | Trailing badge pill. |
| `shortcut` | `List<String>?` | Visual hint only — `['g', 'd']` renders `G › D`. |
| `locked` | `bool` | Permission-gate: dim, lock glyph, block nav, tooltip. |
| `lockMessage` | `String?` | Tooltip on a locked row. |
| `status` | `NavNodeStatus` | State dot — `none`/`open`/`closed`/`locked`/`attention`. |
| `enabled` | `bool` | When `false`, row shown but not activatable. |

---

## Navigation safety

`navigate()` returns `bool`: `true` = applied, `false` = refused (locked,
disabled, or id not found). `onNavigate` is **only** fired on `true`:

```dart
// Safe — onNavigate is never called for locked / disabled nodes:
NavigationSidebar<String>(
  controller: nav,
  mode: mode,
  onNavigate: (node) => setState(() => _screen = node.value!),
)

// Programmatic nav with return-value check:
final ok = nav.navigate('wire');  // false if locked/disabled
```

---

## Deep immutability

`NavNode.children` and `NavSection.items` are `List.unmodifiable` after
construction. Attempts to mutate throw `UnsupportedError`:

```dart
final node = NavNode(id: 'parent', label: 'Parent', children: [
  NavNode(id: 'child', label: 'Child'),
]);
node.children.add(NavNode(id: 'x', label: 'X')); // throws UnsupportedError
```

All structural changes must go through the controller (`replaceSections`,
`navigate`, etc.) which notifies listeners correctly.

---

## Duplicate ID validation

In debug builds the controller asserts that every `NavNode.id` is unique:

```dart
NavigationSidebarController<String>(sections: myBadSections);
// → AssertionError: duplicate NavNode IDs detected: [myId]
```

Programmatic check (for tests or host validation):

```dart
final dups = NavOps.findDuplicateIds<String>(sections);
assert(dups.isEmpty, 'Duplicate nav ids: $dups');
```

---

## Accessibility

- Every interactive row: `Semantics` (button role, `selected`, `toggled`
  expanded/collapsed, lock/disable hints) + `Focus` + `onKeyEvent` (Enter/Space).
- Drawer close button: accessible label from `localizations.drawerCloseLabel`.
- Locked/disabled rows: `SystemMouseCursors.forbidden` cursor.
- Rail items: `Tooltip` with the node label; lock glyph shown on locked nodes.

---

## ERP / banking features

### Built-in search & filter

```dart
NavigationSidebar<String>(
  controller: nav,
  searchable: true,
  searchHint: 'Search accounts, journals, reports…',
);
```

### Quick Access (favorites)

```dart
NavigationSidebarController<String>(
  sections: sections,
  favorites: {'journalEntry', 'trialBalance'},
);
NavigationSidebar<String>(controller: nav, favoritable: true);
```

### Permission-gated nodes

```dart
NavNode(id: 'wire', label: 'Wire / SWIFT', icon: Icons.bolt_outlined,
        value: 'wire', locked: true,
        lockMessage: 'Requires Treasury Approver role');
```

### Status dots

```dart
NavNode(id: 'fy25q3', label: 'FY2025 · Q3', value: 'fy25q3',
        status: NavNodeStatus.open); // open · closed · locked · attention
```

---

## Three modes

### `expanded` — 248 px full tree

### `rail` — 76 px icon column with hover flyouts

### `drawer` — 280 px off-canvas overlay

```dart
// Place in a Stack + Positioned.fill; open via controller.openDrawer():
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

---

## `NavigationSidebarController<T>` API

### Navigation

| Method | Returns | Description |
|---|---|---|
| `navigate(id)` | `bool` | Set active, open ancestors, close drawer. `false` if refused. |

### Expansion

| Method | Description |
|---|---|
| `expand(id)` · `collapse(id)` · `toggleNode(id)` | Open / close / flip a branch. |
| `expandAll()` · `collapseAll()` | All branches. |

### Rail / drawer

| Method / setter | Description |
|---|---|
| `toggleCollapsed()` · `collapsed = bool` | Flip expanded ↔ rail. |
| `openDrawer()` · `closeDrawer()` · `toggleDrawer()` | Drawer state. |

### Data

| Method | Description |
|---|---|
| `replaceSections(sections)` | Hot-swap the section forest. Validates duplicates in debug. |
| `setQuery(q)` · `matchSet()` | Search filter. |
| `toggleFavorite(id)` · `setFavorites(ids)` | Quick Access. |

### Reads

| Property / method | Description |
|---|---|
| `sections` | `List<NavSection<T>>` |
| `active` / `activeValue` | Active id / typed value. |
| `collapsed` / `drawerOpen` / `filtering` | State flags. |
| `isActive(id)` / `isExpanded(id)` / `ownsActive(id)` | Per-node queries. |
| `node(id)` | `NavNode<T>?` by id. |
| `matchSet()` | Matching ids + ancestors for the current query. |
| `favorites` / `favoriteNodes` / `isFavorite(id)` | Quick Access. |

---

## Theming

```dart
ThemeData(
  extensions: [
    NavigationSidebarThemeData.light.copyWith(
      surface: const Color(0xFFFFFFFF),
      bg:      const Color(0xFFF5F3EF),
      border:  const Color(0xFFDDD7CE),
    ),
  ],
)
```

---

## Architecture

```
lib/
├── super_navigation_sidebar.dart   public barrel
└── src/
    ├── models.dart          NavSection · NavNode · NavBadge · NavBadgeTone
    │                        NavNodeRole · NavNodeId · NavNodeStatus
    │                        NavSidebarMode · NavSidebarBreakpoints · NavOps
    ├── theme.dart           NavigationSidebarThemeData (ThemeExtension)
    ├── localizations.dart   NavigationSidebarLocalizations
    ├── controller.dart      NavigationSidebarController (ChangeNotifier)
    │                        NavigationSidebarScope (InheritedNotifier)
    ├── sidebar.dart         NavigationSidebar<T> widget
    │                        _NavRow · _RailItem · _RailFlyout · _FlyoutRow
    │                        _NavBadgeChip · _ShortcutHint · _StarButton
    ├── appbar.dart          NavigationSidebarAppBar · NavBreadcrumb<T>
    │                        NavigationSidebarSearchField
    └── shell.dart           NavigationShell<T> · NavShellSlotBuilder
```

**MVC:** immutable `NavNode<T>` models → `NavigationSidebarController<T>`
(ChangeNotifier) → thin `NavigationSidebar<T>` view →
`NavigationSidebarThemeData` (ThemeExtension). The controller is published to
descendant pages via `NavigationSidebarScope<T>` (InheritedNotifier).

---

## Gotchas

1. **Host derives `mode`.** Use `LayoutBuilder` + `NavSidebarBreakpoints().modeFor(width)`.
2. **Role is positional.** Depth determines visual treatment, not an explicit field.
3. **`value` vs `id`.** `value` is the typed host payload; `id` is the nav identity.
4. **Drawer must overlay.** Place in `Stack + Positioned.fill`.
5. **Register the theme extension.** Without it the dark preset is used.
6. **Shortcuts are visual hints only.** Wire the actual keystroke yourself via `Shortcuts`/`Actions`.
7. **No `const NavNode/NavSection` (1.2+).** Constructors are non-const; remove the `const` keyword.
8. **`navigate()` returns `bool`.** Code calling it in a void context compiles unchanged; only explicit `void` variable assignment needs updating.

---

## Additional information

- **Changelog:** [CHANGELOG.md](CHANGELOG.md)
- **Repository:** https://github.com/GeniusSystems24/super_navigation_sidebar
- **Issues:** https://github.com/GeniusSystems24/super_navigation_sidebar/issues
- **License:** MIT — see [LICENSE](LICENSE)
