import 'package:arc_wallet_flutter/main.dart';
import 'package:arc_wallet_flutter/domain/inference_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'treasury menu opens screens and does not invent balances',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const ArcWalletApp(autoInitialize: false));
      expect(find.text('Dashboard'), findsWidgets);
      expect(
        find.descendant(
          of: find.byKey(const Key('treasury-body')),
          matching: find.text('Caja en dólares'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('treasury-body')),
          matching: find.text('Fideicomiso'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('treasury-body')),
          matching: find.text('Tokenización'),
        ),
        findsNothing,
      );
      expect(find.text('Pagar'), findsWidgets);
      expect(find.textContaining('12,480'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      expect(find.textContaining('APY'), findsNothing);

      await tester.tap(find.byTooltip('Menú'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cajas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fideicomiso'));
      await tester.pumpAndSettle();
      expect(
        find.text('Captar y distribuir con escrow fiduciario.'),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('treasury-body')),
          matching: find.text('Donación'),
        ),
        findsNothing,
      );
      expect(find.text('Sin lectura'), findsWidgets);

      await tester.tap(find.byTooltip('Menú'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tesorería'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Conversión a USDC'));
      await tester.pumpAndSettle();
      expect(find.textContaining('no está conectado'), findsOneWidget);

      await tester.tap(find.byTooltip('Menú'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fluuix'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Asistente'));
      await tester.pumpAndSettle();
      expect(find.text('Asistente'), findsWidgets);
      expect(find.text('Verificar ejecución nativa de Rust'), findsOneWidget);
      expect(find.text('OpenHuman local activo'), findsNothing);
      expect(find.textContaining('12,480'), findsNothing);
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
      expect(
        find.descendant(
          of: find.byKey(const Key('treasury-body')),
          matching: find.text('Caja en dólares'),
        ),
        findsOneWidget,
      );
    },
    skip: awLabTextOnly,
  );
}
