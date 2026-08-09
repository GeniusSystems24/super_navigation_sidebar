# super_navigation_sidebar — ChatGPT / Codex agent instructions

Use these instructions when asked to build or modify a Flutter UI that needs a
**responsive app navigation sidebar** using the `super_navigation_sidebar`
package.

---

## Package

```
name:    super_navigation_sidebar
version: 2.4.2
import:  package:super_navigation_sidebar/super_navigation_sidebar.dart
```

## When to use

Apply this skill when the user asks for:
- "left-nav", "side navigation", "navigation drawer", "navigation rail"
- "responsive sidebar", "app shell navigation"
- "expanded / rail / drawer navigation"
- "collapsible sidebar", "icon rail"
- "navigation with badges", "section-based nav tree"

## Mandatory setup

### 1 · Add to `pubspec.yaml`

```yaml
dependencies:
  super_navigation_sidebar: ^2.4.2
```

### 2 · Integrate with `super_core` 3.3.0

```dart
import 'package:super_core/super_core.dart';
import 'package:super_navigation_sidebar/super_navigation_sidebar.dart';

final typography = SuperTextTheme();

MaterialApp(
  theme: SuperMaterialThemeData.light(
    textTheme: typography,
    primaryTextTheme: typography,
  ),
  darkTheme: SuperMaterialThemeData.dark(
    textTheme: typography,
    primaryTextTheme: typography,
  ),
)
```

The sidebar automatically derives its colors and responsive sizes from the
ambient `SuperMaterialThemeData` unless an explicit
`NavigationSidebarThemeData` extension is registered.

**super_core 3.3.0 rule:** `textTheme` and `primaryTextTheme` are required
`SuperTextTheme` values. `SuperThemeData` no longer exposes `textTheme`; never
use `context.superTheme.textTheme` or `SuperThemeData.of(context).textTheme`.
Use `context.superTextTheme` or `SuperMaterialThemeData.of(context).textTheme`.

---

## Core API cheatsheet

### `NavNode<T>` fields

| Field | Required | Description |
|---|---|---|
| `id` | ✅ | Stable unique String — the nav identity. |
| `label` | ✅ | Display text. |
| `code` | — | Short screen code (`'JE01'`) — mono chip in palette, searchable (2.2). |
| `keywords` | — | Hidden search aliases — matched, never rendered (2.2). |
| `icon` | — | Leading icon. Required in spirit for modules + items. |
| `children` | — | Child nodes. Empty = leaf. |
| `value` | — | Strongly-typed host payload. |
| `badge` | — | `NavBadge(text, tone: NavBadgeTone.*)` |
| `shortcut` | — | `['g', 'd']` keycap hint — becomes a working chord inside `NavShortcutBinder` (2.2). |
| `locked` | — | Permission-gate: dim + lock glyph + blocked nav + tooltip. |
| `lockMessage` | — | Tooltip on a locked row. |
| `status` | — | `NavNodeStatus.open/closed/locked/attention` dot. |
| `enabled` | — | Default `true`. |

### Role derivation (no explicit field)

| Depth | Has children | Role |
|---|---|---|
| 0 | No | `direct` — accent pill |
| 0 | Yes | `module` — icon + chevron |
| ≥1 | Yes | `group` — uppercase bullet header |
| ≥1 | No | `item` — boxed icon + label |

### `NavigationSidebarController<T>` key methods

| Method / Property | Returns | Effect |
|---|---|---|
| `navigate(id)` | `bool` | Set active + open ancestors + close drawer. `false` if locked/disabled/missing. |
| `toggleCollapsed()` | `void` | expanded ↔ rail. |
| `collapsed = true` | — | Force rail. |
| `openDrawer()` / `closeDrawer()` / `toggleDrawer()` | `void` | Drawer state. |
| `canGoBack = bool` | — | Enables AppBar back button. Bind to `router.canPop()`. |
| `expand(id)` / `collapse(id)` / `toggleNode(id)` | `void` | Single-node expansion. |
| `expandAll()` / `collapseAll()` | `void` | Bulk expansion. |
| `setQuery(q)` | `void` | Drives built-in search filter (matches label + code + keywords). |
| `toggleFavorite(id)` / `setFavorites(ids)` | `void` | Quick Access management. |
| `recents` / `recentNodes` / `clearRecents()` | — | MRU history, auto-filled by `navigate()` (2.2). |
| `snapshot()` / `restore(s)` | — | JSON-serializable `NavSidebarStateSnapshot` persistence (2.2). |
| `replaceSections(s)` | `void` | Hot-swap section forest (validates duplicates in debug; prunes recents). |
| `of<T>(context)` | `controller?` | `NavigationSidebarScope` accessor from any descendant (may be null). |

