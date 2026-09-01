// ============================================================
// NavigationSidebar — NAVIGATION SEARCH VIEW.
// ------------------------------------------------------------
// Reusable navigation search surface for package 3.0.0. The view itself is
// presentation-agnostic and can be embedded directly or opened through the
// built-in dialog / bottom-sheet presenter.
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_core/super_core.dart';
import 'package:super_form_field/super_form_field.dart';

import 'controller.dart';
import 'models.dart';
import 'theme.dart';

/// How [showNavigationSearchView] presents [NavigationSearchView].
enum NavigationSearchViewMode {
  /// Centered modal dialog, intended for desktop/tablet layouts.
  dialog,

  /// Modal bottom sheet, intended for compact/mobile layouts.
  sheet,
}

/// A flattened searchable destination extracted from the navigation tree.
@immutable
class NavSearchHit {
  final NavNodeId id;
  final Widget label;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final String? code;
  final List<String> keywords;
  final String module;
  final String group;
  final NavBadge? badge;

  const NavSearchHit({
    required this.id,
    required this.label,
    this.leadingIcon,
    this.trailingIcon,
    this.code,
    this.keywords = const [],
    required this.module,
    required this.group,
    this.badge,
  });

  String get haystack =>
      '${_plainLabelFromWidget(label, fallback: id)} ${code ?? ''} '
              '${keywords.join(' ')} $group $module'
          .toLowerCase();
}

String _plainLabelFromWidget(Widget label, {required String fallback}) {
  if (label is Text) {
    return label.data ?? label.textSpan?.toPlainText() ?? fallback;
  }
  return fallback;
}

/// Helpers for building and querying the navigation search index.
class NavSearchOps {
  NavSearchOps._();

  static List<NavSearchHit> buildIndex<T>(List<NavSection<T>> sections) {
    final out = <NavSearchHit>[];
    for (final section in sections) {
      for (final top in section.items) {
        if (top.isLeaf) {
          out.add(
            NavSearchHit(
              id: top.id,
              label: top.label,
              code: top.code,
              keywords: top.keywords,
              leadingIcon: top.leadingIcon,
              trailingIcon: top.trailingIcon,
              module: section.title,
              group: '',
              badge: top.badge,
            ),
          );
          continue;
        }

        for (final group in top.children) {
          final leaves = group.hasChildren
              ? group.children
              : <NavNode<T>>[group];
          for (final leaf in leaves) {
            if (!leaf.isLeaf) continue;
            out.add(
              NavSearchHit(
                id: leaf.id,
                label: leaf.label,
                code: leaf.code,
                keywords: leaf.keywords,
                leadingIcon: leaf.leadingIcon,
                trailingIcon: leaf.trailingIcon,
                module: _plainLabelFromWidget(top.label, fallback: top.id),
                group: group.hasChildren
                    ? _plainLabelFromWidget(group.label, fallback: group.id)
                    : '',
                badge: leaf.badge,
              ),
            );
          }
        }
      }
    }
    return out;
  }

  static List<NavSearchHit> filter(List<NavSearchHit> index, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return index;
    final tokens = normalized.split(RegExp(r'\s+'));
    return index
        .where((hit) => tokens.every(hit.haystack.contains))
        .toList(growable: false);
  }
}

/// Search UI for navigating to any leaf in a [NavigationSidebarController].
///
/// The widget does not assume a modal presentation. Embed it directly, or use
/// [showNavigationSearchView] with [NavigationSearchViewMode.dialog] or
/// [NavigationSearchViewMode.sheet].
class NavigationSearchView<T> extends StatefulWidget {
  final NavigationSidebarController<T> controller;
  final ValueChanged<NavNodeId>? onPick;
  final VoidCallback? onClose;
  final String hint;
  final String recentsLabel;
  final bool autofocus;
  final bool closeOnPick;
  final bool showKeyboardHints;

  const NavigationSearchView({
    super.key,
    required this.controller,
    this.onPick,
    this.onClose,
    this.hint = 'Search navigation…',
    this.recentsLabel = 'Recent',
    this.autofocus = true,
    this.closeOnPick = true,
    this.showKeyboardHints = true,
  });

  @override
  State<NavigationSearchView<T>> createState() =>
      _NavigationSearchViewState<T>();
}

