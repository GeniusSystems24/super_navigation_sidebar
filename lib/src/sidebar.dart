// ============================================================
// NavigationSidebar — VIEW.
// ------------------------------------------------------------
// A thin, customisable render of NavigationSidebarController<T>. Paints the
// titled sections and their node tree in one of three modes:
//
//   • expanded — full-width labelled tree with │ ├ └ connectors, badges and
//                disclosure chevrons; the active leaf fills with the accent.
//   • rail     — icon-only column; hovering a module opens a grouped flyout.
//   • drawer   — off-canvas panel slid over the content with a scrim.
//
// NAVIGATION SAFETY
// -----------------
// _go() guards against locked/disabled nodes before calling navigate() and
// only fires onNavigate when the controller confirms navigation succeeded.
// Rail and flyout rows are similarly guarded — locked/disabled nodes can
// never trigger host navigation in any mode.
//
// ACCESSIBILITY
// -------------
// Every interactive row is wrapped in Semantics (button role, selected state,
// expanded/collapsed state, lock/disable hints) and a Focus with onKeyEvent
// so keyboard users can activate rows with Enter or Space. The drawer close
// button carries an accessible label. Rail items have Tooltip semantics.
//
// LOCALIZATIONS
// -------------
// All user-facing strings are sourced from NavigationSidebarLocalizations.
// Pass a custom instance (or NavigationSidebarLocalizations.arabic) via the
// `localizations` property. The existing drawerTitle / searchHint /
// quickAccessTitle props still override their localizations counterparts for
// backward compatibility.
//
//   File: lib/src/sidebar.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'controller.dart';
import 'localizations.dart';
import 'models.dart';
import 'theme.dart';

typedef NavSidebarSlotBuilder = Widget Function(BuildContext context, bool collapsed);

class NavigationSidebar<T> extends StatefulWidget {
  /// Initial sections. Required when [controller] is null.
  final List<NavSection<T>>? sections;

  /// Active id on first build (ignored when a [controller] is supplied).
  final NavNodeId? active;

  /// Ids expanded on first build (ignored when a [controller] is supplied).
  final Set<NavNodeId>? initiallyExpanded;

  /// Drive/observe from outside. When null the widget owns a private one.
  final NavigationSidebarController<T>? controller;

  /// How the sidebar is presented.
  final NavSidebarMode mode;

  // ── slots ──
  final NavSidebarSlotBuilder? header;
  final NavSidebarSlotBuilder? footer;

  /// Eyebrow above the drawer close button. Overrides
  /// [localizations.drawerTitle] when set.
  final String? drawerTitle;

  // ── chrome toggles ──
  final bool showGuides;
  final bool railFlyouts;

  /// Show a pane-toggle (collapse ↔ expand) button pinned to the top of the
  /// pane — the NavigationView "menu button" placement. Off by default; enable
  /// it when the pane is used without a [NavigationSidebarAppBar] that already
  /// carries the toggle (e.g. an inset-header [NavigationShell]).
  final bool showPaneToggle;

  /// How keyboard-shortcut hints appear on expanded-tree rows.
  ///
  /// **Note:** [NavNode.shortcut] values are visual hints only. The sidebar
  /// renders the keycap glyphs and surfaces them in tooltips but does not
  /// register global key handlers — wiring the actual keystroke is the host
  /// app's responsibility (via [Shortcuts] / [Actions] or a custom handler).
  final NavShortcutMode shortcutMode;

  /// Show a built-in search field above the tree (expanded / drawer modes).
  final bool searchable;

  /// Placeholder for the [searchable] field. Overrides
  /// [localizations.searchHint] when set.
  final String? searchHint;

  /// Enable per-row star toggles and a synthesized "Quick Access" band.
  final bool favoritable;

  /// Eyebrow for the Quick Access band. Overrides
  /// [localizations.quickAccessTitle] when set.
  final String? quickAccessTitle;

  /// Localization strings for all user-facing text rendered by this widget.
  ///
  /// Defaults to English. Use [NavigationSidebarLocalizations.arabic] for RTL
  /// Arabic apps, or construct a custom instance for other languages.
  final NavigationSidebarLocalizations localizations;

  // ── callbacks ──
  /// Called when a destination is successfully navigated to.
  ///
  /// Only fired when [NavigationSidebarController.navigate] returns true —
  /// locked and disabled nodes never trigger this callback.
  final ValueChanged<NavNode<T>>? onNavigate;

  const NavigationSidebar({
    super.key,
    this.sections,
    this.active,
    this.initiallyExpanded,
    this.controller,
    this.mode = NavSidebarMode.expanded,
    this.header,
    this.footer,
    this.drawerTitle,
    this.showGuides = true,
    this.railFlyouts = true,
    this.showPaneToggle = false,
    this.shortcutMode = NavShortcutMode.onHover,
    this.searchable = false,
    this.searchHint,
    this.favoritable = false,
    this.quickAccessTitle,
    this.localizations = const NavigationSidebarLocalizations(),
    this.onNavigate,
  }) : assert(sections != null || controller != null,
            'Provide sections or a controller.');

  @override
  State<NavigationSidebar<T>> createState() => _NavigationSidebarState<T>();
}

class _NavigationSidebarState<T> extends State<NavigationSidebar<T>> {
  late NavigationSidebarController<T> _controller;
  bool _ownsController = false;
  final ScrollController _scroll = ScrollController();
  final TextEditingController _search = TextEditingController();

