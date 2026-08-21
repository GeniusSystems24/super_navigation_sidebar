# 3.0.0

## Breaking architecture cleanup

- Removed the package-owned integrated application chrome: the 2.x integrated shell, sidebar-specific app-bar layer, breadcrumb helper, and app-bar search-field helper. Host applications now own `Scaffold`, app bars, routing, back navigation, and responsive page composition.
- Removed the package shortcut execution/hint stack and shortcut metadata from navigation nodes. Applications that need shortcuts should register them at the host/application-command layer.
- Removed shell/app-bar-only model, controller, localization, and theme state.
- Removed the legacy overlay-only navigation search dialog API.

## Navigation search

- Added `NavigationSearchView<T>` as a reusable, presentation-independent navigation search surface.
- Added `NavigationSearchViewMode.dialog` and `NavigationSearchViewMode.sheet`.
- Added `showNavigationSearchView<T>(...)` for modal presentation.
- Replaced `NavigationSidebar.allowSearchDialog` with `allowSearchView`.
- Added `NavigationSidebar.searchViewMode` so the built-in trigger can use dialog on desktop and a bottom sheet on compact layouts.
- Search continues to support labels, screen codes, hidden keywords, grouped results, active-state highlighting, and recent destinations.
- `NavigationSearchView` now uses `SuperTextFormField` / `SuperTextFieldController` from `super_form_field` for the search input and owns the required field localization scope internally.
- Added `super_form_field >=1.10.0 <2.0.0` as a runtime dependency.
- Keyboard ↑/↓ navigation now automatically scrolls the highlighted search result into view, including wrap-around between the first and last results.

## Examples and documentation

- Added a dedicated `NavigationSearchView` example covering embedded, dialog, and sheet usage.
- Reworked examples to use host-owned `Row` / `Stack` / `Scaffold` composition.
- Updated the kitchen sink, README, and all files under `skill/**` for the 3.0 public surface.
- Updated package metadata to `3.0.0`.

---

# Changelog

All notable changes to `super_navigation_sidebar` will be documented in this file.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.4.2] - 2026-08-10

### Changed

- Raised the minimum `super_core` dependency to `>=3.3.0 <4.0.0`.
- Updated the runnable example to satisfy the `super_core` 3.3.0 typography API:
  `SuperMaterialThemeData.light` and `.dark` now receive required
  `SuperTextTheme` values through `textTheme` and `primaryTextTheme`.
- Documented that typography no longer comes from `SuperThemeData`; consumers
  must use `SuperMaterialThemeData.textTheme` / `context.superTextTheme` instead
  of `context.superTheme.textTheme`.
- Added regression coverage for deriving `NavigationSidebarThemeData` from a
  `SuperMaterialThemeData` built with the 3.3.0 API.

---

## [2.4.0] - 2026-07-27

### Changed

- Updated `super_core` dependency constraint from `>=2.1.0 <3.0.0` to `^3.0.0` for compatibility with the breaking 3.0.0 consolidation release.
- `SectionCard`, `SuperSection`, `SuperCard`, and `SectionHeader` were removed from `super_core` in 3.0.0; this package contains no direct usage of those widgets — no widget-level changes required.

---

## [2.3.0] — 2026-07-16

### Added

- Now depends on **super_core** (previously zero third-party dependencies).
- **`NavigationSidebarThemeData.fromMaterialTheme(SuperMaterialThemeData)`** —
  derives the sidebar theme from a `SuperMaterialThemeData`, reading palette-,
  brightness- and device-mode-aware surfaces and control/row sizes from its
  `SuperThemeData` / `SuperMetrics` instead of hard-coded hex.
- `NavigationSidebarThemeData.of(context)` now prefers an explicitly registered
  extension, then the ambient `SuperMaterialThemeData`, then the `dark` preset.

### Changed

- Upgraded to **super_core 1.1.0** (`SuperMaterialThemeData` is now a
  `ThemeData` subclass with responsive `SuperDeviceMode` tokens). Minimum
  raised to `dart >=3.8.0`, `flutter >=3.32.0`.

