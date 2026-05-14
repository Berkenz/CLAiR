import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ceb.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fil.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
    Locale('ceb'),
    Locale('en'),
    Locale('fil')
  ];

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get navChat;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navLawyers.
  ///
  /// In en, this message translates to:
  /// **'Lawyers'**
  String get navLawyers;

  /// No description provided for @navAppointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get navAppointments;

  /// No description provided for @drawerRecent.
  ///
  /// In en, this message translates to:
  /// **'RECENT'**
  String get drawerRecent;

  /// No description provided for @drawerNoRecentChats.
  ///
  /// In en, this message translates to:
  /// **'No recent chats'**
  String get drawerNoRecentChats;

  /// No description provided for @drawerNavigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get drawerNavigate;

  /// No description provided for @drawerHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get drawerHome;

  /// No description provided for @drawerNewChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get drawerNewChat;

  /// No description provided for @drawerChatLibrary.
  ///
  /// In en, this message translates to:
  /// **'Chat Library'**
  String get drawerChatLibrary;

  /// No description provided for @drawerFindLawyer.
  ///
  /// In en, this message translates to:
  /// **'Find a Lawyer'**
  String get drawerFindLawyer;

  /// No description provided for @drawerNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get drawerNotifications;

  /// No description provided for @drawerAppointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get drawerAppointments;

  /// No description provided for @drawerAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get drawerAccount;

  /// No description provided for @drawerProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get drawerProfile;

  /// No description provided for @drawerSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get drawerSignOut;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @guestAccount.
  ///
  /// In en, this message translates to:
  /// **'Guest Account'**
  String get guestAccount;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @sectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get sectionAccount;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @sectionApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get sectionApp;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @resetAllToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset All to Default'**
  String get resetAllToDefault;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @settingsResetDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset all settings?'**
  String get settingsResetDialogTitle;

  /// No description provided for @settingsResetDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Appearance options (theme, accent, and font size) will return to their defaults.'**
  String get settingsResetDialogBody;

  /// No description provided for @settingsResetSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Settings reset to default.'**
  String get settingsResetSnackbar;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @languageScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get languageScreenTitle;

  /// No description provided for @languageScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a language for menus and labels in CLAiR.'**
  String get languageScreenSubtitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageFilipino.
  ///
  /// In en, this message translates to:
  /// **'Filipino'**
  String get languageFilipino;

  /// No description provided for @languageCebuano.
  ///
  /// In en, this message translates to:
  /// **'Cebuano'**
  String get languageCebuano;

  /// No description provided for @languageUpdatedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Language updated.'**
  String get languageUpdatedSnackbar;

  /// No description provided for @lawyerMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get lawyerMap;

  /// No description provided for @lawyerList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get lawyerList;

  /// No description provided for @lawyerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or specialty…'**
  String get lawyerSearchHint;

  /// No description provided for @lawyerBrowseByPracticeArea.
  ///
  /// In en, this message translates to:
  /// **'Browse by practice area'**
  String get lawyerBrowseByPracticeArea;

  /// No description provided for @lawyerClearWithCount.
  ///
  /// In en, this message translates to:
  /// **'Clear ({count})'**
  String lawyerClearWithCount(int count);

  /// No description provided for @lawyerAllRegistered.
  ///
  /// In en, this message translates to:
  /// **'All registered lawyers'**
  String get lawyerAllRegistered;

  /// No description provided for @lawyerResultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 result} other{{count} results}}'**
  String lawyerResultsCount(int count);

  /// No description provided for @lawyerClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get lawyerClearAll;

  /// No description provided for @lawyerLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load lawyers.'**
  String get lawyerLoadErrorTitle;

  /// No description provided for @lawyerUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error.'**
  String get lawyerUnknownError;

  /// No description provided for @lawyerRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get lawyerRetry;

  /// No description provided for @lawyerEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No registered lawyers yet.'**
  String get lawyerEmptyState;

  /// No description provided for @lawyerNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No lawyers match your filters.'**
  String get lawyerNoMatches;

  /// No description provided for @lawyerClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get lawyerClearFilters;

  /// No description provided for @lawyerVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get lawyerVerified;

  /// No description provided for @lawyerViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get lawyerViewProfile;

  /// No description provided for @lawyerExtraAreas.
  ///
  /// In en, this message translates to:
  /// **'+{count}'**
  String lawyerExtraAreas(int count);

  /// No description provided for @lawyerSharingTitle.
  ///
  /// In en, this message translates to:
  /// **'Sharing conversation with a lawyer'**
  String get lawyerSharingTitle;

  /// No description provided for @lawyerSharingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" — tap any lawyer below to book with this pre-attached'**
  String lawyerSharingSubtitle(String title);

  /// No description provided for @lawyerChipCriminal.
  ///
  /// In en, this message translates to:
  /// **'Criminal'**
  String get lawyerChipCriminal;

  /// No description provided for @lawyerChipFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get lawyerChipFamily;

  /// No description provided for @lawyerChipCorporate.
  ///
  /// In en, this message translates to:
  /// **'Corporate'**
  String get lawyerChipCorporate;

  /// No description provided for @lawyerChipProperty.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get lawyerChipProperty;

  /// No description provided for @lawyerChipFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get lawyerChipFinance;

  /// No description provided for @lawyerChipLabor.
  ///
  /// In en, this message translates to:
  /// **'Labor'**
  String get lawyerChipLabor;

  /// No description provided for @lawyerChipCivil.
  ///
  /// In en, this message translates to:
  /// **'Civil'**
  String get lawyerChipCivil;

  /// No description provided for @lawyerChipImmigration.
  ///
  /// In en, this message translates to:
  /// **'Immigration'**
  String get lawyerChipImmigration;

  /// No description provided for @lawyerChipContracts.
  ///
  /// In en, this message translates to:
  /// **'Contracts'**
  String get lawyerChipContracts;

  /// No description provided for @lawyerChipWills.
  ///
  /// In en, this message translates to:
  /// **'Wills'**
  String get lawyerChipWills;

  /// No description provided for @lawyerChipAdministrative.
  ///
  /// In en, this message translates to:
  /// **'Administrative'**
  String get lawyerChipAdministrative;

  /// No description provided for @lawyerChipEnvironmental.
  ///
  /// In en, this message translates to:
  /// **'Environmental'**
  String get lawyerChipEnvironmental;

  /// No description provided for @lawyerPracticeAdministrativeLaw.
  ///
  /// In en, this message translates to:
  /// **'Administrative Law'**
  String get lawyerPracticeAdministrativeLaw;

  /// No description provided for @lawyerPracticeBankingFinanceLaw.
  ///
  /// In en, this message translates to:
  /// **'Banking & Finance Law'**
  String get lawyerPracticeBankingFinanceLaw;

  /// No description provided for @lawyerPracticeCivilLaw.
  ///
  /// In en, this message translates to:
  /// **'Civil Law'**
  String get lawyerPracticeCivilLaw;

  /// No description provided for @lawyerPracticeConstitutionalLaw.
  ///
  /// In en, this message translates to:
  /// **'Constitutional Law'**
  String get lawyerPracticeConstitutionalLaw;

  /// No description provided for @lawyerPracticeCorporateLaw.
  ///
  /// In en, this message translates to:
  /// **'Corporate Law'**
  String get lawyerPracticeCorporateLaw;

  /// No description provided for @lawyerPracticeCriminalLaw.
  ///
  /// In en, this message translates to:
  /// **'Criminal Law'**
  String get lawyerPracticeCriminalLaw;

  /// No description provided for @lawyerPracticeEnvironmentalLaw.
  ///
  /// In en, this message translates to:
  /// **'Environmental Law'**
  String get lawyerPracticeEnvironmentalLaw;

  /// No description provided for @lawyerPracticeFamilyLaw.
  ///
  /// In en, this message translates to:
  /// **'Family Law'**
  String get lawyerPracticeFamilyLaw;

  /// No description provided for @lawyerPracticeImmigrationLaw.
  ///
  /// In en, this message translates to:
  /// **'Immigration Law'**
  String get lawyerPracticeImmigrationLaw;

  /// No description provided for @lawyerPracticeInsuranceLaw.
  ///
  /// In en, this message translates to:
  /// **'Insurance Law'**
  String get lawyerPracticeInsuranceLaw;

  /// No description provided for @lawyerPracticeIntellectualPropertyLaw.
  ///
  /// In en, this message translates to:
  /// **'Intellectual Property Law'**
  String get lawyerPracticeIntellectualPropertyLaw;

  /// No description provided for @lawyerPracticeLaborLaw.
  ///
  /// In en, this message translates to:
  /// **'Labor Law'**
  String get lawyerPracticeLaborLaw;

  /// No description provided for @lawyerPracticeRealEstateLaw.
  ///
  /// In en, this message translates to:
  /// **'Real Estate Law'**
  String get lawyerPracticeRealEstateLaw;

  /// No description provided for @lawyerPracticeTaxLaw.
  ///
  /// In en, this message translates to:
  /// **'Tax Law'**
  String get lawyerPracticeTaxLaw;

  /// No description provided for @lawyerPracticeContractLaw.
  ///
  /// In en, this message translates to:
  /// **'Contract Law'**
  String get lawyerPracticeContractLaw;

  /// No description provided for @lawyerPracticeEstateWills.
  ///
  /// In en, this message translates to:
  /// **'Estate & Wills'**
  String get lawyerPracticeEstateWills;

  /// No description provided for @lawyerPracticeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get lawyerPracticeOther;

  /// No description provided for @lawyerDesigAssociate.
  ///
  /// In en, this message translates to:
  /// **'Associate'**
  String get lawyerDesigAssociate;

  /// No description provided for @lawyerDesigJuniorAssociate.
  ///
  /// In en, this message translates to:
  /// **'Junior Associate'**
  String get lawyerDesigJuniorAssociate;

  /// No description provided for @lawyerDesigOfCounsel.
  ///
  /// In en, this message translates to:
  /// **'Of Counsel'**
  String get lawyerDesigOfCounsel;

  /// No description provided for @lawyerDesigParalegal.
  ///
  /// In en, this message translates to:
  /// **'Paralegal'**
  String get lawyerDesigParalegal;

  /// No description provided for @lawyerDesigSeniorAssociate.
  ///
  /// In en, this message translates to:
  /// **'Senior Associate'**
  String get lawyerDesigSeniorAssociate;

  /// No description provided for @lawyerDesigSeniorPartner.
  ///
  /// In en, this message translates to:
  /// **'Senior Partner'**
  String get lawyerDesigSeniorPartner;

  /// No description provided for @lawyerDesigManagingPartner.
  ///
  /// In en, this message translates to:
  /// **'Managing Partner'**
  String get lawyerDesigManagingPartner;

  /// No description provided for @lawyerDesigAssociatePartner.
  ///
  /// In en, this message translates to:
  /// **'Associate Partner'**
  String get lawyerDesigAssociatePartner;

  /// No description provided for @lawyerDesigOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get lawyerDesigOther;

  /// No description provided for @brandAppName.
  ///
  /// In en, this message translates to:
  /// **'CLAiR'**
  String get brandAppName;

  /// No description provided for @homeHelloGuest.
  ///
  /// In en, this message translates to:
  /// **'Hello, there'**
  String get homeHelloGuest;

  /// No description provided for @homeHelloName.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String homeHelloName(String name);

  /// No description provided for @homeTagline.
  ///
  /// In en, this message translates to:
  /// **'How can CLAiR help you today?'**
  String get homeTagline;

  /// No description provided for @homeStartNewChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Start new chat'**
  String get homeStartNewChatTitle;

  /// No description provided for @homeStartNewChatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask CLAiR a legal question'**
  String get homeStartNewChatSubtitle;

  /// No description provided for @homeQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get homeQuickActions;

  /// No description provided for @homeSuggestedLawyers.
  ///
  /// In en, this message translates to:
  /// **'Suggested Lawyers'**
  String get homeSuggestedLawyers;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get homeSeeAll;

  /// No description provided for @homeGeneratedDocuments.
  ///
  /// In en, this message translates to:
  /// **'Generated Documents'**
  String get homeGeneratedDocuments;

  /// No description provided for @homeViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get homeViewAll;

  /// No description provided for @homeConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get homeConnect;

  /// No description provided for @homeRatingCasesLine.
  ///
  /// In en, this message translates to:
  /// **'{rating} · {count} cases'**
  String homeRatingCasesLine(String rating, int count);

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome\nBack'**
  String get authWelcomeBack;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authLogIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get authLogIn;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password ?'**
  String get authForgotPassword;

  /// No description provided for @authNoAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get authNoAccountPrompt;

  /// No description provided for @authSignUpLink.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authSignUpLink;

  /// No description provided for @authGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get authGuest;

  /// No description provided for @authGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get authGoogle;

  /// No description provided for @chatConversationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get chatConversationsTitle;

  /// No description provided for @chatNewChatButton.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get chatNewChatButton;

  /// No description provided for @chatNoConversationsYet.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get chatNoConversationsYet;

  /// No description provided for @chatMenuSaveChat.
  ///
  /// In en, this message translates to:
  /// **'Save Chat'**
  String get chatMenuSaveChat;

  /// No description provided for @chatMenuUnsaveChat.
  ///
  /// In en, this message translates to:
  /// **'Unsave Chat'**
  String get chatMenuUnsaveChat;

  /// No description provided for @chatMenuShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get chatMenuShare;

  /// No description provided for @chatMenuDownloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download as PDF'**
  String get chatMenuDownloadPdf;

  /// No description provided for @chatMenuReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get chatMenuReport;

  /// No description provided for @chatMenuShareToLawyer.
  ///
  /// In en, this message translates to:
  /// **'Share to Lawyer'**
  String get chatMenuShareToLawyer;

  /// No description provided for @chatPdfGeneratingSummary.
  ///
  /// In en, this message translates to:
  /// **'Generating PDF summary...'**
  String get chatPdfGeneratingSummary;

  /// No description provided for @chatPdfSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save PDF: {error}'**
  String chatPdfSaveFailed(String error);

  /// No description provided for @chatDisclaimerDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get chatDisclaimerDismiss;

  /// No description provided for @chatTitleNewChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get chatTitleNewChat;

  /// No description provided for @chatTitleCurrentConversation.
  ///
  /// In en, this message translates to:
  /// **'Current conversation'**
  String get chatTitleCurrentConversation;

  /// No description provided for @chatRagDisconnectedBanner.
  ///
  /// In en, this message translates to:
  /// **'Law library (RAG) not connected on server — answer may use general model knowledge only.'**
  String get chatRagDisconnectedBanner;

  /// No description provided for @chatNoLawExcerpts.
  ///
  /// In en, this message translates to:
  /// **'No law excerpts met the relevance threshold for this question.'**
  String get chatNoLawExcerpts;

  /// No description provided for @chatRetrievedForAnswer.
  ///
  /// In en, this message translates to:
  /// **'Retrieved for this answer'**
  String get chatRetrievedForAnswer;

  /// No description provided for @chatSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get chatSourceLabel;

  /// No description provided for @chatEmptyExploreTopic.
  ///
  /// In en, this message translates to:
  /// **'Start a new conversation to explore a different topic.'**
  String get chatEmptyExploreTopic;

  /// No description provided for @chatCopiedClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get chatCopiedClipboard;

  /// No description provided for @chatEditMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Message'**
  String get chatEditMessageTitle;

  /// No description provided for @chatEditMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Edit your message'**
  String get chatEditMessageHint;

  /// No description provided for @chatComposerHint.
  ///
  /// In en, this message translates to:
  /// **'Ask anything'**
  String get chatComposerHint;

  /// No description provided for @chatAssistantGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi! I\'m CLAiR, how may I assist you today?'**
  String get chatAssistantGreeting;

  /// No description provided for @chatLawyersNearYou.
  ///
  /// In en, this message translates to:
  /// **'Lawyers near you'**
  String get chatLawyersNearYou;

  /// No description provided for @chatMatchPercent.
  ///
  /// In en, this message translates to:
  /// **'{head} · {pct}% match'**
  String chatMatchPercent(String head, String pct);

  /// No description provided for @notifMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notifMarkAllRead;

  /// No description provided for @notifEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notifEmpty;

  /// No description provided for @libScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libScreenTitle;

  /// No description provided for @libTabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get libTabHistory;

  /// No description provided for @libTabSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get libTabSaved;

  /// No description provided for @libSearchChatsHint.
  ///
  /// In en, this message translates to:
  /// **'Search chats...'**
  String get libSearchChatsHint;

  /// No description provided for @libPreviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'Start a new message'**
  String get libPreviewEmpty;

  /// No description provided for @libPreviewYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get libPreviewYou;

  /// No description provided for @libPreviewRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent: {text}'**
  String libPreviewRecent(String text);

  /// No description provided for @appearanceSectionTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get appearanceSectionTheme;

  /// No description provided for @appearanceThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceThemeLight;

  /// No description provided for @appearanceThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceThemeDark;

  /// No description provided for @appearanceThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get appearanceThemeSystem;

  /// No description provided for @appearanceAccentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get appearanceAccentColor;

  /// No description provided for @appearanceFontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get appearanceFontSize;

  /// No description provided for @appearanceSavedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Appearance saved'**
  String get appearanceSavedSnackbar;

  /// No description provided for @appearanceSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Appearance'**
  String get appearanceSaveButton;

  /// No description provided for @appearanceFontSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get appearanceFontSmall;

  /// No description provided for @appearanceFontDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get appearanceFontDefault;

  /// No description provided for @appearanceFontLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get appearanceFontLarge;

  /// No description provided for @appearanceFontExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'Extra Large'**
  String get appearanceFontExtraLarge;

  /// No description provided for @histTapToOpen.
  ///
  /// In en, this message translates to:
  /// **'Tap to open conversation'**
  String get histTapToOpen;

  /// No description provided for @histRenameDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename conversation'**
  String get histRenameDialogTitle;

  /// No description provided for @histRenameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter new title'**
  String get histRenameHint;

  /// No description provided for @histRenameButton.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get histRenameButton;

  /// No description provided for @histDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete conversation?'**
  String get histDeleteTitle;

  /// No description provided for @histDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete this conversation and all its messages.'**
  String get histDeleteBody;

  /// No description provided for @histGeneratingPdf.
  ///
  /// In en, this message translates to:
  /// **'Generating PDF...'**
  String get histGeneratingPdf;

  /// No description provided for @histDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to download: {error}'**
  String histDownloadFailed(String error);

  /// No description provided for @histEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get histEmptyTitle;

  /// No description provided for @histEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a chat and your conversations will appear here'**
  String get histEmptySubtitle;

  /// No description provided for @convSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get convSave;

  /// No description provided for @convUnsave.
  ///
  /// In en, this message translates to:
  /// **'Unsave'**
  String get convUnsave;

  /// No description provided for @convRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get convRename;

  /// No description provided for @convShareToLawyer.
  ///
  /// In en, this message translates to:
  /// **'Share to Lawyer'**
  String get convShareToLawyer;

  /// No description provided for @convDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get convDownload;

  /// No description provided for @convDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get convDelete;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @apptNotFoundSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Could not find that appointment in your list.'**
  String get apptNotFoundSnackbar;

  /// No description provided for @apptMyTitle.
  ///
  /// In en, this message translates to:
  /// **'My Appointments'**
  String get apptMyTitle;

  /// No description provided for @apptTotalCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 appointment total} other{{count} appointments total}}'**
  String apptTotalCount(int count);

  /// No description provided for @apptFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get apptFilterAll;

  /// No description provided for @apptFilterPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get apptFilterPending;

  /// No description provided for @apptFilterAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get apptFilterAccepted;

  /// No description provided for @apptFilterCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get apptFilterCancelled;

  /// No description provided for @apptSortNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Booked · Newest first'**
  String get apptSortNewestFirst;

  /// No description provided for @apptSortOldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Booked · Oldest first'**
  String get apptSortOldestFirst;

  /// No description provided for @apptSortChipNewest.
  ///
  /// In en, this message translates to:
  /// **'Sort: newest first'**
  String get apptSortChipNewest;

  /// No description provided for @apptSortChipOldest.
  ///
  /// In en, this message translates to:
  /// **'Sort: oldest first'**
  String get apptSortChipOldest;

  /// No description provided for @apptNoFilterMatch.
  ///
  /// In en, this message translates to:
  /// **'No appointments match this filter'**
  String get apptNoFilterMatch;

  /// No description provided for @apptShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get apptShowAll;

  /// No description provided for @apptSectionCancelledOrDeclined.
  ///
  /// In en, this message translates to:
  /// **'Cancelled or declined'**
  String get apptSectionCancelledOrDeclined;

  /// No description provided for @apptSectionActivePending.
  ///
  /// In en, this message translates to:
  /// **'Active & pending'**
  String get apptSectionActivePending;

  /// No description provided for @apptSectionPastCancelled.
  ///
  /// In en, this message translates to:
  /// **'Past / cancelled or declined'**
  String get apptSectionPastCancelled;

  /// No description provided for @apptEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No appointments yet'**
  String get apptEmptyTitle;

  /// No description provided for @apptEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Book a lawyer consultation and\ntrack your status here'**
  String get apptEmptySubtitle;

  /// No description provided for @apptCardChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get apptCardChat;

  /// No description provided for @apptCardBookedAt.
  ///
  /// In en, this message translates to:
  /// **'Booked {date} · {time}'**
  String apptCardBookedAt(String date, String time);

  /// No description provided for @bookingAppointmentTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Appointment type'**
  String get bookingAppointmentTypeLabel;

  /// No description provided for @bookingAppointmentTypeHint.
  ///
  /// In en, this message translates to:
  /// **'What kind of consultation?'**
  String get bookingAppointmentTypeHint;

  /// No description provided for @bookingAppointmentTypeLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load types. Tap to retry.'**
  String get bookingAppointmentTypeLoadError;

  /// No description provided for @bookingAppointmentTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select an appointment type.'**
  String get bookingAppointmentTypeRequired;

  /// No description provided for @apptBadgeNew.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get apptBadgeNew;

  /// No description provided for @apptStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get apptStatusPending;

  /// No description provided for @apptStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get apptStatusAccepted;

  /// No description provided for @apptStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get apptStatusCancelled;

  /// No description provided for @apptStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get apptStatusDeclined;

  /// No description provided for @apptDetailLabelType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get apptDetailLabelType;

  /// No description provided for @apptDetailLabelLawyer.
  ///
  /// In en, this message translates to:
  /// **'Lawyer'**
  String get apptDetailLabelLawyer;

  /// No description provided for @apptDetailSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get apptDetailSectionDescription;

  /// No description provided for @apptDetailReasonCancellation.
  ///
  /// In en, this message translates to:
  /// **'Cancellation'**
  String get apptDetailReasonCancellation;

  /// No description provided for @apptDetailReasonDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline reason'**
  String get apptDetailReasonDecline;

  /// No description provided for @apptDetailLabelBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get apptDetailLabelBooked;

  /// No description provided for @apptDetailLabelUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get apptDetailLabelUpdated;

  /// No description provided for @apptDetailCancelAppointment.
  ///
  /// In en, this message translates to:
  /// **'Cancel appointment'**
  String get apptDetailCancelAppointment;

  /// No description provided for @apptDetailAttachedConversationTitle.
  ///
  /// In en, this message translates to:
  /// **'Attached CLAiR conversation'**
  String get apptDetailAttachedConversationTitle;

  /// No description provided for @apptDetailAttachedConversationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open the chat you shared when you booked this appointment.'**
  String get apptDetailAttachedConversationSubtitle;

  /// No description provided for @apptDetailBannerCancelledByClientTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointment cancelled'**
  String get apptDetailBannerCancelledByClientTitle;

  /// No description provided for @apptDetailBannerCancelledByClientSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You cancelled this booking. Your lawyer has been notified.'**
  String get apptDetailBannerCancelledByClientSubtitle;

  /// No description provided for @apptDetailBannerConfirmedTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointment accepted'**
  String get apptDetailBannerConfirmedTitle;

  /// No description provided for @apptDetailBannerConfirmedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your lawyer has confirmed this appointment.'**
  String get apptDetailBannerConfirmedSubtitle;

  /// No description provided for @apptDetailBannerPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Awaiting confirmation'**
  String get apptDetailBannerPendingTitle;

  /// No description provided for @apptDetailBannerPendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your request is pending review by the lawyer.'**
  String get apptDetailBannerPendingSubtitle;

  /// No description provided for @apptDetailBannerDeclinedTitle.
  ///
  /// In en, this message translates to:
  /// **'Request declined'**
  String get apptDetailBannerDeclinedTitle;

  /// No description provided for @apptDetailBannerDeclinedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The lawyer was unable to accept this request.'**
  String get apptDetailBannerDeclinedSubtitle;

  /// No description provided for @apptDetailBannerUnknownTitle.
  ///
  /// In en, this message translates to:
  /// **'Unknown status'**
  String get apptDetailBannerUnknownTitle;

  /// No description provided for @apptDetailChatWithLawyer.
  ///
  /// In en, this message translates to:
  /// **'Chat with {lawyerName}'**
  String apptDetailChatWithLawyer(String lawyerName);

  /// No description provided for @apptDetailChatLockedCancelledSelf.
  ///
  /// In en, this message translates to:
  /// **'Chat is unavailable — you cancelled this appointment.'**
  String get apptDetailChatLockedCancelledSelf;

  /// No description provided for @apptDetailChatLockedCancelledDeclined.
  ///
  /// In en, this message translates to:
  /// **'Chat is unavailable — this appointment was declined.'**
  String get apptDetailChatLockedCancelledDeclined;

  /// No description provided for @apptDetailChatLockedPending.
  ///
  /// In en, this message translates to:
  /// **'Chat will unlock once your appointment is accepted.'**
  String get apptDetailChatLockedPending;

  /// No description provided for @apptDetailCancelOptionsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load cancellation options. Try again later.'**
  String get apptDetailCancelOptionsFailed;

  /// No description provided for @apptDetailCancelledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Appointment cancelled.'**
  String get apptDetailCancelledSuccess;

  /// No description provided for @apptDetailCancelWhyTitle.
  ///
  /// In en, this message translates to:
  /// **'Why are you cancelling?'**
  String get apptDetailCancelWhyTitle;

  /// No description provided for @apptDetailCancelWhySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your lawyer will see the reason you choose.'**
  String get apptDetailCancelWhySubtitle;

  /// No description provided for @apptDetailCancelTellMoreHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us a bit more…'**
  String get apptDetailCancelTellMoreHint;

  /// No description provided for @apptDetailCancelErrorPickReason.
  ///
  /// In en, this message translates to:
  /// **'Please select a reason.'**
  String get apptDetailCancelErrorPickReason;

  /// No description provided for @apptDetailCancelErrorOtherDetails.
  ///
  /// In en, this message translates to:
  /// **'Please briefly describe why you are cancelling.'**
  String get apptDetailCancelErrorOtherDetails;

  /// No description provided for @apptDetailKeepAppointment.
  ///
  /// In en, this message translates to:
  /// **'Keep appointment'**
  String get apptDetailKeepAppointment;

  /// No description provided for @apptDetailConfirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Confirm cancel'**
  String get apptDetailConfirmCancel;

  /// No description provided for @libSavedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved chats'**
  String get libSavedEmptyTitle;

  /// No description provided for @libSavedEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bookmark chats to find\nthem easily later'**
  String get libSavedEmptySubtitle;

  /// No description provided for @libSearchNoSaved.
  ///
  /// In en, this message translates to:
  /// **'No saved chats found'**
  String get libSearchNoSaved;

  /// No description provided for @libSearchNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No chats found'**
  String get libSearchNoHistory;

  /// No description provided for @libSearchTryDifferent.
  ///
  /// In en, this message translates to:
  /// **'Try a different keyword.'**
  String get libSearchTryDifferent;

  /// No description provided for @commonSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get commonSubmit;

  /// No description provided for @legalDocNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Official wording'**
  String get legalDocNoticeTitle;

  /// No description provided for @legalDocNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'For legal accuracy, the full text below is in English.'**
  String get legalDocNoticeBody;

  /// No description provided for @signupTermsPrivacyRequired.
  ///
  /// In en, this message translates to:
  /// **'You must agree to the Terms of Use and Privacy Policy to continue.'**
  String get signupTermsPrivacyRequired;

  /// No description provided for @signupAgreementLead.
  ///
  /// In en, this message translates to:
  /// **'I have read and agree to the CLAiR '**
  String get signupAgreementLead;

  /// No description provided for @signupAgreementMiddle.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get signupAgreementMiddle;

  /// No description provided for @signupAgreementTail.
  ///
  /// In en, this message translates to:
  /// **'. I understand that CLAiR provides legal information only and does not constitute legal advice or create an attorney-client relationship.'**
  String get signupAgreementTail;

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signupTitle;

  /// No description provided for @signupCompleteProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get signupCompleteProfileTitle;

  /// No description provided for @signupGoogleNameBanner.
  ///
  /// In en, this message translates to:
  /// **'Almost there! Just add your name and agree to our terms to complete your Google sign-up.'**
  String get signupGoogleNameBanner;

  /// No description provided for @signupFirstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get signupFirstNameLabel;

  /// No description provided for @signupLastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get signupLastNameLabel;

  /// No description provided for @signupFirstNameRequired.
  ///
  /// In en, this message translates to:
  /// **'First name is required'**
  String get signupFirstNameRequired;

  /// No description provided for @signupLastNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Last name is required'**
  String get signupLastNameRequired;

  /// No description provided for @signupContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get signupContinueButton;

  /// No description provided for @signupCompleteSignUpButton.
  ///
  /// In en, this message translates to:
  /// **'Complete Sign Up'**
  String get signupCompleteSignUpButton;

  /// No description provided for @reportScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Report an issue'**
  String get reportScreenTitle;

  /// No description provided for @reportScreenHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Report an issue with CLAiR'**
  String get reportScreenHeroTitle;

  /// No description provided for @reportScreenHeroBody.
  ///
  /// In en, this message translates to:
  /// **'Found a bug, wrong answer, or have feedback? We read every report and use it to keep CLAiR accurate and useful.'**
  String get reportScreenHeroBody;

  /// No description provided for @reportScreenAnonymousNote.
  ///
  /// In en, this message translates to:
  /// **'Reports are anonymous unless you include details in your description.'**
  String get reportScreenAnonymousNote;

  /// No description provided for @reportIssueCategoryStep.
  ///
  /// In en, this message translates to:
  /// **'Issue category'**
  String get reportIssueCategoryStep;

  /// No description provided for @reportDescribeIssueHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue in detail. What happened, and what did you expect?'**
  String get reportDescribeIssueHint;

  /// No description provided for @reportPrivacyNoteBody.
  ///
  /// In en, this message translates to:
  /// **'Reports are handled confidentially. We may follow up to verify the issue and improve CLAiR.'**
  String get reportPrivacyNoteBody;

  /// No description provided for @reportSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get reportSubmitButton;

  /// No description provided for @reportSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Report submitted'**
  String get reportSuccessTitle;

  /// No description provided for @reportSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Thank you for helping improve CLAiR.\nOur team will review your report carefully.'**
  String get reportSuccessBody;

  /// No description provided for @reportBackToSettings.
  ///
  /// In en, this message translates to:
  /// **'Back to settings'**
  String get reportBackToSettings;

  /// No description provided for @reportReplySheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Report reply'**
  String get reportReplySheetTitle;

  /// No description provided for @reportReplySheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help us improve legal accuracy and safety.'**
  String get reportReplySheetSubtitle;

  /// No description provided for @reportReplyExplainHint.
  ///
  /// In en, this message translates to:
  /// **'What is inaccurate or misleading about this response? Include any statutes or concepts if relevant.'**
  String get reportReplyExplainHint;

  /// No description provided for @reportReplySubmittedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Thanks — your report was sent.'**
  String get reportReplySubmittedSnackbar;

  /// No description provided for @lawyerConcernTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a concern'**
  String get lawyerConcernTitle;

  /// No description provided for @lawyerConcernAbout.
  ///
  /// In en, this message translates to:
  /// **'About: {name}'**
  String lawyerConcernAbout(String name);

  /// No description provided for @lawyerConcernShareSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Report shared via share sheet.'**
  String get lawyerConcernShareSnackbar;

  /// No description provided for @reportFieldContentReported.
  ///
  /// In en, this message translates to:
  /// **'Content being reported'**
  String get reportFieldContentReported;

  /// No description provided for @reportFieldChooseQuestionLegal.
  ///
  /// In en, this message translates to:
  /// **'What best describes this issue?'**
  String get reportFieldChooseQuestionLegal;

  /// No description provided for @reportFieldChooseCategoryLegalIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose the category that closest matches the legal concern.'**
  String get reportFieldChooseCategoryLegalIntro;

  /// No description provided for @reportFieldIssueCategory.
  ///
  /// In en, this message translates to:
  /// **'Issue category'**
  String get reportFieldIssueCategory;

  /// No description provided for @reportFieldYourExplanation.
  ///
  /// In en, this message translates to:
  /// **'Your explanation'**
  String get reportFieldYourExplanation;

  /// No description provided for @reportFieldExplanationBlurb.
  ///
  /// In en, this message translates to:
  /// **'A short explanation is required so our team can understand the issue.'**
  String get reportFieldExplanationBlurb;

  /// No description provided for @reportHintBriefConcern.
  ///
  /// In en, this message translates to:
  /// **'Briefly explain what is wrong or concerning…'**
  String get reportHintBriefConcern;

  /// No description provided for @reportValidationExplanationShort.
  ///
  /// In en, this message translates to:
  /// **'Please add a short explanation (at least a sentence).'**
  String get reportValidationExplanationShort;

  /// No description provided for @reportLawBadLegalLabel.
  ///
  /// In en, this message translates to:
  /// **'Bad Legal Information'**
  String get reportLawBadLegalLabel;

  /// No description provided for @reportLawBadLegalDesc.
  ///
  /// In en, this message translates to:
  /// **'The response contains factually incorrect laws, cases, or statutes.'**
  String get reportLawBadLegalDesc;

  /// No description provided for @reportLawOutdatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Outdated Law or Regulation'**
  String get reportLawOutdatedLabel;

  /// No description provided for @reportLawOutdatedDesc.
  ///
  /// In en, this message translates to:
  /// **'The cited law has been amended, repealed, or superseded.'**
  String get reportLawOutdatedDesc;

  /// No description provided for @reportLawMisleadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Misleading Interpretation'**
  String get reportLawMisleadingLabel;

  /// No description provided for @reportLawMisleadingDesc.
  ///
  /// In en, this message translates to:
  /// **'Legal reasoning is skewed, incomplete, or taken out of context.'**
  String get reportLawMisleadingDesc;

  /// No description provided for @reportLawJurisdictionLabel.
  ///
  /// In en, this message translates to:
  /// **'Wrong Jurisdiction'**
  String get reportLawJurisdictionLabel;

  /// No description provided for @reportLawJurisdictionDesc.
  ///
  /// In en, this message translates to:
  /// **'Laws from a different country, state, or region were applied.'**
  String get reportLawJurisdictionDesc;

  /// No description provided for @reportLawMissingContextLabel.
  ///
  /// In en, this message translates to:
  /// **'Missing Legal Context'**
  String get reportLawMissingContextLabel;

  /// No description provided for @reportLawMissingContextDesc.
  ///
  /// In en, this message translates to:
  /// **'Key exceptions, conditions, or legal nuances were omitted.'**
  String get reportLawMissingContextDesc;

  /// No description provided for @reportLawHarmfulLabel.
  ///
  /// In en, this message translates to:
  /// **'Potentially Harmful Advice'**
  String get reportLawHarmfulLabel;

  /// No description provided for @reportLawHarmfulDesc.
  ///
  /// In en, this message translates to:
  /// **'Following this advice could cause legal harm or risk.'**
  String get reportLawHarmfulDesc;

  /// No description provided for @reportLawUnclearLabel.
  ///
  /// In en, this message translates to:
  /// **'Unclear or Confusing Response'**
  String get reportLawUnclearLabel;

  /// No description provided for @reportLawUnclearDesc.
  ///
  /// In en, this message translates to:
  /// **'The answer is too vague or difficult to apply in a legal context.'**
  String get reportLawUnclearDesc;

  /// No description provided for @reportLawOtherLabel.
  ///
  /// In en, this message translates to:
  /// **'Other Legal Concern'**
  String get reportLawOtherLabel;

  /// No description provided for @reportLawOtherDesc.
  ///
  /// In en, this message translates to:
  /// **'A concern not described by any category above.'**
  String get reportLawOtherDesc;

  /// No description provided for @reportAppBugLabel.
  ///
  /// In en, this message translates to:
  /// **'App Bug'**
  String get reportAppBugLabel;

  /// No description provided for @reportAppBugDesc.
  ///
  /// In en, this message translates to:
  /// **'Something in the app is broken or behaving incorrectly.'**
  String get reportAppBugDesc;

  /// No description provided for @reportAppWrongAiLabel.
  ///
  /// In en, this message translates to:
  /// **'Wrong AI Response'**
  String get reportAppWrongAiLabel;

  /// No description provided for @reportAppWrongAiDesc.
  ///
  /// In en, this message translates to:
  /// **'CLAiR gave an inaccurate, irrelevant, or harmful answer.'**
  String get reportAppWrongAiDesc;

  /// No description provided for @reportAppMisleadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Misleading Content'**
  String get reportAppMisleadingLabel;

  /// No description provided for @reportAppMisleadingDesc.
  ///
  /// In en, this message translates to:
  /// **'Information was deceptive or presented out of context.'**
  String get reportAppMisleadingDesc;

  /// No description provided for @reportAppPrivacyLabel.
  ///
  /// In en, this message translates to:
  /// **'Privacy or Security Concern'**
  String get reportAppPrivacyLabel;

  /// No description provided for @reportAppPrivacyDesc.
  ///
  /// In en, this message translates to:
  /// **'An issue related to how your data is handled or stored.'**
  String get reportAppPrivacyDesc;

  /// No description provided for @reportAppFeatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Feature Feedback'**
  String get reportAppFeatureLabel;

  /// No description provided for @reportAppFeatureDesc.
  ///
  /// In en, this message translates to:
  /// **'Suggestions for new features or improvements to the app.'**
  String get reportAppFeatureDesc;

  /// No description provided for @reportAppOtherLabel.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportAppOtherLabel;

  /// No description provided for @reportAppOtherDesc.
  ///
  /// In en, this message translates to:
  /// **'An issue not covered by any of the categories above.'**
  String get reportAppOtherDesc;

  /// No description provided for @helpHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'How can we help?'**
  String get helpHeroTitle;

  /// No description provided for @helpHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse common questions or search below.'**
  String get helpHeroSubtitle;

  /// No description provided for @helpSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search FAQs…'**
  String get helpSearchHint;

  /// No description provided for @helpEmptyNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String helpEmptyNoResults(String query);

  /// No description provided for @helpEmptySuggest.
  ///
  /// In en, this message translates to:
  /// **'Try different keywords or browse the sections above.'**
  String get helpEmptySuggest;

  /// No description provided for @helpSecUsing.
  ///
  /// In en, this message translates to:
  /// **'Using CLAiR'**
  String get helpSecUsing;

  /// No description provided for @helpSecLawyers.
  ///
  /// In en, this message translates to:
  /// **'Lawyers & Appointments'**
  String get helpSecLawyers;

  /// No description provided for @helpSecPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get helpSecPrivacy;

  /// No description provided for @helpSecAccount.
  ///
  /// In en, this message translates to:
  /// **'Account & Settings'**
  String get helpSecAccount;

  /// No description provided for @helpSecReporting.
  ///
  /// In en, this message translates to:
  /// **'Reporting & Feedback'**
  String get helpSecReporting;

  /// No description provided for @helpFaqEnglishNotice.
  ///
  /// In en, this message translates to:
  /// **'Detailed FAQ answers below are in English for legal accuracy.'**
  String get helpFaqEnglishNotice;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ceb', 'en', 'fil'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ceb':
      return AppLocalizationsCeb();
    case 'en':
      return AppLocalizationsEn();
    case 'fil':
      return AppLocalizationsFil();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
