import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';

/// The app's animated first frame.
///
/// Runs entirely off [AnimationController]s driven by a single
/// [Ticker] (via [TickerProviderStateMixin]) rather than chained
/// `Future.delayed` calls, so every element — glow, floating code
/// tokens, the terminal caret, the typed title — stays perfectly in
/// sync and scales cleanly with `dart:ui`'s frame timing instead of
/// wall-clock timers.
///
/// [onFinished] fires once the exit animation completes; the caller
/// (the router) is responsible for navigating onward. This widget
/// never navigates itself, so it stays trivially reusable/testable.
class SplashScreen extends StatefulWidget {
  const SplashScreen({required this.onFinished, super.key});

  final VoidCallback onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Ambient loop: breathing glow + slowly drifting background particles.
  // Runs continuously for as long as the splash is on screen.
  late final AnimationController _ambientController;

  // One-shot intro: mark scale/glow-in, caret blink, typed title,
  // subtitle fade, progress dots — sequenced by Interval()s below.
  late final AnimationController _introController;

  // Exit: quick scale + fade the whole splash out before handing off.
  late final AnimationController _exitController;

  static const String _title = 'CodeQuest';
  static const Duration _introDuration = Duration(milliseconds: 2200);
  static const Duration _minimumHold = Duration(milliseconds: 2800);

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.darkBackground,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    _ambientController = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);

    _introController = AnimationController(vsync: this, duration: _introDuration);
    _exitController = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));

    _introController.forward();
    _runSequence();
  }

  Future<void> _runSequence() async {
    // Hold on the fully-revealed mark for a beat so the animation
    // doesn't feel rushed even on a fast cold start, then exit.
    await Future.delayed(_minimumHold);
    if (!mounted) return;
    await _exitController.forward();
    if (!mounted) return;
    widget.onFinished();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _introController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.sizeOf(context);

    return AnimatedBuilder(
      animation: _exitController,
      builder: (BuildContext context, Widget? child) {
        final double exitT = Curves.easeInCubic.transform(_exitController.value);
        return Opacity(
          opacity: 1 - exitT,
          child: Transform.scale(
            scale: 1 + exitT * 0.08,
            child: child,
          ),
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: SizedBox(
          width: screen.width,
          height: screen.height,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // Layer 1 — ambient breathing radial glow behind everything.
              AnimatedBuilder(
                animation: _ambientController,
                builder: (BuildContext context, _) {
                  final double breathe = Curves.easeInOut.transform(_ambientController.value);
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.15),
                        radius: 1.1,
                        colors: <Color>[
                          AppColors.accentIndigo.withValues(alpha: 0.20 + breathe * 0.10),
                          AppColors.accentIndigo.withValues(alpha: 0.06),
                          AppColors.darkBackground,
                        ],
                        stops: const <double>[0.0, 0.45, 1.0],
                      ),
                    ),
                  );
                },
              ),

              // Layer 2 — slow-drifting code-token particles.
              AnimatedBuilder(
                animation: _ambientController,
                builder: (BuildContext context, _) {
                  return CustomPaint(
                    painter: _CodeParticlesPainter(
                      t: _ambientController.value,
                      color: AppColors.accentIndigo,
                    ),
                  );
                },
              ),

              // Layer 3 — the mark + typed title, centered.
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _TerminalMark(ambient: _ambientController),
                    const SizedBox(height: 28),
                    _TypedTitle(text: _title, controller: _introController),
                    const SizedBox(height: 10),
                    _Subtitle(controller: _introController),
                  ],
                ),
              ),

              // Layer 4 — loading dots, pinned near the bottom.
              Align(
                alignment: const Alignment(0, 0.86),
                child: _LoadingDots(controller: _introController),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The `>_` terminal-prompt mark: circular glow badge with a
/// `>` chevron and a blinking block caret, scaling in with a
/// slight overshoot to match the app's existing `easeOutBack`
/// language (see OnboardingScreen's icon entrance).
class _TerminalMark extends StatelessWidget {
  const _TerminalMark({required this.ambient});

  final Animation<double> ambient;

  @override
  Widget build(BuildContext context) {
    // The one-shot entrance (.animate().scale().fadeIn()) must wrap the
    // *outside* and run exactly once on mount. Nesting it inside the
    // ambient AnimatedBuilder's `builder` would rebuild — and so
    // restart — that entrance animation on every breathing-glow tick.
    return AnimatedBuilder(
          animation: ambient,
          builder: (BuildContext context, _) {
            final double breathe = Curves.easeInOut.transform(ambient.value);
            return Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: <Color>[AppColors.accentIndigoMuted, AppColors.accentIndigo],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.accentIndigo.withValues(alpha: 0.35 + breathe * 0.20),
                    blurRadius: 36 + breathe * 16,
                    spreadRadius: 2 + breathe * 4,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const _CaretGlyph(),
            );
          },
        )
        .animate()
        .scale(
          duration: 650.ms,
          curve: Curves.easeOutBack,
          begin: const Offset(0.3, 0.3),
          end: const Offset(1, 1),
        )
        .fadeIn(duration: 350.ms);
  }
}

