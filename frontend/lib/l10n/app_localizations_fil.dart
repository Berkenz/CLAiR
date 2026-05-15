// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Filipino Pilipino (`fil`).
class AppLocalizationsFil extends AppLocalizations {
  AppLocalizationsFil([String locale = 'fil']) : super(locale);

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
  String get drawerFindLawyer => 'Maghanap ng abogado';

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
  String get appLanguage => 'Wika ng app';

  @override
  String get sectionAbout => 'About';

  @override
  String get report => 'Mag-report';

  @override
  String get helpCenter => 'Sentro ng Tulong';

  @override
  String get termsOfUse => 'Mga Tuntunin sa Paggamit';

  @override
  String get privacyPolicy => 'Patakaran sa Privacy';

  @override
  String get resetAllToDefault => 'Ibalik sa default';

  @override
  String get logOut => 'Mag-log out';

  @override
  String get exitGuestSession => 'Lumabas sa Guest Session';

  @override
  String get deleteAccount => 'Burahin ang account';

  @override
  String get settingsResetDialogTitle => 'I-reset ang lahat ng setting?';

  @override
  String get settingsResetDialogBody =>
      'Ang tema, accent, at laki ng font ay babalik sa default.';

  @override
  String get settingsResetSnackbar => 'Naibalik na ang mga setting sa default.';

  @override
  String get commonCancel => 'Kanselahin';

  @override
  String get commonConfirm => 'Kumpirmahin';

  @override
  String get languageScreenTitle => 'Wika ng app';

  @override
  String get languageScreenSubtitle =>
      'Pumili ng wika para sa mga menu at label sa CLAiR.';

  @override
  String get languageEnglish => 'Ingles';

  @override
  String get languageFilipino => 'Filipino';

  @override
  String get languageCebuano => 'Bisaya';

  @override
  String get languageUpdatedSnackbar => 'Na-update ang wika.';

  @override
  String get lawyerMap => 'Mapa';

  @override
  String get lawyerList => 'Listahan';

  @override
  String get lawyerSearchHint => 'Maghanap ayon sa pangalan o espesyalidad…';

  @override
  String get lawyerBrowseByPracticeArea => 'Mag-browse ayon sa practice area';

  @override
  String lawyerClearWithCount(int count) {
    return 'Alisin ($count)';
  }

  @override
  String get lawyerAllRegistered => 'Lahat ng rehistradong abogado';

