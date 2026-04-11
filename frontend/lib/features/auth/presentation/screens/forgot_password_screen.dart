import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/auth/presentation/widgets/auth_hero.dart';
import 'package:clair/shared/widgets/spring_button.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  int _page = 0;
  bool _loading = false;

  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confCtrl = TextEditingController();
  final _emailFn = FocusNode(), _codeFn = FocusNode(), _newFn = FocusNode(), _confFn = FocusNode();
  bool _obsN = true, _obsC = true;

  late final AnimationController _anim;
  late final CurvedAnimation _f0, _f1, _f2, _f3;

  @override
  void initState() {
    super.initState();
    for (final fn in [_emailFn, _codeFn, _newFn, _confFn]) {
      fn.addListener(() => setState(() {}));
    }
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 580))..forward();
    _f0 = CurvedAnimation(parent: _anim, curve: const Interval(0.00, 0.40, curve: Curves.easeOut));
    _f1 = CurvedAnimation(parent: _anim, curve: const Interval(0.14, 0.56, curve: Curves.easeOut));
    _f2 = CurvedAnimation(parent: _anim, curve: const Interval(0.30, 0.72, curve: Curves.easeOut));
    _f3 = CurvedAnimation(parent: _anim, curve: const Interval(0.48, 1.00, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _anim.dispose();
    for (final c in [_emailCtrl, _codeCtrl, _newCtrl, _confCtrl]) { c.dispose(); }
    for (final f in [_emailFn, _codeFn, _newFn, _confFn]) { f.dispose(); }
    super.dispose();
  }

  Widget _fade(Widget w, CurvedAnimation a) => AnimatedBuilder(
    animation: a, builder: (_, c) => Opacity(opacity: a.value,
        child: Transform.translate(offset: Offset(0, (1 - a.value) * 12), child: c)), child: w);

  Future<void> _send() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() { _loading = false; _page = 1; });
  }

  Future<void> _reset() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        resizeToAvoidBottomInset: true,
        body: Column(children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _page == 0
                ? const AuthHeroPanel(key: ValueKey(0), headline: 'Forgot\nPassword?', subtext: "Enter your email and we'll send a reset link.", showBack: true)
                : AuthHeroPanel(key: const ValueKey(1), headline: 'Check Your\nEmail', subtext: 'Enter the code sent to ${_emailCtrl.text.isEmpty ? 'your email' : _emailCtrl.text}', showBack: true),
          ),
          Expanded(child: _fade(Container(
            decoration: const BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28))),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _page == 0 ? _emailForm(key: const ValueKey('e')) : _verifyForm(key: const ValueKey('v')),
            ),
          ), _f0)),
        ]),
      ),
    );
  }

  Widget _emailForm({Key? key}) {
    return SingleChildScrollView(key: key, padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _fade(_field('Email', _emailCtrl, _emailFn, hint: 'your@email.com', type: TextInputType.emailAddress), _f1),
        const SizedBox(height: 28),
        _fade(_btn(_loading ? 'Sending…' : 'Send Reset Link', _loading ? null : _send), _f2),
        const SizedBox(height: 20),
        _fade(Center(child: GestureDetector(onTap: () => Navigator.pop(context),
            child: Text('Back to Login', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMid)))), _f3),
      ]),
    );
  }

  Widget _verifyForm({Key? key}) {
    return SingleChildScrollView(key: key, padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _field('Verification Code', _codeCtrl, _codeFn, hint: '6-digit code', type: TextInputType.number),
        const SizedBox(height: 14),
        _field('New Password', _newCtrl, _newFn, hint: '••••••••', isPass: true, obsc: _obsN, toggle: () => setState(() => _obsN = !_obsN)),
        const SizedBox(height: 14),
        _field('Confirm', _confCtrl, _confFn, hint: '••••••••', isPass: true, obsc: _obsC, toggle: () => setState(() => _obsC = !_obsC)),
        const SizedBox(height: 28),
        _btn(_loading ? 'Resetting…' : 'Reset Password', _loading ? null : _reset),
        const SizedBox(height: 18),
        Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text("Didn't receive it? ", style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textMid)),
          GestureDetector(onTap: () => setState(() => _page = 0),
              child: Text('Resend', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accent))),
        ])),
      ]),
    );
  }

  Widget _field(String label, TextEditingController c, FocusNode fn,
      {String hint = '', bool isPass = false, bool obsc = false, VoidCallback? toggle, TextInputType type = TextInputType.text}) {
    final f = fn.hasFocus;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: f ? AppColors.accent : AppColors.textMid)),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(color: f ? Colors.white : AppColors.fieldBg, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: f ? AppColors.accent : AppColors.border)),
        child: TextField(controller: c, focusNode: fn, obscureText: isPass && obsc, keyboardType: type,
          style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
          decoration: InputDecoration(border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            hintText: hint, hintStyle: GoogleFonts.nunito(color: AppColors.textLight, fontSize: 15),
            suffixIcon: isPass ? IconButton(icon: Icon(obsc ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textLight, size: 18), onPressed: toggle) : null)),
      ),
    ]);
  }

  Widget _btn(String label, VoidCallback? onTap) {
    final dis = onTap == null;
    final box = Container(
      width: double.infinity, height: 52,
      decoration: BoxDecoration(
        gradient: dis ? null : const LinearGradient(colors: [AppColors.accent, AppColors.accentDark]),
        color: dis ? AppColors.border : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: dis ? [] : [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Center(child: Text(label, style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: dis ? AppColors.textMid : Colors.white))),
    );
    return dis ? box : SpringButton(onTap: onTap, child: box);
  }
}

typedef VerifyEmailScreen = ForgotPasswordScreen;
