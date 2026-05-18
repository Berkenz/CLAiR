import 'dart:math' show cos, sin, pi;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:clair/core/theme/appearance_provider.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  bool _navigated = false;

  // Trigger navigation this far before the video ends so the login screen's
  // fade-in covers the last frames — no black flash.
  static const _navTrigger = Duration(milliseconds: 700);
  // Hard ceiling: navigate at 5 s even if the video is still playing.
  static const _maxDuration = Duration(milliseconds: 5000);

  // Always-dark background — splash is its own world, no theme adaptation.
  static const _bg = Color(0xFF0A0A0F);

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ));

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);

    _controller = VideoPlayerController.asset('assets/images/1.mp4')
      ..setVolume(0)
      ..setLooping(false);

    _controller
        .initialize()
        .timeout(const Duration(seconds: 3))
        .then((_) {
      if (!mounted) return;
      setState(() {});
      _controller.play();
      _fadeCtrl.forward();
      _controller.addListener(_onProgress);
    }).catchError((Object _, StackTrace __) {
      // Hot reload / missing asset / timeout: still leave splash without crashing.
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fadeCtrl.forward();
        _navigate();
      });
    });

    // Hard ceiling: always navigate even if init hangs or video stalls.
    Future.delayed(_maxDuration, _navigate);
  }

  void _onProgress() {
    if (!_controller.value.isInitialized) return;
    final pos = _controller.value.position;
    final dur = _controller.value.duration;
    if (dur.inMilliseconds <= 0) return;
    if (dur - pos <= _navTrigger) _navigate();
  }

  Future<void> _navigate() async {
    if (_navigated || !mounted) return;
    _navigated = true;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ));

    // Check for an existing Firebase session so users don't have to
    // re-login every time they close and reopen the app.
    // Use a timeout + catch so a slow/unreachable backend never blocks navigation.
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null && !firebaseUser.isAnonymous) {
      try {
        final user = await ref
            .read(authRepositoryProvider)
            .getCurrentUser()
            .timeout(const Duration(seconds: 4));
        if (user != null && mounted) {
          ref.read(currentUserProvider.notifier).state = user;
          context.go('/home');
          return;
        }
      } catch (_) {
        // Network unavailable, timeout, or any error — fall through to login.
      }
    }

    if (mounted) context.go('/login');
  }

  @override
  void dispose() {
    _controller.removeListener(_onProgress);
    _controller.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only read accent for hue-rotation — no dark/light mode branching.
    final accent = ref.watch(appearanceProvider).accent;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        padding: EdgeInsets.zero,
        viewPadding: EdgeInsets.zero,
        viewInsets: EdgeInsets.zero,
      ),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        ),
        child: Material(
          color: _bg,
          child: _controller.value.isInitialized
              ? FadeTransition(
                  opacity: _fade,
                  child: _buildVideo(accent),
                )
              : const SizedBox.expand(),
        ),
      ),
    );
  }

  Widget _buildVideo(Color accent) {
    final size = _controller.value.size;

    final Widget video = SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );

    // Hue-rotate the video so its dominant red/maroon shifts to the accent hue.
    // Always full brightness — the splash is its own dark environment.
    final accentHue = HSLColor.fromColor(accent).hue;
    final matrix = _hueRotateMatrix(accentHue);

    return ColorFiltered(
      colorFilter: ColorFilter.matrix(matrix),
      child: video,
    );
  }

  static List<double> _hueRotateMatrix(double degrees) {
    final rad = degrees * pi / 180.0;
    final c = cos(rad);
    final s = sin(rad);

    const lr = 0.213;
    const lg = 0.715;
    const lb = 0.072;

    return [
      lr + c * (1 - lr) - s * lr,
      lg - c * lg - s * lg,
      lb - c * lb + s * (1 - lb),
      0.0, 0.0,
      lr - c * lr + s * 0.143,
      lg + c * (1 - lg) + s * 0.140,
      lb - c * lb - s * 0.283,
      0.0, 0.0,
      lr - c * lr - s * (1 - lr),
      lg - c * lg + s * lg,
      lb + c * (1 - lb) + s * lb,
      0.0, 0.0,
      0.0, 0.0, 0.0, 1.0, 0.0,
    ];
  }
}
