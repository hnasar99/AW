import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'domain/arc.dart';
import 'domain/inference_config.dart';
import 'domain/treasury_policy.dart';
import 'l10n/app_localizations.dart';
import 'openhuman_bridge.dart';
import 'router.dart';
import 'services/arc_rpc.dart';
import 'services/wallet_session.dart';
import 'ui/splash_view.dart';
import 'ui/theme.dart';

export 'domain/arc.dart' show formatUnits, parseUsdc, validateAddress, validateTransactionHash, TransactionState, TransferProposal, ArcNetwork;
export 'domain/treasury_policy.dart' show TreasuryPolicy, treasuryLedgerKey;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ArcWalletApp(showSplash: true));
}

class ArcWalletApp extends StatefulWidget {
  const ArcWalletApp({
    super.key,
    this.autoInitialize = true,
    this.agent,
    this.showSplash = false,
    this.overrideLocale,
    this.initialLocation,
  });
  final bool autoInitialize;
  final OpenHumanBridge? agent;
  final bool showSplash;
  final Locale? overrideLocale;
  final String? initialLocation;

  @override
  State<ArcWalletApp> createState() => _ArcWalletAppState();
}

class _ArcWalletAppState extends State<ArcWalletApp> {
  Locale? _locale;
  late final WalletAppState _appState;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _appState = WalletAppState(
      autoInitialize: widget.autoInitialize,
      agent: widget.agent,
      onLocaleChanged: _setLocale,
    );
    _router = createRouter(
      appState: _appState,
      initialLocation: widget.initialLocation ?? (awLabTextOnly ? '/agente' : '/inicio'),
    );
  }

  @override
  void dispose() {
    _appState.dispose();
    _router.dispose();
    super.dispose();
  }

  void _setLocale(Locale? locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp.router(
      title: awLabTextOnly ? 'AW · Laboratorio de texto' : 'FluuiX',
      debugShowCheckedModeBanner: false,
      theme: fluuixTheme(),
      locale: widget.overrideLocale ?? _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (_locale != null) return _locale;
        for (final supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return const Locale('es');
      },
      routerConfig: _router,
    );

    if (widget.showSplash) {
      return FluuiXLaunch(child: app);
    }
    return app;
  }
}

class WalletAppState extends AppState with WidgetsBindingObserver {
  WalletAppState({
    required this.autoInitialize,
    this.agent,
    this.onLocaleChanged,
  }) {
    WidgetsBinding.instance.addObserver(this);
    _walletSession?.addListener(_walletChanged);
    if (autoInitialize) {
      if (!awLabTextOnly) unawaited(checkNetwork());
      unawaited(loadSettings());
    }
  }

  final bool autoInitialize;
  final OpenHumanBridge? agent;
  final void Function(Locale?)? onLocaleChanged;

  final _arcRpc = awLabTextOnly ? null : ArcRpc();
  final _walletSession = awLabTextOnly ? null : WalletSession();
  ArcRpc get _rpc =>
      _arcRpc ?? (throw StateError('Arc está deshabilitado en laboratorio.'));
  WalletSession get _wallet =>
      _walletSession ??
      (throw StateError('La wallet está deshabilitada en laboratorio.'));
  late final _agent = agent ?? OpenHumanBridge();
  final _storage = const FlutterSecureStorage();

  final _projectId = TextEditingController(
    text: awLabTextOnly
        ? ''
        : const String.fromEnvironment('WALLETCONNECT_PROJECT_ID'),
  );
  final _endpoint = TextEditingController(
    text: awLabTextOnly ? '' : 'https://api.openai.com/v1',
  );
  final _model = TextEditingController();
  final _key = TextEditingController();
  final _prompt = TextEditingController(
    text: awLabTextOnly
        ? 'Explicá brevemente qué es una inferencia de texto.'
        : 'Usá arc_network_status y explicame el estado real de Arc Testnet.',
  );
  final _recipient = TextEditingController();
  final _amount = TextEditingController(text: '1');
  final _recoverHash = TextEditingController();

