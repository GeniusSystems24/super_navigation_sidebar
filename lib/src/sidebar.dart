// ============================================================
// SuperNavigationSidebar — VIEW.
// ------------------------------------------------------------
// A thin, customisable render of SuperNavigationSidebarController<T>. Paints the
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
// All user-facing strings are sourced from generated package localizations.
// Register SuperNavigationLocalization.localizationsDelegates in the host app.
// The existing drawerTitle / searchHint / quickAccessTitle props still override
// their localization counterparts for backward compatibility.
//
//   File: lib/src/sidebar.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../localizations/generated/l10n.dart';
import 'controller.dart';
import 'models.dart';
import 'navigation_search_view.dart';
import 'theme.dart';

typedef SuperNavSidebarSlotBuilder =
    Widget Function(BuildContext context, bool collapsed);

String _plainNodeLabel<T>(SuperNavNode<T> node) {
  final label = node.label;
  if (label is Text) {
    return label.data ?? label.textSpan?.toPlainText() ?? node.id;
  }
  return node.keywords.isNotEmpty ? node.keywords.first : node.id;
}

class SuperNavigationSidebar<T> extends StatefulWidget {
  /// Initial sections. Required when [controller] is null.
  final List<SuperNavSection<T>>? sections;

  /// Active id on first build (ignored when a [controller] is supplied).
  final SuperNavNodeId? active;

  /// Ids expanded on first build (ignored when a [controller] is supplied).
  final Set<SuperNavNodeId>? initiallyExpanded;

  /// Drive/observe from outside. When null the widget owns a private one.
  final SuperNavigationSidebarController<T>? controller;

  /// How the sidebar is presented.
  final SuperNavSidebarMode mode;

  // ── slots ──
  final SuperNavSidebarSlotBuilder? header;
  final SuperNavSidebarSlotBuilder? footer;

  /// Eyebrow above the drawer close button. Overrides
  /// [localizations.drawerTitle] when set.
  final String? drawerTitle;

  // ── chrome toggles ──
  final bool showGuides;
  final bool railFlyouts;

  /// Show a pane-toggle (collapse ↔ expand) button pinned to the top of the
  /// pane — the NavigationView "menu button" placement. Off by default; enable
  /// it when the host does not provide its own pane toggle.
  final bool showPaneToggle;

  /// Show a built-in search field above the tree (expanded / drawer modes).
  final bool searchable;

  /// Placeholder for the [searchable] / [allowSearchView] field. Overrides
  /// [localizations.searchHint] when set.
  final String? searchHint;

  /// Enable the built-in [SuperNavigationSearchView] command palette.
  ///
  /// This is the single switch that turns on search view: the sidebar
  /// renders a search trigger inside the pane — a field in expanded / drawer
  /// modes, an icon button in rail mode — and opens the configured dialog or
  /// modal bottom sheet. No host-side modal wiring is required.
  ///
  /// Takes precedence over [searchable] when both are `true`.
  final bool allowSearchView;

  /// Presentation used when [allowSearchView] opens the built-in search view.
  final SuperNavigationSearchViewMode searchViewMode;

  /// Called when the user picks a result in the [allowSearchView] search view.
  ///
  /// The controller navigates to the picked node first; when this is null the
  /// sidebar falls back to [onNavigate]. Locked / disabled nodes never fire it.
  final ValueChanged<SuperNavNode<T>>? onSearchPick;

  /// Enable per-row star toggles and a synthesized "Quick Access" band.
  final bool favoritable;

  /// Roll numeric badge counts up onto collapsed modules.
  ///
  /// When `true`, a closed module whose descendants carry numeric badges
  /// (e.g. `SuperNavBadge('3')` pending approvals) shows the summed count as a
  /// chip instead of the plain accent dot — so "12 documents need you
  /// somewhere inside Finance" is visible without expanding the tree.
  /// Non-numeric badges (`'New'`) keep the dot. Default `false`.
  final bool aggregateBadges;

  /// Eyebrow for the Quick Access band. Overrides
  /// [localizations.quickAccessTitle] when set.
  final String? quickAccessTitle;

