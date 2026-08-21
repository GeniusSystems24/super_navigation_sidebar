# Migration Guide: 2.4.2 → 3.0.0

This guide covers the breaking changes required to migrate
`super_navigation_sidebar` from `2.4.2` to `3.0.0`.

Version `3.0.0` removes the legacy shell, app-bar, and shortcut-binding layers
and replaces the old navigation search flow with the reusable
`NavigationSearchView`.

## 1. Update dependencies

Update your `pubspec.yaml`:

```yaml
dependencies:
  super_navigation_sidebar: ^3.0.0
  super_form_field: ">=1.10.0 <2.0.0"
```

Then run:

```bash
flutter pub get
```

`super_navigation_sidebar` now uses `super_form_field` for the search input
inside `NavigationSearchView`.

## 2. Removed APIs

The following public APIs were removed in `3.0.0`:

- `NavigationShell`
- `NavigationSidebarAppBar`
- `NavShortcutBinder`

The cleanup also removes APIs that existed only to support those components,
including legacy shell layout helpers, app-bar-only state, shortcut metadata,
shortcut hint modes, and related presentation widgets.

If your application imports any of those APIs directly, remove those imports
and migrate to the controller/sidebar/search APIs described below.

## 3. Remove `NavigationShell`

### Before

```dart
NavigationShell(
  sidebar: NavigationSidebar(
    controller: controller,
    items: items,
  ),
  body: currentPage,
)
```

### After

Compose the layout directly:

```dart
Row(
  children: [
    NavigationSidebar(
      controller: controller,
      items: items,
    ),
    Expanded(
      child: currentPage,
    ),
  ],
)
```

`NavigationSidebar` remains responsible for navigation UI and selection.
Your application remains responsible for composing the sidebar with the page
content.

This makes the package less opinionated and avoids forcing a specific
application shell structure.

## 4. Remove `NavigationSidebarAppBar`

`NavigationSidebarAppBar` is no longer part of the package.

Use your application's normal `AppBar`, custom header, or page-level toolbar.

### Before

```dart
Scaffold(
  appBar: NavigationSidebarAppBar(
    controller: controller,
    title: 'Dashboard',
  ),
  body: page,
)
```

### After

```dart
Scaffold(
  appBar: AppBar(
    title: const Text('Dashboard'),
  ),
  body: page,
)
```

If your previous app bar displayed navigation-specific state, read that state
from your navigation controller and render it in your own header.

## 5. Remove `NavShortcutBinder`

Keyboard shortcut binding is no longer wrapped by `NavShortcutBinder`.

If your application requires global shortcuts, define them at the application
or feature level using Flutter's `Shortcuts`, `Actions`, and `Intent` APIs.

### Before

```dart
NavShortcutBinder(
  controller: controller,
  child: app,
)
```

### After

```dart
Shortcuts(
  shortcuts: const <ShortcutActivator, Intent>{
    // Define application-specific shortcuts here.
  },
  child: Actions(
    actions: <Type, Action<Intent>>{
      // Define application-specific actions here.
    },
    child: app,
  ),
)
```

Navigation search keyboard handling is built into `NavigationSearchView`, so
you do not need a global shortcut binder to navigate its result list.

## 6. New `NavigationSearchView`

`3.0.0` introduces:

```dart
NavigationSearchView<T>
```

Use it when you need a reusable navigation search UI.

The view supports:

- filtering navigation destinations;
- grouped results;
- recent results;
- keyboard navigation;
- automatic scrolling to the focused result;
- Enter-to-select behavior;
- mouse/touch selection;
- dialog presentation;
- bottom-sheet presentation;
- `super_form_field` styling and behavior.

## 7. Search input now uses `super_form_field`

The search field inside `NavigationSearchView` now uses:

```dart
SuperTextFormField
```

with a `SuperTextFieldController`.

The search field is configured for navigation search behavior, including:

- `FieldDensity.compact`;
- `clearable: true`;
- `TextInputAction.search`;
- configurable autofocus;
- disabled autocorrect;
- disabled text suggestions.

`NavigationSearchView` provides the required `SuperFormLocalizations` around
its internal search field, so applications do not need to add localization
delegates only for this component.

## 8. Open search as a dialog

Use `showNavigationSearchView` with dialog mode:

```dart
final result = await showNavigationSearchView<MyNavigationItem>(
  context: context,
  mode: NavigationSearchViewMode.dialog,
  items: items,
);

if (result != null) {
  // Handle the selected navigation item.
}
```

Dialog mode is recommended for desktop and larger layouts.

## 9. Open search as a bottom sheet

Use sheet mode on mobile or compact layouts:

```dart
final result = await showNavigationSearchView<MyNavigationItem>(
  context: context,
  mode: NavigationSearchViewMode.sheet,
  items: items,
);

if (result != null) {
  // Handle the selected navigation item.
}
```

`NavigationSearchViewMode` provides:

```dart
NavigationSearchViewMode.dialog
NavigationSearchViewMode.sheet
```

## 10. Embed `NavigationSearchView` directly

The search view is not limited to overlays.

