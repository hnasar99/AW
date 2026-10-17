import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/arc.dart' show parseHexQuantity, validateAddress;
import 'evm_network.dart';

class NetworkReadFailure implements Exception {
  const NetworkReadFailure(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => message;
}

class NetworkSnapshot {
  const NetworkSnapshot({required this.network, required this.block,
    required this.observedAt, required this.duration, this.address, this.balance});
  final EvmNetwork network;
  final BigInt block;
  final DateTime observedAt;
  final Duration duration;
  final String? address;
  final BigInt? balance;
}

/// Three read methods only. No caller-selected method, signing or broadcasting.
class EvmReadClient {
  EvmReadClient({http.Client? client, this.deadline = const Duration(seconds: 15)})
      : _client = client ?? http.Client();
  final http.Client _client;
  final Duration deadline;
  int _nextId = 0;
  bool _closed = false;
  void close() { _closed = true; _client.close(); }

  Future<NetworkSnapshot> inspect(EvmNetwork network, {String? address}) async {
    if (_closed) throw const NetworkReadFailure('closed', 'El cliente está cerrado.');
    final checkedAddress = address == null ? null : validateAddress(address);
    final abort = Completer<void>();
    final elapsed = Stopwatch()..start();
    Future<BigInt> quantity(String method, List<Object?> params) async {
      final id = ++_nextId;
      final request = http.AbortableRequest('POST', Uri.parse(network.rpcUrl),
          abortTrigger: abort.future)
        ..followRedirects = false
        ..headers['content-type'] = 'application/json'
        ..body = jsonEncode({'jsonrpc': '2.0', 'id': id, 'method': method, 'params': params});
      final response = await _client.send(request);
      if (response.statusCode != 200) {
        throw NetworkReadFailure('http', 'El RPC respondió HTTP ${response.statusCode}. No se cambió de proveedor.');
      }
      if ((response.contentLength ?? 0) > 65536) {
        throw const NetworkReadFailure('size', 'La respuesta RPC supera 64 KiB.');
      }
      final bytes = <int>[];
      await for (final chunk in response.stream) {
        if (bytes.length + chunk.length > 65536) {
          throw const NetworkReadFailure('size', 'La respuesta RPC supera 64 KiB.');
        }
        bytes.addAll(chunk);
      }
      final value = jsonDecode(utf8.decode(bytes));
      if (value is! Map<String, dynamic> || value['jsonrpc'] != '2.0' ||
          value['id'] != id || value.containsKey('error') || !value.containsKey('result')) {
        throw const NetworkReadFailure('envelope', 'El RPC devolvió un error o una respuesta no coincidente.');
      }
      return parseHexQuantity(value['result']);
    }
    try {
      return await (() async {
        final reported = await quantity('eth_chainId', const []);
        if (reported != BigInt.from(network.chainId)) {
          throw NetworkReadFailure('chain_mismatch',
            'Red rechazada: se esperaba ${network.chainId} y el RPC informa $reported.');
        }
        final block = await quantity('eth_blockNumber', const []);
        final balance = checkedAddress == null ? null : await quantity(
          'eth_getBalance', [checkedAddress, '0x${block.toRadixString(16)}']);
        return NetworkSnapshot(network: network, block: block, address: checkedAddress,
          balance: balance, observedAt: DateTime.now().toUtc(), duration: elapsed.elapsed);
      })().timeout(deadline);
    } on NetworkReadFailure {
      rethrow;
    } on TimeoutException {
      throw const NetworkReadFailure('timeout', 'El RPC no respondió a tiempo. No hay saldo nuevo ni conexión verificada.');
    } on FormatException {
      throw const NetworkReadFailure('format', 'El RPC devolvió datos inválidos. El error no es un saldo cero.');
    } catch (_) {
      // Transport errors may include API keys embedded in RPC paths or queries.
      throw const NetworkReadFailure('transport', 'No se pudo consultar el RPC. Revisá HTTPS, conectividad y permisos del proveedor.');
    } finally {
      elapsed.stop();
      if (!abort.isCompleted) abort.complete();
    }
  }
}
