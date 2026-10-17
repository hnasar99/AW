import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/arc.dart';
import '../domain/inference_config.dart';
import '../domain/treasury_policy.dart';
import '../services/wallet_session.dart';

const _languageKey = 'aw_language_v1';

/// Manages app settings including inference config and language preference.
class SettingsNotifier extends ChangeNotifier {
  SettingsNotifier({
    FlutterSecureStorage? storage,
    WalletSession? session,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _session = session;

  final FlutterSecureStorage _storage;
  final WalletSession? _session;

  bool _busy = false;
  bool _storageReady = false;
  bool _touched = false;
  String? _error;
  String _projectId = const String.fromEnvironment('WALLETCONNECT_PROJECT_ID');
  String _endpoint = awLabTextOnly ? '' : 'https://api.openai.com/v1';
  String _model = '';
  String _apiKey = '';
  bool _rememberKey = false;
  Locale? _locale;

  bool get busy => _busy;
  bool get storageReady => _storageReady;
  bool get touched => _touched;
  String? get error => _error;
  String get projectId => _projectId;
  String get endpoint => _endpoint;
  String get model => _model;
  String get apiKey => _apiKey;
  bool get rememberKey => _rememberKey;
  Locale? get locale => _locale;

  set projectId(String value) {
    _projectId = value;
    _touched = true;
    notifyListeners();
  }

  set endpoint(String value) {
    _endpoint = value;
    _touched = true;
    _apiKey = '';
    notifyListeners();
  }

  set model(String value) {
    _model = value;
    _touched = true;
    notifyListeners();
  }

  set apiKey(String value) {
    _apiKey = value;
    _touched = true;
    notifyListeners();
  }

  set rememberKey(bool value) {
    _rememberKey = value;
    _touched = true;
    notifyListeners();
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    notifyListeners();
    try {
      if (locale == null) {
        await _storage.delete(key: _languageKey);
      } else {
        await _storage.write(key: _languageKey, value: locale.languageCode);
      }
    } catch (_) {
      // Ignore storage errors for language preference
    }
  }

  Future<({
    bool requestUncertain,
    TransferReview? lastReview,
    TransactionResult? transaction,
    TreasuryDayLedger ledger,
  })?> load() async {
    try {
      final saved = await _storage.read(key: inferenceSettingsKey);
      final transfer =
          awLabTextOnly ? null : await _storage.read(key: 'aw_transfer_v1');
      final languageCode = await _storage.read(key: _languageKey);

      if (languageCode != null) {
        _locale = Locale(languageCode);
      }

      if (saved != null && !_touched) {
        final value = jsonDecode(saved) as Map<String, dynamic>;
        final savedEndpoint = value['endpoint'] as String? ?? _endpoint;
        final savedModel = value['model'] as String? ?? '';
        if (awLabTextOnly) {
          if (value['mode'] != labTextMode) {
            throw const FormatException('Invalid saved laboratory profile.');
          }
          if (savedEndpoint.isNotEmpty) {
            validateLabInferenceEndpoint(savedEndpoint);
          }
          if (savedModel.isNotEmpty) validateLabModel(savedModel);
        }
        if (!awLabTextOnly) {
          _projectId = value['project_id'] as String? ?? _projectId;
        }
        _endpoint = savedEndpoint;
        _model = savedModel;
        _apiKey = value['key'] as String? ?? '';
        _rememberKey = _apiKey.isNotEmpty;
      }

      bool requestUncertain = false;
      TransferReview? lastReview;
      TransactionResult? transaction;

      if (transfer != null) {
        final value = jsonDecode(transfer) as Map<String, dynamic>;
        requestUncertain = value['unresolved'] == true;
        if (value['review'] is Map<String, dynamic>) {
          lastReview = TransferReview.fromJson(
            value['review'] as Map<String, dynamic>,
          );
        }
        final hash = value['hash'];
        if (hash is String) {
          transaction = TransactionResult(
            validateTransactionHash(hash),
            TransactionState.pending,
          );
        }
      }

      TreasuryDayLedger ledger = TreasuryDayLedger.empty();
      if (!awLabTextOnly) {
        final savedLedger = await _storage.read(key: treasuryLedgerKey);
        if (savedLedger != null) {
          try {
            ledger = TreasuryDayLedger.fromJson(
              jsonDecode(savedLedger) as Map<String, dynamic>,
            ).forToday();
          } catch (_) {
            ledger = TreasuryDayLedger.empty();
          }
        }
      }

      _storageReady = true;
      notifyListeners();

      return (
        requestUncertain: requestUncertain,
        lastReview: lastReview,
        transaction: transaction,
        ledger: ledger,
      );
    } catch (_) {
      _storageReady = false;
      _error = awLabTextOnly
          ? 'Could not restore laboratory settings.'
          : 'Could not restore secure settings. Transfer blocked.';
      notifyListeners();
      return null;
    }
  }

  Future<void> save() async {
    await _storage.write(
      key: inferenceSettingsKey,
      value: jsonEncode({
        if (awLabTextOnly) 'mode': labTextMode,
        if (!awLabTextOnly) 'project_id': _projectId.trim(),
        'endpoint': _endpoint.trim(),
        'model': _model.trim(),
        'key': _rememberKey ? _apiKey : null,
      }),
    );
  }

  Future<void> saveTransfer({
    required bool requestUncertain,
    required String? hash,
    required TransferReview? review,
  }) async {
    if (awLabTextOnly) return;
    try {
      await _storage.write(
        key: 'aw_transfer_v1',
        value: jsonEncode({
          'unresolved': requestUncertain,
          'hash': hash,
          'review': review?.toJson(),
        }),
      );
    } catch (_) {
      _storageReady = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> saveLedger(TreasuryDayLedger ledger) async {
    if (awLabTextOnly) return;
    await _storage.write(
      key: treasuryLedgerKey,
      value: jsonEncode(ledger.forToday().toJson()),
    );
  }

  Future<void> configureWallet() async {
    if (awLabTextOnly) return;
    if (_busy) return;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _session?.configure(_projectId.trim());
      await save();
    } catch (e) {
      _error = _safeError(e);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> forgetKey() async {
    _apiKey = '';
    _rememberKey = false;
    notifyListeners();
    try {
      await save();
      if (!awLabTextOnly) {
        await _storage.delete(key: 'openhuman_inference_api_key');
      }
    } catch (_) {
      _error = 'Could not confirm key deletion.';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _safeError(Object error) {
    var text = error.toString();
    if (_apiKey.isNotEmpty) text = text.replaceAll(_apiKey, '[redacted]');
    text = text.replaceAll(
      RegExp(r'Bearer\s+\S+', caseSensitive: false),
      'Bearer [redacted]',
    );
    return text.length > 600 ? '${text.substring(0, 600)}…' : text;
  }
}
