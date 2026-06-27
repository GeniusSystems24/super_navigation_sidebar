---
name: super-navigation-sidebar
description: >
  How to use the super_navigation_sidebar Flutter package — a themeable,
  responsive app navigation sidebar with expanded / rail / drawer modes, typed
  NavNode<T> tree, badges, shortcuts, AppBar integration, localization,
  accessibility, deep immutability. Use when building or modifying a Flutter
  app's left-nav.
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
    return Scaffold(
      appBar: NavigationSidebarAppBar(
        controller: nav,
        mode: NavSidebarMode.drawer,
        pageTitle: NavBreadcrumb<String>(controller: nav),
      ),
      body: Stack(children: [
        Positioned.fill(child: page),
        Positioned.fill(
          child: NavigationSidebar<String>(controller: nav, mode: NavSidebarMode.drawer),
        ),
      ]),
    );
  }
  return Row(children: [
    NavigationSidebar<String>(controller: nav, mode: mode),
    Expanded(
      child: Column(children: [
        NavigationSidebarAppBar(
          controller: nav,
          mode: mode,
          pageTitle: NavBreadcrumb<String>(controller: nav),
          globalSearch: NavigationSidebarSearchField(controller: nav),
          actions: [UserAvatar(), NotificationBell()],
        ),
        Expanded(child: page),
      ]),
    ),
  ]);
});
```

## Data model

```dart
// NOTE: NavNode and NavSection constructors are non-const (children and items
// are wrapped in List.unmodifiable at construction). Remove `const` keywords.
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
  drawerTitle: 'Navigation',       // overrides localizations.drawerTitle
  searchHint: 'Search…',          // overrides localizations.searchHint
  quickAccessTitle: 'Quick Access',
  localizations: const NavigationSidebarLocalizations(), // English default
  header: (ctx, collapsed) => MyLogo(collapsed: collapsed),
  footer: (ctx, collapsed) => HelpCard(collapsed: collapsed),
  onNavigate: (node) {},           // only fires when navigation succeeds
);
```

### onNavigate safety
`onNavigate` is only called when `controller.navigate()` returns true.
Locked (`NavNode.locked`) and disabled (`NavNode.enabled = false`) nodes
**never** trigger `onNavigate` in any mode (expanded, rail, drawer, flyout).

### Shortcut hints

A leaf's `shortcut: ['g', 'd']` renders as `G › D` keycaps. `shortcutMode`
controls inline visibility — `onHover` (default), `always`, or `hidden`.
**Shortcuts are visual hints only** — wiring the actual keystroke (via
`Shortcuts`/`Actions` or a key handler) is the host app's responsibility.

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
```

## NavigationSidebarAppBar

Connected app bar. Adapts its leading controls to the current mode:

```dart
// Drawer mode — shows hamburger that calls controller.openDrawer():
Scaffold(
  appBar: NavigationSidebarAppBar(
    controller: nav,
    mode: NavSidebarMode.drawer,
    pageTitle: NavBreadcrumb<String>(controller: nav),
    actions: [NotificationBell(), UserAvatar()],
  ),
  ...
)

// Desktop mode — shows collapse toggle, global search, actions:
NavigationSidebarAppBar(
  controller: nav,
  mode: NavSidebarMode.expanded,
  showCollapseToggle: true,           // flip rail ↔ expanded
  pageTitle: NavBreadcrumb<String>(controller: nav),
  globalSearch: NavigationSidebarSearchField(controller: nav, hint: 'Search…'),
  middle: WorkspaceSwitcher(),
  actions: [NotificationBell(), UserAvatar()],
)
```

### NavBreadcrumb<T>

Reads the ancestor path from the controller and renders `A › B › Active`:

```dart
NavBreadcrumb<String>(
  controller: nav,
  separator: '  ›  ',   // default
)
```

### NavigationSidebarSearchField

A compact field that drives `controller.setQuery`:

```dart
NavigationSidebarSearchField(
  controller: nav,
  hint: 'Search accounts, journals, reports…',
)
```

## Localization

```dart
// English (default — no configuration needed):
NavigationSidebar<String>(controller: nav, mode: mode)

// Arabic preset (pair with RTL Directionality):
NavigationSidebar<String>(
  controller: nav, mode: mode,
  localizations: NavigationSidebarLocalizations.arabic,
)

// Custom — only override what you need:
NavigationSidebar<String>(
  controller: nav, mode: mode,
  localizations: const NavigationSidebarLocalizations(
    searchHint: 'Buscar navegación…',
    quickAccessTitle: 'Acceso Rápido',
    lockedDefault: 'Acceso restringido',
  ),
)
```

Strings available: `searchHint` · `searchEmpty` (use `{query}` placeholder) ·
`drawerTitle` · `drawerCloseLabel` · `quickAccessTitle` ·
`addToQuickAccess` · `removeFromQuickAccess` · `lockedDefault` ·
`shortcutPrefix` · `shortcutSeparator` · `semanticExpanded` ·
`semanticCollapsed` · `semanticLocked` · `semanticDisabled` ·
`semanticToggleSidebar` · `semanticOpenDrawer`.

