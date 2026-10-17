import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'fluuix_theme.dart';

/// Slow blue and gold field behind the treasury. The mark is the light source.
class TreasuryAtmosphere extends StatefulWidget {
  const TreasuryAtmosphere({super.key, required this.child});

  final Widget child;

  @override
  State<TreasuryAtmosphere> createState() => _TreasuryAtmosphereState();
}

class _TreasuryAtmosphereState extends State<TreasuryAtmosphere>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _drift.value = 0.35;
      _drift.stop();
    } else if (!_drift.isAnimating) {
      _drift.repeat();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, child) => DecoratedBox(
        decoration: const BoxDecoration(color: fluuixBackground),
        child: CustomPaint(
          painter: _AtmospherePainter(_drift.value),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

class _AtmospherePainter extends CustomPainter {
  const _AtmospherePainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final drift = math.sin(t * math.pi * 2);
    final blue = Paint()
      ..shader =
          RadialGradient(
            colors: [
              fluuixBlue.withValues(alpha: 0.28),
              fluuixBlue.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(
                size.width * (0.18 + 0.06 * drift),
                size.height * 0.12,
              ),
              radius: size.shortestSide * 0.72,
            ),
          );
    final gold = Paint()
      ..shader =
          RadialGradient(
            colors: [
              fluuixGold.withValues(alpha: 0.22),
              fluuixGold.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(
                size.width * (0.86 - 0.05 * drift),
                size.height * 0.22,
              ),
              radius: size.shortestSide * 0.64,
            ),
          );
    canvas.drawRect(Offset.zero & size, blue);
    canvas.drawRect(Offset.zero & size, gold);
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter oldDelegate) =>
      oldDelegate.t != t;
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: fluuixBlue.withValues(alpha: 0.45),
            blurRadius: size * 0.55,
            offset: Offset(-size * 0.06, 0),
          ),
          BoxShadow(
            color: fluuixGold.withValues(alpha: 0.32),
            blurRadius: size * 0.55,
            offset: Offset(size * 0.06, 0),
          ),
        ],
      ),
      child: Image.asset(
        'assets/brand/fluuix_logo.png',
        width: size,
        height: size,
        filterQuality: FilterQuality.high,
        semanticLabel: 'FluuiX',
      ),
    );
  }
}

/// Quiet surface. A hairline, not a metallic rim.
class LedgerPlate extends StatelessWidget {
  const LedgerPlate({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xff12151c),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x14ffffff)),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: child,
      ),
    );
  }
}

class LedgerRow extends StatelessWidget {
  const LedgerRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final String? trailing;
  final Widget? leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: LedgerPlate(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 10)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              if (onTap != null)
                const Icon(Icons.chevron_right, color: Color(0xff9aa0ae), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class BrandRule extends StatelessWidget {
  const BrandRule({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: Color(0x14ffffff)),
      child: SizedBox(width: double.infinity, height: 1),
    );
  }
}

class TreasuryScreenSwitch extends StatelessWidget {
  const TreasuryScreenSwitch({
    super.key,
    required this.screenKey,
    required this.child,
  });

  final Key screenKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: reduce
          ? const Duration(milliseconds: 1)
          : const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, if (current != null) current],
      ),
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0.04, 0.015),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: KeyedSubtree(key: screenKey, child: child),
    );
  }
}
