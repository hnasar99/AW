import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:arc_wallet_flutter/networks/evm_network.dart';
import 'package:arc_wallet_flutter/networks/evm_read_client.dart';
import 'package:arc_wallet_flutter/networks/network_controller.dart';
import 'package:arc_wallet_flutter/networks/network_manager_screen.dart';

const account = '0x1111111111111111111111111111111111111111';
EvmNetwork custom({String rpc = 'https://rpc.example/v1', int id = 1337}) =>
  EvmNetwork(name: 'Mi red', chainId: id, rpcUrl: rpc, symbol: 'DEV');
class MemoryStore implements NetworkPersistence {
  String? value;
  bool fail = false;
  int writes = 0;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async { if (fail) throw StateError('disk'); writes++; this.value = value; }
}
EvmReadClient fixture({int? reported, List<Map<String, dynamic>>? calls}) => EvmReadClient(client: MockClient((request) async {
  final body = jsonDecode(request.body) as Map<String, dynamic>;
  calls?.add(body);
  expect(request.followRedirects, false);
  final id = reported ?? (request.url.path.endsWith('monad-testnet') ? 10143 : 5042002);
  final result = switch (body['method']) {
    'eth_chainId' => '0x${id.toRadixString(16)}',
    'eth_blockNumber' => '0x100',
    'eth_getBalance' => '0xde0b6b3a7640001',
    _ => throw StateError('forbidden method'),
  };
  return http.Response(jsonEncode({'jsonrpc': '2.0', 'id': body['id'], 'result': result}), 200);
}));

