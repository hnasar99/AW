import 'dart:convert';

import 'package:arc_wallet_flutter/domain/arc.dart';
import 'package:arc_wallet_flutter/services/arc_rpc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'arc_domain_test.dart'
    show sender, recipient, txHash, blockHash, exampleReview;

ArcRpc mockRpc(Object? Function(String, List<dynamic>) handler) => ArcRpc(
  client: MockClient((request) async {
    final rpc = jsonDecode(request.body) as Map<String, dynamic>;
    return http.Response(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': rpc['id'],
        'result': handler(
          rpc['method'] as String,
          rpc['params'] as List<dynamic>,
        ),
      }),
      200,
    );
  }),
);

void main() {
  test('RPC rejects mismatched IDs and wrong networks', () async {
    final malformed = ArcRpc(
      client: MockClient(
        (_) async =>
            http.Response('{"jsonrpc":"2.0","id":999,"result":"0x1"}', 200),
      ),
    );
    await expectLater(malformed.verifyNetwork(), throwsFormatException);
    malformed.close();
    final wrongNetwork = mockRpc((_, __) => '0x1');
    await expectLater(wrongNetwork.verifyNetwork(), throwsStateError);
    wrongNetwork.close();
  });

  test('preflight rejects combined transfer plus gas overspend', () async {
    final rpc = mockRpc(
      (method, _) => switch (method) {
        'eth_chainId' => hexQuantity(BigInt.from(5042002)),
        'eth_estimateGas' => '0x186a0',
        'eth_getBlockByNumber' => {'baseFeePerGas': '0x4a817c800'},
        'eth_gasPrice' => '0x4a817c800',
        'eth_call' => '0x${'1'.padLeft(64, '0')}',
        'eth_getBalance' => hexQuantity(BigInt.from(10).pow(18)),
        _ => throw StateError('Unexpected method'),
      },
    );
    await expectLater(
      rpc.prepare(
        sender: sender,
        recipient: recipient,
        units: BigInt.from(1000000),
        topic: 'session-a',
        sessionRevision: 4,
      ),
      throwsStateError,
    );
    rpc.close();
  });

  test('preflight returns exact type-2 fee cap before review', () async {
    final rpc = mockRpc(
      (method, _) => switch (method) {
        'eth_chainId' => hexQuantity(BigInt.from(5042002)),
        'eth_estimateGas' => '0x186a0',
        'eth_getBlockByNumber' => {'baseFeePerGas': '0x4a817c800'},
        'eth_gasPrice' => '0x4a817c800',
        'eth_call' => '0x${'1'.padLeft(64, '0')}',
        'eth_getBalance' => hexQuantity(BigInt.from(10).pow(20)),
        _ => throw StateError('Unexpected method'),
      },
    );
    final review = await rpc.prepare(
      sender: sender,
      recipient: recipient,
      units: BigInt.from(1000000),
      topic: 'session-a',
      sessionRevision: 4,
    );
    expect(review.gasLimit, BigInt.from(120000));
    expect(review.maximumFee, BigInt.parse('4800000000000000'));
    expect(review.transaction['type'], '0x2');
    rpc.close();
  });

  test(
    'success and revert receipts must both match reviewed transfer',
    () async {
      for (final status in ['0x1', '0x0']) {
        final rpc = mockRpc(
          (method, _) => switch (method) {
            'eth_getTransactionReceipt' => {
              'transactionHash': txHash,
              'blockHash': blockHash,
              'blockNumber': '0x12',
              'status': status,
            },
            'eth_getTransactionByHash' => {
              'hash': txHash,
              'from': sender,
              'to': recipient,
              'value': '0x0',
              'input': exampleReview().transaction['data'],
            },
            _ => throw StateError('Unexpected method'),
          },
        );
        await expectLater(
          rpc.receipt(txHash, review: exampleReview()),
          throwsStateError,
        );
        rpc.close();
      }
    },
  );

  test('node error bodies are not copied into public errors', () async {
    final rpc = ArcRpc(
      client: MockClient((request) async {
        final id = (jsonDecode(request.body) as Map<String, dynamic>)['id'];
        return http.Response(
          jsonEncode({
            'jsonrpc': '2.0',
            'id': id,
            'error': {'code': -32000, 'message': 'Bearer sensitive-data'},
          }),
          200,
        );
      }),
    );
    try {
      await rpc.verifyNetwork();
      fail('Expected rejection');
    } catch (error) {
      expect(error.toString(), isNot(contains('sensitive-data')));
    }
    rpc.close();
  });
}
