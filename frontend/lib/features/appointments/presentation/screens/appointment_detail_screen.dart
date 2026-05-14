import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:clair/app/main_shell_tab.dart';
import 'package:clair/l10n/app_localizations.dart';
import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/core/utils/error_helpers.dart';
import 'package:clair/features/appointments/domain/entities/appointment_entity.dart';
import 'package:clair/features/appointments/presentation/providers/appointment_provider.dart';
import 'package:clair/features/appointments/presentation/providers/direct_message_provider.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColor(appointment.status);

    final dmUnread = appointment.canStartLawyerChat
        ? ref.watch(directMessageProvider(appointment.id)).unreadCount
        : 0;

    return Scaffold(
      backgroundColor: cl.bg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, cl, l10n, statusColor, appointment),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. Status banner ──────────────────────────────────────
                  _StatusBanner(appointment: appointment),
                  const SizedBox(height: 14),

                  // ── 2. Date / time hero ───────────────────────────────────
                  _DateTimeHeroCard(appointment: appointment),
                  const SizedBox(height: 14),

                  // ── 3. PRIMARY ACTION ─────────────────────────────────────
                  if (appointment.canStartLawyerChat)
                    _ChatButton(appointment: appointment, unreadCount: dmUnread)
                  else
                    _ChatLockedBanner(appointment: appointment),
                  const SizedBox(height: 14),

                  // ── 4. Attached CLAiR conversation ────────────────────────
                  if (_hasAttachedConversation(appointment)) ...[
                    _AttachedConversationCard(
                      onOpen: () => _openAttachedConversation(appointment),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── 5. Info card (type + lawyer) ──────────────────────────
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: Icons.work_outline_rounded,
                        label: l10n.apptDetailLabelType,
                        value: appointment.appointmentType,
                      ),
                      _divider(cl),
                      _InfoRow(
                        icon: Icons.person_outline_rounded,
                        label: l10n.apptDetailLabelLawyer,
                        value: appointment.displayLawyerName,
                        valueWidget: Row(
                          children: [
                            _LawyerAvatar(name: appointment.displayLawyerName, cl: cl),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                appointment.displayLawyerName,
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
                    ],
                  ),

                  // ── 6. Description ────────────────────────────────────────
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

                  // ── 7. Rejection / cancellation reason ────────────────────
                  if (appointment.status == 'cancelled' &&
                      (appointment.rejectionReason?.trim().isNotEmpty ?? false)) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1A0D10)
                            : const Color(0xFFFFF0F0),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF3D1520)
                              : const Color(0xFFFFCDD2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 18,
                              color: isDark
                                  ? const Color(0xFF8B3040)
                                  : Colors.red.shade700),
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
                                    color: isDark
                                        ? const Color(0xFF8B3040)
                                        : Colors.red.shade700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  appointment.rejectionReason!.trim(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? const Color(0xFF6B3040)
                                        : Colors.red.shade900,
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

                  // ── 8. Timestamps ─────────────────────────────────────────
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

                  // ── 9. Cancel ─────────────────────────────────────────────
                  if (_canClientCancel(appointment)) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _cancelling
                            ? null
                            : () => _onCancelAppointment(appointment),
                        icon: _cancelling
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: isDark
                                      ? const Color(0xFF8B3040)
                                      : Colors.red.shade700,
                                ),
                              )
                            : Icon(
                                Icons.event_busy_outlined,
                                color: isDark
                                    ? const Color(0xFF8B3040)
                                    : Colors.red.shade700,
                              ),
                        label: Text(
                          l10n.apptDetailCancelAppointment,
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFF8B3040)
                                : Colors.red.shade700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF3D1520)
                                : Colors.red.shade200,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
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
    AppLocalizations l10n,
    Color statusColor,
    AppointmentEntity appointment,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: _StatusChip(
            status: appointment.status,
            statusColor: statusColor,
            isDark: isDark,
            l10n: l10n,
            appointment: appointment,
          ),
        ),
      ],
      // Status-colored accent line below the app bar title.
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(3),
        child: Container(
          height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                statusColor.withValues(alpha: isDark ? 0.5 : 0.7),
                statusColor.withValues(alpha: 0.0),
              ],
            ),
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

  static Widget _divider(AppColorTheme cl) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 2),
      color: cl.border,
    );
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
          content: Text(friendlyErrorMessage(e), style: const TextStyle(fontFamily: 'Satoshi')),
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
          content: Text(friendlyErrorMessage(e), style: const TextStyle(fontFamily: 'Satoshi')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }
}

// ── Status chip (app bar action) ──────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
    required this.statusColor,
    required this.isDark,
    required this.l10n,
    required this.appointment,
  });

  final String status;
  final Color statusColor;
  final bool isDark;
  final AppLocalizations l10n;
  final AppointmentEntity appointment;

  @override
  Widget build(BuildContext context) {
    final String label;
    if (status == 'confirmed') {
      label = l10n.apptStatusAccepted;
    } else if (status == 'pending') {
      label = l10n.apptStatusPending;
    } else if (status == 'cancelled') {
      label = appointment.isClientCancellation
          ? l10n.apptStatusCancelled
          : l10n.apptStatusDeclined;
    } else {
      label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: isDark ? 0.3 : 0.25),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isDark
              ? statusColor.withValues(alpha: 0.85)
              : statusColor,
        ),
      ),
    );
  }
}