  NavigationSidebarThemeData get _t => NavigationSidebarThemeData.of(context);
  NavigationSidebarLocalizations get _l10n => widget.localizations;
  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  // Resolved strings (explicit prop overrides localizations default).
  String get _drawerTitle => widget.drawerTitle ?? _l10n.drawerTitle;
  String get _searchHint => widget.searchHint ?? _l10n.searchHint;
  String get _quickAccessTitle =>
      widget.quickAccessTitle ?? _l10n.quickAccessTitle;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        NavigationSidebarController<T>(
          sections: widget.sections!,
          active: widget.active,
          expanded: widget.initiallyExpanded,
          collapsed: widget.mode == NavSidebarMode.rail,
        );
    _ownsController = widget.controller == null;
    _controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(covariant NavigationSidebar<T> old) {
    super.didUpdateWidget(old);
    if (widget.controller != null && widget.controller != _controller) {
      _controller.removeListener(_onChanged);
      if (_ownsController) _controller.dispose();
      _controller = widget.controller!;
      _ownsController = false;
      _controller.addListener(_onChanged);
    }
    if (_ownsController &&
        widget.mode != old.mode &&
        widget.mode != NavSidebarMode.drawer) {
      _controller.collapsed = widget.mode == NavSidebarMode.rail;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    if (_ownsController) _controller.dispose();
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  /// Navigate to [n] and fire [onNavigate] only when navigation was actually
  /// applied (i.e. node is not locked, disabled, or absent).
  void _go(NavNode<T> n) {
    if (!n.enabled || n.locked) return;
    final navigated = _controller.navigate(n.id);
    if (navigated) widget.onNavigate?.call(n);
  }

  bool get _railed =>
      widget.mode == NavSidebarMode.rail ||
      (widget.mode != NavSidebarMode.drawer && _controller.collapsed);

  /// Sections that flow in the scrollable pane body.
  List<NavSection<T>> get _bodySections => [
        for (final s in _controller.sections)
          if (s.placement == NavSectionPlacement.body) s
      ];

  /// Sections pinned to the bottom of the pane (e.g. Settings / Help).
  List<NavSection<T>> get _footerSections => [
        for (final s in _controller.sections)
          if (s.placement == NavSectionPlacement.footer) s
      ];

  // Pane toggle (top-of-pane menu button).
  Widget _paneToggleRow(NavigationSidebarThemeData t, bool railed) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 2),
      child: Align(
        alignment:
            railed ? Alignment.center : AlignmentDirectional.centerStart,
        child: Semantics(
          button: true,
          label: _l10n.semanticToggleSidebar,
          child: Tooltip(
            message: _l10n.semanticToggleSidebar,
            waitDuration: const Duration(milliseconds: 450),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _controller.toggleCollapsed,
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  child: Icon(
                    railed ? Icons.menu_rounded : Icons.menu_open_rounded,
                    size: 20,
                    color: t.fg2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Pinned footer sections (expanded).
  Widget _expandedFooter(
      NavigationSidebarThemeData t, List<NavSection<T>> footers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Divider(height: 1, color: t.border),
        ),
        for (final sec in footers) ...[
          if (sec.title.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
              child: Text(
                sec.title.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 1.4,
                  color: t.fg4,
                ),
              ),
            ),
          for (final node in sec.items) _treeNode(t, node, 0, null),
        ],
      ],
    );
  }

  // Pinned footer sections (rail).
  Widget _railFooter(
      NavigationSidebarThemeData t, List<NavSection<T>> footers) {
    return Column(
      children: [
        Container(
          width: 26,
          height: 1,
          margin: const EdgeInsets.symmetric(vertical: 5),
          color: t.border,
        ),
        for (final sec in footers)
          for (final node in sec.items)
            _RailItem<T>(
              key: ValueKey('rail-footer-${node.id}'),
              node: node,
              active: node.hasChildren
                  ? _controller.ownsActive(node.id)
                  : _controller.isActive(node.id),
              activeId: _controller.active,
              flyouts: widget.railFlyouts,
              rtl: _rtl,
              localizations: _l10n,
              onNavigate: _go,
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavigationSidebarScope<T>(
      controller: _controller,
      child: widget.mode == NavSidebarMode.drawer
          ? _buildDrawer(_t)
          : _buildInline(_t),
    );
  }

  // ── inline panel (expanded / rail) ─────────────────────────
  Widget _buildInline(NavigationSidebarThemeData t) {
    final railed = _railed;
    return AnimatedContainer(
      duration: NavigationSidebarThemeData.durBase,
      curve: NavigationSidebarThemeData.curveStandard,
      width: railed
          ? t.widthRail
          : t.widthExpanded,
      decoration: BoxDecoration(
        color: t.surface,
        border: BorderDirectional(end: BorderSide(color: t.border)),
      ),
      child: _panelContents(t, railed: railed, drawer: false),
    );
  }

  // ── drawer overlay ─────────────────────────────────────────
  Widget _buildDrawer(NavigationSidebarThemeData t) {
    final open = _controller.drawerOpen;
    final hidden = t.widthDrawer + 8;
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !open,
            child: GestureDetector(
              onTap: _controller.closeDrawer,
              child: AnimatedOpacity(
                duration: NavigationSidebarThemeData.durDrawer,
                opacity: open ? 1 : 0,
                child: const ColoredBox(color: Color(0x8C08090C)),
              ),
            ),
          ),
        ),
        AnimatedPositionedDirectional(
          duration: NavigationSidebarThemeData.durDrawer,
          curve: NavigationSidebarThemeData.curveStandard,
          top: 0,
          bottom: 0,
          start: open ? 0.0 : -hidden,
          width: t.widthDrawer,
          child: Material(
            color: t.surface,
            elevation: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: t.surface,
                boxShadow:
                    open ? NavigationSidebarThemeData.popShadow : null,
                border: BorderDirectional(
                    end: BorderSide(color: t.border)),
              ),
              child: _panelContents(t, railed: false, drawer: true),
            ),
          ),
        ),
      ],
    );
  }

  Widget _panelContents(NavigationSidebarThemeData t,
      {required bool railed, required bool drawer}) {
    final footers = _footerSections;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showPaneToggle && !drawer) ...[
            _paneToggleRow(t, railed),
            const SizedBox(height: 4),
          ],
          if (drawer) ...[
            _drawerHeader(t),
            const SizedBox(height: 2),
          ],
          if (widget.header != null) ...[
            widget.header!(context, railed),
            const SizedBox(height: 12),
          ],
          if (widget.searchable && !railed) ...[
            _SearchField(
              controller: _search,
              hint: _searchHint,
              onChanged: _controller.setQuery,
            ),
            const SizedBox(height: 10),
          ],
          Expanded(
            child: railed ? _railNav(t) : _expandedNav(t),
          ),
          if (footers.isNotEmpty)
            railed ? _railFooter(t, footers) : _expandedFooter(t, footers),
          if (widget.footer != null) ...[
            const SizedBox(height: 12),
            widget.footer!(context, railed),
          ],
        ],
      ),
    );
  }

  Widget _drawerHeader(NavigationSidebarThemeData t) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          Text(
            _drawerTitle.toUpperCase(),
            style: TextStyle(
              fontFamily: NavigationSidebarThemeData.monoFont,
              fontSize: 10,
              letterSpacing: 1.4,
              color: t.fg4,
            ),
          ),
          const Spacer(),
          Semantics(
            button: true,
            label: _l10n.drawerCloseLabel,
            child: InkWell(
              onTap: _controller.closeDrawer,
              borderRadius: BorderRadius.circular(
                  t.radiusSm),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.close, size: 18, color: t.fg3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── expanded tree ──────────────────────────────────────────
  Widget _expandedNav(NavigationSidebarThemeData t) {
    final filtering = _controller.filtering;
    final match = filtering ? _controller.matchSet() : null;

    if (filtering && match!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 26, color: t.fg4),
              const SizedBox(height: 10),
              Text(
                _l10n.searchEmptyFor(_controller.query.trim()),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: NavigationSidebarThemeData.bodyFont,
                  fontSize: 12.5,
                  color: t.fg3,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final showQuickAccess = widget.favoritable &&
        !filtering &&
        _controller.favoriteNodes.isNotEmpty;

    return Scrollbar(
      controller: _scroll,
      child: SingleChildScrollView(
        controller: _scroll,
        primary: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showQuickAccess) _quickAccess(t),
            for (final sec in _bodySections) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: Text(
                  sec.title.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 1.4,
                    color: t.fg4,
                  ),
                ),
              ),
              for (final node in sec.items)
                _treeNode(t, node, 0, match),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }

  Widget _quickAccess(NavigationSidebarThemeData t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Row(
            children: [
              const Icon(Icons.star_rounded,
                  size: 13,
                  color: NavigationSidebarThemeData.accent),
              const SizedBox(width: 6),
              Text(
                _quickAccessTitle.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 1.4,
                  color: t.fg4,
                ),
              ),
            ],
          ),
        ),
        for (final n in _controller.favoriteNodes)
          _NavRow<T>(
            key: ValueKey('fav-${n.id}'),
            node: n,
            depth: 0,
            role: NavNodeRole.direct,
            active: _controller.isActive(n.id),
            shortcutMode: NavShortcutMode.hidden,
            query: '',
            favoritable: true,
            favorite: true,
            localizations: _l10n,
            onToggleFavorite: () => _controller.toggleFavorite(n.id),
            onTap: () => _go(n),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
          child: Divider(height: 1, color: t.border),
        ),
      ],
    );
  }

  Widget _treeNode(
    NavigationSidebarThemeData t,
    NavNode<T> node,
    int depth,
    Set<NavNodeId>? match,
  ) {
    if (match != null && !match.contains(node.id)) {
      return const SizedBox.shrink();
    }
    final filtering = match != null;
    final role =
        NavNodeRole.of(depth: depth, hasChildren: node.hasChildren);

    if (node.isLeaf) {
      return _NavRow<T>(
        key: ValueKey('row-${node.id}'),
        node: node,
        depth: depth,
        role: role,
        active: _controller.isActive(node.id),
        shortcutMode: widget.shortcutMode,
        query: _controller.query,
        favoritable: widget.favoritable,
        favorite: _controller.isFavorite(node.id),
        localizations: _l10n,
        onToggleFavorite:
            widget.favoritable ? () => _controller.toggleFavorite(node.id) : null,
        onTap: () => _go(node),
      );
    }

    final open = filtering || _controller.isExpanded(node.id);
    final ownsActive = _controller.ownsActive(node.id);
    final lx = t.lineInset(depth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NavRow<T>(
          key: ValueKey('row-${node.id}'),
          node: node,
          depth: depth,
          role: role,
          expandable: true,
          open: open,
          ownsActive: ownsActive,
          shortcutMode: widget.shortcutMode,
          query: _controller.query,
          localizations: _l10n,
          onTap: () => _controller.toggleNode(node.id),
        ),
        if (open)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < node.children.length; i++)
                _connectorWrap(
                  t,
                  child: _treeNode(t, node.children[i], depth + 1, match),
                  lx: lx,
                  childRole: NavNodeRole.of(
                    depth: depth + 1,
                    hasChildren: node.children[i].hasChildren,
                  ),
                  last: i == node.children.length - 1,
                ),
            ],
          ),
      ],
    );
  }

  Widget _connectorWrap(
    NavigationSidebarThemeData t, {
    required Widget child,
    required double lx,
    required NavNodeRole childRole,
    required bool last,
  }) {
    if (!widget.showGuides) return child;
    final childH = t.rowHeight(childRole);
    return Stack(
      children: [
        PositionedDirectional(
          start: lx,
          top: 0,
          height: childH / 2,
          width: 1.5,
          child: ColoredBox(color: t.guide),
        ),
        if (!last)
          PositionedDirectional(
            start: lx,
            top: childH / 2,
            bottom: 0,
            width: 1.5,
            child: ColoredBox(color: t.guide),
          ),
        PositionedDirectional(
          start: lx,
          top: childH / 2,
          width: t.elbow,
          height: 1.5,
          child: ColoredBox(color: t.guide),
        ),
        child,
      ],
    );
  }

  // ── rail nav ───────────────────────────────────────────────
  Widget _railNav(NavigationSidebarThemeData t) {
    return Scrollbar(
      controller: _scroll,
      child: SingleChildScrollView(
        controller: _scroll,
        primary: false,
        child: Column(
          children: [
            for (var si = 0; si < _bodySections.length; si++) ...[
              if (si > 0)
                Container(
                  width: 26,
                  height: 1,
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  color: t.border,
                ),
              for (final node in _bodySections[si].items)
                _RailItem<T>(
                  key: ValueKey('rail-${node.id}'),
                  node: node,
                  active: node.hasChildren
                      ? _controller.ownsActive(node.id)
                      : _controller.isActive(node.id),
                  activeId: _controller.active,
                  flyouts: widget.railFlyouts,
                  rtl: _rtl,
                  localizations: _l10n,
                  onNavigate: _go,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// ROW  — one expanded-tree line, styled by role.
// ════════════════════════════════════════════════════════════
class _NavRow<T> extends StatefulWidget {
  final NavNode<T> node;
  final int depth;
  final NavNodeRole role;
  final bool expandable;
  final bool open;
  final bool active;
  final bool ownsActive;
  final VoidCallback onTap;
  final NavShortcutMode shortcutMode;
  final String query;
  final bool favoritable;
  final bool favorite;
  final VoidCallback? onToggleFavorite;
  final NavigationSidebarLocalizations localizations;

  const _NavRow({
    super.key,
    required this.node,
    required this.depth,
    required this.role,
    this.expandable = false,
    this.open = false,
    this.active = false,
    this.ownsActive = false,
    this.shortcutMode = NavShortcutMode.onHover,
    this.query = '',
    this.favoritable = false,
    this.favorite = false,
    this.onToggleFavorite,
    this.localizations = const NavigationSidebarLocalizations(),
    required this.onTap,
  });

  @override
  State<_NavRow<T>> createState() => _NavRowState<T>();
}

class _NavRowState<T> extends State<_NavRow<T>> {
  bool _hover = false;

  bool get _showInline {
    if (widget.node.shortcut == null) return false;
    switch (widget.shortcutMode) {
      case NavShortcutMode.always:
        return true;
      case NavShortcutMode.hidden:
        return false;
      case NavShortcutMode.onHover:
        return _hover;
    }
  }

  Widget _shortcutInline({required bool onAccent}) {
    return AnimatedSwitcher(
      duration: NavigationSidebarThemeData.durFast,
      switchInCurve: NavigationSidebarThemeData.curveStandard,
      switchOutCurve: NavigationSidebarThemeData.curveStandard,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SizeTransition(
          axis: Axis.horizontal,
          axisAlignment: -1,
          sizeFactor: anim,
          child: child,
        ),
      ),
      child: _showInline
          ? Padding(
              key: const ValueKey('sc-on'),
              padding: const EdgeInsetsDirectional.only(start: 6),
              child: _ShortcutHint(
                keys: widget.node.shortcut!,
                onAccent: onAccent,
                localizations: widget.localizations,
              ),
            )
          : const SizedBox.shrink(key: ValueKey('sc-off')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    final l10n = widget.localizations;
    final pad = t.contentInset(widget.depth);
    final h = t.rowHeight(widget.role);
    final isInteractive = widget.node.enabled && !widget.node.locked;

    Widget content;
    switch (widget.role) {
      case NavNodeRole.direct:
      case NavNodeRole.module:
        content = _moduleOrDirect(t);
        break;
      case NavNodeRole.group:
        content = _group(t);
        break;
      case NavNodeRole.item:
        content = _item(t);
        break;
    }

    final radius =
        widget.role == NavNodeRole.direct || widget.role == NavNodeRole.module
            ? t.radiusLg
            : t.radiusMd;

    final barStyle = t.selectionIndicator == NavSelectionIndicator.bar;
    final bool isLeafRow =
        widget.role == NavNodeRole.direct || widget.role == NavNodeRole.item;
    final bool showBar = barStyle && widget.active && isLeafRow;
    Color bg = Colors.transparent;
    if (widget.role == NavNodeRole.direct && widget.active && !barStyle) {
      bg = NavigationSidebarThemeData.accent;
    } else if (widget.active && isLeafRow) {
      bg = t.accentFill(barStyle ? 0.14 : 0.10);
    } else if (_hover) {
      bg = t.hover;
    }

    // Build accessible label for screen readers.
    final buffer = StringBuffer(widget.node.label);
    if (widget.expandable) {
      buffer.write(', ${widget.open ? l10n.semanticExpanded : l10n.semanticCollapsed}');
    }
    if (widget.active) buffer.write(', selected');
    if (widget.node.locked) buffer.write(', ${l10n.semanticLocked}');
    if (!widget.node.enabled) buffer.write(', ${l10n.semanticDisabled}');
    final semanticLabel = buffer.toString();

    return Semantics(
      button: isInteractive && !widget.expandable,
      toggled: widget.expandable ? widget.open : null,
      selected: widget.active,
      label: semanticLabel,
      hint: widget.node.locked
          ? (widget.node.lockMessage ?? l10n.lockedDefault)
          : null,
      excludeSemantics: false,
      child: Focus(
        onKeyEvent: (node, event) {
          if (isInteractive &&
              event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space)) {
            widget.onTap();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: MouseRegion(
          cursor: isInteractive
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isInteractive ? widget.onTap : null,
            child: _withTooltip(
              Opacity(
                opacity: widget.node.locked ? 0.55 : 1.0,
                child: Stack(
                  children: [
                    AnimatedContainer(
                      duration: NavigationSidebarThemeData.durFast,
                      height: h,
                      padding:
                          EdgeInsetsDirectional.only(start: pad, end: 10),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(radius),
                      ),
                      child: content,
                    ),
                    if (showBar)
                      PositionedDirectional(
                        start: 0,
                        top: t.indicatorInset,
                        bottom: t.indicatorInset,
                        child: Container(
                          width: t.indicatorThickness,
                          decoration: BoxDecoration(
                            color: NavigationSidebarThemeData.accent,
                            borderRadius:
                                BorderRadius.circular(t.indicatorThickness),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _withTooltip(Widget child) {
    final l10n = widget.localizations;
    if (widget.node.locked) {
      final msg = widget.node.lockMessage ?? l10n.lockedDefault;
      return Tooltip(
        message: msg,
        waitDuration: const Duration(milliseconds: 350),
        child: child,
      );
    }
    final keys = widget.node.shortcut;
    if (keys == null || widget.shortcutMode == NavShortcutMode.always) {
      return child;
    }
    return Tooltip(
      message: l10n.shortcutTooltip(keys),
      waitDuration: const Duration(milliseconds: 450),
      child: child,
    );
  }

  Widget _label(String text, TextStyle style) {
    final q = widget.query.trim().toLowerCase();
    if (q.isEmpty) {
      return Text(text,
          maxLines: 1, overflow: TextOverflow.ellipsis, style: style);
    }
    final lower = text.toLowerCase();
    final i = lower.indexOf(q);
    if (i < 0) {
      return Text(text,
          maxLines: 1, overflow: TextOverflow.ellipsis, style: style);
    }
    final hi = style.copyWith(
      color: NavigationSidebarThemeData.accent,
      fontWeight: FontWeight.w800,
    );
    return Text.rich(
      TextSpan(style: style, children: [
        TextSpan(text: text.substring(0, i)),
        TextSpan(text: text.substring(i, i + q.length), style: hi),
        TextSpan(text: text.substring(i + q.length)),
      ]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _statusDot(NavigationSidebarThemeData t) {
    final c = t.statusColor(widget.node.status);
    if (c == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 7),
      child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
    );
  }

  Widget _trailing(NavigationSidebarThemeData t,
      {required bool onAccent}) {
    if (widget.node.locked) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(start: 6),
        child: Icon(Icons.lock_outline,
            size: 13, color: onAccent ? Colors.white : t.fg3),
      );
    }
    if (widget.favoritable && (widget.favorite || _hover)) {
      return _StarButton(
        on: widget.favorite,
        onAccent: onAccent,
        localizations: widget.localizations,
        onTap: widget.onToggleFavorite,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _chevron(NavigationSidebarThemeData t) {
    return AnimatedRotation(
      turns: widget.open ? 0.5 : 0,
      duration: NavigationSidebarThemeData.durBase,
      curve: NavigationSidebarThemeData.curveStandard,
      child: Icon(Icons.keyboard_arrow_down, size: 16, color: t.fg3),
    );
  }

  Widget _moduleOrDirect(NavigationSidebarThemeData t) {
    final isDirect = widget.role == NavNodeRole.direct;
    final barStyle = t.selectionIndicator == NavSelectionIndicator.bar;
    final fillActive = isDirect && widget.active && !barStyle;
    final Color tint = isDirect
        ? (fillActive
            ? Colors.white
            : (widget.active
                ? NavigationSidebarThemeData.accent
                : t.fg2))
        : (widget.ownsActive ? NavigationSidebarThemeData.accent : t.fg2);
    final bold = widget.active || widget.ownsActive;
    final moduleDot =
        !isDirect && !widget.open && NavOps.subtreeHasBadge(widget.node);

    return Row(
      children: [
        Icon(widget.node.icon ?? Icons.circle_outlined,
            size: t.iconTop, color: tint),
        const SizedBox(width: 12),
        if (widget.node.status != NavNodeStatus.none) _statusDot(t),
        Expanded(
          child: _label(
            widget.node.label,
            TextStyle(
              fontFamily: NavigationSidebarThemeData.bodyFont,
              fontSize: 13.5,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
              color: tint,
            ),
          ),
        ),
        if (widget.node.badge != null) ...[
          const SizedBox(width: 6),
          _NavBadgeChip(badge: widget.node.badge!),
        ],
        _shortcutInline(onAccent: fillActive),
        if (isDirect) _trailing(t, onAccent: fillActive),
        if (moduleDot) ...[
          const SizedBox(width: 6),
          Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                  color: NavigationSidebarThemeData.accent,
                  shape: BoxShape.circle)),
        ],
        if (widget.expandable) ...[
          const SizedBox(width: 4),
          _chevron(t),
        ],
      ],
    );
  }

  Widget _group(NavigationSidebarThemeData t) {
    final tint = widget.ownsActive
        ? NavigationSidebarThemeData.accent
        : t.fg3;
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: widget.ownsActive
                ? NavigationSidebarThemeData.accent
                : t.fg4,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            widget.node.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: NavigationSidebarThemeData.bodyFont,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: tint,
            ),
          ),
        ),
        if (widget.expandable) _chevron(t),
      ],
    );
  }

  Widget _item(NavigationSidebarThemeData t) {
    final active = widget.active;
    return Row(
      children: [
        Container(
          width: t.itemBox,
          height: t.itemBox,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
                t.radiusMd),
            border: Border.all(
                color: active
                    ? NavigationSidebarThemeData.accent
                    : t.border),
            color: active ? t.accentFill(0.12) : t.surface,
          ),
          child: Icon(
            widget.node.icon ?? Icons.circle,
            size: t.iconItem,
            color: active
                ? NavigationSidebarThemeData.accent
                : t.fg3,
          ),
        ),
        const SizedBox(width: 10),
        if (widget.node.status != NavNodeStatus.none) _statusDot(t),
        Expanded(
          child: _label(
            widget.node.label,
            TextStyle(
              fontFamily: NavigationSidebarThemeData.bodyFont,
              fontSize: 12.5,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: active ? NavigationSidebarThemeData.accent : t.fg2,
            ),
          ),
        ),
        if (widget.node.badge != null) ...[
          const SizedBox(width: 6),
          _NavBadgeChip(badge: widget.node.badge!, small: true),
        ],
        _shortcutInline(onAccent: false),
        _trailing(t, onAccent: false),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// RAIL ITEM — 44×44 icon button with optional hover flyout.
// ════════════════════════════════════════════════════════════
class _RailItem<T> extends StatefulWidget {
  final NavNode<T> node;
  final bool active;
  final NavNodeId? activeId;
  final bool flyouts;
  final bool rtl;
  final NavigationSidebarLocalizations localizations;
  final ValueChanged<NavNode<T>> onNavigate;

  const _RailItem({
    super.key,
    required this.node,
    required this.active,
    required this.activeId,
    required this.flyouts,
    required this.rtl,
    required this.localizations,
    required this.onNavigate,
  });

  @override
  State<_RailItem<T>> createState() => _RailItemState<T>();
}

class _RailItemState<T> extends State<_RailItem<T>> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;
  bool _hover = false;
  bool _overFlyout = false;

  @override
  void dispose() {
    _removeFlyout();
    super.dispose();
  }

  void _scheduleClose() {
    Future<void>.delayed(const Duration(milliseconds: 130), () {
      if (mounted && !_hover && !_overFlyout) _removeFlyout();
    });
  }

  void _removeFlyout() {
    _entry?.remove();
    _entry = null;
  }

  void _showFlyout() {
    if (!widget.flyouts || !widget.node.hasChildren || _entry != null) {
      return;
    }
    final t = NavigationSidebarThemeData.of(context);
    final themeData = Theme.of(context);
    const flyW = 248.0;
    _entry = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          width: flyW,
          child: CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            targetAnchor:
                widget.rtl ? Alignment.topLeft : Alignment.topRight,
            followerAnchor:
                widget.rtl ? Alignment.topRight : Alignment.topLeft,
            offset: Offset(widget.rtl ? -10.0 : 10.0, -4),
            child: Theme(
              data: themeData,
              child: MouseRegion(
                onEnter: (_) => _overFlyout = true,
                onExit: (_) {
                  _overFlyout = false;
                  _scheduleClose();
                },
                child: Directionality(
                  textDirection:
                      widget.rtl ? TextDirection.rtl : TextDirection.ltr,
                  child: _RailFlyout<T>(
                    node: widget.node,
                    theme: t,
                    activeId: widget.activeId,
                    localizations: widget.localizations,
                    onNavigate: (n) {
                      widget.onNavigate(n);
                      _removeFlyout();
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_entry!);
  }

  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    final isModule = widget.node.hasChildren;
    final hasBadge = NavOps.subtreeHasBadge(widget.node);
    final isInteractive =
        widget.node.enabled && !widget.node.locked;

    final barStyle = t.selectionIndicator == NavSelectionIndicator.bar;
    Color bg = Colors.transparent;
    Color fg = t.fg2;
    if (widget.active) {
      if (isModule || barStyle) {
        bg = t.accentFill(0.12);
        fg = NavigationSidebarThemeData.accent;
      } else {
        bg = NavigationSidebarThemeData.accent;
        fg = Colors.white;
      }
    } else if (_hover) {
      bg = t.hover;
    }

    final badgeColor = widget.node.badge != null
        ? t.badgeColors(widget.node.badge!.tone).fg
        : NavigationSidebarThemeData.accent;

    return Semantics(
      button: isInteractive,
      selected: widget.active,
      label: widget.node.label +
          (widget.node.locked
              ? ', ${widget.localizations.semanticLocked}'
              : ''),
      child: CompositedTransformTarget(
        link: _link,
        child: MouseRegion(
          cursor: isInteractive
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
          onEnter: (_) {
            setState(() => _hover = true);
            _showFlyout();
          },
          onExit: (_) {
            setState(() => _hover = false);
            _scheduleClose();
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              // Modules open flyouts on hover; direct taps only navigate
              // leaf items. Guard against locked/disabled nodes.
              if (!isModule && isInteractive) {
                widget.onNavigate(widget.node);
              }
            },
            child: Tooltip(
              message: isModule ? '' : widget.node.label,
              child: Container(
                width: t.railButton,
                height: t.railButton,
                margin: const EdgeInsets.symmetric(vertical: 2.5),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(
                      t.radiusLg),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity:
                          widget.node.locked ? 0.45 : 1.0,
                      child: Icon(
                          widget.node.icon ?? Icons.circle_outlined,
                          size: t.railIconSize,
                          color: fg),
                    ),
                    if (barStyle && widget.active && !isModule)
                      PositionedDirectional(
                        start: 0,
                        top: t.railButton * 0.28,
                        bottom: t.railButton * 0.28,
                        child: Container(
                          width: t.indicatorThickness,
                          decoration: BoxDecoration(
                            color: NavigationSidebarThemeData.accent,
                            borderRadius:
                                BorderRadius.circular(t.indicatorThickness),
                          ),
                        ),
                      ),
                    if (hasBadge)
                      PositionedDirectional(
                        end: 6,
                        top: 6,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: badgeColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: t.surface, width: 1.5),
                          ),
                        ),
                      ),
                    if (widget.node.locked)
                      PositionedDirectional(
                        end: 6,
                        bottom: 6,
                        child:
                            Icon(Icons.lock_outline, size: 10, color: t.fg3),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RailFlyout<T> extends StatelessWidget {
  final NavNode<T> node;
  final NavigationSidebarThemeData theme;
  final NavNodeId? activeId;
  final NavigationSidebarLocalizations localizations;
  final ValueChanged<NavNode<T>> onNavigate;

  const _RailFlyout({
    required this.node,
    required this.theme,
    required this.activeId,
    required this.localizations,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 360),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(
              t.radiusXl),
          border: Border.all(color: t.borderStrong),
          boxShadow: NavigationSidebarThemeData.popShadow,
        ),
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
                child: Row(
                  children: [
                    Icon(node.icon ?? Icons.circle_outlined,
                        size: 17, color: t.fg2),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        node.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: t.fg1,
                          fontFamily:
                              NavigationSidebarThemeData.bodyFont,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: t.border),
              const SizedBox(height: 4),
              for (final group in node.children)
                _flyoutGroup(t, group),
            ],
          ),
        ),
      ),
    );
  }

  Widget _flyoutGroup(NavigationSidebarThemeData t, NavNode<T> group) {
    final leaves = group.hasChildren ? group.children : [group];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (group.hasChildren)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 3),
            child: Text(
              group.label.toUpperCase(),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: t.fg4,
              ),
            ),
          ),
        for (final leaf in leaves) _flyoutRow(t, leaf),
      ],
    );
  }

  Widget _flyoutRow(NavigationSidebarThemeData t, NavNode<T> leaf) {
    return _FlyoutRow<T>(
      leaf: leaf,
      theme: t,
      active: leaf.id == activeId,
      localizations: localizations,
      onTap: () => onNavigate(leaf),
    );
  }
}

class _FlyoutRow<T> extends StatefulWidget {
  final NavNode<T> leaf;
  final NavigationSidebarThemeData theme;
  final bool active;
  final NavigationSidebarLocalizations localizations;
  final VoidCallback onTap;

  const _FlyoutRow({
    required this.leaf,
    required this.theme,
    required this.active,
    required this.localizations,
    required this.onTap,
  });

  @override
  State<_FlyoutRow<T>> createState() => _FlyoutRowState<T>();
}

class _FlyoutRowState<T> extends State<_FlyoutRow<T>> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final l10n = widget.localizations;
    final active = widget.active;
    final isInteractive = widget.leaf.enabled && !widget.leaf.locked;

    return Semantics(
      button: isInteractive,
      selected: active,
      label: widget.leaf.label +
          (widget.leaf.locked ? ', ${l10n.semanticLocked}' : '') +
          (!widget.leaf.enabled ? ', ${l10n.semanticDisabled}' : ''),
      child: MouseRegion(
        cursor: isInteractive
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: isInteractive ? widget.onTap : null,
          child: Opacity(
            opacity: widget.leaf.locked ? 0.55 : 1.0,
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: active
                    ? t.accentFill(0.10)
                    : (_hover ? t.hover : Colors.transparent),
                borderRadius: BorderRadius.circular(
                    t.radiusMd),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                          color: active
                              ? NavigationSidebarThemeData.accent
                              : t.border),
                    ),
                    child: Icon(
                      widget.leaf.icon ?? Icons.circle,
                      size: 13,
                      color: active
                          ? NavigationSidebarThemeData.accent
                          : t.fg3,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.leaf.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: active
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: active
                            ? NavigationSidebarThemeData.accent
                            : t.fg1,
                        fontFamily: NavigationSidebarThemeData.bodyFont,
                      ),
                    ),
                  ),
                  if (widget.leaf.locked)
                    Icon(Icons.lock_outline, size: 12, color: t.fg3),
                  if (widget.leaf.badge != null)
                    _NavBadgeChip(badge: widget.leaf.badge!, small: true),
                  if (widget.leaf.shortcut != null) ...[
                    const SizedBox(width: 6),
                    _ShortcutHint(
                      keys: widget.leaf.shortcut!,
                      localizations: l10n,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// SHARED LEAF WIDGETS
// ════════════════════════════════════════════════════════════
class _NavBadgeChip extends StatelessWidget {
  final NavBadge badge;
  final bool small;
  const _NavBadgeChip({required this.badge, this.small = false});

  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    final c = t.badgeColors(badge.tone);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 5 : 6, vertical: small ? 2 : 3),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.border),
      ),
      child: Text(
        badge.text,
        style: TextStyle(
          fontFamily: NavigationSidebarThemeData.monoFont,
          fontSize: small ? 9 : 9.5,
          fontWeight: FontWeight.w700,
          height: 1.1,
          color: c.fg,
        ),
      ),
    );
  }
}

// ── Search field ───────────────────────────────────────────────────
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  const _SearchField(
      {required this.controller,
      required this.hint,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasText = value.text.isNotEmpty;
        return Container(
          height: 36,
          padding:
              const EdgeInsetsDirectional.only(start: 10, end: 4),
          decoration: BoxDecoration(
            color: t.inputBg,
            borderRadius: BorderRadius.circular(
                t.radiusMd),
            border: Border.all(color: t.border),
          ),
          child: Row(
            children: [
              Icon(Icons.search, size: 15, color: t.fg3),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  cursorColor: NavigationSidebarThemeData.accent,
                  style: TextStyle(
                    fontFamily: NavigationSidebarThemeData.bodyFont,
                    fontSize: 12.5,
                    color: t.fg1,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: TextStyle(
                      fontFamily: NavigationSidebarThemeData.bodyFont,
                      fontSize: 12.5,
                      color: t.fg4,
                    ),
                  ),
                ),
              ),
              if (hasText)
                InkWell(
                  onTap: () {
                    controller.clear();
                    onChanged('');
                  },
                  borderRadius: BorderRadius.circular(
                      t.radiusSm),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(Icons.close, size: 14, color: t.fg3),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Star toggle ────────────────────────────────────────────────────
class _StarButton extends StatelessWidget {
  final bool on;
  final bool onAccent;
  final NavigationSidebarLocalizations localizations;
  final VoidCallback? onTap;

  const _StarButton({
    required this.on,
    required this.onAccent,
    required this.localizations,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    final l10n = localizations;
    final color = on
        ? (onAccent ? Colors.white : NavigationSidebarThemeData.accent)
        : (onAccent ? Colors.white.withOpacity(0.8) : t.fg3);
    return Semantics(
      button: true,
      label: on ? l10n.removeFromQuickAccess : l10n.addToQuickAccess,
      child: Tooltip(
        message: on ? l10n.removeFromQuickAccess : l10n.addToQuickAccess,
        waitDuration: const Duration(milliseconds: 450),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 6),
            child: Icon(
              on ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 15,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shortcut keycap hint ───────────────────────────────────────────
class _ShortcutHint extends StatelessWidget {
  final List<String> keys;
  final bool onAccent;
  final NavigationSidebarLocalizations localizations;

  const _ShortcutHint({
    required this.keys,
    this.onAccent = false,
    this.localizations = const NavigationSidebarLocalizations(),
  });

  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    final capBg =
        onAccent ? Colors.white.withOpacity(0.20) : t.surface;
    final capBorder =
        onAccent ? Colors.white.withOpacity(0.38) : t.border;
    final capFg = onAccent ? Colors.white : t.fg3;

    Widget cap(String k) => Container(
          constraints: const BoxConstraints(minWidth: 17),
          alignment: Alignment.center,
          padding:
              const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: capBg,
            borderRadius: BorderRadius.circular(
                t.radiusSm),
            border: Border.all(color: capBorder),
            boxShadow: onAccent
                ? null
                : [
                    BoxShadow(
                        color: t.guide.withOpacity(0.55),
                        offset: const Offset(0, 1))
                  ],
          ),
          child: Text(
            k.toUpperCase(),
            style: TextStyle(
              fontFamily: NavigationSidebarThemeData.monoFont,
              fontSize: 9.5,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: capFg,
            ),
          ),
        );

    return Tooltip(
      message: localizations.shortcutTooltip(keys),
      waitDuration: const Duration(milliseconds: 450),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < keys.length; i++) ...[
            if (i > 0)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 2.5),
                child: Icon(Icons.chevron_right,
                    size: 10,
                    color: capFg.withOpacity(0.65)),
              ),
            cap(keys[i]),
          ],
        ],
      ),
    );
  }
}
