import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'l10n_ar.dart';
import 'l10n_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of SuperNavigationLocalization
/// returned by `SuperNavigationLocalization.of(context)`.
///
/// Applications need to include `SuperNavigationLocalization.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: SuperNavigationLocalization.localizationsDelegates,
///   supportedLocales: SuperNavigationLocalization.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the SuperNavigationLocalization.supportedLocales
/// property.
abstract class SuperNavigationLocalization {
  SuperNavigationLocalization(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static SuperNavigationLocalization of(BuildContext context) {
    return Localizations.of<SuperNavigationLocalization>(
      context,
      SuperNavigationLocalization,
    )!;
  }

  static const LocalizationsDelegate<SuperNavigationLocalization> delegate =
      _SuperNavigationLocalizationDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// Placeholder shown inside the navigation search field when empty.
  ///
  /// In en, this message translates to:
  /// **'Search navigation…'**
  String get searchHint;

  /// Message shown when a search query returns no hits.
  ///
  /// In en, this message translates to:
  /// **'No matches for \"{query}\"'**
  String searchEmpty(String query);

  /// Eyebrow label above the close button in the navigation drawer.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get drawerTitle;

  /// Accessible tooltip and semantic label for the drawer close icon button.
  ///
  /// In en, this message translates to:
  /// **'Close navigation'**
  String get drawerCloseLabel;

  /// Section eyebrow above the synthesized Quick Access favorites band.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get quickAccessTitle;

  /// Tooltip on the star icon when the node is not yet a favorite.
  ///
  /// In en, this message translates to:
  /// **'Add to Quick Access'**
  String get addToQuickAccess;

  /// Tooltip on the star icon when the node is already a favorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from Quick Access'**
  String get removeFromQuickAccess;

  /// Header of the recent-destinations band in the command palette.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentsTitle;

  /// Fallback tooltip when a navigation node is locked and has no explicit lock message.
  ///
  /// In en, this message translates to:
  /// **'Locked — you don\'\'t have access'**
  String get lockedDefault;

  /// Appended to a branch node semantic label when it is expanded.
  ///
  /// In en, this message translates to:
  /// **'expanded'**
  String get semanticExpanded;

  /// Appended to a branch node semantic label when it is collapsed.
  ///
  /// In en, this message translates to:
  /// **'collapsed'**
  String get semanticCollapsed;

  /// Appended to a node semantic label when it is locked.
  ///
  /// In en, this message translates to:
  /// **'locked'**
  String get semanticLocked;

  /// Appended to a node semantic label when it is disabled.
  ///
  /// In en, this message translates to:
  /// **'disabled'**
  String get semanticDisabled;

  /// Semantic label for the rail collapse and expand toggle button.
  ///
  /// In en, this message translates to:
  /// **'Toggle sidebar'**
  String get semanticToggleSidebar;

  /// Semantic label for the hamburger or open-drawer button in drawer mode.
  ///
  /// In en, this message translates to:
  /// **'Open navigation'**
  String get semanticOpenDrawer;
}

class _SuperNavigationLocalizationDelegate
    extends LocalizationsDelegate<SuperNavigationLocalization> {
  const _SuperNavigationLocalizationDelegate();

  @override
  Future<SuperNavigationLocalization> load(Locale locale) {
    return SynchronousFuture<SuperNavigationLocalization>(
      lookupSuperNavigationLocalization(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_SuperNavigationLocalizationDelegate old) => false;
}

SuperNavigationLocalization lookupSuperNavigationLocalization(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return SuperNavigationLocalizationAr();
    case 'en':
      return SuperNavigationLocalizationEn();
  }

  throw FlutterError(
    'SuperNavigationLocalization.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
