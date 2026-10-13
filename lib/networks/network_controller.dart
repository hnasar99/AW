import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'evm_network.dart';
import 'evm_read_client.dart';

abstract interface class NetworkPersistence {
  Future<String?> read();
  Future<void> write(String value);
}
class SecureNetworkPersistence implements NetworkPersistence {
  const SecureNetworkPersistence();
  static const key = 'fluuix_evm_network_profiles_v1';
  static const storage = FlutterSecureStorage();
  @override
  Future<String?> read() => storage.read(key: key);
  @override
  Future<void> write(String value) => storage.write(key: key, value: value);
}

/// A verified profile is committed to storage before becoming the active one.
class NetworkController extends ChangeNotifier {
  NetworkController({NetworkPersistence? persistence, EvmReadClient Function()? clientFactory})
      : _persistence = persistence ?? const SecureNetworkPersistence(),
        _clientFactory = clientFactory ?? (() => EvmReadClient());
  final NetworkPersistence _persistence;
  final EvmReadClient Function() _clientFactory;
  NetworkBook _book = NetworkBook.initial();
  NetworkBook get book => _book;
  EvmNetwork get selected => _book.selected;
  NetworkSnapshot? snapshot;
  bool busy = false;
  bool loaded = false;
  bool storageFault = false;
  String? error;
  bool _disposed = false;
  int _generation = 0;
  EvmReadClient? _running;
  void _notify() { if (!_disposed) notifyListeners(); }

  Future<void> load() async {
    if (busy || _disposed) return;
    busy = true; error = null; snapshot = null; _notify();
    try {
      final restored = NetworkBook.decode(await _persistence.read());
      if (!_disposed) { _book = restored; loaded = true; storageFault = false; }
    } catch (_) {
      if (!_disposed) {
        storageFault = true; loaded = false;
        error = 'No se pudo restaurar el registro de redes. No se reemplazó ni se conectó a otra red. Recuperá el registro o restablecé sólo esta configuración.';
      }
    } finally { busy = false; _notify(); }
  }

  Future<bool> saveAndConnect(EvmNetwork profile, {required bool replaceExisting}) async {
    if (busy || !loaded || storageFault || _disposed) return false;
    try {
      final next = _book.upsert(profile, replaceExisting: replaceExisting);
      return _read(profile, persist: next);
    } on FormatException catch (e) { error = e.message; _notify(); return false; }
  }

  Future<bool> select(int chainId) async {
    if (busy || !loaded || storageFault || _disposed) return false;
    final next = NetworkBook(_book.profiles, chainId);
    return _read(next.selected, persist: next);
  }

  Future<bool> refresh({String? address}) async {
    if (busy || !loaded || storageFault || _disposed) return false;
    return _read(selected, address: address);
  }

  Future<bool> _read(EvmNetwork profile, {String? address, NetworkBook? persist}) async {
    final generation = ++_generation;
    busy = true; error = null; snapshot = null; _notify();
    final client = _clientFactory();
    _running = client;
    try {
      final result = await client.inspect(profile, address: address);
      if (_disposed || generation != _generation) return false;
      if (persist != null) {
        try { await _persistence.write(persist.encode()); }
        catch (_) {
          storageFault = true;
          throw const NetworkReadFailure('storage', 'La red respondió, pero no se pudo guardar su configuración segura. No se activó.');
        }
        if (_disposed || generation != _generation) return false;
        _book = persist;
      }
      snapshot = result;
      return true;
    } on NetworkReadFailure catch (e) {
      if (!_disposed && generation == _generation) error = e.message;
      return false;
    } catch (_) {
      if (!_disposed && generation == _generation) error = 'No se pudo validar la consulta. Comprobá la dirección y la configuración.';
      return false;
    } finally {
      client.close();
      if (identical(_running, client)) _running = null;
      if (!_disposed && generation == _generation) { busy = false; _notify(); }
    }
  }

  Future<void> remove(int chainId) async {
    if (busy || !loaded || storageFault || _disposed) return;
    busy = true; error = null; _notify();
    try {
      final next = _book.remove(chainId);
      await _persistence.write(next.encode());
      if (!_disposed) _book = next;
    } on FormatException catch (e) { error = e.message; }
    catch (_) { storageFault = true; error = 'No se pudo guardar el registro. Se conservó la configuración anterior.'; }
    finally { busy = false; _notify(); }
  }

  /// Call only after an explicit reset confirmation. Other secure keys are untouched.
  Future<void> resetProfiles() async {
    if (busy || _disposed) return;
    busy = true; snapshot = null; error = null; _notify();
    try {
      final initial = NetworkBook.initial();
      await _persistence.write(initial.encode());
      if (!_disposed) { _book = initial; loaded = true; storageFault = false; }
    } catch (_) { storageFault = true; error = 'No se pudo restablecer la configuración segura.'; }
    finally { busy = false; _notify(); }
  }

  @override
  void dispose() {
    _disposed = true; _generation++; _running?.close(); super.dispose();
  }
}
