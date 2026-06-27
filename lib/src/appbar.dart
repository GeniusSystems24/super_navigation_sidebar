// ============================================================
// NavigationSidebar — APP BAR INTEGRATION.
// ------------------------------------------------------------
// NavigationSidebarAppBar is a PreferredSizeWidget that connects directly to a
// NavigationSidebarController. It adapts its leading controls to the current
// sidebar mode and exposes composable slots for the most common app-bar needs:
// page title, global search, breadcrumbs, user info, notifications, workspace
// switcher, theme toggle, and arbitrary action widgets.
//
// USAGE — drawer mode (mobile):
//   Scaffold(
//     appBar: NavigationSidebarAppBar(
//       controller: _nav,
//       mode: NavSidebarMode.drawer,
//       title: Text('Meridian Bank'),
//     ),
//     body: Stack(children: [
//       Positioned.fill(child: page),
//       Positioned.fill(child: NavigationSidebar(..., mode: NavSidebarMode.drawer)),
//     ]),
//   )
//
// USAGE — expanded / rail mode (desktop):
//   Row(children: [
//     NavigationSidebar(controller: _nav, mode: mode),
//     Expanded(
//       child: Column(children: [
//         NavigationSidebarAppBar(
//           controller: _nav,
//           mode: mode,
//           pageTitle: Text(currentScreenTitle),
//           actions: [NotificationBell(), UserAvatar()],
//         ),
//         Expanded(child: page),
//       ]),
//     ),
//   ])
//
//   File: lib/src/appbar.dart
// ============================================================

import 'package:flutter/material.dart';
import 'controller.dart';
import 'localizations.dart';
import 'models.dart';
import 'theme.dart';

