# super_navigation_sidebar

A focused, responsive navigation pane for Flutter applications.

Version **3.3.0** keeps the package centered on navigation state and navigation
UI. The host application owns its `Scaffold`, app bar, routing, and global
keyboard shortcuts. The package provides the sidebar, controller, models,
theme/generated-localization support, and the reusable `SuperNavigationSearchView`.

## Features

- Expanded sidebar, icon rail, and off-canvas drawer modes.
- `SuperNavSidebarBreakpoints` for adaptive mode selection.
- Typed `SuperNavNode<T>` / `SuperNavSection<T>` navigation trees.
- Deep modules and groups with connector guides and flyouts.
- `SuperNavigationSidebarController<T>` for active state, expansion, drawer state,
  favorites, recents, filtering, and persistence snapshots.
- Screen codes and hidden keywords for navigation search.
- `SuperNavigationSearchView<T>` for reusable navigation search UI.
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
| `super_core` | `>=3.6.0 <4.0.0` |
| `super_form_field` | `>=1.11.1 <2.0.0` |

## Installation

```yaml
dependencies:
  super_navigation_sidebar: ^3.3.0
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
      SuperNavigationSidebarThemeData.fromMaterialTheme(light),
    ],
  ),
  home: const AppRoot(),
);
```

You can also register `SuperNavigationSidebarThemeData.light` / `.dark` directly.

## Localization setup

Version 3.2 uses Flutter generated localizations from
`lib/localizations/generated`. Register the package delegates in the host app:

```dart
MaterialApp(
  localizationsDelegates: SuperNavigationLocalization.localizationsDelegates,
  supportedLocales: SuperNavigationLocalization.supportedLocales,
  home: const AppRoot(),
);
```

`SuperNavigationSidebar` resolves strings from `SuperNavigationLocalization.of`
when delegates are registered and falls back to English otherwise. Explicit
`drawerTitle`, `searchHint`, and `quickAccessTitle` values still take
precedence.

## Super-prefixed API

Version 3.2 renames the public navigation components with a `Super` prefix:
`SuperNavigationSidebar`, `SuperNavigationSidebarController`, `SuperNavNode`,
`SuperNavSection`, `SuperNavigationSearchView`,
`SuperNavigationSidebarThemeData`, and related enums/helpers. The previous
public type names remain available as compatibility typedefs, and
`showNavigationSearchView` forwards to `showSuperNavigationSearchView`.

## Node actions

`SuperNavNode.onTap` attaches an optional context-aware action to a destination.
The sidebar and search surfaces invoke it after `navigate()` succeeds, before
the host `onNavigate` / `onSearchPick` callback.

```dart
SuperNavNode(
  id: 'refresh_balances',
  label: const Text('Refresh balances'),
  leadingIcon: const Icon(Icons.sync_outlined),
  value: 'refresh_balances',
  onTap: (context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refresh queued')),
    );
  },
)
```

Use `onTap` for node-local UI actions that need `BuildContext`. Keep routing
and page state in the host `onNavigate` callback.

## Quick start

Create one controller and let your host own the page layout:

```dart
final sections = <SuperNavSection<String>>[
  SuperNavSection<String>(
    title: 'Workspace',
    items: [
      SuperNavNode(
        id: 'dashboard',
        label: Text('Dashboard'),
        code: 'DB01',
        keywords: const ['overview', 'home'],
        leadingIcon: Icon(Icons.dashboard_outlined),
        value: 'dashboard',
      ),
      SuperNavNode(
        id: 'finance',
        label: Text('Finance'),
        leadingIcon: Icon(Icons.account_balance_outlined),
        children: [
          SuperNavNode(
            id: 'ledger_group',
            label: Text('General ledger'),
            children: [
              SuperNavNode(
                id: 'journals',
                label: Text('Journal entries'),
                code: 'JE01',
                keywords: const ['voucher', 'posting'],
                leadingIcon: Icon(Icons.receipt_long_outlined),
                badge: const SuperNavBadge('8', tone: SuperNavBadgeTone.warning),
                value: 'journals',
              ),
            ],
          ),
        ],
      ),
    ],
  ),
];

late final SuperNavigationSidebarController<String> nav =
    SuperNavigationSidebarController<String>(
  sections: sections,
  active: 'dashboard',
);
```

