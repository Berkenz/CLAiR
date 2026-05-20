import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/core/theme/appearance_provider.dart';
import 'package:clair/core/utils/error_helpers.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';
import 'package:clair/features/auth/presentation/screens/appearance_screen.dart';
import 'package:clair/features/auth/presentation/screens/email_screen.dart';
import 'package:clair/features/auth/presentation/screens/security_screen.dart';
import 'package:clair/features/auth/presentation/screens/edit_profile_screen.dart';
import 'package:clair/features/auth/presentation/screens/privacy_policy_screen.dart';
import 'package:clair/features/auth/presentation/screens/report_screen.dart';
import 'package:clair/features/auth/presentation/screens/help_center_screen.dart';
import 'package:clair/features/auth/presentation/screens/terms_of_use_screen.dart';
import 'package:clair/features/auth/presentation/screens/language_screen.dart';
import 'package:clair/features/chat/presentation/providers/chat_provider.dart';
import 'package:clair/l10n/app_localizations.dart';
import 'package:clair/shared/widgets/profile_photo_image.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isDeleting = false;

  Future<void> _deleteAccount(String? password) async {
    setState(() => _isDeleting = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.deleteAccount(password: password);
      ref.read(currentUserProvider.notifier).state = null;
      ref.read(chatProvider.notifier).reset();
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyErrorMessage(e)),
            backgroundColor: const Color(0xFFDC4C4C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final photoCacheVersion = ref.watch(profilePhotoCacheVersionProvider);
    final name = user?.displayName ?? 'User';
    final parts = name.split(' ');
    final initials = parts
        .map((p) => p.isNotEmpty ? p[0].toUpperCase() : '')
        .take(2)
        .join();

    return Scaffold(
      backgroundColor: cl.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(children: [
            Row(children: [
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
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: cl.textDark,
                    size: 20,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                l10n.settingsTitle,
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cl.textDark,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 38),
            ]),
            const SizedBox(height: 28),

            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cl.accent.withValues(alpha: 0.12),
                    cl.accentLight.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: cl.cardShadow,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: user?.photoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: ProfilePhotoImage(
                        photoUrl: user!.photoUrl!,
                        updatedAt: user.updatedAt,
                        cacheVersion: photoCacheVersion,
                        width: 72,
                        height: 72,
                      ),
                    )
                  : Center(
                      child: Text(
                        initials,
                        style: GoogleFonts.nunito(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: cl.accent,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: cl.textDark,
              ),
            ),
            Text(
              user?.email ?? '',
              style: GoogleFonts.nunito(fontSize: 13, color: cl.textMid),
            ),
            const SizedBox(height: 8),
            if (user?.isAnonymous == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: cl.border.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.guestAccount,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cl.textLight,
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: cl.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.editProfile,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cl.accent,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 28),

            if (user?.isAnonymous != true) ...[
              _section(context, l10n.sectionAccount, [
                _row(
                  context,
                  Icons.mail_outline_rounded,
                  l10n.email,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EmailScreen()),
                  ),
                ),
                _row(
                  context,
                  Icons.notifications_outlined,
                  l10n.notifications,
                  () => context.push('/notifications'),
                ),
                _row(
                  context,
                  Icons.lock_outline_rounded,
                  l10n.security,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SecurityScreen(),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
            ] else ...[
              // Guest: prompt to create a real account
              const _GuestUpgradeBanner(),
              const SizedBox(height: 16),
            ],

            _section(context, l10n.sectionApp, [
              _row(
                context,
                Icons.palette_outlined,
                l10n.appearance,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AppearanceScreen(),
                  ),
                ),
              ),
              _row(
                context,
                Icons.language_rounded,
                l10n.appLanguage,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LanguageScreen()),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            _section(context, l10n.sectionAbout, [
              _row(
                context,
                Icons.flag_outlined,
                l10n.report,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportScreen()),
                ),
              ),
              _row(
                context,
                Icons.help_outline_rounded,
                l10n.helpCenter,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const HelpCenterScreen()),
                ),
              ),
              _row(
                context,
                Icons.description_outlined,
                l10n.termsOfUse,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TermsOfUseScreen()),
                ),
              ),
              _row(
                context,
                Icons.privacy_tip_outlined,
                l10n.privacyPolicy,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                ),
              ),
            ]),
            const SizedBox(height: 24),

            GestureDetector(
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  barrierDismissible: true,
                  builder: (ctx) {
                    final d = ctx.c;
                    final dl = AppLocalizations.of(ctx)!;
                    return AlertDialog(
                      backgroundColor: d.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      title: Text(
                        dl.settingsResetDialogTitle,
                        style: GoogleFonts.nunito(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: d.textDark,
                        ),
                      ),
                      content: Text(
                        dl.settingsResetDialogBody,
                        style: GoogleFonts.nunito(fontSize: 13, height: 1.45, color: d.textMid),
                      ),
                      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(
                            dl.commonCancel,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700,
                              color: d.textMid,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(
                            dl.commonConfirm,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w800,
                              color: d.accent,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );

                if (ok != true || !context.mounted) return;

                final messenger = ScaffoldMessenger.of(context);
                await ref.read(appearanceProvider.notifier).resetToDefaultsAndPersist();
                if (!context.mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.settingsResetSnackbar,
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: cl.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cl.border),
                ),
                child: Center(
                  child: Text(
                    l10n.resetAllToDefault,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cl.textMid,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Log Out / Exit Guest Session
            GestureDetector(
              onTap: () async {
                try {
                  final repo = ref.read(authRepositoryProvider);
                  if (user?.isAnonymous == true) {
                    await repo.exitGuestSession();
                  } else {
                    await repo.signOut();
                  }
                  ref.read(currentUserProvider.notifier).state = null;
                  ref.read(chatProvider.notifier).reset();
                  if (context.mounted) context.go('/login');
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(friendlyErrorMessage(e)),
                        backgroundColor: Colors.red.shade700,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Center(
                  child: Text(
                    user?.isAnonymous == true
                        ? l10n.exitGuestSession
                        : l10n.logOut,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFDC4C4C),
                    ),
                  ),
                ),
              ),
            ),

            if (user?.isAnonymous != true) ...[
              const SizedBox(height: 12),

              // Delete Account (registered users only — guests use Exit Guest Session)
              GestureDetector(
                onTap: _isDeleting
                    ? null
                    : () async {
                        final user = ref.read(currentUserProvider);
                        if (user == null) return;
                        final passwordCompleter = _PasswordCompleter();
                        final confirmed = await showDialog<bool>(
                          context: context,
                          barrierDismissible: true,
                          builder: (_) => _DeleteAccountDialog(
                            authProvider: user.authProvider,
                            isAnonymous: user.isAnonymous,
                            email: user.email,
                            onConfirm: (password) {
                              passwordCompleter.value = password;
                            },
                          ),
                        );
                        if (confirmed == true && mounted) {
                          await _deleteAccount(passwordCompleter.value);
                        }
                      },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFDC4C4C).withOpacity(0.35),
                    ),
                  ),
                  child: Center(
                    child: _isDeleting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFDC4C4C),
                              ),
                            ),
                          )
                        : Text(
                            l10n.deleteAccount,
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color:
                                  const Color(0xFFDC4C4C).withOpacity(0.75),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> rows) {
    final cl = context.c;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: cl.textMid,
          ),
        ),
      ),
      Container(
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
        child: Column(children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              Divider(height: 1, indent: 48, color: cl.border),
          ],
        ]),
      ),
    ]);
  }

  Widget _row(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final cl = context.c;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(children: [
            Icon(icon, size: 20, color: cl.textMid),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: cl.textDark,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: cl.textLight,
            ),
          ]),
        ),
      ),
    );
  }
}

