---
name: super-navigation-sidebar
description: >
  How to use the super_navigation_sidebar Flutter package — a themeable,
  responsive app navigation sidebar with expanded / rail / drawer modes, a typed
  NavNode<T> tree, badges with roll-up counts, working shortcut chords
  (NavShortcutBinder), screen codes + keyword search, recent destinations,
  state persistence snapshots, NavigationShell + AppBar integration, built-in
  command-palette search dialog with keyboard navigation, footer sections,
  Fluent selection indicator, back button, localization, accessibility, RTL
  and deep immutability. Use when building or modifying a Flutter app's left-nav.
---

# super_navigation_sidebar · NavigationSidebar

A themeable, responsive **app navigation sidebar**. One data model (titled
**sections** of a **node tree**) renders in three modes the host picks from
the available width: a full **expanded** labelled tree with `│ ├ └`
connectors, an icon-only **rail** whose modules open hover flyouts, and an
off-canvas **drawer** with a scrim. Zero third-party dependencies.

> **Live preview:** open [`docs/preview.html`](../../docs/preview.html) — a
> faithful browser recreation whose controls toggle every feature (modes,
> themes, selection indicator, RTL, search, favorites, footer, back button).

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
```

### Integrated shell (recommended) — `NavigationShell<T>`

`NavigationShell` composes the app bar, the pane and the content in the
Microsoft-NavigationView arrangement, so you stop hand-wiring Row/Column/Stack.
It resolves the mode (fixed or adaptive by width) and drives two builders:

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
);
```

| Property | Type | Notes |
|---|---|---|
| `controller` | `NavigationSidebarController<T>` | **Required.** Shared by bar + pane. |
| `sidebarBuilder` | `NavShellSlotBuilder` | **Required.** Builds the pane for the mode. |
| `body` | `Widget` | **Required.** Page content. |
| `appBarBuilder` | `NavShellSlotBuilder?` | Builds the bar; omit for none. |
| `mode` | `NavSidebarMode?` | Force a mode; `null` = adaptive from width. |
| `breakpoints` | `NavSidebarBreakpoints` | Width thresholds when adaptive. |
| `headerLayout` | `NavShellHeaderLayout` | `spanning` (bar full-width above pane, default) or `inset` (pane full-height, bar above content only). |
| `paneBehavior` | `NavPaneBehavior` | `push` (pane reflows content, default) or `overlay` (rail in-flow, full pane floats over a scrim). |
| `contentPadding` | `EdgeInsetsGeometry?` | Content margins (24 / 12 px default). |

> **Overlay tip:** with `paneBehavior: NavPaneBehavior.overlay`, construct the
> controller with `collapsed: true` so the pane starts closed and opens as a
> flyout over the content.

### Manual responsive shell (no `NavigationShell`)

