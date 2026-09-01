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

## Version 3.1.0 navigation content rules

When working with `NavNode` or navigation search results, follow these rules:

- `NavNode.label` is a `Widget`, not a `String`.
- `NavNode.leadingIcon` is `Widget?`.
- `NavNode.trailingIcon` is `Widget?`.
- `NavNode.keywords` is `List<String>` and defaults to an empty list.
- `NavSearchHit.label` is a `Widget`.
- `NavSearchHit.leadingIcon` and `NavSearchHit.trailingIcon` are Widgets.
- `NavSearchHit.keywords` is a non-nullable `List<String>`.
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
NavNode(
  label: const Text('Settings'),
  leadingIcon: const Icon(Icons.settings_outlined),
  keywords: const ['settings', 'preferences'],
)
```

For a custom label:

```dart
NavNode(
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
NavNode(
  label: 'Settings',
  icon: Icons.settings,
)
```

New:

```dart
NavNode(
  label: const Text('Settings'),
  leadingIcon: const Icon(Icons.settings),
)
```

If search previously depended on `label`, move the searchable text into
`keywords` instead of reading text from the Widget.
