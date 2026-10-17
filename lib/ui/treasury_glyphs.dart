import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'fluuix_theme.dart';
import 'treasury_catalog.dart';

/// Phosphor (regular) is the icon system. Hand-drawn marks were removed.
///
/// Left out: Rive and Lottie (no designed files), a chart package (the only
/// quantitative series is today's remaining signing cap), and audioplayers
/// (SystemSound already separates an alert from a click).
const _plenty = Color(0xff3dcaa0);
const _alert = Color(0xffe24b4a);
const _muted = Color(0xff9aa0ae);

double treasuryRemainingFraction(BigInt remaining, BigInt capacity) {
  if (capacity <= BigInt.zero || remaining <= BigInt.zero) return 0;
  if (remaining >= capacity) return 1;
  final scaled = (remaining * BigInt.from(10000)) ~/ capacity;
  return scaled.toDouble() / 10000;
}

/// Green while plenty remains, gold in the middle, red only at the real limit.
Color treasuryCapInk({required bool nearLimit, required double fraction}) {
  if (nearLimit) return _alert;
  if (fraction >= 2 / 3) return _plenty;
  return fluuixGold;
}

void treasuryCueFault() => unawaited(_playTreasuryCue(alert: true));

void treasuryCueReceipt() => unawaited(_playTreasuryCue(alert: false));

Future<void> _playTreasuryCue({required bool alert}) async {
  try {
    if (alert) {
      await HapticFeedback.mediumImpact();
      await SystemSound.play(SystemSoundType.alert);
    } else {
      await HapticFeedback.lightImpact();
      await SystemSound.play(SystemSoundType.click);
    }
  } on Object {
    return;
  }
}

enum PaymentMark {
  awaitingSignature,
  awaitingReceipt,
  uncertain,
  confirmed,
  reverted,
}

String paymentMarkCaption(PaymentMark mark) => switch (mark) {
  PaymentMark.awaitingSignature => 'Pendiente de firma',
  PaymentMark.awaitingReceipt => 'Esperando comprobante',
  PaymentMark.uncertain => 'Solicitud sin resolver',
  PaymentMark.confirmed => 'Comprobante confirmado',
  PaymentMark.reverted => 'Operación revertida',
};

/// Phosphor Regular, drawn from the font shipped by phosphor_flutter.
/// The package's Dart classes extend IconData, which this Flutter version
/// made final, so the glyphs are declared here.
class FluuixIcons {
  const FluuixIcons._();

  static const _family = 'PhosphorRegular';
  static const _package = 'phosphor_flutter';