/// A [PreferredSizeWidget] that is directly connected to a
/// [NavigationSidebarController].
///
/// Adapts its leading controls automatically to the current [mode]:
/// - **Drawer mode** — shows a hamburger that calls [controller.openDrawer].
///   The drawer can also be closed from here via [controller.closeDrawer].
/// - **Expanded / rail mode** — optionally shows a collapse ↔ expand toggle
///   (controlled by [showCollapseToggle]).
///
/// All content slots are optional — the bar is usable as a plain
/// Material-style header with sidebar awareness. Use [builder] for full
/// control over the bar's interior.
///
/// The bar listens to [controller] and rebuilds automatically when the
/// sidebar state changes (e.g. when the drawer opens/closes or the sidebar
/// collapses/expands).
class NavigationSidebarAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  // ── controller wiring ──────────────────────────────────────
  /// The sidebar controller this bar is connected to.
  final NavigationSidebarController controller;

  /// The current sidebar mode. Determines which leading controls are shown.
  final NavSidebarMode mode;

  // ── leading ────────────────────────────────────────────────
  /// Widget placed in the leading position.
  ///
  /// When [null] and [mode] is [NavSidebarMode.drawer], a hamburger icon
  /// button (`Icons.menu`) that calls [controller.openDrawer] is inserted.
  ///
  /// Set to an empty [SizedBox] to suppress the auto-hamburger without
  /// providing a custom widget.
  final Widget? leading;

  // ── content slots ──────────────────────────────────────────
  /// Main heading — typically a [Text] with the app or screen name.
  final Widget? title;

  /// Secondary label shown to the right of [title] (desktop only, hidden
  /// when [mode] is [NavSidebarMode.drawer] and the bar is compact).
  ///
  /// Suitable for a breadcrumb trail or active-screen subtitle.
  final Widget? pageTitle;

  /// Trailing action widgets (placed at the end / right edge).
  ///
  /// Common uses: notification bell, user avatar, theme toggle, help button.
  final List<Widget>? actions;

  // ── built-in optional slots ────────────────────────────────
  /// A global search widget placed in the center of the bar.
  ///
  /// Use a [NavigationSidebarSearchField] or any custom [Widget]. The sidebar's
  /// built-in per-sidebar search ([NavigationSidebar.searchable]) is separate;
  /// this slot is for an app-level search that may span multiple surfaces.
  final Widget? globalSearch;

  /// Content placed between [title] / [pageTitle] and [actions].
  ///
  /// Suitable for workspace switcher, environment badge, or custom controls.
  final Widget? middle;

  // ── behavior ───────────────────────────────────────────────
  /// Show a sidebar collapse ↔ expand toggle in [NavSidebarMode.expanded]
  /// and [NavSidebarMode.rail] modes.
  ///
  /// Defaults to `true` for expanded/rail, `false` for drawer.
  final bool? showCollapseToggle;

  // ── custom builder (overrides all slots) ───────────────────
  /// Fully custom bar content. When provided, all other slots are ignored.
  ///
  /// Receives [BuildContext], the effective [NavSidebarMode], and whether the
  /// sidebar is currently [collapsed], so you can render contextually.
  final Widget Function(
    BuildContext context,
    NavSidebarMode mode,
    bool collapsed,
  )? builder;

  // ── appearance ─────────────────────────────────────────────
  /// Bar background colour. Falls back to [NavigationSidebarThemeData.surface].
  final Color? backgroundColor;

  /// Draw a bottom border matching [NavigationSidebarThemeData.border].
  /// Defaults to `true`.
  final bool showBorder;

  /// Bar height. Defaults to [kToolbarHeight] (56 px).
  final double? height;

  /// Padding inside the bar. Defaults to symmetric horizontal 16 px.
  final EdgeInsetsGeometry? padding;

  /// Localizations used for semantic labels on built-in controls.
  final NavigationSidebarLocalizations localizations;

  const NavigationSidebarAppBar({
    super.key,
    required this.controller,
    required this.mode,
    this.leading,
    this.title,
    this.pageTitle,
    this.actions,
    this.globalSearch,
    this.middle,
    this.showCollapseToggle,
    this.builder,
    this.backgroundColor,
    this.showBorder = true,
    this.height,
    this.padding,
    this.localizations = const NavigationSidebarLocalizations(),
  });

  @override
  Size get preferredSize => Size.fromHeight(height ?? kToolbarHeight);

  bool _shouldShowCollapse(NavSidebarMode m) =>
      showCollapseToggle ?? (m != NavSidebarMode.drawer);

  @override
  Widget build(BuildContext context) {
    // AnimatedBuilder re-renders when the controller notifies (drawer open,
    // collapsed flag, etc.) without requiring Scaffold or InheritedWidget.
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = NavigationSidebarThemeData.of(context);
        final collapsed = controller.collapsed;
        final effectiveH = height ?? kToolbarHeight;

        final bg = backgroundColor ?? t.surface;

        Widget content;
        if (builder != null) {
          content = builder!(context, mode, collapsed);
        } else {
          content = _defaultContent(context, t, collapsed);
        }

        return Container(
          height: effectiveH,
          decoration: BoxDecoration(
            color: bg,
            border: showBorder
                ? Border(bottom: BorderSide(color: t.border))
                : null,
          ),
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 16),
          child: content,
        );
      },
    );
  }

  Widget _defaultContent(
    BuildContext context,
    NavigationSidebarThemeData t,
    bool collapsed,
  ) {
    return Row(
      children: [
        // ── leading ───────────────────────────────────────────
        _leading(context, t, collapsed),

        // ── collapse toggle (expanded / rail) ─────────────────
        if (_shouldShowCollapse(mode)) ...[
          const SizedBox(width: 4),
          _CollapseToggle(
            controller: controller,
            theme: t,
            localizations: localizations,
          ),
        ],

        // ── title ─────────────────────────────────────────────
        if (title != null) ...[
          const SizedBox(width: 12),
          DefaultTextStyle(
            style: TextStyle(
              fontFamily: NavigationSidebarThemeData.displayFont,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: t.fg1,
            ),
            child: title!,
          ),
        ],

        // ── page title / breadcrumb ────────────────────────────
        if (pageTitle != null) ...[
          const SizedBox(width: 10),
          Flexible(
            child: DefaultTextStyle(
              style: TextStyle(
                fontFamily: NavigationSidebarThemeData.bodyFont,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: t.fg3,
              ),
              child: pageTitle!,
            ),
          ),
        ],

        // ── global search (centered) ──────────────────────────
        if (globalSearch != null) ...[
          const SizedBox(width: 12),
          Expanded(child: globalSearch!),
          const SizedBox(width: 12),
        ] else
          const Spacer(),

        // ── middle slot ───────────────────────────────────────
        if (middle != null) ...[
          middle!,
          const SizedBox(width: 12),
        ],

        // ── trailing actions ──────────────────────────────────
        if (actions != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < actions!.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                actions![i],
              ],
            ],
          ),
      ],
    );
  }

  Widget _leading(
    BuildContext context,
    NavigationSidebarThemeData t,
    bool collapsed,
  ) {
    if (leading != null) return leading!;

    // In drawer mode → hamburger.
    if (mode == NavSidebarMode.drawer) {
      return Semantics(
        button: true,
        label: localizations.semanticOpenDrawer,
        child: _AppBarIconButton(
          icon: Icons.menu_rounded,
          theme: t,
          onTap: controller.openDrawer,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// ── Collapse toggle ────────────────────────────────────────────────
class _CollapseToggle extends StatelessWidget {
  final NavigationSidebarController controller;
  final NavigationSidebarThemeData theme;
  final NavigationSidebarLocalizations localizations;

  const _CollapseToggle({
    required this.controller,
    required this.theme,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    final collapsed = controller.collapsed;
    return Semantics(
      button: true,
      label: localizations.semanticToggleSidebar,
      child: _AppBarIconButton(
        icon: collapsed
            ? Icons.view_sidebar_outlined
            : Icons.view_sidebar_rounded,
        theme: theme,
        onTap: controller.toggleCollapsed,
      ),
    );
  }
}

// ── Icon button (shared within the app bar) ───────────────────────
class _AppBarIconButton extends StatefulWidget {
  final IconData icon;
  final NavigationSidebarThemeData theme;
  final VoidCallback onTap;

  const _AppBarIconButton({
    required this.icon,
    required this.theme,
    required this.onTap,
  });

  @override
  State<_AppBarIconButton> createState() => _AppBarIconButtonState();
}

class _AppBarIconButtonState extends State<_AppBarIconButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: NavigationSidebarThemeData.durFast,
          width: t.toolbarButtonSize,
          height: t.toolbarButtonSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hover ? t.hover : Colors.transparent,
            borderRadius:
                BorderRadius.circular(t.radiusMd),
          ),
          child: Icon(widget.icon, size: t.toolbarIconSize, color: t.fg2),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// READY-MADE SLOT WIDGETS
// ════════════════════════════════════════════════════════════

/// A styled breadcrumb row that reads ancestor labels from
/// [NavigationSidebarController] and renders them as a `›`-separated trail.
///
/// Rebuilds automatically when the controller's active node changes.
///
/// ```dart
/// NavigationSidebarAppBar(
///   controller: _nav,
///   mode: mode,
///   pageTitle: NavBreadcrumb(controller: _nav),
/// )
/// ```
class NavBreadcrumb<T> extends StatelessWidget {
  /// The sidebar controller whose active node determines the breadcrumb path.
  final NavigationSidebarController<T> controller;

  /// Separator between crumbs. Defaults to `'  ›  '`.
  final String separator;

  /// Style for the crumb labels. Falls back to the app bar's
  /// [NavigationSidebarThemeData.fg3] at 13 px.
  final TextStyle? style;

  /// Style for the final (active) crumb. Falls back to [fg2] + w600.
  final TextStyle? activeStyle;

  const NavBreadcrumb({
    super.key,
    required this.controller,
    this.separator = '  ›  ',
    this.style,
    this.activeStyle,
  });

  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    final activeId = controller.active;
    if (activeId == null) return const SizedBox.shrink();

    final ancestors = NavOps.ancestorsOf<T>(controller.sections, activeId);
    final activeNode = controller.node(activeId);

    final crumbs = [
      ...ancestors.map((id) => controller.node(id)?.label ?? id),
      if (activeNode != null) activeNode.label,
    ];

    if (crumbs.isEmpty) return const SizedBox.shrink();

    final baseStyle = style ??
        TextStyle(
          fontFamily: NavigationSidebarThemeData.bodyFont,
          fontSize: 13,
          color: t.fg3,
        );
    final lastStyle = activeStyle ??
        baseStyle.copyWith(
          color: t.fg2,
          fontWeight: FontWeight.w600,
        );

    return Text.rich(
      TextSpan(
        children: [
          for (var i = 0; i < crumbs.length; i++) ...[
            if (i > 0)
              TextSpan(text: separator, style: baseStyle),
            TextSpan(
              text: crumbs[i],
              style: i == crumbs.length - 1 ? lastStyle : baseStyle,
            ),
          ],
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// A compact search field styled to match the sidebar, suitable for placing
/// in [NavigationSidebarAppBar.globalSearch].
///
/// Drives [NavigationSidebarController.setQuery] on text change and clears
/// on the × tap.
class NavigationSidebarSearchField extends StatefulWidget {
  final NavigationSidebarController controller;
  final String hint;
  final NavigationSidebarLocalizations localizations;

  const NavigationSidebarSearchField({
    super.key,
    required this.controller,
    this.hint = 'Search…',
    this.localizations = const NavigationSidebarLocalizations(),
  });

  @override
  State<NavigationSidebarSearchField> createState() =>
      _NavigationSidebarSearchFieldState();
}

class _NavigationSidebarSearchFieldState
    extends State<NavigationSidebarSearchField> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _ctrl,
      builder: (context, value, _) {
        final hasText = value.text.isNotEmpty;
        return Container(
          height: 36,
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsetsDirectional.only(start: 10, end: 4),
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
                  controller: _ctrl,
                  onChanged: widget.controller.setQuery,
                  cursorColor: NavigationSidebarThemeData.accent,
                  style: TextStyle(
                    fontFamily: NavigationSidebarThemeData.bodyFont,
                    fontSize: 13,
                    color: t.fg1,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle: TextStyle(
                      fontFamily: NavigationSidebarThemeData.bodyFont,
                      fontSize: 13,
                      color: t.fg4,
                    ),
                  ),
                ),
              ),
              if (hasText)
                InkWell(
                  onTap: () {
                    _ctrl.clear();
                    widget.controller.setQuery('');
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