class _NavigationSearchViewState<T> extends State<NavigationSearchView<T>> {
  late List<NavSearchHit> _index;
  late final FocusNode _searchFocusNode = FocusNode(
    onKeyEvent: _onSearchFieldKey,
  );
  late final SuperTextFieldController _searchFieldController =
      SuperTextFieldController(focusNode: _searchFocusNode);
  final ScrollController _resultsScrollController = ScrollController();
  final Map<int, GlobalKey> _resultKeys = <int, GlobalKey>{};
  String _query = '';
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _rebuildIndex();
    widget.controller.addListener(_controllerChanged);
  }

  @override
  void didUpdateWidget(covariant NavigationSearchView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_controllerChanged);
      widget.controller.addListener(_controllerChanged);
      _rebuildIndex();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_controllerChanged);
    _searchFieldController.dispose();
    _searchFocusNode.dispose();
    _resultsScrollController.dispose();
    super.dispose();
  }

  void _rebuildIndex() {
    _index = NavSearchOps.buildIndex<T>(widget.controller.sections);
  }

  void _controllerChanged() {
    if (!mounted) return;
    final next = NavSearchOps.buildIndex<T>(widget.controller.sections);
    setState(() => _index = next);
  }

  List<NavSearchHit> get _results => NavSearchOps.filter(_index, _query);

  List<NavSearchHit> get _recentHits {
    final byId = <NavNodeId, NavSearchHit>{for (final h in _index) h.id: h};
    return <NavSearchHit>[
      for (final id in widget.controller.recents)
        if (byId[id] != null) byId[id]!,
    ];
  }

  List<(String, List<NavSearchHit>)> _bands(List<NavSearchHit> results) {
    final bands = <(String, List<NavSearchHit>)>[];
    if (_query.trim().isEmpty && _recentHits.isNotEmpty) {
      bands.add((widget.recentsLabel, _recentHits));
    }

    final grouped = <String, List<NavSearchHit>>{};
    for (final hit in results) {
      grouped.putIfAbsent(hit.module, () => <NavSearchHit>[]).add(hit);
    }
    for (final entry in grouped.entries) {
      bands.add((entry.key, entry.value));
    }
    return bands;
  }

  void _pick(NavNodeId id) {
    if (widget.onPick != null) {
      widget.onPick!(id);
    } else {
      widget.controller.navigate(id);
    }
    if (widget.closeOnPick) widget.onClose?.call();
  }

  GlobalKey _resultKey(int index) => _resultKeys.putIfAbsent(
    index,
    () => GlobalKey(debugLabel: 'navigation-search-result-$index'),
  );

  void _moveSelection(int delta, int resultCount) {
    if (resultCount == 0) return;

    final next = delta > 0
        ? (_selected + 1) % resultCount
        : (_selected - 1 + resultCount) % resultCount;

    setState(() => _selected = next);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollSelectedIntoView(resultCount, delta);
    });
  }

  ScrollPositionAlignmentPolicy _alignmentPolicyFor(
    int selectedIndex,
    int resultCount,
    int direction,
  ) {
    if (selectedIndex == 0) {
      return ScrollPositionAlignmentPolicy.keepVisibleAtStart;
    }
    if (selectedIndex == resultCount - 1) {
      return ScrollPositionAlignmentPolicy.keepVisibleAtEnd;
    }
    return direction > 0
        ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
        : ScrollPositionAlignmentPolicy.keepVisibleAtStart;
  }

  void _scrollSelectedIntoView(int resultCount, int direction) {
    if (resultCount == 0 || !_resultsScrollController.hasClients) return;

    final selectedIndex = _selected;
    final alignmentPolicy = _alignmentPolicyFor(
      selectedIndex,
      resultCount,
      direction,
    );
    final selectedContext = _resultKeys[selectedIndex]?.currentContext;
    if (selectedContext != null && selectedContext.mounted) {
      Scrollable.ensureVisible(
        selectedContext,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignmentPolicy: alignmentPolicy,
      );
      return;
    }

    // A lazily built ListView can temporarily have no BuildContext for a
    // destination outside its cache extent. Move the viewport toward the
    // selection first, then run ensureVisible once that row is mounted.
    final position = _resultsScrollController.position;
    final double target;
    if (selectedIndex == 0) {
      target = position.minScrollExtent;
    } else if (selectedIndex == resultCount - 1) {
      target = position.maxScrollExtent;
    } else {
      const estimatedRowExtent = 54.0;
      target =
          (selectedIndex * estimatedRowExtent -
                  position.viewportDimension * 0.45)
              .clamp(position.minScrollExtent, position.maxScrollExtent)
              .toDouble();
    }

    _resultsScrollController
        .animateTo(
          target,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
        )
        .then((_) {
          if (!mounted || selectedIndex != _selected) return;
          final context = _resultKeys[selectedIndex]?.currentContext;
          if (context == null || !context.mounted) return;
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            alignmentPolicy: alignmentPolicy,
          );
        });
  }

  KeyEventResult _onKey(
    FocusNode node,
    KeyEvent event,
    List<NavSearchHit> flat,
  ) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape:
        widget.onClose?.call();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _moveSelection(1, flat.length);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _moveSelection(-1, flat.length);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
        if (flat.isNotEmpty && _selected < flat.length) {
          _pick(flat[_selected].id);
        }
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  List<NavSearchHit> _currentFlatResults() {
    return <NavSearchHit>[for (final band in _bands(_results)) ...band.$2];
  }

  KeyEventResult _onSearchFieldKey(FocusNode node, KeyEvent event) {
    return _onKey(node, event, _currentFlatResults());
  }

  @override
  Widget build(BuildContext context) {
    final theme = NavigationSidebarThemeData.of(context);
    final results = _results;
    final bands = _bands(results);
    final flat = <NavSearchHit>[for (final band in bands) ...band.$2];
    _resultKeys.removeWhere((index, _) => index >= flat.length);
    if (_selected >= flat.length) {
      _selected = flat.isEmpty ? 0 : flat.length - 1;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 560.0;
        final height = math.min(math.max(available, 320.0), 720.0);
        return SizedBox(
          height: height,
          child: CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const SingleActivator(LogicalKeyboardKey.arrowDown): () {
                _moveSelection(1, flat.length);
              },
              const SingleActivator(LogicalKeyboardKey.arrowUp): () {
                _moveSelection(-1, flat.length);
              },
              const SingleActivator(LogicalKeyboardKey.enter): () {
                if (flat.isNotEmpty && _selected < flat.length) {
                  _pick(flat[_selected].id);
                }
              },
              const SingleActivator(LogicalKeyboardKey.numpadEnter): () {
                if (flat.isNotEmpty && _selected < flat.length) {
                  _pick(flat[_selected].id);
                }
              },
              const SingleActivator(LogicalKeyboardKey.escape): () {
                widget.onClose?.call();
              },
            },
            child: Focus(
              onKeyEvent: (node, event) => _onKey(node, event, flat),
              child: Material(
                color: theme.surface,
                borderRadius: BorderRadius.circular(theme.radiusXl),
                clipBehavior: Clip.antiAlias,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.borderStrong),
                    borderRadius: BorderRadius.circular(theme.radiusXl),
                  ),
                  child: Column(
                    children: [
                      _buildInput(theme),
                      Expanded(
                        child: _buildResults(theme, results, bands, flat),
                      ),
                      if (widget.showKeyboardHints) _buildFooter(theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInput(NavigationSidebarThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Localizations.override(
              context: context,
              delegates: SuperFormLocalizations.localizationsDelegates,
              child: SuperTextFormField(
                key: const ValueKey('navigation-search-input'),
                controller: _searchFieldController,
                autofocus: widget.autofocus,
                clearable: true,
                density: FieldDensity.compact,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  prefixIcon: Icon(Icons.search, size: 20, color: theme.fg3),
                ),
                style: TextStyle(
                  color: theme.fg1,
                  fontSize: 15,
                  fontFamily: NavigationSidebarThemeData.bodyFont,
                ),
                onChanged: (value) {
                  setState(() {
                    _query = value;
                    _selected = 0;
                  });
                },
              ),
            ),
          ),
          if (widget.onClose != null) ...[
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Close',
              onPressed: widget.onClose,
              icon: Icon(Icons.close_fullscreen, size: 18, color: theme.fg3),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResults(
    NavigationSidebarThemeData theme,
    List<NavSearchHit> results,
    List<(String, List<NavSearchHit>)> bands,
    List<NavSearchHit> flat,
  ) {
    if (results.isEmpty && _query.trim().isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 36, color: theme.fg4),
              const SizedBox(height: 12),
              Text(
                'No navigation results for “${_query.trim()}”',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.fg3, fontSize: 13.5),
              ),
            ],
          ),
        ),
      );
    }

    var flatIndex = 0;
    return ListView(
      controller: _resultsScrollController,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
          child: Text(
            _query.trim().isEmpty
                ? 'ALL DESTINATIONS · ${_index.length}'
                : '${results.length} RESULT${results.length == 1 ? '' : 'S'}',
            style: TextStyle(
              fontFamily: NavigationSidebarThemeData.monoFont,
              fontSize: 10,
              letterSpacing: 1.1,
              color: theme.fg4,
            ),
          ),
        ),
        for (final band in bands) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 5),
            child: Text(
              band.$1.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 10.5,
                letterSpacing: 1.2,
                color: theme.fg3,
              ),
            ),
          ),
          for (final hit in band.$2)
            _NavigationSearchResultRow(
              key: _resultKey(flatIndex),
              hit: hit,
              active: widget.controller.isActive(hit.id),
              highlighted: flatIndex++ == _selected,
              onTap: () => _pick(hit.id),
            ),
        ],
      ],
    );
  }

  Widget _buildFooter(NavigationSidebarThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.border)),
      ),
      child: Row(
        children: [
          _NavigationSearchKeyHint(kbd: '↑↓', label: 'navigate', theme: theme),
          const SizedBox(width: 16),
          _NavigationSearchKeyHint(kbd: '↵', label: 'open', theme: theme),
          const SizedBox(width: 16),
          _NavigationSearchKeyHint(kbd: 'esc', label: 'close', theme: theme),
        ],
      ),
    );
  }
}

