# super_navigation_sidebar — ChatGPT / Codex agent instructions

Use these instructions when asked to build or modify a Flutter UI that needs a
**responsive app navigation sidebar** using the `super_navigation_sidebar`
package.

---

## Package

```
name:    super_navigation_sidebar
version: 1.2.0
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
  super_navigation_sidebar: ^1.2.0
```

### 2 · Register the theme extension

```dart
import 'package:super_navigation_sidebar/super_navigation_sidebar.dart';

MaterialApp(
  theme:     ThemeData(extensions: const [NavigationSidebarThemeData.light]),
  darkTheme: ThemeData(extensions: const [NavigationSidebarThemeData.dark]),
)
```

---

## Core API cheatsheet

### `NavNode<T>` fields

| Field | Required | Description |
|---|---|---|
| `id` | ✅ | Stable unique String — the nav identity. |
| `label` | ✅ | Display text. |
| `icon` | — | Leading icon. Required in spirit for modules + items. |
| `children` | — | Child nodes. Empty = leaf. |
| `value` | — | Strongly-typed host payload. |
| `badge` | — | `NavBadge(text, tone: NavBadgeTone.*)` |
| `shortcut` | — | `['g', 'd']` hint shown on hover. |
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

| Method | Returns | Effect |
|---|---|---|
| `navigate(id)` | `bool` | Set active + open ancestors + close drawer. `false` if locked/disabled/missing. |
| `toggleCollapsed()` | `void` | expanded ↔ rail. |
| `openDrawer()` / `closeDrawer()` | `void` | Drawer state. |
| `expandAll()` / `collapseAll()` | `void` | Bulk expansion. |
| `replaceSections(s)` | `void` | Hot-swap section forest (validates duplicates in debug). |
| `of<T>(context)` | `controller?` | Scope accessor from page content (may be null). |

### `NavigationSidebar<T>` key props

| Prop | Default | Purpose |
|---|---|---|
| `controller` | — | External controller. Provide OR sections+active. |
| `sections` | — | Seed when widget owns the controller. |
| `mode` | `expanded` | `expanded` / `rail` / `drawer` |
| `showGuides` | `true` | │ ├ └ connectors. |
| `railFlyouts` | `true` | Module hover flyouts in rail. |
| `shortcutMode` | `onHover` | Keycap visibility — `onHover`/`always`/`hidden`; always a tooltip. |
| `searchable` | `false` | Built-in filter field + match highlight. |
| `favoritable` | `false` | Per-row star + synthesized Quick Access band. |
| `header` | `null` | `(ctx, collapsed) → Widget` slot. |
| `footer` | `null` | `(ctx, collapsed) → Widget` slot. |
| `localizations` | English | `NavigationSidebarLocalizations` — all UI strings. |
| `onNavigate` | `null` | Called **only when navigation succeeds** (never for locked/disabled nodes). |

---

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

### Pattern A — Responsive shell with AppBar

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
        pageTitle: NavBreadcrumb<String>(controller: nav),
        globalSearch: NavigationSidebarSearchField(controller: nav),
      ),
      Expanded(child: page),
    ])),
  ]);
})
```

### Pattern B — Deep-link from page content

```dart
NavigationSidebarController.of<String>(context)?.navigate('journals');
```

### Pattern C — Live badge update

```dart
// Hot-swap sections after badge counts change:
_nav.replaceSections(updatedSections);
```

---

## Pattern B — Localization (Arabic)

```dart
Directionality(
  textDirection: TextDirection.rtl,
  child: NavigationSidebar<String>(
    controller: nav,
    mode: mode,
    localizations: NavigationSidebarLocalizations.arabic,
  ),
)
```

## Pattern C — Deep-link from page content

```dart
final ok = NavigationSidebarController.of<String>(context)?.navigate('journals');
// ok == false means the node was locked or disabled — safe to check.
```

---

## Common mistakes

- Not using `LayoutBuilder` — the widget doesn't auto-detect width.
- Wrong nesting depth — role is positional; a depth-0 branch is always a module.
- Using `value` as the nav key — `navigate()` uses `id`; `value` is your payload.
- Placing the drawer in a `Row` instead of a `Stack + Positioned.fill`.
- Forgetting `ThemeData(extensions: [NavigationSidebarThemeData.light])`.
- Using `const NavNode(…)` or `const NavSection(…)` — constructors are non-const since 1.2.
- Expecting `onNavigate` to fire for locked/disabled nodes — it never does.
