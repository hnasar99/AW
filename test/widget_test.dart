import 'package:flutter_test/flutter_test.dart';
import 'package:arc_wallet_flutter/main.dart';

void main() {
  testWidgets('renders Arc wallet shell', (tester) async {
    await tester.pumpWidget(const ArcWalletApp());
    expect(find.text('Arc Wallet'), findsOneWidget);
    expect(find.text('Send USDC'), findsOneWidget);
  });
}