class _NavigationSearchResultRow extends StatefulWidget {
  final NavSearchHit hit;
  final bool active;
  final bool highlighted;
  final VoidCallback onTap;

  const _NavigationSearchResultRow({
    super.key,
    required this.hit,
    required this.active,
    required this.highlighted,
    required this.onTap,
  });

  @override
  State<_NavigationSearchResultRow> createState() =>
      _NavigationSearchResultRowState();
}

class _NavigationSearchResultRowState
    extends State<_NavigationSearchResultRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = NavigationSidebarThemeData.of(context);
    final highlighted = widget.highlighted || widget.active;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: highlighted
                ? theme.accentFill(0.10)
                : (_hovered ? theme.hover : Colors.transparent),
            borderRadius: BorderRadius.circular(theme.radiusMd),
            border: Border.all(
              color: widget.highlighted
                  ? NavigationSidebarThemeData.accent.withValues(alpha: 0.45)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.active ? theme.accentFill(0.16) : theme.inputBg,
                  borderRadius: BorderRadius.circular(theme.radiusMd),
                ),
                child: IconTheme(
                  data: IconThemeData(
                    size: 16,
                    color: widget.active
                        ? NavigationSidebarThemeData.accent
                        : theme.fg3,
                  ),
                  child:
                      widget.hit.leadingIcon ??
                      const Icon(Icons.circle_outlined),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DefaultTextStyle.merge(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: theme.fg1,
                      ),
                      child: widget.hit.label,
                    ),
                    Text(
                      widget.hit.group.isEmpty
                          ? widget.hit.module
                          : widget.hit.group,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: NavigationSidebarThemeData.monoFont,
                        color: theme.fg3,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.hit.code != null) ...[
                Container(
                  margin: const EdgeInsetsDirectional.only(end: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.inputBg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: theme.border),
                  ),
                  child: Text(
                    widget.hit.code!.toUpperCase(),
                    style: TextStyle(
                      fontFamily: NavigationSidebarThemeData.monoFont,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: theme.fg3,
                    ),
                  ),
                ),
              ],
              if (widget.hit.badge != null)
                _NavigationSearchBadge(badge: widget.hit.badge!),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationSearchBadge extends StatelessWidget {
  final NavBadge badge;

  const _NavigationSearchBadge({required this.badge});

  @override
  Widget build(BuildContext context) {
    final theme = NavigationSidebarThemeData.of(context);
    final colors = theme.badgeColors(badge.tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        badge.text,
        style: TextStyle(
          fontFamily: NavigationSidebarThemeData.monoFont,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: colors.fg,
        ),
      ),
    );
  }
}

