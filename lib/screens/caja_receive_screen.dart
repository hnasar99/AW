import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../l10n/app_localizations.dart';
import '../router.dart';
import '../ui/context_bar.dart';
import '../ui/theme.dart';

class CajaReceiveScreen extends StatelessWidget {
  const CajaReceiveScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(l10n.receiveTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/caja'),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              FluuixContextBar(
                activeLayer: l10n.navCaja,
                chainName: 'Arc Testnet',
                rpcConnected: appState.networkVerified,
                railName: 'Twin · ARGt',
                walletConnected: appState.walletConnected,
                walletAddress: appState.walletAddress,
                isTestnet: true,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _card(
                      children: [
                        Text(
                          l10n.receiveTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        if (appState.walletAddress == null)
                          Text(
                            l10n.receiveConnectPrompt,
                            style: TextStyle(
                              color: FluuixColors.textMuted,
                              height: 1.4,
                            ),
                          )
                        else ...[
                          Text(
                            l10n.receiveDescription,
                            style: TextStyle(
                              color: FluuixColors.textMuted,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: QrImageView(
                                data: appState.walletAddress!,
                                size: 200,
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: FluuixColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              appState.walletAddress!,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                        if (appState.walletAddress == null) ...[
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: appState.busy ? null : appState.connect,
                            child: Text(l10n.connectWallet),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: FluuixColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: FluuixColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}
