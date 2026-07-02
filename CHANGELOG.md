# Changelog

All notable changes to `super_navigation_sidebar` will be documented in this file.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.1.0] — 2026-07-02

Built-in command-palette search dialog. **Additive — no breaking changes.**

### Added — `NavigationSidebar.allowSearchDialog`

The command palette is now built into the sidebar and enabled by a single
switch — the recommended (and only) way to turn on dialog search.

- **`allowSearchDialog`** (default `false`) — renders a search trigger inside
  the pane (a field in expanded / drawer modes, an icon button in rail mode)
  that opens `NavSearchDialog` via the root `Overlay` on tap. No `Stack` /
  `Overlay` wiring is required in the host app. Takes precedence over
  `searchable` when both are set.
- **`onSearchPick`** — `ValueChanged<NavNode<T>>` fired after the controller
  navigates to the picked result; falls back to `onNavigate` when null.

### Added — dialog primitives

`allowSearchDialog` builds on these public primitives, also usable directly for
custom entry points (a button, a keyboard shortcut):

- **`NavSearchDialog<T>`** — a full-screen overlay widget (requires a `Stack`
  ancestor) that flattens the controller's section tree into a searchable list,
  groups results by module, and navigates on pick. Constructor:
  `controller`, `onClose`, `onPick`, `hint`.
- **`showNavSearchDialog<T>(context, {controller, onPick, hint})`** — opens
  `NavSearchDialog` via the `Overlay` without a `Stack` parent. Theme and
  `Directionality` are captured from the calling context and re-applied inside
  the overlay.
- **`NavSearchHit`** — public immutable model: `id`, `label`, `icon`,
  `module` (group header), `group` (sub-group), `badge`, `shortcut`.
- **`NavSearchOps`** — static helpers:
  - `buildIndex<T>(sections)` — flattens the section forest to a
    `List<NavSearchHit>` (leaves only; non-navigable modules/groups excluded).
  - `filter(index, query)` — tokenised multi-word filter; returns the full
    index when the query is blank.

### Unchanged — `NavigationSidebarSearchField`

Remains the inline `controller.setQuery` filter field (pair with `searchable`);
it does **not** open the dialog. Use `NavigationSidebar.allowSearchDialog` for
the command palette.

### Example — simplified

`navigation_sidebar_demo.dart` drops its ~250-line private `_SearchDialog`
implementation in favour of:

```dart
NavigationSidebar<String>(
  controller: controller,
  allowSearchDialog: true,
  searchHint: 'Search tabs & actions…',
)
```

---

## [2.0.0] — 2026-07-01

The **AppBar ↔ SideBar integration** release. Aligns the package with
Microsoft's [NavigationView](https://learn.microsoft.com/en-us/windows/apps/design/controls/navigationview)
guidelines: a single integrated shell, a back button in the top-left corner, a
top-of-pane menu button, footer navigation items, and the Fluent selection
indicator. **Additive — no breaking API changes from 1.2.x.**

### Added — `NavigationShell<T>` (integrated app scaffold)

One widget composes the app bar, the navigation pane and the page content in
the correct NavigationView arrangement, so hosts no longer hand-wire
`Row` / `Column` / `Stack` (and get the alignment subtly wrong).

- **`headerLayout`** — `NavShellHeaderLayout.spanning` (default) puts a
  full-width app bar across the top with the pane below it, so the bar's
  leading zone (back button + pane toggle) lines up directly over the pane —
  the WinUI Gallery arrangement. `inset` keeps the pane full-height with the
  bar above the content only.
- **`paneBehavior`** — `NavPaneBehavior.push` (default) reflows content as the
  pane widens (Left mode); `overlay` keeps a rail in-flow and floats the full
  pane over the content with an animated scrim (LeftCompact / LeftMinimal).
- **Adaptive by width** — resolves `expanded` / `rail` / `drawer` from
  `NavSidebarBreakpoints`, or force a fixed `mode`. Content gets NavigationView's
  recommended margins (24 px desktop, 12 px in drawer) via `contentPadding`.
