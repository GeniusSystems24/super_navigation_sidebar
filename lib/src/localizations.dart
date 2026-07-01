// ============================================================
// NavigationSidebar — LOCALIZATIONS.
// ------------------------------------------------------------
// All user-facing strings in one immutable data class. Pass a custom instance
// to NavigationSidebar.localizations to override defaults or supply a fully
// translated set. An Arabic preset is included for RTL apps.
//
//   // English (default — no configuration needed):
//   NavigationSidebar<String>(controller: nav, mode: mode)
//
//   // Arabic:
//   NavigationSidebar<String>(
//     controller: nav, mode: mode,
//     localizations: NavigationSidebarLocalizations.arabic,
//   )
//
//   // Custom:
//   NavigationSidebar<String>(
//     controller: nav, mode: mode,
//     localizations: const NavigationSidebarLocalizations(
//       searchHint: 'Buscar navegación…',
//       quickAccessTitle: 'Acceso Rápido',
//       // … only override what you need
//     ),
//   )
//
//   File: lib/src/localizations.dart
// ============================================================

import 'package:flutter/foundation.dart';

/// All user-facing strings rendered by [NavigationSidebar].
///
/// Every field has a sensible English default. Override any subset via
/// [const NavigationSidebarLocalizations(searchHint: '…', …)] — unspecified
/// fields keep their defaults. A ready-made Arabic preset is available as
/// [NavigationSidebarLocalizations.arabic].
@immutable
class NavigationSidebarLocalizations {
  // ── Search field ───────────────────────────────────────────
  /// Placeholder shown inside the search field when empty.
  final String searchHint;

  /// Message shown when a search query returns no hits.
  ///
  /// Include `{query}` as a substitution token; call [searchEmptyFor] to
  /// perform the replacement at runtime.
  ///
  /// Example: `'No matches for "{query}"'` → `'No matches for "journals"'`.
  final String searchEmpty;

  // ── Drawer ─────────────────────────────────────────────────
  /// Eyebrow label above the close button in the navigation drawer.
  final String drawerTitle;

  /// Accessible tooltip / semantic label for the drawer close icon button.
  final String drawerCloseLabel;

  // ── Quick Access / Favorites ───────────────────────────────
  /// Section eyebrow above the synthesized Quick Access / favorites band.
  final String quickAccessTitle;

  /// Tooltip on the star icon when the node is **not** yet a favorite.
  final String addToQuickAccess;

  /// Tooltip on the star icon when the node **is** already a favorite.
  final String removeFromQuickAccess;

  // ── Locked nodes ───────────────────────────────────────────
  /// Fallback tooltip when [NavNode.locked] is `true` but
  /// [NavNode.lockMessage] is `null`.
  final String lockedDefault;

  // ── Shortcut hints ─────────────────────────────────────────
  /// Text prepended to the shortcut tooltip.
  ///
  /// Default: `'Shortcut · '` — produces `'Shortcut · G then D'`.
  final String shortcutPrefix;

  /// Separator between keys in the shortcut tooltip.
  ///
  /// Default: `' then '` — produces `'G then D'`.
  final String shortcutSeparator;

  // ── Semantic / accessibility labels ────────────────────────
  /// Appended to a branch node's semantic label when it is expanded.
  final String semanticExpanded;

  /// Appended to a branch node's semantic label when it is collapsed.
  final String semanticCollapsed;

  /// Appended to a node's semantic label when it is locked.
  final String semanticLocked;

  /// Appended to a node's semantic label when it is disabled.
  final String semanticDisabled;

  /// Semantic label for the rail collapse / expand toggle button.
  final String semanticToggleSidebar;

  /// Semantic label for the hamburger / open-drawer button in drawer mode.
  final String semanticOpenDrawer;

  /// Semantic label for the back button in [NavigationSidebarAppBar].
  final String semanticBack;

