# Migration guide: 3.0.0 to 3.1.0

Version `3.1.0` changes navigation node content from text/icon data to Widgets.

This is a breaking API update for code that directly creates, renders, searches,
or copies `NavNode` and navigation search results.

## Summary

| API | 3.0.0 | 3.1.0 |
| --- | --- | --- |
| `NavNode.label` | `String` | `Widget` |
| `NavNode.icon` | `IconData?` | Removed |
| `NavNode.leadingIcon` | Not available | `Widget?` |
| `NavNode.trailingIcon` | Not available | `Widget?` |
| `NavNode.keywords` | `List<String>?` | `List<String>` |
| `NavSearchHit.label` | `String` | `Widget` |
| `NavSearchHit.icon` | `IconData?` | Removed |
| `NavSearchHit.leadingIcon` | Not available | `Widget?` |
| `NavSearchHit.trailingIcon` | Not available | `Widget?` |
| `NavSearchHit.keywords` | `List<String>?` | `List<String>` |

## 1. Migrate labels

### Before

```dart
NavNode(
  label: 'Dashboard',
)
```

### After

```dart
NavNode(
  label: const Text('Dashboard'),
)
```

`label` can now be any Widget.

```dart
NavNode(
  label: Row(
    mainAxisSize: MainAxisSize.min,
    children: const [
      Text('Inbox'),
      SizedBox(width: 8),
      Badge(label: Text('4')),
    ],
  ),
)
```

Do not assume the new label is `Text`. It may be a completely custom Widget.

## 2. Migrate icons

### Before

```dart
NavNode(
  label: 'Dashboard',
  icon: Icons.dashboard_outlined,
)
```

### After

```dart
NavNode(
  label: const Text('Dashboard'),
  leadingIcon: const Icon(Icons.dashboard_outlined),
)
```

`leadingIcon` is a Widget, so it can contain custom visual content.

```dart
NavNode(
  label: const Text('Profile'),
  leadingIcon: const CircleAvatar(
    radius: 12,
    child: Icon(Icons.person_outline, size: 16),
  ),
)
```

Do not convert `leadingIcon` back to `IconData`.

## 3. Add trailing content when needed

Version `3.1.0` adds `trailingIcon`.

```dart
NavNode(
  label: const Text('Notifications'),
  leadingIcon: const Icon(Icons.notifications_outlined),
  trailingIcon: const Badge(
    label: Text('12'),
  ),
)
```

Despite the property name, `trailingIcon` accepts any Widget.

## 4. Migrate keywords

`keywords` is now non-nullable.

### Before

```dart
final List<String>? keywords;
```

### After

```dart
final List<String> keywords;
```

When creating a `NavNode`, you can still omit the value because the constructor
uses an empty list by default.

```dart
NavNode(
  label: const Text('About'),
)
```

Equivalent behavior:

```dart
NavNode(
  label: const Text('About'),
  keywords: const [],
)
```

Code that previously used null-aware access should be simplified.

### Before

```dart
node.keywords?.contains(query) ?? false
```

### After

```dart
node.keywords.contains(query)
```

## 5. Search must use keywords

A Widget label cannot reliably be converted to searchable text.

Do not add helpers that inspect a Widget, check whether it is `Text`, or call
`toString()` to recover a label.

### Before

```dart
node.label.toLowerCase().contains(query.toLowerCase())
```

### After

```dart
node.keywords.any(
  (keyword) => keyword.toLowerCase().contains(query.toLowerCase()),
)
```

Provide suitable keywords when a node should be searchable.

```dart
NavNode(
  label: const Text('Customer Accounts'),
  leadingIcon: const Icon(Icons.people_outline),
  keywords: const [
    'customer accounts',
    'customers',
    'accounts',
  ],
)
```

## 6. Render Widgets directly

If internal or application code previously wrapped a navigation label or icon,
remove that extra conversion.

### Before

```dart
Text(node.label)
Icon(node.icon)
```

### After

```dart
node.label
node.leadingIcon ?? const SizedBox.shrink()
```

If you need styling that must be controlled by the navigation component, place
the Widget inside a suitable wrapper such as `IconTheme`, `DefaultTextStyle`,
`Theme`, or another inherited styling widget rather than converting the content
back to primitive data.

## 7. Update `copyWith`

The stored `keywords` field is non-nullable, but the `copyWith` parameter can
remain nullable so `null` means "keep the existing value".

```dart
NavNode<T> copyWith({
  Widget? label,
  Widget? leadingIcon,
  Widget? trailingIcon,
  List<String>? keywords,
}) {
  return NavNode<T>(
    label: label ?? this.label,
    leadingIcon: leadingIcon ?? this.leadingIcon,
    trailingIcon: trailingIcon ?? this.trailingIcon,
    keywords: keywords ?? this.keywords,
  );
}
```

Apply the same pattern to `NavSearchHit`.

## 8. Update tests and examples

Replace old constructors:

```dart
NavNode(
  label: 'Home',
  icon: Icons.home,
)
```

with:

```dart
NavNode(
  label: const Text('Home'),
  leadingIcon: const Icon(Icons.home),
)
```

For searchable items, add `keywords` explicitly.

```dart
NavNode(
  label: const Text('Home'),
  leadingIcon: const Icon(Icons.home),
  keywords: const ['home', 'dashboard'],
)
```

## Checklist

- [ ] Replace string `label` values with Widgets.
- [ ] Replace `icon:` with `leadingIcon:`.
- [ ] Wrap old `IconData` values with `Icon`.
- [ ] Add `trailingIcon` where trailing navigation content is required.
- [ ] Treat `keywords` as non-nullable.
- [ ] Remove null-aware keyword access.
- [ ] Search using `keywords`, not `label`.
- [ ] Render labels and icons directly as Widgets.
- [ ] Remove Widget-to-String conversion helpers.
- [ ] Remove Widget-to-IconData conversion helpers.
- [ ] Update tests and examples.
