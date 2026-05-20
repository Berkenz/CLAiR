import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/notifications/push_notification_service.dart';
import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/auth/data/email_notification_prefs.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';
import 'package:clair/l10n/app_localizations.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _prefsLoaded = false;
  bool _prefCaseActivity = true;
  bool _prefAppointments = true;
  bool _prefLegalTips = true;
  bool _prefNewsletter = false;

  bool _pushSupported = false;
  bool _pushEnabled = false;
  bool _pushLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmailPrefs();
    _loadPushStatus();
  }

  Future<void> _loadEmailPrefs() async {
    final state = await EmailNotificationPrefs.load();
    if (!mounted) return;
    setState(() {
      _prefCaseActivity = state.caseActivity;
      _prefAppointments = state.appointments;
      _prefLegalTips = state.legalTips;
      _prefNewsletter = state.newsletter;
      _prefsLoaded = true;
    });
  }

  Future<void> _loadPushStatus() async {
    final supported = !kIsWeb && Platform.isAndroid;
    var enabled = false;
    if (supported) {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      enabled = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    }
    if (!mounted) return;
    setState(() {
      _pushSupported = supported;
      _pushEnabled = enabled;
      _pushLoading = false;
    });
  }

  Future<void> _onPushToggle(bool value) async {
    if (!_pushSupported) return;
    if (value) {
      final settings = await FirebaseMessaging.instance.requestPermission();
      final ok = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (ok) {
        await ref.read(pushNotificationServiceProvider).syncTokenWithBackend();
      }
      if (mounted) setState(() => _pushEnabled = ok);
    } else {
      _snack(AppLocalizations.of(context)!.notificationSettingsPushDisabledHint);
      if (mounted) setState(() => _pushEnabled = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
      backgroundColor: context.c.accent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    final isGuest = ref.watch(currentUserProvider)?.isAnonymous == true;

    return Scaffold(
      backgroundColor: cl.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: cl.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: cl.cardShadow,
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(Icons.arrow_back_rounded,
                          color: cl.textDark, size: 20),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    l10n.notificationSettings,
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cl.textDark,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 38),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_pushSupported) ...[
                      _sectionLabel(l10n.notificationSettingsPushSection),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 10),
                        child: Text(
                          l10n.notificationSettingsPushSubtitle,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: cl.textLight,
                            height: 1.4,
                          ),
                        ),
                      ),
                      _card(cl, [
                        _prefTile(
                          cl,
                          icon: Icons.notifications_active_outlined,
                          iconColor: cl.accent,
                          title: l10n.notificationSettingsPushToggle,
                          subtitle: l10n.notificationSettingsPushToggleSubtitle,
                          value: _pushEnabled,
                          loading: _pushLoading,
                          onChanged: _pushLoading ? null : _onPushToggle,
                        ),
                      ]),
                      const SizedBox(height: 24),
                    ],
                    if (!isGuest) ...[
                      _sectionLabel(l10n.notificationSettingsEmailSection),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 10),
                        child: Text(
                          l10n.notificationSettingsEmailSubtitle,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: cl.textLight,
                            height: 1.4,
                          ),
                        ),
                      ),
                      _card(cl, [
                        _prefTile(
                          cl,
                          icon: Icons.security_rounded,
                          iconColor: const Color(0xFFDC4C4C),
                          title: l10n.notificationSettingsEmailSecurity,
                          subtitle: l10n.notificationSettingsEmailSecuritySub,
                          value: true,
                          locked: true,
                          onChanged: null,
                        ),
                        Divider(height: 1, indent: 60, color: cl.border),
                        if (!_prefsLoaded)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          )
                        else ...[
                          _prefTile(
                            cl,
                            icon: Icons.chat_bubble_outline_rounded,
                            iconColor: const Color(0xFF8B5CF6),
                            title: l10n.notificationSettingsEmailCase,
                            subtitle: l10n.notificationSettingsEmailCaseSub,
                            value: _prefCaseActivity,
                            onChanged: (v) {
                              setState(() => _prefCaseActivity = v);
                              EmailNotificationPrefs.save(
                                EmailNotificationPrefs.caseActivity,
                                v,
                              );
                            },
                          ),
                          Divider(height: 1, indent: 60, color: cl.border),
                          _prefTile(
                            cl,
                            icon: Icons.calendar_today_outlined,
                            iconColor: const Color(0xFF0EA5E9),
                            title: l10n.notificationSettingsEmailAppointments,
                            subtitle: l10n.notificationSettingsEmailAppointmentsSub,
                            value: _prefAppointments,
                            onChanged: (v) {
                              setState(() => _prefAppointments = v);
                              EmailNotificationPrefs.save(
                                EmailNotificationPrefs.appointments,
                                v,
                              );
                            },
                          ),
                          Divider(height: 1, indent: 60, color: cl.border),
                          _prefTile(
                            cl,
                            icon: Icons.lightbulb_outline_rounded,
                            iconColor: const Color(0xFFF59E0B),
                            title: l10n.notificationSettingsEmailTips,
                            subtitle: l10n.notificationSettingsEmailTipsSub,
                            value: _prefLegalTips,
                            onChanged: (v) {
                              setState(() => _prefLegalTips = v);
                              EmailNotificationPrefs.save(
                                EmailNotificationPrefs.legalTips,
                                v,
                              );
                            },
                          ),
                          Divider(height: 1, indent: 60, color: cl.border),
                          _prefTile(
                            cl,
                            icon: Icons.newspaper_rounded,
                            iconColor: cl.textMid,
                            title: l10n.notificationSettingsEmailNewsletter,
                            subtitle: l10n.notificationSettingsEmailNewsletterSub,
                            value: _prefNewsletter,
                            onChanged: (v) {
                              setState(() => _prefNewsletter = v);
                              EmailNotificationPrefs.save(
                                EmailNotificationPrefs.newsletter,
                                v,
                              );
                            },
                          ),
                        ],
                      ]),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          l10n.notificationSettingsEmailFooter,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: cl.textLight,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    _card(cl, [
                      InkWell(
                        onTap: () => context.push('/notifications'),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                          child: Row(
                            children: [
                              Icon(Icons.inbox_outlined,
                                  color: cl.accent, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.notificationSettingsViewInbox,
                                      style: GoogleFonts.nunito(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: cl.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n.notificationSettingsViewInboxSub,
                                      style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        color: cl.textMid,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded,
                                  color: cl.textLight, size: 22),
                            ],
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String s) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          s,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.c.textMid,
          ),
        ),
      );

  Widget _card(AppColorTheme cl, List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: cl.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cl.border),
          boxShadow: [
            BoxShadow(
              color: cl.cardShadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(children: children),
      );

  Widget _prefTile(
    AppColorTheme cl, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    bool locked = false,
    bool loading = false,
    required ValueChanged<bool>? onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cl.textDark,
                        ),
                      ),
                      if (locked) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.lock_rounded, size: 12, color: cl.textLight),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: cl.textMid,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (loading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Switch(
                value: value,
                onChanged: locked ? null : onChanged,
                activeColor: cl.accent,
              ),
          ],
        ),
      );
}
