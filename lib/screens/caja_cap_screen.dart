import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/arc.dart';
import '../domain/treasury_policy.dart';
import '../l10n/app_localizations.dart';
import '../router.dart';
import '../ui/context_bar.dart';
import '../ui/theme.dart';

class CajaCapScreen extends StatelessWidget {
  const CajaCapScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(l10n.capTitle),
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
                          l10n.capTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _limitRow(
                          l10n.perPaymentCap(
                            formatUnits(TreasuryPolicy.perPayment, 6),
                          ),
                          Icons.payment,
                        ),
                        const SizedBox(height: 8),
                        _limitRow(
                          l10n.perDayCap(
                            formatUnits(TreasuryPolicy.perDay, 6),
                          ),
                          Icons.today,
                        ),
                        const Divider(height: 24),
                        _usageRow(
                          l10n.usedToday(
                            formatUnits(
                              appState.ledger?.forToday()?.spent ?? BigInt.zero,
                              6,
                            ),
                          ),
                          FluuixColors.warning,
                        ),
                        const SizedBox(height: 8),
                        _usageRow(
                          l10n.remainingToday(
                            formatUnits(
                              appState.ledger?.remaining ?? BigInt.zero,
                              6,
                            ),
                          ),
                          FluuixColors.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _card(
                      children: [
                        Text(
                          l10n.capPolicyTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.capPolicyExplanation,
                          style: const TextStyle(
                            color: FluuixColors.textMuted,
                            fontSize: 14,
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

  Widget _limitRow(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: FluuixColors.lightBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _usageRow(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
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