  /// Explicit localization strings for all user-facing text rendered by this
  /// widget.
  ///
  /// When null, strings are resolved from [SuperNavigationLocalization.of].
  /// Register [SuperNavigationLocalization.localizationsDelegates] in the host
  /// app and choose the locale through Flutter's standard localization setup.
  final SuperNavigationLocalization? localizations;

  // ── callbacks ──
  /// Called when a destination is successfully navigated to.
  ///
  /// Only fired when [SuperNavigationSidebarController.navigate] returns true —
  /// locked and disabled nodes never trigger this callback.
  final ValueChanged<SuperNavNode<T>>? onNavigate;

  const SuperNavigationSidebar({
    super.key,
    this.sections,
    this.active,
    this.initiallyExpanded,
    this.controller,
    this.mode = SuperNavSidebarMode.expanded,
    this.header,
    this.footer,
    this.drawerTitle,
    this.showGuides = true,
    this.railFlyouts = true,
    this.showPaneToggle = false,
    this.searchable = false,
    this.searchHint,
    this.allowSearchView = false,
    this.searchViewMode = SuperNavigationSearchViewMode.dialog,
    this.onSearchPick,
    this.favoritable = false,
    this.aggregateBadges = false,
    this.quickAccessTitle,
    this.localizations,
    this.onNavigate,
  }) : assert(
         sections != null || controller != null,
         'Provide sections or a controller.',
       );

  @override
  State<SuperNavigationSidebar<T>> createState() =>
      _NavigationSidebarState<T>();
}

class _NavigationSidebarState<T> extends State<SuperNavigationSidebar<T>> {
  late SuperNavigationSidebarController<T> _controller;
  bool _ownsController = false;
  final ScrollController _scroll = ScrollController();
  final TextEditingController _search = TextEditingController();

