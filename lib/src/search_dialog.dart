// ============================================================
// NavigationSidebar — SEARCH DIALOG (command palette).
// ------------------------------------------------------------
// Built-in command-palette overlay. Opened automatically by
// NavigationSidebar(allowSearchDialog: true); also launchable imperatively
// via showNavSearchDialog() for custom entry points.
//
// Public surface:
//   NavSearchHit        — flattened searchable entry (id + label + breadcrumb)
//   NavSearchOps        — buildIndex() + filter() static helpers
//   NavSearchDialog<T>  — dialog widget (requires a Stack ancestor)
//   showNavSearchDialog — convenience Overlay launcher
//
//   File: lib/src/search_dialog.dart
// ============================================================

import 'package:flutter/material.dart';
import 'controller.dart';
import 'models.dart';
import 'theme.dart';

// ════════════════════════════════════════════════════════════
// DATA
// ════════════════════════════════════════════════════════════

/// A flattened, searchable entry extracted from the nav tree.
@immutable
class NavSearchHit {
  /// Stable node id — pass to [NavigationSidebarController.navigate].
  final NavNodeId id;
  final String label;
  final IconData icon;

  /// Top-level module or section title; used as the result group header.
  final String module;

  /// Sub-group label, or empty string for direct section leaves.
  final String group;

  final NavBadge? badge;
  final List<String>? shortcut;

  const NavSearchHit({
    required this.id,
    required this.label,
    required this.icon,
    required this.module,
    required this.group,
    this.badge,
    this.shortcut,
  });
}

// ════════════════════════════════════════════════════════════
// HELPERS
// ════════════════════════════════════════════════════════════

/// Static helpers for building and querying the search index.
class NavSearchOps {
  NavSearchOps._();

  /// Flatten [sections] into a list of [NavSearchHit]s.
  ///
  /// Only navigable leaves are included — module and group headers are
  /// excluded because [NavigationSidebarController.navigate] refuses them.
  static List<NavSearchHit> buildIndex<T>(List<NavSection<T>> sections) {
    final out = <NavSearchHit>[];
    for (final sec in sections) {
      for (final top in sec.items) {
        if (top.isLeaf) {
          out.add(NavSearchHit(
            id: top.id,
            label: top.label,
            icon: top.icon ?? Icons.circle_outlined,
            module: sec.title,
            group: '',
            badge: top.badge,
            shortcut: top.shortcut,
          ));
        } else {
          for (final grp in top.children) {
            final leaves = grp.hasChildren ? grp.children : [grp];
            for (final leaf in leaves) {
              out.add(NavSearchHit(
                id: leaf.id,
                label: leaf.label,
                icon: leaf.icon ?? Icons.circle_outlined,
                module: top.label,
                group: grp.hasChildren ? grp.label : '',
                badge: leaf.badge,
                shortcut: leaf.shortcut,
              ));
            }
          }
        }
      }
    }
    return out;
  }

  /// Filter [index] by tokenised [query]. Returns the full index when blank.
  static List<NavSearchHit> filter(List<NavSearchHit> index, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return index;
    final toks = q.split(RegExp(r'\s+'));
    return index.where((h) {
      final hay = '${h.label} ${h.group} ${h.module}'.toLowerCase();
      return toks.every(hay.contains);
    }).toList();
  }
}

// ════════════════════════════════════════════════════════════
// DIALOG WIDGET
// ════════════════════════════════════════════════════════════

/// A full-screen command-palette overlay that lets users search and jump to any
/// navigable leaf in the sidebar.
///
/// **Requires a [Stack] ancestor** — the widget renders itself via
/// [Positioned.fill] and paints a dimming scrim behind the card. Use
/// [showNavSearchDialog] to open it without managing a Stack yourself.
///
/// ```dart
/// // Manual Stack placement:
/// Stack(children: [
///   MyShellContent(),
///   if (_open)
///     NavSearchDialog<String>(
///       controller: _nav,
///       onClose: () => setState(() => _open = false),
///     ),
/// ])
///
/// // Imperative (no Stack needed):
/// showNavSearchDialog<String>(context, controller: _nav);
/// ```
class NavSearchDialog<T> extends StatefulWidget {
  /// The sidebar controller that owns the section tree.
  final NavigationSidebarController<T> controller;

