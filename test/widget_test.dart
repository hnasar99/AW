import 'package:arc_wallet_flutter/main.dart';
import 'package:arc_wallet_flutter/domain/inference_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'wallet and mission views share state, agent is not falsely ready',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const ArcWalletApp(autoInitialize: false));
      expect(find.text('FluuiX'), findsOneWidget);
      expect(find.text('Caja en dólares'), findsOneWidget);
      expect(find.text('Pagar'), findsWidgets);
      expect(find.text('Conexión pendiente'), findsOneWidget);
      expect(find.text('Sin contrato'), findsWidgets);
      await tester.tap(find.byTooltip('Órdenes del día'));
      await tester.pump();
      expect(find.text('Órdenes del día'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
      await tester.tap(find.byTooltip('Vista de caja'));
      await tester.pump();
      final passage = find.widgetWithText(OutlinedButton, 'Pasar');
      await tester.ensureVisible(passage);
      await tester.tap(passage);
      await tester.pump();
      expect(find.textContaining('no está conectado'), findsOneWidget);
      await tester.tap(find.text('Agente').last);
      await tester.pumpAndSettle();
      expect(find.text('Agente de la caja'), findsOneWidget);
      expect(find.text('Verificar ejecución nativa de Rust'), findsOneWidget);
      expect(find.text('OpenHuman local activo'), findsNothing);
      await tester.tap(find.text('Red').last);
      await tester.pumpAndSettle();
      expect(find.text('ZonaBank'), findsOneWidget);
      expect(find.text('Lending'), findsOneWidget);
      expect(find.text('ZonaFranca'), findsOneWidget);
      expect(find.text('TTN'), findsOneWidget);
      expect(find.text('Fideicomisos'), findsOneWidget);
      expect(find.text('Fondos'), findsOneWidget);
      expect(find.text('Crowd'), findsOneWidget);
      expect(find.text('Licitaciones'), findsOneWidget);
      expect(find.text('Donaciones'), findsOneWidget);
      expect(find.text('Academia'), findsOneWidget);
      expect(find.text('Sin contrato'), findsNWidgets(10));
      expect(find.textContaining('12,480'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      expect(find.textContaining('APY'), findsNothing);
    },
    skip: awLabTextOnly,
  );

  testWidgets(
    'the opening mark gives way to the box',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const ArcWalletApp(autoInitialize: false, showSplash: true),
      );
      expect(find.byKey(const Key('fluuix-splash')), findsOneWidget);
      expect(find.text('Caja en dólares'), findsWidgets);
      await tester.pump(const Duration(milliseconds: 2900));
      await tester.pump();
      expect(find.byKey(const Key('fluuix-splash')), findsNothing);
      expect(find.text('Caja en dólares'), findsOneWidget);
    },
    skip: awLabTextOnly,
  );
}
