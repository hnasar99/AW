import 'dart:convert';

import 'package:http/http.dart' as http;

const suggestedZonafrancaApiBase =
    'https://mmvkgdjudmmnrdwaysbu.supabase.co/functions/v1/ecosystem-api';

const suggestedZonafrancaAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1tdmtnZGp1ZG1tbnJkd2F5c2J1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU5ODgwNDgsImV4cCI6MjA3MTU2NDA0OH0.OMl17_1d2wS6Gp0Ic1h_JWRW8_OCznByWGFZV88QsMc';

class ZfRow {
  const ZfRow({required this.title, required this.detail});
  final String title;
  final String detail;
}

class ZonafrancaSnapshot {
  const ZonafrancaSnapshot({
    required this.signedIn,
    this.email,
    this.businessName,
    this.walletLinked,
    this.sections = const {},
    this.error,
    this.loading = false,
  });

  final bool signedIn;
  final String? email;
  final String? businessName;
  final bool? walletLinked;
  final Map<String, List<ZfRow>> sections;
  final String? error;
  final bool loading;

  List<ZfRow> rows(String key) => sections[key] ?? const [];

  static const disconnected = ZonafrancaSnapshot(signedIn: false);
}

class ZonafrancaSession {
  const ZonafrancaSession({
    required this.accessToken,
    required this.refreshToken,
    required this.email,
    required this.apiBase,
    required this.anonKey,
  });

  final String accessToken;
  final String refreshToken;
  final String email;
  final String apiBase;
  final String anonKey;

  Map<String, String> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'email': email,
    'api_base': apiBase,
    'anon_key': anonKey,
  };

  static ZonafrancaSession? fromJson(Map<String, dynamic> json) {
    final access = json['access_token'] as String?;
    final refresh = json['refresh_token'] as String?;
    final email = json['email'] as String?;
    final base = json['api_base'] as String?;
    final anon = json['anon_key'] as String?;
    if (access == null ||
        refresh == null ||
        email == null ||
        base == null ||
        anon == null) {
      return null;
    }
    return ZonafrancaSession(
      accessToken: access,
      refreshToken: refresh,
      email: email,
      apiBase: base,
      anonKey: anon,
    );
  }
}

class ZonafrancaAuthApi {
  const ZonafrancaAuthApi({http.Client? client}) : _client = client;
  final http.Client? _client;

  http.Client get _http => _client ?? http.Client();

  Future<void> sendCode({
    required String email,
    required String apiBase,
    required String anonKey,
  }) async {
    final response = await _http.post(
      _auth(apiBase, '/auth/v1/otp'),
      headers: _authHeaders(anonKey),
      body: jsonEncode({'email': email, 'create_user': false}),
    );
    _expect(response);
  }

  Future<ZonafrancaSession> verifyCode({
    required String email,
    required String code,
    required String apiBase,
    required String anonKey,
  }) async {
    final response = await _http.post(
      _auth(apiBase, '/auth/v1/verify'),
      headers: _authHeaders(anonKey),
      body: jsonEncode({'email': email, 'token': code, 'type': 'email'}),
    );
    return _session(response, email: email, apiBase: apiBase, anonKey: anonKey);
  }