  @override
  String lawyerResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count na resulta',
      one: '1 resulta',
    );
    return '$_temp0';
  }

  @override
  String get lawyerClearAll => 'Alisin lahat';

  @override
  String get lawyerLoadErrorTitle => 'Hindi ma-load ang mga abogado.';

  @override
  String get lawyerUnknownError => 'Hindi alam na error.';

  @override
  String get lawyerRetry => 'Subukan muli';

  @override
  String get lawyerEmptyState => 'Walang rehistradong abogado pa.';

  @override
  String get lawyerNoMatches => 'Walang abogadong tumutugma sa iyong filter.';

  @override
  String get lawyerClearFilters => 'I-clear ang mga filter';

  @override
  String get lawyerVerified => 'Beripikado';

  @override
  String get lawyerViewProfile => 'Tingnan ang profile';

  @override
  String lawyerExtraAreas(int count) {
    return '+$count';
  }

  @override
  String get lawyerSharingTitle => 'Ibinabahagi ang usapan sa abogado';

  @override
  String lawyerSharingSubtitle(String title) {
    return '\"$title\" — i-tap ang abogado sa ibaba para mag-book nang may naka-attach na';
  }

  @override
  String get lawyerChipCriminal => 'Kriminal';

  @override
  String get lawyerChipFamily => 'Pamilya';

  @override
  String get lawyerChipCorporate => 'Korporasyon';

  @override
  String get lawyerChipProperty => 'Ari-arian';

  @override
  String get lawyerChipFinance => 'Pananalapi';

  @override
  String get lawyerChipLabor => 'Labor';

  @override
  String get lawyerChipCivil => 'Sibil';

  @override
  String get lawyerChipImmigration => 'Imigrasyon';

  @override
  String get lawyerChipContracts => 'Kontrata';

  @override
  String get lawyerChipWills => 'Hudyat';

  @override
  String get lawyerChipAdministrative => 'Administratibo';

  @override
  String get lawyerChipEnvironmental => 'Kapaligiran';

  @override
  String get lawyerPracticeAdministrativeLaw => 'Administratibong batas';

  @override
  String get lawyerPracticeBankingFinanceLaw => 'Batas sa bangko at pananalapi';

  @override
  String get lawyerPracticeCivilLaw => 'Sibil na batas';

  @override
  String get lawyerPracticeConstitutionalLaw => 'Konstitusyonal na batas';

  @override
  String get lawyerPracticeCorporateLaw => 'Batas ng korporasyon';

  @override
  String get lawyerPracticeCriminalLaw => 'Kriminal na batas';

  @override
  String get lawyerPracticeEnvironmentalLaw => 'Batas sa kapaligiran';

  @override
  String get lawyerPracticeFamilyLaw => 'Batas pampamilya';

  @override
  String get lawyerPracticeImmigrationLaw => 'Batas sa imigrasyon';

  @override
  String get lawyerPracticeInsuranceLaw => 'Batas sa seguro';

  @override
  String get lawyerPracticeIntellectualPropertyLaw =>
      'Batas sa intellectual property';

  @override
  String get lawyerPracticeLaborLaw => 'Batas sa paggawa';

  @override
  String get lawyerPracticeRealEstateLaw => 'Batas sa real estate';

  @override
  String get lawyerPracticeTaxLaw => 'Batas sa buwis';

  @override
  String get lawyerPracticeContractLaw => 'Batas sa kontrata';

  @override
  String get lawyerPracticeEstateWills => 'Mana at hudyat';

  @override
  String get lawyerPracticeOther => 'Iba pa';

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
  String get lawyerDesigOther => 'Iba pa';

  @override
  String get brandAppName => 'CLAiR';

  @override
  String get homeHelloGuest => 'Kumusta';

  @override
  String homeHelloName(String name) {
    return 'Kumusta, $name';
  }

  @override
  String get homeTagline => 'Paano ka matutulungan ng CLAiR ngayon?';

  @override
  String get homeStartNewChatTitle => 'Magsimula ng bagong chat';

  @override
  String get homeStartNewChatSubtitle =>
      'Magtanong ng legal na katanungan sa CLAiR';

  @override
  String get homeQuickActions => 'Mabilis na aksyon';

  @override
  String get homeSuggestedLawyers => 'Mga iminumungkahing abogado';

  @override
  String get homeSeeAll => 'Tingnan lahat';

  @override
  String get homeGeneratedDocuments => 'Mga dokumentong ginawa';

  @override
  String get homeViewAll => 'Tingnan lahat';

  @override
  String get homeConnect => 'Kumonekta';

  @override
  String homeRatingCasesLine(String rating, int count) {
    return '$rating · $count na kaso';
  }

  @override
  String get authWelcomeBack => 'Maligayang\npagbabalik';

  @override
  String get authPassword => 'Password';

  @override
  String get authLogIn => 'Mag-log in';

  @override
  String get authForgotPassword => 'Nakalimutan ang password?';

  @override
  String get authNoAccountPrompt => 'Walang account? ';

  @override
  String get authSignUpLink => 'Mag-sign up';

  @override
  String get authGuest => 'Guest';

  @override
  String get authGoogle => 'Google';

  @override
  String get chatConversationsTitle => 'Mga usapan';

  @override
  String get chatNewChatButton => 'Bagong chat';

  @override
  String get chatNoConversationsYet => 'Walang usapan pa';

  @override
  String get chatMenuSaveChat => 'I-save ang chat';

  @override
  String get chatMenuUnsaveChat => 'Alisin sa save ang chat';

  @override
  String get chatMenuShare => 'I-share';

  @override
  String get chatMenuDownloadPdf => 'I-download bilang PDF';

  @override
  String get chatMenuReport => 'I-report';

  @override
  String get chatMenuShareToLawyer => 'I-share sa abogado';

  @override
  String get chatMenuDelete => 'Burahin ang chat';

  @override
  String get chatPdfGeneratingSummary => 'Gumagawa ng PDF summary...';

  @override
  String chatPdfSaveFailed(String error) {
    return 'Hindi na-save ang PDF: $error';
  }

  @override
  String get chatDisclaimerDismiss => 'Isara';

  @override
  String get chatTermsDisclaimerBody =>
      'Sa pag-chat sa CLAiR, isang AI chatbot, sumasang-ayon ka sa aming';

  @override
  String get chatTermsDisclaimerTerms => 'Mga Tuntunin ng Paggamit';

  @override
  String get chatTermsDisclaimerAnd => 'at';

  @override
  String get chatTermsDisclaimerPrivacy => 'Patakaran sa Privacy';

  @override
  String get chatTermsDisclaimerPeriod => '.';

  @override
  String get chatTitleNewChat => 'Bagong chat';

  @override
  String get chatTitleCurrentConversation => 'Kasalukuyang usapan';

  @override
  String get chatRagDisconnectedBanner =>
      'Hindi nakakonekta ang law library (RAG) sa server — maaaring gumamit ng pangkalahatang kaalaman ang sagot.';

  @override
  String get chatNoLawExcerpts =>
      'Walang law excerpt na umabot sa relevance threshold para sa tanong na ito.';

  @override
  String get chatRetrievedForAnswer => 'Kinuha para sa sagot na ito';

  @override
  String get chatSourceLabel => 'Pinagmulan';

  @override
  String get chatEmptyExploreTopic =>
      'Magsimula ng bagong usapan para tumuklas ng ibang paksa.';

  @override
  String get chatCopiedClipboard => 'Nakopya sa clipboard';

  @override
  String get chatEditMessageTitle => 'I-edit ang mensahe';

  @override
  String get chatEditMessageHint => 'I-edit ang iyong mensahe';

  @override
  String get chatComposerHint => 'Magtanong ng kahit ano';

  @override
  String get chatAssistantGreeting =>
      'Kumusta! Ako si CLAiR, paano kita matutulungan ngayon?';

  @override
  String get chatLawyersNearYou => 'Mga abogado malapit sa iyo';

  @override
  String chatMatchPercent(String head, String pct) {
    return '$head · $pct% tugma';
  }

  @override
  String get notifMarkAllRead => 'Markahan lahat na basa na';

  @override
  String get notifEmpty => 'Walang notification pa';

  @override
  String get notifBannerDismissTooltip => 'Isara';

  @override
  String get notifClearAll => 'I-clear lahat';

  @override
  String get notifClearAllConfirmTitle => 'I-clear ang lahat ng notification?';

  @override
  String get notifClearAllConfirmBody =>
      'Permanenteng tatanggalin ang lahat ng notification. Hindi na ito maa-undo.';

  @override
  String get notifDeleteTooltip => 'Tanggalin';

  @override
  String get notifDeleteConfirmTitle => 'Tanggalin ang notification na ito?';

  @override
  String get notifDeleteConfirmBody => 'Hindi na ito maa-undo.';

  @override
  String get libScreenTitle => 'Library';

  @override
  String get libTabHistory => 'History';

  @override
  String get libTabSaved => 'Saved';

  @override
  String get libSearchChatsHint => 'Maghanap ng chat...';

  @override
  String get libPreviewEmpty => 'Magsimula ng bagong mensahe';

  @override
  String get libPreviewYou => 'Ikaw';

  @override
  String libPreviewRecent(String text) {
    return 'Kamakailan: $text';
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
  String get appearanceFontSize => 'Laki ng font';

  @override
  String get appearanceSavedSnackbar => 'Na-save ang hitsura';

  @override
  String get appearanceSaveButton => 'I-save ang hitsura';

  @override
  String get appearanceFontSmall => 'Maliit';

  @override
  String get appearanceFontDefault => 'Default';

  @override
  String get appearanceFontLarge => 'Malaki';

  @override
  String get appearanceFontExtraLarge => 'Sobrang laki';

  @override
  String get histTapToOpen => 'I-tap para buksan ang usapan';

  @override
  String get histRenameDialogTitle => 'Palitan ang pangalan ng usapan';

  @override
  String get histRenameHint => 'Ilagay ang bagong pamagat';

  @override
  String get histRenameButton => 'Palitan ang pangalan';

  @override
  String get histDeleteTitle => 'Burahin ang usapan?';

  @override
  String get histDeleteBody =>
      'Permanenteng mabubura ang usapan na ito at lahat ng mensahe.';

  @override
  String get histGeneratingPdf => 'Gumagawa ng PDF...';

  @override
  String histDownloadFailed(String error) {
    return 'Hindi na-download: $error';
  }

  @override
  String get histEmptyTitle => 'Walang usapan pa';

  @override
  String get histEmptySubtitle =>
      'Magsimula ng chat at lalabas dito ang iyong mga usapan';

  @override
  String get convSave => 'I-save';

  @override
  String get convUnsave => 'Alisin sa save';

  @override
  String get convRename => 'Palitan ang pangalan';

  @override
  String get convShareToLawyer => 'I-share sa abogado';

  @override
  String get convDownload => 'I-download';

  @override
  String get convDelete => 'Burahin';

  @override
  String get commonSave => 'I-save';

  @override
  String get commonDelete => 'Burahin';

  @override
  String get apptNotFoundSnackbar =>
      'Hindi mahanap ang appointment na iyon sa iyong listahan.';

  @override
  String get apptMyTitle => 'Mga appointment ko';

  @override
  String apptTotalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count na appointment sa kabuuan',
      one: '1 appointment sa kabuuan',
    );
    return '$_temp0';
  }

  @override
  String get apptFilterAll => 'Lahat';

  @override
  String get apptFilterPending => 'Pending';

  @override
  String get apptFilterAccepted => 'Accepted';

  @override
  String get apptFilterResolved => 'Resolved';

  @override
  String get apptFilterCancelled => 'Cancelled';

  @override
  String get apptSortNewestFirst => 'Nakabook · Pinakabago muna';

  @override
  String get apptSortOldestFirst => 'Nakabook · Pinakaluma muna';

  @override
  String get apptSortChipNewest => 'Ayos: pinakabago muna';

  @override
  String get apptSortChipOldest => 'Ayos: pinakaluma muna';

  @override
  String get apptNoFilterMatch =>
      'Walang appointment na tumutugma sa filter na ito';

  @override
  String get apptShowAll => 'Ipakita lahat';

  @override
  String get apptSectionCancelledOrDeclined => 'Kinansela o tinanggihan';

  @override
  String get apptSectionActivePending => 'Aktibo at pending';

  @override
  String get apptSectionPastCancelled => 'Nakaraan / kinansela o tinanggihan';

  @override
  String get apptEmptyTitle => 'Walang appointment pa';

  @override
  String get apptEmptySubtitle =>
      'Mag-book ng konsultasyon sa abogado at\nsubaybayan ang status dito';

  @override
  String get apptCardChat => 'Chat';

  @override
  String apptCardBookedAt(String date, String time) {
    return 'Nakabook $date · $time';
  }

  @override
  String get bookingAppointmentTypeLabel => 'Uri ng appointment';

  @override
  String get bookingAppointmentTypeHint => 'Anong uri ng konsultasyon?';

  @override
  String get bookingAppointmentTypeLoadError =>
      'Hindi ma-load ang mga uri. I-tap para subukan muli.';

  @override
  String get bookingAppointmentTypeRequired => 'Pumili ng uri ng appointment.';

  @override
  String get apptBadgeNew => 'BAGO';

  @override
  String get apptStatusPending => 'Pending';

  @override
  String get apptStatusAccepted => 'Accepted';

  @override
  String get apptStatusCancelled => 'Cancelled';

  @override
  String get apptStatusDeclined => 'Tinanggihan';

  @override
  String get apptDetailLabelType => 'Uri';

  @override
  String get apptDetailLabelLawyer => 'Abogado';

  @override
  String get apptDetailSectionDescription => 'Deskripsyon';

  @override
  String get apptDetailReasonCancellation => 'Pagkansela';

  @override
  String get apptDetailReasonDecline => 'Dahilan ng pagtanggi';

  @override
  String get apptDetailLabelBooked => 'Na-book';

  @override
  String get apptDetailLabelUpdated => 'Na-update';

  @override
  String get apptDetailCancelAppointment => 'Kanselahin ang appointment';

  @override
  String get apptDetailAttachedConversationTitle => 'Naka-attach na CLAiR chat';

  @override
  String get apptDetailAttachedConversationSubtitle =>
      'Buksan ang chat na ini-share mo noong nag-book ka ng appointment na ito.';

  @override
  String get apptDetailBannerCancelledByClientTitle =>
      'Kinansela ang appointment';

  @override
  String get apptDetailBannerCancelledByClientSubtitle =>
      'Ikaw ang nagkansela ng booking na ito. Naabisuhan na ang abogado.';

  @override
  String get apptDetailBannerConfirmedTitle => 'Tinanggap ang appointment';

  @override
  String get apptDetailBannerConfirmedSubtitle =>
      'Kumpirmado na ng abogado ang appointment na ito.';

  @override
  String get apptDetailBannerPendingTitle => 'Naghihintay ng kumpirmasyon';

  @override
  String get apptDetailBannerPendingSubtitle =>
      'Ipinapasusuri pa ng abogado ang iyong request.';

  @override
  String get apptDetailBannerDeclinedTitle => 'Tinanggihan ang request';

  @override
  String get apptDetailBannerDeclinedSubtitle =>
      'Hindi tinanggap ng abogado ang request na ito.';

  @override
  String get apptDetailBannerResolvedTitle => 'Natapos na ang kaso';

  @override
  String get apptDetailBannerResolvedSubtitle =>
      'Minarkahan ng abogado ang kasong ito bilang sarado. Maaari ka pa ring mag-message sa kanila sa loob ng 24 oras matapos itong mare-resolve.';

  @override
  String get apptDetailBannerUnknownTitle => 'Di-alam na status';

  @override
  String apptDetailChatWithLawyer(String lawyerName) {
    return 'Makipag-chat kay $lawyerName';
  }

  @override
  String get apptDetailChatLockedCancelledSelf =>
      'Hindi available ang chat — kinansela mo ang appointment na ito.';

  @override
  String get apptDetailChatLockedCancelledDeclined =>
      'Hindi available ang chat — tinanggihan ang appointment na ito.';

  @override
  String get apptDetailChatLockedPending =>
      'Mag-uunlock ang chat kapag tinanggap na ang appointment.';

  @override
  String get apptDetailChatLockedResolved =>
      'Natapos na ang kaso at tapos na ang panahon ng pagmemensahe. Hilingin sa abogado na buksan muli ang kaso kung kailangan mong mag-chat.';

  @override
  String get apptDetailCancelOptionsFailed =>
      'Hindi ma-load ang mga opsyon sa pagkansela. Subukan muli mamaya.';

  @override
  String get apptDetailCancelledSuccess => 'Kinansela ang appointment.';

  @override
  String get apptDetailCancelWhyTitle => 'Bakit ka nagkakansela?';

  @override
  String get apptDetailCancelWhySubtitle =>
      'Makikita ng abogado ang dahilan na pipiliin mo.';

  @override
  String get apptDetailCancelTellMoreHint => 'Sabihan pa kami nang konti…';

  @override
  String get apptDetailCancelErrorPickReason => 'Pumili ng dahilan.';

  @override
  String get apptDetailCancelErrorOtherDetails =>
      'Maikling ipaliwanag kung bakit ka nagkakansela.';

  @override
  String get apptDetailKeepAppointment => 'Ituloy ang appointment';

  @override
  String get apptDetailConfirmCancel => 'Kumpirmahin ang pagkansela';

  @override
  String get libSavedEmptyTitle => 'Walang naka-save na chat';

  @override
  String get libSavedEmptySubtitle =>
      'I-bookmark ang mga chat para madaling\nhanapin mamaya';

  @override
  String get libSearchNoSaved => 'Walang nahanap na saved chat';

  @override
  String get libSearchNoHistory => 'Walang nahanap na chat';

  @override
  String get libSearchTryDifferent => 'Subukan ang ibang keyword.';

  @override
  String get commonSubmit => 'Submit';

  @override
  String get legalDocNoticeTitle => 'Opisyal na teksto';

  @override
  String get legalDocNoticeBody =>
      'Para sa legal na katumpakan, ang buong teksto sa ibaba ay sa Ingles.';

  @override
  String get signupTermsPrivacyRequired =>
      'Kailangan mong sumang-ayon sa Mga Tuntunin sa Paggamit at Patakaran sa Privacy upang magpatuloy.';

  @override
  String get signupAgreementLead => 'Nabasa ko at sumasang-ayon ako sa CLAiR ';

  @override
  String get signupAgreementMiddle => ' at ';

  @override
  String get signupAgreementTail =>
      '. Naiintindihan ko na nagbibigay ang CLAiR ng legal na impormasyon lamang at hindi ito legal na payo o lumilikha ng relasyon na attorney-client.';

  @override
  String get signupTitle => 'Mag-sign up';

  @override
  String get signupCompleteProfileTitle => 'Kumpletuhin ang iyong profile';

  @override
  String get signupGoogleNameBanner =>
      'Malapit na! Idagdag lamang ang iyong pangalan at sumang-ayon sa aming mga tuntunin upang makumpleto ang Google sign-up.';

  @override
  String get signupFirstNameLabel => 'Pangalan';

  @override
  String get signupLastNameLabel => 'Apelyido';

  @override
  String get signupFirstNameRequired => 'Kailangan ang pangalan';

  @override
  String get signupLastNameRequired => 'Kailangan ang apelyido';

  @override
  String get signupContinueButton => 'Magpatuloy';

  @override
  String get signupCompleteSignUpButton => 'Kumpletuhin ang sign up';

  @override
  String get reportScreenTitle => 'Mag-report ng isyu';

  @override
  String get reportScreenHeroTitle => 'Mag-report ng isyu sa CLAiR';

  @override
  String get reportScreenHeroBody =>
      'May nakitang bug, maling sagot, o feedback? Binabasa namin ang bawat report at ginagamit ito para panatilihing tama at kapaki-pakinabang ang CLAiR.';

  @override
  String get reportScreenAnonymousNote =>
      'Anonymous ang mga report maliban kung may idinagdag kang detalye sa paglalarawan.';

  @override
  String get reportIssueCategoryStep => 'Kategorya ng isyu';

  @override
  String get reportDescribeIssueHint =>
      'Ilahad ang isyu nang detalyado. Ano ang nangyari, at ano ang inaasahan mo?';

  @override
  String get reportPrivacyNoteBody =>
      'Kumpidensyal na tinatrato ang mga report. Maaari kaming mag-follow up upang i-verify ang isyu at pagbutihin ang CLAiR.';

  @override
  String get reportSubmitButton => 'Ipasa ang report';

  @override
  String get reportSuccessTitle => 'Naipadala ang report';

  @override
  String get reportSuccessBody =>
      'Salamat sa pagtulong na pagbutihin ang CLAiR.\nSusuriin ng aming koponan ang iyong report nang maingat.';

  @override
  String get reportBackToSettings => 'Bumalik sa settings';

  @override
  String get reportReplySheetTitle => 'I-report ang sagot';

  @override
  String get reportReplySheetSubtitle =>
      'Tulungan kaming pagbutihin ang legal na katumpakan at kaligtasan.';

  @override
  String get reportReplyExplainHint =>
      'Ano ang hindi tama o nakakalinlang sa sagot na ito? Isama ang anumang batas o konsepto kung mayroon.';

  @override
  String get reportReplySubmittedSnackbar =>
      'Salamat — naipadala ang iyong report.';

  @override
  String get lawyerConcernTitle => 'Mag-report ng alalahanin';

  @override
  String lawyerConcernAbout(String name) {
    return 'Tungkol kay: $name';
  }

  @override
  String get lawyerConcernShareSnackbar =>
      'Naibahagi ang report sa pamamagitan ng share sheet.';

  @override
  String get reportFieldContentReported => 'Nilalaman na ini-report';

  @override
  String get reportFieldChooseQuestionLegal =>
      'Ano ang pinakamahusay na naglalarawan sa isyung ito?';

  @override
  String get reportFieldChooseCategoryLegalIntro =>
      'Piliin ang kategoryang pinakamalapit sa legal na alalahanin.';

  @override
  String get reportFieldIssueCategory => 'Kategorya ng isyu';

  @override
  String get reportFieldYourExplanation => 'Iyong paliwanag';

  @override
  String get reportFieldExplanationBlurb =>
      'Kailangan ang maikling paliwanag upang maunawaan ng koponan ang isyu.';

  @override
  String get reportHintBriefConcern =>
      'Maikling ipaliwanag kung ano ang mali o nakakaalarmang…';

  @override
  String get reportValidationExplanationShort =>
      'Magdagdag ng maikling paliwanag (kahit isang pangungusap).';

  @override
  String get reportLawBadLegalLabel => 'Maling legal na impormasyon';

  @override
  String get reportLawBadLegalDesc =>
      'May maling batas, kaso, o batas na nakasaad ang sagot.';

  @override
  String get reportLawOutdatedLabel => 'Lumang batas o regulasyon';

  @override
  String get reportLawOutdatedDesc =>
      'Naamyendahan, na-repeal, o napalitan na ang binanggit na batas.';

  @override
  String get reportLawMisleadingLabel => 'Nakakalinlang na interpretasyon';

  @override
  String get reportLawMisleadingDesc =>
      'Baluktot, hindi kumpleto, o kinuha sa maling konteksto ang legal na pangangatwiran.';

  @override
  String get reportLawJurisdictionLabel => 'Maling hurisdiksyon';

  @override
  String get reportLawJurisdictionDesc =>
      'Inilapat ang mga batas mula sa ibang bansa, estado, o rehiyon.';

  @override
  String get reportLawMissingContextLabel => 'Kulang ang legal na konteksto';

  @override
  String get reportLawMissingContextDesc =>
      'Hindi isinama ang mahahalagang eksepsyon, kondisyon, o nuances.';

  @override
  String get reportLawHarmfulLabel => 'Potensyal na nakakapinsalang payo';

  @override
  String get reportLawHarmfulDesc =>
      'Maaaring magdulot ng legal na pinsala o panganib ang pagsunod sa payong ito.';

  @override
  String get reportLawUnclearLabel => 'Malabo o nakakalitong sagot';

  @override
  String get reportLawUnclearDesc =>
      'Masyadong vague o mahirap mailapat ang sagot sa legal na konteksto.';

  @override
  String get reportLawOtherLabel => 'Ibang legal na alalahanin';

  @override
  String get reportLawOtherDesc =>
      'Alalahaning hindi nailalarawan sa mga kategorya sa itaas.';

  @override
  String get reportAppBugLabel => 'Bug sa app';

  @override
  String get reportAppBugDesc => 'May nasira o maling pag-uugali sa app.';

  @override
  String get reportAppWrongAiLabel => 'Maling sagot ng AI';

  @override
  String get reportAppWrongAiDesc =>
      'Nagbigay ang CLAiR ng hindi tumpak, hindi nauugnay, o nakakapinsalang sagot.';

  @override
  String get reportAppMisleadingLabel => 'Nakakalinlang na nilalaman';

  @override
  String get reportAppMisleadingDesc =>
      'Mapanlinlang ang impormasyon o iniharap nang walang tamang konteksto.';

  @override
  String get reportAppPrivacyLabel => 'Alalahanin sa privacy o seguridad';

  @override
  String get reportAppPrivacyDesc =>
      'Isyu kung paano hinahawakan o iniimbak ang iyong data.';

  @override
  String get reportAppFeatureLabel => 'Feedback sa feature';

  @override
  String get reportAppFeatureDesc =>
      'Mungkahi para sa bagong feature o pagpapabuti ng app.';

  @override
  String get reportAppOtherLabel => 'Iba pa';

  @override
  String get reportAppOtherDesc =>
      'Isyung hindi sakop ng mga kategorya sa itaas.';

  @override
  String get helpHeroTitle => 'Paano ka namin matutulungan?';

  @override
  String get helpHeroSubtitle =>
      'Tingnan ang mga karaniwang tanong o maghanap sa ibaba.';

  @override
  String get helpSearchHint => 'Maghanap sa FAQ…';

  @override
  String helpEmptyNoResults(String query) {
    return 'Walang resulta para sa \"$query\"';
  }

  @override
  String get helpEmptySuggest =>
      'Subukan ang ibang keyword o tingnan ang mga seksyon sa itaas.';

  @override
  String get helpSecUsing => 'Paggamit ng CLAiR';

  @override
  String get helpSecLawyers => 'Mga Abogado & Appointment';

  @override
  String get helpSecPrivacy => 'Privacy & Seguridad';

  @override
  String get helpSecAccount => 'Account & Settings';

  @override
  String get helpSecReporting => 'Pag-report & Feedback';

  @override
  String get helpFaqEnglishNotice =>
      'Ang mga detalyadong sagot sa FAQ sa ibaba ay sa Ingles para sa legal na katumpakan.';

  @override
  String get tutorialSkip => 'Laktawan';

  @override
  String get tutorialNext => 'Susunod';

  @override
  String get tutorialBack => 'Bumalik';

  @override
  String get tutorialDone => 'Simulan Na';

  @override
  String tutorialStepOf(Object current, Object total) {
    return '$current ng $total';
  }

  @override
  String get tutorialWelcomeTitle => 'Maligayang pagdating sa CLAiR';

  @override
  String get tutorialWelcomeBody =>
      'Ang iyong AI-powered na legal assistant. Gabayan ka namin sa mga pangunahing feature.';

  @override
  String get tutorialChatTitle => 'Makipag-chat sa AI';

  @override
  String get tutorialChatBody =>
      'Magtanong kay CLAiR ng kahit anong legal na katanungan. Makakuha ng agarang gabay batay sa batas ng Pilipinas.';

  @override
  String get tutorialLawyersTitle => 'Maghanap ng Abogado';

  @override
  String get tutorialLawyersBody =>
      'Mag-browse ng mga verified na abogado malapit sa iyo, tingnan ang kanilang profile, at mag-book ng konsultasyon.';

  @override
  String get tutorialLibraryTitle => 'Chat Library';

  @override
  String get tutorialLibraryBody =>
      'Lahat ng iyong mga nakaraang usapan ay naka-save dito. I-pin, maghanap, o i-download bilang PDF.';

  @override
  String get tutorialAppointmentsTitle => 'Mga Appointment';

  @override
  String get tutorialAppointmentsBody =>
      'I-track ang mga naka-book na konsultasyon, makipag-chat sa iyong abogado, at pamahalaan ang iyong iskedyul.';
}
