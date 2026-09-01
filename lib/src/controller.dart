// ============================================================
// SuperNavigationSidebar — CONTROLLER.
// ------------------------------------------------------------
// The single source of truth for the sidebar, as a ChangeNotifier. The view
// (SuperNavigationSidebar) is a thin render of this state and forwards every gesture
// to it. The controller is also published to descendants via an
// InheritedNotifier scope, so page content can drive the nav:
//
//   final nav = SuperNavigationSidebarController.of<String>(context);
//   nav?.navigate('settingsHub');
//
// Holds: the immutable section forest, the active node id, the expanded-module
// set (auto-opening the active node's ancestors), the collapsed (rail) flag,
// the mobile-drawer open flag, and an optional search query for the filter.
//
// NAVIGATION SAFETY
// -----------------
// navigate() now returns a bool indicating whether navigation was actually
// applied. It returns false (and is a no-op) for locked or disabled nodes.
// The sidebar's onNavigate callback is only fired when navigate() returns true,
// so host apps never receive callbacks for gated destinations.
//
// DUPLICATE ID VALIDATION
// -----------------------
// In debug builds the controller asserts that every SuperNavNode.id is unique
// across the entire tree. A duplicate triggers an assertion failure with a
// clear message listing the offending ids. Call SuperNavOps.findDuplicateIds() for
// a programmatic check in tests or host-side validation.
//
//   File: lib/src/controller.dart
// ============================================================

import 'package:flutter/widgets.dart';
import 'models.dart';

String _plainNodeLabel<T>(SuperNavNode<T> node) {
  final label = node.label;
  if (label is Text) {
    return label.data ?? label.textSpan?.toPlainText() ?? node.id;
  }
  return node.keywords.isNotEmpty ? node.keywords.first : node.id;
}

class SuperNavigationSidebarController<T> extends ChangeNotifier {
  SuperNavigationSidebarController({
    required List<SuperNavSection<T>> sections,
    SuperNavNodeId? active,
    Set<SuperNavNodeId>? expanded,
    Set<SuperNavNodeId>? favorites,
    List<SuperNavNodeId>? recents,
    this.maxRecents = 8,
    bool collapsed = false,
    bool drawerOpen = false,
    bool autoExpandActive = true,
  }) : _sections = List.unmodifiable(sections),
       _active = active,
       _expanded = {...?expanded},
       _favorites = {...?favorites},
       _recents = [...?recents],
       _collapsed = collapsed,
       _drawerOpen = drawerOpen,
       _autoExpandActive = autoExpandActive {
    assert(
      _debugAssertNoDuplicates(_sections),
      // Message is produced inside _debugAssertNoDuplicates via assert().
    );
    if (_autoExpandActive && active != null) {
      _expanded.addAll(SuperNavOps.ancestorsOf<T>(_sections, active));
    }
  }

  List<SuperNavSection<T>> _sections;
  SuperNavNodeId? _active;
  final Set<SuperNavNodeId> _expanded;
  final Set<SuperNavNodeId> _favorites;
  final List<SuperNavNodeId> _recents;

  /// Maximum entries kept in [recents] (most-recently-used first).
  final int maxRecents;
  bool _collapsed;
  bool _drawerOpen;
  final bool _autoExpandActive;
  String _query = '';

  // ── reads ──────────────────────────────────────────────────
  List<SuperNavSection<T>> get sections => _sections;
  SuperNavNodeId? get active => _active;
  bool get collapsed => _collapsed;
  bool get drawerOpen => _drawerOpen;
  String get query => _query;
  bool get filtering => _query.trim().isNotEmpty;

  bool isExpanded(SuperNavNodeId id) => _expanded.contains(id);
  bool isActive(SuperNavNodeId id) => _active == id;

  /// Whether [id] is on the path to the active node (used to accent-tint an
  /// ancestor module/group even while the leaf itself is the active row).
  bool ownsActive(SuperNavNodeId id) =>
      _active != null &&
      SuperNavOps.ancestorsOf<T>(_sections, _active!).contains(id);