```dart
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
              icon: Icons.menu_book_outlined, value: 'accounts',
              code: 'COA01',                    // 2.2 — searchable mono chip
              keywords: ['دليل الحسابات', 'gl accounts']), // 2.2 — hidden aliases
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

### `NavSection` — footer placement

```dart
NavSection(
  title: '',
  placement: NavSectionPlacement.footer, // pins items to pane bottom
  items: [
    NavNode(id: 'help',     label: 'Help',     icon: Icons.help_outline,     value: 'help'),
    NavNode(id: 'settings', label: 'Settings', icon: Icons.settings_outlined, value: 'settings'),
  ],
);
```

`NavSectionPlacement.body` (default) flows in the scrollable area; `.footer`
pins to the bottom, above any free-form `footer` slot. Footer items share the
one selection model — they highlight, appear in breadcrumbs, search and
`navigate()` exactly like body nodes.

## Options & slots

```dart
NavigationSidebar<T>(
  controller: nav,                 // or sections + active
  mode: NavSidebarMode.expanded,
  showGuides: true,                // │ ├ └ connectors
  railFlyouts: true,               // module hover flyouts in rail
  showPaneToggle: false,           // top-of-pane menu button (collapse ↔ expand);
                                   // enable when there is no AppBar carrying the toggle
  shortcutMode: NavShortcutMode.onHover, // onHover / always / hidden
  searchable: true,                // built-in inline filter field + match highlight
  allowSearchDialog: true,         // command palette — the single switch for dialog search
  onSearchPick: (node) {},         // optional; navigates + falls back to onNavigate
  favoritable: true,               // per-row star + synthesized Quick Access band
  aggregateBadges: true,           // 2.2 — summed numeric badge chip on closed modules
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

### Shortcut hints — and making them work

A leaf's `shortcut: ['g', 'd']` renders as `G › D` keycaps. `shortcutMode`
controls inline visibility — `onHover` (default), `always`, or `hidden`.
Keycaps are **visual until you add a binder** (2.2). A shortcut can be a
**modifier combo** (`['ctrl', 'shift', 'd']` → Ctrl+Shift+D together) or a
**sequential chord** (`['g', 'd']` → g then d) — the style is chosen per
node from its key list, and the binder handles both:

```dart
// Wrap the shell once — every leaf's shortcut becomes a working keystroke:
NavShortcutBinder<String>(
  controller: nav,
  onNavigate: (n) => openScreen(n.value!), // fires only on applied navigation
  chordTimeout: const Duration(milliseconds: 1200), // pause between chord keys
  enabled: true,                            // suspend during modal wizards etc.
  child: NavigationShell<String>(…),
);
```

Combos match the exact modifier set on the main key's press; sequences match
key-by-key with no modifiers held. Both are suspended automatically while any
text field has focus, refuse locked/disabled nodes, and rebuild when
`replaceSections` hot-swaps the tree.

### ERP / banking extras

```dart
NavigationSidebar<String>(
  controller: nav,
  searchable: true,       // built-in filter field + match highlight
  favoritable: true,      // per-row star + synthesized Quick Access band
  aggregateBadges: true,  // 2.2 — "12" chip on a closed module = sum of descendants
);

// Permission-gated + status-dotted nodes:
NavNode(id: 'wire', label: 'Wire / SWIFT', value: 'wire',
        locked: true, lockMessage: 'Requires Treasury Approver role');
NavNode(id: 'fy25q3', label: 'FY2025 · Q3', value: 'fy25q3',
        status: NavNodeStatus.open); // open/closed/locked/attention

// 2.2 — screen codes + hidden keyword aliases (both searchable):
NavNode(id: 'journalEntry', label: 'Journal Entry', value: 'journalEntry',
        code: 'JE01', keywords: ['قيد', 'voucher', 'GL entry']);

// 2.2 — recents are recorded automatically on navigate();
// the command palette opens with a "Recent" band while the query is empty:
nav.recents;      // MRU ids (max nav.maxRecents, default 8)
nav.recentNodes;  // resolved nodes
nav.clearRecents();

// 2.2 — persist the user-owned state across sessions / workstations:
nav.addListener(() =>
    prefs.setString('nav', jsonEncode(nav.snapshot().toJson())));
nav.restore(NavSidebarStateSnapshot.fromJson(jsonDecode(raw)));
// restore() drops ids missing from the current tree and notifies once.
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

The inline filter field — drives `controller.setQuery` (pair with
`NavigationSidebar.searchable`). It does **not** open the dialog:

```dart
NavigationSidebarSearchField(
  controller: nav,
  hint: 'Search accounts, journals, reports…',
)
```

### Command palette — `allowSearchDialog`

The single switch that enables dialog search. The sidebar renders the trigger
in the pane and opens `NavSearchDialog` end-to-end. Full keyboard support
(2.2): `↑`/`↓` move a highlighted row (wraps), `Enter` opens it, `Escape`
closes. While the query is empty a **"Recent" band** (from
`controller.recents`) leads the list; results match label + `code` +
`keywords` and show the code as a mono chip:

```dart
NavigationSidebar<String>(
  controller: nav,
  allowSearchDialog: true,          // ← the only switch that enables search
  searchHint: 'Search tabs & actions…',
  onSearchPick: (node) { … },       // optional; navigates + falls back to onNavigate
)
```

### Command-palette dialog (standalone primitives)

For custom entry points (a button, a keyboard shortcut):

```dart
// Imperative — no Stack needed:
showNavSearchDialog<String>(context, controller: nav,
    recentsLabel: 'الأخيرة'); // optional — header of the Recent band

// Manual Stack placement:
Stack(children: [
  MyShell(),
  if (_open)
    NavSearchDialog<String>(
      controller: nav,
      onClose: () => setState(() => _open = false),
    ),
])

// Build a custom search UI with the helpers:
final index = NavSearchOps.buildIndex<String>(nav.sections);
final hits  = NavSearchOps.filter(index, query);
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
`drawerTitle` · `drawerCloseLabel` · `quickAccessTitle` · `recentsTitle` ·
`addToQuickAccess` · `removeFromQuickAccess` · `lockedDefault` ·
`shortcutPrefix` · `shortcutSeparator` · `semanticExpanded` ·
`semanticCollapsed` · `semanticLocked` · `semanticDisabled` ·
`semanticToggleSidebar` · `semanticOpenDrawer`.

## `NavigationSidebarController<T>` API

```dart
final nav = NavigationSidebarController<String>(
  sections: sections,
  active: 'dashboard',
  expanded: {'accountsHub'},
  favorites: {'journalEntry'},
  recents: ['trialBalance'],  // 2.2 — seed MRU history
  maxRecents: 8,              // 2.2 — MRU cap
  collapsed: false,        // start railed (use true for overlay panes)
  canGoBack: false,        // bind to router can-pop
  autoExpandActive: true,  // auto-open the active node's ancestors
);

// Navigation (returns bool — true = applied, false = refused):
final ok = nav.navigate('settingsHub'); // sets active, opens ancestors, closes drawer
// Returns false (and fires NO onNavigate) for locked / disabled / missing nodes.

// Expansion:
nav.expand(id); nav.collapse(id); nav.toggleNode(id); nav.expandAll(); nav.collapseAll();

// Rail / drawer:
nav.toggleCollapsed(); nav.collapsed = true;    // expanded ↔ rail
nav.openDrawer(); nav.closeDrawer(); nav.toggleDrawer();

// Back state (bind to your router's can-pop):
nav.canGoBack = router.canPop();

// Search / favorites:
nav.setQuery('journals'); nav.matchSet(); // matches label + code + keywords
nav.toggleFavorite(id); nav.setFavorites({'a', 'b'});

// Recents (2.2 — auto-filled by navigate()):
nav.recents; nav.recentNodes; nav.clearRecents();

// State persistence (2.2):
final snap = nav.snapshot();               // NavSidebarStateSnapshot
prefs.setString('nav', jsonEncode(snap.toJson()));
nav.restore(NavSidebarStateSnapshot.fromJson(jsonDecode(raw)));

// Data:
nav.replaceSections(newSections); // hot-swap after a role change; prunes recents

// Reads: sections · active · activeValue · collapsed · drawerOpen · filtering ·
//        isActive(id) · isExpanded(id) · ownsActive(id) · node(id) ·
//        favorites · favoriteNodes · isFavorite(id) · recents · recentNodes

// Duplicate ID validation (debug builds only):
// The controller asserts no duplicate IDs in the constructor and replaceSections.
// Use NavOps.findDuplicateIds<T>(sections) for a programmatic check.

// From inside page content (published via NavigationSidebarScope<T>):
NavigationSidebarController.of<String>(context)?.navigate('dashboard');
```

### Back button

```dart
// In the controller constructor:
final nav = NavigationSidebarController<String>(
  sections: sections, active: 'dashboard',
  canGoBack: false, // start disabled
);

// Bind to your router:
routerDelegate.addListener(() => nav.canGoBack = router.canPop());

// Wire in the AppBar:
NavigationSidebarAppBar(
  controller: nav,
  mode: mode,
  showBackButton: true,    // enabled automatically while canGoBack == true
  onBack: () => router.pop(),
);
```

### `NavigationSidebarScope<T>`

The sidebar publishes its controller via an `InheritedWidget` so any page
widget in the subtree can navigate without receiving the controller directly:

```dart
// Any descendant:
NavigationSidebarController.of<String>(context)?.navigate('journals');
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

## Fluent selection indicator

```dart
ThemeData(extensions: [
  NavigationSidebarThemeData.dark.copyWith(
    selectionIndicator: NavSelectionIndicator.bar, // leading accent pill over a
                                                   // tinted row (tree AND rail)
    indicatorThickness: 3,  // pill width  (default 3)
    indicatorInset: 9,      // top/bottom inset (default 9)
  ),
]);
// Default is NavSelectionIndicator.fill (active direct row fills with accent).
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

  // ── selection indicator ───────────────────────────────
  selectionIndicator: NavSelectionIndicator.bar,
  indicatorThickness: 3,
  indicatorInset: 9,
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

1. **Prefer `NavigationShell`** for the whole app frame; drop to manual
   Row/Column/Stack only when you need bespoke layout.
2. **Host derives `mode`** — `NavSidebarBreakpoints().modeFor(width)`, or let
   `NavigationShell` do it.
3. **Role is positional** — depth determines visual treatment, not a field.
4. **`value` vs `id`** — `value` is your screen key; `id` is the nav identity.
5. **Drawer must overlay** — `Stack + Positioned.fill` (or use `NavigationShell`).
6. **Register the theme** — without it the dark preset is used.
7. **Shortcuts need a binder** — keycaps are visual until you wrap the shell
   in `NavShortcutBinder` (2.2) or wire `Shortcuts`/`Actions` yourself.
8. **No `const NavNode/NavSection`** — constructors are non-const since 1.2.
9. **`navigate()` returns `bool`** — void call sites compile unchanged.
10. **`NavigationSidebar(allowSearchDialog: true)`** → the single switch for the command palette. `showNavSearchDialog` is the imperative escape hatch.

## Reference

- **Live preview:** `../../docs/preview.html` (interactive, all features).
- **Examples (read first):** `EXAMPLES.md` in this folder.
- Source: `lib/src/` — models · theme · localizations · controller · sidebar · appbar · shell · search_dialog · shortcut_binder.
- README: `../../README.md`
- Example app: `../../example/lib/`
