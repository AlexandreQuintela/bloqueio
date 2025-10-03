import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'game_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _glowPulse;
  late final Animation<double> _boardProgress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.9, curve: Curves.easeOutBack),
      ),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.18), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
          ),
        );
    _glowPulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );
    _boardProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutQuart),
    );

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            PageRouteBuilder<void>(
              pageBuilder: (_, __, ___) => const GameSetupScreen(),
              transitionsBuilder: (_, animation, __, child) => FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeIn,
                ),
                child: child,
              ),
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1C37), Color(0xFF071426)],
          ),
        ),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _boardProgress,
              builder: (context, child) => CustomPaint(
                painter: _BoardGlowPainter(progress: _boardProgress.value),
              ),
            ),
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _BoardPreview(
                          glowStrength: _glowPulse.value,
                          boardProgress: _boardProgress.value,
                        ),
                        const SizedBox(height: 40),
                        ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return const LinearGradient(
                              colors: [Color(0xFF35D080), Color(0xFF3A78FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds);
                          },
                          child: Text(
                            'Quoridor',
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'estratégia, bloqueios e grandes jogadas',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white70,
                            letterSpacing: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 36),
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                0,
                                math.sin(_controller.value * math.pi) * 4,
                              ),
                              child: child,
                            );
                          },
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF35D080), Color(0xFF2A7BFF)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF2A7BFF,
                                  ).withValues(alpha: 0.4),
                                  blurRadius: 18,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              size: 32,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardPreview extends StatelessWidget {
  const _BoardPreview({
    required this.glowStrength,
    required this.boardProgress,
  });

  final double glowStrength;
  final double boardProgress;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.08 + 0.08 * glowStrength),
            Colors.white.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18 + 0.2 * glowStrength),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: 0.3 + 0.5 * boardProgress,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF20385C), Color(0xFF132341)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            CustomPaint(
              painter: _GridPainter(progress: boardProgress),
              child: const SizedBox.expand(),
            ),
            _AnimatedPawn(progress: boardProgress),
            _AnimatedBarrier(progress: boardProgress),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4C94FF).withValues(alpha: 0.3 + progress * 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final cellSize = size.width / 9;
    for (int i = 0; i <= 9; i++) {
      final offset = cellSize * i;
      final alpha = progress.clamp(0.0, 1.0);
      paint.color = const Color(
        0xFF4C94FF,
      ).withValues(alpha: 0.15 + alpha * 0.55);
      canvas.drawLine(Offset(offset, 0), Offset(offset, size.height), paint);
      canvas.drawLine(Offset(0, offset), Offset(size.width, offset), paint);
    }

    final borderPaint = Paint()
      ..color = const Color(0xFF35D080).withValues(alpha: 0.6 + progress * 0.4)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(20)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

class _AnimatedPawn extends StatelessWidget {
  const _AnimatedPawn({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final animatedOffset = Tween<Offset>(
      begin: const Offset(0.1, 0.8),
      end: const Offset(0.7, 0.2),
    ).transform(progress);

    return FractionalTranslation(
      translation: animatedOffset,
      child: Align(
        alignment: Alignment.topLeft,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF35D080), Color(0xFF27B76F)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF35D080).withValues(alpha: 0.6),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedBarrier extends StatelessWidget {
  const _AnimatedBarrier({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final curved = Curves.easeInOut.transform(progress.clamp(0.0, 1.0));
    final rotation = Tween<double>(begin: -0.35, end: -0.05).transform(curved);
    final offset = Tween<Offset>(
      begin: const Offset(0.65, 0.65),
      end: const Offset(0.35, 0.3),
    ).transform(curved);

    return FractionalTranslation(
      translation: offset,
      child: Align(
        alignment: Alignment.topLeft,
        child: Transform.rotate(
          angle: rotation,
          child: Container(
            width: 80,
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Color(0xFF3A7BFF), Color(0xFF7A9BFF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3A7BFF).withValues(alpha: 0.5),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BoardGlowPainter extends CustomPainter {
  const _BoardGlowPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide * 0.8;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF3A7BFF).withValues(alpha: 0.15 * progress),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

    canvas.drawCircle(center, maxRadius * (0.6 + progress * 0.4), paint);

    final sparkPaint = Paint()
      ..color = const Color(0xFF35D080).withValues(alpha: 0.1 + 0.25 * progress)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final sparkRadius = maxRadius * (0.4 + 0.3 * progress);
    final segmentCount = 6;
    for (int i = 0; i < segmentCount; i++) {
      final angle = (math.pi * 2 / segmentCount) * i + progress * math.pi / 3;
      final start =
          center + Offset(math.cos(angle), math.sin(angle)) * sparkRadius;
      final end =
          center +
          Offset(math.cos(angle), math.sin(angle)) * (sparkRadius + 18);
      canvas.drawLine(start, end, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(_BoardGlowPainter oldDelegate) =>
      progress != oldDelegate.progress;
}
