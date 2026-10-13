import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'ui/splash_view.dart';

part 'ui/caja_view.dart';
part 'ui/agente_view.dart';
part 'ui/red_view.dart';
part 'ui/ajustes_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ArcWalletApp(showSplash: true));
}

class ArcWalletApp extends StatelessWidget {
  const ArcWalletApp({
    super.key,
    this.autoInitialize = true,
    this.agent,
    this.showSplash = false,
  });
  final bool autoInitialize;
  final OpenHumanBridge? agent;
  final bool showSplash;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: awLabTextOnly ? 'AW · Laboratorio de texto' : 'FluuiX',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xffc4b08a),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xff101017),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xff20202c),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    home: showSplash
        ? FluuiXLaunch(
            child: WalletHome(autoInitialize: autoInitialize, agent: agent),
          )
        : WalletHome(autoInitialize: autoInitialize, agent: agent),
  );
}

class WalletHome extends StatefulWidget {
  const WalletHome({super.key, this.autoInitialize = true, this.agent});
  final bool autoInitialize;
  final OpenHumanBridge? agent;
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
  final _endpoint = TextEditingController();
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
  String _networkStatus = 'Conexión pendiente';
  String _agentStatus = 'Verificá el runtime y configurá la inferencia';
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

  // Errors shown by dependencies are scrubbed before being displayed.
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
      if (!mounted) return;
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
        // The saved key and endpoint form one record; a host edit clears the key.
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
              ? 'No se pudieron restaurar los ajustes del laboratorio. Revisá la configuración segura antes de iniciar.'
              : 'No se pudieron restaurar los ajustes seguros. El envío está bloqueado hasta recuperar el estado y comprobar operaciones pendientes.';
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
        _networkStatus = 'RPC verificado · Arc Testnet';
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
          () => _error =
              'La sesión no autorizó Arc Testnet. Agregá la red a la wallet y reconectá autorizando 5042002.',
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
    await showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Conectá tu wallet'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Escaneá desde otra pantalla o abrí una wallet compatible con WalletConnect. Volvé a FluuiX después de aprobar.',
              ),
              const SizedBox(height: 12),
              ColoredBox(
                color: Colors.white,
                child: QrImageView(data: '$uri', size: 210),
              ),
              const SizedBox(height: 10),
              const Text(
                'La wallet debe tener Arc Testnet configurada. La conexión no envía fondos.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: '$uri'));
              if (dialog.mounted) {
                ScaffoldMessenger.of(dialog).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'URI copiada. Pegala en WalletConnect dentro de tu wallet.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Copiar URI'),
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
                    const SnackBar(
                      content: Text(
                        'Usá Copiar URI y pegala en tu wallet, o escaneá el QR.',
                      ),
                    ),
                  );
                }
                if (opened && dialog.mounted) Navigator.pop(dialog);
              } catch (_) {
                if (dialog.mounted) {
                  ScaffoldMessenger.of(dialog).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'No se encontró una wallet para este enlace. Usá el QR o copiá la URI.',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Abrir wallet'),
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
        setState(
          () => _error =
              'Red solicitada. Volvé a conectar la wallet y autorizá Arc Testnet en la nueva sesión.',
        );
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
      // Persist the uncertainty marker before any wallet authorization request.
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

  Future<bool?> _showReview(TransferReview review) => showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialog) => AlertDialog(
      title: const Text('Revisá la transferencia'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Arc Testnet · fondos de prueba',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Text(
              '${formatUnits(review.units, 6)} USDC',
              style: Theme.of(dialog).textTheme.headlineSmall,
            ),
            const SizedBox(height: 14),
            const Text('Desde'),
            SelectableText(review.sender),
            const SizedBox(height: 10),
            const Text('Destinatario'),
            SelectableText(review.recipient),
            const SizedBox(height: 10),
            Text('Comisión máxima: ${formatUnits(review.maximumFee, 18)} USDC'),
            Text(
              'Total máximo: ${formatUnits(review.nativeRequired, 18)} USDC',
            ),
            const SizedBox(height: 10),
            const Text(
              'La revisión vence en 2 minutos. Verificá en tu wallet que la red, el destinatario, el importe y la comisión coincidan. Tu wallet solicita la firma final.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialog, true),
          child: const Text('Solicitar aprobación'),
        ),
      ],
    ),
  );

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Confirmá el estado en tu wallet'),
        content: const Text(
          'Continuá sólo si verificaste que la solicitud anterior fue rechazada o cancelada y que no existe una transferencia pendiente o enviada. Repetir un envío puede duplicar el pago.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Verifiqué que no se envió'),
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
        _agentStatus = 'Rust ejecutado en ${status.os}/${status.arch} · ABI 1';
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
      final kimi = !awLabTextOnly && isKimiInferenceEndpoint(endpoint);
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
            ? 'Laboratorio listo · endpoint $endpoint · modelo solicitado ${_model.text.trim()}'
            : kimi
            ? 'OpenHuman local activo · motor Kimi ${_model.text.trim()} en api.moonshot.ai'
            : 'OpenHuman local activo · inferencia en ${Uri.parse(endpoint).host}';
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
            ? 'Respuesta recibida · cotejá el ID con el registro de tu servidor'
            : 'Turno completado por OpenHuman';
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
        _agentStatus = 'Agente detenido y conversación local descartada';
      });
    } catch (e) {
      if (mounted) {
        setState(
          () => _agentError =
              'No se pudo verificar que el runtime se haya detenido: ${_safeError(e)}',
        );
      }
    } finally {
      // Forget persisted credentials even when a missing native library cannot
      // be reset. A runtime failure remains visible and is never called success.
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
    setState(() {
      _recipient.text = proposal.recipient;
      _amount.text = formatUnits(proposal.units, 6);
      _cajaPanel = CajaPanel.pay;
      _tab = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Propuesta validada y copiada. Revisá destinatario, importe y comisión antes de firmar.',
        ),
      ),
    );
  }

  Future<void> _open(String url) async {
    try {
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace.')),
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

  void _useKimiEngine() {
    final previous = Uri.tryParse(_endpoint.text.trim());
    if (previous?.host != 'api.moonshot.ai') _key.clear();
    _endpoint.text = kimiInferenceRoot;
    _model.text = kimiModelId;
    setState(() {
      _settingsTouched = true;
      _agentError = null;
    });
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(awLabTextOnly ? 'AW · Laboratorio de texto' : 'FluuiX'),
      actions: [
        if (!awLabTextOnly)
          IconButton(
            onPressed: () => setState(() => _missions = !_missions),
            icon: Icon(
              _missions ? Icons.dashboard_outlined : Icons.flag_outlined,
            ),
            tooltip: _missions ? 'Vista de caja' : 'Órdenes del día',
          ),
        if (!awLabTextOnly)
          IconButton(
            onPressed: _busy ? null : _checkNetwork,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar Arc',
          ),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 660),
          child: ListView(
            key: ValueKey(_tab),
            padding: const EdgeInsets.all(20),
            children: [
              if (awLabTextOnly) ...[_labBanner(), const SizedBox(height: 16)],
              if (!awLabTextOnly && _missions) ...[
                _ordenesCard(),
                const SizedBox(height: 16),
              ],
              if (!awLabTextOnly && _tab == 0) ..._cajaView(),
              if (_tab == 1) ..._agentView(),
              if (!awLabTextOnly && _tab == 3) ..._redView(),
              if (_tab == 2) ..._settingsView(),
              const SizedBox(height: 24),
              const Text(
                awLabTextOnly
                    ? 'AW no cambia de proveedor automáticamente. Confirmá que el servidor autorizado ejecuta un modelo local; recibir texto no demuestra por sí solo su procedencia.'
                    : 'Arc Testnet · USDC de prueba\nLa wallet externa controla tus claves y pide la firma. FluuiX no solicita frases semilla ni claves privadas.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _selectedNav,
      onDestinationSelected: (value) =>
          setState(() => _tab = _tabForNav(value)),
      destinations: const [
        if (!awLabTextOnly)
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Caja',
          ),
        NavigationDestination(
          icon: Icon(Icons.psychology_outlined),
          label: 'Agente',
        ),
        if (!awLabTextOnly)
          NavigationDestination(icon: Icon(Icons.hub_outlined), label: 'Red'),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          label: 'Ajustes',
        ),
      ],
    ),
  );

  Widget _labBanner() => _card(
    children: [
      const Text(
        'Laboratorio · sólo texto',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      const Text(
        'Wallet, pagos, propuestas y consultas Arc deshabilitados. '
        'El agente no dispone de herramientas. '
        'Este modo queda fijo al compilar la app.',
      ),
    ],
  );

  Widget _card({required List<Widget> children}) => SizedBox(
    width: double.infinity,
    child: Material(
      color: const Color(0xff191923),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xff353347)),
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
        color: const Color(0xff37222b),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xffffc4cf), height: 1.4),
      ),
    ),
  );
}
