import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';
import 'package:clair/l10n/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loginWithEmail() async {
    final cl = context.c;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.loginWithEmail(email: email, password: password);
      ref.read(currentUserProvider.notifier).state = user;
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        final detail = _extractErrorDetail(e);
        if (detail.contains('verify your email')) {
          context.go('/verify-email', extra: {'email': email});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(detail),
              backgroundColor: cl.crimson,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _extractErrorDetail(Object e) {
    if (e is DioException && e.response?.data is Map) {
      final detail = (e.response!.data as Map)['detail'];
      if (detail is String) return detail;
    }
    return e.toString();
  }

  Future<void> _signInWithGoogle() async {
    final cl = context.c;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.signInWithGoogle();
      if (result.isNewUser) {
        if (mounted) {
          context.push('/signup/google');
        }
      } else if (result.user != null) {
        ref.read(currentUserProvider.notifier).state = result.user;
        if (mounted) context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: cl.crimson,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _continueAsGuest() async {
    final cl = context.c;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signInAsGuest();
      ref.read(currentUserProvider.notifier).state = user;
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: cl.crimson,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final compact = size.height < 860;
    final logoSize = compact ? 150.0 : 180.0;
    final logoPadding = compact ? 20.0 : 25.0;
    final headingGap = compact ? 24.0 : 40.0;
    final bottomGap = compact ? 16.0 : 30.0;

    return Scaffold(
      backgroundColor: cl.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: size.height - MediaQuery.of(context).padding.top,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(size.width, size.height * 0.35),
                  painter: WavyBackgroundPainter(
                    tanColor: cl.tan,
                    crimsonColor: cl.crimson,
                    darkBrownColor: cl.darkBrown,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      SizedBox(height: compact ? 12 : 20),

                      Container(
                        width: logoSize,
                        height: logoSize,
                        padding: EdgeInsets.all(logoPadding),
                        child: Image.asset(
                          'assets/images/CLAiR-icon.png',
                          fit: BoxFit.contain,
                          color: cl.accent,
                          colorBlendMode: BlendMode.srcIn,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.authWelcomeBack,
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w700,
                            color: cl.darkBrown,
                            fontFamily: 'Satoshi',
                            height: 1.2,
                          ),
                        ),
                      ),

                      SizedBox(height: headingGap),

                      _buildAnimatedInputField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        label: l10n.email,
                        icon: Icons.email_outlined,
                      ),

                      const SizedBox(height: 16),

                      _buildAnimatedInputField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        label: l10n.authPassword,
                        icon: Icons.lock_outline,
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onTogglePassword: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),

                      const SizedBox(height: 24),

                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              cl.crimson,
                              cl.darkBrown,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: cl.crimson.withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _isLoading ? null : _loginWithEmail,
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Text(
                                      l10n.authLogIn,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Satoshi',
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildGoogleButton(
                              onTap: _isLoading ? () {} : _signInWithGoogle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildGuestButton(
                              onTap: _isLoading ? () {} : _continueAsGuest,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: Text(
                          l10n.authForgotPassword,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: cl.crimson,
                            fontFamily: 'Satoshi',
                          ),
                        ),
                      ),

                      SizedBox(height: compact ? 12 : 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.authNoAccountPrompt,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: cl.darkBrown,
                              fontFamily: 'Satoshi',
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/signup'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              l10n.authSignUpLink,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: cl.crimson,
                                fontFamily: 'Satoshi',
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: bottomGap),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
  }) {
    final cl = context.c;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final hasText = value.text.isNotEmpty;
        final hasFocus = focusNode.hasFocus;
        final shouldFloat = hasText || hasFocus;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: cl.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasFocus ? cl.crimson : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: cl.tan.withOpacity(0.3),
                blurRadius: hasFocus ? 15 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              TextField(
                controller: controller,
                focusNode: focusNode,
                obscureText: isPassword && obscureText,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: cl.darkBrown,
                  fontFamily: 'Satoshi',
                ),
                decoration: InputDecoration(
                  hintText: shouldFloat ? '' : label,
                  hintStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: cl.darkBrown.withOpacity(0.4),
                    fontFamily: 'Satoshi',
                  ),
                  prefixIcon: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: Icon(
                      icon,
                      color: hasFocus
                          ? cl.crimson
                          : cl.crimson.withOpacity(0.6),
                      size: 20,
                    ),
                  ),
                  suffixIcon: isPassword && onTogglePassword != null
                      ? IconButton(
                          icon: Icon(
                            obscureText
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: cl.crimson.withOpacity(0.6),
                            size: 20,
                          ),
                          onPressed: onTogglePassword,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: cl.surface,
                  contentPadding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: shouldFloat ? 24 : 18,
                    bottom: shouldFloat ? 8 : 18,
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                left: 50,
                top: shouldFloat ? 8 : 18,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  opacity: shouldFloat ? 1.0 : 0.0,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    style: TextStyle(
                      fontSize: shouldFloat ? 11 : 15,
                      fontWeight: FontWeight.w500,
                      color: cl.crimson.withOpacity(0.8),
                      fontFamily: 'Satoshi',
                    ),
                    child: Text(label),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGoogleButton({required VoidCallback onTap}) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: cl.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cl.border,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: cl.tan.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: cl.surface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.g_mobiledata_rounded,
                color: cl.crimson,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.authGoogle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: cl.darkBrown,
                fontFamily: 'Satoshi',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestButton({required VoidCallback onTap}) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: cl.fieldBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cl.border,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: cl.tan.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              color: cl.darkBrown,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              l10n.authGuest,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: cl.darkBrown,
                fontFamily: 'Satoshi',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WavyBackgroundPainter extends CustomPainter {
  final Color tanColor;
  final Color crimsonColor;
  final Color darkBrownColor;

  WavyBackgroundPainter({
    required this.tanColor,
    required this.crimsonColor,
    required this.darkBrownColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          tanColor.withOpacity(0.4),
          crimsonColor.withOpacity(0.3),
          darkBrownColor.withOpacity(0.2),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.6);
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.7,
      size.width * 0.5,
      size.height * 0.65,
    );
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.6,
      0,
      size.height * 0.7,
    );
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);

    final paint2 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          crimsonColor.withOpacity(0.2),
          tanColor.withOpacity(0.3),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path2 = Path();
    path2.moveTo(size.width, 0);
    path2.lineTo(size.width, size.height * 0.5);
    path2.quadraticBezierTo(
      size.width * 0.6,
      size.height * 0.55,
      size.width * 0.3,
      size.height * 0.45,
    );
    path2.quadraticBezierTo(
      size.width * 0.1,
      size.height * 0.4,
      0,
      size.height * 0.5,
    );
    path2.lineTo(0, 0);
    path2.lineTo(size.width, 0);
    path2.close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
