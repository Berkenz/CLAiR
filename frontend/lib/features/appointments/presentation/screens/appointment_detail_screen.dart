import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:clair/app/main_shell_tab.dart';
import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/appointments/domain/entities/appointment_entity.dart';
import 'package:clair/features/appointments/presentation/screens/lawyer_chat_screen.dart';
import 'package:clair/features/chat/presentation/providers/chat_provider.dart';

class AppointmentDetailScreen extends ConsumerWidget {
  const AppointmentDetailScreen({super.key, required this.appointment});

  final AppointmentEntity appointment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cl = context.c;
    final statusColor = _statusColor(appointment.status);

    return Scaffold(
      backgroundColor: cl.bg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, cl, statusColor),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status banner
                  _StatusBanner(status: appointment.status),
                  const SizedBox(height: 20),

                  // Attached CLAiR conversation (from booking)
                  if (_hasAttachedConversation(appointment)) ...[
                    _AttachedConversationCard(
                      onOpen: () => _openAttachedConversation(
                        context,
                        ref,
                        appointment,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Info card
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: Icons.work_outline_rounded,
                        label: 'Type',
                        value: appointment.appointmentType,
                      ),
                      _divider(cl),
                      _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Date',
                        value: DateFormat('EEEE, MMMM d, y')
                            .format(appointment.appointmentDate),
                      ),
                      _divider(cl),
                      _InfoRow(
                        icon: Icons.access_time_rounded,
                        label: 'Time',
                        value: _to12Hour(appointment.appointmentTime),
                      ),
                      _divider(cl),
                      _InfoRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Lawyer',
                        value: appointment.displayLawyerName,
                      ),
                    ],
                  ),

                  // Description
                  if (appointment.description?.trim().isNotEmpty ?? false) ...[
                    const SizedBox(height: 20),
                    const _SectionLabel(label: 'Description'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cl.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cl.border),
                      ),
                      child: Text(
                        appointment.description!.trim(),
                        style: TextStyle(
                          fontSize: 14,
                          color: cl.textDark,
                          fontFamily: 'Satoshi',
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],

                  // Rejection reason
                  if (appointment.status == 'cancelled' &&
                      (appointment.rejectionReason?.trim().isNotEmpty ??
                          false)) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F0),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFFFCDD2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: Colors.red.shade700,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rejection Reason',
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  appointment.rejectionReason!.trim(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.red.shade900,
                                    fontFamily: 'Satoshi',
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Timestamps
                  const SizedBox(height: 20),
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: Icons.schedule_rounded,
                        label: 'Booked',
                        value: DateFormat('MMM d, y · h:mm a')
                            .format(appointment.createdAt.toLocal()),
                        small: true,
                      ),
                      if (appointment.updatedAt != null) ...[
                        _divider(cl),
                        _InfoRow(
                          icon: Icons.update_rounded,
                          label: 'Updated',
                          value: DateFormat('MMM d, y · h:mm a')
                              .format(appointment.updatedAt!.toLocal()),
                          small: true,
                        ),
                      ],
                    ],
                  ),

                  // Chat CTA
                  const SizedBox(height: 28),
                  if (appointment.canStartLawyerChat)
                    _ChatButton(appointment: appointment)
                  else
                    _ChatLockedBanner(status: appointment.status),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(
    BuildContext context,
    AppColorTheme cl,
    Color statusColor,
  ) {
    return SliverAppBar(
      backgroundColor: cl.surface,
      foregroundColor: cl.textDark,
      surfaceTintColor: Colors.transparent,
      pinned: true,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: cl.textDark,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        appointment.displayCaseTitle,
        style: GoogleFonts.nunito(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: cl.textDark,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: cl.border),
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

  static Widget _divider(AppColorTheme cl) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 2),
      color: cl.border,
    );
  }

  static String _to12Hour(String value) {
    try {
      final parsed = DateFormat('HH:mm').parse(value);
      return DateFormat('h:mm a').format(parsed);
    } catch (_) {
      return value;
    }
  }

  static bool _hasAttachedConversation(AppointmentEntity a) {
    final id = a.attachedConversationId?.trim();
    return id != null && id.isNotEmpty;
  }

  static void _openAttachedConversation(
    BuildContext context,
    WidgetRef ref,
    AppointmentEntity appointment,
  ) {
    final id = appointment.attachedConversationId!.trim();
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mainShellTabProvider.notifier).state = 1;
      ref.read(chatProvider.notifier).loadConversation(
            id,
            title: appointment.displayCaseTitle,
            isPinned: false,
          );
    });
  }
}

class _AttachedConversationCard extends StatelessWidget {
  const _AttachedConversationCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: cl.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cl.accent.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: cl.cardShadow,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cl.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: cl.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attached CLAiR conversation',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cl.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Open the chat you shared when you booked this appointment.',
                        style: TextStyle(
                          fontSize: 12,
                          color: cl.textMid,
                          fontFamily: 'Satoshi',
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: cl.textLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final (Color bg, Color fg, Color iconBg, IconData icon, String title, String subtitle) = switch (status) {
      'confirmed' => (
          const Color(0xFFECFDF5),
          const Color(0xFF065F46),
          const Color(0xFF22A64A),
          Icons.check_circle_rounded,
          'Appointment Accepted',
          'Your lawyer has confirmed this appointment.',
        ),
      'pending' => (
          const Color(0xFFFFFBEB),
          const Color(0xFF78350F),
          const Color(0xFFE59300),
          Icons.hourglass_empty_rounded,
          'Awaiting Confirmation',
          'Your request is pending review by the lawyer.',
        ),
      'cancelled' => (
          const Color(0xFFFFF1F2),
          const Color(0xFF881337),
          const Color(0xFFD63031),
          Icons.cancel_rounded,
          'Appointment Rejected',
          'The lawyer was unable to accept this request.',
        ),
      _ => (
          cl.fieldBg,
          cl.textMid,
          cl.textLight,
          Icons.info_outline_rounded,
          'Unknown Status',
          '',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fg.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: iconBg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: fg.withValues(alpha: 0.75),
                      fontFamily: 'Satoshi',
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    return Text(
      label,
      style: GoogleFonts.nunito(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: cl.textMid,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    return Container(
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
      child: Column(
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.small = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: cl.fieldBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: cl.textMid),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cl.textLight,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: TextStyle(
                  fontSize: small ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: cl.textDark,
                  fontFamily: 'Satoshi',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatButton extends StatelessWidget {
  const _ChatButton({required this.appointment});
  final AppointmentEntity appointment;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LawyerChatScreen(appointment: appointment),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: cl.accent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cl.accent.withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_rounded,
                size: 20, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              'Chat with ${appointment.displayLawyerName}',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatLockedBanner extends StatelessWidget {
  const _ChatLockedBanner({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;

    final msg = status == 'cancelled'
        ? 'Chat is unavailable — this appointment was rejected.'
        : 'Chat will unlock once your appointment is accepted.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      decoration: BoxDecoration(
        color: cl.fieldBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cl.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: cl.textLight,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(
                fontSize: 13,
                color: cl.textMid,
                fontFamily: 'Satoshi',
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
