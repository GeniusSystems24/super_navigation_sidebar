# Migrating from 3.1.0 to 3.2.0

Version 3.2.0 aligns the public API with the GeniusLink `Super*` naming
convention and moves sidebar strings to Flutter generated localizations.

Most 3.1.0 apps can upgrade incrementally: old public type names remain as
typedefs, and the old `showNavigationSearchView` function forwards to
`showSuperNavigationSearchView`.

## Update dependency

```yaml
dependencies:
  super_navigation_sidebar: ^3.2.0
```

The package now expects:

```yaml
dependencies:
  super_core: ">=3.6.0 <4.0.0"
  super_form_field: ">=1.11.1 <2.0.0"
```

## Register localization delegates

Version 3.2.0 uses generated localizations from
`lib/localizations/generated`. Register the package delegates in the host app:

```dart
MaterialApp(
  localizationsDelegates: SuperNavigationLocalization.localizationsDelegates,
  supportedLocales: SuperNavigationLocalization.supportedLocales,
  home: const AppRoot(),
)
```

`SuperNavigationSidebar` resolves strings from
`SuperNavigationLocalization.of(context)` when delegates are registered. It
falls back to English when delegates are missing.

Explicit `drawerTitle`, `searchHint`, and `quickAccessTitle` values still
override localized strings.

## Replace legacy localization overrides

The `NavigationSidebarLocalizations` value object and
`lib/src/localizations.dart` were removed.

Old:

```dart
NavigationSidebar<String>(
  controller: nav,
  localizations: NavigationSidebarLocalizations.arabic,
)
```

New:

```dart
Localizations.override(
  context: context,
  locale: const Locale('ar'),
  delegates: SuperNavigationLocalization.localizationsDelegates,
  child: Directionality(
    textDirection: TextDirection.rtl,
    child: SuperNavigationSidebar<String>(
      controller: nav,
    ),
  ),
)
```

For apps that already set `locale` on `MaterialApp`, no per-widget override is
needed.

## Adopt Super-prefixed types

3.2.0 renames the public navigation/sidebar/search/theme components with a
`Super` prefix.

| 3.1.0 name | 3.2.0 name |
| --- | --- |
| `NavigationSidebar<T>` | `SuperNavigationSidebar<T>` |
| `NavigationSidebarController<T>` | `SuperNavigationSidebarController<T>` |
| `NavigationSidebarScope<T>` | `SuperNavigationSidebarScope<T>` |
| `NavigationSidebarThemeData` | `SuperNavigationSidebarThemeData` |
| `NavigationSearchView<T>` | `SuperNavigationSearchView<T>` |
| `NavigationSearchViewMode` | `SuperNavigationSearchViewMode` |
| `showNavigationSearchView<T>` | `showSuperNavigationSearchView<T>` |
| `NavNodeId` | `SuperNavNodeId` |
| `NavNode<T>` | `SuperNavNode<T>` |
| `NavSection<T>` | `SuperNavSection<T>` |
| `NavBadge` | `SuperNavBadge` |
| `NavBadgeTone` | `SuperNavBadgeTone` |
| `NavNodeStatus` | `SuperNavNodeStatus` |
| `NavNodeRole` | `SuperNavNodeRole` |
| `NavSidebarMode` | `SuperNavSidebarMode` |
| `NavSidebarBreakpoints` | `SuperNavSidebarBreakpoints` |
| `NavSectionPlacement` | `SuperNavSectionPlacement` |
| `NavSelectionIndicator` | `SuperNavSelectionIndicator` |
| `NavSidebarStateSnapshot` | `SuperNavSidebarStateSnapshot` |
| `NavSidebarSlotBuilder` | `SuperNavSidebarSlotBuilder` |
| `NavSearchHit` | `SuperNavSearchHit` |
| `NavSearchOps` | `SuperNavSearchOps` |
| `NavOps` | `SuperNavOps` |

The old names remain available as compatibility typedefs. Prefer the new names
in new code and update existing code when touching it.

## Example API update

Old:

```dart
final nav = NavigationSidebarController<String>(
  sections: <NavSection<String>>[
    NavSection(
      title: 'Workspace',
      items: [
        NavNode(
          id: 'dashboard',
          label: const Text('Dashboard'),
          leadingIcon: const Icon(Icons.dashboard_outlined),
          value: 'dashboard',
        ),
      ],
    ),
  ],
);

NavigationSidebar<String>(
  controller: nav,
  mode: NavSidebarMode.expanded,
  searchViewMode: NavigationSearchViewMode.dialog,
);
```

New:

```dart
final nav = SuperNavigationSidebarController<String>(
  sections: <SuperNavSection<String>>[
    SuperNavSection(
      title: 'Workspace',
      items: [
        SuperNavNode(
          id: 'dashboard',
          label: const Text('Dashboard'),
          leadingIcon: const Icon(Icons.dashboard_outlined),
          value: 'dashboard',
        ),
      ],
    ),
  ],
);

SuperNavigationSidebar<String>(
  controller: nav,
  mode: SuperNavSidebarMode.expanded,
  searchViewMode: SuperNavigationSearchViewMode.dialog,
);
```

## Search presenter update

Old calls still work through a forwarding wrapper:

```dart
showNavigationSearchView<String>(
  context,
  controller: nav,
);
```

Prefer the new function name:

```dart
showSuperNavigationSearchView<String>(
  context,
  controller: nav,
  mode: SuperNavigationSearchViewMode.dialog,
);
```

## Migration checklist

- Bump `super_navigation_sidebar` to `^3.2.0`.
- Register `SuperNavigationLocalization.localizationsDelegates` and
  `SuperNavigationLocalization.supportedLocales`.
- Replace `NavigationSidebarLocalizations` usage with app locale selection or
  `Localizations.override`.
- Rename old public API symbols to their `Super*` equivalents in touched code.
- Keep old names only where compatibility with existing host code is required.
- Run `flutter pub get`, `dart format`, `flutter analyze`, and relevant tests.
