// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Cebuano (`ceb`).
class AppLocalizationsCeb extends AppLocalizations {
  AppLocalizationsCeb([String locale = 'ceb']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navChat => 'Chat';

  @override
  String get navLibrary => 'Library';

  @override
  String get navLawyers => 'Lawyers';

  @override
  String get navAppointments => 'Appointments';

  @override
  String get drawerRecent => 'RECENT';

  @override
  String get drawerNoRecentChats => 'No recent chats';

  @override
  String get drawerNavigate => 'Navigate';

  @override
  String get drawerHome => 'Home';

  @override
  String get drawerNewChat => 'New Chat';

  @override
  String get drawerChatLibrary => 'Chat Library';

  @override
  String get drawerFindLawyer => 'Pangitag abogado';

  @override
  String get drawerNotifications => 'Notifications';

  @override
  String get drawerAppointments => 'Appointments';

  @override
  String get drawerAccount => 'Account';

  @override
  String get drawerProfile => 'Profile';

  @override
  String get drawerSignOut => 'Sign Out';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get guestAccount => 'Guest Account';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get sectionAccount => 'Account';

  @override
  String get email => 'Email';

  @override
  String get notifications => 'Notifications';

  @override
  String get security => 'Security';

  @override
  String get sectionApp => 'App';

  @override
  String get appearance => 'Appearance';

  @override
  String get appLanguage => 'Pinulongan sa app';

  @override
  String get sectionAbout => 'About';

  @override
  String get report => 'Pag-report';

  @override
  String get helpCenter => 'Sentro sa Tabang';

  @override
  String get termsOfUse => 'Mga Termino sa Paggamit';

  @override
  String get privacyPolicy => 'Polisiya sa Privacy';

  @override
  String get resetAllToDefault => 'Ibalik sa default';

  @override
  String get logOut => 'Log out';

  @override
  String get exitGuestSession => 'Biyaan ang Guest Session';

  @override
  String get deleteAccount => 'Tangtangon ang account';

  @override
  String get settingsResetDialogTitle => 'I-reset tanang setting?';

  @override
  String get settingsResetDialogBody =>
      'Ang tema, accent, ug gidak-on sa font mobalik sa default.';

  @override
  String get settingsResetSnackbar => 'Naibalik na ang mga setting sa default.';

  @override
  String get commonCancel => 'Kanselahon';

  @override
  String get commonConfirm => 'Kompirmahon';

  @override
  String get languageScreenTitle => 'Pinulongan sa app';

  @override
  String get languageScreenSubtitle =>
      'Pagpili og pinulongan alang sa menu ug label sa CLAiR.';

  @override
  String get languageEnglish => 'Iningles';

  @override
  String get languageFilipino => 'Filipino';

  @override
  String get languageCebuano => 'Bisaya';

  @override
  String get languageUpdatedSnackbar => 'Na-update ang pinulongan.';

  @override
  String get lawyerMap => 'Mapa';

  @override
  String get lawyerList => 'Lista';

  @override
  String get lawyerSearchHint => 'Pangitaa pinaagi sa ngalan o specialty…';

  @override
  String get lawyerBrowseByPracticeArea => 'Tan-awa sumala sa practice area';

  @override
  String lawyerClearWithCount(int count) {
    return 'Kuhaa ($count)';
  }

  @override
  String get lawyerAllRegistered => 'Tanang rehistradong abogado';

  @override
  String lawyerResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ka mga resulta',
      one: '1 ka resulta',
    );
    return '$_temp0';
  }

  @override
  String get lawyerClearAll => 'Kuhaa tanan';

  @override
  String get lawyerLoadErrorTitle => 'Dili ma-load ang mga abogado.';

  @override
  String get lawyerUnknownError => 'Wala mailhing sayop.';

  @override
  String get lawyerRetry => 'Suwayi pag-usab';

  @override
  String get lawyerEmptyState => 'Walay rehistradong abogado karon.';

  @override
  String get lawyerNoMatches => 'Walay abogadong match sa imong filter.';

  @override
  String get lawyerClearFilters => 'Kuhaa ang mga filter';

  @override
  String get lawyerVerified => 'Na-verify';

  @override
  String get lawyerViewProfile => 'Tan-awa ang profile';

  @override
  String lawyerExtraAreas(int count) {
    return '+$count';
  }

  @override
  String get lawyerSharingTitle => 'Gipaambit ang panag-istorya sa abogado';

  @override
  String lawyerSharingSubtitle(String title) {
    return '\"$title\" — i-tap ang abogado sa ubos aron mag-book nga adunay naka-attach';
  }

  @override
  String get lawyerChipCriminal => 'Kriminal';

  @override
  String get lawyerChipFamily => 'Pamilya';

  @override
  String get lawyerChipCorporate => 'Korporasyon';

  @override
  String get lawyerChipProperty => 'Propiedad';

  @override
  String get lawyerChipFinance => 'Pinansya';

  @override
  String get lawyerChipLabor => 'Labor';

  @override
  String get lawyerChipCivil => 'Sibil';

  @override
  String get lawyerChipImmigration => 'Imigrasyon';

  @override
  String get lawyerChipContracts => 'Kontrata';

  @override
  String get lawyerChipWills => 'Testamento';

  @override
  String get lawyerChipAdministrative => 'Administratibo';

  @override
  String get lawyerChipEnvironmental => 'Kinaiyahan';

  @override
  String get lawyerPracticeAdministrativeLaw => 'Administratibong balaod';

  @override
  String get lawyerPracticeBankingFinanceLaw => 'Balaod sa bangko ug pinansya';

  @override
  String get lawyerPracticeCivilLaw => 'Sibil nga balaod';

  @override
  String get lawyerPracticeConstitutionalLaw => 'Konstitusyonal nga balaod';

  @override
  String get lawyerPracticeCorporateLaw => 'Balaod sa korporasyon';

  @override
  String get lawyerPracticeCriminalLaw => 'Kriminal nga balaod';

  @override
  String get lawyerPracticeEnvironmentalLaw => 'Balaod sa kinaiyahan';

  @override
  String get lawyerPracticeFamilyLaw => 'Balaod sa pamilya';

  @override
  String get lawyerPracticeImmigrationLaw => 'Balaod sa imigrasyon';

  @override
  String get lawyerPracticeInsuranceLaw => 'Balaod sa seguro';

  @override
  String get lawyerPracticeIntellectualPropertyLaw =>
      'Balaod sa intellectual property';

  @override
  String get lawyerPracticeLaborLaw => 'Balaod sa trabaho';

  @override
  String get lawyerPracticeRealEstateLaw => 'Balaod sa real estate';

  @override
  String get lawyerPracticeTaxLaw => 'Balaod sa buhis';

  @override
  String get lawyerPracticeContractLaw => 'Balaod sa kontrata';

  @override
  String get lawyerPracticeEstateWills => 'Katigayonan ug testamento';

  @override
  String get lawyerPracticeOther => 'Uban';

  @override
  String get lawyerDesigAssociate => 'Associate';

  @override
  String get lawyerDesigJuniorAssociate => 'Junior Associate';

  @override
  String get lawyerDesigOfCounsel => 'Of Counsel';

  @override
  String get lawyerDesigParalegal => 'Paralegal';

  @override
  String get lawyerDesigSeniorAssociate => 'Senior Associate';

  @override
  String get lawyerDesigSeniorPartner => 'Senior Partner';

  @override
  String get lawyerDesigManagingPartner => 'Managing Partner';

  @override
  String get lawyerDesigAssociatePartner => 'Associate Partner';

  @override
  String get lawyerDesigOther => 'Uban';

  @override
  String get brandAppName => 'CLAiR';

  @override
  String get homeHelloGuest => 'Kumusta';

  @override
  String homeHelloName(String name) {
    return 'Kumusta, $name';
  }

  @override
  String get homeTagline => 'Unsaon ka matabangan sa CLAiR karon?';

  @override
  String get homeStartNewChatTitle => 'Sugdi og bag-ong chat';

  @override
  String get homeStartNewChatSubtitle =>
      'Pagpamangkot og legal nga pangutana sa CLAiR';

  @override
  String get homeQuickActions => 'Paspas nga aksyon';

  @override
  String get homeSuggestedLawyers => 'Gisugyot nga mga abogado';

  @override
  String get homeSeeAll => 'Tan-awa tanan';

  @override
  String get homeGeneratedDocuments => 'Mga dokumentong gihimo';

  @override
  String get homeViewAll => 'Tan-awa tanan';

  @override
  String get homeConnect => 'Konekta';

  @override
  String homeRatingCasesLine(String rating, int count) {
    return '$rating · $count ka mga kaso';
  }

  @override
  String get authWelcomeBack => 'Maayong\npagbalik';

  @override
  String get authPassword => 'Password';

  @override
  String get authLogIn => 'Sulod';

  @override
  String get authForgotPassword => 'Nakalimtan ang password?';

  @override
  String get authNoAccountPrompt => 'Walay account? ';

  @override
  String get authSignUpLink => 'Mag-sign up';

  @override
  String get authGuest => 'Guest';

  @override
  String get authGoogle => 'Google';

  @override
  String get chatConversationsTitle => 'Mga panag-istorya';

  @override
  String get chatNewChatButton => 'Bag-ong chat';

  @override
  String get chatNoConversationsYet => 'Walay panag-istorya pa';

  @override
  String get chatMenuSaveChat => 'I-save ang chat';

  @override
  String get chatMenuUnsaveChat => 'Kuhaa ang save sa chat';

  @override
  String get chatMenuShare => 'Ipaambit';

  @override
  String get chatMenuDownloadPdf => 'Download isip PDF';

  @override
  String get chatMenuReport => 'Report';

  @override
  String get chatMenuShareToLawyer => 'Ipaambit sa abogado';

  @override
  String get chatMenuDelete => 'Tangtanga ang chat';

  @override
  String get chatPdfGeneratingSummary => 'Naghimo og PDF summary...';

  @override
  String chatPdfSaveFailed(String error) {
    return 'Dili ma-save ang PDF: $error';
  }

  @override
  String get chatDisclaimerDismiss => 'Sirhi';

  @override
  String get chatTermsDisclaimerBody =>
      'Pinaagi sa pag-chat sa CLAiR, usa ka AI chatbot, mouyon ka sa among';

  @override
  String get chatTermsDisclaimerTerms => 'Mga Termino sa Paggamit';

  @override
  String get chatTermsDisclaimerAnd => 'ug';

  @override
  String get chatTermsDisclaimerPrivacy => 'Patakaran sa Privacy';

  @override
  String get chatTermsDisclaimerPeriod => '.';

  @override
  String get chatTitleNewChat => 'Bag-ong chat';

  @override
  String get chatTitleCurrentConversation => 'Karon nga panag-istorya';

  @override
  String get chatRagDisconnectedBanner =>
      'Dili nakakonekta ang law library (RAG) sa server — mahimong gumamit og kinatibuk-ang kahibalo ang tubag.';

  @override
  String get chatNoLawExcerpts =>
      'Walay law excerpt nga nakab-ot sa relevance threshold niini nga pangutana.';

  @override
  String get chatLawyerReportedBanner =>
      'Gi-flag sa abogado kining tubaga alang sa review human nimo gipaambit kining chat. Isipa kini nga kinatibuk-ang impormasyon lamang—dili legal advice.';

  @override
  String get chatRetrievedForAnswer => 'Gikuha alang niini nga tubag';

  @override
  String get chatSourceLabel => 'Tinubdan';

  @override
  String get chatOpenSource => 'Ablihi ang tinubdan';

  @override
  String get chatEmptyExploreTopic =>
      'Pagsugod og bag-ong panag-istorya aron usbon ang lain nga hilisgutan.';

  @override
  String get chatCopiedClipboard => 'Nakopya sa clipboard';

  @override
  String get chatEditMessageTitle => 'Usba ang mensahe';

  @override
  String get chatEditMessageHint => 'Usba ang imong mensahe';

  @override
  String get chatComposerHint => 'Pagpamangkot og bisan unsa';

  @override
  String get chatAssistantGreeting =>
      'Kumusta! Ako si CLAiR, unsa may akong matabangan kanimo karon?';

  @override
  String get chatLawyersNearYou => 'Mga abogado duol nimo';

  @override
  String chatMatchPercent(String head, String pct) {
    return '$head · $pct% nga match';
  }

  @override
  String get notifMarkAllRead => 'Markahi tanan nga nabasa na';

  @override
  String get notifEmpty => 'Walay notification pa';

  @override
  String get notifBannerDismissTooltip => 'I-dismiss';

  @override
  String get notifClearAll => 'I-clear tanan';

  @override
  String get notifClearAllConfirmTitle => 'I-clear tanan nga notification?';

  @override
  String get notifClearAllConfirmBody =>
      'Permanenteng tangtangon ang tanan nga notification. Dili na ma-undo.';

  @override
  String get notifDeleteTooltip => 'Tangtangon';

  @override
  String get notifDeleteConfirmTitle => 'Tangtangon kini nga notification?';

  @override
  String get notifDeleteConfirmBody => 'Dili na ma-undo.';

  @override
  String get libScreenTitle => 'Library';

  @override
  String get libTabHistory => 'History';

  @override
  String get libTabSaved => 'Saved';

  @override
  String get libSearchChatsHint => 'Pangitaa ang titulo ug mensahe...';

  @override
  String get libPreviewEmpty => 'Sugdi og bag-ong mensahe';

  @override
  String get libPreviewYou => 'Ikaw';

  @override
  String libPreviewRecent(String text) {
    return 'Bag-o lang: $text';
  }

  @override
  String get appearanceSectionTheme => 'Tema';

  @override
  String get appearanceThemeLight => 'Light';

  @override
  String get appearanceThemeDark => 'Dark';

  @override
  String get appearanceThemeSystem => 'System';

  @override
  String get appearanceAccentColor => 'Accent color';

  @override
  String get appearanceFontSize => 'Kadako sa font';

  @override
  String get appearanceSavedSnackbar => 'Na-save ang panagway';

  @override
  String get appearanceSaveButton => 'I-save ang panagway';

  @override
  String get appearanceFontSmall => 'Gamay';

  @override
  String get appearanceFontDefault => 'Default';

  @override
  String get appearanceFontLarge => 'Dako';

  @override
  String get appearanceFontExtraLarge => 'Labing dako';

  @override
  String get histTapToOpen => 'I-tap aron ablihan ang panag-istorya';

  @override
  String get histRenameDialogTitle => 'Usba ang ngalan sa panag-istorya';

  @override
  String get histRenameHint => 'Isulod ang bag-ong pamagat';

  @override
  String get histRenameButton => 'Usba ang ngalan';

  @override
  String get histDeleteTitle => 'Tangtangon ang panag-istorya?';

  @override
  String get histDeleteBody =>
      'Permanenteng matangtang kini nga panag-istorya ug tanang mensahe.';

  @override
  String get histGeneratingPdf => 'Naghimo og PDF...';

  @override
  String histDownloadFailed(String error) {
    return 'Dili ma-download: $error';
  }

  @override
  String get histEmptyTitle => 'Walay panag-istorya pa';

  @override
  String get histEmptySubtitle =>
      'Pagsugod og chat ug makita dinhi ang imong mga panag-istorya';

  @override
  String get convSave => 'I-save';

  @override
  String get convUnsave => 'Kuhaa ang save';

  @override
  String get convRename => 'Usba ang ngalan';

  @override
  String get convShareToLawyer => 'Ipaambit sa abogado';

  @override
  String get convDownload => 'Download';

  @override
  String get convDelete => 'Tangtangon';

  @override
  String get commonSave => 'I-save';

  @override
  String get commonDelete => 'Tangtangon';

  @override
  String get apptNotFoundSnackbar =>
      'Dili makit-an kana nga appointment sa imong lista.';

  @override
  String get apptMyTitle => 'Akong mga appointment';

  @override
  String apptTotalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ka mga appointment sa kinatibuk-an',
      one: '1 appointment sa kinatibuk-an',
    );
    return '$_temp0';
  }

  @override
  String get apptFilterAll => 'Tanana';

  @override
  String get apptFilterPending => 'Pending';

  @override
  String get apptFilterAccepted => 'Accepted';

  @override
  String get apptFilterResolved => 'Resolved';

  @override
  String get apptFilterCancelled => 'Cancelled';

  @override
  String get apptSortNewestFirst => 'Gi-book · Pinaka bag-o una';

  @override
  String get apptSortOldestFirst => 'Gi-book · Pinaka karaan una';

  @override
  String get apptSortChipNewest => 'Ayos: pinaka bag-o una';

  @override
  String get apptSortChipOldest => 'Ayos: pinaka karaan una';

  @override
  String get apptNoFilterMatch =>
      'Walay appointment nga match niini nga filter';

  @override
  String get apptShowAll => 'Ipakita tanan';

  @override
  String get apptSectionCancelledOrDeclined => 'Gikanselar o gibalibaran';

  @override
  String get apptSectionActivePending => 'Aktibo ug pending';

  @override
  String get apptSectionPastCancelled => 'Kaniadto / gikanselar o gibalibaran';

  @override
  String get apptEmptyTitle => 'Walay appointment pa';

  @override
  String get apptEmptySubtitle =>
      'Mag-book og konsultasyon sa abogado ug\nsundaa ang status dinhi';

  @override
  String get apptCardChat => 'Chat';

  @override
  String apptCardBookedAt(String date, String time) {
    return 'Gi-book $date · $time';
  }

  @override
  String get bookingAppointmentTypeLabel => 'Matang sa appointment';

  @override
  String get bookingAppointmentTypeHint => 'Unsa nga matang sa konsultasyon?';

  @override
  String get bookingAppointmentTypeLoadError =>
      'Dili ma-load ang mga matang. I-tap aron sulayan pag-usab.';

  @override
  String get bookingAppointmentTypeRequired =>
      'Palihug pagpili og matang sa appointment.';

  @override
  String get apptBadgeNew => 'BAG-O';

  @override
  String get apptStatusPending => 'Pending';

  @override
  String get apptStatusAccepted => 'Accepted';

  @override
  String get apptStatusCancelled => 'Cancelled';

  @override
  String get apptStatusDeclined => 'Gibalibaran';

  @override
  String get apptDetailLabelType => 'Matang';

  @override
  String get apptDetailLabelLawyer => 'Abogado';

  @override
  String get apptDetailSectionDescription => 'Deskripsyon';

  @override
  String get apptDetailReasonCancellation => 'Pagkansela';

  @override
  String get apptDetailReasonDecline => 'Rason sa pagdili';

  @override
  String get apptDetailLabelBooked => 'Gi-book';

  @override
  String get apptDetailLabelUpdated => 'Gi-update';

  @override
  String get apptDetailCancelAppointment => 'Kanselaha ang appointment';

  @override
  String get apptDetailAttachedConversationTitle =>
      'Naka-attach nga CLAiR conversation';

  @override
  String get apptDetailAttachedConversationSubtitle =>
      'Ablihi ang chat nga imong gipaambit pag-book niini nga appointment.';

  @override
  String get apptDetailBannerCancelledByClientTitle =>
      'Gikansela ang appointment';

  @override
  String get apptDetailBannerCancelledByClientSubtitle =>
      'Ikaw ang nagkansela niini nga booking. Naabisuhan na ang abogado.';

  @override
  String get apptDetailBannerConfirmedTitle => 'Gidawat ang appointment';

  @override
  String get apptDetailBannerConfirmedSubtitle =>
      'Gikumpirma na sa abogado kini nga appointment.';

  @override
  String get apptDetailBannerPendingTitle => 'Naghulat og kumpirmasyon';

  @override
  String get apptDetailBannerPendingSubtitle =>
      'Gisusi pa sa abogado ang imong hangyo.';

  @override
  String get apptDetailBannerDeclinedTitle => 'Gibalibaran ang hangyo';

  @override
  String get apptDetailBannerDeclinedSubtitle =>
      'Dili madawat sa abogado kini nga hangyo.';

  @override
  String get apptDetailBannerResolvedTitle => 'Natapos na ang kaso';

  @override
  String get apptDetailBannerResolvedSubtitle =>
      'Gimarkahan sa abogado ang kaso nga sarado na. Makapamessage gihapon ka sulod sa 24 ka oras human kini mare-resolve.';

  @override
  String get apptDetailBannerUnknownTitle => 'Wala mailhan nga status';

  @override
  String apptDetailChatWithLawyer(String lawyerName) {
    return 'Makig-chat kang $lawyerName';
  }

  @override
  String get apptDetailChatLockedCancelledSelf =>
      'Dili available ang chat — imong gikansela kini nga appointment.';

  @override
  String get apptDetailChatLockedCancelledDeclined =>
      'Dili available ang chat — gibalibaran kini nga appointment.';

  @override
  String get apptDetailChatLockedPending =>
      'Ma-unlock ang chat kon madawat na ang appointment.';

  @override
  String get apptDetailChatLockedResolved =>
      'Natapos na ang kaso ug nahuman na ang panahon sa pag-chat. Pangayoa ang abogado nga i-reopen ang kaso kon kinahanglan ka mag-chat pag-usab.';

  @override
  String get apptDetailCancelOptionsFailed =>
      'Dili ma-load ang mga opsyon sa pagkansela. Sulayi pag-usab unya.';

  @override
  String get apptDetailCancelledSuccess => 'Gikansela ang appointment.';

  @override
  String get apptDetailCancelWhyTitle => 'Nganong nagkansela ka?';

  @override
  String get apptDetailCancelWhySubtitle =>
      'Makita sa abogado ang imong pilion nga rason.';

  @override
  String get apptDetailCancelTellMoreHint => 'Pagpasabot gamay…';

  @override
  String get apptDetailCancelErrorPickReason => 'Pagpili og rason.';

  @override
  String get apptDetailCancelErrorOtherDetails =>
      'Palihug pagpasabot nganong nagkansela ka.';

  @override
  String get apptDetailKeepAppointment => 'Padayon ang appointment';

  @override
  String get apptDetailConfirmCancel => 'Kumpirmahi ang pagkansela';

  @override
  String get libSavedEmptyTitle => 'Walay na-save nga chat';

  @override
  String get libSavedEmptySubtitle =>
      'I-bookmark ang mga chat aron sayon\npangitaon unya';

  @override
  String get libSearchNoSaved => 'Walay nakit-an nga saved chat';

  @override
  String get libSearchNoHistory => 'Walay nakit-an nga chat';

  @override
  String get libSearchTryDifferent => 'Suwayi ang laing keyword.';

  @override
  String get commonSubmit => 'Submit';

  @override
  String get legalDocNoticeTitle => 'Opisyal nga teksto';

  @override
  String get legalDocNoticeBody =>
      'Aron legal nga tarong, ang tibuok teksto sa ubos anaa sa English.';

  @override
  String get signupTermsPrivacyRequired =>
      'Kinahanglan nimong mouyon sa Mga Termino sa Paggamit ug Polisiya sa Privacy aron magpadayon.';

  @override
  String get signupAgreementLead => 'Nabasa nako ug mouyon ko sa CLAiR ';

  @override
  String get signupAgreementMiddle => ' ug ';

  @override
  String get signupAgreementTail =>
      '. Nakasabot ko nga ang CLAiR naghatag lamang og legal nga impormasyon ug dili kini legal nga tambag o makahimo og attorney-client relationship.';

  @override
  String get signupTitle => 'Pag-sign up';

  @override
  String get signupCompleteProfileTitle => 'Kumpletuha ang imong profile';

  @override
  String get signupGoogleNameBanner =>
      'Duol na! Idugang lang ang imong pangalan ug mouyon sa among mga termino aron makumpleto ang Google sign-up.';

  @override
  String get signupFirstNameLabel => 'Pangalan';

  @override
  String get signupLastNameLabel => 'Apelyido';

  @override
  String get signupFirstNameRequired => 'Kinahanglan ang pangalan';

  @override
  String get signupLastNameRequired => 'Kinahanglan ang apelyido';

  @override
  String get signupContinueButton => 'Padayon';

  @override
  String get signupCompleteSignUpButton => 'Kumpletuha ang sign up';

  @override
  String get reportScreenTitle => 'Pag-report og isyu';

  @override
  String get reportScreenHeroTitle => 'Pag-report og isyu sa CLAiR';

  @override
  String get reportScreenHeroBody =>
      'Nakakita og bug, sayop nga tubag, o feedback? Gibasa namo ang matag report ug gamiton kini aron tarong ug kapuslanon ang CLAiR.';

  @override
  String get reportScreenAnonymousNote =>
      'Anonymous ang mga report gawas kon naa kay gidungag nga detalye sa deskripsyon.';

  @override
  String get reportIssueCategoryStep => 'Kategorya sa isyu';

  @override
  String get reportDescribeIssueHint =>
      'Hulagway ang isyu nga detalyado. Unsa ang nahitabo, ug unsa ang imong gipaabot?';

  @override
  String get reportPrivacyNoteBody =>
      'Kompederensyal nga gihandel ang mga report. Mahimo kami mag-follow aron i-verify ang isyu ug pagpaayo ang CLAiR.';

  @override
  String get reportSubmitButton => 'Ipasa ang report';

  @override
  String get reportSuccessTitle => 'Naipadala ang report';

  @override
  String get reportSuccessBody =>
      'Salamat sa pagtabang pagpaayo sa CLAiR.\nSusihon sa among team ang imong report pag-ayo.';

  @override
  String get reportBackToSettings => 'Balik sa settings';

  @override
  String get reportReplySheetTitle => 'I-report ang tubag';

  @override
  String get reportReplySheetSubtitle =>
      'Tabangi kami pagpaayo sa legal nga katukoran ug kaluwasan.';

  @override
  String get reportReplyExplainHint =>
      'Unsa ang dili tarong o makalinghaw niini nga tubag? Lakip ang bisan unsang balaod o konsepto kon nagpakauyon.';

  @override
  String get reportReplySubmittedSnackbar =>
      'Salamat — naipadala na ang imong report.';

  @override
  String get lawyerConcernTitle => 'Pag-report og kabalaka';

  @override
  String lawyerConcernAbout(String name) {
    return 'Bahin kang: $name';
  }

  @override
  String get lawyerConcernShareSnackbar =>
      'Na-share ang report pinaagi sa share sheet.';

  @override
  String get reportFieldContentReported => 'Kontento nga gi-report';

  @override
  String get reportFieldChooseQuestionLegal =>
      'Unsa ang labing naglarawan niini nga isyu?';

  @override
  String get reportFieldChooseCategoryLegalIntro =>
      'Pagpili og kategorya nga labing duol sa legal nga kabalaka.';

  @override
  String get reportFieldIssueCategory => 'Kategorya sa isyu';

  @override
  String get reportFieldYourExplanation => 'Imong pasabot';

  @override
  String get reportFieldExplanationBlurb =>
      'Kinahanglan ang mubo nga pasabot aron masabtan sa team ang isyu.';

  @override
  String get reportHintBriefConcern =>
      'Pagpasabot gamay kon unsay sayop o nakapabalaka…';

  @override
  String get reportValidationExplanationShort =>
      'Pagdungag og mubo nga pasabot (bisan usa ka hukmol).';

  @override
  String get reportLawBadLegalLabel => 'Sayop nga legal nga impormasyon';

  @override
  String get reportLawBadLegalDesc =>
      'Adunay sayop nga balaod, kaso, o estatuto ang tubag.';

  @override
  String get reportLawOutdatedLabel => 'Daan nga balaod o regulasyon';

  @override
  String get reportLawOutdatedDesc =>
      'Na-amendar, na-repeal, o napulihan na ang gituki nga balaod.';

  @override
  String get reportLawMisleadingLabel => 'Makapanlimbaw nga pagpasabot';

  @override
  String get reportLawMisleadingDesc =>
      'Likido, kulang, o gikuha sa sayop nga konteksto ang legal nga panghunahuna.';

  @override
  String get reportLawJurisdictionLabel => 'Sayop nga hurisdiksyon';

  @override
  String get reportLawJurisdictionDesc =>
      'Mga balaod gikan sa laing nasud, estado, o rehiyon ang gigamit.';

  @override
  String get reportLawMissingContextLabel => 'Kulang ang legal nga konteksto';

  @override
  String get reportLawMissingContextDesc =>
      'Wala gilakip ang importante nga eksepsyon, kondisyon, o nuances.';

  @override
  String get reportLawHarmfulLabel => 'Potensyal nga makapinsala nga tambag';

  @override
  String get reportLawHarmfulDesc =>
      'Mahimong makadaot ug legal nga kapilde kon sundon kini nga tambag.';

  @override
  String get reportLawUnclearLabel => 'Dimaalam o makalibog nga tubag';

  @override
  String get reportLawUnclearDesc =>
      'Hapsay kaayo o lisod gamiton ang tubag sa legal nga konteksto.';

  @override
  String get reportLawOtherLabel => 'Laing legal nga kabalaka';

  @override
  String get reportLawOtherDesc =>
      'Kabalaka nga wala gihulagway sa mga kategorya sa ibabaw.';

  @override
  String get reportAppBugLabel => 'Bug sa app';

  @override
  String get reportAppBugDesc => 'Adunay buak o sayop nga pamatasan sa app.';

  @override
  String get reportAppWrongAiLabel => 'Sayop nga tubag sa AI';

  @override
  String get reportAppWrongAiDesc =>
      'Nihatag ang CLAiR og dili sakto, dili may kalabutan, o makapinsala nga tubag.';

  @override
  String get reportAppMisleadingLabel => 'Makapanlimbaw nga sulod';

  @override
  String get reportAppMisleadingDesc =>
      'Malimbungon ang impormasyon o gipakita nga walay husto nga konteksto.';

  @override
  String get reportAppPrivacyLabel => 'Kabalaka sa privacy o seguridad';

  @override
  String get reportAppPrivacyDesc =>
      'Isyu kon giunsa pagdumala o pagtipig ang imong data.';

  @override
  String get reportAppFeatureLabel => 'Feedback sa feature';

  @override
  String get reportAppFeatureDesc =>
      'Suhestyon alang sa bag-ong feature o pagpaayo sa app.';

  @override
  String get reportAppOtherLabel => 'Uban pa';

  @override
  String get reportAppOtherDesc =>
      'Isyu nga wala sakop sa mga kategorya sa ibabaw.';

  @override
  String get helpHeroTitle => 'Unsa among matabangan nimo?';

  @override
  String get helpHeroSubtitle =>
      'Tan-awa ang sagad mga pangutana o pangitaa sa ubos.';

  @override
  String get helpSearchHint => 'Pangitaa ang mga FAQ…';

  @override
  String helpEmptyNoResults(String query) {
    return 'Walay resulta alang sa \"$query\"';
  }

  @override
  String get helpEmptySuggest =>
      'Suwayi ang laing keyword o tan-awa ang mga seksyon sa ibabaw.';

  @override
  String get helpSecUsing => 'Paggamit sa CLAiR';

  @override
  String get helpSecLawyers => 'Mga Abogado ug Appointment';

  @override
  String get helpSecPrivacy => 'Privacy ug Seguridad';

  @override
  String get helpSecAccount => 'Account ug Settings';

  @override
  String get helpSecReporting => 'Pag-report ug Feedback';

  @override
  String get helpFaqEnglishNotice =>
      'Ang mga detalyadong tubag sa FAQ sa ubos anaa sa English aron legal nga tarong.';

  @override
  String get tutorialSkip => 'Laktawi';

  @override
  String get tutorialNext => 'Sunod';

  @override
  String get tutorialBack => 'Balik';

  @override
  String get tutorialDone => 'Sugdi Na';

  @override
  String tutorialStepOf(Object current, Object total) {
    return '$current sa $total';
  }

  @override
  String get tutorialWelcomeTitle => 'Welcome sa CLAiR';

  @override
  String get tutorialWelcomeBody =>
      'Ang imong AI-powered nga legal assistant. Giyahan ka namo sa mga nag-unang feature.';

  @override
  String get tutorialChatTitle => 'Makig-chat sa AI';

  @override
  String get tutorialChatBody =>
      'Pangutan-a si CLAiR bisan unsang legal nga pangutana. Makakuha og dayon nga giya base sa balaod sa Pilipinas.';

  @override
  String get tutorialLawyersTitle => 'Pangitag Abogado';

  @override
  String get tutorialLawyersBody =>
      'Pag-browse sa mga verified nga abogado duol nimo, tan-awa ang ilang profile, ug mag-book og konsultasyon.';

  @override
  String get tutorialLibraryTitle => 'Chat Library';

  @override
  String get tutorialLibraryBody =>
      'Tanan nimong mga nangaging panagsultihanay na-save dinhi. I-pin, pangitaa, o i-download isip PDF.';

  @override
  String get tutorialAppointmentsTitle => 'Mga Appointment';

  @override
  String get tutorialAppointmentsBody =>
      'I-track ang imong mga naka-book nga konsultasyon, makig-chat sa imong abogado, ug dumala sa imong iskedyul.';
}