- `appBarBuilder` / `sidebarBuilder` receive the resolved mode; `body` is the
  page. Drawer mode wires the hamburger and off-canvas overlay automatically.

### Added — Back button

- **`NavigationSidebarController.canGoBack`** — bind to your router's can-pop
  state (the analogue of NavigationView's `IsBackEnabled`).
- **`NavigationSidebarAppBar.showBackButton`** + **`onBack`** — renders a back
  button in the leading-most position (top-left corner). It is enabled only
  while `controller.canGoBack` is `true`, mirrors RTL, and calls `onBack` when
  tapped. `NavigationSidebarLocalizations.semanticBack` labels it.

### Added — Footer navigation items

- **`NavSection.placement`** (`NavSectionPlacement.body` | `footer`) — footer
  sections pin to the bottom of the pane (e.g. *Settings*, *Help*) while body
  sections scroll, in both expanded and rail modes. Footer items share the one
  selection model: they highlight when active and take part in breadcrumbs,
  search and `navigate()` exactly like any other node. Mirrors
  NavigationView's `FooterMenuItems`.

### Added — Fluent selection indicator

- **`NavigationSidebarThemeData.selectionIndicator`**
  (`NavSelectionIndicator.fill` | `bar`). `fill` is the original look
  (unchanged default). `bar` draws a vertical accent pill on the leading edge
  of the active leaf over a tinted background — the Fluent NavigationView
  indicator — in the tree **and** on the rail. Tunable via `indicatorThickness`
  (3) and `indicatorInset` (9), both lerp-animated.

### Added — Top-of-pane menu button

- **`NavigationSidebar.showPaneToggle`** — renders a collapse ↔ expand button
  pinned to the top of the pane (the NavigationView "menu button" placement),
  for panes used without an app bar that already carries the toggle (e.g. an
  inset-header shell).

### Added — Misc

- **`NavigationSidebarThemeData.headerHeight`** (52) — fixed content-header band
  height token for shells.
- New enums exported: `NavSectionPlacement`, `NavShellHeaderLayout`,
  `NavPaneBehavior`, `NavSelectionIndicator`, and the `NavShellSlotBuilder`
  typedef.
- Example **06 · Integrated NavigationShell**
  (`example_06_navigation_shell.dart`) — live toggles for header layout, pane
  behavior, selection indicator, a working back-history button and pinned
  footer items.

### Migration

Nothing required. Every addition is opt-in and existing call sites compile
unchanged. To adopt the Fluent look set
`selectionIndicator: NavSelectionIndicator.bar` on your theme extension; to
adopt the integrated layout, wrap your existing `NavigationSidebarAppBar` +
`NavigationSidebar` in a `NavigationShell`.

---

## [1.2.1] — 2026-06-27

### Added — Theme size customisation

All geometry constants that were previously `static const` on
`NavigationSidebarThemeData` are now **instance fields** with the same
defaults, so hosts can tune them via `copyWith` without touching the view layer.
Every size field is also linearly interpolated in `lerp`, enabling smooth
animated theme switches.

New fields (all optional — existing presets are unchanged):

| Field | Default | Controls |
|---|---|---|
| `directHeight` | 42 | Height of a depth-0 leaf row |
| `moduleHeight` | 42 | Height of a depth-0 branch (module) row |
| `groupHeight` | 36 | Height of a depth-≥1 branch (group) header |
| `itemHeight` | 38 | Height of a depth-≥1 leaf (item) row |
| `railButton` | 44 | Rail icon button size (W × H) |
| `railIconSize` | 22 | Icon inside the rail button |
| `widthExpanded` | 248 | Sidebar width in expanded mode |
| `widthRail` | 76 | Sidebar width in rail mode |
| `widthDrawer` | 280 | Sidebar width in drawer mode |
| `iconTop` | 20 | Leading icon for direct / module rows |
| `iconItem` | 16 | Icon inside the boxed item container |
| `itemBox` | 28 | Boxed item container size (W × H) |
| `toolbarButtonSize` | 36 | AppBar icon button size (W × H) |
| `toolbarIconSize` | 20 | Icon inside an AppBar button |
| `radiusSm` | 6 | Small corner radius (keycaps, chips) |
| `radiusMd` | 8 | Medium corner radius (search field, item box) |
| `radiusLg` | 10 | Large corner radius (pills, rail buttons) |
| `radiusXl` | 12 | Extra-large corner radius (flyout panel) |
| `gutter` | 19 | Horizontal indent per nesting level |

`rowHeight(NavNodeRole)`, `contentInset(depth)`, `lineInset(depth)`, and
`elbow` are now **instance methods / getters** (previously static) that
derive from the above fields — no call-site changes needed since the view
already reads them through the theme instance.

### Migration

Remove any direct references to the old static constants
(`NavigationSidebarThemeData.railButton`, `.radiusMd`, etc.) and read
them from the theme instance instead (`t.railButton`, `t.radiusMd`).
The view layer has already been updated.

---


### Added

- **Localization support** (`NavigationSidebarLocalizations`) — every
  user-facing string is now in one immutable data class. Pass a custom instance
  to `NavigationSidebar.localizations`; a ready-made Arabic preset is included
  (`NavigationSidebarLocalizations.arabic`). Strings covered: search field
  placeholder & empty state, drawer title & close label, Quick Access eyebrow &
  star tooltips, locked-node fallback message, shortcut prefix & separator, and
  all accessibility semantic labels.

- **AppBar integration** (`NavigationSidebarAppBar`) — a
  `PreferredSizeWidget` that connects directly to a
  `NavigationSidebarController`. Adapts leading controls to the current mode:
  drawer mode inserts a hamburger that calls `controller.openDrawer`; expanded /
  rail modes show a collapse ↔ expand toggle (`showCollapseToggle`). Content
  slots: `title`, `pageTitle`, `actions`, `globalSearch`, `middle`, custom
  `builder`. Respects RTL, theme, and rebuilds automatically when the controller
  notifies.

- **`NavBreadcrumb<T>`** — a ready-made `Text.rich` widget that reads ancestor
  labels from the controller and renders a `›`-separated crumb trail; designed
  for use in `NavigationSidebarAppBar.pageTitle`.

- **`NavigationSidebarSearchField`** — a compact, themed search field that
  drives `controller.setQuery`; designed for use in
  `NavigationSidebarAppBar.globalSearch`.

- **Deep immutability** — `NavNode.children` and `NavSection.items` are now
  wrapped in `List.unmodifiable()` at construction time. External mutation of
  the list is prevented; all structural changes must go through the controller.

- **Duplicate ID validation** — `NavigationSidebarController` detects duplicate
  `NavNode.id` values in debug builds (`assert`) and fires a clear error message
  listing the offending IDs. `NavOps.findDuplicateIds<T>(sections)` provides a
  programmatic check for use in tests and host-side validation.

- **Accessibility** — every interactive row is wrapped in `Semantics` (button
  role, `selected`, `toggled` expanded/collapsed state, lock/disable hints) and
  a `Focus` with `onKeyEvent` so keyboard users can activate rows with Enter or
  Space. The drawer close button has an accessible label. Rail items carry
  proper Tooltip semantics. Locked and disabled rows expose a `forbidden` mouse
  cursor.

- **`NavOps.findDuplicateIds<T>`** static helper — returns the list of
  duplicate IDs in a section forest; empty list means the tree is valid.

- Example **05 · AppBar integration** (`example_05_appbar_integration.dart`) —
  demonstrates `NavigationSidebarAppBar` with breadcrumb, global search, user
  avatar, notifications, theme toggle, and workspace switcher in both drawer
  and expanded modes.

### Changed

- **Navigation safety** — `NavigationSidebarController.navigate()` now returns
  `bool` (`true` = navigation applied, `false` = refused because the node is
  locked, disabled, or not found). `NavigationSidebar.onNavigate` is only
  fired when `navigate()` returns `true`, so locked/disabled nodes can never
  trigger host navigation in any mode (expanded, rail, drawer, flyout).

- **`NavigationSidebar.drawerTitle`**, **`searchHint`**, **`quickAccessTitle`**
  are now nullable (`String?`). When null they fall back to the corresponding
  field in `localizations`. Explicit string values still take precedence —
  existing code that passes a string literal continues to work unchanged.

- Package `homepage` and `repository` URLs corrected to
  `https://github.com/GeniusSystems24/super_navigation_sidebar`.

- README installation snippet updated to reference `^1.2.0`.

### Breaking changes

- **`NavNode` and `NavSection` constructors are no longer `const`.** The
  `List.unmodifiable()` wrapping requires non-const constructors. Remove the
  `const` keyword from any `const NavNode(…)` or `const NavSection(…)` call
  sites. The `@immutable` annotation is retained.

- **`navigate()` returns `bool`** instead of `void`. Code that calls
  `nav.navigate(id)` without using the return value is unaffected. Code that
  currently wraps the call in a void context (e.g. `onPressed: () =>
  nav.navigate(id)`) continues to compile. Only code that explicitly assigned
  the return value to a `void` variable would need updating.

- **`NavigationSidebarLocalizations`** is a new required-in-spirit parameter.
  It defaults to `const NavigationSidebarLocalizations()` (English) so no
  migration is needed unless you want to localize.

---

## [1.1.0] — 2026-06-22

### Added — ERP / banking capabilities

- **Built-in search & filter** — `NavigationSidebar.searchable` (+ `searchHint`)
  renders a filter field above the tree; matches filter the tree to hits +
  ancestors, auto-expand, and highlight the matched run. `No matches` empty
  state. Drives `controller.setQuery` / `matchSet()`.
- **Quick Access favorites** — `NavigationSidebar.favoritable` (+
  `quickAccessTitle`) adds per-row star toggles and a synthesized favorites
  band at the top. Controller: `favorites` · `favoriteNodes` · `isFavorite` ·
  `toggleFavorite` · `setFavorites`; constructor `favorites:` seed.
- **Permission-gated nodes** — `NavNode.locked` + `NavNode.lockMessage`: dimmed
  row, lock glyph, blocked navigation (`controller.navigate` refuses locked),
  reason tooltip. Segregation-of-duties.
- **Status dots** — `NavNode.status` + `NavNodeStatus` enum (`none` · `open` ·
  `closed` · `locked` · `attention`); `NavigationSidebarThemeData.statusColor`.
- Banking/accounting example app (`example_04_erp_banking.dart`).

---

## [1.0.0] — 2026-06-22

### Added

- **`NavigationSidebar<T>`** widget — responsive sidebar; three modes:
  - `NavSidebarMode.expanded` — 248 px full labelled tree with `│ ├ └`
    connectors, disclosure chevrons, badges and shortcut hints.
  - `NavSidebarMode.rail` — 76 px icon-only column; hovering a module opens
    a grouped flyout overlay. Badge dot on icon when any descendant has a badge.
  - `NavSidebarMode.drawer` — 280 px off-canvas panel with animated scrim.
    Tapping a destination navigates and dismisses.
  - `showGuides` · `railFlyouts` · `drawerTitle` chrome toggles.
  - `shortcutMode` (`onHover` / `always` / `hidden`).
  - `header` / `footer` slot builders.
  - `onNavigate` callback.
- **`NavigationSidebarController<T>`** — ChangeNotifier, single source of truth.
- **`NavSection<T>`** · **`NavNode<T>`** · **`NavBadge`** · **`NavNodeRole`** data model.
- **`NavSidebarBreakpoints`** · **`NavOps`** utilities.
- **`NavigationSidebarThemeData`** — ThemeExtension; `.light` and `.dark` presets.
- **RTL** via `Directionality`.
- **Zero third-party dependencies**.