  /// Called when the dialog should close (backdrop tap, ESC button).
  final VoidCallback? onClose;

  /// Called after the user picks a result. When null [controller.navigate] is
  /// invoked automatically and [onClose] is called.
  final ValueChanged<NavNodeId>? onPick;

  /// Placeholder text in the search field.
  final String hint;

  const NavSearchDialog({
    super.key,
    required this.controller,
    this.onClose,
    this.onPick,
    this.hint = 'Search tabs & actions…',
  });

  @override
  State<NavSearchDialog<T>> createState() => _NavSearchDialogState<T>();
}

class _NavSearchDialogState<T> extends State<NavSearchDialog<T>> {
  late final List<NavSearchHit> _index =
      NavSearchOps.buildIndex<T>(widget.controller.sections);
  final TextEditingController _text = TextEditingController();
  final FocusNode _focus = FocusNode();
  String _q = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<NavSearchHit> get _results => NavSearchOps.filter(_index, _q);

  void _pick(NavNodeId id) {
    if (widget.onPick != null) {
      widget.onPick!(id);
    } else {
      widget.controller.navigate(id);
      widget.onClose?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    final results = _results;

    // Group results by module heading.
    final groups = <String, List<NavSearchHit>>{};
    for (final h in results) {
      groups.putIfAbsent(h.module, () => []).add(h);
    }

    return Positioned.fill(
      child: GestureDetector(
        onTap: widget.onClose,
        child: Container(
          color: const Color(0x8C08090C),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.fromLTRB(20, 90, 20, 20),
          child: GestureDetector(
            onTap: () {}, // absorb taps inside the card
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(t.radiusXl),
                    border: Border.all(color: t.borderStrong),
                    boxShadow: NavigationSidebarThemeData.popShadow,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _inputRow(t),
                      Flexible(child: _resultsList(t, results, groups)),
                      _footerHints(t),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── input row ───────────────────────────────────────────────
  Widget _inputRow(NavigationSidebarThemeData t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.border))),
      child: Row(children: [
        Icon(Icons.search, size: 18, color: t.fg3),
        const SizedBox(width: 11),
        Expanded(
          child: TextField(
            controller: _text,
            focusNode: _focus,
            onChanged: (v) => setState(() => _q = v),
            cursorColor: NavigationSidebarThemeData.accent,
            style: TextStyle(
              fontSize: 15.5,
              color: t.fg1,
              fontFamily: NavigationSidebarThemeData.bodyFont,
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: widget.hint,
              hintStyle: TextStyle(fontSize: 15.5, color: t.fg3),
            ),
          ),
        ),
        GestureDetector(
          onTap: widget.onClose,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              border: Border.all(color: t.border),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              'ESC',
              style: TextStyle(
                fontFamily: NavigationSidebarThemeData.monoFont,
                fontSize: 10,
                color: t.fg3,
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ── results list ────────────────────────────────────────────
  Widget _resultsList(
    NavigationSidebarThemeData t,
    List<NavSearchHit> results,
    Map<String, List<NavSearchHit>> groups,
  ) {
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Text(
          'No tabs match "$_q"',
          style: TextStyle(fontSize: 13.5, color: t.fg3),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
            child: Text(
              _q.trim().isEmpty
                  ? 'ALL TABS · ${_index.length}'
                  : '${results.length} RESULT${results.length == 1 ? '' : 'S'}',
              style: TextStyle(
                fontFamily: NavigationSidebarThemeData.monoFont,
                fontSize: 10,
                letterSpacing: 1.2,
                color: t.fg4,
              ),
            ),
          ),
          for (final entry in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 5),
              child: Text(
                entry.key.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5,
                  letterSpacing: 1.3,
                  color: t.fg3,
                ),
              ),
            ),
            for (final h in entry.value)
              _NavSearchResultRow(
                hit: h,
                active: widget.controller.isActive(h.id),
                onTap: () => _pick(h.id),
              ),
          ],
        ],
      ),
    );
  }

  // ── footer keyboard hints ───────────────────────────────────
  Widget _footerHints(NavigationSidebarThemeData t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration:
          BoxDecoration(border: Border(top: BorderSide(color: t.border))),
      child: Row(children: [
        _NavSearchKbdHint(kbd: '↑↓', label: 'navigate', t: t),
        const SizedBox(width: 16),
        _NavSearchKbdHint(kbd: '↵', label: 'open', t: t),
        const SizedBox(width: 16),
        _NavSearchKbdHint(kbd: 'esc', label: 'close', t: t),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
// INTERNAL WIDGETS
// ════════════════════════════════════════════════════════════

class _NavSearchResultRow extends StatefulWidget {
  final NavSearchHit hit;
  final bool active;
  final VoidCallback onTap;
  const _NavSearchResultRow({
    required this.hit,
    required this.active,
    required this.onTap,
  });
  @override
  State<_NavSearchResultRow> createState() => _NavSearchResultRowState();
}

class _NavSearchResultRowState extends State<_NavSearchResultRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    final active = widget.active;
    final bg = active
        ? t.accentFill(0.10)
        : (_hover ? t.hover : Colors.transparent);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? t.accentFill(0.16) : t.inputBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.hit.icon,
                size: 16,
                color: active
                    ? NavigationSidebarThemeData.accent
                    : t.fg3,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.hit.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: t.fg1,
                    ),
                  ),
                  Text(
                    widget.hit.group.isEmpty
                        ? widget.hit.module
                        : widget.hit.group,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: NavigationSidebarThemeData.monoFont,
                      color: t.fg3,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.hit.badge != null)
              _NavSearchBadgePill(badge: widget.hit.badge!),
          ]),
        ),
      ),
    );
  }
}