### `NavigationSidebar<T>` key props

| Prop | Default | Purpose |
|---|---|---|
| `controller` | — | External controller. Provide OR sections+active. |
| `sections` | — | Seed when widget owns the controller. |
| `mode` | `expanded` | `expanded` / `rail` / `drawer` |
| `showGuides` | `true` | │ ├ └ connectors. |
| `railFlyouts` | `true` | Module hover flyouts in rail. |
| `showPaneToggle` | `false` | Top-of-pane menu button (collapse ↔ expand). Enable when no AppBar carries the toggle. |
| `shortcutMode` | `onHover` | Keycap visibility — `onHover`/`always`/`hidden`; always a tooltip. |
| `searchable` | `false` | Built-in inline filter field + match highlight. |
| `allowSearchDialog` | `false` | Command palette — the single switch for dialog search. Trigger in pane; opens `NavSearchDialog`. Precedence over `searchable`. |
| `onSearchPick` | `null` | `ValueChanged<NavNode<T>>` after a palette pick; falls back to `onNavigate`. |
| `favoritable` | `false` | Per-row star + synthesized Quick Access band. |
| `aggregateBadges` | `false` | Summed numeric badge chip on a closed module (2.2). |
| `header` | `null` | `(ctx, collapsed) → Widget` slot. |
| `footer` | `null` | `(ctx, collapsed) → Widget` slot. |
| `localizations` | English | `NavigationSidebarLocalizations` — all UI strings. |
| `onNavigate` | `null` | Called **only when navigation succeeds** (never for locked/disabled nodes). |

---

## New in 2.2

- **`NavNode.code` + `NavNode.keywords`** — SAP-style screen codes (mono chip in
  the palette) and hidden search aliases; matched by the inline filter and the
  palette (`NavSearchHit` gains `code` / `keywords` / `haystack`).
- **Recents** — `controller.recents` / `recentNodes` / `clearRecents()` /
  constructor `recents:` + `maxRecents:` (8). Auto-filled on successful
  `navigate()`; the palette shows a "Recent" band while the query is empty
  (`NavSearchDialog.recentsLabel`, `localizations.recentsTitle`).
- **`NavSidebarStateSnapshot`** — `controller.snapshot()` / `restore()` with
  `toJson` / `fromJson`; restore drops stale ids and notifies once.
- **`NavigationSidebar.aggregateBadges`** — closed modules show the summed
  numeric descendant badge count as a chip (`NavOps.subtreeBadgeSum`).
- **`NavShortcutBinder<T>`** — wraps the shell and turns `NavNode.shortcut`
  into working keystrokes. Two styles per node: **combo** `['ctrl','shift','d']`
  (Ctrl+Shift+D together) and **sequence** `['g', 'd']` (g then d). Suspended
  in text fields, refuses locked/disabled, rebuilds on `replaceSections`,
  `enabled` switch. Helpers: `NavShortcutOps.isCombo` / `.keyLabel`.
- **Fixes** — palette keyboard navigation actually works now (↑↓ highlighted
  row, ↵ open, esc close); rail modules toggle their flyout on tap (touch);
  rows show a visible keyboard-focus ring.

## New in 2.1

- **`NavigationSidebar.allowSearchDialog`** (bool, default `false`) — the single
  switch that enables the command palette. Renders a search trigger in the pane
  (field in expanded/drawer, icon button in rail) and opens `NavSearchDialog`
  via `Overlay`. No `Stack`/`Overlay` wiring in the host app. Precedence over
  `searchable`.
- **`NavigationSidebar.onSearchPick`** — `ValueChanged<NavNode<T>>`; fires after
  navigate, falls back to `onNavigate` when null.
- **`NavSearchDialog<T>`** — the overlay widget behind it. Requires a `Stack`
  ancestor. Constructor: `controller`, `onClose`, `onPick`, `hint`.
