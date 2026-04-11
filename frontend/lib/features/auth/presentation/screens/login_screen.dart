import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';
import 'package:clair/features/auth/presentation/screens/signup_screen.dart';
import 'package:clair/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:clair/features/auth/presentation/widgets/auth_hero.dart';
import 'package:clair/shared/widgets/spring_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _emailFn    = FocusNode();
  final _passFn     = FocusNode();
  bool _obscure     = true;

  late final AnimationController _anim;
  late final CurvedAnimation _f0, _f1, _f2, _f3, _f4, _f5;

  @override
  void initState() {
    super.initState();
    _emailFn.addListener(() => setState(() {}));
    _passFn.addListener(() => setState(() {}));
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _f0 = CurvedAnimation(parent: _anim, curve: const Interval(0.00, 0.40, curve: Curves.easeOut));
    _f1 = CurvedAnimation(parent: _anim, curve: const Interval(0.10, 0.50, curve: Curves.easeOut));
    _f2 = CurvedAnimation(parent: _anim, curve: const Interval(0.20, 0.60, curve: Curves.easeOut));
    _f3 = CurvedAnimation(parent: _anim, curve: const Interval(0.30, 0.70, curve: Curves.easeOut));
    _f4 = CurvedAnimation(parent: _anim, curve: const Interval(0.40, 0.80, curve: Curves.easeOut));
    _f5 = CurvedAnimation(parent: _anim, curve: const Interval(0.50, 1.00, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _anim.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFn.dispose();
    _passFn.dispose();
    super.dispose();
  }

  Widget _fade(Widget w, CurvedAnimation a) => AnimatedBuilder(
    animation: a,
    builder: (_, c) => Opacity(opacity: a.value,
        child: Transform.translate(offset: Offset(0, (1 - a.value) * 12), child: c)),
    child: w,
  );

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        resizeToAvoidBottomInset: true,
        body: Column(children: [
          const AuthHeroPanel(headline: 'Welcome\nBack', subtext: 'Sign in to access your legal assistant.'),
          Expanded(
            child: _fade(
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _fade(_field('Email', _emailCtrl, _emailFn, hint: 'your@email.com', type: TextInputType.emailAddress), _f1),
                    const SizedBox(height: 16),
                    _fade(_field('Password', _passCtrl, _passFn, hint: '••••••••', isPass: true), _f2),
                    const SizedBox(height: 8),
                    _fade(Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                        child: Text('Forgot password?', style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
                      ),
                    ), _f2),
                    const SizedBox(height: 28),
                    _fade(_primaryBtn('Log In', () => context.go('/home')), _f3),
                    const SizedBox(height: 20),
                    _fade(_divider(), _f4),
                    const SizedBox(height: 16),
                    _fade(Row(children: [
                      Expanded(child: _socialBtn('Google', Icons.g_mobiledata_rounded,
                          () => ref.read(signInWithGoogleProvider.notifier).signInWithGoogle())),
                      const SizedBox(width: 12),
                      Expanded(child: _socialBtn('Guest', Icons.person_outline_rounded, () {})),
                    ]), _f4),
                    const SizedBox(height: 28),
                    _fade(Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text("Don't have an account? ", style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textMid)),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen())),
                        child: Text('Sign Up', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accent)),
                      ),
                    ])), _f5),
                  ]),
                ),
              ),
              _f0,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, FocusNode fn,
      {String hint = '', bool isPass = false, TextInputType type = TextInputType.text}) {
    final f = fn.hasFocus;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: f ? AppColors.accent : AppColors.textMid)),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: f ? Colors.white : AppColors.fieldBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: f ? AppColors.accent : AppColors.border),
        ),
        child: TextField(
          controller: c, focusNode: fn, obscureText: isPass && _obscure, keyboardType: type,
          style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            hintText: hint,
            hintStyle: GoogleFonts.nunito(color: AppColors.textLight, fontSize: 15),
            suffixIcon: isPass
                ? IconButton(icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppColors.textLight, size: 18), onPressed: () => setState(() => _obscure = !_obscure))
                : null,
          ),
        ),
      ),
    ]);
  }

  Widget _primaryBtn(String label, VoidCallback onTap) {
    return SpringButton(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentDark]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Center(child: Text(label,
            style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))),
      ),
    );
  }

  Widget _divider() => Row(children: [
    const Expanded(child: Divider(color: AppColors.border)),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text('or', style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textLight))),
    const Expanded(child: Divider(color: AppColors.border)),
  ]);

  Widget _socialBtn(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.fieldBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 20, color: AppColors.textMid),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        ]),
      ),
    );
  }
}
