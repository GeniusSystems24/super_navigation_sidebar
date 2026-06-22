# Changelog

All notable changes to `super_navigation_sidebar` will be documented in this file.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] — 2026-06-22

### Added

- **`NavigationSidebar<T>`** widget — responsive sidebar; three modes:
  - `NavSidebarMode.expanded` — 248 px full labelled tree with `│ ├ └`
    connectors, disclosure chevrons, badges and shortcut hints.
  - `NavSidebarMode.rail` — 76 px icon-only column; hovering a module opens
    a grouped flyout overlay. Badge dot on icon when any descendant has a
    badge.
  - `NavSidebarMode.drawer` — 280 px off-canvas panel with animated scrim;
    slide in/out with `AnimatedPositionedDirectional`. Tapping a destination
    navigates and dismisses.
  - `showGuides` · `railFlyouts` · `drawerTitle` chrome toggles.
  - `header` / `footer` slot builders — `(ctx, collapsed) → Widget`.
  - `onNavigate` callback fires alongside `controller.navigate`.

- **`NavigationSidebarController<T>`** (`ChangeNotifier`) — single source
  of truth.
  - Navigation: `navigate(id)` — sets active, auto-opens ancestors, closes
    the drawer.
  - Expansion: `expand` · `collapse` · `toggleNode` · `expandAll` ·
    `collapseAll`.
  - Rail / drawer: `toggleCollapsed` · `collapsed` setter · `openDrawer` ·
    `closeDrawer` · `toggleDrawer`.
  - Data: `replaceSections` · `setQuery` · `matchSet()`.
  - Reads: `sections` · `active` · `activeValue` · `collapsed` ·
    `drawerOpen` · `isActive` · `isExpanded` · `ownsActive` · `node`.
  - `of<T>(context)` scope accessor — returns `null` outside a sidebar.
  - `NavigationSidebarScope<T>` (`InheritedNotifier`) exposes the
    controller to descendants.

- **`NavSection<T>`** — `title` + `List<NavNode<T>>` items.

- **`NavNode<T>`** — `id` · `label` · `icon` · `children` · `value` ·
  `badge` · `shortcut` · `enabled`. Immutable; `copyWith` provided.

- **`NavNodeRole`** enum — `direct · module · group · item`; resolved from
  depth + `hasChildren` via `NavNodeRole.of(depth:, hasChildren:)`.

- **`NavBadge`** — `text` + `NavBadgeTone` (`accent · success · warning ·
  muted`). Pill on rows; dot on collapsed modules and rail icons.

- **`NavSidebarMode`** enum — `expanded · rail · drawer`.

- **`NavSidebarBreakpoints`** — `modeFor(width)`: expanded ≥ 1200 px ·
  rail ≥ 768 px · drawer below. Thresholds configurable.

- **`NavOps`** static utilities — `walk` · `find` · `ancestorsOf` ·
  `subtreeHasBadge` · `leafIds`.

- **`NavigationSidebarThemeData`** (`ThemeExtension`) — self-contained theme.
  - `.light` and `.dark` presets.
  - Instance fields: `bg` · `surface` · `inputBg` · `hover` · `border` ·
    `borderStrong` · `guide` · `fg1` – `fg4`.
  - Brand constants: `accent (#4A7CFF)` · `success (#1DB88A)` ·
    `warning (#F97316)` · `danger (#EF4444)`.
  - Layout constants: `widthExpanded (248)` · `widthRail (76)` ·
    `widthDrawer (280)` · `railButton (44)` · row heights · gutter.
  - Motion: `durFast (150 ms)` · `durBase (240 ms)` · `durDrawer (280 ms)` ·
    `curveStandard`.
  - `accentFill(pct)` · `badgeColors(tone)` helpers.
  - Full `copyWith` and `lerp`.

- **RTL** support via `Directionality` — all row padding uses
  `EdgeInsetsDirectional`; connectors, flyouts and drawer slide mirror.

- **Zero third-party dependencies** — pure Flutter + Material.
