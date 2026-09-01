// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class SuperNavigationLocalizationAr extends SuperNavigationLocalization {
  SuperNavigationLocalizationAr([String locale = 'ar']) : super(locale);

  @override
  String get searchHint => 'البحث في القائمة…';

  @override
  String searchEmpty(String query) {
    return 'لا توجد نتائج لـ \"$query\"';
  }

  @override
  String get drawerTitle => 'القائمة';

  @override
  String get drawerCloseLabel => 'إغلاق القائمة';

  @override
  String get quickAccessTitle => 'الوصول السريع';

  @override
  String get addToQuickAccess => 'إضافة للوصول السريع';

  @override
  String get removeFromQuickAccess => 'إزالة من الوصول السريع';

  @override
  String get recentsTitle => 'الأخيرة';

  @override
  String get lockedDefault => 'مقفل — ليس لديك صلاحية الوصول';

  @override
  String get semanticExpanded => 'مفتوح';

  @override
  String get semanticCollapsed => 'مغلق';

  @override
  String get semanticLocked => 'مقفل';

  @override
  String get semanticDisabled => 'غير متاح';

  @override
  String get semanticToggleSidebar => 'تبديل الشريط الجانبي';

  @override
  String get semanticOpenDrawer => 'فتح القائمة';
}
