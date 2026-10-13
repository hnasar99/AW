import 'package:arc_wallet_flutter/domain/treasury_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a payment over the local cap is refused before any order is built', () {
    expect(
      () => TreasuryPolicy.assertOrderAllowed(
        units: TreasuryPolicy.perPayment + BigInt.one,
        spentToday: BigInt.zero,
      ),
      throwsStateError,
    );
    expect(
      () => TreasuryPolicy.assertOrderAllowed(
        units: BigInt.one,
        spentToday: TreasuryPolicy.perDay,
      ),
      throwsStateError,
    );
    TreasuryPolicy.assertOrderAllowed(
      units: TreasuryPolicy.perPayment,
      spentToday: BigInt.zero,
    );
  });

  test('confirmed receipts count once toward the day and reset after it', () {
    final ledger = TreasuryDayLedger(
      day: TreasuryDayLedger.today(),
      spent: BigInt.zero,
      hashes: const <String>{},
    );
    final hash = '0x${'ab' * 32}';
    final once = ledger.recordConfirmed(hash: hash, units: BigInt.from(7));
    final twice = once.recordConfirmed(
      hash: hash.toUpperCase(),
      units: BigInt.from(7),
    );
    expect(twice.spent, BigInt.from(7));
    expect(twice.hashes, {hash});
    final yesterday = TreasuryDayLedger(
      day: '2000-01-01',
      spent: BigInt.from(9),
      hashes: {hash},
    );
    expect(yesterday.forToday().spent, BigInt.zero);
    expect(yesterday.remaining, TreasuryPolicy.perDay);
  });
}
