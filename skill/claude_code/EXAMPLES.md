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
      label: 'Settings',
      icon: Icons.settings_outlined,
      value: 'settings',
    ),
  ],
)
```