class _NavigationSearchKeyHint extends StatelessWidget {
  final String kbd;
  final String label;
  final NavigationSidebarThemeData theme;

  const _NavigationSearchKeyHint({
    required this.kbd,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            border: Border.all(color: theme.border),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            kbd,
            style: TextStyle(
              fontFamily: NavigationSidebarThemeData.monoFont,
              fontSize: 10.5,
              color: theme.fg3,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: NavigationSidebarThemeData.monoFont,
            fontSize: 10.5,
            color: theme.fg4,
          ),
        ),
      ],
    );
  }
}

/// Presents [NavigationSearchView] as either a dialog or modal bottom sheet.
Future<void> showNavigationSearchView<T>(
  BuildContext context, {
  required NavigationSidebarController<T> controller,
  NavigationSearchViewMode mode = NavigationSearchViewMode.dialog,
  ValueChanged<NavNodeId>? onPick,
  String hint = 'Search navigation…',
  String recentsLabel = 'Recent',
}) async {
  switch (mode) {
    case NavigationSearchViewMode.dialog:
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final screen = MediaQuery.sizeOf(dialogContext);
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 40,
            ),
            child: SizedBox(
              width: math.min(620.0, screen.width - 48),
              height: math.min(620.0, screen.height - 80),
              child: NavigationSearchView<T>(
                controller: controller,
                hint: hint,
                recentsLabel: recentsLabel,
                onPick: onPick,
                onClose: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          );
        },
      );
      return;
    case NavigationSearchViewMode.sheet:
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          final media = MediaQuery.of(sheetContext);
          final height = math.min(media.size.height * 0.84, 720.0);
          return Padding(
            padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
            child: SizedBox(
              height: height,
              child: NavigationSearchView<T>(
                controller: controller,
                hint: hint,
                recentsLabel: recentsLabel,
                onPick: onPick,
                onClose: () => Navigator.of(sheetContext).pop(),
                showKeyboardHints: false,
              ),
            ),
          );
        },
      );
      return;
  }
}
