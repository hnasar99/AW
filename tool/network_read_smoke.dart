import 'dart:convert';
import '../lib/networks/evm_network.dart';
import '../lib/networks/evm_read_client.dart';

/// Real read-only HTTP using the same Dart client as the APK. Not an Android test.
Future<void> main() async {
  for (final network in EvmNetwork.defaults()) {
    final client = EvmReadClient();
    try {
      final result = await client.inspect(network,
        address: '0x0000000000000000000000000000000000000000');
      if (result.balance == null) throw StateError('Missing balance');
      print(jsonEncode({'status': 'PASS', 'chain_id': network.chainId,
        'source': network.rpcOrigin, 'block': '${result.block}',
        'balance_units': '${result.balance}', 'symbol': network.symbol,
        'observed_at': result.observedAt.toIso8601String(),
        'scope': 'Dart client on CI host; public zero address, not user wallet or Android'}));
    } finally { client.close(); }
  }
}