  Future<ZonafrancaSession> signInPassword({
    required String email,
    required String password,
    required String apiBase,
    required String anonKey,
  }) async {
    final response = await _http.post(
      _auth(apiBase, '/auth/v1/token').replace(
        queryParameters: {'grant_type': 'password'},
      ),
      headers: _authHeaders(anonKey),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _session(response, email: email, apiBase: apiBase, anonKey: anonKey);
  }

  Future<ZonafrancaSession> refresh(ZonafrancaSession session) async {
    final response = await _http.post(
      _auth(session.apiBase, '/auth/v1/token').replace(
        queryParameters: {'grant_type': 'refresh_token'},
      ),
      headers: _authHeaders(session.anonKey),
      body: jsonEncode({'refresh_token': session.refreshToken}),
    );
    return _session(
      response,
      email: session.email,
      apiBase: session.apiBase,
      anonKey: session.anonKey,
    );
  }

  Future<ZonafrancaSession> redeemCompanyLink(
    String raw, {
    String? anonKey,
  }) async {
    final parsed = parseCompanyLinkQr(raw);
    if (parsed == null) {
      throw const ZonafrancaException('El QR no es de una empresa Fluuix');
    }
    final apiBase = parsed['api_base'] as String;
    final anon = anonKey ?? suggestedZonafrancaAnonKey;
    final response = await _http.post(
      _api(apiBase, '/v1/link/redeem'),
      headers: {
        'Content-Type': 'application/json',
        'apikey': anon,
        'Authorization': 'Bearer $anon',
      },
      body: jsonEncode({'token': parsed['token']}),
    );
    final json = _expect(response);
    final hash = json['token_hash'] as String?;
    final email = json['email'] as String? ?? '';
    if (hash == null || hash.isEmpty) {
      throw const ZonafrancaException('El QR no abrió la sesión de la empresa');
    }
    final verify = await _http.post(
      _auth(apiBase, '/auth/v1/verify'),
      headers: _authHeaders(anon),
      body: jsonEncode({'token_hash': hash, 'type': 'magiclink'}),
    );
    return _session(verify, email: email, apiBase: apiBase, anonKey: anon);
  }

  Future<ZonafrancaSnapshot> loadBooks(
    ZonafrancaSession session, {
    String? wallet,
  }) async {
    Future<Map<String, dynamic>> get(String path) async {
      var uri = _api(session.apiBase, path);
      if (wallet != null && path.startsWith('/v1/me')) {
        uri = uri.replace(
          queryParameters: {...uri.queryParameters, 'wallet': wallet},
        );
      }
      final response = await _http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 401) {
        throw const ZonafrancaException('Sesión vencida');
      }
      return _jsonMap(response);
    }

    final results = await Future.wait([
      get('/v1/me'),
      get('/v1/positions/trusts'),
      get('/v1/positions/funds'),
      get('/v1/positions/campaigns'),
      get('/v1/positions/tenders'),
      get('/v1/positions/donations'),
      get('/v1/zonabank/balances'),
      get('/v1/zonabank/vault'),
      get('/v1/zonabank/history'),
      get('/v1/zonabank/incoming'),
      get('/v1/zonabank/history?scope=cross_border'),
      get('/v1/treasury/caps'),
      get('/v1/zonafranca/assets'),
      get('/v1/ttn/instruments'),
      get('/v1/treasury/position'),
      get('/v1/catalog'),
      get('/v1/zonabank/accounts'),
      get('/v1/zonabank/beneficiaries'),
      get('/v1/zonabank/overview'),
    ]);
    return parseEcosystem({
      'me': results[0],
      'trusts': results[1],
      'funds': results[2],
      'campaigns': results[3],
      'tenders': results[4],
      'donations': results[5],
      'balances': results[6],
      'vault': results[7],
      'history': results[8],
      'incoming': results[9],
      'crossBorder': results[10],
      'caps': results[11],
      'assets': results[12],
      'instruments': results[13],
      'position': results[14],
      'catalog': results[15],
      'accounts': results[16],
      'beneficiaries': results[17],
      'overview': results[18],
    }, emailFallback: session.email);
  }
}

ZonafrancaSnapshot parseEcosystem(
  Map<String, dynamic> bodies, {
  String? emailFallback,
}) {
  final me = _map(bodies['me']);
  final user = _map(me['user']);
  final business = _map(me['business']);
  final error = _firstError(bodies);
  return ZonafrancaSnapshot(
    signedIn: true,
    email: user['email'] as String? ?? emailFallback,
    businessName: business['name'] as String?,
    walletLinked: me['walletLinked'] as bool?,
    error: error,
    sections: {
      'trusts': _items(bodies['trusts'], _trust),
      'funds': _items(bodies['funds'], _fund),
      'campaigns': _items(bodies['campaigns'], _campaign),
      'tenders': _items(bodies['tenders'], _tender),
      'donations': _items(bodies['donations'], _campaign),
      'balances': _balances(bodies['balances']),
      'vault': _vault(bodies['vault']),
      'history': _items(bodies['history'], _movement, listKey: 'transactions'),
      'incoming': _items(bodies['incoming'], _movement, listKey: 'transactions'),
      'crossBorder': _items(
        bodies['crossBorder'],
        _movement,
        listKey: 'transactions',
      ),
      'caps': _items(bodies['caps'], _cap),
      'assets': _items(bodies['assets'], _asset),
      'property': _items(bodies['assets'], _asset, kind: 'real_estate'),
      'zone': _items(bodies['assets'], _asset, kind: 'zone'),
      'shares': _items(bodies['assets'], _asset, kind: 'equity'),
      'documents': _items(bodies['assets'], _asset, kind: 'digital'),
      'contracts': _items(bodies['assets'], _asset, kind: 'contract'),
      'escrow': _items(bodies['assets'], _asset, kind: 'escrow'),
      'instruments': _items(bodies['instruments'], _instrument),
      'position': _position(bodies['position']),
      'catalog': _catalog(bodies['catalog']),
      'accounts': _accounts(bodies['accounts']),
      'beneficiaries': _items(bodies['beneficiaries'], _beneficiary),
      'overview': _overview(bodies['overview']),
    },
  );
}

