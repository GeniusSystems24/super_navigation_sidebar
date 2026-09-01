// ============================================================
// SuperNavigationSidebar — MODEL.
// ------------------------------------------------------------
// Pure data: the immutable schema a host builds to describe its navigation —
// a list of titled sections, each holding a tree of nodes (direct leaf · or a
// module that drills into groups → items). No widgets, no mutable state:
// expansion, the active id, the rail/drawer mode and the open-flyout all live
// in the controller, keyed by node id.
//
// DEEP IMMUTABILITY
// -----------------
// SuperNavNode.children and SuperNavSection.items are wrapped in List.unmodifiable() at
// construction time — external callers cannot mutate the list. All structural
// changes must go through the controller (replaceSections / navigate / etc.)
// which notifies listeners correctly.
//
// NOTE: The SuperNavNode and SuperNavSection constructors are intentionally non-const so
// the List.unmodifiable() wrap can run at construction time. Users who
// previously used `const SuperNavNode(...)` should remove the `const` keyword.
//
// The tree mirrors the GeniusLink web sidebar's four roles:
//   Section  →  Module     →  Group        →  Item
//   Section  →  Direct leaf
// Role is *derived* from depth + whether the node has children — see
// [SuperNavNodeRole.of]. The same recursion paints any depth.
//
//   File: lib/src/models.dart
// ============================================================

import 'package:flutter/widgets.dart';

/// Stable identity of a nav node (the host's own screen/route key).
typedef SuperNavNodeId = String;

/// The four visual roles a node can take, derived from its position.
enum SuperNavNodeRole {
  /// Depth-0 leaf — a flat top-level destination (e.g. *Dashboard*). Renders
  /// as a pill row that fills with the accent when active.
  direct,

  /// Depth-0 branch — a collapsible module (e.g. *Accounts*). Renders with its
  /// leading icon and a disclosure chevron; tints accent when it owns the
  /// active screen.
  module,

  /// Depth-≥1 branch — a sub-group header inside a module (e.g. *Chart of
  /// Accounts*). Renders uppercase with a bullet.
  group,

  /// Depth-≥1 leaf — a destination inside a group. Renders with a boxed icon.
  item;

  /// Resolve a node's role from its [depth] and whether it [hasChildren].
  static SuperNavNodeRole of({required int depth, required bool hasChildren}) {
    if (hasChildren) {
      return depth == 0 ? SuperNavNodeRole.module : SuperNavNodeRole.group;
    }
    return depth == 0 ? SuperNavNodeRole.direct : SuperNavNodeRole.item;
  }
}

/// Semantic colour of a [SuperNavBadge].
enum SuperNavBadgeTone { accent, success, warning, danger, muted }

/// A small trailing pill on a nav row — a count (`'3'`), a status (`'New'`,
/// `'Live'`) or any short token. In the collapsed rail it collapses to a dot.
@immutable
class SuperNavBadge {
  final String text;
  final SuperNavBadgeTone tone;
  const SuperNavBadge(this.text, {this.tone = SuperNavBadgeTone.accent});
}

/// Informational state of a node — surfaced as a small status dot before the
/// label. Built for ERP needs like fiscal-period or ledger state (an *open*
/// period is green, a *closed* one grey, a *locked* one red). Purely
/// presentational; it does not block navigation (use [SuperNavNode.locked] for
/// permission gating).
enum SuperNavNodeStatus {
  /// No status dot.
  none,

  /// Open / active — accounting period open, account live. Green.
  open,

  /// Closed — period closed for posting. Muted grey.
  closed,

  /// Hard-locked / sealed — audited & immutable. Red.
  locked,

  /// Needs attention — reconciliation pending, breach flagged. Amber.
  attention,
}

