import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import 'domain/inference_config.dart';

typedef _InitNative =
    Pointer<Utf8> Function(
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
    );
typedef _InitDart =
    Pointer<Utf8> Function(
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
    );
typedef _TurnNative = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>);
typedef _TurnDart = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>);
typedef _NoArgsNative = Pointer<Utf8> Function();
typedef _NoArgsDart = Pointer<Utf8> Function();
typedef _FreeNative = Void Function(Pointer<Utf8>);
typedef _FreeDart = void Function(Pointer<Utf8>);

class AgentStatus {
  const AgentStatus({
    required this.initialized,
    required this.busy,
    required this.requiresReset,
    required this.arch,
    required this.os,
    required this.commit,
    required this.tools,
  });
  final bool initialized;
  final bool busy;
  final bool requiresReset;
  final String arch;
  final String os;
  final String commit;
  final List<String> tools;

  factory AgentStatus.decode(Map<String, dynamic> value) {
    if (value['abi_version'] != 1 ||
        value['runtime'] != 'openhuman-embed' ||
        value['initialized'] is! bool ||
        value['busy'] is! bool ||
        value['target_arch'] is! String ||
        value['target_os'] is! String ||
        value['upstream_commit'] is! String ||
        value['tools'] is! List) {
      throw const FormatException('Unsupported native OpenHuman ABI.');
    }
    return AgentStatus(
      initialized: value['initialized'] as bool,
      busy: value['busy'] as bool,
      requiresReset: value['requires_reset'] == true,
      arch: value['target_arch'] as String,
      os: value['target_os'] as String,
      commit: value['upstream_commit'] as String,
      tools: (value['tools'] as List).cast<String>(),
    );
  }
}

class AgentTurn {
  const AgentTurn({
    required this.reply,
    required this.sessionId,
    required this.liveReads,
  });
  final String reply;
  final String sessionId;
  final List<AgentLiveRead> liveReads;
  List<String> get toolCalls =>
      liveReads.map((read) => read.tool).toList(growable: false);

  factory AgentTurn.decode(Map<String, dynamic> value) {
    if (value['reply'] is! String || value['session_id'] is! String) {
      throw const FormatException('Invalid native agent response.');
    }
    final reads = value['live_reads'];
    return AgentTurn(
      reply: value['reply'] as String,
      sessionId: value['session_id'] as String,
      liveReads: reads is List
          ? reads
                .map((read) => AgentLiveRead.decode(read))
                .toList(growable: false)
          : const [],
    );
  }
}

class AgentLiveRead {
  const AgentLiveRead({required this.tool, required this.result});
  final String tool;
  final Map<String, dynamic> result;

  factory AgentLiveRead.decode(Object? value) {
    if (value is! Map<String, dynamic> ||
        !const ['arc_network_status', 'arc_balance'].contains(value['tool']) ||
        value['result'] is! Map<String, dynamic>) {
      throw const FormatException('Invalid native tool evidence.');
    }
    return AgentLiveRead(
      tool: value['tool'] as String,
      result: Map.unmodifiable(value['result'] as Map<String, dynamic>),
    );
  }
}

class OpenHumanBridge {
  Future<AgentStatus> status() async => AgentStatus.decode(
    await Isolate.run(() => _noArgs('arc_openhuman_status')),
  );

  Future<void> reset() async {
    await Isolate.run(() => _noArgs('arc_openhuman_reset'));
  }

  Future<void> cancel() async {
    await Isolate.run(() => _noArgs('arc_openhuman_cancel'));
  }

  Future<void> initialize({
    required String endpoint,
    required String apiKey,
    required String model,
    required String workspace,
  }) async {
    validateInferenceEndpoint(endpoint);
    if ([endpoint, apiKey, model, workspace].any((s) => s.contains('\u0000')) ||
        apiKey.isEmpty ||
        apiKey.length > 4096 ||
        model.trim().isEmpty ||
        model.length > 256) {
      throw const FormatException('Invalid inference settings.');
    }
    await Isolate.run(
      () => _initializeSync(endpoint, apiKey, model, workspace),
    );
  }

  Future<AgentTurn> sendTurn({
    required String prompt,
    String sessionId = '',
  }) async {
    if (prompt.trim().isEmpty ||
        utf8.encode(prompt).length > 12000 ||
        prompt.contains('\u0000') ||
        sessionId.contains('\u0000') ||
        sessionId.length > 512) {
      throw const FormatException(
        'A prompt must contain 1–12,000 UTF-8 bytes.',
      );
    }
    return AgentTurn.decode(
      await Isolate.run(() => _turnSync(prompt, sessionId)),
    );
  }
}

Map<String, dynamic> _initializeSync(
  String endpoint,
  String key,
  String model,
  String workspace,
) {
  final api = _NativeApi();
  return using((arena) {
    final init = api.library.lookupFunction<_InitNative, _InitDart>(
      'arc_openhuman_init',
    );
    return api.takeResponse(
      init(
        endpoint.toNativeUtf8(allocator: arena),
        key.toNativeUtf8(allocator: arena),
        model.toNativeUtf8(allocator: arena),
        workspace.toNativeUtf8(allocator: arena),
      ),
    );
  });
}

Map<String, dynamic> _turnSync(String prompt, String sessionId) {
  final api = _NativeApi();
  return using((arena) {
    final turn = api.library.lookupFunction<_TurnNative, _TurnDart>(
      'arc_openhuman_turn',
    );
    return api.takeResponse(
      turn(
        prompt.toNativeUtf8(allocator: arena),
        sessionId.toNativeUtf8(allocator: arena),
      ),
    );
  });
}

Map<String, dynamic> _noArgs(String name) {
  final api = _NativeApi();
  return api.takeResponse(
    api.library.lookupFunction<_NoArgsNative, _NoArgsDart>(name)(),
  );
}

class _NativeApi {
  _NativeApi() {
    if (Platform.isIOS) {
      library = DynamicLibrary.process();
    } else {
      library = DynamicLibrary.open(
        Platform.isWindows
            ? 'arc_openhuman_bridge.dll'
            : Platform.isMacOS
            ? 'libarc_openhuman_bridge.dylib'
            : 'libarc_openhuman_bridge.so',
      );
    }
    free = library.lookupFunction<_FreeNative, _FreeDart>(
      'arc_openhuman_string_free',
    );
  }

  late final DynamicLibrary library;
  late final _FreeDart free;

  Map<String, dynamic> takeResponse(Pointer<Utf8> pointer) {
    if (pointer == nullptr) {
      throw StateError('The native bridge returned a null response.');
    }
    try {
      final raw = pointer.toDartString();
      if (raw.length > 2 * 1024 * 1024) {
        throw const FormatException('Native response is too large.');
      }
      final value = jsonDecode(raw);
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Invalid native response.');
      }
      if (value['ok'] != true) {
        throw StateError(
          value['error'] is String
              ? value['error'] as String
              : 'Native request failed.',
        );
      }
      return value;
    } finally {
      // Rust owns returned strings, including malformed/error responses.
      free(pointer);
    }
  }
}
