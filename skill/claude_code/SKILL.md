# super_navigation_sidebar 3.0.0

Use this package when an application needs a typed, responsive navigation pane
with expanded, rail, or drawer presentation.

## Architecture

Version 3.0 is intentionally focused:

- The host app owns `Scaffold`, app bars, routing, back navigation, and global
  keyboard commands.
- `NavigationSidebar<T>` renders the navigation pane.
- `NavigationSidebarController<T>` owns pane/navigation UI state.
- `NavigationSearchView<T>` provides reusable navigation search.
> 3.0 search-field invariant: `NavigationSearchView` uses `SuperTextFormField` / `SuperTextFieldController` from `super_form_field`; do not replace it with a raw Material `TextField`.
- Responsive page composition belongs to the host and normally uses
  `LayoutBuilder`, `Row`, and `Stack`.

## Core setup

```dart
final nav = NavigationSidebarController<String>(
  sections: <NavSection<String>>[
    NavSection(
      title: 'Workspace',
      items: [
        NavNode(
          id: 'dashboard',
          label: 'Dashboard',
          code: 'DB01',
          keywords: const ['overview', 'home'],
          icon: Icons.dashboard_outlined,
          value: 'dashboard',
        ),
      ],
    ),
  ],
  active: 'dashboard',
);
```

## Responsive composition

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final mode = const NavSidebarBreakpoints().modeFor(constraints.maxWidth);

    if (mode == NavSidebarMode.drawer) {
      return Stack(
        children: [
          Positioned.fill(child: page),
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
        Expanded(child: page),
      ],
    );
  },
);
```

For drawer mode, the host opens the pane with `nav.openDrawer()` and the
`NavigationSidebar` must be layered over content in a `Stack`.

## Search

There are two search patterns:

1. `searchable: true` filters the visible tree in place.
2. `allowSearchView: true` adds a search trigger that opens the reusable search
   UI using `searchViewMode`.

Open search imperatively:

```dart
showNavigationSearchView<String>(
  context,
  controller: nav,
  mode: NavigationSearchViewMode.dialog,
);
```

For compact/mobile layouts use `NavigationSearchViewMode.sheet`.

Embed the search surface directly:

```dart
NavigationSearchView<String>(
  controller: nav,
  autofocus: false,
  closeOnPick: false,
  onPick: nav.navigate,
)
```

Search matches labels, `code`, `keywords`, module labels, and group labels.
Recent destinations are displayed while the query is empty.

## Controller behavior

Useful operations:

```dart
nav.navigate('journals');
nav.expand('finance');
nav.collapse('finance');
nav.toggleCollapsed();
nav.openDrawer();
nav.closeDrawer();
nav.toggleFavorite('journals');
nav.clearRecents();
nav.setQuery('voucher');
nav.replaceSections(updatedSections);
```

`navigate()` returns `false` for missing, locked, or disabled nodes.

## Node capabilities

Use:

- `code` for screen/transaction codes.
- `keywords` for hidden aliases and multilingual terms.
- `badge` for counts/status chips.
- `locked` + `lockMessage` for permission-gated destinations.
- `enabled` for temporarily unavailable destinations.
- `status` for informational state dots.
- `NavSectionPlacement.footer` for pinned footer navigation.

## Favorites and recents

Enable Quick Access with `favoritable: true`. The controller exposes
`favorites`, `favoriteNodes`, `recents`, and `recentNodes`.

## Theming and localization

Prefer registering `NavigationSidebarThemeData.fromMaterialTheme(...)` when the
host uses `super_core`. Use `NavigationSidebarLocalizations.arabic` with RTL
Arabic layouts.

## 3.0 rules

- Keep application chrome outside this package.
- Keep application/router back state outside the navigation controller.
- Register global shortcuts in the host command layer, not in navigation nodes.
- Prefer dialog search on wide layouts and sheet search on compact layouts.
- Do not place drawer mode inline in a `Row`; layer it over content.
