import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'domain/arc.dart';
import 'domain/inference_config.dart';
import 'domain/treasury_policy.dart';
import 'openhuman_bridge.dart';
import 'services/arc_rpc.dart';
import 'services/wallet_session.dart';
import 'ui/context_bar.dart';
import 'ui/splash_view.dart';
import 'ui/theme.dart';

import 'l10n/app_localizations.dart';

part 'ui/caja_view.dart';
part 'ui/agente_view.dart';
part 'ui/red_view.dart';
part 'ui/ajustes_view.dart';

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
  });
  final bool autoInitialize;
  final OpenHumanBridge? agent;
  final bool showSplash;
  final Locale? overrideLocale;

  @override
  State<ArcWalletApp> createState() => _ArcWalletAppState();
}

class _ArcWalletAppState extends State<ArcWalletApp> {
  Locale? _locale;

  void _setLocale(Locale? locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
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
    home: widget.showSplash
        ? FluuiXLaunch(
            child: WalletHome(
              autoInitialize: widget.autoInitialize,
              agent: widget.agent,
              onLocaleChanged: _setLocale,
            ),
          )
        : WalletHome(
            autoInitialize: widget.autoInitialize,
            agent: widget.agent,
            onLocaleChanged: _setLocale,
          ),
  );
}

class WalletHome extends StatefulWidget {
  const WalletHome({
    super.key,
    this.autoInitialize = true,
    this.agent,
    this.onLocaleChanged,
  });
  final bool autoInitialize;
  final OpenHumanBridge? agent;
  final void Function(Locale?)? onLocaleChanged;

  @override
  State<WalletHome> createState() => _WalletHomeState();
}

class _WalletHomeState extends State<WalletHome> with WidgetsBindingObserver {
  final _arcRpc = awLabTextOnly ? null : ArcRpc();
  final _walletSession = awLabTextOnly ? null : WalletSession();
  ArcRpc get _rpc =>
      _arcRpc ?? (throw StateError('Arc está deshabilitado en laboratorio.'));
  WalletSession get _wallet =>
      _walletSession ??
      (throw StateError('La wallet está deshabilitada en laboratorio.'));
  late final _agent = widget.agent ?? OpenHumanBridge();
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

  int _tab = awLabTextOnly ? 1 : 0;
  CajaPanel _cajaPanel = CajaPanel.pay;
  TreasuryDayLedger _ledger = TreasuryDayLedger.empty();
  bool _missions = false;
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
  String _networkStatus = 'connectionPending';
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

