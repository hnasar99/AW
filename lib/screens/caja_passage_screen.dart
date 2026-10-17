import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../router.dart';
import '../ui/context_bar.dart';
import '../ui/theme.dart';

class CajaPassageScreen extends StatelessWidget {
  const CajaPassageScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(l10n.passageTitle),
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
                          l10n.passageTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: FluuixColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: FluuixColors.warning.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: FluuixColors.warning,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l10n.passageNotConnected,
                                  style: TextStyle(
                                    color: FluuixColors.textMuted,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.passageComingSoon,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.passageDescription,
                          style: TextStyle(
                            color: FluuixColors.textMuted,
                            height: 1.45,
                          ),
                        ),
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
