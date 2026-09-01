# super_navigation_sidebar 3.2.0 examples

## 1. Desktop / tablet pane

```dart
Row(
  children: [
    SuperNavigationSidebar<String>(
      controller: nav,
      mode: SuperNavSidebarMode.expanded,
      showPaneToggle: true,
      favoritable: true,
      allowSearchView: true,
> 3.0 search-field invariant: `SuperNavigationSearchView` uses `SuperTextFormField` / `SuperTextFieldController` from `super_form_field`; do not replace it with a raw Material `TextField`.
      searchViewMode: SuperNavigationSearchViewMode.dialog,
      onNavigate: (node) => router.go('/${node.value}'),
    ),
    Expanded(child: page),
  ],
)
```

## 2. Mobile drawer

```dart
Stack(
  children: [
    Positioned.fill(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: nav.openDrawer,
          ),
        ),
        body: page,
      ),
    ),
    Positioned.fill(
      child: SuperNavigationSidebar<String>(
        controller: nav,
        mode: SuperNavSidebarMode.drawer,
        allowSearchView: true,
        searchViewMode: SuperNavigationSearchViewMode.sheet,
      ),
    ),
  ],
)
```

## 3. Search dialog

```dart
await showSuperNavigationSearchView<String>(
  context,
  controller: nav,
  mode: SuperNavigationSearchViewMode.dialog,
  onPick: (id) {
    if (nav.navigate(id)) {
      router.go('/${nav.node(id)?.value}');
    }
  },
);
```

## 4. Search sheet

```dart
await showSuperNavigationSearchView<String>(
  context,
  controller: nav,
  mode: SuperNavigationSearchViewMode.sheet,
);
```

## 5. Embedded search

```dart
SizedBox(
  height: 520,
  child: SuperNavigationSearchView<String>(
    controller: nav,
    autofocus: false,
    closeOnPick: false,
    onPick: nav.navigate,
  ),
)
```

## 6. Rich navigation metadata

```dart
SuperNavNode<String>(
  id: 'journals',
  label: const Text('Journal entries'),
  code: 'JE01',
  keywords: const ['voucher', 'posting', 'قيد يومية'],
  leadingIcon: const Icon(Icons.receipt_long_outlined),
  badge: const SuperNavBadge('9', tone: SuperNavBadgeTone.warning),
  status: SuperNavNodeStatus.open,
  value: 'journals',
)
```

## 7. Locked destination

```dart
SuperNavNode<String>(
  id: 'year_end',
  label: const Text('Year-end close'),
  leadingIcon: const Icon(Icons.lock_outline),
  locked: true,
  lockMessage: 'Requires Controller role',
  value: 'year_end',
)
```

## 8. Footer navigation

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

## 9. Generated localization setup

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
