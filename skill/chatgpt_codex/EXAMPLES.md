# Codex examples — super_navigation_sidebar 3.0.0

## Adaptive host layout

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final mode = const NavSidebarBreakpoints().modeFor(constraints.maxWidth);
    final sidebar = NavigationSidebar<String>(
      controller: nav,
      mode: mode,
      allowSearchView: true,
> 3.0 search-field invariant: `NavigationSearchView` uses `SuperTextFormField` / `SuperTextFieldController` from `super_form_field`; do not replace it with a raw Material `TextField`.
      searchViewMode: mode == NavSidebarMode.drawer
          ? NavigationSearchViewMode.sheet
          : NavigationSearchViewMode.dialog,
      onNavigate: (node) => setState(() => active = node.value!),
    );

    if (mode == NavSidebarMode.drawer) {
      return Stack(
        children: [
          Positioned.fill(child: page),
          Positioned.fill(child: sidebar),
        ],
      );
    }

    return Row(children: [sidebar, Expanded(child: page)]);
  },
)
```

## Dialog search

```dart
showNavigationSearchView<String>(
  context,
  controller: nav,
  mode: NavigationSearchViewMode.dialog,
);
```

## Sheet search

```dart
showNavigationSearchView<String>(
  context,
  controller: nav,
  mode: NavigationSearchViewMode.sheet,
);
```

## Embedded search

```dart
NavigationSearchView<String>(
  controller: nav,
  autofocus: false,
  closeOnPick: false,
  onPick: nav.navigate,
)
```

## Searchable destination

```dart
NavNode<String>(
  id: 'journal_entries',
  label: 'Journal entries',
  code: 'JE01',
  keywords: const ['voucher', 'posting', 'قيد'],
  icon: Icons.receipt_long_outlined,
  value: 'journal_entries',
)
```

## Permission gating

```dart
if (nav.navigate(id)) {
  router.go('/${nav.node(id)!.value}');
}
```
