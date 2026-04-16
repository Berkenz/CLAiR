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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section(context, '1. Acceptance',
                'By using CLAiR, you agree to these Terms. If you do not agree, please stop using the app.'),
            _section(context, '2. Informational Use',
                'CLAiR provides general legal information and workflow support. It is not a lawyer and does not create an attorney-client relationship.'),
            _section(context, '3. User Responsibilities',
                'You agree not to submit unlawful content, impersonate others, or misuse the platform.'),
            _section(context, '4. Account and Access',
                'You are responsible for maintaining account security and all actions taken under your account.'),
            _section(context, '5. Changes to Service',
                'We may update, pause, or discontinue features at any time to improve reliability and safety.'),
            _section(context, '6. Contact',
                'For questions about these Terms, contact support through the app settings.'),
          ],
        ),
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
            style: GoogleFonts.nunito(fontSize: 13, color: cl.textMid, height: 1.4),
          ),
        ],
      ),
    );
  }
}
