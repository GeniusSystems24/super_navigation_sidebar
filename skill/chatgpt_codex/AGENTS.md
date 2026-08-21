# Agent guide — super_navigation_sidebar 3.0.0

## Scope

Treat the package as a navigation-pane library, not an application-shell
library. Host code owns scaffolds, app bars, route transitions, back behavior,
and global shortcut handling.

## Preferred implementation pattern

1. Create one `NavigationSidebarController<T>` from the typed section tree.
2. Resolve `NavSidebarMode` with `NavSidebarBreakpoints` in `LayoutBuilder`.
3. For expanded/rail mode, compose `NavigationSidebar` beside content in a
   `Row`.
4. For drawer mode, compose content and `NavigationSidebar` in a `Stack`, and
   call `controller.openDrawer()` from the host menu button.
5. Use `allowSearchView` for the package-owned search trigger.
> 3.0 search-field invariant: `NavigationSearchView` uses `SuperTextFormField` / `SuperTextFieldController` from `super_form_field`; do not replace it with a raw Material `TextField`.
6. Prefer `NavigationSearchViewMode.dialog` on wide layouts and `.sheet` on
   compact layouts.

## Search API

```dart
showNavigationSearchView<T>(
  context,
  controller: controller,
  mode: NavigationSearchViewMode.dialog,
);
```

`NavigationSearchView<T>` can also be embedded directly. `NavSearchOps` and
`NavSearchHit` are available when custom search presentation is required.

## Sidebar API highlights

```dart
NavigationSidebar<T>(
  controller: controller,
  mode: mode,
  showGuides: true,
  railFlyouts: true,
  showPaneToggle: true,
  searchable: false,
  allowSearchView: true,
  searchViewMode: NavigationSearchViewMode.dialog,
  favoritable: true,
  aggregateBadges: true,
  onNavigate: (node) {},
)
```

## Node model

Use `code` and `keywords` to improve search. Use `badge`, `status`, `locked`,
`lockMessage`, and `enabled` for ERP/navigation state. Use footer sections for
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
- Reimplementing package search when `NavigationSearchView` is sufficient.
- Storing application-level keyboard commands in navigation data.
- Coupling the navigation controller to page-scaffold/back-button state.