String? _firstError(Map<String, dynamic> bodies) {
  for (final value in bodies.values) {
    final map = _map(value);
    if (map['success'] == false) {
      final message = map['error'];
      if (message is String && message.isNotEmpty) return message;
    }
  }
  return null;
}

List<ZfRow> _items(
  dynamic body,
  ZfRow Function(Map<String, dynamic>) mapRow, {
  String listKey = 'items',
  String? kind,
}) {
  final rows = _map(body)[listKey];
  if (rows is! List) return const [];
  return [
    for (final row in rows)
      if (row is Map && _kindOk(row.cast<String, dynamic>(), kind))
        mapRow(row.cast<String, dynamic>()),
  ];
}

bool _kindOk(Map<String, dynamic> row, String? kind) {
  if (kind == null) return true;
  final type = row['asset_type'] as String?;
  final vehicle = row['legal_vehicle_id'];
  return switch (kind) {
    'real_estate' => type == 'real_estate',
    'zone' => type == 'physical' || type == 'commodity',
    'equity' => type == 'equity',
    'digital' => type == 'digital',
    'contract' => type == 'service' || type == 'ip',
    'escrow' => vehicle != null,
    _ => true,
  };
}

List<ZfRow> _balances(dynamic body) {
  final balances = _map(body)['balances'];
  final twin = _map(balances)['twin'];
  if (twin is! List) return const [];
  return [
    for (final row in twin)
      if (row is Map && row['configured'] == true)
        ZfRow(
          title: '${row['symbol'] ?? 'Riel'}',
          detail: '${row['balance'] ?? ''}',
        ),
  ];
}

List<ZfRow> _vault(dynamic body) {
  final balances = _map(_map(body)['balances']);
  if (balances.isEmpty) return const [];
  return [
    if (balances['shares'] != null)
      ZfRow(title: 'Participaciones de reserva', detail: '${balances['shares']}'),
    if (balances['assetsOfShares'] != null)
      ZfRow(title: 'Activos en reserva', detail: '${balances['assetsOfShares']}'),
    if (balances['argtWallet'] != null)
      ZfRow(title: 'ARGt en wallet', detail: '${balances['argtWallet']}'),
  ];
}

List<ZfRow> _position(dynamic body) {
  final map = _map(body);
  if (map.isEmpty || map['success'] == false) return const [];
  final accounts = _map(map['accounts']);
  final wallets = accounts['wallets'];
  final banks = accounts['banks'];
  if (wallets == null && banks == null) return const [];
  return [
    ZfRow(
      title: 'Cuentas de la empresa',
      detail: 'Wallets $wallets · bancos $banks',
    ),
  ];
}

ZfRow _trust(Map<String, dynamic> row) => ZfRow(
  title: 'Fideicomiso ${row['jurisdiction_code'] ?? ''}'.trim(),
  detail: '${row['status'] ?? 'sin estado'}',
);

ZfRow _fund(Map<String, dynamic> row) => ZfRow(
  title: '${row['fund_name'] ?? 'Fondo'}',
  detail: '${row['status'] ?? ''} ${row['current_nav'] ?? ''} ${row['nav_currency'] ?? ''}'
      .trim(),
);

ZfRow _campaign(Map<String, dynamic> row) => ZfRow(
  title: '${row['title'] ?? 'Campaña'}',
  detail: '${row['status'] ?? ''} ${row['raised_amount'] ?? 0}/${row['target_amount'] ?? ''} ${row['currency'] ?? ''}'
      .trim(),
);

ZfRow _tender(Map<String, dynamic> row) => ZfRow(
  title: '${row['title'] ?? row['tender_type'] ?? 'Licitación'}',
  detail: '${row['status'] ?? row['procurement_type'] ?? ''}',
);

ZfRow _asset(Map<String, dynamic> row) => ZfRow(
  title: '${row['asset_name'] ?? 'Activo'}',
  detail: '${row['asset_type'] ?? ''} ${row['tokenization_status'] ?? ''}'.trim(),
);

ZfRow _instrument(Map<String, dynamic> row) => ZfRow(
  title: '${row['name'] ?? 'Instrumento'} ${row['symbol'] ?? ''}'.trim(),
  detail: '${row['status'] ?? 'sin estado'}',
);

ZfRow _movement(Map<String, dynamic> row) => ZfRow(
  title: '${row['amount'] ?? ''} ${row['assetSymbol'] ?? ''}'.trim(),
  detail: '${row['status'] ?? ''}',
);

