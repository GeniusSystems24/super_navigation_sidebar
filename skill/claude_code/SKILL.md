# super_navigation_sidebar 3.3.0

Use this package when an application needs a typed, responsive navigation pane
with expanded, rail, or drawer presentation.

## Architecture

Version 3.0 is intentionally focused:

- The host app owns `Scaffold`, app bars, routing, back navigation, and global
  keyboard commands.
- `SuperNavigationSidebar<T>` renders the navigation pane.
- `SuperNavigationSidebarController<T>` owns pane/navigation UI state.
- `SuperNavigationSearchView<T>` provides reusable navigation search.
> 3.0 search-field invariant: `SuperNavigationSearchView` uses `SuperTextFormField` / `SuperTextFieldController` from `super_form_field`; do not replace it with a raw Material `TextField`.
- Responsive page composition belongs to the host and normally uses
  `LayoutBuilder`, `Row`, and `Stack`.

## Core setup

```dart
final nav = SuperNavigationSidebarController<String>(
  sections: <SuperNavSection<String>>[
    SuperNavSection(
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
    final mode = const SuperNavSidebarBreakpoints().modeFor(constraints.maxWidth);

    if (mode == SuperNavSidebarMode.drawer) {
      return Stack(
        children: [
          Positioned.fill(child: page),
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
        Expanded(child: page),
      ],
    );
  },
);
```

For drawer mode, the host opens the pane with `nav.openDrawer()` and the
`SuperNavigationSidebar` must be layered over content in a `Stack`.

## Search

There are two search patterns:

1. `searchable: true` filters the visible tree in place.
2. `allowSearchView: true` adds a search trigger that opens the reusable search
   UI using `searchViewMode`.

Open search imperatively:

```dart
showSuperNavigationSearchView<String>(
  context,
  controller: nav,
  mode: SuperNavigationSearchViewMode.dialog,
);
```

For compact/mobile layouts use `SuperNavigationSearchViewMode.sheet`.

Embed the search surface directly:

```dart
SuperNavigationSearchView<String>(
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
- `onTap` for node-local UI actions that require `BuildContext`; it fires after
  successful sidebar/search navigation and before host callbacks.
- `SuperNavSectionPlacement.footer` for pinned footer navigation.

## Favorites and recents

Enable Quick Access with `favoritable: true`. The controller exposes
`favorites`, `favoriteNodes`, `recents`, and `recentNodes`.

## Theming and localization

Prefer registering `SuperNavigationSidebarThemeData.fromMaterialTheme(...)` when the
host uses `super_core`. Register
`SuperNavigationLocalization.localizationsDelegates` and
`SuperNavigationLocalization.supportedLocales` in the host `MaterialApp`.
Use Flutter locale selection or `Localizations.override` for RTL Arabic
examples.

```dart
MaterialApp(
  localizationsDelegates: SuperNavigationLocalization.localizationsDelegates,
  supportedLocales: SuperNavigationLocalization.supportedLocales,
  home: const AppRoot(),
)
```

`SuperNavigationSidebar` resolves generated strings from context and falls back to
English when the host has not registered delegates yet. Do not reintroduce
`lib/src/localizations.dart` or `NavigationSidebarLocalizations`.

## 3.0 rules

- Keep application chrome outside this package.
- Keep application/router back state outside the navigation controller.
- Register global shortcuts in the host command layer, not in navigation nodes.
- Prefer dialog search on wide layouts and sheet search on compact layouts.
- Do not place drawer mode inline in a `Row`; layer it over content.

## SuperNavNode widget API

When creating navigation nodes, use widgets directly:

```dart
SuperNavNode(
  label: const Text('Dashboard'),
  leadingIcon: const Icon(Icons.dashboard_outlined),
  trailingIcon: const Icon(Icons.chevron_right),
)
```

Rules:

- `label` is a required `Widget`.
- `leadingIcon` is an optional `Widget`.
- `trailingIcon` is an optional `Widget`.
- Do not pass a `String` directly to `label`; wrap text with `Text`.
- Do not use the removed `icon` argument; use `leadingIcon`.
- Omit optional positions instead of inserting placeholder widgets.

## Version 3.1.0 navigation content rules

When working with `SuperNavNode` or navigation search results, follow these rules:

- `SuperNavNode.label` is a `Widget`, not a `String`.
- `SuperNavNode.leadingIcon` is `Widget?`.
- `SuperNavNode.trailingIcon` is `Widget?`.
- `SuperNavNode.keywords` is `List<String>` and defaults to an empty list.
- `SuperNavSearchHit.label` is a `Widget`.
- `SuperNavSearchHit.leadingIcon` and `SuperNavSearchHit.trailingIcon` are Widgets.
- `SuperNavSearchHit.keywords` is a non-nullable `List<String>`.
- Render label and icon Widgets directly.
- Never assume the label is `Text`.
- Never call `toString()` on a label for search or display behavior.
- Never introduce helpers that attempt to extract `String` from an arbitrary
  Widget.
- Never convert navigation icon Widgets back to `IconData`.
- Use `keywords` for search, matching, indexing, and text-only navigation
  metadata.

### Creating navigation nodes

For a plain text label:

```dart
SuperNavNode(
  label: const Text('Settings'),
  leadingIcon: const Icon(Icons.settings_outlined),
  keywords: const ['settings', 'preferences'],
)
```

For a custom label:

```dart
SuperNavNode(
  label: Row(
    mainAxisSize: MainAxisSize.min,
    children: const [
      Text('Messages'),
      SizedBox(width: 8),
      Badge(label: Text('3')),
    ],
  ),
  leadingIcon: const Icon(Icons.chat_bubble_outline),
  keywords: const ['messages', 'chat'],
)
```

### Migration rule

Old:

```dart
SuperNavNode(
  label: 'Settings',
  icon: Icons.settings,
)
```

New:

```dart
SuperNavNode(
  label: const Text('Settings'),
  leadingIcon: const Icon(Icons.settings),
)
```

If search previously depended on `label`, move the searchable text into
`keywords` instead of reading text from the Widget.