Use `LayoutBuilder` to choose a presentation mode:

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final mode = const SuperNavSidebarBreakpoints().modeFor(constraints.maxWidth);

    if (mode == SuperNavSidebarMode.drawer) {
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
            child: SuperNavigationSidebar<String>(
              controller: nav,
              mode: mode,
              allowSearchView: true,
              searchViewMode: SuperNavigationSearchViewMode.sheet,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        SuperNavigationSidebar<String>(
          controller: nav,
          mode: mode,
          showPaneToggle: true,
          allowSearchView: true,
          searchViewMode: SuperNavigationSearchViewMode.dialog,
        ),
        const Expanded(child: CurrentPage()),
      ],
    );
  },
);
```

## SuperNavigationSearchView

`SuperNavigationSearchView<T>` is presentation-independent. Embed it directly:

```dart
SizedBox(
  height: 520,
  child: SuperNavigationSearchView<String>(
    controller: nav,
    autofocus: false,
    closeOnPick: false,
    onPick: (id) => nav.navigate(id),
  ),
)
```

Open it as a dialog:

```dart
showSuperNavigationSearchView<String>(
  context,
  controller: nav,
  mode: SuperNavigationSearchViewMode.dialog,
);
```

Open it as a modal bottom sheet:

```dart
showSuperNavigationSearchView<String>(
  context,
  controller: nav,
  mode: SuperNavigationSearchViewMode.sheet,
);
```

The search index matches `label`, `code`, `keywords`, module name, and group
name. When the query is empty, recent destinations are shown first.

## Sidebar search options

`SuperNavigationSidebar` supports two distinct search experiences:

- `searchable: true` filters the currently rendered tree in place.
- `allowSearchView: true` renders a search trigger that opens
  `SuperNavigationSearchView` using `searchViewMode`.

When both are enabled, `allowSearchView` takes precedence for the built-in
search control.

## Favorites and recents

```dart
SuperNavigationSidebar<String>(
  controller: nav,
  mode: SuperNavSidebarMode.expanded,
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
SuperNavNode(
  id: 'year_end_close',
  label: Text('Year-end close'),
  leadingIcon: Icon(Icons.lock_outline),
  locked: true,
  lockMessage: 'Requires Controller role',
  value: 'year_end_close',
)

SuperNavNode(
  id: 'fiscal_period',
  label: Text('Current fiscal period'),
  leadingIcon: Icon(Icons.calendar_month_outlined),
  status: SuperNavNodeStatus.open,
  value: 'fiscal_period',
)
```

`SuperNavigationSidebarController.navigate` returns `false` for missing, locked, or
disabled nodes.

## Footer navigation

```dart
SuperNavSection<String>(
  title: 'System',
  placement: SuperNavSectionPlacement.footer,
  items: [
    SuperNavNode(
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
- Open mobile drawers with `SuperNavigationSidebarController.openDrawer()`.
- Replace command-palette calls with `showSuperNavigationSearchView(...)`.
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
| `SuperNavigationSidebar<T>` | Expanded / rail / drawer navigation pane. |
| `SuperNavigationSidebarController<T>` | Navigation and pane state. |
| `SuperNavigationSidebarScope<T>` | Makes a controller available to descendants. |
| `SuperNavigationSidebarThemeData` | Theme extension and geometry tokens. |
| `SuperNavigationLocalization` | Generated package localizations and delegates. |
| `SuperNavigationSearchView<T>` | Reusable navigation search UI. |
| `SuperNavigationSearchViewMode` | `dialog` / `sheet` presentation choice. |
| `showSuperNavigationSearchView<T>` | Opens the search UI modally. |
| `SuperNavSearchHit` | Flattened search-index entry. |
| `SuperNavSearchOps` | Search index/filter helpers. |
| `SuperNavNode<T>` | Typed navigation node. |
| `SuperNavSection<T>` | Navigation section. |
| `SuperNavSidebarBreakpoints` | Responsive mode thresholds. |
| `SuperNavSidebarStateSnapshot` | Serializable pane/controller state snapshot. |

## SuperNavNode content

`SuperNavNode` accepts widgets for its label and optional leading/trailing icons. This allows navigation items to use rich text, badges, progress indicators, custom icon widgets, or any other Flutter widget without requiring a package-specific wrapper.

```dart
SuperNavNode(
  label: const Text('Dashboard'),
  leadingIcon: const Icon(Icons.dashboard_outlined),
  trailingIcon: const Icon(Icons.chevron_right),
)
```

Only `label` is required. Omit `leadingIcon` or `trailingIcon` when that position is not needed.

## Navigation node content

Starting with version `3.1.0`, navigation content is Widget-based.

`SuperNavNode.label` accepts any `Widget`, so labels are no longer limited to plain
text. `leadingIcon` and `trailingIcon` also accept Widgets, allowing navigation
items to use custom visual content without forcing it into `String` or
`IconData`.

```dart
SuperNavNode(
  label: const Text('Dashboard'),
  leadingIcon: const Icon(Icons.dashboard_outlined),
  trailingIcon: const Icon(Icons.chevron_right),
  keywords: const ['dashboard', 'home'],
)
```

A label can also be a custom widget:

```dart
SuperNavNode(
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
SuperNavNode(
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
SuperNavNode(
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