  TreasuryDayLedger _ledger = TreasuryDayLedger.empty();
  bool _busy = false;
  bool _settingsBusy = false;
  bool _agentBusy = false;
  bool _agentReady = false;
  bool _rememberKey = false;
  bool _settingsTouched = false;
  bool _storageReady = false;
  bool _networkVerified = false;
  bool _requestUncertain = false;
  bool _polling = false;
  // ignore: unused_field - status strings for future diagnostics/logging
  String _networkStatus = 'connectionPending';
  // ignore: unused_field - status strings for future diagnostics/logging
  String _agentStatus = 'agentVerifyStatus';
  String? _error;
  String? _agentError;
  String? _settingsError;
  String? _agentSession;
  String? _agentReply;
  String? _lastWalletAddress;
  Map<String, Object?>? _labRequestAudit;
  List<String> _toolCalls = const [];
  List<AgentLiveRead> _liveReads = const [];
  AgentStatus? _nativeStatus;
  BigInt? _balance;
  TransactionResult? _transaction;
  TransferReview? _lastReview;
  Locale? _selectedLocale;
  BuildContext? _dialogContext;

  @override
  bool get networkVerified => _networkVerified;
  @override
  bool get walletConnected => !awLabTextOnly && _wallet.connected;
  @override
  String? get walletAddress => awLabTextOnly ? null : _wallet.address;
  @override
  int? get chainId => awLabTextOnly ? null : _wallet.chainId;
  @override
  bool get supportsArc => !awLabTextOnly && _wallet.supportsArc;
  @override
  BigInt? get balance => _balance;
  @override
  bool get busy => _busy || _settingsBusy;
  @override
  bool get agentReady => _agentReady;
  @override
  bool get agentBusy => _agentBusy;
  @override
  bool get transferBlocked =>
      awLabTextOnly ||
      !_storageReady ||
      _requestUncertain ||
      _wallet.requestPending ||
      (_transaction != null &&
          _transaction!.state != TransactionState.confirmed &&
          _transaction!.state != TransactionState.reverted);
  @override
  bool get requestUncertain => _requestUncertain;
  @override
  dynamic get ledger => _ledger;
  @override
  dynamic get transaction => _transaction;
  @override
  dynamic get lastReview => _lastReview;
  @override
  dynamic get nativeStatus => _nativeStatus;
  @override
  String? get agentReply => _agentReply;
  @override
  List<String> get toolCalls => _toolCalls;
  @override
  List<dynamic> get liveReads => _liveReads;
  @override
  dynamic get proposal {
    if (awLabTextOnly) return null;
    try {
      return _agentReply == null ? null : TransferProposal.parse(_agentReply!);
    } catch (_) {
      return null;
    }
  }
  @override
  String? get error => _error;
  @override
  String? get agentError => _agentError;
  @override
  String? get settingsError => _settingsError;
  @override
  bool get configured => !awLabTextOnly && _wallet.configured;
  @override
  bool get storageReady => _storageReady;
  @override
  bool get requestPending => !awLabTextOnly && _wallet.requestPending;
  @override
  Locale? get selectedLocale => _selectedLocale;

