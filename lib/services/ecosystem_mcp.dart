import 'package:http/http.dart' as http;

import 'zonafranca_api.dart';

/// In-app host for ecosystem-mcp. The session token stays on the phone.
/// Tool arguments never carry it, and write tools are not executed here.
const ecosystemProtocol = '2024-11-05';

class EcosystemTool {
  const EcosystemTool({
    required this.name,
    required this.method,
    required this.path,
    required this.kind,
    required this.description,
    required this.portal,
  });

  final String name;
  final String method;
  final String path;
  final String kind;
  final String description;
  final String portal;

  bool get reads => kind == 'read';

  Map<String, Object> toCatalog() => {
    'name': name,
    'description': description,
    'inputSchema': const {'type': 'object'},
  };
}

class EcosystemPortal {
  const EcosystemPortal({
    required this.id,
    required this.label,
    required this.blurb,
    this.section,
    this.readTool,
  });

  final String id;
  final String label;
  final String blurb;
  final String? section;
  final String? readTool;
}

const ecosystemPortals = <EcosystemPortal>[
  EcosystemPortal(
    id: 'fluuix',
    label: 'Fluuix',
    blurb: 'Posición de la empresa y catálogo de lecturas.',
    section: 'position',
    readTool: 'ecosystem_me',
  ),
  EcosystemPortal(
    id: 'zonafranca',
    label: 'ZonaFranca',
    blurb: 'Activos y trazabilidad del tenant.',
    section: 'assets',
    readTool: 'zonafranca_assets',
  ),
  EcosystemPortal(
    id: 'tokenizatunegocio',
    label: 'TokenizaTuNegocio',
    blurb: 'Instrumentos ya emitidos.',
    section: 'instruments',
    readTool: 'ttn_instruments',
  ),
  EcosystemPortal(
    id: 'tokenizeyourbusiness',
    label: 'Tokenize Your Business',
    blurb: 'El mismo libro de instrumentos.',
    section: 'instruments',
    readTool: 'ttn_instruments',
  ),
  EcosystemPortal(
    id: 'zonabank',
    label: 'ZonaBank',
    blurb: 'Cuentas, riel local y cobros.',
    section: 'accounts',
    readTool: 'zonabank_accounts',
  ),
  EcosystemPortal(
    id: 'fideicomiso',
    label: 'Fideicomisos',
    blurb: 'Vehículos del tenant.',
    section: 'trusts',
    readTool: 'positions_trusts',
  ),
  EcosystemPortal(
    id: 'fondos',
    label: 'Fondos',
    blurb: 'Fondos del tenant.',
    section: 'funds',
    readTool: 'positions_funds',
  ),
  EcosystemPortal(
    id: 'crowdfunding',
    label: 'Crowdfunding',
    blurb: 'Campañas del tenant.',
    section: 'campaigns',
    readTool: 'positions_campaigns',
  ),
  EcosystemPortal(
    id: 'licitaciones',
    label: 'Licitaciones',
    blurb: 'Procesos del tenant.',
    section: 'tenders',
    readTool: 'positions_tenders',
  ),
  EcosystemPortal(
    id: 'donations',
    label: 'Donaciones',
    blurb: 'Campañas de donación.',
    section: 'donations',
    readTool: 'positions_donations',
  ),
  EcosystemPortal(
    id: 'academia',
    label: 'Academia',
    blurb: 'No mueve fondos y no tiene lectura.',
  ),
];

