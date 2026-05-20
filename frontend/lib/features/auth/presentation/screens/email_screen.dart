import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/core/utils/error_helpers.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';

class EmailScreen extends ConsumerStatefulWidget {
  const EmailScreen({super.key});

  @override
  ConsumerState<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends ConsumerState<EmailScreen> {
  // Change-email form
  final _newEmailCtrl   = TextEditingController();
  final _pwCtrl         = TextEditingController();
  bool _obscurePw       = true;
  bool _changingEmail   = false;
  bool _linkSent        = false;
  bool _showChangeForm  = false;

  // Resend verification
  bool _resending       = false;
  bool _resentDone      = false;

  @override
  void dispose() {
    _newEmailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
      backgroundColor:
          isError ? const Color(0xFFDC4C4C) : context.c.accent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _resendVerification() async {
    setState(() => _resending = true);
    try {
      await ref.read(authRepositoryProvider).resendEmailVerification();
      setState(() => _resentDone = true);
      _snack('Verification email sent. Check your inbox.');
    } catch (e) {
      _snack(friendlyErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _submitChangeEmail() async {
    final newEmail = _newEmailCtrl.text.trim();
    final password = _pwCtrl.text;

    if (newEmail.isEmpty) {
      _snack('Please enter a new email address.', isError: true);
      return;
    }
    if (!newEmail.contains('@') || !newEmail.contains('.')) {
      _snack('Please enter a valid email address.', isError: true);
      return;
    }
    if (password.isEmpty) {
      _snack('Please enter your current password.', isError: true);
      return;
    }

    final currentEmail =
        ref.read(currentUserProvider)?.email ?? '';
    if (newEmail.toLowerCase() == currentEmail.toLowerCase()) {
      _snack('New email must be different from your current email.',
          isError: true);
      return;
    }

    setState(() => _changingEmail = true);
    try {
      await ref.read(authRepositoryProvider).changeEmail(
            newEmail: newEmail,
            currentPassword: password,
          );
      setState(() {
        _linkSent = true;
        _showChangeForm = false;
      });
      _newEmailCtrl.clear();
      _pwCtrl.clear();
      _snack('Verification link sent to $newEmail');
    } catch (e) {
      _snack(friendlyErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _changingEmail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cl    = context.c;
    final user  = ref.watch(currentUserProvider);
    final isEmail  = user?.authProvider == 'email' && user?.isAnonymous != true;
    final isGoogle = user?.authProvider == 'google';
    final isGuest  = user?.isAnonymous == true;

    final firebaseUser  = FirebaseAuth.instance.currentUser;
    final isVerified    = firebaseUser?.emailVerified ?? user?.isEmailVerified ?? false;
    final currentEmail  = user?.email ?? '';

    return Scaffold(
      backgroundColor: cl.bg,
      body: SafeArea(
        child: Column(children: [
          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: cl.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(
                        color: cl.cardShadow, blurRadius: 4,
                        offset: const Offset(0, 1))],
                  ),
                  child: Icon(Icons.arrow_back_rounded,
                      color: cl.textDark, size: 20),
                ),
              ),
              const Spacer(),
              Text('Email',
                  style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cl.textDark)),
              const Spacer(),
              const SizedBox(width: 38),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Guest banner ─────────────────────────────────────────
                  if (isGuest) ...[
                    _GuestBanner(cl: cl),
                    const SizedBox(height: 24),
                  ],

                  // ── Email Address ─────────────────────────────────────────
                  _sectionLabel('Email Address'),
                  const SizedBox(height: 10),
                  _card(cl, [
                    // Current email row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Row(children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: cl.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.mail_outline_rounded,
                              color: cl.accent, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isGuest ? 'No email address' : currentEmail,
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isGuest ? cl.textLight : cl.textDark,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isGuest
                                    ? 'Guest account'
                                    : isGoogle
                                        ? 'Managed by Google'
                                        : 'Primary email address',
                                style: GoogleFonts.nunito(
                                    fontSize: 12, color: cl.textLight),
                              ),
                            ],
                          ),
                        ),
                        // Verified badge
                        if (!isGuest && currentEmail.isNotEmpty)
                          _VerifiedBadge(verified: isVerified),
                      ]),
                    ),

                    // Resend verification (email users, not verified)
                    if (isEmail && !isVerified) ...[
                      Divider(height: 1, color: cl.border),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: (_resending || _resentDone)
                              ? null
                              : _resendVerification,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            child: Row(children: [
                              Icon(
                                _resentDone
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.forward_to_inbox_rounded,
                                size: 18,
                                color: _resentDone
                                    ? const Color(0xFF059669)
                                    : cl.accent,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _resentDone
                                      ? 'Verification email sent — check your inbox'
                                      : 'Resend verification email',
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _resentDone
                                        ? const Color(0xFF059669)
                                        : cl.accent,
                                  ),
                                ),
                              ),
                              if (_resending)
                                SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(
                                      color: cl.accent, strokeWidth: 2),
                                ),
                            ]),
                          ),
                        ),
                      ),
                    ],

                    // Link-sent confirmation banner
                    if (_linkSent) ...[
                      Divider(height: 1, color: cl.border),
                      Container(
                        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFF059669)
                                  .withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded,
                                color: Color(0xFF059669), size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'A verification link has been sent to your new email. '
                                'Click the link to complete the change. '
                                'Your email will update automatically once verified.',
                                style: GoogleFonts.nunito(
                                  fontSize: 12.5,
                                  color: const Color(0xFF059669),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ]),

                  // ── Change Email ──────────────────────────────────────────
                  if (isEmail) ...[
                    const SizedBox(height: 16),
                    // Toggle button
                    GestureDetector(
                      onTap: () => setState(() {
                        _showChangeForm = !_showChangeForm;
                        if (!_showChangeForm) {
                          _newEmailCtrl.clear();
                          _pwCtrl.clear();
                        }
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          color: cl.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _showChangeForm
                                ? cl.accent.withValues(alpha: 0.5)
                                : cl.border,
                            width: _showChangeForm ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: cl.cardShadow,
                                blurRadius: 6,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Row(children: [
                          Icon(Icons.edit_outlined,
                              size: 18,
                              color: _showChangeForm
                                  ? cl.accent
                                  : cl.textMid),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Change Email Address',
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _showChangeForm
                                    ? cl.accent
                                    : cl.textDark,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: _showChangeForm ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(Icons.keyboard_arrow_down_rounded,
                                color: cl.textLight, size: 20),
                          ),
                        ]),
                      ),
                    ),

                    // Animated form
                    AnimatedSize(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOut,
                      child: _showChangeForm
                          ? _ChangeEmailForm(
                              cl: cl,
                              newEmailCtrl: _newEmailCtrl,
                              pwCtrl: _pwCtrl,
                              obscurePw: _obscurePw,
                              onTogglePw: () =>
                                  setState(() => _obscurePw = !_obscurePw),
                              isLoading: _changingEmail,
                              onSubmit: _submitChangeEmail,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],

                  // ── Google email info ─────────────────────────────────────
                  if (isGoogle) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4285F4).withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFF4285F4)
                                .withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 16, color: Color(0xFF4285F4)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Your email address is managed by Google. '
                              'To change it, update your Google account at '
                              'myaccount.google.com.',
                              style: GoogleFonts.nunito(
                                  fontSize: 12.5,
                                  color: const Color(0xFF4285F4),
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String s) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(s,
            style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.c.textMid)),
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
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(children: children),
      );
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge({required this.verified});
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: verified
            ? const Color(0xFF059669).withValues(alpha: 0.1)
            : const Color(0xFFDC4C4C).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          verified
              ? Icons.verified_rounded
              : Icons.warning_amber_rounded,
          size: 13,
          color: verified
              ? const Color(0xFF059669)
              : const Color(0xFFDC4C4C),
        ),
        const SizedBox(width: 4),
        Text(
          verified ? 'Verified' : 'Unverified',
          style: GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: verified
                ? const Color(0xFF059669)
                : const Color(0xFFDC4C4C),
          ),
        ),
      ]),
    );
  }
}

