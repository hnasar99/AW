import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/digests/keccak.dart';

/// Public Arc Testnet parameters. No mainnet transaction path is exposed.
abstract final class ArcNetwork {
  static const chainId = 5042002;
  static const caip2 = 'eip155:5042002';
  static const name = 'Arc Testnet';
  static const rpc = 'https://rpc.testnet.arc.io';
  static const explorer = 'https://explorer.testnet.arc.io';
  static const usdc = '0x3600000000000000000000000000000000000000';
  static const tokenDecimals = 6;
  static const nativeDecimals = 18;
  static final nativePerTokenUnit = BigInt.from(10).pow(12);
  static final maxUint256 = (BigInt.one << 256) - BigInt.one;
}

/// Decimal amounts are never converted through binary floating point.
BigInt parseUsdc(String input) {
  final amount = input.trim();
  if (amount.length > 80 ||
      !RegExp(r'^(0|[1-9][0-9]*)(\.[0-9]{1,6})?$').hasMatch(amount)) {
    throw const FormatException(
      'Use a decimal amount with up to 6 places, for example 0.000001. '
      'Commas, exponents and rounding are not accepted.',
    );
  }
  final parts = amount.split('.');
  final units =
      BigInt.parse(parts[0]) * BigInt.from(1000000) +
      BigInt.parse(parts.length == 2 ? parts[1].padRight(6, '0') : '0');
  if (units <= BigInt.zero || units > ArcNetwork.maxUint256) {
    throw const FormatException(
      'Amount is outside the positive uint256 range.',
    );
  }
  return units;
}

String formatUnits(BigInt value, int decimals, {int? places}) {
  if (value < BigInt.zero || decimals < 0 || decimals > 77) {
    throw ArgumentError('Expected non-negative units and valid decimals.');
  }
  final shownPlaces = (places ?? decimals).clamp(0, decimals);
  final base = BigInt.from(10).pow(decimals);
  final whole = value ~/ base;
  final fraction = (value % base)
      .toString()
      .padLeft(decimals, '0')
      .substring(0, shownPlaces)
      .replaceFirst(RegExp(r'0+$'), '');
  return fraction.isEmpty ? '$whole' : '$whole.$fraction';
}

String validateAddress(String input, {bool recipient = false}) {
  final address = input.trim();
  if (!RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(address)) {
    throw const FormatException(
      'Use a complete 0x EVM address (40 hex digits).',
    );
  }
  final body = address.substring(2);
  if (body != body.toLowerCase() && body != body.toUpperCase()) {
    final digest = KeccakDigest(
      256,
    ).process(Uint8List.fromList(utf8.encode(body.toLowerCase())));
    final checksum = digest
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    for (var i = 0; i < body.length; i++) {
      final letter = body[i];
      if (RegExp(r'[a-fA-F]').hasMatch(letter)) {
        final expected = int.parse(checksum[i], radix: 16) >= 8
            ? letter.toUpperCase()
            : letter.toLowerCase();
        if (letter != expected) {
          throw const FormatException(
            'The mixed-case EVM address has an invalid EIP-55 checksum.',
          );
        }
      }
    }
  }
  if (recipient &&
      (BigInt.parse(address.substring(2), radix: 16) == BigInt.zero ||
          address.toLowerCase() == ArcNetwork.usdc)) {
    throw const FormatException(
      'The zero address and USDC contract cannot receive this transfer.',
    );
  }
  return address;
}

String encodeTransfer(String recipient, BigInt units) {
  final address = validateAddress(recipient, recipient: true);
  if (units <= BigInt.zero || units > ArcNetwork.maxUint256) {
    throw const FormatException('Transfer amount is outside uint256 range.');
  }
  return '0xa9059cbb${address.substring(2).toLowerCase().padLeft(64, '0')}'
      '${units.toRadixString(16).padLeft(64, '0')}';
}

String hexQuantity(BigInt value) {
  if (value < BigInt.zero) throw ArgumentError('Negative quantity.');
  return '0x${value.toRadixString(16)}';
}

BigInt parseHexQuantity(Object? value) {
  if (value is! String ||
      !RegExp(r'^0x(?:0|[1-9a-fA-F][0-9a-fA-F]*)$').hasMatch(value) ||
      value.length > 66) {
    throw const FormatException('The node returned an invalid hex quantity.');
  }
  return BigInt.parse(value.substring(2), radix: 16);
}

/// Model output is a proposal, never a transaction or executable tool call.
class TransferProposal {
  const TransferProposal({required this.recipient, required this.units});

  final String recipient;
  final BigInt units;

