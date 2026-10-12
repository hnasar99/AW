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
import 'openhuman_bridge.dart';
import 'services/arc_rpc.dart';
import 'services/wallet_session.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ArcWalletApp());
}

class ArcWalletApp extends StatelessWidget {
  const ArcWalletApp({super.key, this.autoInitialize = true, this.agent});
  final bool autoInitialize;
  final OpenHumanBridge? agent;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: awLabTextOnly ? 'AW · Laboratorio de texto' : 'AW · Arc Wallet',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff9883ff),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xff101017),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xff20202c),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    home: WalletHome(autoInitialize: autoInitialize, agent: agent),
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
          () => _error = 'La sesión no autorizó Arc Testnet. Agregá la red a la wallet y reconectá autorizando 5042002.',
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
                'Escaneá desde otra pantalla o abrí una wallet compatible con WalletConnect. Volvé a AW después de aprobar.',
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
          () => _error = 'Red solicitada. Volvé a conectar la wallet y autorizá Arc Testnet en la nueva sesión.',
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
      });
      await _saveTransfer();
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        awLabTextOnly ? 'AW · Laboratorio de texto' : 'AW · Arc Wallet',
      ),
      actions: [
        if (!awLabTextOnly)
          IconButton(
            onPressed: () => setState(() => _missions = !_missions),
            icon: Icon(
              _missions ? Icons.dashboard_outlined : Icons.flag_outlined,
            ),
            tooltip: _missions ? 'Vista estándar' : 'Vista de misiones',
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
                _missionCard(),
                const SizedBox(height: 16),
              ],
              if (!awLabTextOnly && _tab == 0) ..._walletView(),
              if (_tab == 1) ..._agentView(),
              if (_tab == 2) ..._settingsView(),
              const SizedBox(height: 24),
              const Text(
                awLabTextOnly
                    ? 'AW no cambia de proveedor automáticamente. Confirmá que el servidor autorizado ejecuta un modelo local; recibir texto no demuestra por sí solo su procedencia.'
                    : 'Arc Testnet · USDC de prueba\nLa wallet externa controla tus claves y pide la firma. AW no solicita frases semilla ni claves privadas.',
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
      selectedIndex: awLabTextOnly ? _tab - 1 : _tab,
      onDestinationSelected: (value) =>
          setState(() => _tab = awLabTextOnly ? value + 1 : value),
      destinations: const [
        if (!awLabTextOnly)
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Wallet',
          ),
        NavigationDestination(
          icon: Icon(Icons.psychology_outlined),
          label: 'Agente',
        ),
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

  List<Widget> _walletView() => [
    _card(
      children: [
        Row(
          children: [
            Icon(
              Icons.circle,
              size: 10,
              color: _networkVerified ? Colors.greenAccent : Colors.amber,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'ARC TESTNET · 5042002',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(_networkStatus, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 20),
        Text(
          _balance == null ? '—' : formatUnits(_balance!, 18, places: 6),
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
        ),
        const Text('USDC', style: TextStyle(color: Color(0xffbbaaff))),
        const SizedBox(height: 8),
        const Text(
          'Un único saldo para transferencias y comisiones.',
          style: TextStyle(color: Colors.white60, fontSize: 12),
        ),
        if (_wallet.address != null) ...[
          const Divider(height: 28),
          SelectableText(_wallet.address!),
          Text(
            'Sesión: cadena ${_wallet.chainId}',
            style: const TextStyle(color: Colors.white60),
          ),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: _busy ? null : _disconnect,
                child: const Text('Desconectar'),
              ),
              TextButton(
                onPressed: () =>
                    _open('${ArcNetwork.explorer}/address/${_wallet.address}'),
                child: const Text('Ver cuenta'),
              ),
            ],
          ),
        ],
      ],
    ),
    const SizedBox(height: 20),
    Text('Enviar USDC', style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 12),
    TextField(
      controller: _recipient,
      enabled: !_busy,
      autocorrect: false,
      enableSuggestions: false,
      decoration: const InputDecoration(
        labelText: 'Dirección del destinatario',
        hintText: '0x…',
      ),
    ),
    const SizedBox(height: 12),
    TextField(
      controller: _amount,
      enabled: !_busy,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Importe',
        suffixText: 'USDC',
        helperText: 'Hasta 6 decimales. No se redondea.',
      ),
    ),
    const SizedBox(height: 12),
    FilledButton.icon(
      onPressed:
          _busy ||
              _wallet.requestPending ||
              (_wallet.connected && _transferBlocked)
          ? null
          : (_wallet.connected ? _reviewAndSend : _connect),
      icon: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.fact_check_outlined),
      label: Text(
        _busy
            ? 'Procesando…'
            : _wallet.connected
            ? 'Revisar transferencia'
            : 'Conectar wallet',
      ),
    ),
    if (_wallet.connected && !_wallet.supportsArc)
      OutlinedButton(
        onPressed: _busy ? null : _addArc,
        child: const Text('Solicitar agregar Arc Testnet'),
      ),
    TextButton(
      onPressed: () => _open('https://faucet.circle.com/'),
      child: const Text('Obtener USDC de prueba'),
    ),
    if (_transaction != null) ...[
      const SizedBox(height: 16),
      _transactionCard(),
    ],
    if (_requestUncertain) ...[
      const SizedBox(height: 16),
      _card(
        children: [
          const Text(
            'Solicitud sin resolver',
            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Revisá el historial y las solicitudes en tu wallet antes de otro envío. Si hay un hash, pegalo para comprobarlo.',
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _recoverHash,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Hash de transacción 0x…',
            ),
          ),
          TextButton(
            onPressed: _recoverTransaction,
            child: const Text('Comprobar hash'),
          ),
          TextButton(
            onPressed: _wallet.requestPending ? null : _acknowledgeNoSend,
            child: const Text('La solicitud fue cancelada o rechazada'),
          ),
        ],
      ),
    ],
    if (_error != null) _errorBox(_error!),
  ];

  Widget _transactionCard() {
    final result = _transaction!;
    final label = switch (result.state) {
      TransactionState.submitted => 'Enviada · esperando recibo',
      TransactionState.confirmed => 'Confirmada · ejecución exitosa',
      TransactionState.reverted => 'Revertida · la operación falló en la red',
      TransactionState.pending => 'Pendiente · todavía sin recibo',
      TransactionState.unknown =>
        'Estado no verificado · consultá el explorador',
    };
    return _card(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SelectableText(result.hash),
        if (result.blockNumber != null) Text('Bloque ${result.blockNumber}'),
        Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: _checkReceipt,
              child: const Text('Comprobar recibo'),
            ),
            TextButton(
              onPressed: () =>
                  _open('${ArcNetwork.explorer}/tx/${result.hash}'),
              child: const Text('Abrir explorador'),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _agentView() => [
    Text(
      awLabTextOnly ? 'Consulta al laboratorio' : 'OpenHuman en tu móvil',
      style: Theme.of(context).textTheme.headlineSmall,
    ),
    const SizedBox(height: 10),
    Text(_agentStatus),
    const SizedBox(height: 10),
    const Text(
      awLabTextOnly
          ? 'OpenHuman coordina la consulta dentro de AW. El modelo debe ejecutarse en tu laboratorio, a través del endpoint loopback que configures. No se inicia ninguna consulta de blockchain.'
          : 'La orquestación y las herramientas Arc se ejecutan en Rust dentro de la app. El modelo responde desde el proveedor de inferencia que configurás. Las consultas y los resultados de herramientas usados por el agente se envían a ese proveedor.',
      style: TextStyle(color: Colors.white70, height: 1.5),
    ),
    const SizedBox(height: 16),
    OutlinedButton.icon(
      onPressed: _agentBusy ? null : _probeNative,
      icon: const Icon(Icons.memory),
      label: const Text('Verificar ejecución nativa de Rust'),
    ),
    if (_nativeStatus != null) ...[
      const SizedBox(height: 10),
      _card(
        children: [
          Text(
            'Biblioteca ejecutada: ${_nativeStatus!.os} / ${_nativeStatus!.arch}',
          ),
          Text('OpenHuman ${shorten(_nativeStatus!.commit)}'),
          Text(
            'Herramientas permitidas: ${_nativeStatus!.tools.isEmpty ? 'ninguna' : _nativeStatus!.tools.join(', ')}',
          ),
          if (awLabTextOnly)
            Text('Política nativa: ${_nativeStatus!.mode ?? 'sin iniciar'}'),
          if (awLabTextOnly && _nativeStatus!.labContextTokens != null)
            Text(
              'Presupuesto del agente: ${_nativeStatus!.labContextTokens} tokens. No acredita la capacidad real del modelo.',
            ),
          const Text(
            awLabTextOnly
                ? 'Ejecutar esta biblioteca no verifica todavía el modelo del laboratorio.'
                : 'Esta prueba local no implica que la inferencia o una transferencia hayan sido verificadas.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    ],
    const SizedBox(height: 16),
    if (!_agentReady)
      FilledButton(
        onPressed: () => setState(() => _tab = 2),
        child: const Text(
          awLabTextOnly
              ? 'Configurar laboratorio'
              : 'Configurar proveedor e iniciar agente',
        ),
      ),
    if (_agentReady) ...[
      TextField(
        controller: _prompt,
        minLines: 3,
        maxLines: 8,
        enabled: !_agentBusy,
        decoration: const InputDecoration(labelText: 'Tu consulta al agente'),
      ),
      const SizedBox(height: 10),
      if (!awLabTextOnly)
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              label: const Text('Estado real de Arc'),
              onPressed: _agentBusy ? null : () => _prompt.text = 'Usá arc_network_status y explicame el estado real de Arc Testnet.',
            ),
            if (_wallet.address != null)
              ActionChip(
                label: const Text('Consultar mi saldo'),
                onPressed: _agentBusy
                    ? null
                    : () => _prompt.text =
                          'Usá arc_balance para consultar el saldo USDC de ${_wallet.address} en Arc Testnet. Explicá que es el mismo saldo que paga gas.',
              ),
          ],
        ),
      const SizedBox(height: 10),
      FilledButton.icon(
        onPressed: _agentBusy ? null : _askAgent,
        icon: const Icon(Icons.psychology_outlined),
        label: Text(_agentBusy ? 'Agente trabajando…' : 'Consultar OpenHuman'),
      ),
      if (_agentBusy) ...[
        const SizedBox(height: 8),
        const LinearProgressIndicator(),
        TextButton(
          onPressed: _cancelAgent,
          child: const Text('Cancelar turno'),
        ),
      ],
    ],
    if (_agentReply != null) ...[
      const SizedBox(height: 18),
      _card(
        children: [
          SelectableText(_agentReply!, style: const TextStyle(height: 1.5)),
        ],
      ),
      if (!awLabTextOnly && _toolCalls.isNotEmpty)
        Text('Herramientas ejecutadas: ${_toolCalls.join(', ')}'),
      if (!awLabTextOnly)
        ..._liveReads.map(
          (read) => Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _card(
              children: [
                Text(
                  'Lectura de ${read.tool}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (read.result['block_number'] != null)
                  Text('Bloque: ${read.result['block_number']}'),
                if (read.result['balance_usdc'] != null)
                  Text('Saldo USDC: ${read.result['balance_usdc']}'),
                if (read.result['observed_at_unix'] != null)
                  Text('Observación UNIX: ${read.result['observed_at_unix']}'),
                Text(
                  read.result['ok'] == true
                      ? 'Resultado obtenido por la herramienta Rust'
                      : 'La herramienta no pudo completar la lectura',
                ),
              ],
            ),
          ),
        ),
      if (!awLabTextOnly && _proposal != null)
        OutlinedButton.icon(
          onPressed: _busy ? null : _applyProposal,
          icon: const Icon(Icons.assignment_return_outlined),
          label: const Text('Llevar propuesta al formulario'),
        ),
      const SizedBox(height: 8),
      const Text(
        awLabTextOnly
            ? 'La salida del modelo es texto no confiable. No se interpreta como una instrucción ni habilita acciones.'
            : 'Una respuesta del modelo no es una confirmación de pago. El agente sólo propone; la firma requiere tu revisión en la wallet.',
        style: TextStyle(color: Colors.white60, fontSize: 12),
      ),
    ],
    if (awLabTextOnly && _labRequestAudit != null) ...[
      const SizedBox(height: 16),
      _card(
        children: [
          const Text('Registro de la última consulta'),
          const SizedBox(height: 8),
          SelectableText(
            const JsonEncoder.withIndent('  ').convert(_labRequestAudit),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sólo metadatos del cliente. Cotejá este ID con el procesamiento real en tu servidor y con la respuesta visible. No se incluyen mensajes ni claves.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          TextButton(
            onPressed: () => Clipboard.setData(
              ClipboardData(text: jsonEncode(_labRequestAudit)),
            ),
            child: const Text('Copiar registro sin mensajes ni claves'),
          ),
        ],
      ),
    ],
    if (_agentError != null) _errorBox(_agentError!),
    if (_nativeStatus?.requiresReset == true ||
        (awLabTextOnly && _nativeStatus?.initialized == true && !_agentReady))
      OutlinedButton(
        onPressed: _agentBusy ? null : _resetAgent,
        child: const Text('Reiniciar después del turno interrumpido'),
      ),
  ];

  List<Widget> _settingsView() => [
    Text(
      awLabTextOnly ? 'Configuración del laboratorio' : 'Conexiones',
      style: Theme.of(context).textTheme.headlineSmall,
    ),
    const SizedBox(height: 16),
    if (!awLabTextOnly)
      _card(
        children: [
          const Text(
            'WalletConnect / Reown',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ingresá el Project ID de tu proyecto. Se puede cambiar sin recompilar. La sesión de wallet permanece sólo en memoria; al reiniciar la app se vuelve a conectar.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _projectId,
            autocorrect: false,
            enableSuggestions: false,
            enabled: !_settingsBusy && !_busy && !_wallet.requestPending,
            onChanged: (_) => _settingsTouched = true,
            decoration: const InputDecoration(
              labelText: 'Project ID',
              hintText: '32 caracteres hexadecimales',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _settingsBusy || _busy || _wallet.requestPending
                ? null
                : _configureWallet,
            child: Text(
              _settingsBusy ? 'Conectando…' : 'Guardar y conectar Reown',
            ),
          ),
          if (_wallet.configured)
            const Text(
              'Cliente Reown inicializado',
              style: TextStyle(color: Colors.greenAccent),
            ),
        ],
      ),
    const SizedBox(height: 16),
    _card(
      children: [
        const Text(
          awLabTextOnly
              ? 'Servidor de texto local'
              : 'Inferencia para OpenHuman',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        const Text(
          awLabTextOnly
              ? 'Ingresá la IP loopback literal y la ruta /v1 del transporte que estableciste hacia tu servidor autorizado. Elegí un modelo que ya esté instalado allí. No hay endpoint ni modelo predeterminados.'
              : 'Elegí un endpoint compatible con OpenAI y el modelo habilitado por tu proveedor. El modelo usa Internet; el runtime Rust se ejecuta en el teléfono.',
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('inference-endpoint'),
          controller: _endpoint,
          enabled: !_agentReady && !_agentBusy,
          autocorrect: false,
          keyboardType: TextInputType.url,
          enableSuggestions: false,
          onChanged: (_) {
            _settingsTouched = true;
            _key.clear();
            setState(() {});
          },
          decoration: const InputDecoration(
            labelText: awLabTextOnly
                ? 'Endpoint loopback /v1'
                : 'Endpoint HTTPS',
            hintText: awLabTextOnly
                ? 'Completá tu endpoint autorizado'
                : 'https://provider.example/v1',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('inference-model'),
          controller: _model,
          enabled: !_agentReady && !_agentBusy,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (_) => _settingsTouched = true,
          decoration: const InputDecoration(
            labelText: 'ID del modelo',
            hintText: awLabTextOnly
                ? 'ID exacto del modelo local instalado'
                : 'Modelo habilitado en tu proveedor',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('inference-key'),
          controller: _key,
          enabled: !_agentReady && !_agentBusy,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (_) => _settingsTouched = true,
          decoration: const InputDecoration(
            labelText: awLabTextOnly
                ? 'Clave o marcador del servidor'
                : 'API key de inferencia',
            helperText: awLabTextOnly
                ? 'Un marcador sintético no protege ni autentica el servidor.'
                : null,
            helperMaxLines: 2,
          ),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _rememberKey,
          onChanged: _agentReady || _agentBusy
              ? null
              : (value) => setState(() {
                  _rememberKey = value ?? false;
                  _settingsTouched = true;
                }),
          title: const Text(
            'Recordar la clave en el almacenamiento seguro del sistema',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          awLabTextOnly
              ? 'Las consultas se envían únicamente al endpoint indicado. Los ajustes del laboratorio se guardan separados de los del modo Arc.'
              : 'Al activar y consultar, enviás tus mensajes y el contexto necesario a ${Uri.tryParse(_endpoint.text)?.host ?? 'tu proveedor'}.',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: _agentReady || _agentBusy ? null : _startAgent,
          child: Text(
            _agentBusy
                ? 'Inicializando…'
                : awLabTextOnly
                ? 'Iniciar laboratorio de texto'
                : 'Activar OpenHuman con este proveedor',
          ),
        ),
        OutlinedButton(
          onPressed: _agentBusy ? null : _resetAgent,
          child: const Text('Detener agente y olvidar la clave'),
        ),
      ],
    ),
    const SizedBox(height: 16),
    if (!awLabTextOnly)
      ExpansionTile(
        title: const Text('Agregar Arc Testnet manualmente'),
        children: [
          _card(
            children: [
              const Text(
                'Nombre: Arc Testnet\nChain ID: 5042002\nMoneda nativa: USDC · 18 decimales',
              ),
              const SelectableText(
                'RPC: ${ArcNetwork.rpc}\nExplorador: ${ArcNetwork.explorer}',
              ),
              const SizedBox(height: 8),
              const Text(
                'Agregá la red en tu wallet, luego reconectá a AW autorizando Arc Testnet. Agregar una red no amplía automáticamente los permisos de una sesión existente.',
              ),
              TextButton(
                onPressed: () =>
                    _open('https://docs.arc.io/arc/references/connect-to-arc'),
                child: const Text('Documentación oficial'),
              ),
            ],
          ),
        ],
      ),
    if (_settingsError != null) _errorBox(_settingsError!),
    if (!_storageReady && !_settingsBusy)
      TextButton(
        onPressed: _loadSettings,
        child: const Text('Volver a leer el estado seguro'),
      ),
    if (_agentError != null) _errorBox(_agentError!),
  ];

  Widget _missionCard() {
    final steps = <(String, bool)>[
      ('Verificar Arc Testnet', _networkVerified),
      ('Ejecutar Rust en el dispositivo', _nativeStatus != null),
      ('Activar OpenHuman', _agentReady),
      ('Conectar una cuenta en Arc', _wallet.supportsArc),
      (
        'Confirmar una transferencia real de testnet',
        _transaction?.state == TransactionState.confirmed,
      ),
    ];
    return _card(
      children: [
        const Text(
          'Misiones de verificación',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...steps.map(
          (step) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  step.$2 ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 18,
                  color: step.$2 ? Colors.greenAccent : Colors.white38,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(step.$1)),
              ],
            ),
          ),
        ),
      ],
    );
  }

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
