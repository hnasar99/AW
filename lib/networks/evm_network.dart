import 'dart:convert';

/// User-selected EVM read profile. Configuration never grants signing rights.
class EvmNetwork {
  EvmNetwork({
    required String name,
    required this.chainId,
    required String rpcUrl,
    required String symbol,
    this.decimals = 18,
    String explorerUrl = '',
    this.testnet = true,
  }) : name = name.trim(),
       rpcUrl = checkedHttpsUrl(rpcUrl),
       symbol = symbol.trim(),
       explorerUrl = explorerUrl.trim().isEmpty
           ? ''
           : checkedHttpsUrl(explorerUrl, explorer: true) {
    if (this.name.isEmpty || this.name.length > 64 ||
        RegExp(r'[\x00-\x1f\x7f\u202a-\u202e\u2066-\u2069]').hasMatch(this.name)) {
      throw const FormatException('Nombre requerido: hasta 64 caracteres sin controles.');
    }
    if (chainId <= 0 || chainId > 9007199254740991) {
      throw const FormatException('Chain ID fuera del rango 1 a 2^53-1.');
    }
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,11}$').hasMatch(this.symbol) ||
        RegExp(r'\s').hasMatch(this.symbol)) {
      throw const FormatException('Símbolo requerido: hasta 12 caracteres alfanuméricos.');
    }
    if (decimals < 0 || decimals > 36) {
      throw const FormatException('Los decimales deben estar entre 0 y 36.');
    }
    final knownSymbol = <int, String>{5042002: 'USDC', 10143: 'MON'}[chainId];
    if (knownSymbol != null &&
        (this.symbol != knownSymbol || decimals != 18 || !testnet)) {
      throw const FormatException('Los datos no coinciden con la testnet conocida.');
    }
  }

  final String name;
  final int chainId;
  final String rpcUrl;
  final String symbol;
  final int decimals;
  final String explorerUrl;
  final bool testnet;

  String get caip2 => 'eip155:$chainId';
  String get rpcOrigin => Uri.parse(rpcUrl).origin;
  bool get viaFluuix {
    final uri = Uri.parse(rpcUrl);
    final expectedPath = <int, String>{
      5042002: '/v1/rpc/arc-testnet',
      10143: '/v1/rpc/monad-testnet',
    }[chainId];
    return uri.origin == 'https://fluuix-chain-access-testnet.up.railway.app' &&
        uri.path == expectedPath && !uri.hasQuery;
  }

  Map<String, Object> toJson() => {
    'name': name,
    'chain_id': chainId,
    'rpc_url': rpcUrl,
    'symbol': symbol,
    'decimals': decimals,
    'explorer_url': explorerUrl,
    'testnet': testnet,
  };

  factory EvmNetwork.fromJson(Object? raw) {
    if (raw is! Map<String, dynamic> || raw.length != 7 ||
        raw['name'] is! String || raw['chain_id'] is! int ||
        raw['rpc_url'] is! String || raw['symbol'] is! String ||
        raw['decimals'] is! int || raw['explorer_url'] is! String ||
        raw['testnet'] is! bool) {
      throw const FormatException('Perfil de red inválido.');
    }
    return EvmNetwork(
      name: raw['name'] as String,
      chainId: raw['chain_id'] as int,
      rpcUrl: raw['rpc_url'] as String,
      symbol: raw['symbol'] as String,
      decimals: raw['decimals'] as int,
      explorerUrl: raw['explorer_url'] as String,
      testnet: raw['testnet'] as bool,
    );
  }

  static List<EvmNetwork> defaults() => [
    EvmNetwork(
      name: 'Arc Testnet', chainId: 5042002, symbol: 'USDC',
      rpcUrl: 'https://fluuix-chain-access-testnet.up.railway.app/v1/rpc/arc-testnet',
      explorerUrl: 'https://explorer.testnet.arc.io',
    ),
    EvmNetwork(
      name: 'Monad Testnet', chainId: 10143, symbol: 'MON',
      rpcUrl: 'https://fluuix-chain-access-testnet.up.railway.app/v1/rpc/monad-testnet',
    ),
  ];
}

