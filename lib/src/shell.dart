// ============================================================
// NavigationSidebar — SHELL (integrated AppBar + Pane + Content).
// ------------------------------------------------------------
// NavigationShell is the single widget that lays out the three surfaces of an
// app — the app bar, the navigation pane, and the page content — in the correct
// Microsoft-NavigationView arrangement, so hosts stop hand-wiring Row / Column /
// Stack and getting the alignment subtly wrong.
//
// It resolves the presentation [NavSidebarMode] (fixed, or adaptively from the
// available width via [NavSidebarBreakpoints]) and drives two host builders —
// [appBarBuilder] and [sidebarBuilder] — with that mode, then composes them:
//
//   headerLayout: spanning (default, the WinUI-Gallery arrangement)
//   ┌─────────────────────────────────────┐
//   │  App bar  (full width)              │   ← back + pane toggle sit in the
//   ├──────────┬──────────────────────────┤     bar's leading zone, directly
//   │  Pane    │  Content (padded)        │     over the pane
//   └──────────┴──────────────────────────┘
//
//   headerLayout: inset
//   ┌──────────┬──────────────────────────┐
//   │  Pane    │  App bar                 │   ← pane spans full height; the bar
//   │ (full    ├──────────────────────────┤     is inset above content only
//   │  height) │  Content (padded)        │
//   └──────────┴──────────────────────────┘
//
// paneBehavior controls how an expanded pane affects the content:
//   • push    — the pane widens in-flow and reflows the content (Left mode).
//   • overlay — a rail is always shown; opening the pane floats the full panel
//               over the content with a scrim (LeftCompact / LeftMinimal). For
//               overlay, construct the controller with `collapsed: true` so the
//               pane starts closed.
//
// In drawer mode the pane is rendered as an off-canvas overlay above the
// content, and the app bar's hamburger drives `controller.openDrawer`.
//
//   File: lib/src/shell.dart
// ============================================================

import 'package:flutter/material.dart';
import 'controller.dart';
import 'models.dart';
import 'theme.dart';

/// Builds one of the shell's surfaces for the resolved [NavSidebarMode].
///
/// Typically returns a [NavigationSidebar] (from [NavigationShell.sidebarBuilder])
/// or a `NavigationSidebarAppBar` (from [NavigationShell.appBarBuilder]),
/// configured with the [mode] the shell passes in.
typedef NavShellSlotBuilder = Widget Function(
  BuildContext context,
  NavSidebarMode mode,
);

/// An integrated app shell that composes an app bar, a navigation pane and the
/// page content in the Microsoft NavigationView arrangement.
///
/// ```dart
/// NavigationShell<String>(
///   controller: _nav,
///   headerLayout: NavShellHeaderLayout.spanning,
///   paneBehavior: NavPaneBehavior.push,
///   appBarBuilder: (ctx, mode) => NavigationSidebarAppBar(
///     controller: _nav,
///     mode: mode,
///     showBackButton: true,
///     onBack: _goBack,
///     title: const Text('Meridian'),
///     globalSearch: NavigationSidebarSearchField(controller: _nav),
///     actions: [NotificationBell(), UserAvatar()],
///   ),
///   sidebarBuilder: (ctx, mode) => NavigationSidebar<String>(
///     controller: _nav,
///     mode: mode,
///     onNavigate: (n) => setState(() => _screen = n.value!),
///   ),
///   body: PageFor(screen: _screen),
/// )
/// ```
class NavigationShell<T> extends StatelessWidget {
  /// The controller shared by the app bar and the pane.
  final NavigationSidebarController<T> controller;

  /// Builds the navigation pane for the resolved mode. **Required.**
  final NavShellSlotBuilder sidebarBuilder;

  /// Builds the app bar for the resolved mode. Optional — omit for a shell
  /// with no top bar.
  final NavShellSlotBuilder? appBarBuilder;

  /// The page content.
  final Widget body;

  /// Force a presentation mode. When `null` the shell derives the mode from
  /// the available width using [breakpoints] (the adaptive default).
  final NavSidebarMode? mode;

  /// Width thresholds used when [mode] is `null`.
  final NavSidebarBreakpoints breakpoints;

  /// Where the app bar sits relative to the pane. Defaults to
  /// [NavShellHeaderLayout.spanning] (full-width bar above the pane).
  final NavShellHeaderLayout headerLayout;

  /// How an expanded pane affects the content. Defaults to
  /// [NavPaneBehavior.push].
  final NavPaneBehavior paneBehavior;

  /// Padding around [body]. Defaults to 24 px (12 px in drawer mode), matching
  /// NavigationView's recommended content margins.
  final EdgeInsetsGeometry? contentPadding;

