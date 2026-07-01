// ============================================================
// NavigationSidebar — THEME.
// ------------------------------------------------------------
// The component's own ThemeExtension. All visual tokens live here:
//
//   Colors    — the instance fields that swap dark ↔ light (lerped).
//   Sizes     — row heights, icon sizes, button sizes, widths, radii,
//               gutter — all instance fields with sensible defaults so
//               hosts can tune them via copyWith without touching the view.
//   Constants — brand colors, typefaces, motion, elevation (static const,
//               shared and never lerped).
//
// USAGE
//   // Apply preset:
//   ThemeData(extensions: const [NavigationSidebarThemeData.light]);
//
//   // Customise colors AND sizes:
//   NavigationSidebarThemeData.light.copyWith(
//     surface: const Color(0xFFFAF8F5),
//     directHeight: 46,
//     railButton: 48,
//     iconTop: 22,
//     radiusLg: 14,
//   )
//
//   // Read in widgets:
//   final t = NavigationSidebarThemeData.of(context);
//   t.directHeight   // 42 (or host override)
//   t.rowHeight(role) // convenience dispatch over the four role heights
//   t.contentInset(depth)
//
//   File: lib/src/theme.dart
// ============================================================

import 'dart:ui';

import 'package:flutter/material.dart';
import 'models.dart';

