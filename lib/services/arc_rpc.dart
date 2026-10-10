import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/arc.dart';

class ArcRpc {
  ArcRpc({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  int _id = 0;

  void close() => _client.close();

  Future<Object?> call(String method, List<Object?> params) async {
    final id = ++_id;
    final abort = Completer<void>();
    final request =
        http.AbortableRequest(
            'POST',
            Uri.parse(ArcNetwork.rpc),
            abortTrigger: abort.future,
          )
          ..headers['content-type'] = 'application/json'
          ..followRedirects = false
          ..body = jsonEncode({
            'jsonrpc': '2.0',
            'id': id,
            'method': method,
            'params': params,
          });
    try {
      return await (() async {
        final response = await _client.send(request);
        if (response.statusCode != 200) {
          throw StateError('Arc RPC returned HTTP ${response.statusCode}.');
        }
        final bytes = <int>[];
        await for (final part in response.stream) {
          if (bytes.length + part.length > 1024 * 1024) {
            throw const FormatException(
              'Arc RPC response exceeded the size limit.',
            );
          }
          bytes.addAll(part);
        }
        final value = jsonDecode(utf8.decode(bytes));
        if (value is! Map<String, dynamic> ||
            value['jsonrpc'] != '2.0' ||
            value['id'] != id) {
          throw const FormatException(
            'Arc RPC returned a mismatched response.',
          );
        }
        if (value.containsKey('error')) {
          final error = value['error'];
          final code = error is Map ? error['code'] : null;
          // Server error bodies can contain sensitive transaction/provider data.
          throw StateError(
            'Arc RPC rejected $method (code ${code is int ? code : 'unknown'}).',
          );
        }
        if (!value.containsKey('result')) {
          throw const FormatException(
            'Arc RPC response is missing its result.',
          );
        }
        return value['result'];
      })().timeout(const Duration(seconds: 15));
    } finally {
      if (!abort.isCompleted) abort.complete();
    }
  }

  Future<void> verifyNetwork() async {
    if (parseHexQuantity(await call('eth_chainId', const [])) !=
        BigInt.from(ArcNetwork.chainId)) {
      throw StateError(
        'The RPC is not serving Arc Testnet. Sending is disabled.',
      );
    }
  }

  Future<BigInt> nativeBalance(String address) async => parseHexQuantity(
    await call('eth_getBalance', [validateAddress(address), 'latest']),
  );

  Future<TransferReview> prepare({
    required String sender,
    required String recipient,
    required BigInt units,
    required String topic,
    required int sessionRevision,
  }) async {
    validateAddress(sender);
    final data = encodeTransfer(recipient, units);
    await verifyNetwork();
    final tx = <String, String>{
      'from': sender,
      'to': ArcNetwork.usdc,
      'data': data,
      'value': '0x0',
    };
    final results = await Future.wait([
      call('eth_estimateGas', [tx]),
      call('eth_getBlockByNumber', ['latest', false]),
      call('eth_gasPrice', const []),
      call('eth_call', [tx, 'latest']),
    ]);
    final estimatedGas = parseHexQuantity(results[0]);
    if (estimatedGas <= BigInt.zero || estimatedGas > BigInt.from(1000000)) {
      throw StateError('Unexpected gas estimate for a USDC transfer.');
    }
    final block = results[1];
    if (block is! Map<String, dynamic>) {
      throw const FormatException('Missing current block fee data.');
    }
    final baseFee = parseHexQuantity(block['baseFeePerGas']);
    final gasPrice = parseHexQuantity(results[2]);
    final simulated = results[3];
    if (simulated is! String ||
        !RegExp(r'^0x[0-9a-fA-F]{64}$').hasMatch(simulated) ||
        BigInt.parse(simulated.substring(2), radix: 16) != BigInt.one) {
      throw StateError('USDC transfer simulation did not return true.');
    }
    final floor = BigInt.from(20000000000); // Published testnet base-fee floor.
    final priority = gasPrice > baseFee ? gasPrice - baseFee : BigInt.zero;
    final base = baseFee > floor ? baseFee : floor;
    final review = TransferReview(
      sender: sender,
      recipient: recipient,
      units: units,
      topic: topic,
      sessionRevision: sessionRevision,
      expiresAt: DateTime.now().add(const Duration(minutes: 2)),
      // Integer ceiling, with a margin for execution state changes.
      gasLimit:
          (estimatedGas * BigInt.from(120) + BigInt.from(99)) ~/
          BigInt.from(100),
      maxFeePerGas: base * BigInt.two + priority,
      maxPriorityFeePerGas: priority,
    );
    await verifyFunds(review);
    return review;
  }

  Future<void> verifyFunds(TransferReview review) async {
    final balance = await nativeBalance(review.sender);
    if (balance < review.nativeRequired) {
      throw StateError(
        'USDC balance must cover the transfer and its maximum network fee. '
        'Arc has one USDC balance, also used for gas.',
      );
    }
  }

  /// Receipt status is conclusive; a timeout only means pending/unknown.
  Future<TransactionResult> receipt(
    String hash, {
    TransferReview? review,
  }) async {
    final result = parseReceipt(
      hash,
      await call('eth_getTransactionReceipt', [hash]),
    );
    if (result.state == TransactionState.pending || review == null) {
      return result;
    }
    final tx = await call('eth_getTransactionByHash', [hash]);
    final expected = review.transaction;
    if (tx is! Map<String, dynamic> ||
        tx['hash'] is! String ||
        (tx['hash'] as String).toLowerCase() != hash.toLowerCase() ||
        tx['from'] is! String ||
        (tx['from'] as String).toLowerCase() != review.sender.toLowerCase() ||
        tx['to'] is! String ||
        (tx['to'] as String).toLowerCase() != ArcNetwork.usdc ||
        tx['input'] is! String ||
        (tx['input'] as String).toLowerCase() != expected['data'] ||
        parseHexQuantity(tx['value']) != BigInt.zero) {
      throw StateError(
        'The confirmed transaction does not match the reviewed transfer. Inspect the explorer.',
      );
    }
    return result;
  }
}