/// One node in the navigation tree, generic over a strongly-typed host
/// [value] (a route, a screen enum, …) so callers read `node.value` with no
/// casting. Deeply immutable; [children] is wrapped in [List.unmodifiable] at
/// construction time. Use [copyWith] to derive modified copies.
///
/// **Breaking change from 1.1:** The constructor is no longer `const`. Remove
/// the `const` keyword from any `const SuperNavNode(…)` call sites.
@immutable
class SuperNavNode<T> {
  /// Unique, stable id across the whole sidebar (the host's screen key).
  ///
  /// [SuperNavigationSidebarController] validates that every id in the tree is
  /// unique in debug builds. Duplicate ids cause an assertion failure.
  final SuperNavNodeId id;

  /// Display label.
  final Widget label;

  /// Optional short screen code (an SAP-style transaction code, e.g. `'JE01'`,
  /// `'AP-INV'`). Rendered as a mono chip in the command palette and matched
  /// by search — power users can jump by code instead of label.
  final String? code;

  /// Extra search terms (synonyms, legacy names, Arabic/English aliases).
  /// Never rendered — only matched by the tree filter and the command
  /// palette. Wrapped in [List.unmodifiable] at construction.
  final List<String> keywords;

  /// Leading leadingIcon. Optional for [SuperNavNodeRole.group] headers (they show a
  /// bullet), required-in-spirit for everything else.
  final Widget? leadingIcon;

  final Widget? trailingIcon;

  /// Child nodes. Empty for a leaf.
  ///
  /// Always an unmodifiable view — external mutation is prevented. All
  /// structural changes must go through the controller.
  final List<SuperNavNode<T>> children;

  /// Optional trailing badge (count or status).
  final SuperNavBadge? badge;

  /// Strongly-typed payload travelling with the node (`null` for structural
  /// nodes).
  final T? value;

  /// When false the row is shown but can't be activated.
  final bool enabled;

  /// When true the row is permission-gated: rendered with a lock glyph, dimmed,
  /// not activatable (the controller refuses to navigate to it and
  /// [SuperNavigationSidebar.onNavigate] is never fired), and its [lockMessage] is
  /// surfaced as a tooltip. Use for segregation-of-duties / role-gated screens.
  final bool locked;

  /// Tooltip shown on a [locked] row, e.g. `'Requires Approver role'`.
  final String? lockMessage;

  /// Informational state dot before the label (fiscal-period / ledger state).
  final SuperNavNodeStatus status;

  /// Creates a deeply-immutable nav node.
  ///
  /// [children] is wrapped in [List.unmodifiable]; passing a list and then
  /// mutating it externally has no effect on this node.
  SuperNavNode({
    required this.id,
    required this.label,
    this.code,
    List<String> keywords = const [],
    this.leadingIcon,
    this.trailingIcon,
    List<SuperNavNode<T>>? children,
    this.badge,
    this.value,
    this.enabled = true,
    this.locked = false,
    this.lockMessage,
    this.status = SuperNavNodeStatus.none,
  }) : keywords = List.unmodifiable(keywords),
       children = children == null ? const [] : List.unmodifiable(children);

  bool get hasChildren => children.isNotEmpty;
  bool get isLeaf => children.isEmpty;

  SuperNavNode<T> copyWith({
    SuperNavNodeId? id,
    Widget? label,
    String? code,
    List<String>? keywords,
    Widget? leadingIcon,
    Widget? trailingIcon,
    List<SuperNavNode<T>>? children,
    SuperNavBadge? badge,
    T? value,
    bool? enabled,
    bool? locked,
    String? lockMessage,
    SuperNavNodeStatus? status,
  }) => SuperNavNode<T>(
    id: id ?? this.id,
    label: label ?? this.label,
    code: code ?? this.code,
    keywords: keywords ?? this.keywords,
    leadingIcon: leadingIcon ?? this.leadingIcon,
    trailingIcon: trailingIcon ?? this.trailingIcon,
    children: children ?? List<SuperNavNode<T>>.of(this.children),
    badge: badge ?? this.badge,
    value: value ?? this.value,
    enabled: enabled ?? this.enabled,
    locked: locked ?? this.locked,
    lockMessage: lockMessage ?? this.lockMessage,
    status: status ?? this.status,
  );