  static const IconData list = IconData(0xe2f0, fontFamily: _family, fontPackage: _package);
  static const IconData arrowsClockwise = IconData(0xe094, fontFamily: _family, fontPackage: _package);
  static const IconData x = IconData(0xe4f6, fontFamily: _family, fontPackage: _package);
  static const IconData squaresFour = IconData(0xe464, fontFamily: _family, fontPackage: _package);
  static const IconData wallet = IconData(0xe68a, fontFamily: _family, fontPackage: _package);
  static const IconData bank = IconData(0xe0b4, fontFamily: _family, fontPackage: _package);
  static const IconData hexagon = IconData(0xe2ae, fontFamily: _family, fontPackage: _package);
  static const IconData sparkle = IconData(0xe6a2, fontFamily: _family, fontPackage: _package);
  static const IconData userCircle = IconData(0xe4c4, fontFamily: _family, fontPackage: _package);
  static const IconData bell = IconData(0xe0ce, fontFamily: _family, fontPackage: _package);
  static const IconData currencyDollar = IconData(0xe550, fontFamily: _family, fontPackage: _package);
  static const IconData arrowDown = IconData(0xe03e, fontFamily: _family, fontPackage: _package);
  static const IconData vault = IconData(0xe76e, fontFamily: _family, fontPackage: _package);
  static const IconData shieldCheck = IconData(0xe40c, fontFamily: _family, fontPackage: _package);
  static const IconData piggyBank = IconData(0xea04, fontFamily: _family, fontPackage: _package);
  static const IconData gavel = IconData(0xea32, fontFamily: _family, fontPackage: _package);
  static const IconData handHeart = IconData(0xe810, fontFamily: _family, fontPackage: _package);
  static const IconData usersThree = IconData(0xe68e, fontFamily: _family, fontPackage: _package);
  static const IconData calendarBlank = IconData(0xe10a, fontFamily: _family, fontPackage: _package);
  static const IconData qrCode = IconData(0xe3e6, fontFamily: _family, fontPackage: _package);
  static const IconData paperPlaneTilt = IconData(0xe398, fontFamily: _family, fontPackage: _package);
  static const IconData arrowsLeftRight = IconData(0xe0a0, fontFamily: _family, fontPackage: _package);
  static const IconData globeHemisphereWest = IconData(0xe28c, fontFamily: _family, fontPackage: _package);
  static const IconData checks = IconData(0xe53a, fontFamily: _family, fontPackage: _package);
  static const IconData gauge = IconData(0xe628, fontFamily: _family, fontPackage: _package);
  static const IconData package = IconData(0xe390, fontFamily: _family, fontPackage: _package);
  static const IconData chartPie = IconData(0xe158, fontFamily: _family, fontPackage: _package);
  static const IconData lockKey = IconData(0xe2fe, fontFamily: _family, fontPackage: _package);
  static const IconData fileText = IconData(0xe23a, fontFamily: _family, fontPackage: _package);
  static const IconData files = IconData(0xe710, fontFamily: _family, fontPackage: _package);
  static const IconData buildings = IconData(0xe102, fontFamily: _family, fontPackage: _package);
  static const IconData warehouse = IconData(0xecd4, fontFamily: _family, fontPackage: _package);
  static const IconData certificate = IconData(0xe766, fontFamily: _family, fontPackage: _package);
  static const IconData flag = IconData(0xe244, fontFamily: _family, fontPackage: _package);
  static const IconData seal = IconData(0xe604, fontFamily: _family, fontPackage: _package);
  static const IconData steps = IconData(0xecbe, fontFamily: _family, fontPackage: _package);
  static const IconData gift = IconData(0xe276, fontFamily: _family, fontPackage: _package);
  static const IconData scales = IconData(0xe750, fontFamily: _family, fontPackage: _package);
  static const IconData lightning = IconData(0xe2de, fontFamily: _family, fontPackage: _package);
  static const IconData chartLine = IconData(0xe154, fontFamily: _family, fontPackage: _package);
  static const IconData robot = IconData(0xe762, fontFamily: _family, fontPackage: _package);
  static const IconData circleDashed = IconData(0xe602, fontFamily: _family, fontPackage: _package);
  static const IconData eye = IconData(0xe220, fontFamily: _family, fontPackage: _package);
  static const IconData warningCircle = IconData(0xe4e2, fontFamily: _family, fontPackage: _package);
  static const IconData deviceMobile = IconData(0xe1e0, fontFamily: _family, fontPackage: _package);
  static const IconData pencilSimple = IconData(0xe3b4, fontFamily: _family, fontPackage: _package);
  static const IconData clock = IconData(0xe19a, fontFamily: _family, fontPackage: _package);
  static const IconData warning = IconData(0xe4e0, fontFamily: _family, fontPackage: _package);
  static const IconData checkCircle = IconData(0xe184, fontFamily: _family, fontPackage: _package);
  static const IconData xCircle = IconData(0xe4f8, fontFamily: _family, fontPackage: _package);
}

IconData treasuryGroupIcon(TreasuryGroup group) => switch (group) {
  TreasuryGroup.today => FluuixIcons.squaresFour,
  TreasuryGroup.boxes => FluuixIcons.wallet,
  TreasuryGroup.treasury => FluuixIcons.bank,
  TreasuryGroup.token => FluuixIcons.hexagon,
  TreasuryGroup.fluuix => FluuixIcons.sparkle,
  TreasuryGroup.account => FluuixIcons.userCircle,
};