  SuperNavNode<T>? node(SuperNavNodeId id) =>
      SuperNavOps.find<T>(_sections, id);

  /// The strongly-typed value behind the active node, or null.
  T? get activeValue => _active == null ? null : node(_active!)?.value;

  // ── favorites / quick access ───────────────────────────────
  /// Ids the user has starred for the synthesized "Quick Access" band.
  Set<SuperNavNodeId> get favorites => Set.unmodifiable(_favorites);

  bool isFavorite(SuperNavNodeId id) => _favorites.contains(id);

  /// Favorited nodes, in the order they appear in the tree (skips missing ids).
  List<SuperNavNode<T>> get favoriteNodes {
    final out = <SuperNavNode<T>>[];
    SuperNavOps.walk<T>(_sections, (n, _) {
      if (_favorites.contains(n.id)) out.add(n);
    });
    return out;
  }

  void toggleFavorite(SuperNavNodeId id) {
    _favorites.contains(id) ? _favorites.remove(id) : _favorites.add(id);
    notifyListeners();
  }

  void setFavorites(Iterable<SuperNavNodeId> ids) {
    _favorites
      ..clear()
      ..addAll(ids);
    notifyListeners();
  }

  // ── recents / history ──────────────────────────────────
  /// Recently visited destination ids, most-recent first (max [maxRecents]).
  ///
  /// Updated automatically on every successful [navigate]. Surfaced by the
  /// command palette as a "Recent" band when the query is empty — the fastest
  /// path back to the handful of screens an ERP user lives in.
  List<SuperNavNodeId> get recents => List.unmodifiable(_recents);

  /// [recents] resolved to their nodes (missing ids are skipped).
  List<SuperNavNode<T>> get recentNodes => [
    for (final id in _recents)
      if (node(id) != null) node(id)!,
  ];

  void clearRecents() {
    if (_recents.isEmpty) return;
    _recents.clear();
    notifyListeners();
  }

  void _pushRecent(SuperNavNodeId id) {
    _recents
      ..remove(id)
      ..insert(0, id);
    if (_recents.length > maxRecents) {
      _recents.removeRange(maxRecents, _recents.length);
    }
  }

  // ── navigation ─────────────────────────────────────────────
  /// Make [id] the active destination and return `true`.
  ///
  /// Returns `false` without changing state when:
  /// - [id] does not exist in the tree.
  /// - The node has [SuperNavNode.enabled] == `false`.
  /// - The node has [SuperNavNode.locked] == `true` (permission-gated).
  ///
  /// Auto-opens ancestor modules and closes the mobile drawer on success.
  ///
  /// [SuperNavigationSidebar.onNavigate] is only called when this returns `true`,
  /// ensuring locked and disabled nodes can never trigger host navigation.
  bool navigate(SuperNavNodeId id) {
    final n = node(id);
    if (n == null || !n.enabled || n.locked) return false;
    var changed = false;
    if (_active != id) {
      _active = id;
      changed = true;
    }
    if (n.isLeaf) {
      final wasFirst = _recents.isNotEmpty && _recents.first == id;
      _pushRecent(id);
      if (!wasFirst) changed = true;
    }
    if (_autoExpandActive) {
      for (final a in SuperNavOps.ancestorsOf<T>(_sections, id)) {
        changed |= _expanded.add(a);
      }
    }
    if (_drawerOpen) {
      _drawerOpen = false;
      changed = true;
    }
    if (changed) notifyListeners();
    return true;
  }

  // ── expansion ──────────────────────────────────────────────
  void expand(SuperNavNodeId id) {
    if (_expanded.add(id)) notifyListeners();
  }

  void collapse(SuperNavNodeId id) {
    if (_expanded.remove(id)) notifyListeners();
  }

  void toggleNode(SuperNavNodeId id) {
    _expanded.contains(id) ? _expanded.remove(id) : _expanded.add(id);
    notifyListeners();
  }

  void expandAll() {
    SuperNavOps.walk<T>(_sections, (n, _) {
      if (n.hasChildren) _expanded.add(n.id);
    });
    notifyListeners();
  }