You can render it directly inside a page:

```dart
NavigationSearchView<MyNavigationItem>(
  items: items,
  onSelected: (item) {
    // Navigate to item.
  },
)
```

This is useful for command-center, search, launcher, and navigation-management
screens.

## 11. Sidebar search integration

`NavigationSidebar` can expose the new search experience directly.

Relevant configuration includes:

```dart
NavigationSidebar(
  controller: controller,
  items: items,
  allowSearchView: true,
  searchViewMode: NavigationSearchViewMode.dialog,
)
```

For compact/mobile layouts:

```dart
NavigationSidebar(
  controller: controller,
  items: items,
  allowSearchView: true,
  searchViewMode: NavigationSearchViewMode.sheet,
)
```

This replaces the legacy search-dialog-specific flow.

## 12. Keyboard navigation behavior

`NavigationSearchView` supports keyboard navigation through the visible
results.

Typical behavior:

- `ArrowDown` selects the next result.
- `ArrowUp` selects the previous result.
- `Enter` activates the selected result.
- navigation wraps between the first and last result when applicable.

Starting with `3.0.0`, when keyboard focus moves to the next or previous
result, the result list automatically scrolls to keep that item visible.

The implementation uses the appropriate alignment policy based on navigation
direction:

```dart
ScrollPositionAlignmentPolicy.keepVisibleAtStart
ScrollPositionAlignmentPolicy.keepVisibleAtEnd
```

This also works when wrapping from the last result to the first result or from
the first result to the last result.

## 13. Replace legacy navigation search widgets

If your `2.4.2` code uses the old search-field or search-dialog components,
replace them with `NavigationSearchView`.

### Before

```dart
NavigationSidebarSearchField(
  // legacy search configuration
)
```

### After

```dart
NavigationSearchView<MyNavigationItem>(
  items: items,
  onSelected: onSelected,
)
```

For an overlay:

```dart
await showNavigationSearchView<MyNavigationItem>(
  context: context,
  mode: NavigationSearchViewMode.dialog,
  items: items,
);
```

## 14. Breadcrumb and app-bar-only APIs

Legacy APIs that existed specifically for `NavigationSidebarAppBar` or
`NavigationShell` should be removed from application code.

For example, if your application depended on package-managed breadcrumb or
back-button state, move that state into your page/router layer and render it
with your own widgets.

A typical replacement is:

```dart
AppBar(
  leading: canPop
      ? IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        )
      : null,
  title: Text(currentTitle),
)
```

The package no longer owns application-level breadcrumb or shell behavior.

## 15. Example application changes

The example application in `3.0.0` was updated to demonstrate the new API.

Changes include:

- removal of the old shell example;
- removal of the old navigation app-bar example;
- removal of shortcut-binder examples;
- a dedicated `NavigationSearchView` example screen;
- dialog search example;
- bottom-sheet search example;
- embedded search example;
- keyboard navigation with automatic scrolling.

The visual style of `example/lib/main.dart` remains unchanged. The existing
launcher layout, hero header, cards, hover effects, theme toggle, and visual
language are preserved.

## 16. Recommended migration sequence

Use the following order when upgrading an application:

1. Update `super_navigation_sidebar` to `^3.0.0`.
2. Add a compatible `super_form_field` dependency.
3. Run `flutter pub get`.
4. Remove `NavigationShell`.
5. Replace `NavigationSidebarAppBar` with your application header/AppBar.
6. Remove `NavShortcutBinder`.
7. Remove old search-field/search-dialog usage.
8. Add `NavigationSearchView` where navigation search is required.
9. Choose `dialog` or `sheet` presentation per platform/layout.
10. Run formatting, analysis, and tests.

## 17. Validation commands

After migration, run:

```bash
dart format lib example/lib test
flutter analyze
flutter test
```

Also search your source tree for removed APIs:

```text
NavigationShell
NavigationSidebarAppBar
NavShortcutBinder
NavigationSidebarSearchField
```

No production references to those legacy APIs should remain.

## 18. Complete layout example

A typical `3.0.0` application layout can look like this:

```dart
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.controller,
    required this.items,
    required this.page,
  });

  final NavigationSidebarController controller;
  final List<MyNavigationItem> items;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationSidebar(
            controller: controller,
            items: items,
            allowSearchView: true,
            searchViewMode: NavigationSearchViewMode.dialog,
          ),
          Expanded(
            child: page,
          ),
        ],
      ),
    );
  }
}
```

For a mobile layout, switch the search presentation to:

```dart
searchViewMode: NavigationSearchViewMode.sheet,
```

## 19. Summary

The main architectural change in `3.0.0` is separation of concerns.

`super_navigation_sidebar` now focuses on:

- sidebar navigation;
- navigation state;
- navigation search;
- reusable navigation UI.

Your application owns:

- the application shell;
- the app bar/header;
- global shortcuts;
- page routing;
- breadcrumb presentation.

The new `NavigationSearchView` replaces the old search-specific components
with one reusable search surface that can be embedded directly or presented as
a dialog or bottom sheet.