  SuperNavigationSidebarThemeData get _t =>
      SuperNavigationSidebarThemeData.of(context);
  SuperNavigationLocalization get _l10n =>
      widget.localizations ??
      Localizations.of<SuperNavigationLocalization>(
        context,
        SuperNavigationLocalization,
      ) ??
      lookupSuperNavigationLocalization(switch (Localizations.maybeLocaleOf(
        context,
      )?.languageCode) {
        'ar' => const Locale('ar'),
        _ => const Locale('en'),
      });
  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  // Resolved strings (explicit prop overrides localizations default).
  String get _drawerTitle => widget.drawerTitle ?? _l10n.drawerTitle;
  String get _searchHint => widget.searchHint ?? _l10n.searchHint;
  String get _quickAccessTitle =>
      widget.quickAccessTitle ?? _l10n.quickAccessTitle;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        SuperNavigationSidebarController<T>(
          sections: widget.sections!,
          active: widget.active,
          expanded: widget.initiallyExpanded,
          collapsed: widget.mode == SuperNavSidebarMode.rail,
        );
    _ownsController = widget.controller == null;
    _controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(covariant SuperNavigationSidebar<T> old) {
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
        widget.mode != SuperNavSidebarMode.drawer) {
      _controller.collapsed = widget.mode == SuperNavSidebarMode.rail;
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
  void _go(SuperNavNode<T> n) {
    if (!n.enabled || n.locked) return;
    final navigated = _controller.navigate(n.id);
    if (!navigated) return;
    n.onTap?.call(context);
    widget.onNavigate?.call(n);
  }

  /// Open the built-in [SuperNavigationSearchView].
  ///
  /// Enabled by [SuperNavigationSidebar.allowSearchView]; the sidebar owns the
  /// entire modal flow so host apps do not need to build the view themselves. On pick the
  /// controller navigates and [SuperNavigationSidebar.onSearchPick] (falling back
  /// to [SuperNavigationSidebar.onNavigate]) fires for the chosen node.
  void _openSearchView() {
    if (widget.mode == SuperNavSidebarMode.drawer) _controller.closeDrawer();
    showSuperNavigationSearchView<T>(
      context,
      controller: _controller,
      mode: widget.searchViewMode,
      hint: _searchHint,
      recentsLabel: _l10n.recentsTitle,
      onPick: (id) {
        if (!_controller.navigate(id)) return;
        final n = _controller.node(id);
        if (n == null) return;
        n.onTap?.call(context);
        (widget.onSearchPick ?? widget.onNavigate)?.call(n);
      },
    );
  }

  // Rail-mode search launcher (icon button sized like a rail item).
  Widget _railSearchButton(SuperNavigationSidebarThemeData t) {
    return Semantics(
      button: true,
      label: _searchHint,
      child: Tooltip(
        message: _searchHint,
        waitDuration: const Duration(milliseconds: 450),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _openSearchView,
            child: Container(
              width: t.railButton,
              height: t.railButton,
              alignment: Alignment.center,
              margin: const EdgeInsets.symmetric(vertical: 2.5),
              decoration: BoxDecoration(
                color: t.inputBg,
                borderRadius: BorderRadius.circular(t.radiusLg),
                border: Border.all(color: t.border),
              ),
              child: Icon(Icons.search, size: t.railIconSize, color: t.fg3),
            ),
          ),
        ),
      ),
    );
  }

  bool get _railed =>
      widget.mode == SuperNavSidebarMode.rail ||
      (widget.mode != SuperNavSidebarMode.drawer && _controller.collapsed);

  /// Sections that flow in the scrollable pane body.
  List<SuperNavSection<T>> get _bodySections => [
    for (final s in _controller.sections)
      if (s.placement == SuperNavSectionPlacement.body) s,
  ];

  /// Sections pinned to the bottom of the pane (e.g. Settings / Help).
  List<SuperNavSection<T>> get _footerSections => [
    for (final s in _controller.sections)
      if (s.placement == SuperNavSectionPlacement.footer) s,
  ];

  // Pane toggle (top-of-pane menu button).
  Widget _paneToggleRow(SuperNavigationSidebarThemeData t, bool railed) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 2),
      child: Align(
        alignment: railed ? Alignment.center : AlignmentDirectional.centerStart,
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
    SuperNavigationSidebarThemeData t,
    List<SuperNavSection<T>> footers,
  ) {
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
    SuperNavigationSidebarThemeData t,
    List<SuperNavSection<T>> footers,
  ) {
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
    return SuperNavigationSidebarScope<T>(
      controller: _controller,
      child: widget.mode == SuperNavSidebarMode.drawer
          ? _buildDrawer(_t)
          : _buildInline(_t),
    );
  }

  // ── inline panel (expanded / rail) ─────────────────────────
  Widget _buildInline(SuperNavigationSidebarThemeData t) {
    final railed = _railed;
    return AnimatedContainer(
      duration: SuperNavigationSidebarThemeData.durBase,
      curve: SuperNavigationSidebarThemeData.curveStandard,
      width: railed ? t.widthRail : t.widthExpanded,
      decoration: BoxDecoration(
        color: t.surface,
        border: BorderDirectional(end: BorderSide(color: t.border)),
      ),
      child: _panelContents(t, railed: railed, drawer: false),
    );
  }

  // ── drawer overlay ─────────────────────────────────────────
  Widget _buildDrawer(SuperNavigationSidebarThemeData t) {
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
                duration: SuperNavigationSidebarThemeData.durDrawer,
                opacity: open ? 1 : 0,
                child: const ColoredBox(color: Color(0x8C08090C)),
              ),
            ),
          ),
        ),
        AnimatedPositionedDirectional(
          duration: SuperNavigationSidebarThemeData.durDrawer,
          curve: SuperNavigationSidebarThemeData.curveStandard,
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
                boxShadow: open
                    ? SuperNavigationSidebarThemeData.popShadow
                    : null,
                border: BorderDirectional(end: BorderSide(color: t.border)),
              ),
              child: _panelContents(t, railed: false, drawer: true),
            ),
          ),
        ),
      ],
    );
  }

  Widget _panelContents(
    SuperNavigationSidebarThemeData t, {
    required bool railed,
    required bool drawer,
  }) {
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
          if (drawer) ...[_drawerHeader(t), const SizedBox(height: 2)],
          if (widget.header != null) ...[
            widget.header!(context, railed),
            const SizedBox(height: 12),
          ],
          if (widget.allowSearchView) ...[
            railed
                ? _railSearchButton(t)
                : _SearchTrigger(hint: _searchHint, onTap: _openSearchView),
            SizedBox(height: railed ? 6 : 10),
          ] else if (widget.searchable && !railed) ...[
            _SearchField(
              controller: _search,
              hint: _searchHint,
              onChanged: _controller.setQuery,
            ),
            const SizedBox(height: 10),
          ],
          Expanded(child: railed ? _railNav(t) : _expandedNav(t)),
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

  Widget _drawerHeader(SuperNavigationSidebarThemeData t) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          Text(
            _drawerTitle.toUpperCase(),
            style: TextStyle(
              fontFamily: SuperNavigationSidebarThemeData.monoFont,
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
              borderRadius: BorderRadius.circular(t.radiusSm),
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
  Widget _expandedNav(SuperNavigationSidebarThemeData t) {
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
                _l10n.searchEmpty(_controller.query.trim()),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: SuperNavigationSidebarThemeData.bodyFont,
                  fontSize: 12.5,
                  color: t.fg3,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final showQuickAccess =
        widget.favoritable &&
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
              for (final node in sec.items) _treeNode(t, node, 0, match),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }

  Widget _quickAccess(SuperNavigationSidebarThemeData t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Row(
            children: [
              const Icon(
                Icons.star_rounded,
                size: 13,
                color: SuperNavigationSidebarThemeData.accent,
              ),
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
            role: SuperNavNodeRole.direct,
            active: _controller.isActive(n.id),
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
    SuperNavigationSidebarThemeData t,
    SuperNavNode<T> node,
    int depth,
    Set<SuperNavNodeId>? match,
  ) {
    if (match != null && !match.contains(node.id)) {
      return const SizedBox.shrink();
    }
    final filtering = match != null;
    final role = SuperNavNodeRole.of(
      depth: depth,
      hasChildren: node.hasChildren,
    );

    if (node.isLeaf) {
      return _NavRow<T>(
        key: ValueKey('row-${node.id}'),
        node: node,
        depth: depth,
        role: role,
        active: _controller.isActive(node.id),
        query: _controller.query,
        favoritable: widget.favoritable,
        favorite: _controller.isFavorite(node.id),
        localizations: _l10n,
        onToggleFavorite: widget.favoritable
            ? () => _controller.toggleFavorite(node.id)
            : null,
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
          aggregateBadges: widget.aggregateBadges,
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
                  childRole: SuperNavNodeRole.of(
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
    SuperNavigationSidebarThemeData t, {
    required Widget child,
    required double lx,
    required SuperNavNodeRole childRole,
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
  Widget _railNav(SuperNavigationSidebarThemeData t) {
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
  final SuperNavNode<T> node;
  final int depth;
  final SuperNavNodeRole role;
  final bool expandable;
  final bool open;
  final bool active;
  final bool ownsActive;
  final bool aggregateBadges;
  final VoidCallback onTap;
  final String query;
  final bool favoritable;
  final bool favorite;
  final VoidCallback? onToggleFavorite;
  final SuperNavigationLocalization localizations;

  const _NavRow({
    super.key,
    required this.node,
    required this.depth,
    required this.role,
    this.expandable = false,
    this.open = false,
    this.active = false,
    this.ownsActive = false,
    this.aggregateBadges = false,
    this.query = '',
    this.favoritable = false,
    this.favorite = false,
    this.onToggleFavorite,
    required this.localizations,
    required this.onTap,
  });

  @override
  State<_NavRow<T>> createState() => _NavRowState<T>();
}

class _NavRowState<T> extends State<_NavRow<T>> {
  bool _hover = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final t = SuperNavigationSidebarThemeData.of(context);
    final l10n = widget.localizations;
    final pad = t.contentInset(widget.depth);
    final h = t.rowHeight(widget.role);
    final isInteractive = widget.node.enabled && !widget.node.locked;

    Widget content;
    switch (widget.role) {
      case SuperNavNodeRole.direct:
      case SuperNavNodeRole.module:
        content = _moduleOrDirect(t);
        break;
      case SuperNavNodeRole.group:
        content = _group(t);
        break;
      case SuperNavNodeRole.item:
        content = _item(t);
        break;
    }

    final radius =
        widget.role == SuperNavNodeRole.direct ||
            widget.role == SuperNavNodeRole.module
        ? t.radiusLg
        : t.radiusMd;

    final barStyle = t.selectionIndicator == SuperNavSelectionIndicator.bar;
    final bool isLeafRow =
        widget.role == SuperNavNodeRole.direct ||
        widget.role == SuperNavNodeRole.item;
    final bool showBar = barStyle && widget.active && isLeafRow;
    Color bg = Colors.transparent;
    if (widget.role == SuperNavNodeRole.direct && widget.active && !barStyle) {
      bg = SuperNavigationSidebarThemeData.accent;
    } else if (widget.active && isLeafRow) {
      bg = t.accentFill(barStyle ? 0.14 : 0.10);
    } else if (_hover || _focused) {
      bg = t.hover;
    }

    // Build accessible label for screen readers.
    final buffer = StringBuffer(_plainNodeLabel(widget.node));
    if (widget.expandable) {
      buffer.write(
        ', ${widget.open ? l10n.semanticExpanded : l10n.semanticCollapsed}',
      );
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
        onFocusChange: (f) => setState(() => _focused = f),
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
                      duration: SuperNavigationSidebarThemeData.durFast,
                      height: h,
                      padding: EdgeInsetsDirectional.only(start: pad, end: 10),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(radius),
                        border: Border.all(
                          color: _focused
                              ? SuperNavigationSidebarThemeData.accent
                                    .withValues(alpha: 0.55)
                              : Colors.transparent,
                        ),
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
                            color: SuperNavigationSidebarThemeData.accent,
                            borderRadius: BorderRadius.circular(
                              t.indicatorThickness,
                            ),
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
    return child;
  }

  Widget _label(String text, TextStyle style) {
    final q = widget.query.trim().toLowerCase();
    if (q.isEmpty) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    final lower = text.toLowerCase();
    final i = lower.indexOf(q);
    if (i < 0) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    final hi = style.copyWith(
      color: SuperNavigationSidebarThemeData.accent,
      fontWeight: FontWeight.w800,
    );
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, i)),
          TextSpan(text: text.substring(i, i + q.length), style: hi),
          TextSpan(text: text.substring(i + q.length)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _labelWidget(SuperNavigationSidebarThemeData t, TextStyle style) {
    final label = widget.node.label;
    if (label is Text) {
      final text = label.data ?? label.textSpan?.toPlainText();
      if (text != null) return _label(text, style);
    }
    return DefaultTextStyle.merge(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
      child: label,
    );
  }

  Widget _statusDot(SuperNavigationSidebarThemeData t) {
    final c = t.statusColor(widget.node.status);
    if (c == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 7),
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      ),
    );
  }

  Widget _trailing(
    SuperNavigationSidebarThemeData t, {
    required bool onAccent,
  }) {
    if (widget.node.locked) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(start: 6),
        child: Icon(
          Icons.lock_outline,
          size: 13,
          color: onAccent ? Colors.white : t.fg3,
        ),
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

  Widget _chevron(SuperNavigationSidebarThemeData t) {
    return AnimatedRotation(
      turns: widget.open ? 0.5 : 0,
      duration: SuperNavigationSidebarThemeData.durBase,
      curve: SuperNavigationSidebarThemeData.curveStandard,
      child: Icon(Icons.keyboard_arrow_down, size: 16, color: t.fg3),
    );
  }

  Widget _moduleOrDirect(SuperNavigationSidebarThemeData t) {
    final isDirect = widget.role == SuperNavNodeRole.direct;
    final barStyle = t.selectionIndicator == SuperNavSelectionIndicator.bar;
    final fillActive = isDirect && widget.active && !barStyle;
    final Color tint = isDirect
        ? (fillActive
              ? Colors.white
              : (widget.active
                    ? SuperNavigationSidebarThemeData.accent
                    : t.fg2))
        : (widget.ownsActive ? SuperNavigationSidebarThemeData.accent : t.fg2);
    final bold = widget.active || widget.ownsActive;
    final closedWithBadges =
        !isDirect && !widget.open && SuperNavOps.subtreeHasBadge(widget.node);
    final badgeSum = closedWithBadges && widget.aggregateBadges
        ? SuperNavOps.subtreeBadgeSum(widget.node)
        : 0;
    final moduleDot = closedWithBadges && badgeSum == 0;

    return Row(
      children: [
        IconTheme(
          data: IconThemeData(size: t.iconTop, color: tint),
          child: widget.node.leadingIcon ?? const Icon(Icons.circle_outlined),
        ),
        const SizedBox(width: 12),
        if (widget.node.status != SuperNavNodeStatus.none) _statusDot(t),
        Expanded(
          child: _labelWidget(
            t,
            TextStyle(
              fontFamily: SuperNavigationSidebarThemeData.bodyFont,
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
        if (isDirect) _trailing(t, onAccent: fillActive),
        if (badgeSum > 0) ...[
          const SizedBox(width: 6),
          _NavBadgeChip(badge: SuperNavBadge('$badgeSum'), small: true),
        ],
        if (moduleDot) ...[
          const SizedBox(width: 6),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: SuperNavigationSidebarThemeData.accent,
              shape: BoxShape.circle,
            ),
          ),
        ],
        if (widget.expandable) ...[const SizedBox(width: 4), _chevron(t)],
      ],
    );
  }

  Widget _group(SuperNavigationSidebarThemeData t) {
    final tint = widget.ownsActive
        ? SuperNavigationSidebarThemeData.accent
        : t.fg3;
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: widget.ownsActive
                ? SuperNavigationSidebarThemeData.accent
                : t.fg4,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            _plainNodeLabel(widget.node).toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: SuperNavigationSidebarThemeData.bodyFont,
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

  Widget _item(SuperNavigationSidebarThemeData t) {
    final active = widget.active;
    return Row(
      children: [
        Container(
          width: t.itemBox,
          height: t.itemBox,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(t.radiusMd),
            border: Border.all(
              color: active ? SuperNavigationSidebarThemeData.accent : t.border,
            ),
            color: active ? t.accentFill(0.12) : t.surface,
          ),
          child: IconTheme(
            data: IconThemeData(
              size: t.iconItem,
              color: active ? SuperNavigationSidebarThemeData.accent : t.fg3,
            ),
            child: widget.node.leadingIcon ?? const Icon(Icons.circle),
          ),
        ),
        const SizedBox(width: 10),
        if (widget.node.status != SuperNavNodeStatus.none) _statusDot(t),
        Expanded(
          child: _labelWidget(
            t,
            TextStyle(
              fontFamily: SuperNavigationSidebarThemeData.bodyFont,
              fontSize: 12.5,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: active ? SuperNavigationSidebarThemeData.accent : t.fg2,
            ),
          ),
        ),
        if (widget.node.badge != null) ...[
          const SizedBox(width: 6),
          _NavBadgeChip(badge: widget.node.badge!, small: true),
        ],
        _trailing(t, onAccent: false),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// RAIL ITEM — 44×44 icon button with optional hover flyout.
// ════════════════════════════════════════════════════════════
class _RailItem<T> extends StatefulWidget {
  final SuperNavNode<T> node;
  final bool active;
  final SuperNavNodeId? activeId;
  final bool flyouts;
  final bool rtl;
  final SuperNavigationLocalization localizations;
  final ValueChanged<SuperNavNode<T>> onNavigate;

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
    final t = SuperNavigationSidebarThemeData.of(context);
    final themeData = Theme.of(context);
    const flyW = 248.0;
    _entry = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          width: flyW,
          child: CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            targetAnchor: widget.rtl ? Alignment.topLeft : Alignment.topRight,
            followerAnchor: widget.rtl ? Alignment.topRight : Alignment.topLeft,
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
                  textDirection: widget.rtl
                      ? TextDirection.rtl
                      : TextDirection.ltr,
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
    final t = SuperNavigationSidebarThemeData.of(context);
    final isModule = widget.node.hasChildren;
    final hasBadge = SuperNavOps.subtreeHasBadge(widget.node);
    final isInteractive = widget.node.enabled && !widget.node.locked;

    final barStyle = t.selectionIndicator == SuperNavSelectionIndicator.bar;
    Color bg = Colors.transparent;
    Color fg = t.fg2;
    if (widget.active) {
      if (isModule || barStyle) {
        bg = t.accentFill(0.12);
        fg = SuperNavigationSidebarThemeData.accent;
      } else {
        bg = SuperNavigationSidebarThemeData.accent;
        fg = Colors.white;
      }
    } else if (_hover) {
      bg = t.hover;
    }

    final badgeColor = widget.node.badge != null
        ? t.badgeColors(widget.node.badge!.tone).fg
        : SuperNavigationSidebarThemeData.accent;

    return Semantics(
      button: isInteractive,
      selected: widget.active,
      label:
          _plainNodeLabel(widget.node) +
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
              // Leaf items navigate on tap. Modules toggle their flyout on
              // tap too — hover-only flyouts are unreachable on touch
              // devices (tablets / hybrid POS terminals).
              if (isModule) {
                _entry != null ? _removeFlyout() : _showFlyout();
              } else if (isInteractive) {
                widget.onNavigate(widget.node);
              }
            },
            child: Tooltip(
              message: isModule ? '' : _plainNodeLabel(widget.node),
              child: Container(
                width: t.railButton,
                height: t.railButton,
                margin: const EdgeInsets.symmetric(vertical: 2.5),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(t.radiusLg),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: widget.node.locked ? 0.45 : 1.0,
                      child: IconTheme(
                        data: IconThemeData(size: t.railIconSize, color: fg),
                        child:
                            widget.node.leadingIcon ??
                            const Icon(Icons.circle_outlined),
                      ),
                    ),
                    if (barStyle && widget.active && !isModule)
                      PositionedDirectional(
                        start: 0,
                        top: t.railButton * 0.28,
                        bottom: t.railButton * 0.28,
                        child: Container(
                          width: t.indicatorThickness,
                          decoration: BoxDecoration(
                            color: SuperNavigationSidebarThemeData.accent,
                            borderRadius: BorderRadius.circular(
                              t.indicatorThickness,
                            ),
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
                            border: Border.all(color: t.surface, width: 1.5),
                          ),
                        ),
                      ),
                    if (widget.node.locked)
                      PositionedDirectional(
                        end: 6,
                        bottom: 6,
                        child: Icon(Icons.lock_outline, size: 10, color: t.fg3),
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
  final SuperNavNode<T> node;
  final SuperNavigationSidebarThemeData theme;
  final SuperNavNodeId? activeId;
  final SuperNavigationLocalization localizations;
  final ValueChanged<SuperNavNode<T>> onNavigate;

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
          borderRadius: BorderRadius.circular(t.radiusXl),
          border: Border.all(color: t.borderStrong),
          boxShadow: SuperNavigationSidebarThemeData.popShadow,
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
                    IconTheme(
                      data: IconThemeData(size: 17, color: t.fg2),
                      child:
                          node.leadingIcon ?? const Icon(Icons.circle_outlined),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: DefaultTextStyle.merge(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: t.fg1,
                          fontFamily: SuperNavigationSidebarThemeData.bodyFont,
                        ),
                        child: node.label,
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: t.border),
              const SizedBox(height: 4),
              for (final group in node.children) _flyoutGroup(t, group),
            ],
          ),
        ),
      ),
    );
  }

  Widget _flyoutGroup(
    SuperNavigationSidebarThemeData t,
    SuperNavNode<T> group,
  ) {
    final leaves = group.hasChildren ? group.children : [group];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (group.hasChildren)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 3),
            child: Text(
              _plainNodeLabel(group).toUpperCase(),
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

  Widget _flyoutRow(SuperNavigationSidebarThemeData t, SuperNavNode<T> leaf) {
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
  final SuperNavNode<T> leaf;
  final SuperNavigationSidebarThemeData theme;
  final bool active;
  final SuperNavigationLocalization localizations;
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
      label:
          _plainNodeLabel(widget.leaf) +
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
                borderRadius: BorderRadius.circular(t.radiusMd),
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
                            ? SuperNavigationSidebarThemeData.accent
                            : t.border,
                      ),
                    ),
                    child: IconTheme(
                      data: IconThemeData(
                        size: 13,
                        color: active
                            ? SuperNavigationSidebarThemeData.accent
                            : t.fg3,
                      ),
                      child:
                          widget.leaf.leadingIcon ?? const Icon(Icons.circle),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DefaultTextStyle.merge(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                        color: active
                            ? SuperNavigationSidebarThemeData.accent
                            : t.fg1,
                        fontFamily: SuperNavigationSidebarThemeData.bodyFont,
                      ),
                      child: widget.leaf.label,
                    ),
                  ),
                  if (widget.leaf.locked)
                    Icon(Icons.lock_outline, size: 12, color: t.fg3),
                  if (widget.leaf.badge != null)
                    _NavBadgeChip(badge: widget.leaf.badge!, small: true),
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
  final SuperNavBadge badge;
  final bool small;
  const _NavBadgeChip({required this.badge, this.small = false});

  @override
  Widget build(BuildContext context) {
    final t = SuperNavigationSidebarThemeData.of(context);
    final c = t.badgeColors(badge.tone);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 5 : 6,
        vertical: small ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.border),
      ),
      child: Text(
        badge.text,
        style: TextStyle(
          fontFamily: SuperNavigationSidebarThemeData.monoFont,
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
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = SuperNavigationSidebarThemeData.of(context);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasText = value.text.isNotEmpty;
        return Container(
          height: 36,
          padding: const EdgeInsetsDirectional.only(start: 10, end: 4),
          decoration: BoxDecoration(
            color: t.inputBg,
            borderRadius: BorderRadius.circular(t.radiusMd),
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
                  cursorColor: SuperNavigationSidebarThemeData.accent,
                  style: TextStyle(
                    fontFamily: SuperNavigationSidebarThemeData.bodyFont,
                    fontSize: 12.5,
                    color: t.fg1,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: TextStyle(
                      fontFamily: SuperNavigationSidebarThemeData.bodyFont,
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
                  borderRadius: BorderRadius.circular(t.radiusSm),
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
// ── Search view trigger ──────────────────────────────────
// A field-styled button that opens SuperNavigationSearchView. Rendered inside the pane
// when SuperNavigationSidebar.allowSearchView is enabled (expanded / drawer).
class _SearchTrigger extends StatefulWidget {
  final String hint;
  final VoidCallback onTap;
  const _SearchTrigger({required this.hint, required this.onTap});

  @override
  State<_SearchTrigger> createState() => _SearchTriggerState();
}

class _SearchTriggerState extends State<_SearchTrigger> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = SuperNavigationSidebarThemeData.of(context);
    return Semantics(
      button: true,
      label: widget.hint,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: SuperNavigationSidebarThemeData.durFast,
            height: 36,
            padding: const EdgeInsetsDirectional.only(start: 10, end: 8),
            decoration: BoxDecoration(
              color: t.inputBg,
              borderRadius: BorderRadius.circular(t.radiusMd),
              border: Border.all(color: _hover ? t.borderStrong : t.border),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 15, color: t.fg3),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: SuperNavigationSidebarThemeData.bodyFont,
                      fontSize: 12.5,
                      color: t.fg4,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: t.border),
                    borderRadius: BorderRadius.circular(t.radiusSm),
                  ),
                  child: Text(
                    '/',
                    style: TextStyle(
                      fontFamily: SuperNavigationSidebarThemeData.monoFont,
                      fontSize: 10,
                      color: t.fg4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StarButton extends StatelessWidget {
  final bool on;
  final bool onAccent;
  final SuperNavigationLocalization localizations;
  final VoidCallback? onTap;

  const _StarButton({
    required this.on,
    required this.onAccent,
    required this.localizations,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = SuperNavigationSidebarThemeData.of(context);
    final l10n = localizations;
    final color = on
        ? (onAccent ? Colors.white : SuperNavigationSidebarThemeData.accent)
        : (onAccent ? Colors.white.withValues(alpha: 0.8) : t.fg3);
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

typedef NavSidebarSlotBuilder = SuperNavSidebarSlotBuilder;
typedef NavigationSidebar<T> = SuperNavigationSidebar<T>;