IconData treasuryScreenIcon(TreasuryScreen screen) => switch (screen) {
  TreasuryScreen.dashboard => FluuixIcons.squaresFour,
  TreasuryScreen.alerts => FluuixIcons.bell,
  TreasuryScreen.boxDollars => FluuixIcons.currencyDollar,
  TreasuryScreen.boxLocal => FluuixIcons.bank,
  TreasuryScreen.boxEntry => FluuixIcons.arrowDown,
  TreasuryScreen.boxReserve => FluuixIcons.vault,
  TreasuryScreen.boxTrust => FluuixIcons.shieldCheck,
  TreasuryScreen.boxFund => FluuixIcons.piggyBank,
  TreasuryScreen.boxTender => FluuixIcons.gavel,
  TreasuryScreen.boxDonation => FluuixIcons.handHeart,
  TreasuryScreen.boxCrowd => FluuixIcons.usersThree,
  TreasuryScreen.forecast => FluuixIcons.calendarBlank,
  TreasuryScreen.collections => FluuixIcons.qrCode,
  TreasuryScreen.payments => FluuixIcons.paperPlaneTilt,
  TreasuryScreen.convert => FluuixIcons.arrowsLeftRight,
  TreasuryScreen.international => FluuixIcons.globeHemisphereWest,
  TreasuryScreen.reconcile => FluuixIcons.checks,
  TreasuryScreen.caps => FluuixIcons.gauge,
  TreasuryScreen.tokenInventory => FluuixIcons.package,
  TreasuryScreen.tokenShares => FluuixIcons.chartPie,
  TreasuryScreen.tokenEscrow => FluuixIcons.lockKey,
  TreasuryScreen.tokenContracts => FluuixIcons.fileText,
  TreasuryScreen.tokenDocuments => FluuixIcons.files,
  TreasuryScreen.tokenProperty => FluuixIcons.buildings,
  TreasuryScreen.tokenZone => FluuixIcons.warehouse,
  TreasuryScreen.tokenTtn => FluuixIcons.certificate,
  TreasuryScreen.schemeAllOrNothing => FluuixIcons.flag,
  TreasuryScreen.schemeBidBond => FluuixIcons.seal,
  TreasuryScreen.schemeProgress => FluuixIcons.steps,
  TreasuryScreen.schemeMilestoneGift => FluuixIcons.gift,
  TreasuryScreen.schemeNavFund => FluuixIcons.scales,
  TreasuryScreen.factoring => FluuixIcons.lightning,
  TreasuryScreen.quotes => FluuixIcons.chartLine,
  TreasuryScreen.assistant => FluuixIcons.robot,
  TreasuryScreen.account => FluuixIcons.userCircle,
};

class TreasuryIcon extends StatelessWidget {
  const TreasuryIcon({
    super.key,
    required this.icon,
    this.size = 22,
    this.selected = false,
    this.color,
  });

  final IconData icon;
  final double size;
  final bool selected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: color ?? (selected ? fluuixGold : _muted),
    );
  }
}

class CapacityGauge extends StatefulWidget {
  const CapacityGauge({
    super.key,
    required this.remaining,
    required this.capacity,
    required this.nearLimit,
  });

  final BigInt remaining;
  final BigInt capacity;
  final bool nearLimit;

  @override
  State<CapacityGauge> createState() => _CapacityGaugeState();
}

