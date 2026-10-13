import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import 'domain/inference_config.dart';

typedef _InitNative = Pointer<Utf8> Function(
  Pointer<Utf8>,
  Pointer<Utf8>,
  Pointer<Utf8>,
  Pointer<Utf8>,
);
typedef _InitDart = Pointer<Utf8> Function(
  Pointer<Utf8>,
  Pointer<Utf8>,
  Pointer<Utf8>,
  Pointer<Utf8>,
);
typedef _TurnNative = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>);
typedef _TurnDart = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>);
typedef _LabTurnNative = Pointer<Utf8> Function(
  Pointer<Utf8>,
  Pointer<Utf8>,
  Pointer<Utf8>,
);
typedef _LabTurnDart = Pointer<Utf8> Function(
  Pointer<Utf8>,
  Pointer<Utf8>,
  Pointer<Utf8>,
);
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
    this.mode,
    this.inference,
    this.supportedModes = const [],
    this.labContextTokens,
  });
  final bool initialized;
  final bool busy;
  final bool requiresReset;
  final String arch;
  final String os;
  final String commit;
  final List<String> tools;
  final String? mode;
  final String? inference;
  final List<String> supportedModes;
  final int? labContextTokens;

  void verifyLabPolicy() {
    if (!supportedModes.contains(labTextMode) ||
        (initialized &&
            (mode != labTextMode ||
                inference != labInferenceKind ||
                tools.isNotEmpty))) {
      throw StateError(
        'El runtime no acredita la política de laboratorio sin herramientas. '
        'No se habilitó ninguna consulta.',
      );
    }
  }

  factory AgentStatus.decode(Map<String, dynamic> value) {
    if (value['abi_version'] != 1 ||
        value['runtime'] != 'openhuman-embed' ||
        value['initialized'] is! bool ||
        value['busy'] is! bool ||
        value['target_arch'] is! String ||
        value['target_os'] is! String ||
        value['upstream_commit'] is! String ||
        value['tools'] is! List ||
        (value['tools'] as List).any((tool) => tool is! String) ||
        (value['supported_modes'] != null &&
            (value['supported_modes'] is! List ||
                (value['supported_modes'] as List).any(
                  (mode) => mode is! String,
                )))) {
      throw const FormatException('Unsupported native OpenHuman ABI.');
    }
    return AgentStatus(
      initialized: value['initialized'] as bool,
      busy: value['busy'] as bool,
      requiresReset: value['requires_reset'] == true,
      arch: value['target_arch'] as String,
      os: value['target_os'] as String,
      commit: value['upstream_commit'] as String,
      tools: List.unmodifiable((value['tools'] as List).cast<String>()),
      mode: value['mode'] is String ? value['mode'] as String : null,
      inference: value['inference'] is String
          ? value['inference'] as String
          : null,
      supportedModes: value['supported_modes'] is List
          ? List.unmodifiable((value['supported_modes'] as List).cast<String>())
          : const [],
      labContextTokens: value['lab_context_tokens'] is int
          ? value['lab_context_tokens'] as int
          : null,
    );
  }
}

class AgentTurn {
  const AgentTurn({
    required this.reply,
    required this.sessionId,
    required this.liveReads,
    this.requestId,
    this.durationMs,
    this.modelRequested,
    this.mode,
  });
  final String reply;
  final String sessionId;
  final List<AgentLiveRead> liveReads;
  final String? requestId;
  final int? durationMs;
  final String? modelRequested;
  final String? mode;
  List<String> get toolCalls =>
      liveReads.map((read) => read.tool).toList(growable: false);

