import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:clair/app/main_shell_tab.dart';
import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/appointments/domain/entities/appointment_entity.dart';
import 'package:clair/features/appointments/presentation/providers/appointment_provider.dart';
import 'package:clair/features/appointments/presentation/screens/appointment_detail_screen.dart';
import 'package:clair/shared/widgets/clair_app_bar.dart';
import 'package:clair/shared/widgets/spring_button.dart';

class AppointmentTabScreen extends ConsumerStatefulWidget {
  const AppointmentTabScreen({super.key});

  @override
  ConsumerState<AppointmentTabScreen> createState() =>
      _AppointmentTabScreenState();
}

class _AppointmentTabScreenState extends ConsumerState<AppointmentTabScreen> {
  static const int _tabIndex = 4;

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(appointmentProvider.notifier).loadAppointments());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(mainShellTabProvider, (prev, next) {
      if (next == _tabIndex) {
        ref.read(appointmentProvider.notifier).loadAppointments();
      }
    });

    ref.listen<AppointmentState>(appointmentProvider, (prev, next) {
      if (next.error != null && prev?.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red.shade700,
          ),
        );
        ref.read(appointmentProvider.notifier).clearError();
      }
    });

    final state = ref.watch(appointmentProvider);

    return Column(
      children: [
        const ClairAppBar(),
        Expanded(child: _buildBody(state)),
      ],
    );
  }

  Widget _buildBody(AppointmentState state) {
    final cl = context.c;

    if (state.isLoading && state.appointments.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: cl.accent),
      );
    }

    final all = state.appointments;

    if (all.isEmpty) {
      return _buildEmptyState();
    }

    // Group appointments
    final active = all
        .where((a) => a.status == 'confirmed' || a.status == 'pending')
        .toList();
    final past = all.where((a) => a.status == 'cancelled').toList();

    return RefreshIndicator(
      color: cl.accent,
      onRefresh: () =>
          ref.read(appointmentProvider.notifier).loadAppointments(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Appointments',
                    style: GoogleFonts.nunito(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: cl.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${all.length} appointment${all.length == 1 ? '' : 's'} total',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: cl.textMid,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (active.isNotEmpty) ...[
            _buildSectionHeader('Active & Pending', active.length),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AppointmentCard(
                      appointment: active[i],
                      onTap: () => _openDetail(active[i]),
                    ),
                  ),
                  childCount: active.length,
                ),
              ),
            ),
          ],

          if (past.isNotEmpty) ...[
            _buildSectionHeader('Past / Rejected', past.length),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AppointmentCard(
                      appointment: past[i],
                      onTap: () => _openDetail(past[i]),
                      muted: true,
                    ),
                  ),
                  childCount: past.length,
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    final cl = context.c;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            Text(
              title,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cl.textMid,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: cl.fieldBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cl.textMid,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(AppointmentEntity appt) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AppointmentDetailScreen(appointment: appt),
      ),
    );
  }

  Widget _buildEmptyState() {
    final cl = context.c;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cl.accent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_note_rounded,
              size: 38,
              color: cl.accent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No appointments yet',
            style: GoogleFonts.nunito(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: cl.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Book a lawyer consultation and\ntrack your status here',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: cl.textMid,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Appointment card ──────────────────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.onTap,
    this.muted = false,
  });

  final AppointmentEntity appointment;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final statusColor = _statusColor(appointment.status);
    final date = DateFormat('MMM d, y').format(appointment.appointmentDate);
    final time = _to12Hour(appointment.appointmentTime);

    return SpringButton(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cl.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cl.border),
          boxShadow: [
            BoxShadow(
              color: cl.cardShadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
          children: [
            // Colored status strip
            Container(
              width: 4,
              constraints: const BoxConstraints(minHeight: 72),
              decoration: BoxDecoration(
                color: muted
                    ? statusColor.withValues(alpha: 0.35)
                    : statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appointment.displayCaseTitle,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: muted
                                      ? cl.textDark.withValues(alpha: 0.5)
                                      : cl.textDark,
                                  fontFamily: 'Satoshi',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                appointment.displayLawyerName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cl.textMid,
                                  fontFamily: 'Satoshi',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusPill(
                          status: appointment.status,
                          muted: muted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: cl.textLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$date  •  $time',
                          style: TextStyle(
                            fontSize: 12,
                            color: cl.textMid,
                            fontFamily: 'Satoshi',
                          ),
                        ),
                        const Spacer(),
                        if (appointment.canStartLawyerChat)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: cl.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_rounded,
                                  size: 11,
                                  color: cl.accent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Chat',
                                  style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: cl.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: cl.textLight,
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  static Color _statusColor(String status) {
    return switch (status) {
      'confirmed' => const Color(0xFF22A64A),
      'pending' => const Color(0xFFE59300),
      'cancelled' => const Color(0xFFD63031),
      _ => const Color(0xFF6B7280),
    };
  }

  static String _to12Hour(String value) {
    try {
      final parsed = DateFormat('HH:mm').parse(value);
      return DateFormat('h:mm a').format(parsed);
    } catch (_) {
      return value;
    }
  }
}

// ── Status pill ───────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, this.muted = false});

  final String status;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final (Color bg, Color fg, String label) = switch (status) {
      'pending' => (
          const Color(0xFFFFF4DE),
          const Color(0xFFB26A00),
          'Pending',
        ),
      'confirmed' => (
          const Color(0xFFE9F9EE),
          const Color(0xFF1E7E34),
          'Accepted',
        ),
      'cancelled' => (
          const Color(0xFFFFEAEA),
          const Color(0xFFB02A37),
          'Rejected',
        ),
      _ => (cl.fieldBg, cl.textMid, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: muted ? bg.withValues(alpha: 0.5) : bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: muted ? fg.withValues(alpha: 0.6) : fg,
        ),
      ),
    );
  }
}