const ecosystemTools = <EcosystemTool>[
  EcosystemTool(name: 'ecosystem_me', method: 'GET', path: '/v1/me', kind: 'read', description: 'Usuario, empresa y wallets vinculadas.', portal: 'fluuix'),
  EcosystemTool(name: 'link_qr', method: 'POST', path: '/v1/link/qr', kind: 'write', description: 'Crea un QR de un solo uso.', portal: 'fluuix'),
  EcosystemTool(name: 'link_redeem', method: 'POST', path: '/v1/link/redeem', kind: 'write', description: 'Canjea el QR de la empresa.', portal: 'fluuix'),
  EcosystemTool(name: 'ecosystem_catalog', method: 'GET', path: '/v1/catalog', kind: 'read', description: 'Catálogo de herramientas del tenant.', portal: 'fluuix'),
  EcosystemTool(name: 'zonabank_accounts', method: 'GET', path: '/v1/zonabank/accounts', kind: 'read', description: 'Cuentas de la empresa.', portal: 'zonabank'),
  EcosystemTool(name: 'zonabank_balances', method: 'GET', path: '/v1/zonabank/balances', kind: 'read', description: 'Saldos del riel local.', portal: 'zonabank'),
  EcosystemTool(name: 'zonabank_beneficiaries', method: 'GET', path: '/v1/zonabank/beneficiaries', kind: 'read', description: 'Destinatarios de la empresa.', portal: 'zonabank'),
  EcosystemTool(name: 'zonabank_history', method: 'GET', path: '/v1/zonabank/history', kind: 'read', description: 'Pagos emitidos por la empresa.', portal: 'zonabank'),
  EcosystemTool(name: 'zonabank_overview', method: 'GET', path: '/v1/zonabank/overview', kind: 'read', description: 'Resumen de cuentas y movimientos.', portal: 'zonabank'),
  EcosystemTool(name: 'zonabank_vault', method: 'GET', path: '/v1/zonabank/vault', kind: 'read', description: 'Reserva del riel local.', portal: 'zonabank'),
  EcosystemTool(name: 'zonabank_incoming', method: 'GET', path: '/v1/zonabank/incoming', kind: 'read', description: 'Cobros liquidados hacia la empresa.', portal: 'zonabank'),
  EcosystemTool(name: 'companies_search', method: 'GET', path: '/v1/companies/search', kind: 'read', description: 'Directorio de empresas del ecosistema.', portal: 'fluuix'),
  EcosystemTool(name: 'company_payment_profile', method: 'GET', path: '/v1/companies/:id/payment-profile', kind: 'read', description: 'Rieles públicos de una empresa.', portal: 'fluuix'),
  EcosystemTool(name: 'zonafranca_assets', method: 'GET', path: '/v1/zonafranca/assets', kind: 'read', description: 'Activos y eventos de ZonaFranca.', portal: 'zonafranca'),
  EcosystemTool(name: 'ttn_instruments', method: 'GET', path: '/v1/ttn/instruments', kind: 'read', description: 'Instrumentos ya emitidos.', portal: 'tokenizatunegocio'),
  EcosystemTool(name: 'positions_trusts', method: 'GET', path: '/v1/positions/trusts', kind: 'read', description: 'Fideicomisos del tenant.', portal: 'fideicomiso'),
  EcosystemTool(name: 'positions_funds', method: 'GET', path: '/v1/positions/funds', kind: 'read', description: 'Fondos del tenant.', portal: 'fondos'),
  EcosystemTool(name: 'positions_campaigns', method: 'GET', path: '/v1/positions/campaigns', kind: 'read', description: 'Crowdfunding del tenant.', portal: 'crowdfunding'),
  EcosystemTool(name: 'positions_tenders', method: 'GET', path: '/v1/positions/tenders', kind: 'read', description: 'Licitaciones del tenant.', portal: 'licitaciones'),
  EcosystemTool(name: 'positions_donations', method: 'GET', path: '/v1/positions/donations', kind: 'read', description: 'Donaciones del tenant.', portal: 'donations'),
  EcosystemTool(name: 'treasury_position', method: 'GET', path: '/v1/treasury/position', kind: 'read', description: 'Posición de tesorería sin sumar Arc.', portal: 'fluuix'),
  EcosystemTool(name: 'treasury_caps', method: 'GET', path: '/v1/treasury/caps', kind: 'read', description: 'Topes de política de la empresa.', portal: 'fluuix'),
  EcosystemTool(name: 'payments_routes', method: 'POST', path: '/v1/payments/routes', kind: 'write', description: 'Rutas ejecutables hacia otra empresa.', portal: 'fluuix'),
  EcosystemTool(name: 'payment_prepare', method: 'POST', path: '/v1/payments/prepare', kind: 'write', description: 'Prepara un pago. No firma.', portal: 'fluuix'),
  EcosystemTool(name: 'payment_submit', method: 'POST', path: '/v1/payments/submit', kind: 'write', description: 'Registra un hash ya firmado por la wallet.', portal: 'fluuix'),
  EcosystemTool(name: 'payment_cross_border_prepare', method: 'POST', path: '/v1/payments/cross-border/prepare', kind: 'write', description: 'Prepara un pago transfronterizo.', portal: 'fluuix'),
  EcosystemTool(name: 'tokenization_initiate', method: 'POST', path: '/v1/tokenization/initiate', kind: 'write', description: 'Inicia una tokenización. No despliega.', portal: 'tokenizatunegocio'),
  EcosystemTool(name: 'tokenization_status', method: 'GET', path: '/v1/tokenization/:id', kind: 'read', description: 'Estado de una tokenización del tenant.', portal: 'tokenizatunegocio'),
];

EcosystemTool? ecosystemTool(String name) {
  for (final tool in ecosystemTools) {
    if (tool.name == name) return tool;
  }
  return null;
}

class EcosystemMcp {
  const EcosystemMcp({http.Client? client}) : _client = client;
  final http.Client? _client;

  http.Client get _http => _client ?? http.Client();

  Future<Map<String, dynamic>> handle(
    Map<String, dynamic> message, {
    ZonafrancaSession? session,
  }) async {
    final id = message['id'];
    if (message['jsonrpc'] != '2.0') {
      return _error(id, -32600, 'Invalid request');
    }
    if (id == null) return const {};
    switch (message['method']) {
      case 'initialize':
        return _result(id, {
          'protocolVersion': ecosystemProtocol,
          'capabilities': {
            'tools': {'listChanged': false},
          },
          'serverInfo': {'name': 'ecosystem-mcp', 'version': '1.0.0'},
        });
      case 'ping':
        return _result(id, const {});
      case 'tools/list':
        return _result(id, {
          'tools': [for (final tool in ecosystemTools) tool.toCatalog()],
        });
      case 'tools/call':
        final params = message['params'];
        final map = params is Map
            ? Map<String, dynamic>.from(params)
            : const <String, dynamic>{};
        final called = await _call(map, session);
        return _result(id, called);
      default:
        return _error(id, -32601, 'Unknown method ${message['method']}');
    }
  }

