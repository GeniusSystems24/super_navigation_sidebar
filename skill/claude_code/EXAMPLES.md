# super_navigation_sidebar 3.0.0 examples

## 1. Desktop / tablet pane

```dart
Row(
  children: [
    NavigationSidebar<String>(
      controller: nav,
      mode: NavSidebarMode.expanded,
      showPaneToggle: true,
      favoritable: true,
      allowSearchView: true,
> 3.0 search-field invariant: `NavigationSearchView` uses `SuperTextFormField` / `SuperTextFieldController` from `super_form_field`; do not replace it with a raw Material `TextField`.
      searchViewMode: NavigationSearchViewMode.dialog,
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
      child: NavigationSidebar<String>(
        controller: nav,
        mode: NavSidebarMode.drawer,
        allowSearchView: true,
        searchViewMode: NavigationSearchViewMode.sheet,
      ),
    ),
  ],
)
```

## 3. Search dialog

```dart
await showNavigationSearchView<String>(
  context,
  controller: nav,
  mode: NavigationSearchViewMode.dialog,
  onPick: (id) {
    if (nav.navigate(id)) {
      router.go('/${nav.node(id)?.value}');
    }
  },
);
```

## 4. Search sheet

```dart
await showNavigationSearchView<String>(
  context,
  controller: nav,
  mode: NavigationSearchViewMode.sheet,
);
```

## 5. Embedded search

```dart
SizedBox(
  height: 520,
  child: NavigationSearchView<String>(
    controller: nav,
    autofocus: false,
    closeOnPick: false,
    onPick: nav.navigate,
  ),
)
```

## 6. Rich navigation metadata

```dart
NavNode<String>(
  id: 'journals',
  label: 'Journal entries',
  code: 'JE01',
  keywords: const ['voucher', 'posting', 'قيد يومية'],
  icon: Icons.receipt_long_outlined,
  badge: const NavBadge('9', tone: NavBadgeTone.warning),
  status: NavNodeStatus.open,
  value: 'journals',
)
```

## 7. Locked destination

```dart
NavNode<String>(
  id: 'year_end',
  label: 'Year-end close',
  icon: Icons.lock_outline,
  locked: true,
  lockMessage: 'Requires Controller role',
  value: 'year_end',
)
```

## 8. Footer navigation

```dart
NavSection<String>(
  title: 'System',
  placement: NavSectionPlacement.footer,
  items: [
    NavNode(
      id: 'settings',
      label: Text('Settings'),
      leadingIcon: Icon(Icons.settings_outlined),
      value: 'settings',
    ),
  ],
)
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
