# super_navigation_sidebar

A focused, responsive navigation pane for Flutter applications.

Version **3.0.0** keeps the package centered on navigation state and navigation
UI. The host application owns its `Scaffold`, app bar, routing, and global
keyboard shortcuts. The package provides the sidebar, controller, models,
theme/localization support, and the reusable `NavigationSearchView`.

## Features

- Expanded sidebar, icon rail, and off-canvas drawer modes.
- `NavSidebarBreakpoints` for adaptive mode selection.
- Typed `NavNode<T>` / `NavSection<T>` navigation trees.
- Deep modules and groups with connector guides and flyouts.
- `NavigationSidebarController<T>` for active state, expansion, drawer state,
  favorites, recents, filtering, and persistence snapshots.
- Screen codes and hidden keywords for navigation search.
- `NavigationSearchView<T>` for reusable navigation search UI.
- Dialog and modal-bottom-sheet search presentation modes.
- Quick Access favorites and recent destinations.
- Permission-locked and disabled nodes.
- Status indicators and badge aggregation.
- Footer navigation sections.
- Light/dark theming with `super_core` integration.
- Arabic localization, RTL support, semantics, and keyboard navigation.

## Requirements

| Requirement | Version |
| --- | ---: |
| Dart SDK | `>=3.8.0 <4.0.0` |
| Flutter | `>=3.32.0` |
| `super_core` | `>=3.3.0 <4.0.0` |
| `super_form_field` | `>=1.10.0 <2.0.0` |

## Installation

```yaml
dependencies:
  super_navigation_sidebar: ^3.0.0
```

```dart
import 'package:super_navigation_sidebar/super_navigation_sidebar.dart';
```

## Theme setup

```dart
final typography = SuperTextTheme();

final light = SuperMaterialThemeData.light(
  textTheme: typography,
  primaryTextTheme: typography,
);

MaterialApp(
  theme: light.copyWith(
    extensions: [
      NavigationSidebarThemeData.fromMaterialTheme(light),
    ],
  ),
  home: const AppRoot(),
);
```

You can also register `NavigationSidebarThemeData.light` / `.dark` directly.

## Quick start

Create one controller and let your host own the page layout:

```dart
final sections = <NavSection<String>>[
  NavSection<String>(
    title: 'Workspace',
    items: [
      NavNode(
        id: 'dashboard',
        label: Text('Dashboard'),
        code: 'DB01',
        keywords: const ['overview', 'home'],
        leadingIcon: Icon(Icons.dashboard_outlined),
        value: 'dashboard',
      ),
      NavNode(
        id: 'finance',
        label: Text('Finance'),
        leadingIcon: Icon(Icons.account_balance_outlined),
        children: [
          NavNode(
            id: 'ledger_group',
            label: Text('General ledger'),
            children: [
              NavNode(
                id: 'journals',
                label: Text('Journal entries'),
                code: 'JE01',
                keywords: const ['voucher', 'posting'],
                leadingIcon: Icon(Icons.receipt_long_outlined),
                badge: const NavBadge('8', tone: NavBadgeTone.warning),
                value: 'journals',
              ),
            ],
          ),
        ],
      ),
    ],
  ),
];

late final NavigationSidebarController<String> nav =
    NavigationSidebarController<String>(
  sections: sections,
  active: 'dashboard',
);
```

Use `LayoutBuilder` to choose a presentation mode:

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final mode = const NavSidebarBreakpoints().modeFor(constraints.maxWidth);

    if (mode == NavSidebarMode.drawer) {
      return Stack(
        children: [
          Positioned.fill(
            child: Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: nav.openDrawer,
                ),
                title: const Text('GeniusLink'),
              ),
              body: const CurrentPage(),
            ),
          ),
          Positioned.fill(
            child: NavigationSidebar<String>(
              controller: nav,
              mode: mode,
              allowSearchView: true,
              searchViewMode: NavigationSearchViewMode.sheet,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        NavigationSidebar<String>(
          controller: nav,
          mode: mode,
          showPaneToggle: true,
          allowSearchView: true,
          searchViewMode: NavigationSearchViewMode.dialog,
        ),
        const Expanded(child: CurrentPage()),
      ],
    );
  },
);
```

## NavigationSearchView

`NavigationSearchView<T>` is presentation-independent. Embed it directly:

```dart
SizedBox(
  height: 520,
  child: NavigationSearchView<String>(
    controller: nav,
    autofocus: false,
    closeOnPick: false,
    onPick: (id) => nav.navigate(id),
  ),
)
```

Open it as a dialog:

```dart
showNavigationSearchView<String>(
  context,
  controller: nav,
  mode: NavigationSearchViewMode.dialog,
);
```

Open it as a modal bottom sheet:

```dart
showNavigationSearchView<String>(
  context,
  controller: nav,
  mode: NavigationSearchViewMode.sheet,
);
```

The search index matches `label`, `code`, `keywords`, module name, and group
name. When the query is empty, recent destinations are shown first.

## Sidebar search options

`NavigationSidebar` supports two distinct search experiences:

- `searchable: true` filters the currently rendered tree in place.
- `allowSearchView: true` renders a search trigger that opens
  `NavigationSearchView` using `searchViewMode`.

When both are enabled, `allowSearchView` takes precedence for the built-in
search control.

## Favorites and recents

```dart
NavigationSidebar<String>(
  controller: nav,
  mode: NavSidebarMode.expanded,
  favoritable: true,
)
```

The controller exposes:

```dart
nav.favorites;
nav.favoriteNodes;
nav.recents;
nav.recentNodes;
nav.toggleFavorite('journals');
nav.clearRecents();
```

## Locked, disabled, and status nodes

```dart
NavNode(
  id: 'year_end_close',
  label: Text('Year-end close'),
  leadingIcon: Icon(Icons.lock_outline),
  locked: true,
  lockMessage: 'Requires Controller role',
  value: 'year_end_close',
)

