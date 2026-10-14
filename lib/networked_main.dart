import 'package:flutter/material.dart';
import 'main.dart' as existing;
import 'networks/network_manager_screen.dart';

/// Entry point for the company treasury. Network reads open from Cuenta.
/// The lab remains the original isolated application, with no blockchain client.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const existing.ArcWalletApp(showSplash: true));
}

class FluuixNetworksApp extends StatelessWidget {
  const FluuixNetworksApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Fluuix · Redes EVM',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffc4b08a), brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xff101017),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    home: NetworkManagerScreen(openArcWorkspace: _openArc),
  );

  void _openArc(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => const existing.WalletHome(),
    ));
  }
}
