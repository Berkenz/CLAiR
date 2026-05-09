import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/lawyer/domain/entities/lawyer_entity.dart';
import 'package:clair/features/lawyer/presentation/sheets/lawyer_booking_sheet.dart';
import 'package:clair/features/lawyer/presentation/sheets/lawyer_concern_sheet.dart';
import 'package:clair/shared/widgets/spring_button.dart';

/// Full professional lawyer profile screen shown before booking.
class LawyerOverviewScreen extends ConsumerWidget {
  const LawyerOverviewScreen({super.key, required this.lawyer});

  final LawyerEntity lawyer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cl = context.c;

    return Scaffold(
      backgroundColor: cl.bg,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          _ProfileHeader(lawyer: lawyer, cl: cl),

          // ── Scrollable body ─────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Practice areas
                  if (lawyer.practiceAreas.isNotEmpty) ...[
                    _SectionTitle(label: 'Practice Areas', cl: cl),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: lawyer.practiceAreas.map((area) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: cl.accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: cl.accent.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            area,
                            style: GoogleFonts.nunito(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: cl.accent,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),
                  ],

                  // About
                  _InfoCard(
                    cl: cl,
                    icon: Icons.person_outline_rounded,
                    title: 'About',
                    child: Text(
                      lawyer.bioOrDefault,
                      style: GoogleFonts.nunito(
                          fontSize: 13.5, height: 1.55, color: cl.textDark),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Office details (Location + Hours side-by-side cards)
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          cl: cl,
                          icon: Icons.location_on_outlined,
                          title: 'Office',
                          compact: true,
                          child: Text(
                            lawyer.officeLocationOrDefault,
                            style: GoogleFonts.nunito(
                                fontSize: 13, height: 1.45, color: cl.textDark),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          cl: cl,
                          icon: Icons.schedule_rounded,
                          title: 'Hours',
                          compact: true,
                          child: Text(
                            lawyer.officeHoursOrDefault,
                            style: GoogleFonts.nunito(
                                fontSize: 13, height: 1.45, color: cl.textDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Disclaimer
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cl.fieldBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cl.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 15, color: cl.textLight),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This directory lists verified, registered lawyers. '
                            'CLAiR does not endorse any listed professional.',
                            style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: cl.textLight,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Action bar ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: cl.surface,
              border: Border(top: BorderSide(color: cl.border)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SpringButton(
                    onTap: () {
                      if (showGuestBookingPrompt(context, ref)) return;
                      showLawyerBookingSheet(context, lawyer);
                    },
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: cl.accent,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: cl.accent.withValues(alpha: 0.22),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 17, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Book appointment',
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cl.textMid,
                        side: BorderSide(color: cl.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => showLawyerConcernSheet(context, lawyer),
                      icon: Icon(Icons.flag_outlined,
                          size: 16, color: cl.textMid),
                      label: Text(
                        'Report concern',
                        style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w600, fontSize: 13.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile header ────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.lawyer, required this.cl});
  final LawyerEntity lawyer;
  final AppColorTheme cl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cl.surface,
        border: Border(bottom: BorderSide(color: cl.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Back row
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_rounded, color: cl.textDark),
                  ),
                  const Spacer(),
                  // Verified badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded,
                            size: 13, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: GoogleFonts.nunito(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Avatar + identity
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cl.accent.withValues(alpha: 0.14),
                          cl.accentLight.withValues(alpha: 0.35),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: cl.accent.withValues(alpha: 0.2), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        lawyer.initials,
                        style: GoogleFonts.nunito(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: cl.accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Name + designation + specialty
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lawyer.name,
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: cl.textDark,
                            height: 1.2,
                          ),
                        ),
                        if (lawyer.designation != null &&
                            lawyer.designation!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: cl.accent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              lawyer.designation!,
                              style: GoogleFonts.nunito(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: cl.accent,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          lawyer.specialty,
                          style: GoogleFonts.nunito(
                            fontSize: 12.5,
                            color: cl.textMid,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable section widgets ──────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label, required this.cl});
  final String label;
  final AppColorTheme cl;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.nunito(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: cl.textLight,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.cl,
    required this.icon,
    required this.title,
    required this.child,
    this.compact = false,
  });

  final AppColorTheme cl;
  final IconData icon;
  final String title;
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: cl.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cl.border),
        boxShadow: [
          BoxShadow(color: cl.cardShadow, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: cl.accent),
              const SizedBox(width: 7),
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: cl.textMid,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
