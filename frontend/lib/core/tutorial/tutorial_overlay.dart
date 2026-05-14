import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/core/tutorial/tutorial_provider.dart';
import 'package:clair/l10n/app_localizations.dart';

/// Data for a single tutorial step.
class _TutorialStep {
  final IconData icon;
  final String Function(AppLocalizations) title;
  final String Function(AppLocalizations) body;
  /// Index of the bottom-nav item to spotlight, or null for a full-screen card.
  final int? navSpotlight;

  const _TutorialStep({
    required this.icon,
    required this.title,
    required this.body,
    this.navSpotlight,
  });
}

const _steps = <_TutorialStep>[
  _TutorialStep(
    icon: Icons.waving_hand_rounded,
    title: _welcomeTitle,
    body: _welcomeBody,
  ),
  _TutorialStep(
    icon: Icons.chat_bubble_rounded,
    title: _chatTitle,
    body: _chatBody,
    navSpotlight: 1,
  ),
  _TutorialStep(
    icon: Icons.balance_rounded,
    title: _lawyersTitle,
    body: _lawyersBody,
    navSpotlight: 3,
  ),
  _TutorialStep(
    icon: Icons.library_books_rounded,
    title: _libraryTitle,
    body: _libraryBody,
    navSpotlight: 2,
  ),
  _TutorialStep(
    icon: Icons.event_note_rounded,
    title: _appointmentsTitle,
    body: _appointmentsBody,
    navSpotlight: 4,
  ),
];

String _welcomeTitle(AppLocalizations l) => l.tutorialWelcomeTitle;
String _welcomeBody(AppLocalizations l) => l.tutorialWelcomeBody;
String _chatTitle(AppLocalizations l) => l.tutorialChatTitle;
String _chatBody(AppLocalizations l) => l.tutorialChatBody;
String _lawyersTitle(AppLocalizations l) => l.tutorialLawyersTitle;
String _lawyersBody(AppLocalizations l) => l.tutorialLawyersBody;
String _libraryTitle(AppLocalizations l) => l.tutorialLibraryTitle;
String _libraryBody(AppLocalizations l) => l.tutorialLibraryBody;
String _appointmentsTitle(AppLocalizations l) => l.tutorialAppointmentsTitle;
String _appointmentsBody(AppLocalizations l) => l.tutorialAppointmentsBody;

/// Full-screen overlay that teaches the user about the main tabs.
///
/// Pass [navItemKeys] — a list of `GlobalKey`s attached to each bottom-nav
/// item — so the overlay can spotlight the correct element.
class TutorialOverlay extends ConsumerStatefulWidget {
  const TutorialOverlay({super.key, required this.navItemKeys});

  final List<GlobalKey> navItemKeys;

  @override
  ConsumerState<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends ConsumerState<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<double> _cardSlide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _cardSlide = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _animateStep(VoidCallback action) {
    _anim.reverse().then((_) {
      action();
      _anim.forward();
    });
  }

  Rect? _spotlightRect(int navIndex) {
    if (navIndex < 0 || navIndex >= widget.navItemKeys.length) return null;
    final key = widget.navItemKeys[navIndex];
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final offset = box.localToGlobal(Offset.zero);
    return offset & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tutorialProvider);
    if (!state.show) return const SizedBox.shrink();

    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    final step = _steps[state.step.clamp(0, _steps.length - 1)];
    final spotlightIdx = step.navSpotlight;
    final rect = spotlightIdx != null ? _spotlightRect(spotlightIdx) : null;

    return FadeTransition(
      opacity: _fade,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // ── Dark scrim with optional spotlight cutout ────────────
            Positioned.fill(
              child: GestureDetector(
                onTap: () {},
                child: CustomPaint(
                  painter: _SpotlightPainter(
                    spotlightRect: rect,
                    scrimColor: Colors.black.withValues(alpha: 0.72),
                  ),
                ),
              ),
            ),

            // ── Spotlight pulse ring ────────────────────────────────
            if (rect != null)
              Positioned(
                left: rect.center.dx - 34,
                top: rect.center.dy - 34,
                child: IgnorePointer(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: cl.accent.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),

            // ── Card ────────────────────────────────────────────────
            Positioned(
              left: 24,
              right: 24,
              // If there's a spotlight, position card above the bottom nav.
              // Otherwise center it vertically.
              bottom: rect != null
                  ? MediaQuery.of(context).size.height -
                      rect.top +
                      20
                  : null,
              top: rect == null
                  ? MediaQuery.of(context).size.height * 0.28
                  : null,
              child: AnimatedBuilder(
                animation: _cardSlide,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _cardSlide.value),
                  child: child,
                ),
                child: _StepCard(
                  step: step,
                  state: state,
                  cl: cl,
                  l10n: l10n,
                  onNext: () => _animateStep(
                      () => ref.read(tutorialProvider.notifier).next()),
                  onBack: () => _animateStep(
                      () => ref.read(tutorialProvider.notifier).back()),
                  onSkip: () async {
                    await _anim.reverse();
                    if (mounted) ref.read(tutorialProvider.notifier).skip();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step card ─────────────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.state,
    required this.cl,
    required this.l10n,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  final _TutorialStep step;
  final TutorialState state;
  final AppColorTheme cl;
  final AppLocalizations l10n;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cl.accent.withValues(alpha: isDark ? 0.18 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(step.icon, size: 28, color: cl.accent),
          ),
          const SizedBox(height: 18),

          // Title
          Text(
            step.title(l10n),
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: cl.textDark,
            ),
          ),
          const SizedBox(height: 10),

          // Body
          Text(
            step.body(l10n),
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: cl.textMid,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 22),

          // Progress dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(state.totalSteps, (i) {
              final active = i == state.step;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: active ? 20 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: active
                      ? cl.accent
                      : cl.textLight.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Step indicator + buttons
          Row(
            children: [
              // Skip / Back
              if (state.isFirst)
                _TextBtn(
                  label: l10n.tutorialSkip,
                  color: cl.textMid,
                  onTap: onSkip,
                )
              else
                _TextBtn(
                  label: l10n.tutorialBack,
                  color: cl.textMid,
                  onTap: onBack,
                ),

              const Spacer(),

              // Step counter
              Text(
                l10n.tutorialStepOf(
                  (state.step + 1).toString(),
                  state.totalSteps.toString(),
                ),
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cl.textLight,
                ),
              ),

              const Spacer(),

              // Next / Done
              _PrimaryBtn(
                label: state.isLast ? l10n.tutorialDone : l10n.tutorialNext,
                accent: cl.accent,
                onTap: onNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Buttons ───────────────────────────────────────────────────────────────────

class _TextBtn extends StatelessWidget {
  const _TextBtn({required this.label, required this.color, required this.onTap});

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  const _PrimaryBtn({required this.label, required this.accent, required this.onTap});

  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Spotlight painter ─────────────────────────────────────────────────────────

class _SpotlightPainter extends CustomPainter {
  final Rect? spotlightRect;
  final Color scrimColor;

  _SpotlightPainter({this.spotlightRect, required this.scrimColor});

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Offset.zero & size;

    if (spotlightRect == null) {
      canvas.drawRect(fullRect, Paint()..color = scrimColor);
      return;
    }

    // Expand the spotlight a bit for padding around the nav item.
    final padded = spotlightRect!.inflate(14);
    final center = padded.center;
    final radius = padded.longestSide / 2 + 6;

    final path = Path()
      ..addRect(fullRect)
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, Paint()..color = scrimColor);
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.spotlightRect != spotlightRect || old.scrimColor != scrimColor;
}
