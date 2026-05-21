import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/core/utils/error_helpers.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';
import 'package:clair/features/chat/presentation/providers/chat_provider.dart';
import 'package:clair/features/history/presentation/providers/history_provider.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  // Change password
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _savingPassword = false;

  // Password reset
  bool _sendingReset = false;
  bool _resetSent = false;

  // Sign out all
  bool _signingOutAll = false;

  @override
  void dispose() {
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    final cl = context.c;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
      backgroundColor: isError ? const Color(0xFFDC4C4C) : cl.accent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // Strength: 0–4
  int _passwordStrength(String pw) {
    if (pw.isEmpty) return 0;
    int score = 0;
    if (pw.length >= 8) score++;
    if (pw.length >= 12) score++;
    if (pw.contains(RegExp(r'[A-Z]'))) score++;
    if (pw.contains(RegExp(r'[0-9]'))) score++;
    if (pw.contains(RegExp(r'[!@#\$&*~%^()_\-+=<>?]'))) score++;
    return score.clamp(0, 4);
  }

  String _strengthLabel(int s) =>
      ['', 'Weak', 'Fair', 'Good', 'Strong'][s];

  Color _strengthColor(int s, AppColorTheme cl) => switch (s) {
        1 => const Color(0xFFDC4C4C),
        2 => const Color(0xFFF59E0B),
        3 => const Color(0xFF10B981),
        4 => const Color(0xFF059669),
        _ => cl.border,
      };

  Future<void> _changePassword() async {
    final current = _currentPwCtrl.text;
    final next = _newPwCtrl.text;
    final confirm = _confirmPwCtrl.text;

    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      _snack('Please fill in all password fields.', isError: true);
      return;
    }
    if (next.length < 8) {
      _snack('New password must be at least 8 characters.', isError: true);
      return;
    }
    if (!next.contains(RegExp(r'[A-Z]'))) {
      _snack('New password must contain at least one uppercase letter.', isError: true);
      return;
    }
    if (!next.contains(RegExp(r'[0-9]'))) {
      _snack('New password must contain at least one number.', isError: true);
      return;
    }
    if (next != confirm) {
      _snack('Passwords do not match.', isError: true);
      return;
    }
    if (current == next) {
      _snack('New password must be different from your current password.', isError: true);
      return;
    }

    setState(() => _savingPassword = true);
    try {
      await ref.read(authRepositoryProvider).changePassword(
            currentPassword: current,
            newPassword: next,
          );
      _currentPwCtrl.clear();
      _newPwCtrl.clear();
      _confirmPwCtrl.clear();
      _snack('Password updated successfully.');
    } catch (e) {
      _snack(friendlyErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final user = ref.read(currentUserProvider);
    final email = user?.email;
    if (email == null || email.isEmpty) return;

    setState(() => _sendingReset = true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email: email);
      setState(() => _resetSent = true);
      _snack('Reset link sent to $email');
    } catch (e) {
      _snack(friendlyErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _sendingReset = false);
    }
  }

  Future<void> _signOutAllDevices() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Sign Out All Devices',
        message:
            'This will sign you out of your current session. You will need to log in again.',
        confirmLabel: 'Sign Out',
        confirmColor: const Color(0xFFDC4C4C),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _signingOutAll = true);
    try {
      await ref.read(authRepositoryProvider).signOut();
      ref.read(currentUserProvider.notifier).state = null;
      ref.read(historyProvider.notifier).reset();
      ref.read(chatProvider.notifier).reset();
      if (mounted) context.go('/login');
    } catch (e) {
      _snack(friendlyErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _signingOutAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final user = ref.watch(currentUserProvider);
    final isEmailUser = user?.authProvider == 'email' && user?.isAnonymous != true;
    final isGoogleUser = user?.authProvider == 'google';
    final isGuest = user?.isAnonymous == true;

    final firebaseUser = FirebaseAuth.instance.currentUser;
    final lastSignIn = firebaseUser?.metadata.lastSignInTime;
    final createdAt = firebaseUser?.metadata.creationTime ?? user?.createdAt;
    final strength = _passwordStrength(_newPwCtrl.text);

    return Scaffold(
      backgroundColor: cl.bg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
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
                          offset: const Offset(0, 1))
                    ],
                  ),
                  child: Icon(Icons.arrow_back_rounded,
                      color: cl.textDark, size: 20),
                ),
              ),
              const Spacer(),
              Text(
                'Security',
                style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cl.textDark),
              ),
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
                  // ─── Account Overview ───────────────────────────────────
                  _sectionLabel('Account Overview'),
                  const SizedBox(height: 10),
                  _card(cl, [
                    _infoTile(
                      cl,
                      icon: Icons.shield_outlined,
                      label: 'Auth Method',
                      value: isGuest
                          ? 'Guest / Anonymous'
                          : isGoogleUser
                              ? 'Google Sign-In'
                              : 'Email & Password',
                      iconColor: cl.accent,
                    ),
                    _divider(cl),
                    _infoTile(
                      cl,
                      icon: Icons.calendar_today_outlined,
                      label: 'Account Created',
                      value: createdAt != null
                          ? _formatDate(createdAt)
                          : '—',
                    ),
                    _divider(cl),
                    _infoTile(
                      cl,
                      icon: Icons.login_rounded,
                      label: 'Last Sign-In',
                      value: lastSignIn != null
                          ? _formatDate(lastSignIn)
                          : '—',
                    ),
                    if (user?.email != null) ...[
                      _divider(cl),
                      _infoTile(
                        cl,
                        icon: Icons.mark_email_read_outlined,
                        label: 'Email Verified',
                        value: user?.isEmailVerified == true ? 'Yes' : 'No',
                        valueColor: user?.isEmailVerified == true
                            ? const Color(0xFF059669)
                            : const Color(0xFFDC4C4C),
                      ),
                    ],
                  ]),

                  // ─── Change Password ─────────────────────────────────────
                  if (isEmailUser) ...[
                    const SizedBox(height: 24),
                    _sectionLabel('Change Password'),
                    const SizedBox(height: 10),
                    Container(
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _pwField(
                            cl,
                            label: 'Current Password',
                            ctrl: _currentPwCtrl,
                            obscure: _obscureCurrent,
                            onToggle: () => setState(
                                () => _obscureCurrent = !_obscureCurrent),
                          ),
                          const SizedBox(height: 12),
                          _pwField(
                            cl,
                            label: 'New Password',
                            ctrl: _newPwCtrl,
                            obscure: _obscureNew,
                            hint: 'Min. 8 chars, 1 uppercase, 1 number',
                            onToggle: () =>
                                setState(() => _obscureNew = !_obscureNew),
                            onChanged: (_) => setState(() {}),
                          ),
                          // Strength bar
                          if (_newPwCtrl.text.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(children: [
                              ...List.generate(4, (i) {
                                final active = i < strength;
                                return Expanded(
                                  child: Container(
                                    margin: EdgeInsets.only(
                                        right: i < 3 ? 4 : 0),
                                    height: 4,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2),
                                      color: active
                                          ? _strengthColor(strength, cl)
                                          : cl.border,
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(width: 8),
                              Text(
                                _strengthLabel(strength),
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _strengthColor(strength, cl),
                                ),
                              ),
                            ]),
                          ],
                          const SizedBox(height: 12),
                          _pwField(
                            cl,
                            label: 'Confirm New Password',
                            ctrl: _confirmPwCtrl,
                            obscure: _obscureConfirm,
                            onToggle: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _savingPassword ? null : _changePassword,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
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
                                child: _savingPassword
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : Text(
                                        'Update Password',
                                        style: GoogleFonts.nunito(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ─── Password Reset ──────────────────────────────────────
                  if (isEmailUser) ...[
                    const SizedBox(height: 24),
                    _sectionLabel('Password Reset'),
                    const SizedBox(height: 10),
                    _card(cl, [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: cl.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.email_outlined,
                                  color: cl.accent, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Send Reset Link',
                                    style: GoogleFonts.nunito(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: cl.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Sends a password reset email to ${user?.email ?? 'your email'}.',
                                    style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        color: cl.textMid,
                                        height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: (_sendingReset || _resetSent)
                                  ? null
                                  : _sendPasswordReset,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _resetSent
                                      ? const Color(0xFF059669)
                                          .withValues(alpha: 0.1)
                                      : cl.accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: _sendingReset
                                    ? SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            color: cl.accent, strokeWidth: 2))
                                    : Text(
                                        _resetSent ? 'Sent ✓' : 'Send',
                                        style: GoogleFonts.nunito(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _resetSent
                                              ? const Color(0xFF059669)
                                              : cl.accent,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ],

                  // ─── Google Account ──────────────────────────────────────
                  if (isGoogleUser) ...[
                    const SizedBox(height: 24),
                    _sectionLabel('Google Account'),
                    const SizedBox(height: 10),
                    _card(cl, [
                      _infoTile(
                        cl,
                        icon: Icons.g_mobiledata_rounded,
                        label: 'Connected Account',
                        value: user?.email ?? '—',
                        iconColor: const Color(0xFF4285F4),
                      ),
                      _divider(cl),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Row(children: [
                          Icon(Icons.info_outline_rounded,
                              size: 16, color: cl.textLight),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Your password and two-factor authentication are managed through your Google account.',
                              style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  color: cl.textMid,
                                  height: 1.4),
                            ),
                          ),
                        ]),
                      ),
                    ]),
                  ],

                  // ─── Two-Factor Authentication ───────────────────────────
                  const SizedBox(height: 24),
                  _sectionLabel('Two-Factor Authentication'),
                  const SizedBox(height: 10),
                  _card(cl, [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.phonelink_lock_rounded,
                                color: Color(0xFF8B5CF6), size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text(
                                    '2FA / MFA',
                                    style: GoogleFonts.nunito(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: cl.textDark,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: cl.border,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Coming Soon',
                                      style: GoogleFonts.nunito(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: cl.textLight,
                                      ),
                                    ),
                                  ),
                                ]),
                                const SizedBox(height: 2),
                                Text(
                                  'Add an extra layer of security with an authenticator app or SMS.',
                                  style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      color: cl.textMid,
                                      height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),

                  // ─── Active Session ──────────────────────────────────────
                  const SizedBox(height: 24),
                  _sectionLabel('Active Session'),
                  const SizedBox(height: 10),
                  _card(cl, [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.devices_rounded,
                                color: Color(0xFF10B981), size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'This Device',
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: cl.textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  lastSignIn != null
                                      ? 'Signed in ${_timeAgo(lastSignIn)}'
                                      : 'Currently active',
                                  style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      color: cl.textMid),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _divider(cl),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        onTap: _signingOutAll ? null : _signOutAllDevices,
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                          child: Row(children: [
                            Icon(Icons.logout_rounded,
                                size: 18,
                                color: const Color(0xFFDC4C4C)
                                    .withValues(alpha: 0.8)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Sign Out This Device',
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFDC4C4C)
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                            if (_signingOutAll)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFDC4C4C),
                                ),
                              ),
                          ]),
                        ),
                      ),
                    ),
                  ]),

                  // ─── Security Tips ───────────────────────────────────────
                  const SizedBox(height: 24),
                  _sectionLabel('Security Tips'),
                  const SizedBox(height: 10),
                  _card(cl, [
                    _tipTile(cl,
                        icon: Icons.lock_reset_rounded,
                        text:
                            'Use a unique password not shared with other services.'),
                    _divider(cl),
                    _tipTile(cl,
                        icon: Icons.visibility_off_outlined,
                        text:
                            'Never share your password or one-time codes with anyone.'),
                    _divider(cl),
                    _tipTile(cl,
                        icon: Icons.wifi_lock_rounded,
                        text:
                            'Avoid accessing CLAiR on public Wi-Fi without a VPN.'),
                    _divider(cl),
                    _tipTile(cl,
                        icon: Icons.gavel_rounded,
                        text:
                            'Legal information shared in CLAiR is not covered by attorney-client privilege. Be mindful of what you submit.'),
                  ]),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _sectionLabel(String s) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          s,
          style: GoogleFonts.nunito(
              fontSize: 13, fontWeight: FontWeight.w700, color: context.c.textMid),
        ),
      );

  Widget _card(AppColorTheme cl, List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: cl.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cl.border),
          boxShadow: [
            BoxShadow(color: cl.cardShadow, blurRadius: 6, offset: const Offset(0, 2))
          ],
        ),
        child: Column(children: children),
      );

  Widget _divider(AppColorTheme cl) =>
      Divider(height: 1, indent: 48, color: cl.border);

  Widget _infoTile(
    AppColorTheme cl, {
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
    Color? valueColor,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Icon(icon, size: 20, color: iconColor ?? cl.textMid),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: cl.textDark)),
          ),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? cl.textMid,
            ),
          ),
        ]),
      );

  Widget _tipTile(AppColorTheme cl,
          {required IconData icon, required String text}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: cl.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: GoogleFonts.nunito(
                    fontSize: 13, color: cl.textMid, height: 1.4)),
          ),
        ]),
      );

  Widget _pwField(
    AppColorTheme cl, {
    required String label,
    required TextEditingController ctrl,
    required bool obscure,
    required VoidCallback onToggle,
    String? hint,
    ValueChanged<String>? onChanged,
  }) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 12, fontWeight: FontWeight.w600, color: cl.textMid)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: cl.fieldBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cl.border),
          ),
          child: TextField(
            controller: ctrl,
            obscureText: obscure,
            onChanged: onChanged,
            style: GoogleFonts.nunito(
                fontSize: 14, fontWeight: FontWeight.w600, color: cl.textDark),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              hintText: hint ?? '••••••••',
              hintStyle:
                  GoogleFonts.nunito(color: cl.textLight, fontSize: 13),
              prefixIcon: Icon(Icons.lock_outline_rounded,
                  size: 18, color: cl.textLight),
              suffixIcon: IconButton(
                icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: cl.textLight),
                onPressed: onToggle,
              ),
            ),
          ),
        ),
      ]);

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ─── Confirm Dialog ──────────────────────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    return Dialog(
      backgroundColor: cl.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(title,
              style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: cl.textDark)),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  fontSize: 13, color: cl.textMid, height: 1.5)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context, false),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: cl.fieldBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cl.border),
                  ),
                  child: Center(
                    child: Text('Cancel',
                        style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cl.textMid)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context, true),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: confirmColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(confirmLabel,
                        style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
