import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/arc.dart';
import '../domain/inference_config.dart';
import '../openhuman_bridge.dart';

/// Manages OpenHuman agent state and interactions.
class AgentNotifier extends ChangeNotifier {
  AgentNotifier({OpenHumanBridge? agent}) : _agent = agent ?? OpenHumanBridge();

  final OpenHumanBridge _agent;

  bool _busy = false;
  bool _ready = false;
  String _status = 'agentVerifyStatus';
  String? _error;
  String? _sessionId;
  String? _reply;
  List<String> _toolCalls = const [];
  List<AgentLiveRead> _liveReads = const [];
  AgentStatus? _nativeStatus;
  Map<String, Object?>? _labRequestAudit;

  bool get busy => _busy;
  bool get ready => _ready;
  String get status => _status;
  String? get error => _error;
  String? get sessionId => _sessionId;
  String? get reply => _reply;
  List<String> get toolCalls => _toolCalls;
  List<AgentLiveRead> get liveReads => _liveReads;
  AgentStatus? get nativeStatus => _nativeStatus;
  Map<String, Object?>? get labRequestAudit => _labRequestAudit;

  bool get configuredForRequests => _agent.configuredForRequests;

  bool _statusAllowsQueries(AgentStatus status) {
    if (awLabTextOnly) status.verifyLabPolicy();
    return status.initialized &&
        !status.busy &&
        !status.requiresReset &&
        _agent.configuredForRequests;
  }

  Future<void> probeNative() async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final status = await _agent.status();
      _nativeStatus = status;
      _ready = _statusAllowsQueries(status);
      _status = 'rustExecutedStatus';
      notifyListeners();
    } catch (e) {
      _nativeStatus = null;
      _ready = false;
      _error = 'Could not execute native library: ${_safeError(e)}';
      notifyListeners();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> initialize({
    required String endpoint,
    required String apiKey,
    required String model,
  }) async {
    if (_busy) return;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final validEndpoint =
          (awLabTextOnly
                  ? validateLabInferenceEndpoint(endpoint)
                  : validateInferenceEndpoint(endpoint))
              .toString();
      if (awLabTextOnly) validateLabModel(model);
      if (model.trim().isEmpty || apiKey.isEmpty) {
        throw const FormatException(
          awLabTextOnly
              ? 'Complete the local model and the server key or marker.'
              : 'Complete the model and the provider key.',
        );
      }
      final cache = await getApplicationCacheDirectory();
      final workspace = Directory(
        '${cache.path}/${awLabTextOnly ? 'openhuman_lab' : 'openhuman_arc'}',
      );
      await workspace.create(recursive: true);
      await _agent.initialize(
        endpoint: validEndpoint,
        apiKey: apiKey,
        model: model.trim(),
        workspace: workspace.path,
      );
      final status = await _agent.status();
      _nativeStatus = status;
      _ready = _statusAllowsQueries(status);
      _sessionId = null;
      _reply = null;
      _toolCalls = const [];
      _liveReads = const [];
      _labRequestAudit = null;
      _status = awLabTextOnly
          ? 'labReadyStatus'
          : 'openHumanLocalActive';
      notifyListeners();
    } catch (e) {
      _ready = false;
      _error = _safeError(e);
      notifyListeners();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> sendTurn(String prompt) async {
    if (!_ready || _busy) return;
    final requestId = awLabTextOnly ? newLabRequestId() : null;
    _busy = true;
    _error = null;
    _reply = null;
    _toolCalls = const [];
    _liveReads = const [];
    if (requestId != null) {
      _labRequestAudit = {
        'scope': 'aw-client-observation-only',
        'mode': labTextMode,
        'request_id': requestId,
        'started_at_utc': DateTime.now().toUtc().toIso8601String(),
        'outcome': 'in_progress',
      };
    }
    notifyListeners();
    try {
      final turn = await _agent.sendTurn(
        prompt: prompt.trim(),
        sessionId: _sessionId ?? '',
        requestId: requestId,
      );
      _reply = turn.reply;
      _sessionId = turn.sessionId;
      _toolCalls = turn.toolCalls;
      _liveReads = turn.liveReads;
      _finishLabAudit('response_received', durationMs: turn.durationMs);
      _status = awLabTextOnly
          ? 'labResponseReceivedStatus'
          : 'turnCompletedStatus';
      notifyListeners();
    } catch (e) {
      _error = _safeError(e);
      _finishLabAudit('error');
      notifyListeners();
      try {
        final status = await _agent.status();
        _nativeStatus = status;
        _ready = _statusAllowsQueries(status);
        notifyListeners();
      } catch (_) {
        _ready = false;
        notifyListeners();
      }
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> cancel() async {
    try {
      await _agent.cancel();
      if (_labRequestAudit != null) {
        _labRequestAudit = {
          ..._labRequestAudit!,
          'cancellation_requested_at_utc': DateTime.now()
              .toUtc()
              .toIso8601String(),
        };
        notifyListeners();
      }
    } catch (e) {
      _error = _safeError(e);
      notifyListeners();
    }
  }

  Future<void> reset() async {
    if (_busy) return;
    _busy = true;
    notifyListeners();
    try {
      await _agent.reset();
      final status = await _agent.status();
      _nativeStatus = status;
      _ready = false;
      _sessionId = null;
      _reply = null;
      _error = null;
      _toolCalls = const [];
      _liveReads = const [];
      _status = 'agentStoppedStatus';
      notifyListeners();
    } catch (e) {
      _error = 'Could not verify that the runtime has stopped: ${_safeError(e)}';
      notifyListeners();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  TransferProposal? get proposal {
    if (awLabTextOnly) return null;
    try {
      return _reply == null ? null : TransferProposal.parse(_reply!);
    } catch (_) {
      return null;
    }
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

  String _safeError(Object error) {
    var text = error.toString();
    text = text.replaceAll(
      RegExp(r'Bearer\s+\S+', caseSensitive: false),
      'Bearer [redacted]',
    );
    return text.length > 600 ? '${text.substring(0, 600)}…' : text;
  }
}
