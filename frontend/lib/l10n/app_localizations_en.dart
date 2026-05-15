// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
  String get drawerFindLawyer => 'Find a Lawyer';

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
  String get appLanguage => 'App Language';

  @override
  String get sectionAbout => 'About';

  @override
  String get report => 'Report';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get resetAllToDefault => 'Reset All to Default';

  @override
  String get logOut => 'Log Out';

  @override
  String get exitGuestSession => 'Exit Guest Session';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get settingsResetDialogTitle => 'Reset all settings?';

  @override
  String get settingsResetDialogBody =>
      'Appearance options (theme, accent, and font size) will return to their defaults.';

  @override
  String get settingsResetSnackbar => 'Settings reset to default.';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get languageScreenTitle => 'App language';

  @override
  String get languageScreenSubtitle =>
      'Choose a language for menus and labels in CLAiR.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFilipino => 'Filipino';

  @override
  String get languageCebuano => 'Cebuano';

  @override
  String get languageUpdatedSnackbar => 'Language updated.';

  @override
  String get lawyerMap => 'Map';

  @override
  String get lawyerList => 'List';

  @override
  String get lawyerSearchHint => 'Search by name or specialty…';

  @override
  String get lawyerBrowseByPracticeArea => 'Browse by practice area';

  @override
  String lawyerClearWithCount(int count) {
    return 'Clear ($count)';
  }

  @override
  String get lawyerAllRegistered => 'All registered lawyers';

  @override
  String lawyerResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String get lawyerClearAll => 'Clear all';

  @override
  String get lawyerLoadErrorTitle => 'Couldn\'t load lawyers.';

  @override
  String get lawyerUnknownError => 'Unknown error.';

  @override
  String get lawyerRetry => 'Retry';

  @override
  String get lawyerEmptyState => 'No registered lawyers yet.';

  @override
  String get lawyerNoMatches => 'No lawyers match your filters.';

  @override
  String get lawyerClearFilters => 'Clear filters';

  @override
  String get lawyerVerified => 'Verified';

  @override
  String get lawyerViewProfile => 'View profile';

  @override
  String lawyerExtraAreas(int count) {
    return '+$count';
  }

  @override
  String get lawyerSharingTitle => 'Sharing conversation with a lawyer';

  @override
  String lawyerSharingSubtitle(String title) {
    return '\"$title\" — tap any lawyer below to book with this pre-attached';
  }

  @override
  String get lawyerChipCriminal => 'Criminal';

  @override
  String get lawyerChipFamily => 'Family';

  @override
  String get lawyerChipCorporate => 'Corporate';

  @override
  String get lawyerChipProperty => 'Property';

  @override
  String get lawyerChipFinance => 'Finance';

  @override
  String get lawyerChipLabor => 'Labor';

  @override
  String get lawyerChipCivil => 'Civil';

  @override
  String get lawyerChipImmigration => 'Immigration';

  @override
  String get lawyerChipContracts => 'Contracts';

  @override
  String get lawyerChipWills => 'Wills';

  @override
  String get lawyerChipAdministrative => 'Administrative';

  @override
  String get lawyerChipEnvironmental => 'Environmental';

  @override
  String get lawyerPracticeAdministrativeLaw => 'Administrative Law';

  @override
  String get lawyerPracticeBankingFinanceLaw => 'Banking & Finance Law';

  @override
  String get lawyerPracticeCivilLaw => 'Civil Law';

  @override
  String get lawyerPracticeConstitutionalLaw => 'Constitutional Law';

  @override
  String get lawyerPracticeCorporateLaw => 'Corporate Law';

  @override
  String get lawyerPracticeCriminalLaw => 'Criminal Law';

  @override
  String get lawyerPracticeEnvironmentalLaw => 'Environmental Law';

  @override
  String get lawyerPracticeFamilyLaw => 'Family Law';

  @override
  String get lawyerPracticeImmigrationLaw => 'Immigration Law';

  @override
  String get lawyerPracticeInsuranceLaw => 'Insurance Law';

  @override
  String get lawyerPracticeIntellectualPropertyLaw =>
      'Intellectual Property Law';

  @override
  String get lawyerPracticeLaborLaw => 'Labor Law';

  @override
  String get lawyerPracticeRealEstateLaw => 'Real Estate Law';

  @override
  String get lawyerPracticeTaxLaw => 'Tax Law';

  @override
  String get lawyerPracticeContractLaw => 'Contract Law';

  @override
  String get lawyerPracticeEstateWills => 'Estate & Wills';

  @override
  String get lawyerPracticeOther => 'Other';

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
  String get lawyerDesigOther => 'Other';

  @override
  String get brandAppName => 'CLAiR';

  @override
  String get homeHelloGuest => 'Hello, there';

  @override
  String homeHelloName(String name) {
    return 'Hello, $name';
  }

  @override
  String get homeTagline => 'How can CLAiR help you today?';

  @override
  String get homeStartNewChatTitle => 'Start new chat';

  @override
  String get homeStartNewChatSubtitle => 'Ask CLAiR a legal question';

  @override
  String get homeQuickActions => 'Quick Actions';

  @override
  String get homeSuggestedLawyers => 'Suggested Lawyers';

  @override
  String get homeSeeAll => 'See All';

  @override
  String get homeGeneratedDocuments => 'Generated Documents';

  @override
  String get homeViewAll => 'View All';

  @override
  String get homeConnect => 'Connect';

  @override
  String homeRatingCasesLine(String rating, int count) {
    return '$rating · $count cases';
  }

  @override
  String get authWelcomeBack => 'Welcome\nBack';

  @override
  String get authPassword => 'Password';

  @override
  String get authLogIn => 'Log in';

  @override
  String get authForgotPassword => 'Forgot Password ?';

  @override
  String get authNoAccountPrompt => 'Don\'t have an account? ';

  @override
  String get authSignUpLink => 'Sign up';

  @override
  String get authGuest => 'Guest';

  @override
  String get authGoogle => 'Google';

  @override
  String get chatConversationsTitle => 'Conversations';

  @override
  String get chatNewChatButton => 'New Chat';

  @override
  String get chatNoConversationsYet => 'No conversations yet';

  @override
  String get chatMenuSaveChat => 'Save Chat';

  @override
  String get chatMenuUnsaveChat => 'Unsave Chat';

  @override
  String get chatMenuShare => 'Share';

  @override
  String get chatMenuDownloadPdf => 'Download as PDF';

  @override
  String get chatMenuReport => 'Report';

  @override
  String get chatMenuShareToLawyer => 'Share to Lawyer';

  @override
  String get chatMenuDelete => 'Delete chat';

  @override
  String get chatPdfGeneratingSummary => 'Generating PDF summary...';

  @override
  String chatPdfSaveFailed(String error) {
    return 'Failed to save PDF: $error';
  }

  @override
  String get chatDisclaimerDismiss => 'Dismiss';

  @override
  String get chatTermsDisclaimerBody =>
      'By chatting with CLAiR, an AI chatbot, you agree to our';

  @override
  String get chatTermsDisclaimerTerms => 'Terms of Use';

  @override
  String get chatTermsDisclaimerAnd => 'and';

  @override
  String get chatTermsDisclaimerPrivacy => 'Privacy Policy';

  @override
  String get chatTermsDisclaimerPeriod => '.';

  @override
  String get chatTitleNewChat => 'New Chat';

  @override
  String get chatTitleCurrentConversation => 'Current conversation';

  @override
  String get chatRagDisconnectedBanner =>
      'Law library (RAG) not connected on server — answer may use general model knowledge only.';

  @override
  String get chatNoLawExcerpts =>
      'No law excerpts met the relevance threshold for this question.';

  @override
  String get chatRetrievedForAnswer => 'Retrieved for this answer';

  @override
  String get chatSourceLabel => 'Source';

  @override
  String get chatEmptyExploreTopic =>
      'Start a new conversation to explore a different topic.';

  @override
  String get chatCopiedClipboard => 'Copied to clipboard';

  @override
  String get chatEditMessageTitle => 'Edit Message';

  @override
  String get chatEditMessageHint => 'Edit your message';

  @override
  String get chatComposerHint => 'Ask anything';

  @override
  String get chatAssistantGreeting =>
      'Hi! I\'m CLAiR, how may I assist you today?';

  @override
  String get chatLawyersNearYou => 'Lawyers near you';

  @override
  String chatMatchPercent(String head, String pct) {
    return '$head · $pct% match';
  }

  @override
  String get notifMarkAllRead => 'Mark all read';

  @override
  String get notifEmpty => 'No notifications yet';

  @override
  String get notifBannerDismissTooltip => 'Dismiss';

  @override
  String get notifClearAll => 'Clear all';

  @override
  String get notifClearAllConfirmTitle => 'Clear all notifications?';

  @override
  String get notifClearAllConfirmBody =>
      'This permanently removes every notification. You cannot undo this.';

  @override
  String get notifDeleteTooltip => 'Delete';

  @override
  String get notifDeleteConfirmTitle => 'Delete this notification?';

  @override
  String get notifDeleteConfirmBody => 'This cannot be undone.';

  @override
  String get libScreenTitle => 'Library';

  @override
  String get libTabHistory => 'History';

  @override
  String get libTabSaved => 'Saved';

  @override
  String get libSearchChatsHint => 'Search chats...';

  @override
  String get libPreviewEmpty => 'Start a new message';

  @override
  String get libPreviewYou => 'You';

  @override
  String libPreviewRecent(String text) {
    return 'Recent: $text';
  }

  @override
  String get appearanceSectionTheme => 'Theme';

  @override
  String get appearanceThemeLight => 'Light';

  @override
  String get appearanceThemeDark => 'Dark';

  @override
  String get appearanceThemeSystem => 'System';

  @override
  String get appearanceAccentColor => 'Accent Color';

  @override
  String get appearanceFontSize => 'Font Size';

  @override
  String get appearanceSavedSnackbar => 'Appearance saved';

  @override
  String get appearanceSaveButton => 'Save Appearance';

  @override
  String get appearanceFontSmall => 'Small';

  @override
  String get appearanceFontDefault => 'Default';

  @override
  String get appearanceFontLarge => 'Large';

  @override
  String get appearanceFontExtraLarge => 'Extra Large';

  @override
  String get histTapToOpen => 'Tap to open conversation';

  @override
  String get histRenameDialogTitle => 'Rename conversation';

  @override
  String get histRenameHint => 'Enter new title';

  @override
  String get histRenameButton => 'Rename';

  @override
  String get histDeleteTitle => 'Delete conversation?';

  @override
  String get histDeleteBody =>
      'This will permanently delete this conversation and all its messages.';

  @override
  String get histGeneratingPdf => 'Generating PDF...';

  @override
  String histDownloadFailed(String error) {
    return 'Failed to download: $error';
  }

  @override
  String get histEmptyTitle => 'No conversations yet';

  @override
  String get histEmptySubtitle =>
      'Start a chat and your conversations will appear here';

  @override
  String get convSave => 'Save';

  @override
  String get convUnsave => 'Unsave';

  @override
  String get convRename => 'Rename';

  @override
  String get convShareToLawyer => 'Share to Lawyer';

  @override
  String get convDownload => 'Download';

  @override
  String get convDelete => 'Delete';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get apptNotFoundSnackbar =>
      'Could not find that appointment in your list.';

  @override
  String get apptMyTitle => 'My Appointments';

  @override
  String apptTotalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count appointments total',
      one: '1 appointment total',
    );
    return '$_temp0';
  }

  @override
  String get apptFilterAll => 'All';

  @override
  String get apptFilterPending => 'Pending';

  @override
  String get apptFilterAccepted => 'Accepted';

  @override
  String get apptFilterResolved => 'Resolved';

  @override
  String get apptFilterCancelled => 'Cancelled';

  @override
  String get apptSortNewestFirst => 'Booked · Newest first';

  @override
  String get apptSortOldestFirst => 'Booked · Oldest first';

  @override
  String get apptSortChipNewest => 'Sort: newest first';

  @override
  String get apptSortChipOldest => 'Sort: oldest first';

  @override
  String get apptNoFilterMatch => 'No appointments match this filter';

  @override
  String get apptShowAll => 'Show all';

  @override
  String get apptSectionCancelledOrDeclined => 'Cancelled or declined';

  @override
  String get apptSectionActivePending => 'Active & pending';

  @override
  String get apptSectionPastCancelled => 'Past / cancelled or declined';

  @override
  String get apptEmptyTitle => 'No appointments yet';

  @override
  String get apptEmptySubtitle =>
      'Book a lawyer consultation and\ntrack your status here';

  @override
  String get apptCardChat => 'Chat';

  @override
  String apptCardBookedAt(String date, String time) {
    return 'Booked $date · $time';
  }

  @override
  String get bookingAppointmentTypeLabel => 'Appointment type';

  @override
  String get bookingAppointmentTypeHint => 'What kind of consultation?';

  @override
  String get bookingAppointmentTypeLoadError =>
      'Could not load types. Tap to retry.';

  @override
  String get bookingAppointmentTypeRequired =>
      'Please select an appointment type.';

  @override
  String get apptBadgeNew => 'NEW';

  @override
  String get apptStatusPending => 'Pending';

  @override
  String get apptStatusAccepted => 'Accepted';

  @override
  String get apptStatusCancelled => 'Cancelled';

  @override
  String get apptStatusDeclined => 'Declined';

  @override
  String get apptDetailLabelType => 'Type';

  @override
  String get apptDetailLabelLawyer => 'Lawyer';

  @override
  String get apptDetailSectionDescription => 'Description';

  @override
  String get apptDetailReasonCancellation => 'Cancellation';

  @override
  String get apptDetailReasonDecline => 'Decline reason';

  @override
  String get apptDetailLabelBooked => 'Booked';

  @override
  String get apptDetailLabelUpdated => 'Updated';

  @override
  String get apptDetailCancelAppointment => 'Cancel appointment';

  @override
  String get apptDetailAttachedConversationTitle =>
      'Attached CLAiR conversation';

  @override
  String get apptDetailAttachedConversationSubtitle =>
      'Open the chat you shared when you booked this appointment.';

  @override
  String get apptDetailBannerCancelledByClientTitle => 'Appointment cancelled';

  @override
  String get apptDetailBannerCancelledByClientSubtitle =>
      'You cancelled this booking. Your lawyer has been notified.';

  @override
  String get apptDetailBannerConfirmedTitle => 'Appointment accepted';

  @override
  String get apptDetailBannerConfirmedSubtitle =>
      'Your lawyer has confirmed this appointment.';

  @override
  String get apptDetailBannerPendingTitle => 'Awaiting confirmation';

  @override
  String get apptDetailBannerPendingSubtitle =>
      'Your request is pending review by the lawyer.';

  @override
  String get apptDetailBannerDeclinedTitle => 'Request declined';

  @override
  String get apptDetailBannerDeclinedSubtitle =>
      'The lawyer was unable to accept this request.';

  @override
  String get apptDetailBannerResolvedTitle => 'Case resolved';

  @override
  String get apptDetailBannerResolvedSubtitle =>
      'Your lawyer marked this case as closed. You can still message them for 24 hours after it was resolved.';

  @override
  String get apptDetailBannerUnknownTitle => 'Unknown status';

  @override
  String apptDetailChatWithLawyer(String lawyerName) {
    return 'Chat with $lawyerName';
  }

  @override
  String get apptDetailChatLockedCancelledSelf =>
      'Chat is unavailable — you cancelled this appointment.';

  @override
  String get apptDetailChatLockedCancelledDeclined =>
      'Chat is unavailable — this appointment was declined.';

  @override
  String get apptDetailChatLockedPending =>
      'Chat will unlock once your appointment is accepted.';

  @override
  String get apptDetailChatLockedResolved =>
      'This case is resolved and the messaging period has ended. Ask your lawyer to reopen the case if you need to chat again.';

  @override
  String get apptDetailCancelOptionsFailed =>
      'Could not load cancellation options. Try again later.';

  @override
  String get apptDetailCancelledSuccess => 'Appointment cancelled.';

  @override
  String get apptDetailCancelWhyTitle => 'Why are you cancelling?';

  @override
  String get apptDetailCancelWhySubtitle =>
      'Your lawyer will see the reason you choose.';

  @override
  String get apptDetailCancelTellMoreHint => 'Tell us a bit more…';

  @override
  String get apptDetailCancelErrorPickReason => 'Please select a reason.';

  @override
  String get apptDetailCancelErrorOtherDetails =>
      'Please briefly describe why you are cancelling.';

  @override
  String get apptDetailKeepAppointment => 'Keep appointment';

  @override
  String get apptDetailConfirmCancel => 'Confirm cancel';

  @override
  String get libSavedEmptyTitle => 'No saved chats';

  @override
  String get libSavedEmptySubtitle =>
      'Bookmark chats to find\nthem easily later';

  @override
  String get libSearchNoSaved => 'No saved chats found';

  @override
  String get libSearchNoHistory => 'No chats found';

  @override
  String get libSearchTryDifferent => 'Try a different keyword.';

  @override
  String get commonSubmit => 'Submit';

  @override
  String get legalDocNoticeTitle => 'Official wording';

  @override
  String get legalDocNoticeBody =>
      'For legal accuracy, the full text below is in English.';

  @override
  String get signupTermsPrivacyRequired =>
      'You must agree to the Terms of Use and Privacy Policy to continue.';

  @override
  String get signupAgreementLead => 'I have read and agree to the CLAiR ';

  @override
  String get signupAgreementMiddle => ' and ';

  @override
  String get signupAgreementTail =>
      '. I understand that CLAiR provides legal information only and does not constitute legal advice or create an attorney-client relationship.';

  @override
  String get signupTitle => 'Sign Up';

  @override
  String get signupCompleteProfileTitle => 'Complete Your Profile';

  @override
  String get signupGoogleNameBanner =>
      'Almost there! Just add your name and agree to our terms to complete your Google sign-up.';

  @override
  String get signupFirstNameLabel => 'First Name';

  @override
  String get signupLastNameLabel => 'Last Name';

  @override
  String get signupFirstNameRequired => 'First name is required';

  @override
  String get signupLastNameRequired => 'Last name is required';

  @override
  String get signupContinueButton => 'Continue';

  @override
  String get signupCompleteSignUpButton => 'Complete Sign Up';

  @override
  String get reportScreenTitle => 'Report an issue';

  @override
  String get reportScreenHeroTitle => 'Report an issue with CLAiR';

  @override
  String get reportScreenHeroBody =>
      'Found a bug, wrong answer, or have feedback? We read every report and use it to keep CLAiR accurate and useful.';

  @override
  String get reportScreenAnonymousNote =>
      'Reports are anonymous unless you include details in your description.';

  @override
  String get reportIssueCategoryStep => 'Issue category';

  @override
  String get reportDescribeIssueHint =>
      'Describe the issue in detail. What happened, and what did you expect?';

  @override
  String get reportPrivacyNoteBody =>
      'Reports are handled confidentially. We may follow up to verify the issue and improve CLAiR.';

  @override
  String get reportSubmitButton => 'Submit report';

  @override
  String get reportSuccessTitle => 'Report submitted';

  @override
  String get reportSuccessBody =>
      'Thank you for helping improve CLAiR.\nOur team will review your report carefully.';

  @override
  String get reportBackToSettings => 'Back to settings';

  @override
  String get reportReplySheetTitle => 'Report reply';

  @override
  String get reportReplySheetSubtitle =>
      'Help us improve legal accuracy and safety.';

  @override
  String get reportReplyExplainHint =>
      'What is inaccurate or misleading about this response? Include any statutes or concepts if relevant.';

  @override
  String get reportReplySubmittedSnackbar => 'Thanks — your report was sent.';

  @override
  String get lawyerConcernTitle => 'Report a concern';

  @override
  String lawyerConcernAbout(String name) {
    return 'About: $name';
  }

  @override
  String get lawyerConcernShareSnackbar => 'Report shared via share sheet.';

  @override
  String get reportFieldContentReported => 'Content being reported';

  @override
  String get reportFieldChooseQuestionLegal =>
      'What best describes this issue?';

  @override
  String get reportFieldChooseCategoryLegalIntro =>
      'Choose the category that closest matches the legal concern.';

  @override
  String get reportFieldIssueCategory => 'Issue category';

  @override
  String get reportFieldYourExplanation => 'Your explanation';

  @override
  String get reportFieldExplanationBlurb =>
      'A short explanation is required so our team can understand the issue.';

  @override
  String get reportHintBriefConcern =>
      'Briefly explain what is wrong or concerning…';

  @override
  String get reportValidationExplanationShort =>
      'Please add a short explanation (at least a sentence).';

  @override
  String get reportLawBadLegalLabel => 'Bad Legal Information';

  @override
  String get reportLawBadLegalDesc =>
      'The response contains factually incorrect laws, cases, or statutes.';

  @override
  String get reportLawOutdatedLabel => 'Outdated Law or Regulation';

  @override
  String get reportLawOutdatedDesc =>
      'The cited law has been amended, repealed, or superseded.';

  @override
  String get reportLawMisleadingLabel => 'Misleading Interpretation';

  @override
  String get reportLawMisleadingDesc =>
      'Legal reasoning is skewed, incomplete, or taken out of context.';

  @override
  String get reportLawJurisdictionLabel => 'Wrong Jurisdiction';

  @override
  String get reportLawJurisdictionDesc =>
      'Laws from a different country, state, or region were applied.';

  @override
  String get reportLawMissingContextLabel => 'Missing Legal Context';

  @override
  String get reportLawMissingContextDesc =>
      'Key exceptions, conditions, or legal nuances were omitted.';

  @override
  String get reportLawHarmfulLabel => 'Potentially Harmful Advice';

  @override
  String get reportLawHarmfulDesc =>
      'Following this advice could cause legal harm or risk.';

  @override
  String get reportLawUnclearLabel => 'Unclear or Confusing Response';

  @override
  String get reportLawUnclearDesc =>
      'The answer is too vague or difficult to apply in a legal context.';

  @override
  String get reportLawOtherLabel => 'Other Legal Concern';

  @override
  String get reportLawOtherDesc =>
      'A concern not described by any category above.';

  @override
  String get reportAppBugLabel => 'App Bug';

  @override
  String get reportAppBugDesc =>
      'Something in the app is broken or behaving incorrectly.';

  @override
  String get reportAppWrongAiLabel => 'Wrong AI Response';

  @override
  String get reportAppWrongAiDesc =>
      'CLAiR gave an inaccurate, irrelevant, or harmful answer.';

  @override
  String get reportAppMisleadingLabel => 'Misleading Content';

  @override
  String get reportAppMisleadingDesc =>
      'Information was deceptive or presented out of context.';

  @override
  String get reportAppPrivacyLabel => 'Privacy or Security Concern';

  @override
  String get reportAppPrivacyDesc =>
      'An issue related to how your data is handled or stored.';

  @override
  String get reportAppFeatureLabel => 'Feature Feedback';

  @override
  String get reportAppFeatureDesc =>
      'Suggestions for new features or improvements to the app.';

  @override
  String get reportAppOtherLabel => 'Other';

  @override
  String get reportAppOtherDesc =>
      'An issue not covered by any of the categories above.';

  @override
  String get helpHeroTitle => 'How can we help?';

  @override
  String get helpHeroSubtitle => 'Browse common questions or search below.';

  @override
  String get helpSearchHint => 'Search FAQs…';

  @override
  String helpEmptyNoResults(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get helpEmptySuggest =>
      'Try different keywords or browse the sections above.';

  @override
  String get helpSecUsing => 'Using CLAiR';

  @override
  String get helpSecLawyers => 'Lawyers & Appointments';

  @override
  String get helpSecPrivacy => 'Privacy & Security';

  @override
  String get helpSecAccount => 'Account & Settings';

  @override
  String get helpSecReporting => 'Reporting & Feedback';

  @override
  String get helpFaqEnglishNotice =>
      'Detailed FAQ answers below are in English for legal accuracy.';

  @override
  String get tutorialSkip => 'Skip';

  @override
  String get tutorialNext => 'Next';

  @override
  String get tutorialBack => 'Back';

  @override
  String get tutorialDone => 'Get Started';

  @override
  String tutorialStepOf(Object current, Object total) {
    return '$current of $total';
  }

  @override
  String get tutorialWelcomeTitle => 'Welcome to CLAiR';

  @override
  String get tutorialWelcomeBody =>
      'Your AI-powered legal assistant. Let us give you a quick tour of the main features.';

  @override
  String get tutorialChatTitle => 'Chat with AI';

  @override
  String get tutorialChatBody =>
      'Ask CLAiR any legal question. Get instant, AI-powered guidance based on Philippine law.';

  @override
  String get tutorialLawyersTitle => 'Find a Lawyer';

  @override
  String get tutorialLawyersBody =>
      'Browse verified lawyers near you, view their profiles, and book consultations.';

  @override
  String get tutorialLibraryTitle => 'Chat Library';

  @override
  String get tutorialLibraryBody =>
      'All your past conversations are saved here. Pin, search, or download them as PDFs.';

  @override
  String get tutorialAppointmentsTitle => 'Appointments';

  @override
  String get tutorialAppointmentsBody =>
      'Track your booked consultations, chat with your lawyer, and manage your schedule.';
}
