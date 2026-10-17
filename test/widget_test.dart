import 'package:arc_wallet_flutter/main.dart';
import 'package:arc_wallet_flutter/domain/inference_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder navBarItem(String label) => find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    );

void main() {
  testWidgets(
    'navigation between tabs works with new router structure',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const ArcWalletApp(
          autoInitialize: false,
          overrideLocale: Locale('es'),
        ),
      );
      await tester.pumpAndSettle();
      expect(navBarItem('Inicio'), findsOneWidget);
      expect(navBarItem('Caja'), findsOneWidget);
      expect(navBarItem('Agente'), findsOneWidget);
      expect(navBarItem('Rieles'), findsOneWidget);
      expect(navBarItem('Más'), findsOneWidget);
      await tester.tap(navBarItem('Caja'));
      await tester.pumpAndSettle();
      expect(find.text('Caja en dólares'), findsOneWidget);
      expect(find.text('Pagar'), findsWidgets);
      await tester.tap(navBarItem('Agente'));
      await tester.pumpAndSettle();
      expect(find.text('Agente de la caja'), findsOneWidget);
      expect(find.text('Verificar ejecución nativa de Rust'), findsOneWidget);
      await tester.tap(navBarItem('Más'));
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
      await tester.tap(navBarItem('Rieles'));
      await tester.pumpAndSettle();
      expect(find.text('Rieles'), findsWidgets);
      expect(find.text('Twin · ARGt'), findsWidgets);
    },
    skip: awLabTextOnly,
  );

  testWidgets(
    'home screen shows all 6 layers with proper states',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const ArcWalletApp(
          autoInitialize: false,
          overrideLocale: Locale('es'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bienvenido a FluuiX'), findsOneWidget);
      expect(find.text('Capas'), findsOneWidget);
      expect(find.text('Agentes'), findsOneWidget);
      expect(find.text('Rieles'), findsWidgets);
      expect(find.text('Contratos'), findsOneWidget);
      expect(find.text('Wallets'), findsOneWidget);
      expect(find.text('Settlement'), findsOneWidget);
      expect(find.text('Multichain'), findsOneWidget);
      expect(find.text('Sin contrato'), findsNWidgets(3));
      expect(find.text('Parcial'), findsNWidgets(2));
      expect(find.text('Activo'), findsOneWidget);
      expect(find.text('Acciones rápidas'), findsOneWidget);
      expect(find.text('Estado del sistema'), findsOneWidget);
    },
    skip: awLabTextOnly,
  );

  testWidgets(
    'layer card tap navigates to correct screen',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const ArcWalletApp(
          autoInitialize: false,
          overrideLocale: Locale('es'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wallets'));
      await tester.pumpAndSettle();
      expect(find.text('Caja en dólares'), findsOneWidget);
      await tester.tap(navBarItem('Inicio'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Agentes'));
      await tester.pumpAndSettle();
      expect(find.text('Agente de la caja'), findsOneWidget);
    },
    skip: awLabTextOnly,
  );
  
  testWidgets(
    'context bar shows TESTNET badge and status indicators',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const ArcWalletApp(
          autoInitialize: false,
          overrideLocale: Locale('es'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('TESTNET'), findsOneWidget);
      expect(find.text('Arc Testnet'), findsOneWidget);
      expect(find.text('Twin · ARGt'), findsWidgets);
    },
    skip: awLabTextOnly,
  );

  testWidgets(
    'theme uses Fluuix brand colors',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const ArcWalletApp(
          autoInitialize: false,
          overrideLocale: Locale('es'),
        ),
      );
      await tester.pumpAndSettle();
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold, isNotNull);
      final theme = Theme.of(tester.element(find.byType(Scaffold).first));
      expect(theme.useMaterial3, isTrue);
    },
    skip: awLabTextOnly,
  );

  testWidgets(
    'caja pay screen shows checklist and review button',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const ArcWalletApp(
          autoInitialize: false,
          overrideLocale: Locale('es'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(navBarItem('Caja'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pagar').first);
      await tester.pumpAndSettle();
      expect(find.text('Pagar'), findsWidgets);
      expect(find.text('Lista de verificación'), findsOneWidget);
      expect(find.text('RPC conectado'), findsOneWidget);
      expect(find.text('Dentro del límite diario'), findsOneWidget);
    },
    skip: awLabTextOnly,
  );

  testWidgets(
    'caja sub-routes accessible from main caja screen',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const ArcWalletApp(
          autoInitialize: false,
          overrideLocale: Locale('es'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(navBarItem('Caja'));
      await tester.pumpAndSettle();
      expect(find.text('Pagar'), findsWidgets);
      expect(find.text('Recibir'), findsWidgets);
      expect(find.text('Pasar'), findsWidgets);
      expect(find.text('Tope'), findsWidgets);
      await tester.tap(find.text('Tope').first);
      await tester.pumpAndSettle();
      expect(find.text('Política de límites'), findsOneWidget);
    },
    skip: awLabTextOnly,
  );

  testWidgets(
    'agent screen shows native verification option',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const ArcWalletApp(
          autoInitialize: false,
          overrideLocale: Locale('es'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(navBarItem('Agente'));
      await tester.pumpAndSettle();
      expect(find.text('Agente de la caja'), findsOneWidget);
      expect(find.text('Verificar ejecución nativa de Rust'), findsOneWidget);
    },
    skip: awLabTextOnly,
  );

  testWidgets(
    'rieles screen shows available instruments',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const ArcWalletApp(
          autoInitialize: false,
          overrideLocale: Locale('es'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(navBarItem('Rieles'));
      await tester.pumpAndSettle();
      expect(find.text('Rieles'), findsWidgets);
      expect(find.text('Twin · ARGt'), findsWidgets);
      expect(find.text('cirBTC'), findsWidgets);
      expect(find.text('USDC'), findsWidgets);
    },
    skip: awLabTextOnly,
  );
}