- **`showNavSearchDialog<T>(context, {controller, onPick, hint})`** — opens
  `NavSearchDialog` via `Overlay` (no Stack needed) — imperative escape hatch.
- **`NavSearchHit`** — public model: `id`, `label`, `icon`, `module`, `group`,
  `badge`, `shortcut`.
- **`NavSearchOps`** — `buildIndex<T>(sections)` + `filter(index, query)`.
- **`NavigationSidebarSearchField`** — unchanged; the inline `setQuery` filter
  field (pair with `searchable`). It does **not** open the dialog.

## New in 2.0

- **`NavigationShell<T>`** — full-app shell that composes bar + pane + body.
  Props: `headerLayout` (`spanning`/`inset`), `paneBehavior` (`push`/`overlay`),
  `appBarBuilder`, `sidebarBuilder`, `body`, `mode`, `breakpoints`, `contentPadding`.
- **`NavSectionPlacement.footer`** — pins a section to the pane bottom.
- **`NavSelectionIndicator.bar`** — Fluent-style leading pill + tinted row.
  Theme props: `selectionIndicator`, `indicatorThickness`, `indicatorInset`.
- **Back button** — `NavigationSidebarAppBar(showBackButton: true, onBack: …)`;
  enabled while `controller.canGoBack == true`.
- **`showPaneToggle`** on `NavigationSidebar` — top-of-pane collapse button for
  layouts with no AppBar.
- **`NavigationSidebarScope<T>`** — publishes the controller via
  `InheritedWidget`; access via `NavigationSidebarController.of<T>(context)`.
- **`autoExpandActive`** — controller constructor flag (default `true`) to
  auto-open ancestors when `active` changes.

## New in 1.2

- **`NavigationSidebarAppBar`** — connected `PreferredSizeWidget` with hamburger
  (drawer mode) / collapse toggle (desktop). Slots: `pageTitle`, `globalSearch`,
  `middle`, `actions`, custom `builder`.
- **`NavBreadcrumb<T>`** — reads ancestor path from the controller live.
- **`NavigationSidebarSearchField`** — compact field driving `controller.setQuery`.
- **`NavigationSidebarLocalizations`** — all user-facing strings in one class.
  Arabic preset: `NavigationSidebarLocalizations.arabic`.
- **Deep immutability** — `NavNode.children` and `NavSection.items` are
  `List.unmodifiable` after construction.
- **Duplicate ID validation** — debug assertion in the controller constructor.
  Programmatic: `NavOps.findDuplicateIds<T>(sections)`.
- **Navigation safety** — `navigate()` returns `bool`; `onNavigate` only fires
  on `true`.
- **⚠ Breaking:** `NavNode` / `NavSection` constructors are no longer `const`.
  Remove `const` keyword from call sites.

---

## Patterns

### Pattern A — NavigationShell with command-palette search (recommended)

```dart
NavigationShell<String>(
  controller: nav,
  headerLayout: NavShellHeaderLayout.spanning,
  paneBehavior: NavPaneBehavior.push,
  appBarBuilder: (ctx, mode) => NavigationSidebarAppBar(
    controller: nav,
    mode: mode,
    showBackButton: true,
    onBack: () => Navigator.of(ctx).maybePop(),
    pageTitle: NavBreadcrumb<String>(controller: nav),
  ),
  sidebarBuilder: (ctx, mode) => NavigationSidebar<String>(
    controller: nav,
    mode: mode,
    allowSearchDialog: true,   // ← single switch: sidebar owns the palette
    searchHint: 'Search tabs & actions…',
    onNavigate: (n) => setState(() => screen = n.value!),
  ),
  body: page,
)
```

### Pattern A1 — Imperative dialog (from a button / keyboard shortcut)

```dart
// From any BuildContext — no Stack required:
showNavSearchDialog<String>(context, controller: nav);
```

### Pattern A2 — Manual responsive shell (no NavigationShell)