@immutable
class NavigationSidebarThemeData
    extends ThemeExtension<NavigationSidebarThemeData> {
  // ── swappable surfaces (dark ↔ light) ──────────────────────
  /// Page backdrop the rail/drawer floats over.
  final Color bg;

  /// Sidebar panel fill.
  final Color surface;

  /// Boxed-icon leaf fill / chip backgrounds / search field bg.
  final Color inputBg;

  /// Row hover tint.
  final Color hover;

  /// Hairline dividers.
  final Color border;

  /// Outer frame / flyout panel edge.
  final Color borderStrong;

  /// `│ ├ └` connector line colour.
  final Color guide;

  /// Active / primary label colour.
  final Color fg1;

  /// Row label colour.
  final Color fg2;

  /// Icons, group labels, chevrons.
  final Color fg3;

  /// Section eyebrows, disabled text.
  final Color fg4;

  // ── ROW HEIGHTS ────────────────────────────────────────────
  /// Height of a depth-0 leaf row (`direct` role). Default: **42**.
  final double directHeight;

  /// Height of a depth-0 branch row (`module` role). Default: **42**.
  final double moduleHeight;

  /// Height of a depth-≥1 branch header (`group` role). Default: **36**.
  final double groupHeight;

  /// Height of a depth-≥1 leaf row (`item` role). Default: **38**.
  final double itemHeight;

  // ── RAIL ───────────────────────────────────────────────────
  /// Width **and** height of the icon button in the collapsed rail.
  /// Default: **44**.
  final double railButton;

  /// Icon rendered inside the rail button. Default: **22**.
  final double railIconSize;

  // ── SIDEBAR WIDTHS ─────────────────────────────────────────
  /// Sidebar width in `expanded` mode. Default: **248**.
  final double widthExpanded;

  /// Sidebar width in `rail` (collapsed) mode. Default: **76**.
  final double widthRail;

  /// Sidebar width in `drawer` mode. Default: **280**.
  final double widthDrawer;

  // ── TREE ICONS & BOXED ITEM ────────────────────────────────
  /// Leading icon size for `direct` and `module` rows. Default: **20**.
  final double iconTop;

  /// Icon rendered inside the boxed `item` container. Default: **16**.
  final double iconItem;

  /// Width **and** height of the square `item` icon container. Default: **28**.
  final double itemBox;

  // ── TOOLBAR (APP BAR) ──────────────────────────────────────
  /// Width **and** height of the square icon button in
  /// `NavigationSidebarAppBar` (hamburger, collapse toggle). Default: **36**.
  final double toolbarButtonSize;

  /// Icon rendered inside a toolbar button. Default: **20**.
  final double toolbarIconSize;

  // ── CORNER RADII ───────────────────────────────────────────
  /// Smallest radius — keycap chips, small controls. Default: **6**.
  final double radiusSm;

  /// Medium radius — search field, item box border, badge chips. Default: **8**.
  final double radiusMd;

  /// Large radius — direct/module pill rows, rail buttons. Default: **10**.
  final double radiusLg;

  /// Extra-large radius — flyout panel, drawer header controls. Default: **12**.
  final double radiusXl;

  // ── INDENT ─────────────────────────────────────────────────
  /// Horizontal indent added per nesting level (drives the connector
  /// geometry). Default: **19**.
  final double gutter;

  // ── SELECTION INDICATOR & HEADER ───────────────────────────
  /// How the active leaf row is highlighted.
  /// Default: [NavSelectionIndicator.fill] (unchanged original look).
  final NavSelectionIndicator selectionIndicator;

  /// Thickness of the [NavSelectionIndicator.bar] pill. Default: **3**.
  final double indicatorThickness;

  /// Vertical inset of the [NavSelectionIndicator.bar] pill from the top and
  /// bottom of its row. Default: **9**.
  final double indicatorInset;

  /// Fixed height of a [NavigationShell] content header band. Default: **52**.
  final double headerHeight;

  // ── constructor ────────────────────────────────────────────
  const NavigationSidebarThemeData({
    // ── colors (required) ────────────────────────────────────
    required this.bg,
    required this.surface,
    required this.inputBg,
    required this.hover,
    required this.border,
    required this.borderStrong,
    required this.guide,
    required this.fg1,
    required this.fg2,
    required this.fg3,
    required this.fg4,
    // ── sizes (optional — all have defaults) ─────────────────
    this.directHeight = 42,
    this.moduleHeight = 42,
    this.groupHeight = 36,
    this.itemHeight = 38,
    this.railButton = 44,
    this.railIconSize = 22,
    this.widthExpanded = 248,
    this.widthRail = 76,
    this.widthDrawer = 280,
    this.iconTop = 20,
    this.iconItem = 16,
    this.itemBox = 28,
    this.toolbarButtonSize = 36,
    this.toolbarIconSize = 20,
    this.radiusSm = 6,
    this.radiusMd = 8,
    this.radiusLg = 10,
    this.radiusXl = 12,
    this.gutter = 19,
    this.selectionIndicator = NavSelectionIndicator.fill,
    this.indicatorThickness = 3,
    this.indicatorInset = 9,
    this.headerHeight = 52,
  });

  // ── brand + semantic palette (const — never lerped) ────────
  static const Color accent  = Color(0xFF4A7CFF);
  static const Color success = Color(0xFF1DB88A);
  static const Color warning = Color(0xFFF97316);
  static const Color danger  = Color(0xFFEF4444);

  // ── typography ─────────────────────────────────────────────
  static const String displayFont = 'Manrope';
  static const String bodyFont    = 'Inter';
  static const String monoFont    = 'JetBrainsMono';

  // ── motion ─────────────────────────────────────────────────
  static const Duration durFast   = Duration(milliseconds: 150);
  static const Duration durBase   = Duration(milliseconds: 240);
  static const Duration durDrawer = Duration(milliseconds: 280);
  static const Curve curveStandard = Cubic(0.4, 0, 0.2, 1);

  // ── elevation ──────────────────────────────────────────────
  static const List<BoxShadow> popShadow = [
    BoxShadow(
      color: Color(0x73000000),
      blurRadius: 32,
      spreadRadius: -8,
      offset: Offset(0, 12),
    ),
  ];

  // ── default breakpoints ────────────────────────────────────
  static const NavSidebarBreakpoints breakpoints = NavSidebarBreakpoints();

  // ── derived geometry (instance — depend on [gutter]) ───────
  /// Horizontal stub length of the ├ / └ elbow connector.
  double get elbow => gutter - 8;

  /// Leading-edge padding of a row at [depth].
  double contentInset(int depth) => 13 + depth * gutter;

  /// X-position of the vertical guide line for children at [depth].
  double lineInset(int depth) => contentInset(depth) + 10;

  /// Row height for [role] — convenience for the view layer.
  double rowHeight(NavNodeRole role) {
    switch (role) {
      case NavNodeRole.direct: return directHeight;
      case NavNodeRole.module: return moduleHeight;
      case NavNodeRole.group:  return groupHeight;
      case NavNodeRole.item:   return itemHeight;
    }
  }

  // ── presets ────────────────────────────────────────────────
  static const NavigationSidebarThemeData dark = NavigationSidebarThemeData(
    bg:           Color(0xFF111318),
    surface:      Color(0xFF1E2025),
    inputBg:      Color(0xFF33353A),
    hover:        Color(0xFF2F3540),
    border:       Color(0x66434654),
    borderStrong: Color(0xFF434654),
    guide:        Color(0xFF434654),
    fg1:          Color(0xFFE2E2E9),
    fg2:          Color(0xFFC3C6D7),
    fg3:          Color(0xFF8D90A0),
    fg4:          Color(0xFF44474E),
    // sizes use their defaults
  );

  static const NavigationSidebarThemeData light = NavigationSidebarThemeData(
    bg:           Color(0xFFF7F8FA),
    surface:      Color(0xFFFFFFFF),
    inputBg:      Color(0xFFF1F3F8),
    hover:        Color(0xFFEEF1F7),
    border:       Color(0xFFE2E8F0),
    borderStrong: Color(0xFFC2C6D6),
    guide:        Color(0xFFC2C6D6),
    fg1:          Color(0xFF0F172A),
    fg2:          Color(0xFF424754),
    fg3:          Color(0xFF64748B),
    fg4:          Color(0xFFC2C6D6),
    // sizes use their defaults
  );

  // ── helpers ────────────────────────────────────────────────
  /// Reads the registered extension, or falls back to [dark].
  static NavigationSidebarThemeData of(BuildContext context) =>
      Theme.of(context).extension<NavigationSidebarThemeData>() ?? dark;

  /// Accent-tinted fill over [surface] at [pct] opacity.
  Color accentFill([double pct = 0.12]) =>
      Color.alphaBlend(accent.withOpacity(pct), surface);

  /// Resolves a [NavBadgeTone] to its (background, foreground, border) trio.
  ({Color bg, Color fg, Color border}) badgeColors(NavBadgeTone tone) {
    switch (tone) {
      case NavBadgeTone.accent:
        return (
          bg:     accent.withOpacity(0.16),
          fg:     accent,
          border: accent.withOpacity(0.34),
        );
      case NavBadgeTone.success:
        return (
          bg:     success.withOpacity(0.16),
          fg:     const Color(0xFF2BBE7C),
          border: success.withOpacity(0.34),
        );
      case NavBadgeTone.warning:
        return (
          bg:     warning.withOpacity(0.16),
          fg:     const Color(0xFFE0A23B),
          border: warning.withOpacity(0.34),
        );
      case NavBadgeTone.danger:
        return (
          bg:     danger.withOpacity(0.16),
          fg:     const Color(0xFFF26464),
          border: danger.withOpacity(0.34),
        );
      case NavBadgeTone.muted:
        return (bg: inputBg, fg: fg3, border: border);
    }
  }

  /// Resolves a [NavNodeStatus] to its status-dot colour (null = no dot).
  Color? statusColor(NavNodeStatus status) {
    switch (status) {
      case NavNodeStatus.none:      return null;
      case NavNodeStatus.open:      return success;
      case NavNodeStatus.closed:    return fg4;
      case NavNodeStatus.locked:    return danger;
      case NavNodeStatus.attention: return warning;
    }
  }

  // ── ThemeExtension overrides ───────────────────────────────
  @override
  NavigationSidebarThemeData copyWith({
    // colors
    Color? bg,
    Color? surface,
    Color? inputBg,
    Color? hover,
    Color? border,
    Color? borderStrong,
    Color? guide,
    Color? fg1,
    Color? fg2,
    Color? fg3,
    Color? fg4,
    // sizes
    double? directHeight,
    double? moduleHeight,
    double? groupHeight,
    double? itemHeight,
    double? railButton,
    double? railIconSize,
    double? widthExpanded,
    double? widthRail,
    double? widthDrawer,
    double? iconTop,
    double? iconItem,
    double? itemBox,
    double? toolbarButtonSize,
    double? toolbarIconSize,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusXl,
    double? gutter,
    NavSelectionIndicator? selectionIndicator,
    double? indicatorThickness,
    double? indicatorInset,
    double? headerHeight,
  }) =>
      NavigationSidebarThemeData(
        bg:           bg           ?? this.bg,
        surface:      surface      ?? this.surface,
        inputBg:      inputBg      ?? this.inputBg,
        hover:        hover        ?? this.hover,
        border:       border       ?? this.border,
        borderStrong: borderStrong ?? this.borderStrong,
        guide:        guide        ?? this.guide,
        fg1:          fg1          ?? this.fg1,
        fg2:          fg2          ?? this.fg2,
        fg3:          fg3          ?? this.fg3,
        fg4:          fg4          ?? this.fg4,
        directHeight:      directHeight      ?? this.directHeight,
        moduleHeight:      moduleHeight      ?? this.moduleHeight,
        groupHeight:       groupHeight       ?? this.groupHeight,
        itemHeight:        itemHeight        ?? this.itemHeight,
        railButton:        railButton        ?? this.railButton,
        railIconSize:      railIconSize      ?? this.railIconSize,
        widthExpanded:     widthExpanded     ?? this.widthExpanded,
        widthRail:         widthRail         ?? this.widthRail,
        widthDrawer:       widthDrawer       ?? this.widthDrawer,
        iconTop:           iconTop           ?? this.iconTop,
        iconItem:          iconItem          ?? this.iconItem,
        itemBox:           itemBox           ?? this.itemBox,
        toolbarButtonSize: toolbarButtonSize ?? this.toolbarButtonSize,
        toolbarIconSize:   toolbarIconSize   ?? this.toolbarIconSize,
        radiusSm:          radiusSm          ?? this.radiusSm,
        radiusMd:          radiusMd          ?? this.radiusMd,
        radiusLg:          radiusLg          ?? this.radiusLg,
        radiusXl:          radiusXl          ?? this.radiusXl,
        gutter:            gutter            ?? this.gutter,
        selectionIndicator: selectionIndicator ?? this.selectionIndicator,
        indicatorThickness: indicatorThickness ?? this.indicatorThickness,
        indicatorInset:     indicatorInset     ?? this.indicatorInset,
        headerHeight:       headerHeight       ?? this.headerHeight,
      );

  @override
  NavigationSidebarThemeData lerp(
    ThemeExtension<NavigationSidebarThemeData>? other,
    double t,
  ) {
    if (other is! NavigationSidebarThemeData) return this;
    return NavigationSidebarThemeData(
      // colors — smooth interpolation
      bg:           Color.lerp(bg,           other.bg,           t)!,
      surface:      Color.lerp(surface,      other.surface,      t)!,
      inputBg:      Color.lerp(inputBg,      other.inputBg,      t)!,
      hover:        Color.lerp(hover,        other.hover,        t)!,
      border:       Color.lerp(border,       other.border,       t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      guide:        Color.lerp(guide,        other.guide,        t)!,
      fg1:          Color.lerp(fg1,          other.fg1,          t)!,
      fg2:          Color.lerp(fg2,          other.fg2,          t)!,
      fg3:          Color.lerp(fg3,          other.fg3,          t)!,
      fg4:          Color.lerp(fg4,          other.fg4,          t)!,
      // sizes — linear interpolation (enables animated theme switches)
      directHeight:      lerpDouble(directHeight,      other.directHeight,      t)!,
      moduleHeight:      lerpDouble(moduleHeight,      other.moduleHeight,      t)!,
      groupHeight:       lerpDouble(groupHeight,        other.groupHeight,       t)!,
      itemHeight:        lerpDouble(itemHeight,         other.itemHeight,        t)!,
      railButton:        lerpDouble(railButton,         other.railButton,        t)!,
      railIconSize:      lerpDouble(railIconSize,       other.railIconSize,      t)!,
      widthExpanded:     lerpDouble(widthExpanded,      other.widthExpanded,     t)!,
      widthRail:         lerpDouble(widthRail,          other.widthRail,         t)!,
      widthDrawer:       lerpDouble(widthDrawer,        other.widthDrawer,       t)!,
      iconTop:           lerpDouble(iconTop,            other.iconTop,           t)!,
      iconItem:          lerpDouble(iconItem,           other.iconItem,          t)!,
      itemBox:           lerpDouble(itemBox,            other.itemBox,           t)!,
      toolbarButtonSize: lerpDouble(toolbarButtonSize,  other.toolbarButtonSize, t)!,
      toolbarIconSize:   lerpDouble(toolbarIconSize,    other.toolbarIconSize,   t)!,
      radiusSm:          lerpDouble(radiusSm,           other.radiusSm,          t)!,
      radiusMd:          lerpDouble(radiusMd,           other.radiusMd,          t)!,
      radiusLg:          lerpDouble(radiusLg,           other.radiusLg,          t)!,
      radiusXl:          lerpDouble(radiusXl,           other.radiusXl,          t)!,
      gutter:            lerpDouble(gutter,             other.gutter,            t)!,
      // enum — snap at the midpoint (cannot be interpolated)
      selectionIndicator:
          t < 0.5 ? selectionIndicator : other.selectionIndicator,
      indicatorThickness: lerpDouble(indicatorThickness, other.indicatorThickness, t)!,
      indicatorInset:     lerpDouble(indicatorInset,     other.indicatorInset,     t)!,
      headerHeight:       lerpDouble(headerHeight,       other.headerHeight,       t)!,
    );
  }
}