  @override
  TextEditingController get recipientController => _recipient;
  @override
  TextEditingController get amountController => _amount;
  @override
  TextEditingController get promptController => _prompt;
  @override
  TextEditingController get projectIdController => _projectId;
  @override
  TextEditingController get endpointController => _endpoint;
  @override
  TextEditingController get modelController => _model;
  @override
  TextEditingController get keyController => _key;
  @override
  TextEditingController get recoverHashController => _recoverHash;
  @override
  bool get rememberKey => _rememberKey;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _walletSession?.removeListener(_walletChanged);
    _walletSession?.dispose();
    _arcRpc?.close();
    for (final controller in [
      _projectId,
      _endpoint,
      _model,
      _key,
      _prompt,
      _recipient,
      _amount,
      _recoverHash,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (awLabTextOnly) return;
    if (state == AppLifecycleState.resumed) {
      _wallet.reconcile();
      unawaited(refreshBalance());
      if (_transaction?.state == TransactionState.pending ||
          _transaction?.state == TransactionState.unknown) {
        unawaited(_checkReceipt());
      }
    }
  }

  String _safeError(Object error) {
    var text = error.toString();
    if (_key.text.isNotEmpty) text = text.replaceAll(_key.text, '[redacted]');
    text = text.replaceAll(
      RegExp(r'Bearer\s+\S+', caseSensitive: false),
      'Bearer [redacted]',
    );
    return text.length > 600 ? '${text.substring(0, 600)}…' : text;
  }

  @override
  Future<void> loadSettings() async {
    try {
      final saved = await _storage.read(key: inferenceSettingsKey);
      final transfer = awLabTextOnly
          ? null
          : await _storage.read(key: 'aw_transfer_v1');
      final languageCode = await _storage.read(key: 'aw_language_v1');
      if (languageCode != null) {
        _selectedLocale = Locale(languageCode);
        onLocaleChanged?.call(_selectedLocale);
      }
      if (saved != null && !_settingsTouched) {
        final value = jsonDecode(saved) as Map<String, dynamic>;
        final endpoint = value['endpoint'] as String? ?? _endpoint.text;
        final model = value['model'] as String? ?? '';
        if (awLabTextOnly) {
          if (value['mode'] != labTextMode) {
            throw const FormatException('Invalid saved laboratory profile.');
          }
          if (endpoint.isNotEmpty) validateLabInferenceEndpoint(endpoint);
          if (model.isNotEmpty) validateLabModel(model);
        }
        if (!awLabTextOnly) {
          _projectId.text = value['project_id'] as String? ?? _projectId.text;
        }
        _endpoint.text = endpoint;
        _model.text = model;
        _key.text = value['key'] as String? ?? '';
        _rememberKey = _key.text.isNotEmpty;
      }
      if (transfer != null) {
        final value = jsonDecode(transfer) as Map<String, dynamic>;
        _requestUncertain = value['unresolved'] == true;
        if (value['review'] is Map<String, dynamic>) {
          _lastReview = TransferReview.fromJson(
            value['review'] as Map<String, dynamic>,
          );
        }
        final hash = value['hash'];
        if (hash is String) {
          _transaction = TransactionResult(
            validateTransactionHash(hash),
            TransactionState.pending,
          );
        }
      }
      if (!awLabTextOnly) {
        final savedLedger = await _storage.read(key: treasuryLedgerKey);
        if (savedLedger != null) {
          try {
            _ledger = TreasuryDayLedger.fromJson(
              jsonDecode(savedLedger) as Map<String, dynamic>,
            ).forToday();
          } catch (_) {
            _ledger = TreasuryDayLedger.empty();
          }
        }
      }
      _storageReady = true;
      notifyListeners();
      if (!awLabTextOnly && _projectId.text.trim().isNotEmpty) {
        await configureWallet(persist: false);
      }
    } catch (_) {
      _storageReady = false;
      _settingsError = awLabTextOnly ? 'settingsErrorLab' : 'settingsErrorArc';
      notifyListeners();
    }
  }

  Future<void> _saveSettings() => _storage.write(
    key: inferenceSettingsKey,
    value: jsonEncode({
      if (awLabTextOnly) 'mode': labTextMode,
      if (!awLabTextOnly) 'project_id': _projectId.text.trim(),
      'endpoint': _endpoint.text.trim(),
      'model': _model.text.trim(),
      'key': _rememberKey ? _key.text : null,
    }),
  );

  Future<void> _saveTransfer() async {
    if (awLabTextOnly) return;
    try {
      await _storage.write(
        key: 'aw_transfer_v1',
        value: jsonEncode({
          'unresolved': _requestUncertain,
          'hash': _transaction?.hash,
          'review': _lastReview?.toJson(),
        }),
      );
    } catch (_) {
      _storageReady = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _saveLedger() async {
    if (awLabTextOnly) return;
    final current = _ledger.forToday();
    _ledger = current;
    await _storage.write(
      key: treasuryLedgerKey,
      value: jsonEncode(current.toJson()),
    );
  }

  @override
  Future<void> saveLocale(Locale? locale) async {
    _selectedLocale = locale;
    onLocaleChanged?.call(locale);
    try {
      if (locale == null) {
        await _storage.delete(key: 'aw_language_v1');
      } else {
        await _storage.write(key: 'aw_language_v1', value: locale.languageCode);
      }
    } catch (_) {}
    notifyListeners();
  }

  @override
  Future<void> configureWallet({bool persist = true}) async {
    if (awLabTextOnly) return;
    if (_settingsBusy || _busy) return;
    _settingsBusy = true;
    _settingsError = null;
    notifyListeners();
    try {
      await _wallet.configure(_projectId.text.trim());
      if (persist) await _saveSettings();
    } catch (e) {
      _settingsError = _safeError(e);
    } finally {
      _settingsBusy = false;
      notifyListeners();
    }
  }

  void _walletChanged() {
    if (awLabTextOnly) return;
    final address = _wallet.address;
    if (_lastWalletAddress != address) {
      _lastWalletAddress = address;
      _balance = null;
      unawaited(refreshBalance());
    }
    final hash = _wallet.lastHash;
    if (hash != null && hash != _transaction?.hash) {
      _transaction = TransactionResult(hash, TransactionState.submitted);
      _requestUncertain = false;
      unawaited(_saveTransfer().catchError((Object _) {}));
      unawaited(_pollReceipt());
    }
    notifyListeners();
  }

  @override
  Future<void> checkNetwork() async {
    if (awLabTextOnly) return;
    try {
      await _rpc.verifyNetwork();
      _networkVerified = true;
      _networkStatus = 'rpcVerified';
      notifyListeners();
      await refreshBalance();
    } catch (e) {
      _networkVerified = false;
      _networkStatus = _safeError(e);
      notifyListeners();
    }
  }

  @override
  Future<void> refreshBalance() async {
    if (awLabTextOnly) return;
    final address = _wallet.address;
    if (address == null) return;
    try {
      await _rpc.verifyNetwork();
      final balance = await _rpc.nativeBalance(address);
      if (address == _wallet.address) {
        _balance = balance;
        _networkVerified = true;
        notifyListeners();
      }
    } catch (e) {
      if (address == _wallet.address) {
        _error = _safeError(e);
        notifyListeners();
      }
    }
  }

  @override
  Future<void> connect() async {
    if (awLabTextOnly) return;
    if (!_wallet.configured) {
      return;
    }
    if (_busy) return;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _wallet.connect(_showPairing);
      if (!_wallet.supportsArc) {
        _error = 'sessionNotAuthorizedArc';
      }
      await refreshBalance();
    } catch (e) {
      _error = _safeError(e);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _showPairing(Uri uri) async {
    if (awLabTextOnly || _dialogContext == null) return;
    final context = _dialogContext!;
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.connectYourWallet),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.scanFromOtherScreen),
              const SizedBox(height: 12),
              ColoredBox(
                color: Colors.white,
                child: QrImageView(data: '$uri', size: 210),
              ),
              const SizedBox(height: 10),
              Text(l10n.walletMustHaveArc),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: Text(l10n.goBack),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: '$uri'));
              if (dialog.mounted) {
                ScaffoldMessenger.of(dialog).showSnackBar(
                  SnackBar(content: Text(l10n.uriCopied)),
                );
              }
            },
            child: Text(l10n.copyUri),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final opened = await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
                if (!opened && dialog.mounted) {
                  ScaffoldMessenger.of(dialog).showSnackBar(
                    SnackBar(content: Text(l10n.useCopyUriOrQr)),
                  );
                }
                if (opened && dialog.mounted) Navigator.pop(dialog);
              } catch (_) {
                if (dialog.mounted) {
                  ScaffoldMessenger.of(dialog).showSnackBar(
                    SnackBar(content: Text(l10n.noWalletForLink)),
                  );
                }
              }
            },
            child: Text(l10n.openWallet),
          ),
        ],
      ),
    );
  }

  @override
  Future<void> addArc() async {
    if (awLabTextOnly) return;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _wallet.requestArcNetwork();
      _error = 'networkRequestedReconnect';
    } catch (e) {
      _error = _safeError(e);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  Future<void> disconnect() async {
    if (awLabTextOnly) return;
    try {
      await _wallet.disconnect();
    } catch (e) {
      _error = _safeError(e);
      notifyListeners();
    }
  }

  @override
  Future<void> reviewAndSend() async {
    if (awLabTextOnly || _busy || transferBlocked) return;
    _busy = true;
    _error = null;
    notifyListeners();
    var requested = false;
    try {
      final units = parseUsdc(_amount.text);
      TreasuryPolicy.assertOrderAllowed(
        units: units,
        spentToday: _ledger.forToday().spent,
      );
      final sender = _wallet.address;
      final topic = _wallet.topic;
      if (sender == null || topic == null || !_wallet.supportsArc) {
        throw StateError('Conectá una wallet que autorice Arc Testnet.');
      }
      final review = await _rpc.prepare(
        sender: sender,
        recipient: validateAddress(_recipient.text, recipient: true),
        units: parseUsdc(_amount.text),
        topic: topic,
        sessionRevision: _wallet.revision,
      );
      _wallet.verifyReview(review);
      await _rpc.verifyNetwork();
      await _rpc.verifyFunds(review);
      _wallet.verifyReview(review);
      _lastReview = review;
      _transaction = null;
      _requestUncertain = true;
      await _saveTransfer();
      _wallet.verifyReview(review);
      requested = true;
      final hash = await _wallet.send(review);
      _transaction = TransactionResult(hash, TransactionState.submitted);
      _requestUncertain = false;
      notifyListeners();
      await _saveTransfer();
      await _pollReceipt();
    } catch (e) {
      if (!requested) _requestUncertain = false;
      _error = requested
          ? '${_safeError(e)}\nRevisá el estado en tu wallet. Una demora o error de comunicación no demuestra que no se haya enviado.'
          : _safeError(e);
      if (!requested) await _saveTransfer().catchError((Object _) {});
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _pollReceipt() async {
    if (awLabTextOnly || _polling || _transaction == null) return;
    _polling = true;
    final hash = _transaction!.hash;
    try {
      final deadline = DateTime.now().add(const Duration(seconds: 60));
      while (_transaction?.hash == hash && DateTime.now().isBefore(deadline)) {
        await _checkReceipt();
        final state = _transaction?.state;
        if (state == TransactionState.confirmed ||
            state == TransactionState.reverted ||
            state == TransactionState.unknown) {
          break;
        }
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    } finally {
      _polling = false;
    }
  }

  Future<void> _checkReceipt() async {
    if (awLabTextOnly) return;
    final current = _transaction;
    if (current == null) return;
    try {
      await _rpc.verifyNetwork();
      final result = await _rpc.receipt(current.hash, review: _lastReview);
      if (_transaction?.hash != current.hash) return;
      _transaction = result;
      if (_lastReview != null &&
          (result.state == TransactionState.confirmed ||
              result.state == TransactionState.reverted)) {
        _requestUncertain = false;
      }
      if (result.state == TransactionState.confirmed && _lastReview != null) {
        _ledger = _ledger.recordConfirmed(
          hash: result.hash,
          units: _lastReview!.units,
        );
      }
      notifyListeners();
      await _saveTransfer();
      if (result.state == TransactionState.confirmed) {
        await _saveLedger();
      }
      if (result.state == TransactionState.confirmed ||
          result.state == TransactionState.reverted) {
        await refreshBalance();
      }
    } catch (e) {
      if (_transaction?.hash == current.hash) {
        _transaction = TransactionResult(
          current.hash,
          TransactionState.unknown,
        );
        _error = _safeError(e);
        notifyListeners();
      }
    }
  }

  @override
  Future<void> recoverTransaction() async {
    if (awLabTextOnly) return;
    try {
      final hash = validateTransactionHash(_recoverHash.text.trim());
      _transaction = TransactionResult(hash, TransactionState.pending);
      _error = null;
      notifyListeners();
      await _checkReceipt();
    } catch (e) {
      _error = _safeError(e);
      notifyListeners();
    }
  }

  @override
  Future<void> acknowledgeNoSend() async {
    if (awLabTextOnly) return;
    if (_wallet.requestPending) return;
    _requestUncertain = false;
    _error = null;
    _lastReview = null;
    _transaction = null;
    notifyListeners();
    await _saveTransfer();
  }

  bool _statusAllowsQueries(AgentStatus status) {
    if (awLabTextOnly) status.verifyLabPolicy();
    return status.initialized &&
        !status.busy &&
        !status.requiresReset &&
        _agent.configuredForRequests;
  }

  void _finishLabAudit(String outcome, {int? durationMs}) {
    if (_labRequestAudit == null) return;
    _labRequestAudit = {
      ..._labRequestAudit!,
      'finished_at_utc': DateTime.now().toUtc().toIso8601String(),
      'outcome': outcome,
      if (durationMs != null) 'native_duration_ms': durationMs,
    };
  }

  @override
  Future<void> probeNative() async {
    _agentBusy = true;
    _agentError = null;
    notifyListeners();
    try {
      final status = await _agent.status();
      _nativeStatus = status;
      _agentReady = _statusAllowsQueries(status);
      _agentStatus = 'rustExecutedStatus';
    } catch (e) {
      _nativeStatus = null;
      _agentReady = false;
      _agentError = 'No se pudo ejecutar la biblioteca nativa: ${_safeError(e)}';
    } finally {
      _agentBusy = false;
      notifyListeners();
    }
  }

  @override
  Future<void> startAgent() async {
    if (_agentBusy) return;
    _agentBusy = true;
    _agentError = null;
    notifyListeners();
    try {
      final endpoint =
          (awLabTextOnly
                  ? validateLabInferenceEndpoint(_endpoint.text)
                  : validateInferenceEndpoint(_endpoint.text))
              .toString();
      if (awLabTextOnly) validateLabModel(_model.text);
      if (_model.text.trim().isEmpty || _key.text.isEmpty) {
        throw const FormatException(
          awLabTextOnly
              ? 'Completá el modelo local y la clave o marcador del servidor de laboratorio.'
              : 'Completá el modelo y la clave del proveedor.',
        );
      }
      await _saveSettings();
      final cache = await getApplicationCacheDirectory();
      final workspace = Directory(
        '${cache.path}/${awLabTextOnly ? 'openhuman_lab' : 'openhuman_arc'}',
      );
      await workspace.create(recursive: true);
      await _agent.initialize(
        endpoint: endpoint,
        apiKey: _key.text,
        model: _model.text.trim(),
        workspace: workspace.path,
      );
      final status = await _agent.status();
      _nativeStatus = status;
      _agentReady = _statusAllowsQueries(status);
      _agentSession = null;
      _agentReply = null;
      _toolCalls = const [];
      _liveReads = const [];
      _labRequestAudit = null;
      _agentStatus = awLabTextOnly ? 'labReadyStatus' : 'openHumanLocalActive';
    } catch (e) {
      _agentReady = false;
      _agentError = _safeError(e);
    } finally {
      _agentBusy = false;
      notifyListeners();
    }
  }

  @override
  Future<void> askAgent() async {
    if (!_agentReady || _agentBusy) return;
    final requestId = awLabTextOnly ? newLabRequestId() : null;
    _agentBusy = true;
    _agentError = null;
    _agentReply = null;
    _toolCalls = const [];
    _liveReads = const [];
    if (requestId != null) {
      _labRequestAudit = {
        'scope': 'aw-client-observation-only',
        'mode': labTextMode,
        'request_id': requestId,
        'started_at_utc': DateTime.now().toUtc().toIso8601String(),
        'endpoint': _endpoint.text.trim(),
        'model_requested': _model.text.trim(),
        'outcome': 'in_progress',
      };
    }
    notifyListeners();
    try {
      final turn = await _agent.sendTurn(
        prompt: _prompt.text.trim(),
        sessionId: _agentSession ?? '',
        requestId: requestId,
      );
      _agentReply = turn.reply;
      _agentSession = turn.sessionId;
      _toolCalls = turn.toolCalls;
      _liveReads = turn.liveReads;
      _finishLabAudit('response_received', durationMs: turn.durationMs);
      _agentStatus =
          awLabTextOnly ? 'labResponseReceivedStatus' : 'turnCompletedStatus';
    } catch (e) {
      _agentError = _safeError(e);
      _finishLabAudit('error');
      try {
        final status = await _agent.status();
        _nativeStatus = status;
        _agentReady = _statusAllowsQueries(status);
      } catch (_) {
        _agentReady = false;
      }
    } finally {
      _agentBusy = false;
      notifyListeners();
    }
  }

  @override
  Future<void> cancelAgent() async {
    try {
      await _agent.cancel();
      if (_labRequestAudit != null) {
        _labRequestAudit = {
          ..._labRequestAudit!,
          'cancellation_requested_at_utc':
              DateTime.now().toUtc().toIso8601String(),
        };
        notifyListeners();
      }
    } catch (e) {
      _agentError = _safeError(e);
      notifyListeners();
    }
  }

  @override
  Future<void> resetAgent() async {
    if (_agentBusy) return;
    _agentBusy = true;
    notifyListeners();
    try {
      await _agent.reset();
      final status = await _agent.status();
      _nativeStatus = status;
      _agentReady = false;
      _agentSession = null;
      _agentReply = null;
      _agentError = null;
      _toolCalls = const [];
      _liveReads = const [];
      _agentStatus = 'agentStoppedStatus';
    } catch (e) {
      _agentError =
          'No se pudo verificar que el runtime se haya detenido: ${_safeError(e)}';
    } finally {
      _key.clear();
      _rememberKey = false;
      try {
        await _saveSettings();
        if (!awLabTextOnly) {
          await _storage.delete(key: 'openhuman_inference_api_key');
        }
      } catch (_) {
        _settingsError = 'No se pudo confirmar el borrado de la clave guardada.';
      }
      _agentBusy = false;
      notifyListeners();
    }
  }

  @override
  void applyProposal() {
    if (awLabTextOnly) return;
    final p = proposal;
    if (p == null || _busy) return;
    _recipient.text = p.recipient;
    _amount.text = formatUnits(p.units, 6);
    notifyListeners();
  }

  @override
  Future<void> open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  void setRememberKey(bool? value) {
    _rememberKey = value ?? false;
    _settingsTouched = true;
    notifyListeners();
  }

  @override
  void noteEndpointEdited() {
    _settingsTouched = true;
    _key.clear();
    notifyListeners();
  }

  void setDialogContext(BuildContext context) {
    _dialogContext = context;
  }
}