---

## [2.2.0] — 2026-07-03

The **ERP power-user** release: screen codes, recents, state persistence,
badge roll-up and working keyboard shortcuts (Ctrl+Shift combos **and**
sequential chords) — plus three real fixes.
**Additive — no breaking changes.**

### Added — screen codes & keyword search

- **`NavNode.code`** — optional short screen code (SAP-style transaction
  code, e.g. `'JE01'`). Rendered as a mono chip in the command palette and
  matched by both the inline tree filter and the palette.
- **`NavNode.keywords`** — hidden search aliases (synonyms, legacy names,
  bilingual terms). Matched, never rendered. Unmodifiable after construction.
- `NavigationSidebarController.matchSet()` and `NavSearchOps.filter` now
  match label + code + keywords (+ group/module in the palette).
  `NavSearchHit` gains `code`, `keywords` and a `haystack` getter.

### Added — recent destinations

- The controller records every successful leaf navigation in an MRU list:
  **`recents`** / **`recentNodes`** / **`clearRecents()`** /
  constructor `recents:` seed / **`maxRecents`** (default 8).
- The command palette shows a **"Recent" band** first while the query is
  empty. Localized via `NavigationSidebarLocalizations.recentsTitle`
  (Arabic preset: `'الأخيرة'`); `NavSearchDialog.recentsLabel` /
  `showNavSearchDialog(recentsLabel:)` for direct use.
- `replaceSections` prunes recents whose nodes no longer exist.

### Added — sidebar state persistence

- **`NavSidebarStateSnapshot`** — immutable, JSON-serializable capture of
  the user-owned state (active, expanded, favorites, recents, collapsed)
  with `toJson` / `fromJson`.
- **`controller.snapshot()`** / **`controller.restore(snapshot)`** — restore
  drops ids missing from the current tree (permissions may have changed) and
  notifies once. Persist per-user so pinned screens and open modules follow
  the user to any workstation.

### Added — badge count roll-up

- **`NavigationSidebar.aggregateBadges`** — a closed module whose descendants
  carry numeric badges shows the **summed count chip** instead of the plain
  accent dot ("12 documents need you inside Finance"). Non-numeric badges
  keep the dot. **`NavOps.subtreeBadgeSum`** exposed for hosts.

### Added — working keyboard shortcuts

- **`NavShortcutBinder<T>`** — wraps the shell and turns every leaf's
  `NavNode.shortcut` into a working keystroke. Two styles, chosen per node
  from its key list:
  - **Modifier combo** — `['ctrl', 'shift', 'd']` fires on Ctrl+Shift+D
    pressed together (any of ctrl/shift/alt/cmd + one main key), matched on
    the exact modifier set.
  - **Sequential chord** — `['g', 'd']` fires on "g then d", matched
    key-by-key with a rolling buffer and `chordTimeout` (1.2 s).
  Both are suspended while any text field has focus, refuse locked/disabled
  nodes, rebuild on `replaceSections`, and honor the `enabled` switch.
  `shortcut` is no longer "visual hint only" when a binder is present.
- **`NavShortcutOps.isCombo` / `.keyLabel`** and `kNavShortcutModifiers`
  exposed; shortcut-hint keycaps render combos with `+` separators and
  Ctrl/Shift/Alt/Cmd labels, sequences with `›`.

### Fixed

- **Command palette keyboard navigation** — the footer advertised
  `↑↓ navigate · ↵ open · esc close` but none of it was wired. Now: ↑/↓ move
  a highlighted row (wraps), Enter opens it, Escape closes the dialog.
- **Rail modules were dead on touch** — flyouts opened on hover only.
  Tapping a rail module now toggles its flyout (tablets / POS terminals).
- **No visible keyboard focus** — focused rows now show the hover tint plus
  an accent focus ring, so Tab navigation is usable.

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