class _GuestBanner extends StatelessWidget {
  const _GuestBanner({required this.cl});
  final AppColorTheme cl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cl.accent.withValues(alpha: 0.1),
            cl.accentLight.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cl.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: cl.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.person_outline_rounded,
                color: cl.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You\'re using a guest account',
                  style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cl.textDark),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create a full account to get an email address, '
                  'save your chat history, and receive important notifications.',
                  style: GoogleFonts.nunito(
                      fontSize: 12.5, color: cl.textMid, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangeEmailForm extends StatelessWidget {
  const _ChangeEmailForm({
    required this.cl,
    required this.newEmailCtrl,
    required this.pwCtrl,
    required this.obscurePw,
    required this.onTogglePw,
    required this.isLoading,
    required this.onSubmit,
  });

  final AppColorTheme cl;
  final TextEditingController newEmailCtrl;
  final TextEditingController pwCtrl;
  final bool obscurePw;
  final VoidCallback onTogglePw;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cl.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cl.border),
        boxShadow: [
          BoxShadow(
              color: cl.cardShadow, blurRadius: 6, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cl.accent.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cl.accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 15, color: cl.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'A verification link will be sent to your new email. '
                    'Your email address will only change once you click the link.',
                    style: GoogleFonts.nunito(
                        fontSize: 12, color: cl.accent, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // New email field
          _fieldLabel('New Email Address'),
          const SizedBox(height: 6),
          _textField(
            context,
            controller: newEmailCtrl,
            hint: 'newaddress@example.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),

          // Password field
          _fieldLabel('Current Password'),
          const SizedBox(height: 6),
          _textField(
            context,
            controller: pwCtrl,
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscure: obscurePw,
            suffixIcon: IconButton(
              icon: Icon(
                obscurePw
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: cl.textLight,
              ),
              onPressed: onTogglePw,
            ),
          ),
          const SizedBox(height: 16),

          // Submit button
          GestureDetector(
            onTap: isLoading ? null : onSubmit,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                    colors: [cl.accent, cl.accentDark]),
                boxShadow: [
                  BoxShadow(
                    color: cl.accent.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('Send Verification Link',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String s) => Text(s,
      style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: cl.textMid));

  Widget _textField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: cl.fieldBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cl.border),
        ),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cl.textDark),
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            hintText: hint,
            hintStyle: GoogleFonts.nunito(
                color: cl.textLight, fontSize: 13),
            prefixIcon:
                Icon(icon, size: 18, color: cl.textLight),
            suffixIcon: suffixIcon,
          ),
        ),
      );
}