  void collapseAll() {
    if (_expanded.isEmpty) return;
    _expanded.clear();
    notifyListeners();
  }

  // ── rail (collapse) ────────────────────────────────────────
  set collapsed(bool v) {
    if (_collapsed == v) return;
    _collapsed = v;
    notifyListeners();
  }

  void toggleCollapsed() => collapsed = !_collapsed;

  // ── mobile drawer ──────────────────────────────────────────
  set drawerOpen(bool v) {
    if (_drawerOpen == v) return;
    _drawerOpen = v;
    notifyListeners();
  }

  void openDrawer() => drawerOpen = true;
  void closeDrawer() => drawerOpen = false;
  void toggleDrawer() => drawerOpen = !_drawerOpen;

  // ── search filter (optional) ───────────────────────────────
  void setQuery(String q) {
    if (q == _query) return;
    _query = q;
    notifyListeners();
  }

  /// Ids that match the current query, plus their ancestors (so the matches
  /// are reachable). Empty when not filtering. Matches [SuperNavNode.label],
  /// [SuperNavNode.code] and [SuperNavNode.keywords].
  Set<SuperNavNodeId> matchSet() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const {};
    final matched = <SuperNavNodeId>{};
    final onPath = <SuperNavNodeId>{};
    bool hit(SuperNavNode<T> n) {
      if (_plainNodeLabel(n).toLowerCase().contains(q)) return true;
      if (n.code != null && n.code!.toLowerCase().contains(q)) return true;
      final kw = n.keywords;
      for (final k in kw) {
        if (k.toLowerCase().contains(q)) return true;
      }
      return false;
    }

    void rec(List<SuperNavNode<T>> nodes, List<SuperNavNodeId> path) {
      for (final n in nodes) {
        if (hit(n)) {
          matched.add(n.id);
          onPath.addAll(path);
        }
        if (n.hasChildren) rec(n.children, [...path, n.id]);
      }
    }

    for (final s in _sections) {
      rec(s.items, const []);
    }
    return {...matched, ...onPath};
  }

  // ── host-driven reload ─────────────────────────────────────
  /// Replace the whole section forest (e.g. permissions changed).
  ///
  /// Validates for duplicate ids in debug builds. Clears [active] if the
  /// previously active node no longer exists in the new tree.
  void replaceSections(List<SuperNavSection<T>> sections) {
    assert(_debugAssertNoDuplicates(sections));
    _sections = List.unmodifiable(sections);
    if (_active != null && node(_active!) == null) _active = null;
    _recents.removeWhere((id) => node(id) == null);
    notifyListeners();
  }

  // ── state persistence ─────────────────────────────────
  /// Capture the user-owned sidebar state (active screen, expanded modules,
  /// favorites, recents, rail flag) as an immutable, JSON-serializable
  /// snapshot. Persist it with SharedPreferences / your backend and pass it
  /// back through [restore] (or the constructor) on next launch:
  ///
  /// ```dart
  /// // On change:
  /// nav.addListener(() => prefs.setString('nav', jsonEncode(nav.snapshot().toJson())));
  /// // On launch:
  /// nav.restore(SuperNavSidebarStateSnapshot.fromJson(jsonDecode(raw)));
  /// ```
  SuperNavSidebarStateSnapshot snapshot() => SuperNavSidebarStateSnapshot(
    active: _active,
    expanded: Set.unmodifiable(_expanded),
    favorites: Set.unmodifiable(_favorites),
    recents: List.unmodifiable(_recents),
    collapsed: _collapsed,
  );

  /// Apply a previously captured [snapshot]. Ids that no longer exist in the
  /// current tree are dropped silently (permissions / modules may have
  /// changed since the snapshot was taken). Notifies once.
  void restore(SuperNavSidebarStateSnapshot s) {
    _expanded
      ..clear()
      ..addAll(s.expanded.where((id) => node(id) != null));
    _favorites
      ..clear()
      ..addAll(s.favorites.where((id) => node(id) != null));
    _recents
      ..clear()
      ..addAll(s.recents.where((id) => node(id) != null));
    if (_recents.length > maxRecents) {
      _recents.removeRange(maxRecents, _recents.length);
    }
    _collapsed = s.collapsed;
    final a = s.active;
    if (a != null && node(a) != null) {
      _active = a;
      if (_autoExpandActive) {
        _expanded.addAll(SuperNavOps.ancestorsOf<T>(_sections, a));
      }
    }
    notifyListeners();
  }

  // ── duplicate-id debug validation ─────────────────────────
  /// Asserts that [sections] contains no duplicate [SuperNavNodeId]s.
  ///
  /// Called automatically in the constructor and [replaceSections] in debug
  /// builds. The assert short-circuits in release builds (zero cost).
  ///
  /// Use [SuperNavOps.findDuplicateIds] for a programmatic check in tests.
  static bool _debugAssertNoDuplicates<T>(List<SuperNavSection<T>> sections) {
    assert(() {
      final dups = SuperNavOps.findDuplicateIds<T>(sections);
      assert(
        dups.isEmpty,
        'SuperNavigationSidebarController: duplicate SuperNavNode IDs detected: '
        '[${dups.join(', ')}]. Every SuperNavNode.id must be unique across the '
        'entire navigation tree. Duplicate IDs cause undefined navigation '
        'behaviour — the controller cannot reliably resolve expansion, '
        'active state or ancestor paths when multiple nodes share an id.',
      );
      return true;
    }());
    return true;
  }

  // ── InheritedNotifier access ───────────────────────────────
  static SuperNavigationSidebarController<T>? of<T>(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<SuperNavigationSidebarScope<T>>();
    return scope?.controller;
  }
}

