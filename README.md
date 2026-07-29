# super_navigation_sidebar

[![pub package](https://img.shields.io/pub/v/super_navigation_sidebar.svg)](https://pub.dev/packages/super_navigation_sidebar)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%89%A53.32.0-02569B.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%E2%89%A53.8.0-0175C2.svg)](https://dart.dev)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A responsive, themeable navigation sidebar for Flutter applications.

Build one typed navigation tree and render it as an expanded sidebar, a compact
icon rail, or an off-canvas drawer. The package also provides an integrated app
shell, a controller-driven state model, AppBar integration, search, favorites,
recent destinations, keyboard shortcuts, state persistence, localization, RTL,
and accessibility support.

## Features

- Three presentation modes: expanded, rail, and drawer.
- Adaptive mode selection with configurable width breakpoints.
- Typed, deeply immutable `NavNode<T>` and `NavSection<T>` models.
- Nested modules, groups, destinations, tree guides, and hover flyouts.
- Shared `NavigationSidebarController<T>` for navigation and UI state.
- Integrated `NavigationShell<T>` for AppBar, pane, and content layout.
- AppBar controls, breadcrumbs, global search, and custom slots.
- Built-in tree filtering and command-palette search.
- Quick Access favorites and recent destinations.
- Sequential chords and modifier-based keyboard shortcuts.
- Badges, numeric badge aggregation, permission locks, and status indicators.
- JSON-serializable state snapshots.
- Light and dark themes with `super_core` integration.
- Arabic strings, RTL mirroring, keyboard navigation, and semantic labels.

## Requirements

| Requirement | Version |
|---|---:|---
| Dart SDK | `>=3.8.0 <4.0.0` |
| Flutter | `>=3.32.0` |
| `super_core` | `>=3.0.0 <4.0.0` |

## Installation

Add the package to `pubspec.yaml`:

```yaml
dependencies:
  super_navigation_sidebar: ^2.4.0
```

Install the dependency:

```bash
flutter pub get
```

Import the public library:

```dart
import 'package:super_navigation_sidebar/super_navigation_sidebar.dart';
```

## Theme setup

Register the package theme extension in `MaterialApp`:

```dart
MaterialApp(
  theme: ThemeData(
    brightness: Brightness.light,
    extensions: const <ThemeExtension<dynamic>>[
      NavigationSidebarThemeData.light,
    ],
  ),
  darkTheme: ThemeData(
    brightness: Brightness.dark,
    extensions: const <ThemeExtension<dynamic>>[
      NavigationSidebarThemeData.dark,
    ],
  ),
  home: const AppShell(),
);
```

When the extension is not registered, `NavigationSidebarThemeData.of(context)`
tries to derive its tokens from the ambient `SuperMaterialThemeData` supplied
by `super_core`. An explicitly registered `NavigationSidebarThemeData` always
takes precedence.

## Quick start

The recommended setup uses one external controller shared by the sidebar,
AppBar, shell, and keyboard-shortcut binder.

```dart
import 'package:flutter/material.dart';
import 'package:super_navigation_sidebar/super_navigation_sidebar.dart';

enum AppDestination {
  dashboard,
  chartOfAccounts,
  journalEntries,
  settings,
}

final navigationSections = <NavSection<AppDestination>>[
  NavSection<AppDestination>(
    title: 'Workspace',
    items: <NavNode<AppDestination>>[
      NavNode<AppDestination>(
        id: 'dashboard',
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        value: AppDestination.dashboard,
        shortcut: const <String>['g', 'd'],
      ),
      NavNode<AppDestination>(
        id: 'accounting',
        label: 'Accounting',
        icon: Icons.account_balance_outlined,
        children: <NavNode<AppDestination>>[
          NavNode<AppDestination>(
            id: 'accounts_group',
            label: 'Accounts',
            children: <NavNode<AppDestination>>[
              NavNode<AppDestination>(
                id: 'chart_of_accounts',
                label: 'Chart of accounts',
                code: 'COA',
                keywords: const <String>['ledger', 'accounts tree'],
                icon: Icons.account_tree_outlined,
                value: AppDestination.chartOfAccounts,
              ),
              NavNode<AppDestination>(
                id: 'journal_entries',
                label: 'Journal entries',
                code: 'JE01',
                icon: Icons.receipt_long_outlined,
                badge: const NavBadge('4', tone: NavBadgeTone.warning),
                shortcut: const <String>['ctrl', 'j'],
                value: AppDestination.journalEntries,
              ),
            ],
          ),
        ],
      ),
    ],
  ),
  NavSection<AppDestination>(
    title: 'System',
    placement: NavSectionPlacement.footer,
    items: <NavNode<AppDestination>>[
      NavNode<AppDestination>(
        id: 'settings',
        label: 'Settings',
        icon: Icons.settings_outlined,
        value: AppDestination.settings,
      ),
    ],
  ),
];

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final NavigationSidebarController<AppDestination> _navigation;
  AppDestination _destination = AppDestination.dashboard;

  @override
  void initState() {
    super.initState();
    _navigation = NavigationSidebarController<AppDestination>(
      sections: navigationSections,
      active: 'dashboard',
    );
  }

  @override
  void dispose() {
    _navigation.dispose();
    super.dispose();
  }

  void _openNode(NavNode<AppDestination> node) {
    final destination = node.value;
    if (destination == null) return;

    setState(() => _destination = destination);
    // Update go_router, Navigator, or another router here.
  }

  @override
  Widget build(BuildContext context) {
    return NavShortcutBinder<AppDestination>(
      controller: _navigation,
      onNavigate: _openNode,
      child: NavigationShell<AppDestination>(
        controller: _navigation,
        appBarBuilder: (BuildContext context, NavSidebarMode mode) {
          return NavigationSidebarAppBar(
            controller: _navigation,
            mode: mode,
            title: const Text('Example ERP'),
            pageTitle: NavBreadcrumb<AppDestination>(
              controller: _navigation,
            ),
            actions: <Widget>[
              IconButton(
                tooltip: 'Notifications',
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined),
              ),
            ],
          );
        },
        sidebarBuilder: (BuildContext context, NavSidebarMode mode) {
          return NavigationSidebar<AppDestination>(
            controller: _navigation,
            mode: mode,
            searchable: true,
            allowSearchDialog: true,
            favoritable: true,
            aggregateBadges: true,
            onNavigate: _openNode,
          );
        },
        body: Center(
          child: Text('Current destination: ${_destination.name}'),
        ),
      ),
    );
  }
}
```

`NavigationShell` derives the active presentation mode from the available width.
The default breakpoints are:

| Width | Mode |
|---:|---|---
| `>= 1200` | `NavSidebarMode.expanded` |
| `>= 768` and `< 1200` | `NavSidebarMode.rail` |
| `< 768` | `NavSidebarMode.drawer` |

## Navigation model

### `NavSection<T>`

A section groups top-level navigation nodes. Body sections scroll with the pane;
footer sections remain pinned near the bottom.

```dart
NavSection<String>(
  title: 'Support',
  placement: NavSectionPlacement.footer,
  items: <NavNode<String>>[
    NavNode<String>(
      id: 'help',
      label: 'Help',
      icon: Icons.help_outline,
      value: '/help',
    ),
  ],
);
```

### `NavNode<T>`

A node can be a structural branch or a navigable leaf. Its visual role is
derived from its depth and whether it has children.

| Property | Purpose |
|---|---|---
| `id` | Stable, unique identity across the full tree. |
| `label` | Visible title and primary search text. |
| `value` | Strongly typed destination payload. |
| `children` | Nested immutable nodes. |
| `icon` | Leading icon. |
| `code` | Short screen or transaction code used by search. |
| `keywords` | Hidden aliases and search terms. |
| `badge` | Count or status pill. |
| `shortcut` | Sequential chord or modifier shortcut declaration. |
| `enabled` | Displays the node but prevents activation when `false`. |
| `locked` | Permission-gates the node and prevents activation. |
| `lockMessage` | Tooltip explaining why the node is locked. |
| `status` | Informational status dot. |

`NavNode.children` and `NavSection.items` are wrapped with
`List.unmodifiable`. Their constructors are intentionally not `const`.

### Node roles

`NavNodeRole.of` resolves one of four visual roles:

| Role | Structure |
|---|---|---
| `direct` | Top-level leaf. |
| `module` | Top-level branch. |
| `group` | Nested branch. |
| `item` | Nested leaf. |

## Presentation modes

### Expanded

`NavSidebarMode.expanded` displays the full labeled tree, section titles,
optional guide connectors, badges, shortcuts, and nested disclosure controls.

### Rail

`NavSidebarMode.rail` displays an icon-only column. Hovering a branch can open a
flyout when `railFlyouts` is enabled.

### Drawer

`NavSidebarMode.drawer` renders an off-canvas pane above the current page. The
AppBar automatically shows a menu button, and successful navigation closes the
drawer.

### Custom breakpoints

```dart
const breakpoints = NavSidebarBreakpoints(
  expanded: 1366,
  rail: 720,
);

final mode = breakpoints.modeFor(MediaQuery.sizeOf(context).width);
```

Pass custom breakpoints directly to `NavigationShell`:

```dart
NavigationShell<String>(
  controller: controller,
  breakpoints: const NavSidebarBreakpoints(
    expanded: 1366,
    rail: 720,
  ),
  sidebarBuilder: buildSidebar,
  body: const SizedBox(),
);
```

## Controller

`NavigationSidebarController<T>` is the single source of truth for active,
expanded, collapsed, drawer, search, favorites, and recent state.

### Create and dispose

Keep the controller in a `State`, dependency container, or another owner with a
matching lifecycle:

```dart
late final NavigationSidebarController<String> controller;

@override
void initState() {
  super.initState();
  controller = NavigationSidebarController<String>(
    sections: sections,
    active: 'dashboard',
    expanded: <NavNodeId>{'accounting'},
    favorites: <NavNodeId>{'journal_entries'},
    maxRecents: 10,
  );
}

@override
void dispose() {
  controller.dispose();
  super.dispose();
}
```

`NavigationSidebar` can create an internal controller when only `sections` are
provided, but an external controller is recommended when other widgets or the
router need to read or change navigation state.

### Navigation

```dart
final didNavigate = controller.navigate('journal_entries');

if (didNavigate) {
  final destination = controller.activeValue;
}
```

`navigate` returns `false` when the node does not exist, is disabled, or is
locked. `NavigationSidebar.onNavigate` is invoked only after successful
navigation.

### Expansion

```dart
controller.expand('accounting');
controller.collapse('accounting');
controller.toggleNode('accounting');
controller.expandAll();
controller.collapseAll();
```

### Rail and drawer state

```dart
controller.toggleCollapsed();
controller.openDrawer();
controller.closeDrawer();
controller.toggleDrawer();
```

### Read state

```dart
final activeId = controller.active;
final activeValue = controller.activeValue;
final isOpen = controller.isExpanded('accounting');
final ownsActive = controller.ownsActive('accounting');
final node = controller.node('journal_entries');
```

### Replace the tree

Use `replaceSections` when permissions, modules, or tenant configuration changes:

```dart
controller.replaceSections(updatedSections);
```

The controller removes stale recent entries and clears the active ID when the
active node no longer exists. Duplicate IDs are asserted in debug builds.

### Access from descendants

`NavigationSidebar` publishes the controller through `NavigationSidebarScope`.
A descendant can retrieve it without manually passing it through every widget:

```dart
final controller =
    NavigationSidebarController.of<AppDestination>(context);

controller?.navigate('settings');
```

## Integrated app shell

`NavigationShell<T>` composes three surfaces:

1. An optional AppBar.
2. A responsive navigation pane.
3. The current page body.

It removes the need to manually coordinate `Row`, `Column`, `Stack`, drawer
scrims, and responsive pane widths.

### Header layout

```dart
NavigationShell<String>(
  controller: controller,
  headerLayout: NavShellHeaderLayout.spanning,
  sidebarBuilder: buildSidebar,
  appBarBuilder: buildAppBar,
  body: page,
);
```

- `spanning`: the AppBar spans the entire width above pane and content.
- `inset`: the pane occupies full height and the AppBar sits above content only.

### Pane behavior

```dart
NavigationShell<String>(
  controller: controller,
  paneBehavior: NavPaneBehavior.overlay,
  sidebarBuilder: buildSidebar,
  body: page,
);
```

- `push`: the pane takes layout space and pushes the content.
- `overlay`: a rail remains in-flow while the expanded pane floats above content.

For overlay behavior, initialize the controller with `collapsed: true` when the
pane should start closed.

### Force a mode

The shell is adaptive by default. Set `mode` only when the host application must
force a presentation:

```dart
NavigationShell<String>(
  controller: controller,
  mode: NavSidebarMode.rail,
  sidebarBuilder: buildSidebar,
  body: page,
);
```

## AppBar integration

`NavigationSidebarAppBar` is a `PreferredSizeWidget` connected directly to the
sidebar controller.

```dart
Scaffold(
  appBar: NavigationSidebarAppBar(
    controller: controller,
    mode: NavSidebarMode.drawer,
    title: const Text('Genius Link'),
    pageTitle: NavBreadcrumb<String>(controller: controller),
    globalSearch: NavigationSidebarSearchField(
      controller: controller,
    ),
    middle: const Chip(label: Text('Production')),
    actions: <Widget>[
      IconButton(
        onPressed: () {},
        icon: const Icon(Icons.notifications_outlined),
      ),
    ],
  ),
  body: const SizedBox(),
);
```

The AppBar:

- inserts a drawer menu button in drawer mode;
- can display a collapse/expand button in expanded and rail modes;
- supports title, page title, global search, middle, actions, and custom leading;
- rebuilds when the controller changes;
- can be fully replaced through `builder`.

### Back button

Bind `controller.canGoBack` to the router's current pop state:

```dart
controller.canGoBack = Navigator.of(context).canPop();

NavigationSidebarAppBar(
  controller: controller,
  mode: mode,
  showBackButton: true,
  onBack: () => Navigator.of(context).maybePop(),
);
```

The button is disabled while `canGoBack` is `false`.

### Breadcrumbs

```dart
NavBreadcrumb<String>(
  controller: controller,
  separator: ' / ',
);
```

The breadcrumb automatically reads the active node and its ancestor path.

### Search field

```dart
NavigationSidebarSearchField(
  controller: controller,
  hint: 'Search navigation',
);
```

This widget updates `controller.query`, which filters the sidebar tree.

## Search

The package provides two complementary search experiences.

### Inline tree filter

Enable the built-in field in expanded and drawer modes:

```dart
NavigationSidebar<String>(
  controller: controller,
  mode: mode,
  searchable: true,
);
```

Filtering matches `label`, `code`, and `keywords`, and keeps ancestor nodes
visible so each result remains reachable.

### Command palette

Enable the package-owned command palette:

```dart
NavigationSidebar<String>(
  controller: controller,
  mode: mode,
  allowSearchDialog: true,
  onSearchPick: (NavNode<String> node) {
    final route = node.value;
    if (route == null) return;
    // Send route to Navigator, go_router, or your routing layer.
  },
);
```

When `allowSearchDialog` and `searchable` are both `true`, the command-palette
trigger takes precedence in the sidebar chrome.

Open the palette from a custom button:

```dart
showNavSearchDialog<String>(
  context,
  controller: controller,
  hint: 'Search screens and actions…',
  recentsLabel: 'Recent',
  onPick: (NavNodeId id) {
    if (controller.navigate(id)) {
      final node = controller.node(id);
      // Update the application router from node?.value.
    }
  },
);
```

For advanced custom search interfaces, use `NavSearchOps.buildIndex` and
`NavSearchOps.filter`.

## Favorites and recent destinations

### Quick Access favorites

```dart
NavigationSidebar<String>(
  controller: controller,
  mode: mode,
  favoritable: true,
  quickAccessTitle: 'Pinned',
);
```

Programmatic operations:

```dart
controller.toggleFavorite('journal_entries');
controller.setFavorites(<NavNodeId>{'dashboard', 'journal_entries'});

final ids = controller.favorites;
final nodes = controller.favoriteNodes;
```

### Recents

Successful navigation to a leaf automatically updates a most-recently-used list:

```dart
final ids = controller.recents;
final nodes = controller.recentNodes;

controller.clearRecents();
```

The command palette displays recent destinations while its query is empty.
Control the maximum list size with `maxRecents` in the controller constructor.

## State persistence

Capture the user-owned UI state as JSON:

```dart
import 'dart:convert';

final encoded = jsonEncode(controller.snapshot().toJson());
```

Restore it after rebuilding the navigation tree:

```dart
final decoded = Map<String, Object?>.from(
  jsonDecode(encoded) as Map<dynamic, dynamic>,
);

controller.restore(NavSidebarStateSnapshot.fromJson(decoded));
```

The snapshot contains:

- active node ID;
- expanded node IDs;
- favorite node IDs;
- recent node IDs;
- collapsed rail state.

IDs that no longer exist are ignored during restore.

## Keyboard shortcuts

Declare a sequential chord:

```dart
NavNode<String>(
  id: 'dashboard',
  label: 'Dashboard',
  shortcut: const <String>['g', 'd'],
  value: '/dashboard',
);
```

Declare a modifier combination:

```dart
NavNode<String>(
  id: 'journal_entries',
  label: 'Journal entries',
  shortcut: const <String>['ctrl', 'shift', 'j'],
  value: '/journal-entries',
);
```

`NavNode.shortcut` is a visual declaration until the relevant subtree is
wrapped with `NavShortcutBinder<T>`:

```dart
NavShortcutBinder<String>(
  controller: controller,
  chordTimeout: const Duration(milliseconds: 1200),
  onNavigate: (NavNode<String> node) {
    final route = node.value;
    if (route == null) return;
    // Send route to Navigator, go_router, or your routing layer.
  },
  child: appShell,
);
```

Shortcuts are suspended while an `EditableText` has primary focus. Locked and
disabled nodes remain protected. Use `enabled: false` to temporarily suspend all
registered shortcuts, such as while a modal workflow is open.

Control how hints appear in the expanded tree:

```dart
NavigationSidebar<String>(
  controller: controller,
  mode: mode,
  shortcutMode: NavShortcutMode.onHover,
);
```

Available modes are `onHover`, `always`, and `hidden`.

## Badges, status, and permissions

### Badges

```dart
NavNode<String>(
  id: 'approvals',
  label: 'Approvals',
  badge: const NavBadge('12', tone: NavBadgeTone.danger),
  value: '/approvals',
);
```

Tones: `accent`, `success`, `warning`, `danger`, and `muted`.

Enable numeric badge aggregation to roll descendant counts up to a collapsed
module:

```dart
NavigationSidebar<String>(
  controller: controller,
  mode: mode,
  aggregateBadges: true,
);
```

### Status indicators

```dart
NavNode<String>(
  id: 'current_period',
  label: 'Current period',
  status: NavNodeStatus.open,
  value: '/period/current',
);
```

Statuses are informational only: `none`, `open`, `closed`, `locked`, and
`attention`.

### Permission-gated nodes

```dart
NavNode<String>(
  id: 'audit_log',
  label: 'Audit log',
  icon: Icons.policy_outlined,
  locked: true,
  lockMessage: 'Requires the Auditor role',
  value: '/audit-log',
);
```

A locked node is dimmed, receives lock semantics, displays its message in a
tooltip, and cannot trigger controller or host navigation.

Use `enabled: false` for temporarily unavailable destinations that are not
permission-gated.

## Localization and RTL

The package uses an immutable `NavigationSidebarLocalizations` object rather
than Flutter localization delegates. English is the default, and an Arabic
preset is included.

```dart
const arabic = NavigationSidebarLocalizations.arabic;

Directionality(
  textDirection: TextDirection.rtl,
  child: NavigationShell<String>(
    controller: controller,
    appBarBuilder: (BuildContext context, NavSidebarMode mode) {
      return NavigationSidebarAppBar(
        controller: controller,
        mode: mode,
        title: const Text('نظام المحاسبة'),
        localizations: arabic,
      );
    },
    sidebarBuilder: (BuildContext context, NavSidebarMode mode) {
      return NavigationSidebar<String>(
        controller: controller,
        mode: mode,
        localizations: arabic,
      );
    },
    body: const SizedBox(),
  ),
);
```

Create a custom translation by overriding only the required strings:

```dart
const customStrings = NavigationSidebarLocalizations(
  searchHint: 'Find a screen…',
  quickAccessTitle: 'Pinned',
  recentsTitle: 'History',
  semanticOpenDrawer: 'Open application navigation',
);
```

RTL affects drawer direction, connector geometry, flyouts, row padding, and
back-button direction.

## Theming

### Presets

```dart
const light = NavigationSidebarThemeData.light;
const dark = NavigationSidebarThemeData.dark;
```

### Customize the extension

```dart
final sidebarTheme = NavigationSidebarThemeData.light.copyWith(
  widthExpanded: 280,
  widthRail: 72,
  widthDrawer: 304,
  directHeight: 46,
  moduleHeight: 46,
  selectionIndicator: NavSelectionIndicator.bar,
  indicatorThickness: 3,
  radiusLg: 12,
);

final theme = ThemeData(
  brightness: Brightness.light,
  extensions: <ThemeExtension<dynamic>>[
    sidebarTheme,
  ],
);
```

### Color tokens

| Token | Purpose |
|---|---|---
| `bg` | Shell background. |
| `surface` | Sidebar and AppBar surface. |
| `inputBg` | Search fields, chips, and boxed icons. |
| `hover` | Hovered control fill. |
| `border` | Standard dividers and outlines. |
| `borderStrong` | Strong outlines and flyout borders. |
| `guide` | Tree connector color. |
| `fg1` | Primary foreground. |
| `fg2` | Standard labels. |
| `fg3` | Secondary labels and icons. |
| `fg4` | Muted and disabled content. |

Semantic constants are available as `accent`, `success`, `warning`, and
`danger`.

### Geometry tokens

The extension exposes row heights, sidebar widths, rail and toolbar dimensions,
icon sizes, radii, gutter spacing, selection-indicator geometry, and shell header
height. Common properties include:

```text
directHeight, moduleHeight, groupHeight, itemHeight
widthExpanded, widthRail, widthDrawer
railButton, railIconSize
iconTop, iconItem, itemBox
toolbarButtonSize, toolbarIconSize
radiusSm, radiusMd, radiusLg, radiusXl
gutter, indicatorThickness, indicatorInset, headerHeight
```

Use `NavigationSidebarThemeData.of(context)` inside custom widgets to read the
resolved extension.

The theme references `Manrope`, `Inter`, and `JetBrainsMono` by family name, but
the package does not bundle font files. Add those fonts to the host application
or allow Flutter to use its platform fallback.

## Accessibility

The sidebar includes:

- semantic button, selection, expansion, lock, and disabled states;
- Enter and Space activation for focused rows;
- tooltips for rail items, locked nodes, and shortcut hints;
- accessible labels for drawer, collapse, and back controls;
- RTL-aware navigation and directional geometry.

Keep destination labels concise and provide meaningful `lockMessage` text when
using permission-gated nodes.

## Testing

The controller can be tested without rendering the sidebar:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:super_navigation_sidebar/super_navigation_sidebar.dart';

void main() {
  test('navigate updates active destination', () {
    final controller = NavigationSidebarController<String>(
      sections: <NavSection<String>>[
        NavSection<String>(
          title: 'Main',
          items: <NavNode<String>>[
            NavNode<String>(
              id: 'dashboard',
              label: 'Dashboard',
              value: '/dashboard',
            ),
          ],
        ),
      ],
    );

    addTearDown(controller.dispose);

    expect(controller.navigate('dashboard'), isTrue);
    expect(controller.active, 'dashboard');
    expect(controller.activeValue, '/dashboard');
  });
}
```

Use `NavOps.findDuplicateIds` in tests that generate navigation trees from
permissions or remote configuration:

```dart
expect(
  NavOps.findDuplicateIds<String>(sections),
  isEmpty,
);
```

## Public API overview

| API | Purpose |
|---|---|---
| `NavigationSidebar<T>` | Renders the navigation pane. |
| `NavigationShell<T>` | Composes AppBar, pane, and page content. |
| `NavigationSidebarAppBar` | Sidebar-aware AppBar. |
| `NavBreadcrumb<T>` | Active-node breadcrumb. |
| `NavigationSidebarSearchField` | Controller-backed tree search field. |
| `NavSearchDialog<T>` | Command-palette widget. |
| `showNavSearchDialog<T>` | Opens the command palette through `Overlay`. |
| `NavShortcutBinder<T>` | Activates declared keyboard shortcuts. |
| `NavigationSidebarController<T>` | Owns all navigation state. |
| `NavigationSidebarScope<T>` | Exposes the controller to descendants. |
| `NavSidebarStateSnapshot` | JSON-serializable persisted state. |
| `NavSection<T>` | Navigation section model. |
| `NavNode<T>` | Typed navigation node model. |
| `NavNodeId` | Alias for a stable node identifier (`String`). |
| `NavBadge` | Badge model. |
| `NavSearchHit` | Flattened command-palette search result. |
| `NavSidebarBreakpoints` | Resolves a mode from width. |
| `NavigationSidebarThemeData` | Theme extension and visual tokens. |
| `NavigationSidebarLocalizations` | User-facing and semantic strings. |
| `NavOps` | Tree traversal, badge, leaf, and validation utilities. |
| `NavSearchOps` | Search indexing and filtering utilities. |
| `NavShortcutOps` | Shortcut parsing and label utilities. |
| `NavSidebarSlotBuilder` | Builder signature for sidebar header and footer slots. |
| `NavShellSlotBuilder` | Builder signature for shell surfaces. |
| `kNavShortcutModifiers` | Recognized modifier names for shortcut declarations. |

Public enums include `NavSidebarMode`, `NavNodeRole`, `NavBadgeTone`,
`NavShortcutMode`, `NavNodeStatus`, `NavSectionPlacement`,
`NavShellHeaderLayout`, `NavPaneBehavior`, and `NavSelectionIndicator`.

## Recommended practices

- Keep node IDs stable and unique across the entire tree.
- Store typed route or screen data in `NavNode<T>.value`.
- Use branches for organization and leaves for destinations.
- Keep the application router as the source of truth for page navigation.
- Keep one controller shared by the shell, sidebar, AppBar, and shortcut binder.
- Dispose externally owned controllers.
- Use `replaceSections` after permission or tenant changes.
- Persist `snapshot()` per user when navigation preferences should survive restarts.
- Use `NavigationShell` instead of duplicating responsive pane layout.
- Provide localized semantic labels and lock messages.

## Additional information

- Repository: <https://github.com/GeniusSystems24/super_navigation_sidebar>
- Issues: <https://github.com/GeniusSystems24/super_navigation_sidebar/issues>
- Changelog: [CHANGELOG.md](CHANGELOG.md)
- License: [LICENSE](LICENSE)
