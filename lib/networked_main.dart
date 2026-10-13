import 'package:flutter/material.dart';
import 'domain/inference_config.dart' show awLabTextOnly;
import 'main.dart' as existing;
import 'networks/network_manager_screen.dart';

/// New entry point in AW: network manager plus the existing Arc workspace.
/// The lab remains the original isolated application, with no blockchain client.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(awLabTextOnly ? const existing.ArcWalletApp(showSplash: true) : const FluuixNetworksApp());
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