  /// Backdrop colour behind the whole shell. Falls back to
  /// [NavigationSidebarThemeData.bg].
  final Color? backgroundColor;

  /// Scrim colour for the overlay pane / drawer. Falls back to a translucent
  /// black.
  final Color? scrimColor;

  const NavigationShell({
    super.key,
    required this.controller,
    required this.sidebarBuilder,
    required this.body,
    this.appBarBuilder,
    this.mode,
    this.breakpoints = const NavSidebarBreakpoints(),
    this.headerLayout = NavShellHeaderLayout.spanning,
    this.paneBehavior = NavPaneBehavior.push,
    this.contentPadding,
    this.backgroundColor,
    this.scrimColor,
  });

  static const Color _defaultScrim = Color(0x8C08090C);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolved = mode ?? breakpoints.modeFor(constraints.maxWidth);
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final t = NavigationSidebarThemeData.of(context);
            Widget child;
            if (resolved == NavSidebarMode.drawer) {
              child = _drawer(context, t);
            } else if (headerLayout == NavShellHeaderLayout.inset) {
              child = _inset(context, t, resolved);
            } else {
              child = _spanning(context, t, resolved);
            }
            return Material(color: backgroundColor ?? t.bg, child: child);
          },
        );
      },
    );
  }

  EdgeInsetsGeometry _pad(NavSidebarMode m) =>
      contentPadding ??
      (m == NavSidebarMode.drawer
          ? const EdgeInsets.all(12)
          : const EdgeInsets.all(24));

  Widget _content(NavSidebarMode m) => Padding(padding: _pad(m), child: body);

  // ── spanning: full-width bar above pane + content ──────────
  Widget _spanning(
      BuildContext ctx, NavigationSidebarThemeData t, NavSidebarMode mode) {
    return Column(
      children: [
        if (appBarBuilder != null) appBarBuilder!(ctx, mode),
        Expanded(child: _paneAndContent(ctx, t, mode)),
      ],
    );
  }

  // ── inset: full-height pane, bar above content only ────────
  Widget _inset(
      BuildContext ctx, NavigationSidebarThemeData t, NavSidebarMode mode) {
    return Row(
      children: [
        sidebarBuilder(ctx, mode),
        Expanded(
          child: Column(
            children: [
              if (appBarBuilder != null) appBarBuilder!(ctx, mode),
              Expanded(child: _content(mode)),
            ],
          ),
        ),
      ],
    );
  }

  // ── pane + content, honouring push / overlay ───────────────
  Widget _paneAndContent(
      BuildContext ctx, NavigationSidebarThemeData t, NavSidebarMode mode) {
    if (paneBehavior == NavPaneBehavior.push) {
      return Row(
        children: [
          sidebarBuilder(ctx, mode),
          Expanded(child: _content(mode)),
        ],
      );
    }

    // Overlay: a rail is always in-flow; the full pane floats over content.
    final collapsed = controller.collapsed;
    final expandedW = t.widthExpanded;
    final hidden = expandedW + 8;
    return Stack(
      children: [
        Row(
          children: [
            SizedBox(
              width: t.widthRail,
              child: sidebarBuilder(ctx, NavSidebarMode.rail),
            ),
            Expanded(child: _content(mode)),
          ],
        ),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: collapsed,
            child: GestureDetector(
              onTap: () => controller.collapsed = true,
              child: AnimatedOpacity(
                duration: NavigationSidebarThemeData.durDrawer,
                opacity: collapsed ? 0 : 1,
                child: ColoredBox(color: scrimColor ?? _defaultScrim),
              ),
            ),
          ),
        ),
        AnimatedPositionedDirectional(
          duration: NavigationSidebarThemeData.durDrawer,
          curve: NavigationSidebarThemeData.curveStandard,
          top: 0,
          bottom: 0,
          start: collapsed ? -hidden : 0,
          width: expandedW,
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow:
                  collapsed ? null : NavigationSidebarThemeData.popShadow,
            ),
            child: sidebarBuilder(ctx, NavSidebarMode.expanded),
          ),
        ),
      ],
    );
  }

  // ── drawer: off-canvas pane over content ───────────────────
  Widget _drawer(BuildContext ctx, NavigationSidebarThemeData t) {
    return Column(
      children: [
        if (appBarBuilder != null)
          appBarBuilder!(ctx, NavSidebarMode.drawer),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: _content(NavSidebarMode.drawer)),
              Positioned.fill(
                child: sidebarBuilder(ctx, NavSidebarMode.drawer),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