/// An immutable, JSON-serializable capture of the user-owned sidebar state.
///
/// Produced by [SuperNavigationSidebarController.snapshot], consumed by
/// [SuperNavigationSidebarController.restore]. Node ids are plain strings, so a
/// snapshot survives app restarts and can be stored per-user on a backend —
/// an ERP user's pinned screens, open modules and recent history follow them
/// to any workstation.
@immutable
class SuperNavSidebarStateSnapshot {
  final SuperNavNodeId? active;
  final Set<SuperNavNodeId> expanded;
  final Set<SuperNavNodeId> favorites;
  final List<SuperNavNodeId> recents;
  final bool collapsed;

  const SuperNavSidebarStateSnapshot({
    this.active,
    this.expanded = const {},
    this.favorites = const {},
    this.recents = const [],
    this.collapsed = false,
  });

  Map<String, Object?> toJson() => {
    'active': active,
    'expanded': expanded.toList(),
    'favorites': favorites.toList(),
    'recents': recents,
    'collapsed': collapsed,
  };

  factory SuperNavSidebarStateSnapshot.fromJson(Map<String, Object?> json) {
    List<String> strs(Object? v) =>
        v is List ? v.whereType<String>().toList() : const [];
    return SuperNavSidebarStateSnapshot(
      active: json['active'] as String?,
      expanded: strs(json['expanded']).toSet(),
      favorites: strs(json['favorites']).toSet(),
      recents: strs(json['recents']),
      collapsed: json['collapsed'] == true,
    );
  }
}

/// Exposes a [SuperNavigationSidebarController] to the subtree so any descendant
/// (a page, a custom header/footer) can read/drive the sidebar and rebuild
/// when it changes.
class SuperNavigationSidebarScope<T>
    extends InheritedNotifier<SuperNavigationSidebarController<T>> {
  const SuperNavigationSidebarScope({
    super.key,
    required SuperNavigationSidebarController<T> controller,
    required super.child,
  }) : super(notifier: controller);

  SuperNavigationSidebarController<T> get controller => notifier!;
}

typedef NavigationSidebarController<T> = SuperNavigationSidebarController<T>;
typedef NavSidebarStateSnapshot = SuperNavSidebarStateSnapshot;
typedef NavigationSidebarScope<T> = SuperNavigationSidebarScope<T>;