## `NavigationSidebarController<T>` API

```dart
final nav = NavigationSidebarController<String>(
  sections: sections, active: 'dashboard',
);

// Navigation (returns bool — true = applied, false = refused):
final ok = nav.navigate('settingsHub');  // sets active, opens ancestors, closes drawer
// Returns false (and fires NO onNavigate) for locked / disabled / missing nodes.

// Expansion:
nav.toggleNode(id); nav.expandAll(); nav.collapseAll();

// Rail / drawer:
nav.toggleCollapsed();  // expanded ↔ rail
nav.openDrawer();       // mobile

// Duplicate ID validation (debug builds only):
// The controller asserts no duplicate IDs in the constructor and replaceSections.
// Use NavOps.findDuplicateIds<T>(sections) for a programmatic check.

// Data:
nav.replaceSections(newSections); // hot-swap after a role change

// From inside page content:
NavigationSidebarController.of<String>(context)?.navigate('dashboard');
```

## Deep immutability

`NavNode.children` and `NavSection.items` are wrapped in `List.unmodifiable`
at construction. External mutation of the list throws `UnsupportedError`. All
structural changes must go through the controller.

**Breaking change from 1.1:** Remove `const` from `const NavNode(…)` and
`const NavSection(…)` call sites.

## Duplicate ID validation

In debug builds the controller asserts that all `NavNode.id` values are unique.
A duplicate triggers a clear assertion failure listing the offending IDs.

```dart
// Programmatic check (for tests / host validation):
final dups = NavOps.findDuplicateIds<String>(sections);
assert(dups.isEmpty, 'Duplicate nav ids: $dups');
```

## Badges

```dart
NavBadge('3')                                 // accent (default)
NavBadge('Live', tone: NavBadgeTone.success)  // green pill / dot
NavBadge('9+',   tone: NavBadgeTone.danger)   // red
NavBadge('12',   tone: NavBadgeTone.muted)    // grey
```

## Theming

```dart
NavigationSidebarThemeData.light.copyWith(
  // ── colors ────────────────────────────────────────────
  bg:      const Color(0xFFF5F3EF),
  surface: const Color(0xFFFFFFFF),
  border:  const Color(0xFFDDD7CE),

  // ── row heights ───────────────────────────────────────
  directHeight: 46,   // depth-0 leaf row     (default 42)
  moduleHeight: 46,   // depth-0 module row   (default 42)
  groupHeight:  38,   // group header row      (default 36)
  itemHeight:   40,   // depth-≥1 item row    (default 38)

  // ── rail ─────────────────────────────────────────────
  railButton:   48,   // rail button size W×H (default 44)
  railIconSize: 24,   // icon inside rail btn (default 22)
  widthRail:    80,   // rail sidebar width   (default 76)
  widthExpanded: 260, // expanded width       (default 248)
  widthDrawer:  300,  // drawer width         (default 280)

  // ── tree icons & boxed item ───────────────────────────
  iconTop:  22,       // direct/module icon   (default 20)
  iconItem: 17,       // item icon            (default 16)
  itemBox:  30,       // item box W×H         (default 28)

  // ── app bar buttons ───────────────────────────────────
  toolbarButtonSize: 38, // AppBar btn W×H    (default 36)
  toolbarIconSize:   20, // icon inside btn   (default 20)

  // ── corner radii ──────────────────────────────────────
  radiusSm: 4,   // keycaps, chips             (default 6)
  radiusMd: 8,   // search field, item box     (default 8)
  radiusLg: 12,  // pills, rail buttons        (default 10)
  radiusXl: 14,  // flyout panel               (default 12)

  // ── indent ────────────────────────────────────────────
  gutter: 22,    // indent per nesting level   (default 19)
)
```

Brand constants: `accent #4A7CFF` · `success #1DB88A` · `warning #F97316` ·
`danger #EF4444`.

## RTL

```dart
Directionality(textDirection: TextDirection.rtl, child: NavigationSidebar(...))
// Pair with NavigationSidebarLocalizations.arabic for translated strings.
```

## Gotchas

1. **Host derives `mode`** — use `LayoutBuilder` + `NavSidebarBreakpoints`.
2. **Role is positional** — depth determines visual treatment, not a field.
3. **`value` vs `id`** — `value` is your screen key; `id` is the nav identity.
4. **Drawer must overlay** — place in `Stack + Positioned.fill`.
5. **Register the theme** — without it the dark preset is used.
6. **Shortcuts are visual hints only** — wire keystrokes yourself via `Shortcuts`/`Actions`.
7. **No `const NavNode/NavSection`** — constructors are non-const since 1.2.

## Reference

- **Examples (read first):** `EXAMPLES.md` in this folder.
- Source: `lib/src/` (models · theme · localizations · controller · sidebar · appbar)
- README: `../../README.md`
- Example app: `../../example/lib/`
