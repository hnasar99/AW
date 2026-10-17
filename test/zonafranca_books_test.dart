import 'package:arc_wallet_flutter/domain/inference_config.dart';
import 'package:arc_wallet_flutter/main.dart';
import 'package:arc_wallet_flutter/services/zonafranca_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parser keeps an empty donation list empty', () {
    final snapshot = parseEcosystem({
      'me': {
        'success': true,
        'user': {'email': 'ana@zf.test'},
        'business': {'name': 'Norte'},
        'walletLinked': true,
      },
      'trusts': {
        'success': true,
        'available': true,
        'items': [
          {'status': 'active', 'jurisdiction_code': 'AR', 'vehicle_type': 'trust'},
        ],
      },
      'funds': {
        'success': true,
        'items': [
          {'fund_name': 'Fondo Andino', 'status': 'open', 'current_nav': 12, 'nav_currency': 'USD'},
        ],
      },
      'donations': {'success': true, 'available': false, 'items': []},
      'balances': {
        'success': true,
        'balances': {
          'twin': [
            {'symbol': 'ARGt', 'balance': '40', 'configured': true},
          ],
        },
      },
      'instruments': {
        'success': true,
        'items': [
          {'name': 'Participación Norte', 'symbol': 'NOR', 'status': 'deployed'},
        ],
      },
      'assets': {
        'success': true,
        'items': [
          {'asset_name': 'Lote 4', 'asset_type': 'physical', 'tokenization_status': 'draft'},
        ],
      },
    });
    expect(snapshot.email, 'ana@zf.test');
    expect(snapshot.businessName, 'Norte');
    expect(snapshot.walletLinked, isTrue);
    expect(snapshot.rows('trusts').single.title, 'Fideicomiso AR');
    expect(snapshot.rows('funds').single.title, 'Fondo Andino');
    expect(snapshot.rows('donations'), isEmpty);
    expect(snapshot.rows('balances').single.detail, '40');
    expect(snapshot.rows('instruments').single.title, contains('NOR'));
    expect(snapshot.rows('zone').single.title, 'Lote 4');
  });

  test('a company QR only accepts the fluuix payload', () {
    expect(
      parseCompanyLinkQr(
        '{"type":"fluuix_company_link","token":"abc","api_base":"https://example.test"}',
      )?['token'],
      'abc',
    );
    expect(parseCompanyLinkQr('{"type":"device","token":"abc","api_base":"x"}'), isNull);
    final next = adoptCompanyLink(
      previous: const ZonafrancaSnapshot(signedIn: true, businessName: 'Norte'),
      next: const ZonafrancaSnapshot(signedIn: true, businessName: 'Sur'),
    );
    expect(next.businessName, 'Sur');
  });

  testWidgets('signed-in company fills the live sections', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final snapshot = parseEcosystem({
      'me': {
        'success': true,
        'user': {'email': 'ana@zf.test'},
        'business': {'name': 'Norte'},
        'walletLinked': false,
      },
      'trusts': {
        'success': true,
        'items': [
          {'status': 'active', 'jurisdiction_code': 'AR'},
        ],
      },
      'funds': {
        'success': true,
        'items': [
          {'fund_name': 'Fondo Andino', 'status': 'open'},
        ],
      },
      'donations': {'success': true, 'items': []},
      'balances': {
        'success': true,
        'balances': {
          'twin': [
            {'symbol': 'ARGt', 'balance': '40', 'configured': true},
          ],
        },
      },
      'instruments': {
        'success': true,
        'items': [
          {'name': 'Participación Norte', 'symbol': 'NOR', 'status': 'deployed'},
        ],
      },
      'position': {
        'success': true,
        'accounts': {'wallets': 1, 'banks': 0},
      },
    });

    await tester.pumpWidget(
      ArcWalletApp(autoInitialize: false, zonafrancaPreview: snapshot),
    );
    expect(find.text('Cuentas de la empresa'), findsOneWidget);
    expect(find.textContaining('12,480'), findsNothing);

    await tester.tap(find.byTooltip('Menú'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Cuenta'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('zf-business')), findsOneWidget);
    expect(find.text('ana@zf.test'), findsOneWidget);
    expect(find.text('Norte'), findsOneWidget);
    expect(
      find.textContaining('no está en la empresa'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Menú'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Cajas'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Fideicomiso'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Fideicomiso AR'), findsOneWidget);
    expect(find.text('Conectá Zonafranca'), findsNothing);

    await tester.tap(find.byTooltip('Menú'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Donación'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('No hay movimientos.'), findsOneWidget);
    expect(find.textContaining('12,480'), findsNothing);

    await tester.tap(find.byTooltip('Menú'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Riel local'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('ARGt'), findsOneWidget);
    expect(find.text('40'), findsOneWidget);

    await tester.tap(find.byTooltip('Menú'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Tokenización'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('TTN'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Participación Norte'), findsOneWidget);
  }, skip: awLabTextOnly);

  testWidgets('connecting another company drops the previous books', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final norte = parseEcosystem({
      'me': {
        'success': true,
        'user': {'email': 'ana@zf.test'},
        'business': {'name': 'Norte'},
      },
      'trusts': {
        'success': true,
        'items': [
          {'status': 'active', 'jurisdiction_code': 'AR'},
        ],
      },
    });
    final sur = parseEcosystem({
      'me': {
        'success': true,
        'user': {'email': 'sol@zf.test'},
        'business': {'name': 'Sur'},
      },
      'trusts': {'success': true, 'items': []},
    });

    await tester.pumpWidget(
      ArcWalletApp(
        autoInitialize: false,
        zonafrancaPreview: norte,
        linkedPreview: sur,
        redeemCompanyLink: (_) async => const ZonafrancaSession(
          accessToken: 'access',
          refreshToken: 'refresh',
          email: 'sol@zf.test',
          apiBase: suggestedZonafrancaApiBase,
          anonKey: suggestedZonafrancaAnonKey,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Menú'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Cuenta'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Norte'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('zf-qr-payload')),
      '{"type":"fluuix_company_link","token":"abc","api_base":"https://example.test/functions/v1/ecosystem-api"}',
    );
    await tester.tap(find.byKey(const Key('zf-qr-connect')));
    await tester.pump();
    await tester.pump();

    expect(find.text('Sur'), findsOneWidget);
    expect(find.text('sol@zf.test'), findsOneWidget);
    expect(find.text('Norte'), findsNothing);
    expect(find.text('Fideicomiso AR'), findsNothing);

    await tester.tap(find.text('Cerrar sesión de Zonafranca'));
    await tester.pump();
    expect(find.text('Sur'), findsNothing);
    expect(find.text('Conectar con QR'), findsOneWidget);
  }, skip: awLabTextOnly);

  testWidgets('a failed QR leaves the phone without the previous company', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const norte = ZonafrancaSnapshot(signedIn: true, businessName: 'Norte', email: 'ana@zf.test');
    await tester.pumpWidget(
      ArcWalletApp(
        autoInitialize: false,
        zonafrancaPreview: norte,
        redeemCompanyLink: (_) async => throw const ZonafrancaException('QR vencido'),
      ),
    );
    await tester.tap(find.byTooltip('Menú'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Cuenta'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(find.byKey(const Key('zf-qr-payload')), '{"type":"fluuix_company_link","token":"abc","api_base":"https://example.test"}');
    await tester.tap(find.byKey(const Key('zf-qr-connect')));
    await tester.pump();
    await tester.pump();
    expect(find.text('Norte'), findsNothing);
    expect(find.text('QR vencido'), findsOneWidget);
  }, skip: awLabTextOnly);
}
