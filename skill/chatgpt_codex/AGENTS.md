# Agent guide — super_navigation_sidebar 3.3.0

## Scope

Treat the package as a navigation-pane library, not an application-shell
library. Host code owns scaffolds, app bars, route transitions, back behavior,
and global shortcut handling.

## Preferred implementation pattern

1. Create one `SuperNavigationSidebarController<T>` from the typed section tree.
2. Resolve `SuperNavSidebarMode` with `SuperNavSidebarBreakpoints` in `LayoutBuilder`.
3. For expanded/rail mode, compose `SuperNavigationSidebar` beside content in a
   `Row`.
4. For drawer mode, compose content and `SuperNavigationSidebar` in a `Stack`, and
   call `controller.openDrawer()` from the host menu button.
5. Use `allowSearchView` for the package-owned search trigger.
> 3.0 search-field invariant: `SuperNavigationSearchView` uses `SuperTextFormField` / `SuperTextFieldController` from `super_form_field`; do not replace it with a raw Material `TextField`.
6. Prefer `SuperNavigationSearchViewMode.dialog` on wide layouts and `.sheet` on
   compact layouts.

## Search API

```dart
showSuperNavigationSearchView<T>(
  context,
  controller: controller,
  mode: SuperNavigationSearchViewMode.dialog,
);
```

`SuperNavigationSearchView<T>` can also be embedded directly. `SuperNavSearchOps` and
`SuperNavSearchHit` are available when custom search presentation is required.

## Sidebar API highlights

```dart
SuperNavigationSidebar<T>(
  controller: controller,
  mode: mode,
  showGuides: true,
  railFlyouts: true,
  showPaneToggle: true,
  searchable: false,
  allowSearchView: true,
  searchViewMode: SuperNavigationSearchViewMode.dialog,
  favoritable: true,
  aggregateBadges: true,
  onNavigate: (node) {},
)
```

## Localization

Use the generated localization API exported by the package barrel:

```dart
MaterialApp(
  localizationsDelegates: SuperNavigationLocalization.localizationsDelegates,
  supportedLocales: SuperNavigationLocalization.supportedLocales,
  home: const AppRoot(),
)
```

`SuperNavigationSidebar` reads `SuperNavigationLocalization` from context and has an
English fallback. Use `Localizations.override` for examples that switch between
English and Arabic inside one demo screen. Do not reintroduce
`NavigationSidebarLocalizations` or `lib/src/localizations.dart`.

## Node model

Use `code` and `keywords` to improve search. Use `badge`, `status`, `locked`,
`lockMessage`, and `enabled` for ERP/navigation state. Use `onTap` for
node-local UI actions that need `BuildContext`; it fires after successful
sidebar/search navigation and before host callbacks. Use footer sections for
persistent Settings/Help destinations.

## Controller rules

- Always check the boolean result from `navigate()` when downstream routing
  should only happen for a valid destination.
- `replaceSections()` is the supported way to update the tree after permissions
  or badge counts change.
- `recents` are updated automatically on successful leaf navigation.
- Favorites are controller state and can be surfaced through
  `favoritable: true`.
- Keep router/back-stack state in the host router.

## Avoid

- Building drawer mode inline beside content.
- Reimplementing package search when `SuperNavigationSearchView` is sufficient.
- Storing application-level keyboard commands in navigation data.
- Coupling the navigation controller to page-scaffold/back-button state.

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
