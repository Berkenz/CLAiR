import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cl = context.c;

    return Scaffold(
      backgroundColor: cl.bg,
      appBar: AppBar(
        backgroundColor: cl.bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Terms of Use',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: cl.textDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Cover Block ──────────────────────────────────────────────
            _header(context,
                'CLAiR — Terms of Use',
                'Effective Date: April 24, 2026\n'
                'Last Updated: April 24, 2026\n'
                'Version: 1.0\n\n'
                'PLEASE READ THESE TERMS OF USE CAREFULLY BEFORE USING THE '
                'CLAIR APPLICATION. BY ACCESSING OR USING THE APP YOU AGREE '
                'TO BE LEGALLY BOUND BY THESE TERMS.'),

            // ── Critical Disclaimer ──────────────────────────────────────
            _alert(context,
                '⚠  IMPORTANT LEGAL DISCLAIMER',
                'CLAiR IS NOT A LAW FIRM. THE CLAIR APPLICATION PROVIDES '
                'GENERAL LEGAL INFORMATION ONLY AND DOES NOT CONSTITUTE LEGAL '
                'ADVICE. USE OF THIS APPLICATION DOES NOT CREATE AN '
                'ATTORNEY-CLIENT RELATIONSHIP OF ANY KIND. DO NOT USE CLAIR '
                'AS A SUBSTITUTE FOR ADVICE FROM A LICENSED ATTORNEY. FOR '
                'LEGAL ADVICE SPECIFIC TO YOUR SITUATION, CONSULT A QUALIFIED '
                'LAWYER IN THE RELEVANT JURISDICTION.'),

            _section(context, '1. Acceptance of Terms and Binding Agreement',
                '1.1  Agreement to Terms. By downloading, installing, '
                'accessing, browsing, or using the CLAiR mobile application '
                '("App," "Service," or "Platform"), creating an account, or '
                'clicking "I Agree," you ("User," "you," or "your") '
                'acknowledge that you have read, understood, and agree to be '
                'legally bound by these Terms of Use ("Terms"), our Privacy '
                'Policy (incorporated herein by reference), and all guidelines, '
                'policies, and supplemental terms referenced herein. If you do '
                'not agree to all of these Terms, you must immediately '
                'discontinue use of the App and delete it from your device.\n\n'
                '1.2  Legal Capacity. By accepting these Terms you represent '
                'and warrant that you have the legal capacity to enter into a '
                'binding contract. If you are accepting on behalf of a company, '
                'organization, or other legal entity, you represent that you '
                'have the authority to bind that entity to these Terms.\n\n'
                '1.3  Electronic Acceptance. Your acceptance of these Terms is '
                'made electronically in accordance with the Electronic Commerce '
                'Act of the Philippines (Republic Act No. 8792), the Electronic '
                'Signatures in Global and National Commerce Act (E-SIGN Act, '
                '15 U.S.C. § 7001 et seq.), and the EU Electronic Identification '
                'and Trust Services Regulation (eIDAS, Regulation (EU) No '
                '910/2014). You agree that your electronic acceptance carries '
                'the same legal force as a handwritten signature.\n\n'
                '1.4  Modifications to Terms. CLAiR Technologies, Inc. '
                '("CLAiR," "we," "us," or "our") reserves the right to modify '
                'these Terms at any time at our sole discretion. We will notify '
                'you of material changes by: (a) posting the revised Terms in '
                'the App with an updated effective date; (b) sending an in-app '
                'notification or email; and/or (c) requiring you to affirmatively '
                're-accept the Terms on next login. Continued use of the App '
                'after the effective date of any modification constitutes your '
                'acceptance of the revised Terms. If you object to any change, '
                'your sole remedy is to discontinue use.'),

            _section(context, '2. Definitions',
                'For purposes of these Terms, the following definitions apply:\n\n'
                '"AI Assistant" means the artificial intelligence system '
                'integrated into the App that generates legal information '
                'responses, summaries, and analyses.\n\n'
                '"AI-Generated Content" means any text, analysis, summary, '
                'document draft, or other output produced by the AI Assistant.\n\n'
                '"App" or "Service" means the CLAiR mobile application, '
                'including all features, content, software, and services '
                'accessible through it, and any successor versions.\n\n'
                '"Applicable Law" means all applicable statutes, regulations, '
                'ordinances, rules, orders, and decrees of any governmental '
                'authority with jurisdiction over the parties or the subject '
                'matter of these Terms.\n\n'
                '"Attorney-Client Relationship" means the formal legal '
                'relationship established between a client and a licensed '
                'attorney that gives rise to duties of confidentiality, loyalty, '
                'and competence, and which confers attorney-client privilege.\n\n'
                '"CLAiR Technologies, Inc." means the company that owns and '
                'operates the App.\n\n'
                '"Confidential Information" has the meaning given to it in '
                'Section 10 of these Terms.\n\n'
                '"Guest Account" means an anonymous user account created '
                'without email registration.\n\n'
                '"Lawyer Directory" means the directory of independently '
                'licensed legal professionals accessible through the App.\n\n'
                '"Legal Information" means general information about legal '
                'topics, laws, regulations, and legal processes, as distinct '
                'from legal advice tailored to a specific individual\'s '
                'circumstances.\n\n'
                '"Prohibited Content" means content described in Section 7.2.\n\n'
                '"Subscription" means a paid plan granting access to premium '
                'features of the App.\n\n'
                '"User Content" means any information, text, files, documents, '
                'queries, or other materials that you submit to the App.\n\n'
                '"User" means any individual who accesses or uses the App, '
                'whether registered or anonymous.'),

            _section(context, '3. Description of Service',
                '3.1  Overview. CLAiR is an AI-powered legal information '
                'platform designed to help users understand legal concepts, '
                'explore legal documents, and connect with licensed legal '
                'professionals. The App is a technology product — not a law '
                'firm, legal aid society, or bar association — and does not '
                'employ attorneys to represent users.\n\n'
                '3.2  Core Features. The App may include the following '
                'features, which may vary by subscription tier, jurisdiction, '
                'and platform version:\n\n'
                '(a) AI Legal Q&A — natural language question-and-answer on '
                'general legal topics, case law summaries, statutory '
                'interpretation, and procedural guidance;\n'
                '(b) Document Analysis — AI-assisted review and summary of '
                'uploaded legal documents, contracts, and pleadings;\n'
                '(c) Legal Research Assistance — AI-generated summaries of '
                'publicly available case law, statutes, and regulations;\n'
                '(d) Lawyer Directory — listing of independently licensed '
                'attorneys who have registered on the Platform;\n'
                '(e) Appointment Scheduling — tools to request and schedule '
                'consultations with Lawyers listed in the Directory;\n'
                '(f) Case and Document Management — storage and organization '
                'of user-created notes, saved queries, and documents;\n'
                '(g) Notifications — reminders, alerts, and updates related '
                'to your activity on the Platform.\n\n'
                '3.3  Service Availability. CLAiR does not guarantee that the '
                'App will be available continuously, uninterrupted, or free '
                'from errors. We reserve the right to modify, suspend, limit, '
                'or discontinue any feature at any time for maintenance, '
                'regulatory compliance, security, or any other reason.'),

            _section(context, '4. No Attorney-Client Relationship',
                '4.1  No Legal Representation. CLAIR IS NOT A LAW FIRM AND '
                'DOES NOT PROVIDE LEGAL REPRESENTATION. USE OF THE APP DOES '
                'NOT CREATE AN ATTORNEY-CLIENT RELATIONSHIP BETWEEN YOU AND '
                'CLAIR, ANY CLAIR EMPLOYEE, ANY CLAIR CONTRACTOR, OR ANY '
                'LAWYER LISTED IN THE LAWYER DIRECTORY UNLESS YOU HAVE '
                'SEPARATELY ENTERED INTO A WRITTEN RETAINER AGREEMENT WITH '
                'THAT ATTORNEY.\n\n'
                '4.2  No Privilege. Communications through the App — '
                'including all queries submitted to the AI Assistant and any '
                'messages sent through the Platform — are NOT protected by '
                'attorney-client privilege or the work product doctrine. This '
                'is because no attorney-client relationship exists with CLAiR. '
                'Under ABA Model Rule 1.6 (Confidentiality of Information), '
                'privilege attaches only to communications made in the context '
                'of an attorney-client relationship. CLAiR does not create '
                'such a relationship.\n\n'
                '4.3  Lawyer Directory Disclaimer. The appearance of a lawyer '
                'in the CLAiR Lawyer Directory does not constitute: (a) an '
                'endorsement by CLAiR of that attorney\'s services; (b) a '
                'referral in the sense governed by ABA Model Rule 7.2 '
                '(Communications Concerning a Lawyer\'s Services); or (c) the '
                'establishment of any professional relationship. CLAiR does '
                'not verify the credentials, licensure status, disciplinary '
                'history, or competency of listed lawyers beyond the '
                'information they self-report. You are solely responsible for '
                'conducting due diligence before retaining any attorney.\n\n'
                '4.4  Third-Party Legal Services. If you independently retain '
                'a lawyer through the Platform, any resulting attorney-client '
                'relationship is exclusively between you and that lawyer. CLAiR '
                'is not a party to that relationship and assumes no liability '
                'for the lawyer\'s services, advice, or conduct. Any fee '
                'arrangements are solely between you and the attorney.\n\n'
                '4.5  Duty to Seek Independent Counsel. For any matter that '
                'may have significant legal consequences — including but not '
                'limited to criminal charges, civil litigation, immigration '
                'proceedings, family law matters, business transactions, '
                'property disputes, or constitutional rights — you are strongly '
                'advised to retain a licensed attorney who can provide advice '
                'specific to your factual circumstances and applicable law.'),

            _section(context, '5. Legal Information vs. Legal Advice',
                '5.1  Information Only. The App provides Legal Information '
                'only. Legal Information is general information about laws, '
                'regulations, court procedures, and legal concepts. It is '
                'educational in nature and not tailored to any particular '
                'individual\'s facts or circumstances.\n\n'
                '5.2  What AI-Generated Content Cannot Do. AI-Generated '
                'Content provided through CLAiR:\n\n'
                '(a) Does not constitute legal advice under ABA Model Rule 1.2 '
                '(Scope of Representation) or equivalent professional conduct '
                'rules in any jurisdiction;\n'
                '(b) Does not reflect advice from a lawyer with knowledge of '
                'your specific facts, jurisdiction, or applicable law;\n'
                '(c) Does not account for procedural deadlines, statutes of '
                'limitations, or jurisdictional variations that may critically '
                'affect your rights;\n'
                '(d) May not reflect the most recent legislative changes, '
                'amendments, court decisions, or administrative guidance;\n'
                '(e) Cannot replace a lawyer\'s duties of competence and '
                'diligence under ABA Model Rule 1.1 and Rule 1.3;\n'
                '(f) Is not protected by any privilege and cannot be presented '
                'as a legal opinion in any court or administrative proceeding.\n\n'
                '5.3  Unauthorized Practice of Law. The practice of law is '
                'regulated by bar associations and government authorities in '
                'each jurisdiction. Under ABA Model Rule 5.5 (Unauthorized '
                'Practice of Law), only licensed attorneys may provide legal '
                'advice. CLAiR expressly does not provide legal advice, and '
                'nothing in the App should be construed as the unauthorized '
                'practice of law. The App is designed as an information and '
                'productivity tool, not as a legal services provider.\n\n'
                '5.4  Specific Limitations by Practice Area. You should be '
                'especially cautious about relying on AI-Generated Content '
                'in the following areas:\n\n'
                '• Criminal Law: Any criminal matter — including arrest, '
                'charges, plea negotiations, sentencing, or appeals — requires '
                'the immediate assistance of a licensed criminal defense '
                'attorney. You have constitutional rights that require human '
                'counsel to protect (e.g., Sixth Amendment right to counsel '
                'in the United States).\n'
                '• Immigration Law: Immigration matters are highly fact-specific '
                'and involve complex, frequently changing regulations. Errors '
                'can result in detention, removal, or bars to future admission. '
                'Consult an immigration attorney or accredited representative.\n'
                '• Family Law: Matters involving child custody, divorce, '
                'domestic violence, adoption, and support are highly '
                'jurisdiction-specific and emotionally complex.\n'
                '• Tax Law: Tax obligations vary significantly by jurisdiction '
                'and individual circumstances. Consult a licensed tax '
                'professional or tax attorney.\n'
                '• Real Estate and Property Law: Title issues, zoning, and '
                'real property transactions require jurisdiction-specific '
                'legal expertise.\n'
                '• Intellectual Property: Patent, trademark, and copyright '
                'matters require specialized legal analysis.\n'
                '• Medical Malpractice and Personal Injury: Statute of '
                'limitations and liability rules vary widely by jurisdiction '
                'and must be assessed by a licensed attorney promptly.'),

            _section(context, '6. User Eligibility and Account Registration',
                '6.1  Age Requirements. You must be at least eighteen (18) '
                'years of age to create an account and use the App. If you are '
                'under the age of majority in your jurisdiction but at least 13 '
                'years old, you may only use the App with the verifiable consent '
                'of a parent or legal guardian who agrees to be bound by these '
                'Terms on your behalf. In countries where the EU General Data '
                'Protection Regulation (GDPR) applies, the minimum age for '
                'digital consent is sixteen (16) absent member-state variations '
                '(GDPR Article 8).\n\n'
                '6.2  COPPA Compliance. In accordance with the Children\'s '
                'Online Privacy Protection Act (COPPA), 15 U.S.C. §§ 6501–6506, '
                'and the FTC\'s COPPA Rule (16 C.F.R. Part 312), CLAiR does '
                'not knowingly collect personal information from individuals '
                'under thirteen (13) years of age. If we discover that a user '
                'is under 13, we will immediately terminate the account and '
                'delete all associated personal data.\n\n'
                '6.3  Registration Requirements. When creating an account, '
                'you agree to: (a) provide accurate, current, and complete '
                'information; (b) maintain and promptly update your information '
                'to keep it accurate; (c) keep your password confidential and '
                'not share it with any third party; (d) notify us immediately '
                'of any unauthorized use of your account at security@clair.app; '
                'and (e) accept responsibility for all activities that occur '
                'under your account.\n\n'
                '6.4  Account Types. The App offers the following account '
                'types:\n\n'
                '(a) Email Account: Registered with a valid email address and '
                'password. Requires email verification before full access is '
                'granted.\n'
                '(b) Google Account: Authenticated via Google Sign-In, governed '
                'additionally by Google\'s Terms of Service and Privacy Policy.\n'
                '(c) Guest Account: Anonymous access with limited features. '
                'Guest accounts may be deleted after 90 days of inactivity. '
                'Guest users cannot access the Lawyer Directory or Appointment '
                'Scheduling features.\n\n'
                '6.5  Account Security. You are responsible for maintaining '
                'the security of your account. CLAiR will not be liable for '
                'any loss or damage arising from your failure to comply with '
                'these security obligations. You agree not to: (a) create '
                'multiple accounts for deceptive purposes; (b) use another '
                'person\'s account; or (c) transfer your account to any third '
                'party without CLAiR\'s prior written consent.\n\n'
                '6.6  Professional Users. If you are a licensed attorney using '
                'CLAiR for professional purposes, you additionally represent '
                'that: (a) your use of the App complies with the professional '
                'conduct rules of every jurisdiction in which you are licensed; '
                '(b) you maintain sole responsibility for any legal advice you '
                'provide to clients, regardless of any AI-Generated Content '
                'you may consult; and (c) you will comply with confidentiality '
                'obligations when inputting client information into the App.'),

            _section(context, '7. Permitted Use and Prohibited Conduct',
                '7.1  Permitted Use. Subject to these Terms, CLAiR grants you '
                'a limited, non-exclusive, non-transferable, revocable license '
                'to access and use the App for your personal, non-commercial '
                'informational purposes only.\n\n'
                '7.2  Prohibited Conduct. You agree NOT to:\n\n'
                '(a) Legal Violations\n'
                '• Use the App for any unlawful purpose or in violation of '
                'any Applicable Law, including consumer protection laws, '
                'anti-spam regulations, export control laws, and privacy laws;\n'
                '• Use the App to threaten, harass, stalk, defame, or '
                'intimidate any person;\n'
                '• Use the App to engage in or facilitate fraud, identity theft, '
                'money laundering, terrorist financing, or other financial crimes;\n'
                '• Use the App to create, distribute, or assist in the creation '
                'of fraudulent legal documents or forged instruments;\n\n'
                '(b) Unauthorized Access and Interference\n'
                '• Attempt to gain unauthorized access to any portion of the '
                'App or its infrastructure, including servers, databases, '
                'and software;\n'
                '• Circumvent, disable, or interfere with any security feature '
                'of the App;\n'
                '• Use the App in a manner that could disable, overburden, '
                'damage, or impair the App\'s servers or networks;\n'
                '• Conduct or facilitate denial-of-service attacks;\n'
                '• Introduce any malware, ransomware, Trojan horse, worm, '
                'or other malicious code;\n'
                '• Violate the Computer Fraud and Abuse Act (CFAA), '
                '18 U.S.C. § 1030, the Philippines Cybercrime Prevention Act '
                '(Republic Act No. 10175), or equivalent laws;\n\n'
                '(c) Reverse Engineering and Unauthorized Copying\n'
                '• Reverse engineer, decompile, disassemble, or attempt to '
                'derive the source code of the App;\n'
                '• Copy, reproduce, distribute, publish, or create derivative '
                'works from the App\'s content without permission;\n'
                '• Use data mining, scraping, web crawling, or other automated '
                'data extraction methods;\n'
                '• Frame or mirror any content from the App on another website;\n\n'
                '(d) Misrepresentation and Impersonation\n'
                '• Impersonate any person or entity, including any CLAiR '
                'employee, officer, lawyer, judge, or government official;\n'
                '• Falsely claim an affiliation with any person or organization;\n'
                '• Submit false, inaccurate, or misleading information;\n\n'
                '(e) Professional Misconduct\n'
                '• Use the App in violation of any applicable bar association '
                'rules or professional conduct regulations;\n'
                '• Use AI-Generated Content to misrepresent legal status '
                'or credentials;\n'
                '• Use the App to engage in or assist the unauthorized '
                'practice of law;\n\n'
                '(f) Content Violations\n'
                '• Upload, transmit, or distribute content that is obscene, '
                'pornographic, or sexually explicit;\n'
                '• Upload content that infringes any third party\'s copyright, '
                'trademark, patent, trade secret, or other intellectual '
                'property right;\n'
                '• Upload content that violates any person\'s privacy rights;\n'
                '• Use the App to generate content that advocates violence, '
                'discrimination, or hatred based on race, religion, national '
                'origin, gender, sexual orientation, disability, or other '
                'protected characteristic;\n\n'
                '7.3  Consequences of Violations. Violations of this Section '
                'may result in immediate account suspension or termination, '
                'reporting to law enforcement authorities, civil or criminal '
                'liability, and/or injunctive relief. CLAiR reserves the right '
                'to investigate suspected violations and cooperate with law '
                'enforcement agencies.'),

            _section(context, '8. AI-Generated Content — Accuracy and Limitations',
                '8.1  Nature of AI Technology. CLAiR uses large language model '
                '(LLM) artificial intelligence technology to generate responses. '
                'LLMs are trained on large datasets and generate outputs based '
                'on statistical patterns. By their nature, LLMs may produce '
                'content that is factually incorrect, outdated, biased, '
                'inconsistent, or contextually inappropriate.\n\n'
                '8.2  Known Limitations. You acknowledge and agree that '
                'AI-Generated Content:\n\n'
                '(a) May contain "hallucinations" — plausible-sounding but '
                'factually incorrect information, including false citations to '
                'non-existent cases, statutes, or legal authorities;\n'
                '(b) May not reflect recent legislative changes, new case law, '
                'regulatory updates, or emergency orders issued after the '
                'model\'s training cutoff date;\n'
                '(c) May not account for jurisdiction-specific variations in '
                'law that materially affect your situation;\n'
                '(d) May misinterpret ambiguous legal terminology or concepts '
                'in ways that lead to incorrect conclusions;\n'
                '(e) Is not peer-reviewed, professionally edited, or approved '
                'by a licensed attorney prior to delivery;\n'
                '(f) Does not constitute a legal opinion admissible in any '
                'court, arbitral proceeding, or regulatory proceeding;\n'
                '(g) May reflect training data biases that skew analysis '
                'toward certain legal traditions, jurisdictions, or outcomes;\n'
                '(h) Cannot be relied upon for legal strategy, case theory, '
                'or professional legal judgment.\n\n'
                '8.3  EU AI Act Compliance. Pursuant to the EU Artificial '
                'Intelligence Act (Regulation (EU) 2024/1689, "AI Act"), '
                'CLAiR classifies its AI features used in legal contexts and '
                'implements appropriate transparency and user notification '
                'measures. The AI Act establishes obligations for high-risk AI '
                'systems in the administration of justice and legal research. '
                'CLAiR maintains an AI Governance Policy available upon '
                'request at legal@clair.app.\n\n'
                '8.4  Verification Obligation. You bear sole responsibility '
                'for independently verifying all AI-Generated Content before '
                'relying on it for any purpose. You should consult primary '
                'legal sources (official statutes, published case reporters, '
                'regulatory codes) and, for matters of legal consequence, '
                'a licensed attorney.\n\n'
                '8.5  AI Training Data. CLAiR may use aggregated, anonymized '
                'interaction data to improve its AI models, subject to the '
                'terms of our Privacy Policy. You may opt out of AI training '
                'use in App Settings. CLAiR will not use your personally '
                'identifiable information or the specific content of your '
                'legal queries for AI training without your explicit consent.'),

            _section(context, '9. User Content and License Grant',
                '9.1  Your Ownership. You retain all ownership rights in '
                'User Content you submit to the App. These Terms do not '
                'transfer ownership of your User Content to CLAiR.\n\n'
                '9.2  License to CLAiR. By submitting User Content, you grant '
                'CLAiR a non-exclusive, worldwide, royalty-free, sublicensable, '
                'transferable license to: (a) host, store, process, and '
                'transmit your User Content to provide the Service; '
                '(b) use your User Content in anonymized, aggregated form to '
                'improve and train AI models; and (c) display your User Content '
                'to you and, where applicable, to lawyers you designate.\n\n'
                '9.3  Representations About User Content. You represent and '
                'warrant that: (a) you own or have the necessary rights to '
                'submit your User Content; (b) your User Content does not '
                'infringe the intellectual property rights of any third party; '
                '(c) your User Content does not violate any third party\'s '
                'privacy rights or confidentiality obligations; and (d) you '
                'have obtained all required consents before submitting any '
                'third-party personal information to the App.\n\n'
                '9.4  Content Responsibility. CLAiR does not pre-screen User '
                'Content but reserves the right to review, remove, or restrict '
                'access to User Content that violates these Terms or that we '
                'are required to remove by law. We are not liable for any '
                'User Content submitted by you or any other user.\n\n'
                '9.5  Feedback. If you provide feedback, suggestions, or '
                'ideas regarding the App ("Feedback"), CLAiR may use that '
                'Feedback without restriction or compensation to you. Feedback '
                'does not constitute User Content and you hereby waive any '
                'rights in such Feedback to the fullest extent permitted by law.'),

            _section(context, '10. Sensitive and Confidential Information',
                '10.1  No Confidentiality Obligation. Unlike communications '
                'with a licensed attorney, communications through the CLAiR App '
                'are NOT confidential in the legal sense. CLAiR does not assume '
                'any obligation of confidentiality with respect to User Content, '
                'except as expressly stated in our Privacy Policy.\n\n'
                '10.2  Types of Sensitive Information. Before submitting '
                'information to the App, you should carefully consider whether '
                'it includes:\n\n'
                '(a) Attorney-Client Privileged Communications — which do NOT '
                'retain their privileged character when disclosed to CLAiR;\n'
                '(b) Work Product — materials prepared in anticipation of '
                'litigation, which are not protected by work product doctrine '
                'when submitted to CLAiR;\n'
                '(c) Protected Health Information (PHI) — as defined under '
                'the Health Insurance Portability and Accountability Act '
                '(HIPAA), 45 C.F.R. Parts 160 and 164; CLAiR is not a '
                '"covered entity" or "business associate" under HIPAA;\n'
                '(d) Personally Identifiable Information (PII) of third parties, '
                'including opposing parties in litigation, clients of law firms, '
                'or other individuals who have not consented to having their '
                'information submitted to an AI platform;\n'
                '(e) Classified or Sensitive Government Information — which '
                'must not be submitted to the App under any circumstances;\n'
                '(f) Trade Secrets or Proprietary Business Information subject '
                'to nondisclosure agreements;\n'
                '(g) Court-Ordered Confidential or Sealed Materials.\n\n'
                '10.3  Professional Attorney Obligations. If you are a licensed '
                'attorney, you acknowledge that submitting client information '
                'to the App may implicate your duties under ABA Model Rule 1.6 '
                '(Confidentiality), ABA Model Rule 1.1 (Competence — '
                'including technological competence), and equivalent rules in '
                'your jurisdiction. You are solely responsible for determining '
                'whether your use of CLAiR complies with your professional '
                'obligations to clients.\n\n'
                '10.4  Proceed with Caution. CLAiR strongly recommends that '
                'users avoid submitting sensitive personal information, '
                'third-party information, or any information subject to a '
                'legal privilege or confidentiality agreement to the AI '
                'Assistant. Provide only the minimum information necessary '
                'to receive the assistance you need.'),

            _section(context, '11. Intellectual Property Rights',
                '11.1  CLAiR Ownership. The App, including all software, '
                'algorithms, code, user interfaces, design elements, graphics, '
                'text, data compilations, trademarks, logos, and other content '
                'created or owned by CLAiR (collectively, "CLAiR IP"), is the '
                'exclusive property of CLAiR Technologies, Inc. and is '
                'protected by:\n\n'
                '• U.S. Copyright Act, 17 U.S.C. § 101 et seq.\n'
                '• Lanham Act (trademarks), 15 U.S.C. § 1051 et seq.\n'
                '• Computer Software Copyright Act, 17 U.S.C. §§ 101, 106\n'
                '• Digital Millennium Copyright Act (DMCA), 17 U.S.C. § 512\n'
                '• Philippine Intellectual Property Code (Republic Act No. 8293)\n'
                '• EU Directive 2009/24/EC on the legal protection of computer '
                'programs\n'
                '• EU Directive 96/9/EC on the legal protection of databases\n'
                '• Berne Convention for the Protection of Literary and '
                'Artistic Works (as implemented by signatory nations)\n'
                '• WIPO Copyright Treaty and WIPO Performances and Phonograms '
                'Treaty\n\n'
                '11.2  License Restrictions. You may not: (a) reproduce, copy, '
                'download, or archive any portion of the CLAiR IP except as '
                'necessary for your personal use; (b) create derivative works '
                'based on the CLAiR IP; (c) sell, sublicense, or commercially '
                'exploit any CLAiR IP; (d) remove or alter any copyright, '
                'trademark, or proprietary notice; or (e) use CLAiR\'s '
                'trademarks in any manner that implies sponsorship or endorsement '
                'by CLAiR without prior written consent.\n\n'
                '11.3  Copyright Complaints (DMCA). If you believe that your '
                'copyright has been infringed by content on the App, please '
                'send a written notice to legal@clair.app in accordance with '
                '17 U.S.C. § 512(c)(3), including: (a) a description of the '
                'copyrighted work claimed to have been infringed; (b) the '
                'location of the infringing material; (c) your contact '
                'information; (d) a statement that you have a good faith belief '
                'the use is not authorized; and (e) a statement under penalty '
                'of perjury that the information is accurate.\n\n'
                '11.4  Open-Source Components. The App may incorporate '
                'open-source software components subject to their own licenses. '
                'Nothing in these Terms restricts your rights under those '
                'open-source licenses. A list of open-source components is '
                'available at legal@clair.app upon request.'),

            _section(context, '12. Subscriptions, Fees, and Payments',
                '12.1  Free and Paid Tiers. CLAiR may offer both free and '
                'paid subscription tiers. Paid tiers may unlock premium '
                'features, increased usage limits, access to additional AI '
                'models, or enhanced Lawyer Directory access.\n\n'
                '12.2  Pricing. Subscription fees, billing cycles, and payment '
                'methods are displayed in the App at the time of subscription. '
                'CLAiR reserves the right to change pricing at any time with '
                'at least thirty (30) days\' advance notice. Continued use of '
                'a paid subscription after a price change takes effect '
                'constitutes acceptance of the new pricing.\n\n'
                '12.3  Billing. Subscription fees are billed in advance on '
                'a recurring basis (monthly or annually, as selected). You '
                'authorize CLAiR or its payment processor to charge your '
                'designated payment method automatically on each renewal date.\n\n'
                '12.4  Cancellation and Refunds. You may cancel your '
                'subscription at any time through the App settings. '
                'Cancellation takes effect at the end of the current billing '
                'period; you will not receive a refund for the unused portion '
                'of a billing period, except where required by Applicable Law. '
                'For users in the European Union, a statutory 14-day cooling-off '
                'period may apply to digital service subscriptions under '
                'Directive 2011/83/EU.\n\n'
                '12.5  Taxes. Subscription fees are exclusive of applicable '
                'taxes. You are responsible for all taxes, levies, or duties '
                'imposed by taxing authorities in connection with your purchase, '
                'excluding taxes based on CLAiR\'s net income.\n\n'
                '12.6  Failed Payments. If a payment fails, CLAiR may suspend '
                'access to premium features and will attempt to notify you '
                'via email. If payment is not received within fifteen (15) '
                'days, the subscription may be downgraded to the free tier.'),

            _section(context, '13. Lawyer Directory and Referral Services',
                '13.1  Directory Nature. The CLAiR Lawyer Directory is an '
                'informational listing of independently licensed legal '
                'professionals who have voluntarily registered on the Platform. '
                'The Directory is provided for informational purposes only '
                'and does not constitute a legal referral service, a lawyer '
                'referral service as defined by any state bar association, '
                'or an endorsement of any listed attorney.\n\n'
                '13.2  No Vetting or Verification. CLAiR does not: (a) verify '
                'that listed lawyers are currently licensed and in good '
                'standing with their respective bar associations; (b) conduct '
                'background checks or review disciplinary histories; (c) '
                'evaluate competence, experience, or qualifications; or '
                '(d) supervise the quality of legal services provided. You '
                'are solely responsible for verifying a lawyer\'s credentials '
                'through official sources such as your state bar\'s attorney '
                'search tool before engaging their services.\n\n'
                '13.3  No Fee-Splitting. CLAiR does not engage in fee-splitting '
                'with listed lawyers. Any appearance in the Directory does not '
                'constitute a pecuniary arrangement that would violate ABA '
                'Model Rule 5.4 (Professional Independence of a Lawyer) or '
                'equivalent rules. Directory listing fees, if any, are flat '
                'technology service fees only.\n\n'
                '13.4  Consultation Disclaimer. Scheduling a consultation '
                'through the App does not, by itself, establish an '
                'attorney-client relationship. An attorney-client relationship '
                'is formed only when: (a) you and the attorney reach an '
                'explicit agreement on the scope of representation; and '
                '(b) the attorney agrees to represent you, typically '
                'evidenced by a signed retainer agreement or engagement letter.\n\n'
                '13.5  Conflicts of Interest. Lawyers listed on the Platform '
                'are independently responsible for conducting conflict-of-interest '
                'checks before agreeing to represent you, as required by ABA '
                'Model Rule 1.7 (Conflict of Interest). CLAiR does not conduct '
                'or assist with conflict checks.\n\n'
                '13.6  Regulated Advertising. Lawyer advertising is regulated '
                'by state and national bar associations. Listed lawyers are '
                'responsible for ensuring their Directory profiles comply with '
                'applicable advertising rules, including ABA Model Rules 7.1–7.5 '
                'and equivalent rules in their jurisdictions. CLAiR reserves '
                'the right to remove profiles that we reasonably believe '
                'violate these standards.'),

            _section(context, '14. Third-Party Services and Integrations',
                '14.1  Third-Party Services. The App integrates with '
                'third-party services to provide authentication, infrastructure, '
                'and other functionality, including:\n\n'
                '(a) Google LLC — Firebase Authentication, Firebase Realtime '
                'Database, and Google Sign-In. Use of these services is subject '
                'to Google\'s Terms of Service (https://policies.google.com/terms) '
                'and Google\'s Privacy Policy (https://policies.google.com/privacy);\n'
                '(b) Cloud AI Providers — AI processing may be handled by '
                'third-party AI infrastructure providers under data processing '
                'agreements with appropriate confidentiality and security '
                'obligations;\n'
                '(c) Payment Processors — if you purchase a subscription, '
                'payment processing is handled by a third-party processor '
                'subject to PCI DSS compliance standards;\n'
                '(d) Analytics Services — CLAiR may use anonymized analytics '
                'services to improve the App.\n\n'
                '14.2  Third-Party Links. The App may contain links to '
                'third-party websites, resources, or legal databases. These '
                'links are provided for convenience only. CLAiR does not '
                'endorse, control, or assume responsibility for the content, '
                'privacy practices, or accuracy of any third-party site. '
                'Access to third-party sites is at your own risk and subject '
                'to those sites\' terms.\n\n'
                '14.3  No Liability for Third Parties. CLAiR is not responsible '
                'for the actions, omissions, errors, or misconduct of any '
                'third-party service provider, including listed lawyers, '
                'payment processors, or AI infrastructure providers.'),

            _section(context, '15. Privacy and Data Protection',
                '15.1  Privacy Policy. Your use of the App is subject to '
                'CLAiR\'s Privacy Policy, which is incorporated into these '
                'Terms by reference. The Privacy Policy explains how we '
                'collect, use, share, and protect personal data.\n\n'
                '15.2  Applicable Privacy Laws. CLAiR processes personal data '
                'in compliance with applicable privacy laws including:\n\n'
                '(a) General Data Protection Regulation (GDPR), '
                'Regulation (EU) 2016/679 — for users in the European '
                'Economic Area;\n'
                '(b) Philippine Data Privacy Act of 2012 (Republic Act '
                'No. 10173) and its Implementing Rules and Regulations — '
                'for users in the Philippines;\n'
                '(c) California Consumer Privacy Act (CCPA) / California '
                'Privacy Rights Act (CPRA), Cal. Civ. Code § 1798.100 '
                'et seq. — for California residents;\n'
                '(d) Children\'s Online Privacy Protection Act (COPPA), '
                '15 U.S.C. §§ 6501–6506;\n'
                '(e) CAN-SPAM Act, 15 U.S.C. § 7701 et seq.;\n'
                '(f) Other applicable national and state/provincial privacy '
                'laws in jurisdictions where the App is used.\n\n'
                '15.3  Data Subject Rights. Depending on your jurisdiction, '
                'you may have rights to access, correct, delete, port, or '
                'restrict the processing of your personal data. See our '
                'Privacy Policy or contact privacy@clair.app to exercise '
                'these rights.'),

            _section(context, '16. Security',
                '16.1  Security Measures. CLAiR implements technical and '
                'organizational security measures designed to protect your '
                'personal data and User Content from unauthorized access, '
                'alteration, disclosure, or destruction. These measures '
                'include encryption in transit (TLS/SSL), encryption at '
                'rest, access controls, and periodic security assessments.\n\n'
                '16.2  No Guarantee. Despite our security measures, no '
                'method of electronic transmission or storage is one hundred '
                'percent (100%) secure. CLAiR cannot guarantee the absolute '
                'security of your data and is not liable for unauthorized '
                'access, use, alteration, or disclosure of your personal data '
                'that results from circumstances beyond our reasonable control.\n\n'
                '16.3  Security Breach Notification. In the event of a data '
                'breach involving your personal data, CLAiR will notify '
                'affected users and relevant regulatory authorities as required '
                'by Applicable Law, including: (a) GDPR Article 33 and 34 — '
                '72-hour notification to supervisory authority and, where '
                'required, to affected data subjects; (b) Philippine DPA '
                '(R.A. 10173) Section 20 — notification to the National '
                'Privacy Commission and affected data subjects within '
                '72 hours.\n\n'
                '16.4  Your Security Responsibilities. You are responsible '
                'for: (a) keeping your password and account credentials '
                'secure; (b) not using the same password on multiple services; '
                '(c) logging out of shared or public devices; and '
                '(d) reporting any unauthorized account activity immediately '
                'to security@clair.app.'),

            _section(context, '17. Emergency Services Disclaimer',
                'THE APP CANNOT BE USED TO CONTACT EMERGENCY SERVICES. IF '
                'YOU OR ANOTHER PERSON IS IN IMMEDIATE DANGER OR FACING AN '
                'EMERGENCY SITUATION — INCLUDING A LEGAL EMERGENCY SUCH AS '
                'AN ARREST — DO NOT USE THIS APP. INSTEAD:\n\n'
                '• Call your local emergency number (911 in the U.S., 911 '
                'in the Philippines, 112 in the EU)\n'
                '• Contact law enforcement directly\n'
                '• If you have been arrested, invoke your right to remain '
                'silent and your right to an attorney before answering any '
                'questions\n\n'
                'CLAiR assumes no liability for any failure to provide '
                'emergency assistance through the App.'),

            _section(context, '18. Disclaimer of Warranties',
                '18.1  "As Is" Basis. TO THE MAXIMUM EXTENT PERMITTED BY '
                'APPLICABLE LAW, THE APP AND ALL CONTENT, FEATURES, AND '
                'SERVICES PROVIDED THROUGH IT ARE OFFERED ON AN "AS IS," '
                '"AS AVAILABLE," AND "WITH ALL FAULTS" BASIS, WITHOUT '
                'WARRANTY OF ANY KIND.\n\n'
                '18.2  Express Disclaimer. CLAIR EXPRESSLY DISCLAIMS ALL '
                'WARRANTIES, WHETHER EXPRESS, IMPLIED, STATUTORY, OR '
                'OTHERWISE, INCLUDING WITHOUT LIMITATION:\n\n'
                '(a) IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A '
                'PARTICULAR PURPOSE, AND NON-INFRINGEMENT;\n'
                '(b) WARRANTIES THAT THE APP WILL MEET YOUR REQUIREMENTS '
                'OR EXPECTATIONS;\n'
                '(c) WARRANTIES THAT THE APP WILL BE UNINTERRUPTED, '
                'TIMELY, SECURE, OR ERROR-FREE;\n'
                '(d) WARRANTIES REGARDING THE ACCURACY, RELIABILITY, '
                'COMPLETENESS, OR CURRENCY OF ANY AI-GENERATED CONTENT;\n'
                '(e) WARRANTIES THAT ANY ERRORS OR DEFECTS WILL BE '
                'CORRECTED;\n'
                '(f) WARRANTIES REGARDING RESULTS THAT MAY BE OBTAINED '
                'FROM USE OF THE APP;\n'
                '(g) WARRANTIES THAT AI-GENERATED CONTENT CONSTITUTES '
                'COMPETENT OR ACCURATE LEGAL ANALYSIS UNDER ANY '
                'JURISDICTION\'S STANDARDS.\n\n'
                '18.3  Jurisdictional Limits. CERTAIN CONSUMER PROTECTION '
                'STATUTES AND REGULATIONS IN SOME JURISDICTIONS (INCLUDING '
                'CONSUMER LAWS IN EU MEMBER STATES AND THE PHILIPPINE '
                'CONSUMER ACT, REPUBLIC ACT NO. 7394) PROVIDE MANDATORY '
                'WARRANTIES AND PROTECTIONS THAT CANNOT BE EXCLUDED BY '
                'CONTRACT. NOTHING IN THESE TERMS IS INTENDED TO LIMIT '
                'SUCH MANDATORY PROTECTIONS WHERE THEY APPLY.'),

            _section(context, '19. Limitation of Liability',
                '19.1  Exclusion of Certain Damages. TO THE MAXIMUM EXTENT '
                'PERMITTED BY APPLICABLE LAW, IN NO EVENT SHALL CLAIR '
                'TECHNOLOGIES, INC., ITS PARENT COMPANIES, SUBSIDIARIES, '
                'AFFILIATES, OFFICERS, DIRECTORS, SHAREHOLDERS, EMPLOYEES, '
                'AGENTS, CONTRACTORS, LICENSORS, OR SERVICE PROVIDERS BE '
                'LIABLE FOR:\n\n'
                '(a) ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, '
                'EXEMPLARY, OR PUNITIVE DAMAGES;\n'
                '(b) LOSS OF PROFITS, REVENUE, DATA, BUSINESS OPPORTUNITIES, '
                'GOODWILL, OR ANTICIPATED SAVINGS;\n'
                '(c) PHYSICAL, REPUTATIONAL, OR LEGAL HARM RESULTING FROM '
                'RELIANCE ON AI-GENERATED CONTENT;\n'
                '(d) COSTS OF SUBSTITUTE LEGAL SERVICES NECESSITATED BY '
                'INACCURATE AI-GENERATED CONTENT;\n'
                '(e) DAMAGES RESULTING FROM UNAUTHORIZED ACCESS TO OR '
                'ALTERATION OF YOUR TRANSMISSIONS, ACCOUNT, OR DATA;\n'
                '(f) DAMAGES RESULTING FROM CONDUCT OF ANY LAWYER LISTED '
                'IN THE DIRECTORY;\n'
                '(g) ANY OTHER MATTER RELATING TO THE APP;\n\n'
                'WHETHER BASED IN CONTRACT, TORT (INCLUDING NEGLIGENCE), '
                'STRICT LIABILITY, STATUTE, OR ANY OTHER LEGAL THEORY, '
                'EVEN IF CLAIR HAS BEEN ADVISED OF THE POSSIBILITY OF '
                'SUCH DAMAGES.\n\n'
                '19.2  Liability Cap. TO THE MAXIMUM EXTENT PERMITTED BY '
                'APPLICABLE LAW, CLAIR\'S AGGREGATE LIABILITY FOR ALL CLAIMS '
                'ARISING OUT OF OR RELATED TO THESE TERMS OR THE APP SHALL '
                'NOT EXCEED THE GREATER OF: (a) THE AMOUNT YOU PAID TO '
                'CLAIR IN THE TWELVE (12) MONTHS PRECEDING THE CLAIM; OR '
                '(b) ONE HUNDRED U.S. DOLLARS (USD \$100.00).\n\n'
                '19.3  Essential Basis. YOU ACKNOWLEDGE THAT THE DISCLAIMERS '
                'AND LIMITATIONS OF LIABILITY IN THIS SECTION REFLECT A '
                'REASONABLE AND FAIR ALLOCATION OF RISK BETWEEN THE PARTIES, '
                'AND THAT CLAIR WOULD NOT PROVIDE THE APP WITHOUT SUCH '
                'LIMITATIONS.\n\n'
                '19.4  Mandatory Rights. NOTHING IN THESE TERMS LIMITS OR '
                'EXCLUDES LIABILITY FOR DEATH OR PERSONAL INJURY CAUSED BY '
                'NEGLIGENCE, FOR FRAUD OR FRAUDULENT MISREPRESENTATION, OR '
                'FOR ANY LIABILITY THAT CANNOT BE EXCLUDED OR LIMITED UNDER '
                'APPLICABLE LAW.'),

            _section(context, '20. Indemnification',
                '20.1  Your Indemnification Obligation. To the fullest extent '
                'permitted by Applicable Law, you agree to defend, indemnify, '
                'and hold harmless CLAiR Technologies, Inc. and its parent '
                'companies, subsidiaries, affiliates, officers, directors, '
                'shareholders, employees, agents, contractors, licensors, '
                'and successors ("Indemnitees") from and against any and all '
                'claims, actions, demands, proceedings, losses, liabilities, '
                'damages, settlements, penalties, fines, costs, and expenses '
                '(including reasonable attorneys\' fees and court costs) '
                'arising out of or relating to:\n\n'
                '(a) Your breach of any representation, warranty, obligation, '
                'or covenant in these Terms;\n'
                '(b) Your User Content or your use of AI-Generated Content;\n'
                '(c) Your violation of any Applicable Law, including '
                'professional conduct rules;\n'
                '(d) Your violation of any third-party right, including '
                'intellectual property rights or privacy rights;\n'
                '(e) Any claim that your User Content caused damage to a '
                'third party;\n'
                '(f) Your misuse of the App in any manner.\n\n'
                '20.2  Indemnification Procedure. CLAiR will: (a) notify '
                'you promptly in writing of any claim for which '
                'indemnification is sought; (b) give you reasonable control '
                'over the defense and settlement of such claim; and '
                '(c) provide you with reasonable assistance, at your expense. '
                'You may not settle any claim that imposes any obligation, '
                'liability, or restriction on CLAiR without CLAiR\'s prior '
                'written consent.'),

            _section(context, '21. Arbitration, Governing Law, and Dispute Resolution',
                '21.1  Governing Law. These Terms shall be governed by and '
                'construed in accordance with the laws of the Republic of '
                'the Philippines, without regard to conflict-of-law principles, '
                'including:\n\n'
                '• Civil Code of the Philippines (Republic Act No. 386)\n'
                '• Electronic Commerce Act (Republic Act No. 8792)\n'
                '• Data Privacy Act of 2012 (Republic Act No. 10173)\n'
                '• Consumer Act of the Philippines (Republic Act No. 7394)\n'
                '• Alternative Dispute Resolution Act (Republic Act No. 9285)\n\n'
                'For users in the United States, applicable federal law and '
                'the laws of the state in which you reside may also apply. '
                'EU users additionally benefit from mandatory consumer '
                'protection rights under EU law, which shall not be displaced '
                'by the choice of Philippine law.\n\n'
                '21.2  Informal Resolution. Before initiating formal dispute '
                'resolution, you agree to first contact CLAiR at '
                'legal@clair.app and attempt to resolve the dispute informally '
                'by good-faith negotiation for a period of not less than '
                'thirty (30) days.\n\n'
                '21.3  Binding Arbitration. If informal resolution fails, '
                'any dispute, controversy, or claim arising out of or relating '
                'to these Terms or the App (excluding small claims, IP '
                'infringement claims, and emergency injunctive relief) shall '
                'be finally resolved by binding arbitration in accordance '
                'with the Philippine Arbitration Rules and the Alternative '
                'Dispute Resolution Act (R.A. 9285). For users in the U.S., '
                'arbitration will be conducted under the AAA Consumer '
                'Arbitration Rules. The arbitrator\'s decision will be final '
                'and binding.\n\n'
                '21.4  Class Action Waiver. TO THE FULLEST EXTENT PERMITTED '
                'BY APPLICABLE LAW, YOU WAIVE YOUR RIGHT TO BRING OR '
                'PARTICIPATE IN ANY CLASS ACTION LAWSUIT, CLASS-WIDE '
                'ARBITRATION, OR REPRESENTATIVE PROCEEDING AGAINST CLAIR '
                'OR ITS AFFILIATES. ALL DISPUTES MUST BE BROUGHT ON AN '
                'INDIVIDUAL BASIS ONLY.\n\n'
                '21.5  EU Dispute Resolution. If you are a consumer in the '
                'European Union, you may also use the EU Online Dispute '
                'Resolution platform at https://ec.europa.eu/consumers/odr/ '
                'or contact your national consumer dispute resolution body. '
                'EU consumer mandatory rights are not affected by the '
                'arbitration clause.\n\n'
                '21.6  Venue for Non-Arbitrable Claims. For any claims not '
                'subject to arbitration, you consent to the exclusive '
                'jurisdiction of the courts of competent jurisdiction in '
                'Metro Manila, Philippines. For U.S. users, venue lies in '
                'the federal or state courts of the applicable U.S. '
                'jurisdiction.'),

            _section(context, '22. Termination and Suspension',
                '22.1  CLAiR\'s Right to Terminate. CLAiR may, at its sole '
                'discretion, suspend, restrict, or terminate your account '
                'and access to the App at any time, with or without cause '
                'and with or without notice, for conduct that CLAiR believes '
                'violates these Terms, poses a risk to other users or third '
                'parties, involves fraudulent or illegal activity, or '
                'jeopardizes the security or integrity of the App. Grounds '
                'for immediate termination include:\n\n'
                '(a) Material breach of these Terms;\n'
                '(b) Submission of false or fraudulent information;\n'
                '(c) Commission of a crime using or in connection with the App;\n'
                '(d) Harassment or threatening behavior toward CLAiR staff '
                'or other users;\n'
                '(e) Chargebacks or payment fraud;\n'
                '(f) Violation of any court order or regulatory directive.\n\n'
                '22.2  Your Right to Terminate. You may delete your account '
                'at any time through Settings → Security → Delete Account. '
                'Deletion is subject to the terms in our Privacy Policy '
                'regarding data retention, including any data we are required '
                'to retain by law.\n\n'
                '22.3  Effect of Termination. Upon any termination: (a) your '
                'license to use the App immediately terminates; (b) you must '
                'cease all use of the App; (c) CLAiR may delete your account '
                'data in accordance with our Privacy Policy; and (d) any '
                'outstanding payment obligations remain due. Sections that '
                'by their nature should survive termination — including '
                'Sections 4, 5, 8, 9, 10, 11, 18, 19, 20, 21, and 26 — '
                'shall survive indefinitely.\n\n'
                '22.4  Appeals. If you believe your account was terminated '
                'in error, you may appeal by contacting legal@clair.app '
                'within thirty (30) days of termination. CLAiR will review '
                'the appeal and respond within fifteen (15) business days.'),

            _section(context, '23. Modifications to Service and Terms',
                '23.1  Service Changes. CLAiR continuously evolves the App '
                'and reserves the right to: (a) add, modify, or remove features; '
                '(b) change the user interface or underlying technology; '
                '(c) impose new usage limits; (d) suspend or discontinue the '
                'App or any portion thereof; and (e) introduce new terms '
                'governing new features.\n\n'
                '23.2  Notice of Material Changes. For material changes to '
                'these Terms, CLAiR will provide at least thirty (30) days\' '
                'advance notice where reasonably practicable, except where '
                'immediate change is required for legal, security, or '
                'regulatory reasons.\n\n'
                '23.3  Acceptance After Notice. Your continued access to or '
                'use of the App after the effective date of any modification '
                'constitutes your binding acceptance of the new Terms. If '
                'you do not agree to the modified Terms, you must stop using '
                'the App and delete your account.'),

            _section(context, '24. Export Controls and Trade Compliance',
                '24.1  Export Control Laws. The App and any AI-Generated '
                'Content may be subject to export control laws and regulations '
                'of the United States, the Philippines, the European Union, '
                'and other applicable jurisdictions, including the U.S. Export '
                'Administration Regulations (EAR, 15 C.F.R. Parts 730–774), '
                'the U.S. Office of Foreign Assets Control (OFAC) sanctions '
                'regulations, and the EU Dual-Use Regulation (Regulation (EU) '
                '2021/821).\n\n'
                '24.2  Compliance Obligation. You agree not to export, '
                're-export, transfer, or use the App or any AI-Generated '
                'Content in violation of any applicable export control law '
                'or trade sanction. You represent and warrant that: (a) you '
                'are not located in or a resident of any country subject to '
                'comprehensive U.S., EU, or UN sanctions; (b) you are not '
                'listed on any U.S. or EU denied parties list, including '
                'OFAC\'s Specially Designated Nationals (SDN) List; and '
                '(c) your use of the App does not violate any applicable '
                'export control law.\n\n'
                '24.3  Anti-Corruption. You agree to comply with all '
                'applicable anti-bribery and anti-corruption laws, including '
                'the U.S. Foreign Corrupt Practices Act (FCPA), the UK '
                'Bribery Act 2010, and the Philippine Anti-Graft and Corrupt '
                'Practices Act (Republic Act No. 3019).'),

            _section(context, '25. Regulatory Compliance and AI Governance',
                '25.1  Regulatory Framework. CLAiR is committed to responsible '
                'AI development and compliance with applicable regulations '
                'governing AI-assisted technology platforms and legal '
                'information services, including:\n\n'
                '(a) EU Artificial Intelligence Act (Regulation (EU) 2024/1689) '
                '— CLAiR classifies its AI systems, implements transparency '
                'obligations, and maintains technical documentation as required;\n'
                '(b) GDPR and EU data protection law — applicable to users in '
                'the EEA, including data minimization, purpose limitation, '
                'and automated decision-making provisions (Article 22);\n'
                '(c) Philippine Data Privacy Act (R.A. 10173) — including '
                'NPC registration, privacy impact assessments, and data breach '
                'notification obligations;\n'
                '(d) California Consumer Privacy Act / CPRA — including the '
                'right to opt out of sale of personal information, the right '
                'to correct, and the right to limit use of sensitive personal '
                'information;\n'
                '(e) ABA Model Rules of Professional Conduct — serving as '
                'informational guidance for professional responsibility '
                'compliance by lawyers using the Platform;\n'
                '(f) Bar Association Advertising Rules — CLAiR requires '
                'lawyers listed in the Directory to comply with applicable '
                'advertising and solicitation rules;\n'
                '(g) Consumer Protection Laws — including the Philippine '
                'Consumer Act (R.A. 7394) and EU Consumer Rights Directive '
                '(Directive 2011/83/EU).\n\n'
                '25.2  AI Transparency. CLAiR discloses that: (a) responses '
                'you receive are generated by AI, not human legal professionals; '
                '(b) AI-Generated Content may be reviewed or filtered by '
                'automated systems; and (c) CLAiR maintains a human oversight '
                'mechanism for AI system performance monitoring.\n\n'
                '25.3  Non-Discrimination. CLAiR is committed to ensuring '
                'that its AI systems do not unlawfully discriminate against '
                'users on the basis of race, color, religion, national origin, '
                'sex, disability, age, or other protected characteristics '
                'under applicable civil rights laws, including 42 U.S.C. '
                '§ 1981 et seq., the Philippine Magna Carta of Women '
                '(R.A. 9710), and EU non-discrimination directives.'),

            _section(context, '26. Accessibility',
                'CLAiR is committed to making the App accessible to users '
                'with disabilities in compliance with applicable accessibility '
                'standards, including:\n\n'
                '• The Americans with Disabilities Act (ADA), 42 U.S.C. '
                '§ 12101 et seq., and Section 508 of the Rehabilitation Act;\n'
                '• The Web Content Accessibility Guidelines (WCAG) 2.1, '
                'Level AA, published by the World Wide Web Consortium (W3C);\n'
                '• The EU Web Accessibility Directive (Directive (EU) 2016/2102);\n'
                '• The Philippine Magna Carta for Disabled Persons '
                '(Republic Act No. 7277).\n\n'
                'If you encounter accessibility barriers in the App, please '
                'contact us at accessibility@clair.app and we will make '
                'reasonable efforts to accommodate your needs.'),

            _section(context, '27. Miscellaneous Provisions',
                '27.1  Entire Agreement. These Terms, together with the '
                'Privacy Policy and any supplemental terms, guidelines, or '
                'policies referenced herein, constitute the entire agreement '
                'between you and CLAiR with respect to the App and supersede '
                'all prior agreements, representations, warranties, and '
                'understandings, whether written or oral.\n\n'
                '27.2  Severability. If any provision of these Terms is found '
                'to be invalid, illegal, or unenforceable under Applicable Law, '
                'that provision will be modified to the minimum extent necessary '
                'to make it enforceable, and the remaining provisions will '
                'continue in full force and effect.\n\n'
                '27.3  No Waiver. No failure or delay by CLAiR in exercising '
                'any right, power, or privilege under these Terms shall operate '
                'as a waiver of that right. No single or partial exercise of '
                'any right precludes any other or further exercise of that '
                'right or the exercise of any other right.\n\n'
                '27.4  Assignment. You may not assign or transfer any rights '
                'or obligations under these Terms without CLAiR\'s prior '
                'written consent. CLAiR may assign these Terms or any rights '
                'hereunder at any time without your consent in connection with '
                'a merger, acquisition, corporate reorganization, or sale of '
                'substantially all of its assets.\n\n'
                '27.5  Force Majeure. CLAiR shall not be liable for any '
                'failure or delay in performance under these Terms to the '
                'extent caused by circumstances beyond our reasonable control, '
                'including acts of God, natural disasters, pandemics, war, '
                'terrorism, cyberattacks, governmental actions, internet '
                'disruptions, or other force majeure events. CLAiR will use '
                'reasonable efforts to resume performance as soon as '
                'practicable.\n\n'
                '27.6  Relationship of Parties. Nothing in these Terms '
                'creates any partnership, joint venture, agency, employment, '
                'or franchise relationship between you and CLAiR.\n\n'
                '27.7  Notices. CLAiR may provide notices under these Terms '
                'by: (a) posting on the App; (b) sending email to the address '
                'associated with your account; or (c) in-app notifications. '
                'You may send legal notices to CLAiR at legal@clair.app or '
                'to the address listed in Section 28. Notices are effective '
                'upon posting or email transmission.\n\n'
                '27.8  Language. These Terms are written in English. If '
                'these Terms are translated into another language and there '
                'is a conflict between the English version and the translation, '
                'the English version shall prevail.\n\n'
                '27.9  Headings. Section headings in these Terms are for '
                'convenience only and do not affect the interpretation '
                'of any provision.\n\n'
                '27.10  No Third-Party Beneficiaries. These Terms are for '
                'the sole benefit of CLAiR and its permitted assignees and '
                'you. Nothing in these Terms shall create or be deemed to '
                'create any right in any third party.'),

            _section(context, '28. Contact Information',
                'If you have any questions or concerns about these Terms, '
                'please reach out to us:\n\n'
                'Email: clair.support@email.com\n\n'
                'We will do our best to respond as soon as possible.'),

          ],
        ),
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────────

  Widget _header(BuildContext context, String title, String subtitle) {
    final cl = context.c;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cl.accent.withOpacity(0.14), cl.accentLight.withOpacity(0.2)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cl.accent.withOpacity(0.28)),
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
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.nunito(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: cl.textMid,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _alert(BuildContext context, String title, String body) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFB91C1C),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFB91C1C),
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cl.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cl.border),
        boxShadow: [
          BoxShadow(
            color: cl.cardShadow,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: cl.textDark,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            body,
            style: GoogleFonts.nunito(
              fontSize: 12.5,
              color: cl.textMid,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