  factory TransferProposal.parse(String reply) {
    if (utf8.encode(reply).length > 32768) {
      throw const FormatException('Proposal exceeds the size limit.');
    }
    var json = reply.trim();
    final fence = RegExp(r'^```(?:json)?\s*([\s\S]*?)\s*```$').firstMatch(json);
    if (fence != null) json = fence.group(1)!;
    final value = jsonDecode(json);
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Proposal must be a JSON object.');
    }
    const fields = {
      'intent',
      'chain_id',
      'token',
      'recipient',
      'amount',
      'explanation',
      'requires_user_approval',
    };
    if (value.keys.any((key) => !fields.contains(key)) ||
        value['intent'] != 'transfer_usdc' ||
        value['chain_id'] is! int ||
        value['chain_id'] != ArcNetwork.chainId ||
        value['token'] != 'USDC' ||
        value['requires_user_approval'] != true ||
        value['recipient'] is! String ||
        value['amount'] is! String) {
      throw const FormatException(
        'Only a USDC proposal on Arc Testnet requiring user approval is accepted.',
      );
    }
    return TransferProposal(
      recipient: validateAddress(value['recipient'] as String, recipient: true),
      units: parseUsdc(value['amount'] as String),
    );
  }
}

/// Immutable review state prevents edits or session changes altering consent.
class TransferReview {
  TransferReview({
    required this.sender,
    required this.recipient,
    required this.units,
    required this.topic,
    required this.sessionRevision,
    required this.expiresAt,
    required this.gasLimit,
    required this.maxFeePerGas,
    required this.maxPriorityFeePerGas,
  });

  final String sender;
  final String recipient;
  final BigInt units;
  final String topic;
  final int sessionRevision;
  final DateTime expiresAt;
  final BigInt gasLimit;
  final BigInt maxFeePerGas;
  final BigInt maxPriorityFeePerGas;

  BigInt get maximumFee => gasLimit * maxFeePerGas;
  BigInt get nativeRequired =>
      units * ArcNetwork.nativePerTokenUnit + maximumFee;

  Map<String, Object> toJson() => {
    'sender': sender,
    'recipient': recipient,
    'units': '$units',
    'topic': topic,
    'session_revision': sessionRevision,
    'expires_at': expiresAt.toIso8601String(),
    'gas_limit': '$gasLimit',
    'max_fee': '$maxFeePerGas',
    'priority': '$maxPriorityFeePerGas',
  };

  factory TransferReview.fromJson(Map<String, dynamic> value) => TransferReview(
    sender: validateAddress(value['sender'] as String),
    recipient: validateAddress(value['recipient'] as String, recipient: true),
    units: BigInt.parse(value['units'] as String),
    topic: value['topic'] as String,
    sessionRevision: value['session_revision'] as int,
    expiresAt: DateTime.parse(value['expires_at'] as String),
    gasLimit: BigInt.parse(value['gas_limit'] as String),
    maxFeePerGas: BigInt.parse(value['max_fee'] as String),
    maxPriorityFeePerGas: BigInt.parse(value['priority'] as String),
  );

  Map<String, String> get transaction => Map.unmodifiable({
    'from': sender,
    'to': ArcNetwork.usdc,
    'data': encodeTransfer(recipient, units),
    'value': '0x0',
    'gas': hexQuantity(gasLimit),
    'maxFeePerGas': hexQuantity(maxFeePerGas),
    'maxPriorityFeePerGas': hexQuantity(maxPriorityFeePerGas),
    'type': '0x2',
    'chainId': hexQuantity(BigInt.from(ArcNetwork.chainId)),
  });

  void verifyConsent({
    required String? currentSender,
    required String? currentTopic,
    required int currentRevision,
    required DateTime now,
  }) {
    if (currentSender?.toLowerCase() != sender.toLowerCase() ||
        currentTopic != topic ||
        currentRevision != sessionRevision) {
      throw StateError('The wallet account or session changed. Review again.');
    }
    if (!now.isBefore(expiresAt)) {
      throw StateError(
        'The transaction review expired. Review fresh fees again.',
      );
    }
  }
}

enum TransactionState { submitted, confirmed, reverted, pending, unknown }

class TransactionResult {
  const TransactionResult(this.hash, this.state, {this.blockNumber});
  final String hash;
  final TransactionState state;
  final BigInt? blockNumber;
}

String validateTransactionHash(Object? value) {
  if (value is! String || !RegExp(r'^0x[0-9a-fA-F]{64}$').hasMatch(value)) {
    throw const FormatException(
      'The wallet returned an invalid transaction hash.',
    );
  }
  return value;
}

TransactionResult parseReceipt(String expectedHash, Object? value) {
  validateTransactionHash(expectedHash);
  if (value == null) {
    return TransactionResult(expectedHash, TransactionState.pending);
  }
  if (value is! Map<String, dynamic> ||
      value['transactionHash'] is! String ||
      (value['transactionHash'] as String).toLowerCase() !=
          expectedHash.toLowerCase() ||
      value['blockHash'] is! String) {
    throw const FormatException(
      'The node returned a mismatched transaction receipt.',
    );
  }
  validateTransactionHash(value['blockHash']);
  final status = parseHexQuantity(value['status']);
  if (status != BigInt.zero && status != BigInt.one) {
    throw const FormatException(
      'The receipt has an unsupported execution status.',
    );
  }
  return TransactionResult(
    expectedHash,
    status == BigInt.one
        ? TransactionState.confirmed
        : TransactionState.reverted,
    blockNumber: parseHexQuantity(value['blockNumber']),
  );
}

String shorten(String value) => value.length < 14
    ? value
    : '${value.substring(0, 7)}…${value.substring(value.length - 5)}';