class _GuestUpgradeBanner extends StatelessWidget {
  const _GuestUpgradeBanner();

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cl.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person_add_alt_1_rounded,
              color: cl.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Browsing as Guest',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: cl.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Create an account to save chats, book appointments, and more.',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: cl.textMid,
                    height: 1.4,
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

/// Simple mutable holder so the dialog can return the password
/// alongside the bool result from [showDialog].
class _PasswordCompleter {
  String? value;
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({
    required this.authProvider,
    required this.isAnonymous,
    this.email,
    required this.onConfirm,
  });

  final String authProvider;
  final bool isAnonymous;
  final String? email;
  final void Function(String? password) onConfirm;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _confirmedWarning = false;

  bool get _isEmailProvider =>
      widget.authProvider == 'email' && !widget.isAnonymous;

  bool get _isGoogleProvider =>
      widget.authProvider == 'google' && !widget.isAnonymous;

  bool get _canProceed {
    if (!_confirmedWarning) return false;
    if (_isEmailProvider) return _passwordController.text.isNotEmpty;
    return true;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.c;

    return Dialog(
      backgroundColor: cl.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: Color(0xFFDC4C4C),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Delete Account',
                    style: GoogleFonts.nunito(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: cl.textDark,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Warning box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                'This action is permanent and cannot be undone. '
                'Your account, chat history, and all personal data will be '
                'permanently deleted in accordance with our Privacy Policy.',
                style: GoogleFonts.nunito(
                  fontSize: 12.5,
                  color: const Color(0xFFB91C1C),
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Provider-specific section
            if (_isEmailProvider) ...[
              Text(
                'Enter your password to confirm',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cl.textDark,
                ),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _passwordController,
                builder: (_, __, ___) {
                  return TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Satoshi',
                      color: cl.textDark,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Current password',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: cl.textLight,
                        fontFamily: 'Satoshi',
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline_rounded,
                        color: cl.textMid,
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: cl.textMid,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: cl.fieldBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cl.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cl.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFDC4C4C),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ] else if (_isGoogleProvider) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cl.fieldBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cl.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.g_mobiledata_rounded,
                        color: cl.textMid, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You\'ll be asked to re-authenticate with Google before your account is deleted.',
                        style: GoogleFonts.nunito(
                          fontSize: 12.5,
                          color: cl.textMid,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else if (widget.isAnonymous) ...[
              // Guest account — no re-auth needed
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cl.fieldBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cl.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: cl.textMid, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You\'re signed in as a guest. Deleting this guest session '
                        'will erase your chat history and temporary data. '
                        'No password is required.',
                        style: GoogleFonts.nunito(
                          fontSize: 12.5,
                          color: cl.textMid,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              const SizedBox(height: 4),
            ],

            // "I understand" checkbox
            GestureDetector(
              onTap: () =>
                  setState(() => _confirmedWarning = !_confirmedWarning),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: _confirmedWarning,
                      onChanged: (v) =>
                          setState(() => _confirmedWarning = v ?? false),
                      activeColor: const Color(0xFFDC4C4C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'I understand this will permanently delete my account and all associated data.',
                      style: GoogleFonts.nunito(
                        fontSize: 12.5,
                        color: cl.textMid,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: cl.fieldBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cl.border),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cl.textMid,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedOpacity(
                    opacity: _canProceed ? 1.0 : 0.45,
                    duration: const Duration(milliseconds: 200),
                    child: GestureDetector(
                      onTap: _canProceed
                          ? () {
                              widget.onConfirm(
                                _isEmailProvider
                                    ? _passwordController.text
                                    : null,
                              );
                              Navigator.of(context).pop(true);
                            }
                          : null,
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC4C4C),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Delete Account',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
