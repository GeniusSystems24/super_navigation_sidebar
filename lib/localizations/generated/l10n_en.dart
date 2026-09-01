// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SuperNavigationLocalizationEn extends SuperNavigationLocalization {
  SuperNavigationLocalizationEn([String locale = 'en']) : super(locale);

  @override
  String get searchHint => 'Search navigation…';

  @override
  String searchEmpty(String query) {
    return 'No matches for \"$query\"';
  }

  @override
  String get drawerTitle => 'Navigation';

  @override
  String get drawerCloseLabel => 'Close navigation';

  @override
  String get quickAccessTitle => 'Quick Access';

  @override
  String get addToQuickAccess => 'Add to Quick Access';

  @override
  String get removeFromQuickAccess => 'Remove from Quick Access';

  @override
  String get recentsTitle => 'Recent';

  @override
  String get lockedDefault => 'Locked — you don\'t have access';

  @override
  String get semanticExpanded => 'expanded';

  @override
  String get semanticCollapsed => 'collapsed';

  @override
  String get semanticLocked => 'locked';

  @override
  String get semanticDisabled => 'disabled';

  @override
  String get semanticToggleSidebar => 'Toggle sidebar';

  @override
  String get semanticOpenDrawer => 'Open navigation';
}
