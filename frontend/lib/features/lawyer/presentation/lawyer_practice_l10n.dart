import 'package:clair/l10n/app_localizations.dart';

/// Maps API / filter [practiceArea] strings to localized labels for display.
String localizeLawyerPracticeArea(AppLocalizations l, String raw) {
  switch (raw.trim()) {
    case 'Administrative Law':
      return l.lawyerPracticeAdministrativeLaw;
    case 'Banking & Finance Law':
      return l.lawyerPracticeBankingFinanceLaw;
    case 'Civil Law':
      return l.lawyerPracticeCivilLaw;
    case 'Constitutional Law':
      return l.lawyerPracticeConstitutionalLaw;
    case 'Corporate Law':
      return l.lawyerPracticeCorporateLaw;
    case 'Criminal Law':
      return l.lawyerPracticeCriminalLaw;
    case 'Environmental Law':
      return l.lawyerPracticeEnvironmentalLaw;
    case 'Family Law':
      return l.lawyerPracticeFamilyLaw;
    case 'Immigration Law':
      return l.lawyerPracticeImmigrationLaw;
    case 'Insurance Law':
      return l.lawyerPracticeInsuranceLaw;
    case 'Intellectual Property Law':
      return l.lawyerPracticeIntellectualPropertyLaw;
    case 'Labor Law':
      return l.lawyerPracticeLaborLaw;
    case 'Real Estate Law':
      return l.lawyerPracticeRealEstateLaw;
    case 'Tax Law':
      return l.lawyerPracticeTaxLaw;
    case 'Contract Law':
      return l.lawyerPracticeContractLaw;
    case 'Estate & Wills':
      return l.lawyerPracticeEstateWills;
    case 'Other':
      return l.lawyerPracticeOther;
    default:
      return raw;
  }
}

/// Maps API [designation] strings to localized labels for display.
String localizeLawyerDesignation(AppLocalizations l, String raw) {
  switch (raw.trim()) {
    case 'Associate':
      return l.lawyerDesigAssociate;
    case 'Junior Associate':
      return l.lawyerDesigJuniorAssociate;
    case 'Of Counsel':
      return l.lawyerDesigOfCounsel;
    case 'Paralegal':
      return l.lawyerDesigParalegal;
    case 'Senior Associate':
      return l.lawyerDesigSeniorAssociate;
    case 'Senior Partner':
      return l.lawyerDesigSeniorPartner;
    case 'Managing Partner':
      return l.lawyerDesigManagingPartner;
    case 'Associate Partner':
      return l.lawyerDesigAssociatePartner;
    case 'Other':
      return l.lawyerDesigOther;
    default:
      return raw;
  }
}
