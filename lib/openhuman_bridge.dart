import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:io';

import 'package:ffi/ffi.dart';

// Native ABI. The Rust crate exports these symbols in libarc_openhuman_bridge.
typedef _InitNative = Pointer<Utf8> Function(
  Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>);
typedef _InitDart = Pointer<Utf8> Function(
  Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>);
typedef _TurnNative = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>);
typedef _TurnDart = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>);
typedef _FreeNative = Void Function(Pointer<Utf8>);
typedef _FreeDart = void Function(Pointer<Utf8>);

class OpenHumanBridge {
  Future<Map<String, dynamic>> initialize({
    required String endpoint,
    required String apiKey,
    required String model,
    required String workspace,
  }) => Isolate.run(() => _initializeSync(endpoint, apiKey, model, workspace));

  Future<Map<String, dynamic>> sendTurn({
    required String prompt,
    String sessionId = '',
  }) => Isolate.run(() => _turnSync(prompt, sessionId));
}

Map<String, dynamic> _initializeSync(String endpoint, String key, String model, String workspace) {
  final api = _NativeApi();
  final args = [endpoint, key, model, workspace].map((s) => s.toNativeUtf8()).toList();
  try {
    final pointer = api.init(args[0], args[1], args[2], args[3]);
    if (pointer == nullptr) throw StateError('OpenHuman native bridge returned a null response.');
    final raw = pointer.toDartString();
    api.free(pointer);
    return _decode(raw);
  } finally {
    for (final arg in args) { malloc.free(arg); }
  }
}

Map<String, dynamic> _turnSync(String prompt, String sessionId) {
  final api = _NativeApi();
  final p = prompt.toNativeUtf8();
  final s = sessionId.toNativeUtf8();
  try {
    final pointer = api.turn(p, s);
    if (pointer == nullptr) throw StateError('OpenHuman native bridge returned a null response.');
    final raw = pointer.toDartString();
    api.free(pointer);
    return _decode(raw);
  } finally {
    malloc.free(p);
    malloc.free(s);
  }
}

Map<String, dynamic> _decode(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) throw const FormatException('Invalid OpenHuman response.');
  if (decoded['ok'] != true) throw Exception(decoded['error'] ?? 'OpenHuman request failed.');
  return decoded;
}

class _NativeApi {
  late final DynamicLibrary _library;
  late final _InitDart init;
  late final _TurnDart turn;
  late final _FreeDart free;

  _NativeApi() {
    if (Platform.isAndroid) {
      _library = DynamicLibrary.open('libarc_openhuman_bridge.so');
    } else if (Platform.isIOS) {
      // The static library must be linked into the iOS Runner target.
      _library = DynamicLibrary.process();
    } else if (Platform.isMacOS) {
      _library = DynamicLibrary.open('libarc_openhuman_bridge.dylib');
    } else if (Platform.isWindows) {
      _library = DynamicLibrary.open('arc_openhuman_bridge.dll');
    } else {
      _library = DynamicLibrary.open('libarc_openhuman_bridge.so');
    }
    init = _library.lookupFunction<_InitNative, _InitDart>('arc_openhuman_init');
    turn = _library.lookupFunction<_TurnNative, _TurnDart>('arc_openhuman_turn');
    free = _library.lookupFunction<_FreeNative, _FreeDart>('arc_openhuman_string_free');
  }
}