  factory AgentTurn.decode(
    Map<String, dynamic> value, {
    String? expectedRequestId,
    String? expectedModel,
  }) {
    if (value['reply'] is! String || value['session_id'] is! String) {
      throw const FormatException('Invalid native agent response.');
    }
    final reads = value['live_reads'];
    if (expectedRequestId != null &&
        (!isLabRequestId(expectedRequestId) ||
            value['request_id'] != expectedRequestId ||
            value['mode'] != labTextMode ||
            (value['reply'] as String).trim().isEmpty ||
            expectedModel == null ||
            value['model_requested'] != expectedModel ||
            value['duration_ms'] is! int ||
            (value['duration_ms'] as int) < 0 ||
            reads is! List ||
            reads.isNotEmpty)) {
      throw const FormatException(
        'La respuesta no cumple la política o la correlación del laboratorio.',
      );
    }
    return AgentTurn(
      reply: value['reply'] as String,
      sessionId: value['session_id'] as String,
      liveReads: reads is List
          ? reads
                .map((read) => AgentLiveRead.decode(read))
                .toList(growable: false)
          : const [],
      requestId: value['request_id'] is String
          ? value['request_id'] as String
          : null,
      durationMs: value['duration_ms'] is int
          ? value['duration_ms'] as int
          : null,
      modelRequested: value['model_requested'] is String
          ? value['model_requested'] as String
          : null,
      mode: value['mode'] is String ? value['mode'] as String : null,
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
  OpenHumanBridge({bool labTextOnly = awLabTextOnly})
    : labTextOnly = awLabTextOnly || labTextOnly;

  final bool labTextOnly;
  String? _labModel;
  bool get configuredForRequests => !labTextOnly || _labModel != null;

  Future<AgentStatus> status() async {
    final status = AgentStatus.decode(
      await Isolate.run(() => _noArgs('arc_openhuman_status')),
    );
    if (labTextOnly) status.verifyLabPolicy();
    return status;
  }

  Future<void> reset() async {
    await Isolate.run(() => _noArgs('arc_openhuman_reset'));
    _labModel = null;
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
    if (labTextOnly) {
      _labModel = null;
      validateLabInferenceEndpoint(endpoint);
      validateLabModel(model);
    } else {
      validateInferenceEndpoint(endpoint);
    }
    if ([endpoint, apiKey, model, workspace].any((s) => s.contains('\u0000')) ||
        apiKey.isEmpty ||
        apiKey.length > 4096 ||
        model.trim().isEmpty ||
        model.length > 256) {
      throw const FormatException('Invalid inference settings.');
    }
    await Isolate.run(
      () => _initializeSync(endpoint, apiKey, model, workspace, labTextOnly),
    );
    if (labTextOnly) {
      final current = await status();
      if (!current.initialized || current.requiresReset || current.busy) {
        throw StateError('El laboratorio no quedó listo. Reiniciá el runtime.');
      }
      _labModel = model.trim();
    }
  }

  Future<AgentTurn> sendTurn({
    required String prompt,
    String sessionId = '',
    String? requestId,
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
    if (labTextOnly) {
      if (requestId == null ||
          !isLabRequestId(requestId) ||
          _labModel == null) {
        throw StateError(
          'Inicializá el laboratorio y asigná un ID de consulta.',
        );
      }
      final current = await status();
      if (!current.initialized || current.requiresReset || current.busy) {
        throw StateError('El laboratorio no está listo para otra consulta.');
      }
      try {
        return AgentTurn.decode(
          await Isolate.run(() => _labTurnSync(prompt, sessionId, requestId)),
          expectedRequestId: requestId,
          expectedModel: _labModel,
        );
      } catch (_) {
        // An invalid response cannot re-enable the old configuration via status.
        // Reinitialize explicitly after the native runtime has been reset.
        _labModel = null;
        rethrow;
      }
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
  bool labTextOnly,
) {
  final api = _NativeApi();
  return using((arena) {
    final init = api.library.lookupFunction<_InitNative, _InitDart>(
      labTextOnly ? 'arc_openhuman_init_lab' : 'arc_openhuman_init',
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

Map<String, dynamic> _labTurnSync(
  String prompt,
  String sessionId,
  String requestId,
) {
  final api = _NativeApi();
  return using((arena) {
    // Missing lab symbols are fatal. Never fall back to the proposal-only ABI.
    final turn = api.library.lookupFunction<_LabTurnNative, _LabTurnDart>(
      'arc_openhuman_turn_lab',
    );
    return api.takeResponse(
      turn(
        prompt.toNativeUtf8(allocator: arena),
        sessionId.toNativeUtf8(allocator: arena),
        requestId.toNativeUtf8(allocator: arena),
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
