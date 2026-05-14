import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: cl.bg,
      appBar: AppBar(
        backgroundColor: cl.bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.privacyPolicy,
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: cl.textDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _legalDocNotice(context),
            _header(context,
                'CLAiR — Privacy Policy',
                'Effective Date: April 24, 2026\nLast Updated: April 24, 2026'),
            _section(context, '1. Introduction and Scope',
                'CLAiR Technologies, Inc. ("CLAiR," "we," "us," or "our") is committed to protecting '
                'your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard '
                'your information when you use the CLAiR mobile application ("App").\n\n'
                'This Policy applies to all users globally, with specific provisions for users in the '
                'European Union (pursuant to GDPR), California (pursuant to CCPA/CPRA), and the Philippines '
                '(pursuant to the Data Privacy Act of 2012, Republic Act No. 10173).\n\n'
                'By creating an account and using the App, you consent to the data practices described '
                'in this Privacy Policy. If you do not agree, please do not use the App.\n\n'
                'Our Data Protection Officer (DPO) can be reached at: privacy@clair.app'),
            _section(context, '2. Information We Collect',
                'A. Information You Provide Directly:\n'
                '• Account registration data: first name, last name, email address, password (hashed)\n'
                '• Profile information: optional profile photo, contact preferences\n'
                '• Authentication data: Google account information (when using Google Sign-In)\n'
                '• Chat and query content: legal questions, document text, case descriptions you submit '
                'to the AI assistant\n'
                '• Communications: messages, feedback, support requests\n\n'
                'B. Information Collected Automatically:\n'
                '• Device identifiers: device type, operating system version, unique device ID\n'
                '• Usage data: features accessed, session duration, navigation patterns, timestamps\n'
                '• Log data: IP addresses, crash reports, error logs\n'
                '• Firebase Analytics: anonymized usage metrics and app performance data\n\n'
                'C. Information from Third Parties:\n'
                '• Google Sign-In: name, email address, and profile photo from your Google account, '
                'subject to your Google privacy settings\n'
                '• Firebase Authentication: authentication tokens and verification status'),
            _section(context, '3. How We Use Your Information',
                'We use the information we collect for the following purposes:\n\n'
                '• Service Delivery: To create and manage your account, authenticate your identity, '
                'and provide AI-assisted legal information responses\n'
                '• AI Processing: To generate responses to your legal queries using our AI system; '
                'inputs may be processed by third-party AI infrastructure providers under strict '
                'data processing agreements\n'
                '• Service Improvement: To analyze usage patterns, improve AI model accuracy, '
                'fix bugs, and develop new features (data used in aggregate or anonymized form)\n'
                '• Security: To detect and prevent fraud, abuse, unauthorized access, and other '
                'harmful activities, including compliance with the Computer Fraud and Abuse Act '
                '(CFAA) and equivalent laws\n'
                '• Communications: To send service notifications, security alerts, and — with '
                'your consent — promotional communications (you may opt out at any time)\n'
                '• Legal Compliance: To comply with applicable laws, respond to lawful requests '
                'from government authorities, and enforce our Terms of Use\n'
                '• Analytics: To understand how users interact with the App in aggregate form'),
            _section(context, '4. Legal Basis for Processing (GDPR — EU Users)',
                'For users in the European Economic Area (EEA), we process personal data on the '
                'following legal bases under Regulation (EU) 2016/679 (GDPR):\n\n'
                '• Article 6(1)(b) — Performance of a Contract: Processing necessary to provide '
                'the App services you have requested\n'
                '• Article 6(1)(a) — Consent: For optional features, marketing communications, '
                'and AI training on your content (you may withdraw consent at any time)\n'
                '• Article 6(1)(c) — Legal Obligation: To comply with applicable EU and member '
                'state laws, including tax, anti-money laundering, and record-keeping requirements\n'
                '• Article 6(1)(f) — Legitimate Interests: For fraud prevention, network security, '
                'and service improvement, where these interests are not overridden by your rights\n\n'
                'For processing of special categories of data (Article 9 GDPR) — such as legal '
                'matters that may reveal health, religion, or other sensitive information — we rely '
                'on your explicit consent (Article 9(2)(a)).'),
            _section(context, '5. Philippine Data Privacy Act Compliance',
                'For users in the Philippines, CLAiR complies with the Data Privacy Act of 2012 '
                '(Republic Act No. 10173) and its Implementing Rules and Regulations (IRR), '
                'as enforced by the National Privacy Commission (NPC).\n\n'
                'Our processing of personal information is based on the following criteria '
                '(Section 12 and 13, R.A. 10173):\n\n'
                '• Your consent to the collection and processing of your personal data\n'
                '• Fulfillment of a contract to which you are a party\n'
                '• Compliance with legal obligations applicable to CLAiR\n'
                '• Legitimate interests pursued by CLAiR, provided these do not override your rights\n\n'
                'As required by the NPC, our Privacy Management Program includes designation of a '
                'Data Protection Officer, implementation of privacy impact assessments, and a '
                'personal data breach management policy. Data breaches will be reported to the '
                'NPC and affected data subjects within 72 hours as required.'),
            _section(context, '6. How We Share Your Information',
                'CLAiR does not sell, rent, or trade your personal information. We may share '
                'information in the following circumstances:\n\n'
                '• Service Providers: With carefully vetted third-party vendors who assist in '
                'operating the App (cloud hosting, AI processing, analytics), bound by contractual '
                'data processing agreements with appropriate safeguards\n'
                '• Firebase / Google: Authentication and database services are provided by Google '
                'LLC under Google\'s Data Processing Addendum, compliant with GDPR Standard '
                'Contractual Clauses (SCCs)\n'
                '• Affiliated Lawyers: If you initiate a consultation, your contact information '
                'and query summary may be shared with the specific licensed attorney you select, '
                'with your explicit consent\n'
                '• Legal Requirements: When required by law, subpoena, court order, or governmental '
                'authority; we will notify you of such disclosure when legally permitted\n'
                '• Business Transfers: In connection with a merger, acquisition, or sale of assets, '
                'with notice to you and subject to the same privacy protections\n'
                '• Safety: When we believe disclosure is necessary to prevent imminent harm to '
                'any person or to protect our rights\n\n'
                'We do not share your legal queries or case information with third parties for '
                'their independent marketing or commercial purposes.'),
            _section(context, '7. Data Retention',
                'We retain your personal data for the following periods:\n\n'
                '• Account data: Retained while your account is active and for 7 years following '
                'account deletion to comply with applicable legal, tax, and regulatory obligations\n'
                '• Chat and query history: Retained for up to 3 years from the date of the query, '
                'or as required by applicable law\n'
                '• Anonymized AI training data: May be retained indefinitely in de-identified form\n'
                '• Security and fraud prevention logs: Retained for up to 3 years\n'
                '• Marketing consent records: Retained for the duration required by applicable law\n\n'
                'Upon account deletion, we will delete or anonymize your personal data within 30 '
                'days, except where retention is required by law. Backup copies may persist for '
                'up to 90 days for disaster recovery purposes.'),
            _section(context, '8. Your Privacy Rights',
                'Depending on your jurisdiction, you may have the following rights:\n\n'
                'For All Users:\n'
                '• Access: Request a copy of personal data we hold about you\n'
                '• Correction: Request correction of inaccurate or incomplete data\n'
                '• Deletion: Request deletion of your account and associated data\n'
                '• Data Portability: Receive your data in a structured, machine-readable format\n\n'
                'EU/EEA Users (GDPR — Articles 15–22):\n'
                '• Right to object to processing based on legitimate interests\n'
                '• Right to restrict processing in certain circumstances\n'
                '• Right not to be subject to solely automated decision-making with legal effects\n'
                '• Right to lodge a complaint with your national supervisory authority\n\n'
                'California Users (CCPA/CPRA — Cal. Civ. Code § 1798.100):\n'
                '• Right to know what personal information is collected, used, shared, or sold\n'
                '• Right to opt out of sale or sharing of personal information (CLAiR does not '
                'sell personal information)\n'
                '• Right to non-discrimination for exercising privacy rights\n'
                '• Right to correct inaccurate personal information\n'
                '• Right to limit use of sensitive personal information\n\n'
                'Philippine Users (R.A. 10173):\n'
                '• Right to be informed, right to access, right to object, right to erasure, '
                'right to rectification, right to data portability, and right to damages\n\n'
                'To exercise any right, contact us at privacy@clair.app or through App settings.'),
            _section(context, '9. Data Security',
                'We implement appropriate technical and organizational security measures to protect '
                'your personal data, including:\n\n'
                '• Encryption in transit: TLS/SSL encryption for all data transmitted between '
                'the App and our servers\n'
                '• Encryption at rest: Database encryption using AES-256 or equivalent standards\n'
                '• Access controls: Role-based access control (RBAC) limiting employee access '
                'to personal data on a need-to-know basis\n'
                '• Authentication: Multi-factor authentication for administrative access\n'
                '• Security audits: Regular penetration testing and vulnerability assessments\n'
                '• Incident response: A documented breach response plan compliant with GDPR '
                'Article 33 (72-hour notification requirement) and R.A. 10173 Section 20\n\n'
                'Despite our security measures, no method of transmission over the internet or '
                'electronic storage is 100% secure. You transmit data at your own risk and should '
                'exercise caution with highly sensitive legal information.'),
            _section(context, '10. Artificial Intelligence and Automated Processing',
                'Your legal queries are processed by AI systems to generate responses. You should '
                'be aware that:\n\n'
                '• AI processing may involve transmission of your query to AI infrastructure '
                'providers (e.g., cloud AI APIs) under data processing agreements\n'
                '• AI responses are not reviewed by human legal professionals before delivery '
                'unless you explicitly request human lawyer assistance\n'
                '• Under GDPR Article 22, you have the right not to be subject to decisions '
                'based solely on automated processing that produces legal or similarly significant '
                'effects; CLAiR\'s AI provides information only and does not make binding decisions\n'
                '• We use your anonymized interaction data to improve AI model performance; '
                'you may opt out of this use in App settings\n\n'
                'CLAiR complies with applicable AI regulation, including the EU AI Act '
                '(Regulation (EU) 2024/1689) which classifies AI systems used in legal contexts.'),
            _section(context, '11. Cookies and Tracking Technologies',
                'The App may use the following tracking technologies:\n\n'
                '• Firebase Analytics: Collects anonymized usage metrics to help us understand '
                'app performance and user behavior\n'
                '• Crash Reporting (Firebase Crashlytics): Collects technical information about '
                'app crashes to improve stability\n'
                '• Local Storage: Used to store preferences and session data on your device\n\n'
                'We do not use third-party advertising trackers or sell data to ad networks. '
                'You may limit analytics collection in your device\'s privacy settings or '
                'through the App\'s notification settings.'),
            _section(context, '12. Children\'s Privacy',
                'CLAiR is not intended for children under the age of 13 (or the applicable age '
                'of digital consent in your jurisdiction — 16 in the EU under GDPR Article 8).\n\n'
                'In compliance with the Children\'s Online Privacy Protection Act (COPPA), '
                '15 U.S.C. §§ 6501–6506, we do not knowingly collect personal information from '
                'children under 13. If you are a parent or guardian and believe your child has '
                'provided personal information to CLAiR, please contact us immediately at '
                'privacy@clair.app and we will delete that information promptly.'),
            _section(context, '13. International Data Transfers',
                'CLAiR may transfer your personal data to countries outside your jurisdiction, '
                'including to countries that may not provide the same level of data protection '
                'as your home country.\n\n'
                'For EU/EEA users, international transfers are made under appropriate safeguards '
                'including:\n'
                '• Standard Contractual Clauses (SCCs) approved by the European Commission '
                '(Commission Implementing Decision (EU) 2021/914)\n'
                '• Adequacy decisions where applicable\n\n'
                'For Philippine users, cross-border data flows comply with NPC Circular No. 16-01 '
                'on cross-border data transfers.\n\n'
                'Our primary data processing infrastructure is located in [Region]. Firebase and '
                'Google services may process data in multiple global regions.'),
            _section(context, '14. Legal Holds and Compliance Requests',
                'As an AI legal information platform, CLAiR may receive legal process requests '
                '(subpoenas, court orders, warrants) relating to user data. Our policy is to:\n\n'
                '(a) Review all requests for legal validity and sufficiency;\n'
                '(b) Notify affected users of requests unless prohibited by law or court order;\n'
                '(c) Produce only the minimum information necessary to comply;\n'
                '(d) Challenge requests that appear overbroad or lacking legal authority.\n\n'
                'We maintain a Transparency Report documenting government data requests, '
                'available upon request or published periodically on our website.'),
            _section(context, '15. Third-Party Privacy Policies',
                'The following third-party services used in CLAiR have their own privacy policies:\n\n'
                '• Google LLC (Firebase, Google Sign-In): https://policies.google.com/privacy\n'
                '• Firebase Authentication: Governed by Google\'s Privacy Policy\n\n'
                'We encourage you to review the privacy policies of any third-party services '
                'you interact with through the App. CLAiR is not responsible for the privacy '
                'practices of third-party services.'),
            _section(context, '16. Changes to This Privacy Policy',
                'We may update this Privacy Policy from time to time to reflect changes in our '
                'practices, technology, legal requirements, or other factors. We will notify you '
                'of material changes by:\n\n'
                '• Posting the updated Policy in the App with a revised "Last Updated" date\n'
                '• Sending an in-app notification or email to your registered address\n'
                '• Requiring re-acknowledgment of the updated Policy when required by law\n\n'
                'Your continued use of the App after the effective date of any changes constitutes '
                'your acceptance of the revised Privacy Policy. If you do not agree, you must '
                'discontinue use of the App.'),
            _section(context, '17. Contact Us — Data Protection Officer',
                'For privacy inquiries, rights requests, or data protection concerns:\n\n'
                'CLAiR Technologies, Inc.\n'
                'Data Protection Officer\n'
                'Email: privacy@clair.app\n'
                'In-App: Settings → Help & Support → Privacy Request\n\n'
                'EU Representative (GDPR Article 27): [EU Representative Contact]\n\n'
                'Philippine Data Protection Officer:\n'
                'Registered with the National Privacy Commission (NPC)\n'
                'Contact: privacy@clair.app\n\n'
                'We will respond to all verifiable privacy requests within:\n'
                '• 30 days for general requests\n'
                '• 72 hours for data breach notifications (as required by GDPR and R.A. 10173)\n'
                '• As required by applicable law for rights requests'),
          ],
        ),
      ),
    );
  }

  Widget _legalDocNotice(BuildContext context) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cl.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cl.accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.legalDocNoticeTitle,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: cl.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.legalDocNoticeBody,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: cl.textMid,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, String title, String subtitle) {
    final cl = context.c;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cl.accent.withOpacity(0.15), cl.accentLight.withOpacity(0.2)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cl.accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: cl.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: cl.textMid,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, String body) {
    final cl = context.c;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cl.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cl.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: cl.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: GoogleFonts.nunito(fontSize: 13, color: cl.textMid, height: 1.5),
          ),
        ],
      ),
    );
  }
}