```dart
LayoutBuilder(builder: (context, c) {
  final mode = const NavSidebarBreakpoints().modeFor(c.maxWidth);
  final sidebar = NavigationSidebar<String>(controller: nav, mode: mode,
      onNavigate: (n) => setState(() => screen = n.value!));

  if (mode == NavSidebarMode.drawer) {
    return Scaffold(
      appBar: NavigationSidebarAppBar(
        controller: nav,
        mode: NavSidebarMode.drawer,
        pageTitle: NavBreadcrumb<String>(controller: nav),
      ),
      body: Stack(children: [Positioned.fill(child: page), Positioned.fill(child: sidebar)]),
    );
  }
  return Row(children: [
    sidebar,
    Expanded(child: Column(children: [
      NavigationSidebarAppBar(
        controller: nav,
        mode: mode,
        showCollapseToggle: true,
        showBackButton: true,
        onBack: () => Navigator.of(context).maybePop(),
        pageTitle: NavBreadcrumb<String>(controller: nav),
        globalSearch: NavigationSidebarSearchField(controller: nav),
      ),
      Expanded(child: page),
    ])),
  ]);
})
```

### Pattern B — Footer sections (Settings / Help)

```dart
NavSection(
  title: '', placement: NavSectionPlacement.footer,
  items: [
    NavNode(id: 'help',     label: 'Help',     icon: Icons.help_outline,     value: 'help'),
    NavNode(id: 'settings', label: 'Settings', icon: Icons.settings_outlined, value: 'settings'),
  ],
);
```

### Pattern C — Fluent bar selection indicator

```dart
ThemeData(extensions: [
  NavigationSidebarThemeData.dark.copyWith(
    selectionIndicator: NavSelectionIndicator.bar,
    indicatorThickness: 3, indicatorInset: 9,
  ),
])
```

### Pattern D — Deep-link from page content (NavigationSidebarScope)

```dart
final ok = NavigationSidebarController.of<String>(context)?.navigate('journals');
// ok == false means the node was locked or disabled — safe to check.
```

### Pattern E — Live badge update

```dart
// Hot-swap sections after badge counts change:
_nav.replaceSections(updatedSections);
```

### Pattern F — Localization (Arabic)

```dart
Directionality(
  textDirection: TextDirection.rtl,
  child: NavigationSidebar<String>(
    controller: nav, mode: mode,
    localizations: NavigationSidebarLocalizations.arabic,
  ),
)
```

### Pattern G — Working shortcut chords (2.2)

```dart
NavShortcutBinder<String>(
  controller: nav,
  onNavigate: (n) => setState(() => screen = n.value!),
  child: NavigationShell<String>(…),
)
// NavNode(shortcut: ['ctrl','shift','d']) → Ctrl+Shift+D together.
// NavNode(shortcut: ['g', 'd'])           → g then d (sequence).
```

### Pattern H — State persistence (2.2)

```dart
// Save on change:
nav.addListener(() =>
    prefs.setString('nav', jsonEncode(nav.snapshot().toJson())));
// Restore on launch (stale ids dropped automatically):
nav.restore(NavSidebarStateSnapshot.fromJson(jsonDecode(raw)));
```

### Pattern I — Screen codes + badge roll-up (2.2)

```dart
NavNode(id: 'je', label: 'Journal Entry', value: 'je',
        code: 'JE01', keywords: ['قيد', 'voucher']);
NavigationSidebar<String>(controller: nav, mode: mode,
    aggregateBadges: true); // closed module shows summed descendant counts
```

---

## Common mistakes

- Hand-wiring Row/Column/Stack instead of using `NavigationShell`.
- Not using `LayoutBuilder` when building a manual shell — the widget doesn't auto-detect width.
- Wrong nesting depth — role is positional; a depth-0 branch is always a module.
- Using `value` as the nav key — `navigate()` uses `id`; `value` is your payload.
- Placing the drawer in a `Row` instead of a `Stack + Positioned.fill` (or use `NavigationShell`).
- Forgetting `ThemeData(extensions: [NavigationSidebarThemeData.light])`.
- Using `const NavNode(…)` or `const NavSection(…)` — constructors are non-const since 1.2.
- Expecting `onNavigate` to fire for locked/disabled nodes — it never does.
- Wiring chord keystrokes by hand — wrap the shell in `NavShortcutBinder` instead (2.2).
- Persisting favorites/expansion piecemeal — use `snapshot()` / `restore()` (2.2).
- Not setting `NavigationSidebar.allowSearchDialog: true` when a command palette is the intended UX — it is the single switch; the sidebar owns the whole dialog.