List<ZfRow> _catalog(dynamic body) {
  final tools = _map(body)['tools'];
  if (tools is! List) return const [];
  return [
    for (final tool in tools)
      if (tool is Map && tool['name'] != null)
        ZfRow(
          title: '${tool['name']}',
          detail: tool['available'] == false
              ? '${tool['reason'] ?? 'Sin datos'}'
              : '${tool['description'] ?? tool['kind'] ?? ''}',
        ),
  ];
}

List<ZfRow> _accounts(dynamic body) {
  final map = _map(body);
  final rows = map['items'] ?? map['wallets'];
  if (rows is! List) return const [];
  return [
    for (final row in rows)
      if (row is Map)
        ZfRow(
          title: '${row['label'] ?? row['name'] ?? 'Cuenta'}',
          detail:
              '${row['wallet_address'] ?? row['address'] ?? row['chain'] ?? ''}'
                  .trim(),
        ),
  ];
}

List<ZfRow> _overview(dynamic body) {
  final map = _map(body);
  if (map.isEmpty || map['success'] == false) return const [];
  final accounts = _map(map['accounts']);
  if (accounts.isEmpty && map['recent'] is! List) return const [];
  return [
    if (accounts.isNotEmpty)
      ZfRow(
        title: 'Resumen ZonaBank',
        detail:
            'Wallets ${accounts['wallets'] ?? 0} · bancos ${accounts['banks'] ?? 0}',
      ),
    ..._items({'items': map['recent']}, _movement),
  ];
}

ZfRow _beneficiary(Map<String, dynamic> row) => ZfRow(
  title: '${row['label'] ?? 'Destinatario'}',
  detail: '${row['wallet_address'] ?? row['chain'] ?? ''}'.trim(),
);

ZfRow _cap(Map<String, dynamic> row) => ZfRow(
  title: '${row['name'] ?? 'Tope'}',
  detail:
      'Día ${row['daily_limit_usd'] ?? '—'} · operación ${row['single_tx_limit_usd'] ?? '—'}',
);

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? value.cast<String, dynamic>() : const {};

Uri _auth(String apiBase, String path) {
  final base = Uri.parse(apiBase);
  return Uri(
    scheme: base.scheme,
    host: base.host,
    port: base.hasPort ? base.port : null,
    path: path,
  );
}

Uri _api(String apiBase, String path) {
  final base = Uri.parse(apiBase.endsWith('/') ? apiBase.substring(0, apiBase.length - 1) : apiBase);
  final extra = path.startsWith('/') ? path.substring(1) : path;
  return Uri.parse('${base.toString()}/$extra');
}

Map<String, String> _authHeaders(String anonKey) => {
  'apikey': anonKey,
  'Authorization': 'Bearer $anonKey',
  'Content-Type': 'application/json',
};

ZonafrancaSession _session(
  http.Response response, {
  required String email,
  required String apiBase,
  required String anonKey,
}) {
  final json = _expect(response);
  final access = json['access_token'] as String?;
  final refresh = json['refresh_token'] as String?;
  if (access == null || refresh == null) {
    throw const ZonafrancaException('La sesión no incluyó tokens');
  }
  return ZonafrancaSession(
    accessToken: access,
    refreshToken: refresh,
    email: json['user'] is Map
        ? (json['user']['email'] as String? ?? email)
        : email,
    apiBase: apiBase,
    anonKey: anonKey,
  );
}

Map<String, dynamic> _expect(http.Response response) {
  final json = _jsonMap(response);
  if (response.statusCode >= 400) {
    final message = json['error_description'] ?? json['msg'] ?? json['error'];
    throw ZonafrancaException(
      message is String ? message : 'No se pudo conectar Zonafranca',
    );
  }
  return json;
}

Map<String, dynamic> _jsonMap(http.Response response) {
  if (response.body.isEmpty) return const {};
  final decoded = jsonDecode(response.body);
  if (decoded is Map<String, dynamic>) return decoded;
  if (decoded is Map) return decoded.cast<String, dynamic>();
  return const {};
}

Map<String, dynamic>? parseCompanyLinkQr(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final map = decoded.cast<String, dynamic>();
    if (map['type'] != 'fluuix_company_link') return null;
    if (map['token'] is! String || (map['token'] as String).isEmpty) return null;
    if (map['api_base'] is! String || (map['api_base'] as String).isEmpty) {
      return null;
    }
    return map;
  } catch (_) {
    return null;
  }
}

/// The next company replaces the previous books. Nothing from [previous] is kept.
ZonafrancaSnapshot adoptCompanyLink({
  ZonafrancaSnapshot? previous,
  required ZonafrancaSnapshot next,
}) {
  return identical(previous, next) ? next : next;
}

class ZonafrancaException implements Exception {
  const ZonafrancaException(this.message);
  final String message;
  @override
  String toString() => message;
}