// ── Date / time hero card ─────────────────────────────────────────────────────

class _DateTimeHeroCard extends StatelessWidget {
  const _DateTimeHeroCard({required this.appointment});

  final AppointmentEntity appointment;

  static String _to12Hour(String value) {
    try {
      return DateFormat('h:mm a').format(DateFormat('HH:mm').parse(value));
    } catch (_) {
      return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = appointment.appointmentDate;
    final dayName = DateFormat('EEEE').format(date);
    final monthDay = DateFormat('MMMM d, y').format(date);
    final time = _to12Hour(appointment.appointmentTime);

    final isOnline = appointment.appointmentType.toLowerCase().contains('online') ||
        appointment.appointmentType.toLowerCase().contains('video');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
      child: Row(
        children: [
          // Calendar icon block
          Container(
            width: 52,
            decoration: BoxDecoration(
              color: cl.accent.withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cl.accent.withValues(alpha: isDark ? 0.2 : 0.15),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: cl.accent,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(11),
                    ),
                  ),
                  child: Text(
                    DateFormat('MMM').format(date).toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    DateFormat('d').format(date),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: cl.textDark,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayName,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: cl.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  monthDay,
                  style: TextStyle(
                    fontSize: 13,
                    color: cl.textMid,
                    fontFamily: 'Satoshi',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: cl.accent.withValues(
                            alpha: isDark ? 0.15 : 0.09),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 12, color: cl.accent),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: cl.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cl.fieldBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cl.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOnline
                                ? Icons.videocam_outlined
                                : Icons.place_outlined,
                            size: 12,
                            color: cl.textMid,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            appointment.appointmentType,
                            style: TextStyle(
                              fontSize: 11,
                              color: cl.textMid,
                              fontFamily: 'Satoshi',
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
        ],
      ),
    );
  }
}

// ── Lawyer avatar (initials) ──────────────────────────────────────────────────

class _LawyerAvatar extends StatelessWidget {
  const _LawyerAvatar({required this.name, required this.cl});

  final String name;
  final AppColorTheme cl;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: cl.accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: cl.accent.withValues(alpha: 0.2),
        ),
      ),
      child: Center(
        child: Text(
          _initials,
          style: GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: cl.accent,
          ),
        ),
      ),
    );
  }
}

// ── Attached conversation card ────────────────────────────────────────────────

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    late final Color bg, fg, iconBg;
    late final IconData icon;
    late final String title, subtitle;

    if (s == 'cancelled' && appointment.isClientCancellation) {
      bg = isDark ? const Color(0xFF1A0D0E) : const Color(0xFFFFF1F2);
      fg = isDark ? const Color(0xFF8B3040) : const Color(0xFF881337);
      iconBg = const Color(0xFFD63031);
      icon = Icons.event_busy_rounded;
      title = l10n.apptDetailBannerCancelledByClientTitle;
      subtitle = l10n.apptDetailBannerCancelledByClientSubtitle;
    } else if (s == 'confirmed') {
      bg = isDark ? const Color(0xFF0D1A10) : const Color(0xFFECFDF5);
      fg = isDark ? const Color(0xFF2D7A48) : const Color(0xFF065F46);
      iconBg = const Color(0xFF22A64A);
      icon = Icons.check_circle_rounded;
      title = l10n.apptDetailBannerConfirmedTitle;
      subtitle = l10n.apptDetailBannerConfirmedSubtitle;
    } else if (s == 'pending') {
      bg = isDark ? const Color(0xFF131008) : const Color(0xFFFFFBEB);
      fg = isDark ? const Color(0xFF6D5615) : const Color(0xFF78350F);
      iconBg = isDark ? const Color(0xFF9A7820) : const Color(0xFFE59300);
      icon = Icons.hourglass_empty_rounded;
      title = l10n.apptDetailBannerPendingTitle;
      subtitle = l10n.apptDetailBannerPendingSubtitle;
    } else if (s == 'cancelled') {
      bg = isDark ? const Color(0xFF1A0D0E) : const Color(0xFFFFF1F2);
      fg = isDark ? const Color(0xFF8B3040) : const Color(0xFF881337);
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
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.small = false,
    this.valueWidget,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool small;
  final Widget? valueWidget;

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
          Expanded(
            child: Column(
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
                const SizedBox(height: 2),
                valueWidget ??
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
          ),
        ],
      ),
    );
  }
}

class _ChatButton extends StatelessWidget {
  const _ChatButton({
    required this.appointment,
    this.unreadCount = 0,
  });

  final AppointmentEntity appointment;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    final hasUnread = unreadCount > 0;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LawyerChatScreen(appointment: appointment),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: cl.accent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cl.accent.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.chat_bubble_rounded,
                    size: 22, color: Colors.white),
                if (hasUnread)
                  Positioned(
                    top: -5,
                    right: -7,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.red.shade500,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cl.accent, width: 1.5),
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                l10n.apptDetailChatWithLawyer(appointment.displayLawyerName),
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasUnread) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$unreadCount new',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
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
          Icon(Icons.lock_outline_rounded, size: 18, color: cl.textLight),
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
        setState(() => _error = l10n.apptDetailCancelErrorOtherDetails);
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
