import 'dart:convert';

import 'package:arc_wallet_flutter/services/ecosystem_mcp.dart';
import 'package:arc_wallet_flutter/services/zonafranca_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  const session = ZonafrancaSession(
    accessToken: 'session-token',
    refreshToken: 'refresh-token',
    email: 'ana@zf.test',
    apiBase: 'https://example.test/functions/v1/ecosystem-api',
    anonKey: 'anon',
  );

  test('the catalog names Fluuix, ZonaFranca and TokenizaTuNegocio', () async {
    final mcp = EcosystemMcp(client: _Boom());
    final listed = await mcp.handle({
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'tools/list',
    });
    final names = catalogNames(listed['result']);
    expect(names, containsAll([
      'ecosystem_me',
      'zonafranca_assets',
      'ttn_instruments',
      'positions_trusts',
      'positions_funds',
      'positions_campaigns',
      'positions_tenders',
      'positions_donations',
      'zonabank_accounts',
    ]));
    expect(
      ecosystemPortals.map((portal) => portal.id),
      containsAll([
        'fluuix',
        'zonafranca',
        'tokenizatunegocio',
        'academia',
      ]),
    );
  });

  test('a write tool never leaves the phone', () async {
    final mcp = EcosystemMcp(client: _Boom());
    final denied = await mcp.handle(
      {
        'jsonrpc': '2.0',
        'id': 2,
        'method': 'tools/call',
        'params': {
          'name': 'payment_prepare',
          'arguments': {
            'accessToken': 'leaked',
            'password': 'secret',
            'amount': '1',
            'idempotency_key': '12345678',
          },
        },
      },
      session: session,
    );
    final encoded = jsonEncode(denied);
    expect(denied['result']['isError'], isTrue);
    expect(encoded, contains('no la ejecuta'));
    expect(encoded, isNot(contains('leaked')));
    expect(encoded, isNot(contains('secret')));
    expect(encoded, isNot(contains('session-token')));
  });

  test('a portal read uses the session and drops secret arguments', () async {
    final client = _Capture();
    final mcp = EcosystemMcp(client: client);
    final text = await mcp.read(
      'zonafranca_assets',
      session,
      arguments: {'kind': 'zone', 'accessToken': 'leaked'},
    );
    expect(text, contains('Lote 4'));
    expect(client.last!.headers['Authorization'], 'Bearer session-token');
    expect(client.last!.url.path, endsWith('/v1/zonafranca/assets'));
    expect(client.last!.url.queryParameters['kind'], 'zone');
    expect(client.last!.url.query, isNot(contains('leaked')));
    expect(client.last!.url.query, isNot(contains('session-token')));
  });

  test('books keep catalog and account rows', () {
    final snapshot = parseEcosystem({
      'catalog': {
        'tools': [
          {
            'name': 'zonafranca_assets',
            'available': true,
            'description': 'Activos',
          },
        ],
      },
      'accounts': {
        'items': [
          {'label': 'Operativa', 'wallet_address': '0xabc'},
        ],
      },
    });
    expect(snapshot.rows('catalog').single.title, 'zonafranca_assets');
    expect(snapshot.rows('accounts').single.detail, '0xabc');
    final bank = ecosystemPortals.firstWhere((portal) => portal.id == 'zonabank');
    expect(portalStatus(bank, snapshot), 'Conectado. 1 lectura.');
    final academy = ecosystemPortals.firstWhere((portal) => portal.id == 'academia');
    expect(portalStatus(academy, snapshot), contains('No mueve fondos'));
  });
}

class _Boom extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw StateError('network ${request.url}');
  }
}

class _Capture extends http.BaseClient {
  http.BaseRequest? last;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    last = request;
    return http.StreamedResponse(
      Stream.value(
        utf8.encode(
          '{"success":true,"items":[{"asset_name":"Lote 4","asset_type":"physical"}]}',
        ),
      ),
      200,
      request: request,
    );
  }
}
