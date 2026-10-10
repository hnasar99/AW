import 'dart:convert';

import 'package:arc_wallet_flutter/domain/arc.dart';
import 'package:arc_wallet_flutter/domain/inference_config.dart';
import 'package:flutter_test/flutter_test.dart';

const sender = '0x1111111111111111111111111111111111111111';
const recipient = '0x2222222222222222222222222222222222222222';
final txHash = '0x${List.filled(64, 'a').join()}';
final blockHash = '0x${List.filled(64, 'b').join()}';

Map<String, Object> proposal({
  Object chain = 5042002,
  Object token = 'USDC',
  Object amount = '1.000001',
  Object approval = true,
}) => {
  'intent': 'transfer_usdc',
  'chain_id': chain,
  'token': token,
  'recipient': recipient,
  'amount': amount,
  'requires_user_approval': approval,
};

TransferReview exampleReview() => TransferReview(
  sender: sender,
  recipient: recipient,
  units: BigInt.from(1000000),
  topic: 'session-a',
  sessionRevision: 4,
  expiresAt: DateTime.utc(2026, 10, 10, 12, 2),
  gasLimit: BigInt.from(100000),
  maxFeePerGas: BigInt.from(40000000000),
  maxPriorityFeePerGas: BigInt.zero,
);

void main() {
  group('Exact money and native/token scale', () {
    test('preserves values above the floating-point exact integer range', () {
      expect(parseUsdc('9007199254.740993'), BigInt.parse('9007199254740993'));
      expect(parseUsdc('0.000001'), BigInt.one);
      expect(formatUnits(parseUsdc('1.100001'), 6), '1.100001');
    });
    test('never rounds or silently accepts scientific notation', () {
      for (final input in [
        '0',
        '-1',
        'NaN',
        'Infinity',
        '1e6',
        '1,2',
        '0.0000009',
        '1.1234567',
        '.5',
        '01',
        '1.',
      ]) {
        expect(() => parseUsdc(input), throwsFormatException, reason: input);
      }
    });
    test('rejects overflow before ABI encoding', () {
      expect(() => parseUsdc('9' * 78), throwsFormatException);
      expect(
        () => encodeTransfer(recipient, ArcNetwork.maxUint256 + BigInt.one),
        throwsFormatException,
      );
    });
    test('includes gas against the same balance as the transfer', () {
      final review = exampleReview();
      expect(review.nativeRequired, BigInt.parse('1004000000000000000'));
      expect(review.transaction['value'], '0x0');
      expect(review.transaction['to'], ArcNetwork.usdc);
      expect(
        review.transaction['data'],
        '0xa9059cbb0000000000000000000000002222222222222222222222222222222222222222'
        '00000000000000000000000000000000000000000000000000000000000f4240',
      );
    });
  });

  group('Address validation', () {
    test('accepts EIP-55 checksums and unchecksummed lowercase', () {
      expect(
        validateAddress('0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed'),
        isNotEmpty,
      );
      expect(validateAddress(recipient, recipient: true), recipient);
    });
    test(
      'rejects wrong mixed-case checksums and burn/contract destinations',
      () {
        expect(
          () => validateAddress('0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAEd'),
          throwsFormatException,
        );
        expect(
          () => validateAddress('0x${'0' * 40}', recipient: true),
          throwsFormatException,
        );
        expect(
          () => validateAddress(ArcNetwork.usdc, recipient: true),
          throwsFormatException,
        );
      },
    );
  });

  group('Untrusted model proposals', () {
    test('allows only a typed Arc USDC proposal requiring human approval', () {
      expect(
        TransferProposal.parse(jsonEncode(proposal())).units,
        BigInt.from(1000001),
      );
      expect(
        TransferProposal.parse(
          '```json\n${jsonEncode(proposal())}\n```',
        ).recipient,
        recipient,
      );
    });
    test('rejects wrong chain, token, numeric amount and missing approval', () {
      for (final input in [
        proposal(chain: 1),
        proposal(chain: '5042002'),
        proposal(token: 'USDT'),
        proposal(amount: 1.0),
        proposal(approval: false),
      ]) {
        expect(
          () => TransferProposal.parse(jsonEncode(input)),
          throwsFormatException,
        );
      }
      final withData = {...proposal(), 'data': '0xdeadbeef'};
      expect(
        () => TransferProposal.parse(jsonEncode(withData)),
        throwsFormatException,
      );
    });
  });

  group('Consent snapshot', () {
    test('expired or changed wallet cannot reuse earlier approval', () {
      final review = exampleReview();
      review.verifyConsent(
        currentSender: sender,
        currentTopic: 'session-a',
        currentRevision: 4,
        now: DateTime.utc(2026, 10, 10, 12, 1),
      );
      for (final mutation in [
        () => review.verifyConsent(
          currentSender: recipient,
          currentTopic: 'session-a',
          currentRevision: 4,
          now: DateTime.utc(2026),
        ),
        () => review.verifyConsent(
          currentSender: sender,
          currentTopic: 'session-b',
          currentRevision: 4,
          now: DateTime.utc(2026),
        ),
        () => review.verifyConsent(
          currentSender: sender,
          currentTopic: 'session-a',
          currentRevision: 5,
          now: DateTime.utc(2026),
        ),
        () => review.verifyConsent(
          currentSender: sender,
          currentTopic: 'session-a',
          currentRevision: 4,
          now: review.expiresAt,
        ),
      ]) {
        expect(mutation, throwsStateError);
      }
    });
  });

  group('Receipt evidence', () {
    final receipt = {
      'transactionHash': txHash,
      'blockHash': blockHash,
      'blockNumber': '0x12',
      'status': '0x1',
    };
    test('distinguishes pending, success and revert', () {
      expect(parseReceipt(txHash, null).state, TransactionState.pending);
      expect(parseReceipt(txHash, receipt).state, TransactionState.confirmed);
      expect(
        parseReceipt(txHash, {...receipt, 'status': '0x0'}).state,
        TransactionState.reverted,
      );
    });
    test('missing, malformed or unrelated evidence is never success', () {
      expect(
        () => parseReceipt(txHash, {...receipt}..remove('status')),
        throwsFormatException,
      );
      expect(
        () => parseReceipt(txHash, {...receipt, 'status': '0x2'}),
        throwsFormatException,
      );
      expect(
        () => parseReceipt(txHash, {...receipt, 'transactionHash': blockHash}),
        throwsFormatException,
      );
    });
  });

  group('Inference endpoint credential boundary', () {
    test('allows HTTPS and exact loopback only', () {
      for (final endpoint in [
        'https://provider.example/v1',
        'http://localhost:8080/v1',
        'http://127.0.0.1:8080/v1',
        'http://[::1]:8080/v1',
      ]) {
        expect(validateInferenceEndpoint(endpoint), isNotNull);
      }
    });
    test('blocks pseudo-loopback and secrets embedded in URLs', () {
      for (final endpoint in [
        'http://127.evil.test/v1',
        'http://127.0.0.1.evil.test/v1',
        'http://localhost.evil/v1',
        'http://192.168.1.2/v1',
        'https://user:key@provider.example/v1',
        'https://provider.example/v1?api_key=secret',
        'https://provider.example/#secret',
        'file:///etc/passwd',
      ]) {
        expect(
          () => validateInferenceEndpoint(endpoint),
          throwsFormatException,
          reason: endpoint,
        );
      }
    });
  });
}
