import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

/// Opening mark for a real launch. Tests omit it by leaving [FluuiXLaunch] out.
class FluuiXLaunch extends StatefulWidget {
  const FluuiXLaunch({super.key, required this.child});

  final Widget child;

  @override
  State<FluuiXLaunch> createState() => _FluuiXLaunchState();
}

class _FluuiXLaunchState extends State<FluuiXLaunch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _play;
  var _started = false;
  var _cover = true;

  @override
  void initState() {
    super.initState();
    _play = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _cover = false);
        }
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduce = MediaQuery.disableAnimationsOf(context);
    _play.duration = reduce
        ? const Duration(milliseconds: 700)
        : const Duration(milliseconds: 2800);
    _play.forward();
  }

  @override
  void dispose() {
    _play.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_cover)
          Positioned.fill(
            key: const Key('fluuix-splash'),
            child: AnimatedBuilder(
              animation: _play,
              builder: (context, _) {
                final reduce = MediaQuery.disableAnimationsOf(context);
                final t = _play.value;
                final veil = reduce
                    ? (t < 0.72 ? 1.0 : (1 - (t - 0.72) / 0.28))
                    : (t < 0.84 ? 1.0 : (1 - (t - 0.84) / 0.16));
                return Opacity(
                  opacity: veil.clamp(0.0, 1.0),
                  child: _SplashStage(t: t, reduce: reduce),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _SplashStage extends StatelessWidget {
  const _SplashStage({required this.t, required this.reduce});

  final double t;
  final bool reduce;

  @override
  Widget build(BuildContext context) {
    final entrance = reduce
        ? 1.0
        : Curves.easeOutCubic.transform((t / 0.28).clamp(0.0, 1.0));
    final word = reduce
        ? 1.0
        : Curves.easeOut.transform(((t - 0.34) / 0.22).clamp(0.0, 1.0));
    final pulse = reduce ? 0.72 : 0.45 + 0.55 * math.sin(t * math.pi * 4);
    final glint = reduce
        ? 0.0
        : () {
            final u = ((t - 0.22) / 0.38).clamp(0.0, 1.0);
            return math.sin(u * math.pi);
          }();

    return AbsorbPointer(
      child: DecoratedBox(
        decoration: const BoxDecoration(color: FluuixColors.backgroundDark),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _BrandLightsPainter(t: t, reduce: reduce, pulse: pulse),
            ),
            Center(
              child: Opacity(
                opacity: entrance,
                child: Transform.scale(
                  scale: 0.9 + 0.1 * entrance,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Mark(pulse: pulse, glint: glint, travel: t),
                      const SizedBox(height: 28),
                      Opacity(
                        opacity: word,
                        child: const Column(
                          children: [
                            Text(
                              'FluuiX',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 7,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Caja en dólares',
                              style: TextStyle(
                                color: FluuixColors.gold,
                                fontSize: 13,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            CustomPaint(painter: _BeamPainter(t: t, reduce: reduce)),
          ],
        ),
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({
    required this.pulse,
    required this.glint,
    required this.travel,
  });

  final double pulse;
  final double glint;
  final double travel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: FluuixColors.lightBlue.withValues(alpha: 0.55 * pulse),
            blurRadius: 42,
            spreadRadius: 2,
            offset: const Offset(-18, 0),
          ),
          BoxShadow(
            color: FluuixColors.gold.withValues(alpha: 0.5 * pulse),
            blurRadius: 42,
            spreadRadius: 2,
            offset: const Offset(18, 0),
          ),
        ],
      ),
      child: ClipRect(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/brand/fluuix_logo.png',
              width: 248,
              filterQuality: FilterQuality.high,
              semanticLabel: 'FluuiX',
            ),
            if (glint > 0.04)
              Transform.translate(
                offset: Offset(-120 + 280 * ((travel - 0.22) / 0.38), 0),
                child: Opacity(
                  opacity: (glint * 0.85).clamp(0.0, 1.0),
                  child: Transform.rotate(
                    angle: -0.45,
                    child: Container(
                      width: 28,
                      height: 280,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0x00FFFFFF),
                            Color(0xF2FFF6DE),
                            Color(0x99FFFFFF),
                            Color(0x00FFFFFF),
                          ],
                        ),
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

class _BrandLightsPainter extends CustomPainter {
  const _BrandLightsPainter({
    required this.t,
    required this.reduce,
    required this.pulse,
  });

  final double t;
  final bool reduce;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = FluuixColors.backgroundDark,
    );
    _orb(
      canvas,
      size,
      Offset(size.width * (0.18 + 0.04 * math.sin(t * math.pi * 2)), size.height * 0.40),
      FluuixColors.lightBlue,
      0.62 * pulse,
    );
    _orb(
      canvas,
      size,
      Offset(size.width * (0.82 - 0.04 * math.sin(t * math.pi * 2)), size.height * 0.52),
      FluuixColors.gold,
      0.55 * pulse,
    );
    if (!reduce) {
      _orb(
        canvas,
        size,
        Offset(size.width * 0.5, size.height * 0.46),
        FluuixColors.goldBright,
        0.12 * pulse,
      );
    }
  }

  void _orb(Canvas canvas, Size size, Offset center, Color color, double alpha) {
    final radius = size.shortestSide * 0.52;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: alpha),
          color.withValues(alpha: alpha * 0.28),
          const Color(0x00000000),
        ],
        stops: const [0, 0.42, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _BrandLightsPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.reduce != reduce ||
      oldDelegate.pulse != pulse;
}

class _BeamPainter extends CustomPainter {
  const _BeamPainter({required this.t, required this.reduce});

  final double t;
  final bool reduce;

  @override
  void paint(Canvas canvas, Size size) {
    if (reduce) return;
    final u = ((t - 0.16) / 0.46).clamp(0.0, 1.0);
    if (u <= 0 || u >= 1) return;
    final strength = math.sin(u * math.pi);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-0.42);
    final travel = size.width * 1.5;
    final x = -travel / 2 + Curves.easeInOut.transform(u) * travel;
    final rect = Rect.fromCenter(
      center: Offset(x, 0),
      width: size.width * 0.16,
      height: size.height * 1.8,
    );
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0x00FFFFFF),
          const Color(0xfff7f1e4).withValues(alpha: 0.05 * strength),
          const Color(0xfffff8e8).withValues(alpha: 0.42 * strength),
          const Color(0xff9ec0ff).withValues(alpha: 0.16 * strength),
          const Color(0x00FFFFFF),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BeamPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.reduce != reduce;
}
