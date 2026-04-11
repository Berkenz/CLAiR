import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/auth/presentation/widgets/auth_hero.dart';
import 'package:clair/shared/widgets/spring_button.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});
  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _firstCtrl = TextEditingController();
  final _lastCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _confCtrl  = TextEditingController();
  final _firstFn = FocusNode(), _lastFn = FocusNode(), _emailFn = FocusNode(),
        _passFn = FocusNode(), _confFn = FocusNode();
  bool _obsP = true, _obsC = true;

  late final AnimationController _anim;
  late final CurvedAnimation _f0, _f1, _f2, _f3, _f4, _f5;

  @override
  void initState() {
    super.initState();
    for (final fn in [_firstFn, _lastFn, _emailFn, _passFn, _confFn]) {
      fn.addListener(() => setState(() {}));
    }
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 640))..forward();
    _f0 = CurvedAnimation(parent: _anim, curve: const Interval(0.00, 0.38, curve: Curves.easeOut));
    _f1 = CurvedAnimation(parent: _anim, curve: const Interval(0.10, 0.48, curve: Curves.easeOut));
    _f2 = CurvedAnimation(parent: _anim, curve: const Interval(0.20, 0.58, curve: Curves.easeOut));
    _f3 = CurvedAnimation(parent: _anim, curve: const Interval(0.30, 0.68, curve: Curves.easeOut));
    _f4 = CurvedAnimation(parent: _anim, curve: const Interval(0.44, 0.82, curve: Curves.easeOut));
    _f5 = CurvedAnimation(parent: _anim, curve: const Interval(0.58, 1.00, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _anim.dispose();
    for (final c in [_firstCtrl, _lastCtrl, _emailCtrl, _passCtrl, _confCtrl]) { c.dispose(); }
    for (final f in [_firstFn, _lastFn, _emailFn, _passFn, _confFn]) { f.dispose(); }
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
          const AuthHeroPanel(headline: 'Create\nAccount', subtext: 'Join CLAiR and get legal support today.', showBack: true),
          Expanded(child: _fade(Container(
            decoration: const BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28))),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _fade(Row(children: [
                  Expanded(child: _field('First Name', _firstCtrl, _firstFn, hint: 'Juan')),
                  const SizedBox(width: 12),
                  Expanded(child: _field('Last Name', _lastCtrl, _lastFn, hint: 'Dela Cruz')),
                ]), _f1),
                const SizedBox(height: 14),
                _fade(_field('Email', _emailCtrl, _emailFn, hint: 'your@email.com', type: TextInputType.emailAddress), _f2),
                const SizedBox(height: 14),
                _fade(_field('Password', _passCtrl, _passFn, hint: '••••••••', isPass: true, obsc: _obsP, toggle: () => setState(() => _obsP = !_obsP)), _f3),
                const SizedBox(height: 14),
                _fade(_field('Confirm Password', _confCtrl, _confFn, hint: '••••••••', isPass: true, obsc: _obsC, toggle: () => setState(() => _obsC = !_obsC)), _f3),
                const SizedBox(height: 24),
                _fade(SpringButton(onTap: () => Navigator.pop(context), child: Container(
                  width: double.infinity, height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentDark]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Center(child: Text('Create Account', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))),
                )), _f4),
                const SizedBox(height: 24),
                _fade(Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Already have an account? ', style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textMid)),
                  GestureDetector(onTap: () => Navigator.pop(context),
                      child: Text('Sign In', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accent))),
                ])), _f5),
              ]),
            ),
          ), _f0)),
        ]),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, FocusNode fn,
      {String hint = '', bool isPass = false, bool obsc = false, VoidCallback? toggle, TextInputType type = TextInputType.text}) {
    final f = fn.hasFocus;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: f ? AppColors.accent : AppColors.textMid)),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
          color: f ? Colors.white : AppColors.fieldBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: f ? AppColors.accent : AppColors.border),
        ),
        child: TextField(
          controller: c, focusNode: fn, obscureText: isPass && obsc, keyboardType: type,
          style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            hintText: hint, hintStyle: GoogleFonts.nunito(color: AppColors.textLight, fontSize: 15),
            suffixIcon: isPass
                ? IconButton(icon: Icon(obsc ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textLight, size: 18), onPressed: toggle)
                : null,
          ),
        ),
      ),
    ]);
  }
}