  Future<String> read(
    String name,
    ZonafrancaSession session, {
    Map<String, dynamic> arguments = const {},
  }) async {
    final response = await handle(
      {
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'tools/call',
        'params': {'name': name, 'arguments': arguments},
      },
      session: session,
    );
    final result = response['result'];
    if (result is! Map) {
      throw const ZonafrancaException('El MCP no devolvió una lectura');
    }
    final content = result['content'];
    final text = content is List && content.isNotEmpty && content.first is Map
        ? '${(content.first as Map)['text'] ?? ''}'
        : '';
    if (result['isError'] == true) {
      throw ZonafrancaException(
        text.isEmpty ? 'El MCP no pudo leer el portal' : text,
      );
    }
    return presentMcpText(text);
  }

  Future<Map<String, dynamic>> _call(
    Map<String, dynamic> params,
    ZonafrancaSession? session,
  ) async {
    final name = '${params['name'] ?? ''}';
    final tool = ecosystemTool(name);
    if (tool == null) {
      return _toolError('Unknown tool');
    }
    final args = stripToolSecrets(params['arguments']);
    if (!tool.reads) {
      return _toolError(
        'La herramienta $name escribe. El teléfono no la ejecuta desde el MCP.',
      );
    }
    if (session == null) {
      return _toolError('Conectá la empresa para leer este portal.');
    }
    var path = tool.path;
    final paramsInPath = RegExp(r':([A-Za-z0-9_]+)');
    for (final match in paramsInPath.allMatches(tool.path)) {
      final key = match.group(1)!;
      final value = args[key];
      if (value == null || '$value'.isEmpty) {
        return _toolError('Missing $key');
      }
      path = path.replaceAll(':$key', Uri.encodeComponent('$value'));
      args.remove(key);
    }
    final query = <String, String>{};
    for (final entry in args.entries) {
      if (entry.value != null) query[entry.key] = '${entry.value}';
    }
    final uri = _join(session.apiBase, path, query);
    final response = await _http
        .get(
          uri,
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 20));
    return {
      'content': [
        {'type': 'text', 'text': response.body},
      ],
      'isError': response.statusCode < 200 || response.statusCode >= 300,
    };
  }
}

String presentMcpText(String text) {
  final trimmed = text.trim();
  if (trimmed.length <= 1800) return trimmed;
  return '${trimmed.substring(0, 1800)}…';
}

Map<String, dynamic> stripToolSecrets(dynamic arguments) {
  if (arguments is! Map) return {};
  const blocked = {
    'accesstoken',
    'access_token',
    'authorization',
    'apikey',
    'refresh_token',
    'secret',
    'password',
  };
  final clean = <String, dynamic>{};
  for (final entry in arguments.entries) {
    if (!blocked.contains('${entry.key}'.toLowerCase())) {
      clean['${entry.key}'] = entry.value;
    }
  }
  return clean;
}

Map<String, dynamic> _result(Object? id, Object? result) => {
  'jsonrpc': '2.0',
  'id': id,
  'result': result,
};

Map<String, dynamic> _error(Object? id, int code, String message) => {
  'jsonrpc': '2.0',
  'id': id,
  'error': {'code': code, 'message': message},
};

Map<String, dynamic> _toolError(String text) => {
  'content': [
    {'type': 'text', 'text': text},
  ],
  'isError': true,
};

Uri _join(String apiBase, String path, Map<String, String> query) {
  final base = apiBase.endsWith('/')
      ? apiBase.substring(0, apiBase.length - 1)
      : apiBase;
  final extra = path.startsWith('/') ? path.substring(1) : path;
  final uri = Uri.parse('$base/$extra');
  if (query.isEmpty) return uri;
  return uri.replace(queryParameters: {...uri.queryParameters, ...query});
}

/// Keeps portal rows derived from the live books. Empty sections stay empty.
String portalStatus(EcosystemPortal portal, ZonafrancaSnapshot? books) {
  if (portal.readTool == null) return portal.blurb;
  if (books?.signedIn != true) return 'Misma cuenta del hub. Conectala para leer.';
  final count = books!.rows(portal.section ?? '').length;
  if (count == 0) return 'Conectado. No hay movimientos.';
  final noun = count == 1 ? 'lectura' : 'lecturas';
  return 'Conectado. $count $noun.';
}

List<String> catalogNames(dynamic body) {
  final tools = body is Map ? body['tools'] : null;
  if (tools is! List) return const [];
  return [
    for (final tool in tools)
      if (tool is Map && tool['name'] is String) tool['name'] as String,
  ];
}
