import 'package:arc_wallet_flutter/main.dart';
import 'package:arc_wallet_flutter/domain/inference_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'wallet and mission views share state, agent is not falsely ready',
    (tester) async {
      await tester.pumpWidget(const ArcWalletApp(autoInitialize: false));
      expect(find.text('AW · Arc Wallet'), findsOneWidget);
      expect(find.text('Enviar USDC'), findsOneWidget);
      expect(find.text('Conexión pendiente'), findsOneWidget);
      await tester.tap(find.byTooltip('Vista de misiones'));
      await tester.pump();
      expect(find.text('Misiones de verificación'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
      await tester.tap(find.byTooltip('Vista estándar'));
      await tester.pump();
      await tester.tap(find.text('Agente').last);
      await tester.pumpAndSettle();
      expect(find.text('OpenHuman en tu móvil'), findsOneWidget);
      expect(find.text('Verificar ejecución nativa de Rust'), findsOneWidget);
      expect(find.text('OpenHuman local activo'), findsNothing);
    },
    skip: awLabTextOnly,
  );
}
