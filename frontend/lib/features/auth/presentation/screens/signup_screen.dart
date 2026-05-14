import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';
import 'package:clair/features/auth/presentation/screens/terms_of_use_screen.dart';
import 'package:clair/features/auth/presentation/screens/privacy_policy_screen.dart';
import 'package:clair/l10n/app_localizations.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final _firstNameFocusNode = FocusNode();
  final _lastNameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _agreedToTerms = false;

  Future<void> _signUp() async {
    final l10n = AppLocalizations.of(context)!;
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }
    if (!_agreedToTerms) {
      _showError(l10n.signupTermsPrivacyRequired);
      return;
    }
    if (!email.contains('@')) {
      _showError('Please enter a valid email');
      return;
    }
    if (password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      _showError('Password must contain at least one uppercase letter');
      return;
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      _showError('Password must contain at least one number');
      return;
    }
    if (password != confirmPassword) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.registerWithEmail(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      if (mounted) {
        context.go('/verify-email', extra: {'email': email});
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    final cl = context.c;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: cl.crimson,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _firstNameFocusNode.addListener(() => setState(() {}));
    _lastNameFocusNode.addListener(() => setState(() {}));
    _emailFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));
    _confirmPasswordFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: cl.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // Wavy Gradient Background
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: CustomPaint(
                size: Size(size.width, size.height * 0.35),
                painter: WavyBackgroundPainter(
                  tanColor: cl.tan,
                  crimsonColor: cl.crimson,
                  darkBrownColor: cl.darkBrown,
                ),
              ),
            ),
            
            // Scrollable Content
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    
                    // App Icon
                    Container(
                      width: 140,
                      height: 140,
                      padding: const EdgeInsets.all(20),
                      child: Image.asset(
                        'assets/images/CLAiR-icon.png',
                        fit: BoxFit.contain,
                        color: cl.accent,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                      
                      // Sign Up Text
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w700,
                            color: cl.darkBrown,
                            fontFamily: 'Satoshi',
                            height: 1.2,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // First Name & Last Name side by side
                      Row(
                        children: [
                          Expanded(
                            child: _buildAnimatedInputField(
                              controller: _firstNameController,
                              focusNode: _firstNameFocusNode,
                              label: 'First Name',
                              icon: Icons.person_outline,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildAnimatedInputField(
                              controller: _lastNameController,
                              focusNode: _lastNameFocusNode,
                              label: 'Last Name',
                              icon: Icons.person_outline,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Email Input
                      _buildAnimatedInputField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        label: 'Enter Email',
                        icon: Icons.email_outlined,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Password Input
                      _buildAnimatedInputField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        label: 'Enter Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onTogglePassword: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Confirm Password Input
                      _buildAnimatedInputField(
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordFocusNode,
                        label: 'Confirm Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        obscureText: _obscureConfirmPassword,
                        onTogglePassword: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 20),

                      // T&C Agreement Checkbox
                      _buildTermsCheckbox(cl, l10n),

                      const SizedBox(height: 20),
                      
                      // Sign Up Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: _agreedToTerms
                                ? [cl.crimson, cl.darkBrown]
                                : [cl.crimson.withOpacity(0.4), cl.darkBrown.withOpacity(0.4)],
                          ),
                          boxShadow: _agreedToTerms
                              ? [
                                  BoxShadow(
                                    color: cl.crimson.withOpacity(0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                              : [],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: (_isLoading || !_agreedToTerms) ? null : _signUp,
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Sign up',
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
                      
                      const SizedBox(height: 24),
                      
                      // Log In Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: cl.darkBrown,
                              fontFamily: 'Satoshi',
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Log in',
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
                      
                      const SizedBox(height: 30),
                    ],  // closes children array
                  ),    // closes Column
                ),      // closes Padding
              ),        // closes SingleChildScrollView
            ],          // closes Stack children
          ),            // closes Stack
        ),              // closes SafeArea
    );                  // closes Scaffold
  }

  Widget _buildTermsCheckbox(AppColorTheme cl, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _agreedToTerms
              ? cl.accent.withOpacity(0.08)
              : cl.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _agreedToTerms ? cl.accent : cl.border,
            width: _agreedToTerms ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: cl.cardShadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: _agreedToTerms,
                onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                activeColor: cl.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 12.5,
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w400,
                    color: cl.textMid,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(text: l10n.signupAgreementLead),
                    TextSpan(
                      text: l10n.termsOfUse,
                      style: TextStyle(
                        color: cl.accent,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TermsOfUseScreen(),
                            ),
                          );
                        },
                    ),
                    TextSpan(text: l10n.signupAgreementMiddle),
                    TextSpan(
                      text: l10n.privacyPolicy,
                      style: TextStyle(
                        color: cl.accent,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyScreen(),
                            ),
                          );
                        },
                    ),
                    TextSpan(
                      text: l10n.signupAgreementTail,
                      style: TextStyle(color: cl.textMid),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
              color: hasFocus
                  ? cl.crimson
                  : Colors.transparent,
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
