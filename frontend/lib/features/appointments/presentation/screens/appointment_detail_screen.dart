import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:clair/app/main_shell_tab.dart';
import 'package:clair/l10n/app_localizations.dart';
import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/appointments/domain/entities/appointment_entity.dart';
import 'package:clair/features/appointments/presentation/providers/appointment_provider.dart';
import 'package:clair/features/appointments/presentation/screens/lawyer_chat_screen.dart';
import 'package:clair/features/chat/presentation/providers/chat_provider.dart';

class AppointmentDetailScreen extends ConsumerStatefulWidget {
  const AppointmentDetailScreen({super.key, required this.appointment});

  final AppointmentEntity appointment;

  @override
  ConsumerState<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends ConsumerState<AppointmentDetailScreen> {
  bool _cancelling = false;

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _statusColor(appointment.status);

    return Scaffold(
      backgroundColor: cl.bg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, cl, statusColor, appointment),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status banner
                  _StatusBanner(appointment: appointment),
                  const SizedBox(height: 20),

                  // Attached CLAiR conversation (from booking)
                  if (_hasAttachedConversation(appointment)) ...[
                    _AttachedConversationCard(
                      onOpen: () => _openAttachedConversation(appointment),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Info card
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: Icons.work_outline_rounded,
                        label: l10n.apptDetailLabelType,
                        value: appointment.appointmentType,
                      ),
                      _divider(cl),
                      _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: l10n.apptDetailLabelDate,
                        value: DateFormat('EEEE, MMMM d, y')
                            .format(appointment.appointmentDate),
                      ),
                      _divider(cl),
                      _InfoRow(
                        icon: Icons.access_time_rounded,
                        label: l10n.apptDetailLabelTime,
                        value: _to12Hour(appointment.appointmentTime),
                      ),
                      _divider(cl),
                      _InfoRow(
                        icon: Icons.person_outline_rounded,
                        label: l10n.apptDetailLabelLawyer,
                        value: appointment.displayLawyerName,
                      ),
                    ],
                  ),

                  // Description
                  if (appointment.description?.trim().isNotEmpty ?? false) ...[
                    const SizedBox(height: 20),
                    _SectionLabel(label: l10n.apptDetailSectionDescription),
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
                                  appointment.isClientCancellation
                                      ? l10n.apptDetailReasonCancellation
                                      : l10n.apptDetailReasonDecline,
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
                        label: l10n.apptDetailLabelBooked,
                        value: DateFormat('MMM d, y · h:mm a')
                            .format(appointment.createdAt.toLocal()),
                        small: true,
                      ),
                      if (appointment.updatedAt != null) ...[
                        _divider(cl),
                        _InfoRow(
                          icon: Icons.update_rounded,
                          label: l10n.apptDetailLabelUpdated,
                          value: DateFormat('MMM d, y · h:mm a')
                              .format(appointment.updatedAt!.toLocal()),
                          small: true,
                        ),
                      ],
                    ],
                  ),

                  // Cancel (client)
                  if (_canClientCancel(appointment)) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            _cancelling ? null : () => _onCancelAppointment(appointment),
                        icon: _cancelling
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.red.shade700,
                                ),
                              )
                            : Icon(
                                Icons.event_busy_outlined,
                                color: Colors.red.shade700,
                              ),
                        label: Text(
                          l10n.apptDetailCancelAppointment,
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w700,
                            color: Colors.red.shade700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],

                  // Chat CTA
                  const SizedBox(height: 28),
                  if (appointment.canStartLawyerChat)
                    _ChatButton(appointment: appointment)
                  else
                    _ChatLockedBanner(appointment: appointment),
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
    AppointmentEntity appointment,
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

  void _openAttachedConversation(AppointmentEntity appointment) {
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

  bool _canClientCancel(AppointmentEntity a) =>
      a.status == 'pending' || a.status == 'confirmed';

  Future<void> _onCancelAppointment(AppointmentEntity appointment) async {
    final l10n = AppLocalizations.of(context)!;
    List<({String id, String label})> reasons;
    try {
      reasons = await ref.read(appointmentDataSourceProvider).getCancellationReasons();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            style: const TextStyle(fontFamily: 'Satoshi'),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }
    if (!mounted) return;
    if (reasons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.apptDetailCancelOptionsFailed,
            style: const TextStyle(fontFamily: 'Satoshi'),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final picked = await showModalBottomSheet<_AppointmentCancelPick>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CancelAppointmentReasonSheet(reasons: reasons),
    );
    if (!mounted || picked == null) return;

    setState(() => _cancelling = true);
    try {
      await ref.read(appointmentProvider.notifier).cancelAppointment(
            appointment.id,
            reason: picked.reason,
            otherDetails: picked.otherDetails,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.apptDetailCancelledSuccess,
            style: const TextStyle(fontFamily: 'Satoshi'),
          ),
          backgroundColor: const Color(0xFF22A64A),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            style: const TextStyle(fontFamily: 'Satoshi'),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }
}

class _AttachedConversationCard extends StatelessWidget {
  const _AttachedConversationCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
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
                        l10n.apptDetailAttachedConversationTitle,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cl.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.apptDetailAttachedConversationSubtitle,
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
  const _StatusBanner({required this.appointment});

  final AppointmentEntity appointment;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    final s = appointment.status;

    late final Color bg, fg, iconBg;
    late final IconData icon;
    late final String title, subtitle;

    if (s == 'cancelled' && appointment.isClientCancellation) {
      bg = const Color(0xFFFFF1F2);
      fg = const Color(0xFF881337);
      iconBg = const Color(0xFFD63031);
      icon = Icons.event_busy_rounded;
      title = l10n.apptDetailBannerCancelledByClientTitle;
      subtitle = l10n.apptDetailBannerCancelledByClientSubtitle;
    } else if (s == 'confirmed') {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF065F46);
      iconBg = const Color(0xFF22A64A);
      icon = Icons.check_circle_rounded;
      title = l10n.apptDetailBannerConfirmedTitle;
      subtitle = l10n.apptDetailBannerConfirmedSubtitle;
    } else if (s == 'pending') {
      bg = const Color(0xFFFFFBEB);
      fg = const Color(0xFF78350F);
      iconBg = const Color(0xFFE59300);
      icon = Icons.hourglass_empty_rounded;
      title = l10n.apptDetailBannerPendingTitle;
      subtitle = l10n.apptDetailBannerPendingSubtitle;
    } else if (s == 'cancelled') {
      bg = const Color(0xFFFFF1F2);
      fg = const Color(0xFF881337);
      iconBg = const Color(0xFFD63031);
      icon = Icons.cancel_rounded;
      title = l10n.apptDetailBannerDeclinedTitle;
      subtitle = l10n.apptDetailBannerDeclinedSubtitle;
    } else {
      bg = cl.fieldBg;
      fg = cl.textMid;
      iconBg = cl.textLight;
      icon = Icons.info_outline_rounded;
      title = l10n.apptDetailBannerUnknownTitle;
      subtitle = '';
    }

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
    final l10n = AppLocalizations.of(context)!;
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
              l10n.apptDetailChatWithLawyer(appointment.displayLawyerName),
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
  const _ChatLockedBanner({required this.appointment});

  final AppointmentEntity appointment;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    final status = appointment.status;

    final String msg;
    if (status == 'cancelled' && appointment.isClientCancellation) {
      msg = l10n.apptDetailChatLockedCancelledSelf;
    } else if (status == 'cancelled') {
      msg = l10n.apptDetailChatLockedCancelledDeclined;
    } else {
      msg = l10n.apptDetailChatLockedPending;
    }

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

class _AppointmentCancelPick {
  const _AppointmentCancelPick({required this.reason, this.otherDetails});

  final String reason;
  final String? otherDetails;
}

class _CancelAppointmentReasonSheet extends StatefulWidget {
  const _CancelAppointmentReasonSheet({required this.reasons});

  final List<({String id, String label})> reasons;

  @override
  State<_CancelAppointmentReasonSheet> createState() =>
      _CancelAppointmentReasonSheetState();
}

class _CancelAppointmentReasonSheetState
    extends State<_CancelAppointmentReasonSheet> {
  String? _selectedId;
  final _other = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _error = null);
    final id = _selectedId;
    if (id == null) {
      setState(() => _error = l10n.apptDetailCancelErrorPickReason);
      return;
    }
    if (id == 'other') {
      final t = _other.text.trim();
      if (t.isEmpty) {
        setState(
          () => _error = l10n.apptDetailCancelErrorOtherDetails,
        );
        return;
      }
      Navigator.of(context).pop(
        _AppointmentCancelPick(reason: id, otherDetails: t),
      );
      return;
    }
    Navigator.of(context).pop(_AppointmentCancelPick(reason: id));
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cl.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cl.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.apptDetailCancelWhyTitle,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: cl.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.apptDetailCancelWhySubtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: cl.textMid,
                    fontFamily: 'Satoshi',
                  ),
                ),
                const SizedBox(height: 14),
                ...widget.reasons.map((r) {
                  final sel = _selectedId == r.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(() => _selectedId = r.id),
                        borderRadius: BorderRadius.circular(12),
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel ? cl.accent : cl.border,
                              width: sel ? 2 : 1,
                            ),
                            color: sel
                                ? cl.accent.withValues(alpha: 0.06)
                                : cl.fieldBg,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                sel
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_off_rounded,
                                size: 22,
                                color: sel ? cl.accent : cl.textLight,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  r.label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: cl.textDark,
                                    fontFamily: 'Satoshi',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                if (_selectedId == 'other') ...[
                  const SizedBox(height: 6),
                  TextField(
                    controller: _other,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: l10n.apptDetailCancelTellMoreHint,
                      filled: true,
                      fillColor: cl.fieldBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cl.border),
                      ),
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                      fontFamily: 'Satoshi',
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          l10n.apptDetailKeepAppointment,
                          style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                        ),
                        child: Text(
                          l10n.apptDetailConfirmCancel,
                          style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