  const NavigationSidebarLocalizations({
    this.searchHint = 'Search navigation…',
    this.searchEmpty = 'No matches for "{query}"',
    this.drawerTitle = 'Navigation',
    this.drawerCloseLabel = 'Close navigation',
    this.quickAccessTitle = 'Quick Access',
    this.addToQuickAccess = 'Add to Quick Access',
    this.removeFromQuickAccess = 'Remove from Quick Access',
    this.lockedDefault = "Locked — you don't have access",
    this.shortcutPrefix = 'Shortcut · ',
    this.shortcutSeparator = ' then ',
    this.semanticExpanded = 'expanded',
    this.semanticCollapsed = 'collapsed',
    this.semanticLocked = 'locked',
    this.semanticDisabled = 'disabled',
    this.semanticToggleSidebar = 'Toggle sidebar',
    this.semanticOpenDrawer = 'Open navigation',
    this.semanticBack = 'Back',
  });

  // ── Built-in presets ───────────────────────────────────────

  /// Arabic preset — pair with
  /// `Directionality(textDirection: TextDirection.rtl, …)`.
  static const NavigationSidebarLocalizations arabic =
      NavigationSidebarLocalizations(
    searchHint: 'البحث في القائمة…',
    searchEmpty: 'لا توجد نتائج لـ "{query}"',
    drawerTitle: 'القائمة',
    drawerCloseLabel: 'إغلاق القائمة',
    quickAccessTitle: 'الوصول السريع',
    addToQuickAccess: 'إضافة للوصول السريع',
    removeFromQuickAccess: 'إزالة من الوصول السريع',
    lockedDefault: 'مقفل — ليس لديك صلاحية الوصول',
    shortcutPrefix: 'اختصار · ',
    shortcutSeparator: ' ثم ',
    semanticExpanded: 'مفتوح',
    semanticCollapsed: 'مغلق',
    semanticLocked: 'مقفل',
    semanticDisabled: 'غير متاح',
    semanticToggleSidebar: 'تبديل الشريط الجانبي',
    semanticOpenDrawer: 'فتح القائمة',
    semanticBack: 'رجوع',
  );

  // ── Helpers ────────────────────────────────────────────────

  /// Returns [searchEmpty] with `{query}` replaced by [query].
  ///
  /// Example: `searchEmptyFor('journals')` → `'No matches for "journals"'`.
  String searchEmptyFor(String query) =>
      searchEmpty.replaceAll('{query}', query);

  /// Builds the full shortcut tooltip string from a key list.
  ///
  /// Example: `shortcutTooltip(['g', 'd'])` → `'Shortcut · G then D'`.
  String shortcutTooltip(List<String> keys) {
    if (keys.isEmpty) return '';
    final pretty =
        keys.map((k) => k.toUpperCase()).join(shortcutSeparator);
    return '$shortcutPrefix$pretty';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationSidebarLocalizations &&
          other.searchHint == searchHint &&
          other.searchEmpty == searchEmpty &&
          other.drawerTitle == drawerTitle &&
          other.drawerCloseLabel == drawerCloseLabel &&
          other.quickAccessTitle == quickAccessTitle &&
          other.addToQuickAccess == addToQuickAccess &&
          other.removeFromQuickAccess == removeFromQuickAccess &&
          other.lockedDefault == lockedDefault &&
          other.shortcutPrefix == shortcutPrefix &&
          other.shortcutSeparator == shortcutSeparator &&
          other.semanticExpanded == semanticExpanded &&
          other.semanticCollapsed == semanticCollapsed &&
          other.semanticLocked == semanticLocked &&
          other.semanticDisabled == semanticDisabled &&
          other.semanticToggleSidebar == semanticToggleSidebar &&
          other.semanticOpenDrawer == semanticOpenDrawer &&
          other.semanticBack == semanticBack;

  @override
  int get hashCode => Object.hash(
        searchHint, searchEmpty, drawerTitle, drawerCloseLabel,
        quickAccessTitle, addToQuickAccess, removeFromQuickAccess,
        lockedDefault, shortcutPrefix, shortcutSeparator,
        semanticExpanded, semanticCollapsed, semanticLocked,
        semanticDisabled, semanticToggleSidebar, semanticOpenDrawer,
        semanticBack,
      );
}