  @override
  bool operator ==(Object other) => other is SuperNavNode<T> && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// A titled band of the sidebar (e.g. *Overview*, *Finance*). The title is the
/// small uppercase eyebrow above the band; [items] are its top-level nodes.
///
/// [items] is wrapped in [List.unmodifiable] at construction time.
///
/// **Breaking change from 1.1:** The constructor is no longer `const`. Remove
/// the `const` keyword from any `const SuperNavSection(…)` call sites.
@immutable
class SuperNavSection<T> {
  final String title;

  /// Top-level nodes in this section. Always an unmodifiable list.
  final List<SuperNavNode<T>> items;

  /// Whether this band flows in the pane body or is pinned to the footer.
  ///
  /// Footer sections (e.g. *Settings*, *Help*) stay pinned to the bottom of
  /// the pane while body sections scroll. Both share one selection model.
  final SuperNavSectionPlacement placement;

  /// Creates a nav section whose [items] list is deeply immutable.
  SuperNavSection({
    required this.title,
    required List<SuperNavNode<T>> items,
    this.placement = SuperNavSectionPlacement.body,
  }) : items = List.unmodifiable(items);
}

/// How the sidebar is currently presented. The view can derive this from the
/// available width (see [SuperNavSidebarBreakpoints]) or a host can force it.
enum SuperNavSidebarMode {
  /// Full-width labelled tree.
  expanded,

  /// Icon-only rail; hovering a module opens a grouped flyout.
  rail,

  /// Off-canvas drawer slid over the content (small screens), with a scrim.
  drawer,
}

/// Where a [SuperNavSection] is laid out within the pane.
///
/// Mirrors Microsoft NavigationView's split between `MenuItems` (top of pane)
/// and `FooterMenuItems` (pinned to the bottom — e.g. *Settings*, *Account*,
/// *Help*). Footer sections share the same selection model as body sections:
/// a footer destination highlights when active and participates in
/// breadcrumbs, search and `navigate()` exactly like any other node.
enum SuperNavSectionPlacement {
  /// Default — flows in the scrollable body of the pane, top-down.
  body,

  /// Pinned to the bottom of the pane, above the free-form `footer` slot.
  footer,
}

/// Visual treatment of the active-row selection indicator.
enum SuperNavSelectionIndicator {
  /// The whole leaf row fills with the accent colour (the original look).
  fill,

  /// A vertical accent pill is drawn on the row's leading edge over a subtle
  /// tinted background — the Fluent NavigationView selection indicator.
  bar,
}

/// Width thresholds that map an available width to a [SuperNavSidebarMode] — the
/// Flutter analogue of the web `getNavMode(w)`. Tune per app.
@immutable
class SuperNavSidebarBreakpoints {
  /// At/above this the sidebar is [SuperNavSidebarMode.expanded].
  final double expanded;

  /// At/above this (but below [expanded]) it's a [SuperNavSidebarMode.rail];
  /// below it the sidebar becomes a [SuperNavSidebarMode.drawer].
  final double rail;

  const SuperNavSidebarBreakpoints({this.expanded = 1200, this.rail = 768});

  SuperNavSidebarMode modeFor(double width) {
    if (width >= expanded) return SuperNavSidebarMode.expanded;
    if (width >= rail) return SuperNavSidebarMode.rail;
    return SuperNavSidebarMode.drawer;
  }
}

/// Static helpers shared by the controller and the view.
class SuperNavOps {
  SuperNavOps._();

  /// Depth-first walk over every node in [sections], with its ancestor path.
  static void walk<T>(
    List<SuperNavSection<T>> sections,
    void Function(SuperNavNode<T> node, List<SuperNavNode<T>> ancestors) visit,
  ) {
    void rec(List<SuperNavNode<T>> nodes, List<SuperNavNode<T>> path) {
      for (final n in nodes) {
        visit(n, path);
        if (n.hasChildren) rec(n.children, [...path, n]);
      }
    }

    for (final s in sections) {
      rec(s.items, const []);
    }
  }

