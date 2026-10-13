import 'package:arc_wallet_flutter/domain/inference_config.dart';
import 'package:arc_wallet_flutter/openhuman_bridge.dart';
import 'package:flutter_test/flutter_test.dart';

const labRequestId = 'awlab-0123456789abcdef0123456789abcdef';

Map<String, dynamic> labStatus({bool initialized = true}) => {
  'abi_version': 1,
  'runtime': 'openhuman-embed',
  'initialized': initialized,
  'busy': false,
  'requires_reset': false,
  'target_arch': 'test-architecture',
  'target_os': 'test-host',
  'upstream_commit': 'test-only',
  'mode': labTextMode,
  'inference': labInferenceKind,
  'supported_modes': ['proposal-only', labTextMode],
  'tools': <String>[],
  'lab_context_tokens': 4096,
};

Map<String, dynamic> labTurn() => {
  'reply': 'Synthetic unit-test reply; no inference performed.',
  'session_id': 'test-session',
  'request_id': labRequestId,
  'duration_ms': 12,
  'mode': labTextMode,
  'model_requested': 'test-local-model',
  'live_reads': <Object>[],
};

void main() {
  test('lab endpoint accepts only canonical loopback and exact /v1', () {
    for (final endpoint in [
      'http://127.0.0.1:11434/v1',
      'http://127.2.3.4:8787/v1',
      'https://[::1]:8443/v1',
      'http://127.0.0.1/v1',
    ]) {
      expect(validateLabInferenceEndpoint(endpoint).path, '/v1');
    }
  });

  test('lab rejects cloud, LAN, DNS aliases and ambiguous paths/ports', () {
    for (final endpoint in [
      '',
      'https://api.openai.com/v1',
      'https://192.168.1.2:11434/v1',
      'http://localhost:11434/v1',
      'http://127.0.0.1.evil:11434/v1',
      'http://2130706433:11434/v1',
      'http://127.1:11434/v1',
      'http://127.00.0.1:11434/v1',
      'http://[0:0:0:0:0:0:0:1]:11434/v1',
      'http://%31%32%37.0.0.1:11434/v1',
      'http://127.0.0.1:11434/v1/',
      'http://127.0.0.1:11434/v1/chat/completions',
      'http://127.0.0.1:11434/x/../v1',
      'http://127.0.0.1:11434/x/%2e%2e/v1',
      'http://user:pass@127.0.0.1:11434/v1',
      'http://127.0.0.1:11434/v1?token=synthetic',
      'http://127.0.0.1:11434/v1#fragment',
      'http://127.0.0.1:70000/v1',
      'http://127.0.0.1:0/v1',
      'http://127.0.0.1:80/v1',
      'https://[::1]:443/v1',
    ]) {
      expect(
        () => validateLabInferenceEndpoint(endpoint),
        throwsFormatException,
        reason: endpoint,
      );
    }
  });

  test('lab model rejects routed hints and explicit cloud references', () {
    expect(validateLabModel(' local-model:4b '), 'local-model:4b');
    for (final model in [
      '',
      'hint:fast',
      'HINT:fast',
      'local@remote',
      'qwen:cloud',
      'LOCAL-CLOUD-ALIAS',
      'model\u0000name',
    ]) {
      expect(
        () => validateLabModel(model),
        throwsFormatException,
        reason: model,
      );
    }
  });

  test('generated correlation IDs satisfy the native fixed ASCII contract', () {
    final ids = List.generate(8, (_) => newLabRequestId());
    expect(ids.every(isLabRequestId), isTrue);
    expect(ids.toSet().length, ids.length);
    expect(isLabRequestId('$labRequestId\n'), isFalse);
    expect(isLabRequestId(labRequestId.toUpperCase()), isFalse);
  });

  test(
    'lab status accepts explicit policy and advertised pre-init support',
    () {
      AgentStatus.decode(labStatus()).verifyLabPolicy();
      AgentStatus.decode(labStatus(initialized: false)).verifyLabPolicy();
      expect(AgentStatus.decode(labStatus()).labContextTokens, 4096);
    },
  );

  test('lab status rejects legacy ABI policy and any active tool grant', () {
    final legacy = labStatus()..remove('supported_modes');
    for (final status in [
      legacy,
      {...labStatus(), 'mode': 'proposal-only'},
      {...labStatus(), 'inference': 'remote'},
      {
        ...labStatus(),
        'tools': ['arc_balance'],
      },
      {
        ...labStatus(),
        'supported_modes': ['proposal-only'],
      },
    ]) {
      expect(
        () => AgentStatus.decode(status).verifyLabPolicy(),
        throwsStateError,
      );
    }
    expect(
      () => AgentStatus.decode({
        ...labStatus(),
        'tools': [42],
      }),
      throwsFormatException,
    );
  });

  test('lab reply retains verified correlation and native duration', () {
    final result = AgentTurn.decode(
      labTurn(),
      expectedRequestId: labRequestId,
      expectedModel: 'test-local-model',
    );
    expect(result.requestId, labRequestId);
    expect(result.durationMs, 12);
    expect(result.liveReads, isEmpty);
  });

  test('lab rejects missing/mismatched metadata and every tool result', () {
    final missingReads = labTurn()..remove('live_reads');
    for (final value in [
      missingReads,
      {...labTurn(), 'request_id': newLabRequestId()},
      {...labTurn(), 'mode': 'proposal-only'},
      {...labTurn(), 'model_requested': 'different-model'},
      {...labTurn(), 'duration_ms': -1},
      {...labTurn(), 'duration_ms': '12'},
      {...labTurn(), 'reply': ''},
      {
        ...labTurn(),
        'live_reads': [
          {'tool': 'arc_balance', 'result': {}},
        ],
      },
    ]) {
      expect(
        () => AgentTurn.decode(
          value,
          expectedRequestId: labRequestId,
          expectedModel: 'test-local-model',
        ),
        throwsFormatException,
      );
    }
  });

  test(
    'invalid lab input fails before native library or network access',
    () async {
      final bridge = OpenHumanBridge(labTextOnly: true);
      await expectLater(
        bridge.initialize(
          endpoint: 'https://api.openai.com/v1',
          apiKey: 'synthetic-marker',
          model: 'test-local-model',
          workspace: '/not-accessed',
        ),
        throwsFormatException,
      );
      await expectLater(
        bridge.sendTurn(prompt: 'Synthetic test', requestId: labRequestId),
        throwsStateError,
      );
      expect(bridge.configuredForRequests, isFalse);
      expect(OpenHumanBridge(labTextOnly: false).labTextOnly, awLabTextOnly);
    },
  );
}
