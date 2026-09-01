# Codex examples — super_navigation_sidebar 3.2.0

## Adaptive host layout

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final mode = const SuperNavSidebarBreakpoints().modeFor(constraints.maxWidth);
    final sidebar = SuperNavigationSidebar<String>(
      controller: nav,
      mode: mode,
      allowSearchView: true,
> 3.0 search-field invariant: `SuperNavigationSearchView` uses `SuperTextFormField` / `SuperTextFieldController` from `super_form_field`; do not replace it with a raw Material `TextField`.
      searchViewMode: mode == SuperNavSidebarMode.drawer
          ? SuperNavigationSearchViewMode.sheet
          : SuperNavigationSearchViewMode.dialog,
      onNavigate: (node) => setState(() => active = node.value!),
    );

    if (mode == SuperNavSidebarMode.drawer) {
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
showSuperNavigationSearchView<String>(
  context,
  controller: nav,
  mode: SuperNavigationSearchViewMode.dialog,
);
```

## Sheet search

```dart
showSuperNavigationSearchView<String>(
  context,
  controller: nav,
  mode: SuperNavigationSearchViewMode.sheet,
);
```

## Embedded search

```dart
SuperNavigationSearchView<String>(
  controller: nav,
  autofocus: false,
  closeOnPick: false,
  onPick: nav.navigate,
)
```

## Searchable destination

```dart
SuperNavNode<String>(
  id: 'journal_entries',
  label: const Text('Journal entries'),
  code: 'JE01',
  keywords: const ['voucher', 'posting', 'قيد'],
  leadingIcon: const Icon(Icons.receipt_long_outlined),
  value: 'journal_entries',
)
```

## Permission gating

```dart
if (nav.navigate(id)) {
  router.go('/${nav.node(id)!.value}');
}
```

## Generated localization setup

```dart
MaterialApp(
  localizationsDelegates: SuperNavigationLocalization.localizationsDelegates,
  supportedLocales: SuperNavigationLocalization.supportedLocales,
  home: const AppRoot(),
)
```

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