/// `>` chevron followed by a caret block that blinks like a terminal
/// cursor waiting for input — a small detail that sells the
/// "code editor" identity established in AppTypography's doc comment.
class _CaretGlyph extends StatefulWidget {
  const _CaretGlyph();

  @override
  State<_CaretGlyph> createState() => _CaretGlyphState();
}

class _CaretGlyphState extends State<_CaretGlyph> with SingleTickerProviderStateMixin {
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(vsync: this, duration: const Duration(milliseconds: 650))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Text(
          '>',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 42,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1,
          ),
        ),
        const SizedBox(width: 4),
        FadeTransition(
          opacity: _blink.drive(CurveTween(curve: Curves.easeInOut)),
          child: Container(
            width: 10,
            height: 34,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}

/// Types [text] out character-by-character in the app's monospace
/// code face, then settles into the regular display face — echoing
/// the "typed code" motif without needing a real terminal widget.
class _TypedTitle extends StatelessWidget {
  const _TypedTitle({required this.text, required this.controller});

  final String text;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    // Typing happens across the early-to-mid portion of the intro
    // timeline, after the mark has finished its entrance.
    final Animation<int> charCount = StepTween(begin: 0, end: text.length).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.22, 0.62, curve: Curves.easeOut),
      ),
    );

    return AnimatedBuilder(
      animation: charCount,
      builder: (BuildContext context, _) {
        final String shown = text.substring(0, charCount.value);
        final bool done = charCount.value == text.length;
        return RichText(
          text: TextSpan(
            children: <InlineSpan>[
              TextSpan(
                text: shown,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
              if (!done)
                const TextSpan(
                  text: '▌',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentIndigo,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final Animation<double> fade = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.62, 0.85, curve: Curves.easeOut),
    );
    final Animation<Offset> slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(fade);

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: Text(
          'Учись программировать играя',
          style: TextStyle(
            fontFamily: 'sans-serif',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
            color: AppColors.darkTextSecondary,
          ),
        ),
      ),
    );
  }
}

/// Three dots that pulse in a left-to-right chase, appearing last in
/// the intro sequence as a subtle "loading" affordance.
class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final Animation<double> reveal = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.85, 1.0, curve: Curves.easeOut),
    );

    return FadeTransition(
      opacity: reveal,
      child: const _DotsChase(),
    );
  }
}

class _DotsChase extends StatefulWidget {
  const _DotsChase();

  @override
  State<_DotsChase> createState() => _DotsChaseState();
}

class _DotsChaseState extends State<_DotsChase> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(3, (int i) {
            final double phase = (_controller.value - i * 0.18) % 1.0;
            final double t = math.sin(phase * math.pi).clamp(0.0, 1.0);
            return Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(
                  AppColors.darkBorder,
                  AppColors.accentIndigo,
                  t,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Faint, slowly-drifting code glyphs (`{ }`, `< / >`, `01`, `;`,
/// `fn`) scattered behind the mark. Positions/glyphs/phases are
/// deterministic (seeded [math.Random]) so the layout is stable
/// across rebuilds instead of jumping every frame.
class _CodeParticlesPainter extends CustomPainter {
  _CodeParticlesPainter({required this.t, required this.color});

  final double t;
  final Color color;

  static const List<String> _glyphs = <String>['{ }', '< / >', '01', ';', 'fn', '=>', '#', '01'];

  @override
  void paint(Canvas canvas, Size size) {
    final math.Random rnd = math.Random(7);

    for (int i = 0; i < _glyphs.length; i++) {
      final double baseX = rnd.nextDouble();
      final double baseY = rnd.nextDouble();
      final double driftSpeed = 0.4 + rnd.nextDouble() * 0.6;
      final double phase = rnd.nextDouble() * math.pi * 2;

      // Gentle vertical bob + very slow horizontal sway.
      final double dy = math.sin((t * math.pi * 2 * driftSpeed) + phase) * 10;
      final double dx = math.cos((t * math.pi * 2 * driftSpeed * 0.5) + phase) * 6;

      final double opacity = 0.05 + 0.06 * (0.5 + 0.5 * math.sin((t * math.pi * 2) + phase));

      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: _glyphs[i],
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 15 + rnd.nextDouble() * 8,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final Offset origin = Offset(
        (baseX * size.width) + dx,
        (baseY * size.height * 0.85) + dy,
      );

      tp.paint(canvas, origin);
    }
  }

  @override
  bool shouldRepaint(covariant _CodeParticlesPainter oldDelegate) => oldDelegate.t != t;
}