void main() {
  test('decimal and hex IDs are equivalent and bounded', () {
    expect(parseChainId('5042002'), 5042002);
    expect(parseChainId('0x4cef52'), 5042002);
    for (final bad in ['0', '-1', '1.0', '0x', '9007199254740992', '1e3']) {
      expect(() => parseChainId(bad), throwsFormatException);
    }
  });
  test('HTTPS only, no userinfo, fragments or ambiguous whitespace', () {
    for (final bad in ['http://rpc.example', 'file:///tmp/a', 'https://u:p@rpc.example', 'https://rpc.example/#x', 'https://rpc.ex ample', 'https://rpc.example:0']) {
      expect(() => custom(rpc: bad), throwsFormatException);
    }
    expect(custom(rpc: 'https://rpc.example/key?token=private').rpcOrigin, 'https://rpc.example');
  });
  test('known testnet metadata and Fluuix routing are explicit', () {
    expect(EvmNetwork.defaults().every((p) => p.viaFluuix), true);
    expect(() => EvmNetwork(name: 'bad', chainId: 10143, rpcUrl: 'https://rpc.example', symbol: 'USDC'), throwsFormatException);
    expect(EvmNetwork(name: 'Arc', chainId: 5042002, rpcUrl: 'https://rpc.testnet.arc.io', symbol: 'USDC').viaFluuix, false);
  });
  test('profile storage round trips and never silently replaces corruption', () {
    final initial = NetworkBook.initial();
    expect(NetworkBook.decode(initial.encode()).encode(), initial.encode());
    for (final bad in ['{', '{}', 'null', '[]', 'x' * 65537]) {
      expect(() => NetworkBook.decode(bad), throwsFormatException);
    }
    expect(NetworkBook.decode(null).selectedId, 5042002);
  });
  test('no duplicate chain IDs and no active-network deletion', () {
    final book = NetworkBook.initial();
    expect(() => book.upsert(book.selected, replaceExisting: false), throwsFormatException);
    expect(() => book.remove(book.selectedId), throwsFormatException);
    expect(book.upsert(custom(), replaceExisting: false).selectedId, 1337);
  });
  test('identity checked before block and balance is block-pinned and exact', () async {
    final calls = <Map<String, dynamic>>[];
    final client = fixture(calls: calls);
    final result = await client.inspect(EvmNetwork.defaults().first, address: account);
    expect(result.balance, BigInt.parse('1000000000000000001'));
    expect(result.block, BigInt.from(256));
    expect(calls.map((c) => c['method']).toList(), ['eth_chainId', 'eth_blockNumber', 'eth_getBalance']);
    expect(calls.last['params'], [account, '0x100']);
    client.close();
  });
  test('chain mismatch prevents the balance lookup', () async {
    final calls = <Map<String, dynamic>>[];
    final client = fixture(reported: 1, calls: calls);
    await expectLater(client.inspect(EvmNetwork.defaults().first, address: account),
      throwsA(isA<NetworkReadFailure>().having((e) => e.code, 'code', 'chain_mismatch')));
    expect(calls.length, 1); client.close();
  });
  test('transport error never exposes token URL', () async {
    final client = EvmReadClient(client: MockClient((_) async => throw StateError('https://rpc.example/SECRET_CANARY')));
    try { await client.inspect(custom()); fail('must fail'); }
    on NetworkReadFailure catch (e) { expect(e.message.contains('SECRET_CANARY'), false); }
    client.close();
  });
  test('redirect is rejected rather than accepted', () async {
    final client = EvmReadClient(client: MockClient((_) async => http.Response('', 307, headers: {'location': 'https://elsewhere.example'})));
    await expectLater(client.inspect(custom()), throwsA(isA<NetworkReadFailure>())); client.close();
  });
  test('malformed envelopes and excessive responses are rejected', () async {
    for (final text in ['{}', '{', 'x' * 65537, jsonEncode({'jsonrpc': '2.0', 'id': 999, 'result': '0x1'})]) {
      final client = EvmReadClient(client: MockClient((_) async => http.Response(text, 200)));
      await expectLater(client.inspect(custom()), throwsA(isA<NetworkReadFailure>())); client.close();
    }
  });
  test('overall timeout is surfaced without provider fallback', () async {
    final client = EvmReadClient(deadline: const Duration(milliseconds: 5),
      client: MockClient((_) => Completer<http.Response>().future));
    await expectLater(client.inspect(custom()), throwsA(isA<NetworkReadFailure>().having((e) => e.code, 'code', 'timeout')));
    client.close();
  });
  test('load does not contact network; successful switch persists', () async {
    final store = MemoryStore(); int clients = 0;
    final c = NetworkController(persistence: store, clientFactory: () { clients++; return fixture(); });
    await c.load(); expect(clients, 0); expect(c.snapshot, null);
    expect(await c.select(10143), true); expect(c.selected.chainId, 10143);
    expect(NetworkBook.decode(store.value).selectedId, 10143); c.dispose();
  });
  test('failed switch does not replace selected profile or persist it', () async {
    final store = MemoryStore();
    final c = NetworkController(persistence: store, clientFactory: () => fixture(reported: 1));
    await c.load(); expect(await c.select(10143), false);
    expect(c.selected.chainId, 5042002); expect(c.snapshot, null); expect(store.writes, 0); c.dispose();
  });
  test('storage failure prevents activation after valid RPC observation', () async {
    final store = MemoryStore()..fail = true;
    final c = NetworkController(persistence: store, clientFactory: () => fixture());
    await c.load(); expect(await c.select(10143), false);
    expect(c.storageFault, true); expect(c.selected.chainId, 5042002); expect(c.snapshot, null); c.dispose();
  });
  test('corrupt stored configuration fails closed without deleting data', () async {
    final store = MemoryStore()..value = '{corrupt';
    final c = NetworkController(persistence: store, clientFactory: () => fixture());
    await c.load(); expect(c.storageFault, true); expect(await c.refresh(), false);
    expect(store.value, '{corrupt'); expect(store.writes, 0);
    await c.resetProfiles(); expect(c.loaded, true); expect(c.storageFault, false); c.dispose();
  });
  test('custom profile is verified and persisted with exact endpoint', () async {
    final store = MemoryStore();
    final c = NetworkController(persistence: store, clientFactory: () => fixture(reported: 1337));
    await c.load();
    expect(await c.saveAndConnect(custom(), replaceExisting: false), true);
    expect(c.selected.chainId, 1337);
    expect(NetworkBook.decode(store.value).selected.rpcUrl, 'https://rpc.example/v1');
    c.dispose();
  });
  testWidgets('native screen displays scope and reads a selected chain with fixture', (tester) async {
    final c = NetworkController(persistence: MemoryStore(), clientFactory: () => fixture());
    await c.load();
    await tester.pumpWidget(MaterialApp(home: NetworkManagerScreen(controller: c, autoLoad: false)));
    expect(find.text('Fluuix · Redes EVM'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('verify-network')));
    await tester.tap(find.byKey(const Key('verify-network'))); await tester.pumpAndSettle();
    expect(find.text('RPC verificado · chain 5042002'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink()); c.dispose();
  });
  testWidgets('selector does not display an unverified network after a rejected change', (tester) async {
    final c = NetworkController(persistence: MemoryStore(), clientFactory: () => fixture(reported: 1));
    await c.load();
    await tester.pumpWidget(MaterialApp(home: NetworkManagerScreen(controller: c, autoLoad: false)));
    final selector = find.byKey(const Key('network-selector'));
    tester.widget<DropdownButton<int>>(selector).onChanged!(10143);
    await tester.pumpAndSettle();
    expect(tester.widget<DropdownButton<int>>(selector).value, 5042002);
    expect(c.snapshot, null);
    await tester.pumpWidget(const SizedBox.shrink()); c.dispose();
  });
  testWidgets('new RPC requires explicit consent and valid fields', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NetworkEditor()));
    final scroll = find.byType(Scrollable).first;
    final save = find.byKey(const Key('save-network'));
    await tester.scrollUntilVisible(save, 200, scrollable: scroll);
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    final consent = find.byType(CheckboxListTile);
    await tester.ensureVisible(consent); await tester.tap(consent); await tester.pumpAndSettle();
    await tester.ensureVisible(save); await tester.tap(save); await tester.pumpAndSettle();
    expect(find.text('Chain ID decimal o hexadecimal 0x requerido.'), findsOneWidget);
  });
}