class _NavSearchBadgePill extends StatelessWidget {
  final NavBadge badge;
  const _NavSearchBadgePill({required this.badge});

  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    final c = t.badgeColors(badge.tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.border),
      ),
      child: Text(
        badge.text,
        style: TextStyle(
          fontFamily: NavigationSidebarThemeData.monoFont,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: c.fg,
        ),
      ),
    );
  }
}

class _NavSearchKbdHint extends StatelessWidget {
  final String kbd;
  final String label;
  final NavigationSidebarThemeData t;
  const _NavSearchKbdHint(
      {required this.kbd, required this.label, required this.t});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          border: Border.all(color: t.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          kbd,
          style: TextStyle(
            fontFamily: NavigationSidebarThemeData.monoFont,
            fontSize: 10.5,
            color: t.fg3,
          ),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: TextStyle(
          fontFamily: NavigationSidebarThemeData.monoFont,
          fontSize: 10.5,
          color: t.fg4,
        ),
      ),
    ]);
  }
}

// ════════════════════════════════════════════════════════════
// IMPERATIVE LAUNCHER
// ════════════════════════════════════════════════════════════

/// Show a [NavSearchDialog] as a full-screen overlay via the [Overlay].
///
/// The dialog dismisses on backdrop tap or the ESC button. When the user
/// picks a result [onPick] is called (if provided); otherwise
/// [controller.navigate] is invoked automatically.
///
/// Theme and text direction are inherited from [context] and re-applied
/// inside the overlay so the dialog looks correct regardless of where it
/// is opened from.
///
/// ```dart
/// // In a button's onPressed / any onTap:
/// showNavSearchDialog<String>(context, controller: _nav);
/// ```
void showNavSearchDialog<T>(
  BuildContext context, {
  required NavigationSidebarController<T> controller,
  ValueChanged<NavNodeId>? onPick,
  String hint = 'Search tabs & actions…',
}) {
  final overlay = Overlay.of(context);
  final themeData = Theme.of(context);
  final dir = Directionality.of(context);

  // Use a list so the bool is mutable from both the close closure and the
  // entry builder without needing a late variable trick.
  final dismissed = [false];
  late OverlayEntry entry;

  void close() {
    if (!dismissed[0]) {
      dismissed[0] = true;
      entry.remove();
    }
  }

  entry = OverlayEntry(
    builder: (ctx) => Theme(
      data: themeData,
      child: Directionality(
        textDirection: dir,
        child: Stack(
          children: [
            NavSearchDialog<T>(
              controller: controller,
              onClose: close,
              onPick: onPick != null
                  ? (id) {
                      onPick(id);
                      close();
                    }
                  : null,
              hint: hint,
            ),
          ],
        ),
      ),
    ),
  );

  overlay.insert(entry);
}