class _CapacityGaugeState extends State<CapacityGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _play;
  double _from = 0;
  double _to = 0;

  @override
  void initState() {
    super.initState();
    _to = treasuryRemainingFraction(widget.remaining, widget.capacity);
    _play = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 640),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _from = _to;
      _play
        ..value = 1
        ..stop();
    } else if (!_play.isAnimating && _play.value == 0) {
      _play.forward();
    }
  }

  @override
  void didUpdateWidget(CapacityGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = treasuryRemainingFraction(widget.remaining, widget.capacity);
    final same = next == _to && oldWidget.nearLimit == widget.nearLimit;
    if (same) return;
    _from = _shown;
    _to = next;
    if (MediaQuery.disableAnimationsOf(context)) {
      _play.value = 1;
      _play.stop();
    } else {
      _play.forward(from: 0);
    }
  }

  double get _shown =>
      _from + (_to - _from) * Curves.easeOutCubic.transform(_play.value);

  @override
  void dispose() {
    _play.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = treasuryCapInk(nearLimit: widget.nearLimit, fraction: _to);
    return AnimatedBuilder(
      animation: _play,
      builder: (context, _) {
        final fraction = _shown.clamp(0.0, 1.0);
        return Semantics(
          label: 'Firma restante',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 10,
              width: double.infinity,
              child: ColoredBox(
                color: const Color(0xff232833),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: fraction,
                    heightFactor: 1,
                    child: ColoredBox(color: ink),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class CapSeal extends StatelessWidget {
  const CapSeal({
    super.key,
    required this.remaining,
    required this.capacity,
    required this.nearLimit,
    this.size = 26,
  });

  final BigInt remaining;
  final BigInt capacity;
  final bool nearLimit;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fraction = treasuryRemainingFraction(remaining, capacity);
    final ink = treasuryCapInk(nearLimit: nearLimit, fraction: fraction);
    return TreasuryIcon(
      icon: FluuixIcons.gauge,
      size: size,
      color: ink,
    );
  }
}

class UnreadVessel extends StatelessWidget {
  const UnreadVessel({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return TreasuryIcon(
      icon: FluuixIcons.circleDashed,
      size: size,
      color: _muted,
    );
  }
}

class ReadingMark extends StatelessWidget {
  const ReadingMark({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return TreasuryIcon(
      icon: FluuixIcons.eye,
      size: size,
      color: fluuixBlue,
    );
  }
}

class FaultMark extends StatelessWidget {
  const FaultMark({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return TreasuryIcon(
      icon: FluuixIcons.warningCircle,
      size: size,
      color: _alert,
    );
  }
}

class PhoneBoundMark extends StatelessWidget {
  const PhoneBoundMark({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return TreasuryIcon(
      icon: FluuixIcons.deviceMobile,
      size: size,
      color: _muted,
    );
  }
}

class PhoneBoundLine extends StatelessWidget {
  const PhoneBoundLine({super.key, this.color = _muted});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: PhoneBoundMark(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            treasuryNotOnPhone,
            style: TextStyle(color: color, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class PaymentMarkView extends StatelessWidget {
  const PaymentMarkView({super.key, required this.mark, this.size = 28});

  final PaymentMark mark;
  final double size;

  IconData get _icon => switch (mark) {
    PaymentMark.awaitingSignature => FluuixIcons.pencilSimple,
    PaymentMark.awaitingReceipt => FluuixIcons.clock,
    PaymentMark.uncertain => FluuixIcons.warning,
    PaymentMark.confirmed => FluuixIcons.checkCircle,
    PaymentMark.reverted => FluuixIcons.xCircle,
  };

  Color get _color => switch (mark) {
    PaymentMark.awaitingSignature => fluuixGold,
    PaymentMark.awaitingReceipt => fluuixBlue,
    PaymentMark.uncertain => fluuixGold,
    PaymentMark.confirmed => _plenty,
    PaymentMark.reverted => _alert,
  };

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      key: ValueKey(mark),
      tween: Tween<double>(begin: reduce ? 1 : 0.86, end: 1),
      duration: reduce
          ? const Duration(milliseconds: 1)
          : const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Semantics(
        label: paymentMarkCaption(mark),
        child: Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: child,
        ),
      ),
      child: TreasuryIcon(icon: _icon, size: size, color: _color),
    );
  }
}

class LiabilityRow extends StatelessWidget {
  const LiabilityRow({super.key, required this.mark});

  final PaymentMark mark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PaymentMarkView(mark: mark),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            paymentMarkCaption(mark),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class HonestFigure extends StatefulWidget {
  const HonestFigure({super.key, required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<HonestFigure> createState() => _HonestFigureState();
}

class _HonestFigureState extends State<HonestFigure>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _enter
        ..value = 1
        ..stop();
    } else if (_enter.value == 0 && !_enter.isAnimating) {
      _enter.forward();
    }
  }

  @override
  void didUpdateWidget(HonestFigure oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text == widget.text) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _enter.value = 1;
      return;
    }
    _enter.forward(from: 0);
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _enter,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_enter.value);
        return Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 8),
            child: child,
          ),
        );
      },
      child: Text(widget.text, style: widget.style),
    );
  }
}

/// Empty frame. No points, because this phone has no price series.
class AbsentSeries extends StatelessWidget {
  const AbsentSeries({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Sin serie',
      child: const SizedBox(
        height: 72,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xff12151c),
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: Center(
            child: Text(
              'Sin serie',
              style: TextStyle(color: _muted, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }
}