  bool get _transferBlocked =>
      awLabTextOnly ||
      !_storageReady ||
      _requestUncertain ||
      _wallet.requestPending ||
      (_transaction != null &&
          _transaction!.state != TransactionState.confirmed &&
          _transaction!.state != TransactionState.reverted);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _walletSession?.addListener(_walletChanged);
    if (widget.autoInitialize) {
      if (!awLabTextOnly) unawaited(_checkNetwork());
      unawaited(_loadSettings());
    }
  }

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
      unawaited(_refreshBalance());
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

  Future<void> _loadSettings() async {
    try {
      final saved = await _storage.read(key: inferenceSettingsKey);
      final transfer = awLabTextOnly
          ? null
          : await _storage.read(key: 'aw_transfer_v1');
      final languageCode = await _storage.read(key: 'aw_language_v1');
      if (!mounted) return;
      if (languageCode != null) {
        _selectedLocale = Locale(languageCode);
        widget.onLocaleChanged?.call(_selectedLocale);
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
      setState(() => _storageReady = true);
      if (!awLabTextOnly && _projectId.text.trim().isNotEmpty) {
        await _configureWallet(persist: false);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _storageReady = false;
          _settingsError = awLabTextOnly
              ? 'settingsErrorLab'
              : 'settingsErrorArc';
        });
      }
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
      if (mounted) setState(() => _storageReady = false);
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

  Future<void> _saveLocale(Locale? locale) async {
    _selectedLocale = locale;
    widget.onLocaleChanged?.call(locale);
    try {
      if (locale == null) {
        await _storage.delete(key: 'aw_language_v1');
      } else {
        await _storage.write(key: 'aw_language_v1', value: locale.languageCode);
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _configureWallet({bool persist = true}) async {
    if (awLabTextOnly) return;
    if (_settingsBusy || _busy) return;
    setState(() {
      _settingsBusy = true;
      _settingsError = null;
    });
    try {
      await _wallet.configure(_projectId.text.trim());
      if (persist) await _saveSettings();
    } catch (e) {
      if (mounted) setState(() => _settingsError = _safeError(e));
    } finally {
      if (mounted) setState(() => _settingsBusy = false);
    }
  }

  void _walletChanged() {
    if (awLabTextOnly || !mounted) return;
    final address = _wallet.address;
    if (_lastWalletAddress != address) {
      _lastWalletAddress = address;
      _balance = null;
      unawaited(_refreshBalance());
    }
    final hash = _wallet.lastHash;
    if (hash != null && hash != _transaction?.hash) {
      _transaction = TransactionResult(hash, TransactionState.submitted);
      _requestUncertain = false;
      unawaited(_saveTransfer().catchError((Object _) {}));
      unawaited(_pollReceipt());
    }
    setState(() {});
  }

  Future<void> _checkNetwork() async {
    if (awLabTextOnly) return;
    try {
      await _rpc.verifyNetwork();
      if (!mounted) return;
      setState(() {
        _networkVerified = true;
        _networkStatus = 'rpcVerified';
      });
      await _refreshBalance();
    } catch (e) {
      if (mounted) {
        setState(() {
          _networkVerified = false;
          _networkStatus = _safeError(e);
        });
      }
    }
  }

  Future<void> _refreshBalance() async {
    if (awLabTextOnly) return;
    final address = _wallet.address;
    if (address == null) return;
    try {
      await _rpc.verifyNetwork();
      final balance = await _rpc.nativeBalance(address);
      if (mounted && address == _wallet.address) {
        setState(() {
          _balance = balance;
          _networkVerified = true;
        });
      }
    } catch (e) {
      if (mounted && address == _wallet.address) {
        setState(() => _error = _safeError(e));
      }
    }
  }

  Future<void> _connect() async {
    if (awLabTextOnly) return;
    if (!_wallet.configured) {
      setState(() => _tab = 2);
      return;
    }
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _wallet.connect(_showPairing);
      if (mounted && !_wallet.supportsArc) {
        setState(
          () => _error = 'sessionNotAuthorizedArc',
        );
      }
      await _refreshBalance();
    } catch (e) {
      if (mounted) setState(() => _error = _safeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showPairing(Uri uri) async {
    if (awLabTextOnly || !mounted) return;
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

  Future<void> _addArc() async {
    if (awLabTextOnly) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _wallet.requestArcNetwork();
      if (mounted) {
        setState(() => _error = 'networkRequestedReconnect');
      }
    } catch (e) {
      if (mounted) setState(() => _error = _safeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect() async {
    if (awLabTextOnly) return;
    try {
      await _wallet.disconnect();
    } catch (e) {
      if (mounted) setState(() => _error = _safeError(e));
    }
  }

  Future<void> _reviewAndSend() async {
    if (awLabTextOnly || _busy || _transferBlocked) return;
    setState(() {
      _busy = true;
      _error = null;
    });
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
      if (!mounted) return;
      _wallet.verifyReview(review);
      final accepted = await _showReview(review);
      if (!mounted || accepted != true) return;
      await _rpc.verifyNetwork();
      await _rpc.verifyFunds(review);
      if (!mounted) return;
      _wallet.verifyReview(review);
      _lastReview = review;
      _transaction = null;
      _requestUncertain = true;
      await _saveTransfer();
      if (!mounted) return;
      _wallet.verifyReview(review);
      requested = true;
      final hash = await _wallet.send(review);
      if (!mounted) return;
      setState(() {
        _transaction = TransactionResult(hash, TransactionState.submitted);
        _requestUncertain = false;
      });
      await _saveTransfer();
      await _pollReceipt();
    } catch (e) {
      if (mounted) {
        setState(() {
          if (!requested) _requestUncertain = false;
          _error = requested
              ? '${_safeError(e)}\nRevisá el estado en tu wallet. Una demora o error de comunicación no demuestra que no se haya enviado.'
              : _safeError(e);
        });
        if (!requested) await _saveTransfer().catchError((Object _) {});
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _showReview(TransferReview review) {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.reviewTransferTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.arcTestnetTestFunds,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              Text(
                '${formatUnits(review.units, 6)} USDC',
                style: Theme.of(dialog).textTheme.headlineSmall,
              ),
              const SizedBox(height: 14),
              Text(l10n.from),
              SelectableText(review.sender),
              const SizedBox(height: 10),
              Text(l10n.recipient),
              SelectableText(review.recipient),
              const SizedBox(height: 10),
              Text(l10n.maxFee(formatUnits(review.maximumFee, 18))),
              Text(l10n.maxTotal(formatUnits(review.nativeRequired, 18))),
              const SizedBox(height: 10),
              Text(l10n.reviewExpiry),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(l10n.requestApproval),
          ),
        ],
      ),
    );
  }

  Future<void> _pollReceipt() async {
    if (awLabTextOnly || _polling || _transaction == null) return;
    _polling = true;
    final hash = _transaction!.hash;
    try {
      final deadline = DateTime.now().add(const Duration(seconds: 60));
      while (mounted &&
          _transaction?.hash == hash &&
          DateTime.now().isBefore(deadline)) {
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
      if (!mounted || _transaction?.hash != current.hash) return;
      setState(() {
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
      });
      await _saveTransfer();
      if (result.state == TransactionState.confirmed) {
        await _saveLedger();
      }
      if (result.state == TransactionState.confirmed ||
          result.state == TransactionState.reverted) {
        await _refreshBalance();
      }
    } catch (e) {
      if (mounted && _transaction?.hash == current.hash) {
        setState(() {
          _transaction = TransactionResult(
            current.hash,
            TransactionState.unknown,
          );
          _error = _safeError(e);
        });
      }
    }
  }

  Future<void> _recoverTransaction() async {
    if (awLabTextOnly) return;
    try {
      final hash = validateTransactionHash(_recoverHash.text.trim());
      setState(() {
        _transaction = TransactionResult(hash, TransactionState.pending);
        _error = null;
      });
      await _checkReceipt();
    } catch (e) {
      if (mounted) setState(() => _error = _safeError(e));
    }
  }

  Future<void> _acknowledgeNoSend() async {
    if (awLabTextOnly) return;
    if (_wallet.requestPending) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.confirmWalletState),
        content: Text(l10n.confirmNoSendMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(l10n.goBack),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(l10n.verifiedNotSent),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() {
      _requestUncertain = false;
      _error = null;
      _lastReview = null;
      _transaction = null;
    });
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

  Future<void> _probeNative() async {
    setState(() {
      _agentBusy = true;
      _agentError = null;
    });
    try {
      final status = await _agent.status();
      if (!mounted) return;
      setState(() {
        _nativeStatus = status;
        _agentReady = _statusAllowsQueries(status);
        _agentStatus = 'rustExecutedStatus';
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _nativeStatus = null;
          _agentReady = false;
          _agentError =
              'No se pudo ejecutar la biblioteca nativa: ${_safeError(e)}';
        });
      }
    } finally {
      if (mounted) setState(() => _agentBusy = false);
    }
  }

  Future<void> _startAgent() async {
    if (_agentBusy) return;
    setState(() {
      _agentBusy = true;
      _agentError = null;
    });
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
      if (!mounted) return;
      setState(() {
        _nativeStatus = status;
        _agentReady = _statusAllowsQueries(status);
        _agentSession = null;
        _agentReply = null;
        _toolCalls = const [];
        _liveReads = const [];
        _labRequestAudit = null;
        _tab = 1;
        _agentStatus = awLabTextOnly
            ? 'labReadyStatus'
            : 'openHumanLocalActive';
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _agentReady = false;
          _agentError = _safeError(e);
        });
      }
    } finally {
      if (mounted) setState(() => _agentBusy = false);
    }
  }

  Future<void> _askAgent() async {
    if (!_agentReady || _agentBusy) return;
    final requestId = awLabTextOnly ? newLabRequestId() : null;
    setState(() {
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
    });
    try {
      final turn = await _agent.sendTurn(
        prompt: _prompt.text.trim(),
        sessionId: _agentSession ?? '',
        requestId: requestId,
      );
      if (!mounted) return;
      setState(() {
        _agentReply = turn.reply;
        _agentSession = turn.sessionId;
        _toolCalls = turn.toolCalls;
        _liveReads = turn.liveReads;
        _finishLabAudit('response_received', durationMs: turn.durationMs);
        _agentStatus = awLabTextOnly
            ? 'labResponseReceivedStatus'
            : 'turnCompletedStatus';
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _agentError = _safeError(e);
          _finishLabAudit('error');
        });
      }
      try {
        final status = await _agent.status();
        if (mounted) {
          setState(() {
            _nativeStatus = status;
            _agentReady = _statusAllowsQueries(status);
          });
        }
      } catch (_) {
        if (mounted) setState(() => _agentReady = false);
      }
    } finally {
      if (mounted) setState(() => _agentBusy = false);
    }
  }

  Future<void> _cancelAgent() async {
    try {
      await _agent.cancel();
      if (mounted && _labRequestAudit != null) {
        setState(() {
          _labRequestAudit = {
            ..._labRequestAudit!,
            'cancellation_requested_at_utc': DateTime.now()
                .toUtc()
                .toIso8601String(),
          };
        });
      }
    } catch (e) {
      if (mounted) setState(() => _agentError = _safeError(e));
    }
  }

  Future<void> _resetAgent() async {
    if (_agentBusy) return;
    setState(() => _agentBusy = true);
    try {
      await _agent.reset();
      final status = await _agent.status();
      if (!mounted) return;
      setState(() {
        _nativeStatus = status;
        _agentReady = false;
        _agentSession = null;
        _agentReply = null;
        _agentError = null;
        _toolCalls = const [];
        _liveReads = const [];
        _agentStatus = 'agentStoppedStatus';
      });
    } catch (e) {
      if (mounted) {
        setState(
          () => _agentError =
              'No se pudo verificar que el runtime se haya detenido: ${_safeError(e)}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _key.clear();
          _rememberKey = false;
        });
        try {
          await _saveSettings();
          if (!awLabTextOnly) {
            await _storage.delete(key: 'openhuman_inference_api_key');
          }
        } catch (_) {
          if (mounted) {
            setState(
              () => _settingsError =
                  'No se pudo confirmar el borrado de la clave guardada.',
            );
          }
        }
        if (mounted) setState(() => _agentBusy = false);
      }
    }
  }

  TransferProposal? get _proposal {
    if (awLabTextOnly) return null;
    try {
      return _agentReply == null ? null : TransferProposal.parse(_agentReply!);
    } catch (_) {
      return null;
    }
  }

  void _applyProposal() {
    if (awLabTextOnly) return;
    final proposal = _proposal;
    if (proposal == null || _busy) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _recipient.text = proposal.recipient;
      _amount.text = formatUnits(proposal.units, 6);
      _cajaPanel = CajaPanel.pay;
      _tab = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.proposalValidatedCopied)),
    );
  }

  Future<void> _open(String url) async {
    final l10n = AppLocalizations.of(context);
    try {
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotOpenLink)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotOpenLink)),
        );
      }
    }
  }

  void _showCajaPanel(CajaPanel panel) => setState(() => _cajaPanel = panel);

  void _openSettingsTab() => setState(() => _tab = 2);

  void _noteEndpointEdited() {
    _settingsTouched = true;
    _key.clear();
    setState(() {});
  }

  void _setRememberKey(bool? value) => setState(() {
    _rememberKey = value ?? false;
    _settingsTouched = true;
  });

  int get _selectedNav {
    if (awLabTextOnly) return _tab - 1;
    return switch (_tab) {
      0 => 0,
      1 => 1,
      3 => 2,
      _ => 3,
    };
  }

  int _tabForNav(int value) {
    if (awLabTextOnly) return value + 1;
    return switch (value) {
      0 => 0,
      1 => 1,
      2 => 3,
      _ => 2,
    };
  }

  String _getNetworkStatusText(AppLocalizations l10n) {
    if (_networkStatus == 'connectionPending') return l10n.connectionPending;
    if (_networkStatus == 'rpcVerified') return l10n.rpcVerified;
    return _networkStatus;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (!awLabTextOnly)
              FluuixContextBar(
                activeLayer: l10n.navCaja,
                chainName: 'Arc Testnet',
                rpcConnected: _networkVerified,
                railName: 'Twin · ARGt',
                walletConnected: _wallet.connected,
                walletAddress: _wallet.address,
                isTestnet: true,
              ),
            AppBar(
              title: Text(awLabTextOnly ? l10n.appTitleLab : l10n.appTitle),
              actions: [
                if (!awLabTextOnly)
                  IconButton(
                    onPressed: () => setState(() => _missions = !_missions),
                    icon: Icon(
                      _missions ? Icons.dashboard_outlined : Icons.flag_outlined,
                    ),
                    tooltip: _missions ? l10n.ordersViewTooltip : l10n.missionViewTooltip,
                  ),
                if (!awLabTextOnly)
                  IconButton(
                    onPressed: _busy ? null : _checkNetwork,
                    icon: const Icon(Icons.refresh),
                    tooltip: l10n.refreshArcTooltip,
                  ),
              ],
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 660),
                  child: ListView(
                    key: ValueKey(_tab),
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (awLabTextOnly) ...[_labBanner(l10n), const SizedBox(height: 16)],
                      if (!awLabTextOnly && _missions) ...[
                        _ordenesCard(l10n),
                        const SizedBox(height: 16),
                      ],
                      if (!awLabTextOnly && _tab == 0) ..._cajaView(l10n),
                      if (_tab == 1) ..._agentView(l10n),
                      if (!awLabTextOnly && _tab == 3) ..._redView(l10n),
                      if (_tab == 2) ..._settingsView(l10n),
                      const SizedBox(height: 24),
                      Text(
                        awLabTextOnly ? l10n.footerLab : l10n.footerArcTestnet,
                        style: const TextStyle(
                          color: FluuixColors.textMuted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedNav,
        onDestinationSelected: (value) =>
            setState(() => _tab = _tabForNav(value)),
        destinations: [
          if (!awLabTextOnly)
            NavigationDestination(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: l10n.navCaja,
            ),
          NavigationDestination(
            icon: const Icon(Icons.psychology_outlined),
            label: l10n.navAgente,
          ),
          if (!awLabTextOnly)
            NavigationDestination(
              icon: const Icon(Icons.hub_outlined),
              label: l10n.navRed,
            ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            label: l10n.navAjustes,
          ),
        ],
      ),
    );
  }

  Widget _labBanner(AppLocalizations l10n) => _card(
    children: [
      Text(
        l10n.labBannerTitle,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Text(l10n.labBannerDesc),
    ],
  );

  Widget _card({required List<Widget> children}) => SizedBox(
    width: double.infinity,
    child: Material(
      color: FluuixColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: FluuixColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    ),
  );

  Widget _errorBox(String message) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FluuixColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FluuixColors.error.withValues(alpha: 0.3)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: FluuixColors.error, height: 1.4),
      ),
    ),
  );
}