NavNode(
  id: 'fiscal_period',
  label: Text('Current fiscal period'),
  leadingIcon: Icon(Icons.calendar_month_outlined),
  status: NavNodeStatus.open,
  value: 'fiscal_period',
)
```

`NavigationSidebarController.navigate` returns `false` for missing, locked, or
disabled nodes.

## Footer navigation

```dart
NavSection<String>(
  title: 'System',
  placement: NavSectionPlacement.footer,
  items: [
    NavNode(
      id: 'settings',
      label: Text('Settings'),
      leadingIcon: Icon(Icons.settings_outlined),
      value: 'settings',
    ),
  ],
)
```

## State persistence

Use the existing snapshot APIs on the controller to persist navigation UI
state. Keep application routing state in the host router rather than in the
sidebar package.

## 3.0 migration

Version 3.0 removes the package-owned application chrome and keyboard shortcut
execution layer. Migrate host code as follows:

- Build app bars and page scaffolds with Flutter / your application design
  system.
- Compose responsive layouts with `LayoutBuilder`, `Row`, and `Stack`.
- Open mobile drawers with `NavigationSidebarController.openDrawer()`.
- Replace command-palette calls with `showNavigationSearchView(...)`.
- Replace `allowSearchDialog` with `allowSearchView` and choose
  `searchViewMode`.
- Register application keyboard shortcuts in the host using Flutter
  `Shortcuts` / `Actions`, your router, or your command system.

The following 2.x APIs are intentionally no longer part of the 3.0 public
surface: the integrated shell, sidebar-specific app-bar helpers, breadcrumb and
app-bar search helpers, package shortcut binder, shortcut metadata/hint modes,
and app-bar/shell-only controller/theme state.

## Public API overview

| API | Purpose |
| --- | --- |
| `NavigationSidebar<T>` | Expanded / rail / drawer navigation pane. |
| `NavigationSidebarController<T>` | Navigation and pane state. |
| `NavigationSidebarScope<T>` | Makes a controller available to descendants. |
| `NavigationSidebarThemeData` | Theme extension and geometry tokens. |
| `NavigationSidebarLocalizations` | User-facing strings and Arabic preset. |
| `NavigationSearchView<T>` | Reusable navigation search UI. |
| `NavigationSearchViewMode` | `dialog` / `sheet` presentation choice. |
| `showNavigationSearchView<T>` | Opens the search UI modally. |
| `NavSearchHit` | Flattened search-index entry. |
| `NavSearchOps` | Search index/filter helpers. |
| `NavNode<T>` | Typed navigation node. |
| `NavSection<T>` | Navigation section. |
| `NavSidebarBreakpoints` | Responsive mode thresholds. |
| `NavSidebarStateSnapshot` | Serializable pane/controller state snapshot. |

## NavNode content

`NavNode` accepts widgets for its label and optional leading/trailing icons. This allows navigation items to use rich text, badges, progress indicators, custom icon widgets, or any other Flutter widget without requiring a package-specific wrapper.

```dart
NavNode(
  label: const Text('Dashboard'),
  leadingIcon: const Icon(Icons.dashboard_outlined),
  trailingIcon: const Icon(Icons.chevron_right),
)
```

Only `label` is required. Omit `leadingIcon` or `trailingIcon` when that position is not needed.

## Navigation node content

Starting with version `3.1.0`, navigation content is Widget-based.

`NavNode.label` accepts any `Widget`, so labels are no longer limited to plain
text. `leadingIcon` and `trailingIcon` also accept Widgets, allowing navigation
items to use custom visual content without forcing it into `String` or
`IconData`.

```dart
NavNode(
  label: const Text('Dashboard'),
  leadingIcon: const Icon(Icons.dashboard_outlined),
  trailingIcon: const Icon(Icons.chevron_right),
  keywords: const ['dashboard', 'home'],
)
```

A label can also be a custom widget:

```dart
NavNode(
  label: Row(
    mainAxisSize: MainAxisSize.min,
    children: const [
      Text('Inbox'),
      SizedBox(width: 8),
      Badge(label: Text('4')),
    ],
  ),
  leadingIcon: const Icon(Icons.inbox_outlined),
  keywords: const ['inbox', 'messages', 'mail'],
)
```

### Search keywords

Because `label` can be any Widget, the package does not attempt to extract text
from it. Search and filtering should use `keywords`.

```dart
NavNode(
  label: const Text('Customer Accounts'),
  leadingIcon: const Icon(Icons.people_outline),
  keywords: const [
    'customer accounts',
    'customers',
    'accounts',
  ],
)
```

`keywords` is non-nullable in `3.1.0`. If no search terms are needed, omit the
argument and the default empty list is used.

### Leading and trailing content

Both icon positions accept arbitrary Widgets:

```dart
NavNode(
  label: const Text('Notifications'),
  leadingIcon: const Icon(Icons.notifications_outlined),
  trailingIcon: const Badge(
    label: Text('12'),
  ),
  keywords: const ['notifications', 'alerts'],
)
```

Do not convert `label` to `String`, and do not convert `leadingIcon` or
`trailingIcon` back to `IconData`. Render these values directly as Widgets.