/// RPC path/query may contain a provider token; do not log or show raw URLs.
/// User-defined endpoints run on the device, not as an arbitrary Fluuix proxy.
String checkedHttpsUrl(String input, {bool explorer = false}) {
  final value = input.trim();
  if (value.isEmpty || value.length > 2048 ||
      RegExp(r'[\s\x00-\x1f\x7f\\]').hasMatch(value)) {
    throw const FormatException('URL HTTPS inválida.');
  }
  final uri = Uri.tryParse(value);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty ||
      uri.userInfo.isNotEmpty || uri.hasFragment || uri.port <= 0 ||
      uri.port > 65535 || uri.host.contains('%') ||
      (explorer && uri.hasQuery)) {
    throw const FormatException('Usá HTTPS sin usuario, contraseña ni fragmento.');
  }
  return uri.toString();
}

int parseChainId(String input) {
  final text = input.trim();
  if (RegExp(r'\s').hasMatch(text) ||
      (!RegExp(r'^[1-9][0-9]{0,15}$').hasMatch(text) &&
       !RegExp(r'^0x[0-9a-fA-F]{1,14}$').hasMatch(text))) {
    throw const FormatException('Chain ID decimal o hexadecimal 0x requerido.');
  }
  final value = BigInt.parse(
    text.startsWith('0x') ? text.substring(2) : text,
    radix: text.startsWith('0x') ? 16 : 10,
  );
  if (value <= BigInt.zero || value > BigInt.from(9007199254740991)) {
    throw const FormatException('Chain ID fuera de rango.');
  }
  return value.toInt();
}

class NetworkBook {
  NetworkBook(List<EvmNetwork> profiles, this.selectedId)
      : profiles = List.unmodifiable(profiles) {
    if (profiles.isEmpty || profiles.length > 16 ||
        profiles.map((p) => p.chainId).toSet().length != profiles.length ||
        !profiles.any((p) => p.chainId == selectedId)) {
      throw const FormatException('Registro de redes inconsistente.');
    }
  }
  final List<EvmNetwork> profiles;
  final int selectedId;
  EvmNetwork get selected => profiles.firstWhere((p) => p.chainId == selectedId);

  String encode() => jsonEncode({
    'version': 1, 'selected_id': selectedId,
    'profiles': profiles.map((p) => p.toJson()).toList(),
  });

  factory NetworkBook.initial() => NetworkBook(EvmNetwork.defaults(), 5042002);
  factory NetworkBook.decode(String? raw) {
    if (raw == null) return NetworkBook.initial();
    if (utf8.encode(raw).length > 65536) {
      throw const FormatException('Registro de redes excesivo.');
    }
    final value = jsonDecode(raw);
    if (value is! Map<String, dynamic> || value.length != 3 ||
        value['version'] != 1 || value['selected_id'] is! int ||
        value['profiles'] is! List) {
      throw const FormatException('No se pudo restaurar el registro de redes.');
    }
    return NetworkBook(
      (value['profiles'] as List).map(EvmNetwork.fromJson).toList(),
      value['selected_id'] as int,
    );
  }

  NetworkBook upsert(EvmNetwork profile, {required bool replaceExisting}) {
    final exists = profiles.any((p) => p.chainId == profile.chainId);
    if (exists && !replaceExisting) {
      throw const FormatException('La chain ya existe: editá su RPC.');
    }
    if (!exists && replaceExisting) {
      throw const FormatException('El perfil a editar ya no existe.');
    }
    return NetworkBook([
      for (final p in profiles) if (p.chainId != profile.chainId) p,
      profile,
    ], profile.chainId);
  }

  NetworkBook remove(int chainId) {
    if (chainId == selectedId) {
      throw const FormatException('Seleccioná otra red antes de eliminar esta.');
    }
    return NetworkBook(
      profiles.where((p) => p.chainId != chainId).toList(), selectedId,
    );
  }
}
