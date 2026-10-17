import 'dart:convert';
import 'dart:io';

import 'package:arc_wallet_flutter/domain/arc.dart';
import 'package:arc_wallet_flutter/domain/inference_config.dart';
import 'package:arc_wallet_flutter/main.dart';
import 'package:arc_wallet_flutter/openhuman_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'arc_domain_test.dart' show proposal;
import 'inference_lab_test.dart' show labStatus;

/// Widget-only double. It performs no FFI, HTTP or model execution.
class LabWidgetBridge extends OpenHumanBridge {
  LabWidgetBridge(this.reply, {AgentStatus? nativeStatus})
    : _nativeStatus = nativeStatus ?? AgentStatus.decode(labStatus()),
      super(labTextOnly: true);
  final String reply;
  final AgentStatus _nativeStatus;
  String? lastRequestId;
  int calls = 0;

  @override
  bool get configuredForRequests => true;

  @override
  Future<AgentStatus> status() async => _nativeStatus;

  @override
  Future<AgentTurn> sendTurn({
    required String prompt,
    String sessionId = '',
    String? requestId,
  }) async {
    calls++;
    lastRequestId = requestId;
    return AgentTurn(
      reply: reply,
      sessionId: 'widget-only-session',
      liveReads: const [],
      requestId: requestId,
      durationMs: 0,
      modelRequested: 'widget-only-model',
      mode: labTextMode,
    );
  }
}

void main() {
  testWidgets(
    'uninitialized native defaults are not presented as active lab permissions',
    (tester) async {
      // Mirrors the native pre-init policy fields; no native call is made.
      final status = AgentStatus.decode({
        ...labStatus(initialized: false),
        'mode': 'proposal-only',
        'inference': 'remote',
        'tools': ['arc_network_status', 'arc_balance'],
      });
      final bridge = LabWidgetBridge('', nativeStatus: status);
      await tester.pumpWidget(
        ArcWalletApp(
          autoInitialize: false,
          agent: bridge,
          overrideLocale: const Locale('es'),
        ),
      );
      final probe = find.text('Verificar ejecución nativa de Rust');
      await tester.scrollUntilVisible(
        probe,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(probe);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Runtime sin inicializar. La política de herramientas se comprueba al inicializar.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Herramientas permitidas:'), findsNothing);
      expect(find.text('Política nativa: proposal-only'), findsNothing);
      expect(find.textContaining('arc_network_status'), findsNothing);
      expect(find.textContaining('arc_balance'), findsNothing);
      final configure = find.text('Configurar laboratorio');
      await tester.scrollUntilVisible(
        configure,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(configure, findsOneWidget);
      expect(find.text('Consultar OpenHuman'), findsNothing);
      expect(bridge.calls, 0);
      expect(tester.takeException(), isNull);
    },
    skip: !awLabTextOnly,
  );

  testWidgets(
    'lab startup and resume make no HTTP requests or restore Arc credentials',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({
        'aw_settings_v1': jsonEncode({
          'endpoint': 'https://api.openai.com/v1',
          'model': 'historical-model',
          'key': 'historical-synthetic-marker',
          'project_id': '1' * 32,
        }),
        'aw_transfer_v1': 'deliberately invalid; laboratory must not read this',
      });
      var httpClients = 0;
      await HttpOverrides.runZoned(
        () async {
          await tester.pumpWidget(
            const ArcWalletApp(overrideLocale: Locale('es')),
          );
          await tester.pumpAndSettle();
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pumpAndSettle();
          expect(find.text('Laboratorio · sólo texto'), findsOneWidget);
          expect(find.text('Enviar USDC'), findsNothing);
          expect(find.byTooltip('Actualizar Arc'), findsNothing);
          expect(find.byTooltip('Vista de misiones'), findsNothing);
          expect(
            tester
                .widgetList<NavigationDestination>(
                  find.byType(NavigationDestination),
                )
                .map((item) => item.label),
            ['Agente', 'Ajustes'],
          );
          await tester.tap(find.text('Ajustes').last);
          await tester.pumpAndSettle();
          for (final key in [
            'inference-endpoint',
            'inference-model',
            'inference-key',
          ]) {
            final field = find.byKey(Key(key));
            await tester.scrollUntilVisible(
              field,
              180,
              scrollable: find.byType(Scrollable).first,
            );
            expect(tester.widget<TextField>(field).controller!.text, isEmpty);
          }
          expect(find.text('Guardar y conectar Reown'), findsNothing);
          expect(find.text('Agregar Arc Testnet manualmente'), findsNothing);
          expect(httpClients, 0);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
        createHttpClient: (SecurityContext? _) {
          httpClients++;
          throw StateError(
            'Unexpected HTTP access in a laboratory widget test',
          );
        },
      );
      expect(
        await const FlutterSecureStorage().read(key: 'aw_transfer_v1'),
        'deliberately invalid; laboratory must not read this',
      );
    },
    skip: !awLabTextOnly,
  );

  testWidgets(
    'financial-shaped model text remains text with no wallet action in lab',
    (tester) async {
      final reply = jsonEncode(proposal());
      expect(TransferProposal.parse(reply).units, isNot(BigInt.zero));
      final bridge = LabWidgetBridge(reply);
      await tester.pumpWidget(
        ArcWalletApp(
          autoInitialize: false,
          agent: bridge,
          overrideLocale: const Locale('es'),
        ),
      );
      final probe = find.text('Verificar ejecución nativa de Rust');
      await tester.scrollUntilVisible(
        probe,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(probe);
      await tester.pumpAndSettle();
      expect(find.text('Herramientas permitidas: ninguna'), findsOneWidget);
      expect(find.text('Política nativa: lab-text-only'), findsOneWidget);
      final ask = find.text('Consultar OpenHuman');
      await tester.scrollUntilVisible(
        ask,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(ask);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(reply),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(reply), findsOneWidget);
      expect(bridge.calls, 1);
      expect(isLabRequestId(bridge.lastRequestId!), isTrue);
      expect(find.text('Llevar propuesta al formulario'), findsNothing);
      expect(find.text('Revisar transferencia'), findsNothing);
      expect(find.text('Conectar wallet'), findsNothing);
      expect(tester.takeException(), isNull);
    },
    skip: !awLabTextOnly,
  );
}
