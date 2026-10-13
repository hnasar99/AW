/// Local payment caps for the FluuiX box. These are app policy, not a
/// Circle Agent Wallet limit and not a balance on another chain.
abstract final class TreasuryPolicy {
  static final perPayment = BigInt.from(1000) * BigInt.from(1000000);
  static final perDay = BigInt.from(5000) * BigInt.from(1000000);

  static void assertOrderAllowed({
    required BigInt units,
    required BigInt spentToday,
  }) {
    if (units > perPayment) {
      throw StateError(
        'El importe supera el tope por pago de esta app. La orden no se arma.',
      );
    }
    if (spentToday + units > perDay) {
      throw StateError(
        'El importe supera el tope del día de esta app. La orden no se arma.',
      );
    }
  }
}

const treasuryLedgerKey = 'aw_treasury_cap_v1';

/// Confirmed receipts counted toward today's cap on this phone.
class TreasuryDayLedger {
  const TreasuryDayLedger({
    required this.day,
    required this.spent,
    required this.hashes,
  });

  final String day;
  final BigInt spent;
  final Set<String> hashes;

  static String today() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  factory TreasuryDayLedger.empty([String? day]) => TreasuryDayLedger(
    day: day ?? today(),
    spent: BigInt.zero,
    hashes: const <String>{},
  );

  factory TreasuryDayLedger.fromJson(Map<String, dynamic> json) {
    final day = json['day'];
    final spent = json['spent'];
    final hashes = json['hashes'];
    if (day is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day)) {
      throw const FormatException('Invalid treasury day.');
    }
    if (spent is! String || !RegExp(r'^(0|[1-9][0-9]*)$').hasMatch(spent)) {
      throw const FormatException('Invalid treasury spent amount.');
    }
    if (hashes is! List) {
      throw const FormatException('Invalid treasury receipt list.');
    }
    return TreasuryDayLedger(
      day: day,
      spent: BigInt.parse(spent),
      hashes: hashes.map((hash) {
        if (hash is! String || !RegExp(r'^0x[0-9a-f]{64}$').hasMatch(hash)) {
          throw const FormatException('Invalid treasury receipt hash.');
        }
        return hash;
      }).toSet(),
    );
  }

  TreasuryDayLedger forToday() =>
      day == today() ? this : TreasuryDayLedger.empty();

  BigInt get remaining {
    final current = forToday().spent;
    if (current >= TreasuryPolicy.perDay) return BigInt.zero;
    return TreasuryPolicy.perDay - current;
  }

  TreasuryDayLedger recordConfirmed({
    required String hash,
    required BigInt units,
  }) {
    final current = forToday();
    final key = hash.toLowerCase();
    if (current.hashes.contains(key) || units <= BigInt.zero) return current;
    return TreasuryDayLedger(
      day: current.day,
      spent: current.spent + units,
      hashes: {...current.hashes, key},
    );
  }

  Map<String, Object> toJson() => {
    'day': day,
    'spent': '$spent',
    'hashes': hashes.toList()..sort(),
  };
}
