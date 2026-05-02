import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
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
            _section(context, '1. Data We Collect',
                'We collect account details, chat content, and usage data needed to provide and improve CLAiR features.'),
            _section(context, '2. How We Use Data',
                'We use data to operate the service, personalize experience, and maintain safety and quality.'),
            _section(context, '3. Data Sharing',
                'We do not sell personal data. Data may be shared with service providers strictly for app operation.'),
            _section(context, '4. Data Retention',
                'We retain data only as long as needed for service delivery, legal obligations, and security monitoring.'),
            _section(context, '5. Your Choices',
                'You may request account updates or deletion according to applicable law and platform support.'),
            _section(context, '6. Contact',
                'If you have privacy questions, contact support through settings.'),
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
