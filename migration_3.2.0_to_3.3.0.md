# Migrating from 3.2.0 to 3.3.0

Version 3.3.0 adds node-owned tap actions through `SuperNavNode.onTap`.

This is an additive release. Existing 3.2.0 apps should continue to compile
without code changes.

## Update dependency

```yaml
dependencies:
  super_navigation_sidebar: ^3.3.0
```

## What changed

`SuperNavNode` now accepts an optional context-aware callback:

```dart
void Function(BuildContext context)? onTap
```

The callback is invoked by package UI after a node is successfully activated.
It is available from sidebar rows and package search surfaces.

## Add node-owned actions

Use `onTap` when a destination owns a small UI side effect that needs
`BuildContext`, such as showing a snackbar, opening a dialog, or triggering a
node-local command.

```dart
SuperNavNode<String>(
  id: 'refresh_balances',
  label: const Text('Refresh balances'),
  leadingIcon: const Icon(Icons.sync_outlined),
  code: 'RF01',
  keywords: const ['reload', 'balances'],
  value: 'refresh_balances',
  onTap: (context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refresh queued')),
    );
  },
)
```

## Callback order

When a user activates a leaf node from `SuperNavigationSidebar`:

1. The sidebar checks that the node is enabled and not locked.
2. `SuperNavigationSidebarController.navigate(node.id)` runs.
3. If navigation succeeds, `node.onTap?.call(context)` runs.
4. The host `SuperNavigationSidebar.onNavigate` callback runs.

When a user picks a node from the sidebar-owned search view:

1. `SuperNavigationSidebarController.navigate(id)` runs.
2. If navigation succeeds, `node.onTap?.call(context)` runs.
3. `onSearchPick` runs, falling back to `onNavigate` when `onSearchPick` is
   null.

When using `SuperNavigationSearchView` directly with no custom `onPick`,
successful default navigation also invokes `node.onTap`.

If you provide a custom `onPick` to `SuperNavigationSearchView` or
`showSuperNavigationSearchView`, that callback owns the pick behavior.

## Controller behavior is unchanged

`SuperNavigationSidebarController.navigate` remains state-only and does not
invoke `onTap`, because the controller has no `BuildContext`.

This remains valid:

```dart
if (nav.navigate('refresh_balances')) {
  router.go('/refresh-balances');
}
```

If you call `navigate` manually and also want the node action, invoke it from
your UI layer:

```dart
final node = nav.node('refresh_balances');
if (node != null && nav.navigate(node.id)) {
  node.onTap?.call(context);
}
```

## `copyWith`

`SuperNavNode.copyWith` preserves the existing action when `onTap` is omitted:

```dart
final updated = node.copyWith(
  badge: const SuperNavBadge('3'),
);
```

Pass a new callback to replace it:

```dart
final updated = node.copyWith(
  onTap: (context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Updated action')),
    );
  },
);
```

## Choosing `onTap` vs `onNavigate`

Use `SuperNavNode.onTap` for node-local UI behavior that belongs to that
destination.

Use `SuperNavigationSidebar.onNavigate` for host-owned concerns such as routing,
page state, analytics, and application-level orchestration.

```dart
SuperNavigationSidebar<String>(
  controller: nav,
  onNavigate: (node) {
    router.go('/${node.value}');
  },
)
```

## New example

Version 3.3.0 adds a runnable example:

```text
example/lib/example_08_node_on_tap.dart
```

It demonstrates `SuperNavNode.onTap` with `ScaffoldMessenger` and shows that
node actions run alongside normal sidebar navigation.

## Migration checklist

- [ ] Bump `super_navigation_sidebar` to `^3.3.0`.
- [ ] Keep existing navigation code unchanged unless you want node-owned
  actions.
- [ ] Add `SuperNavNode.onTap` only for context-aware node-local behavior.
- [ ] Keep routing and page ownership in `onNavigate`.
- [ ] If calling `navigate` manually, invoke `node.onTap?.call(context)` from
  the UI layer only when you need the node action.
- [ ] Run `flutter pub get`, `dart format`, `flutter analyze`, and relevant
  tests.
