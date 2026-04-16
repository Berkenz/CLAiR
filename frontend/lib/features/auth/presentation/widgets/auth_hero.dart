import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';

class AuthHeroPanel extends StatelessWidget {
  final String headline;
  final String subtext;
  final bool showBack;

  const AuthHeroPanel({
    super.key,
    required this.headline,
    required this.subtext,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final cl = context.c;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3ECF0), Color(0xFFF0E8EC), Color(0xFFEDE3E8)],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, topPad + 28, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showBack)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: cl.surface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.arrow_back_rounded, color: cl.textDark, size: 20),
                ),
              )
            else
              Row(children: [
                SizedBox(width: 24, height: 24,
                  child: Image.asset('assets/images/CLAiR-icon.png', fit: BoxFit.contain,
                      color: cl.accent, colorBlendMode: BlendMode.srcIn)),
                const SizedBox(width: 6),
                Text('clair', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: cl.accentDark)),
              ]),
            const SizedBox(height: 20),
            Text(headline, style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w800, color: cl.textDark, height: 1.15)),
            const SizedBox(height: 4),
            Text(subtext, style: GoogleFonts.nunito(fontSize: 13, color: cl.textMid, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