  /// Find a node by id across all sections, or null.
  static SuperNavNode<T>? find<T>(
    List<SuperNavSection<T>> sections,
    SuperNavNodeId id,
  ) {
    SuperNavNode<T>? hit;
    walk<T>(sections, (n, _) {
      if (n.id == id) hit = n;
    });
    return hit;
  }

  /// Ancestor ids of [id], outermost-first (empty if top-level or missing).
  static List<SuperNavNodeId> ancestorsOf<T>(
    List<SuperNavSection<T>> sections,
    SuperNavNodeId id,
  ) {
    List<SuperNavNodeId>? result;
    void rec(List<SuperNavNode<T>> nodes, List<SuperNavNodeId> path) {
      for (final n in nodes) {
        if (n.id == id) {
          result = path;
          return;
        }
        if (n.hasChildren) rec(n.children, [...path, n.id]);
      }
    }

    for (final s in sections) {
      rec(s.items, const []);
      if (result != null) break;
    }
    return result ?? const [];
  }

  /// True when [node] or anything beneath it carries a badge — used to mark a
  /// collapsed module/rail icon with a dot.
  static bool subtreeHasBadge<T>(SuperNavNode<T> node) {
    if (node.badge != null) return true;
    for (final c in node.children) {
      if (subtreeHasBadge(c)) return true;
    }
    return false;
  }

  /// Sum of all numeric badge texts on [node] and its descendants.
  ///
  /// Non-numeric badges (`'New'`, `'Live'`) count as 0. Used by
  /// `SuperNavigationSidebar.aggregateBadges` to roll pending-approval /
  /// unposted-document counts up onto a collapsed module row — the ERP
  /// "12 things need you inside" affordance.
  static int subtreeBadgeSum<T>(SuperNavNode<T> node) {
    var sum = int.tryParse(node.badge?.text ?? '') ?? 0;
    for (final c in node.children) {
      sum += subtreeBadgeSum(c);
    }
    return sum;
  }

  /// All leaf ids beneath (and including, if leaf) [node].
  static List<SuperNavNodeId> leafIds<T>(SuperNavNode<T> node) {
    final out = <SuperNavNodeId>[];
    void rec(SuperNavNode<T> n) {
      if (n.isLeaf) {
        out.add(n.id);
      } else {
        for (final c in n.children) {
          rec(c);
        }
      }
    }

    rec(node);
    return out;
  }

  /// Returns all duplicate [SuperNavNodeId]s found by walking [sections].
  ///
  /// An empty list means the tree is valid (all ids are unique). Use this in
  /// host-app debug assertions or unit tests to validate nav trees:
  ///
  /// ```dart
  /// assert(SuperNavOps.findDuplicateIds(sections).isEmpty,
  ///     'Duplicate nav ids: ${SuperNavOps.findDuplicateIds(sections)}');
  /// ```
  static List<SuperNavNodeId> findDuplicateIds<T>(
    List<SuperNavSection<T>> sections,
  ) {
    final seen = <SuperNavNodeId>{};
    final dups = <SuperNavNodeId>[];
    walk<T>(sections, (n, _) {
      if (!seen.add(n.id)) dups.add(n.id);
    });
    return dups;
  }
}

typedef NavNodeId = SuperNavNodeId;
typedef NavNodeRole = SuperNavNodeRole;
typedef NavBadgeTone = SuperNavBadgeTone;
typedef NavBadge = SuperNavBadge;
typedef NavNodeStatus = SuperNavNodeStatus;
typedef NavNode<T> = SuperNavNode<T>;
typedef NavSection<T> = SuperNavSection<T>;
typedef NavSidebarMode = SuperNavSidebarMode;
typedef NavSectionPlacement = SuperNavSectionPlacement;
typedef NavSelectionIndicator = SuperNavSelectionIndicator;
typedef NavSidebarBreakpoints = SuperNavSidebarBreakpoints;
typedef NavOps = SuperNavOps;
