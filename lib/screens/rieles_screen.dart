import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../router.dart';
import '../ui/context_bar.dart';
import '../ui/theme.dart';

class RielesScreen extends StatelessWidget {
  const RielesScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) => SafeArea(
        child: Column(
          children: [
            FluuixContextBar(
              activeLayer: l10n.navRieles,
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
                  Text(
                    l10n.rielesTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.rielesDescription,
                    style: TextStyle(color: FluuixColors.textMuted, height: 1.45),
                  ),
                  const SizedBox(height: 24),
                  _buildRailCard(
                    context,
                    l10n,
                    title: 'Twin · ARGt',
                    subtitle: l10n.localRail,
                    icon: Icons.account_balance,
                    isActive: true,
                  ),
                  const SizedBox(height: 12),
                  _buildRailCard(
                    context,
                    l10n,
                    title: 'cirBTC',
                    subtitle: l10n.reserve,
                    icon: Icons.savings,
                    isActive: false,
                  ),
                  const SizedBox(height: 12),
                  _buildRailCard(
                    context,
                    l10n,
                    title: 'USDC',
                    subtitle: l10n.rielUsdcNative,
                    icon: Icons.monetization_on,
                    isActive: true,
                  ),
                  const SizedBox(height: 24),
                  _card(
                    children: [
                      Text(
                        l10n.rielesHowItWorks,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.rielesExplanation,
                        style: TextStyle(
                          color: FluuixColors.textMuted,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.footerArcTestnet,
                    style: TextStyle(
                      color: FluuixColors.textMuted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRailCard(
    BuildContext context,
    AppLocalizations l10n, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isActive,
  }) {
    return _card(
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isActive
                    ? FluuixColors.gold.withValues(alpha: 0.2)
                    : FluuixColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isActive ? FluuixColors.gold : FluuixColors.textMuted,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: FluuixColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? FluuixColors.success.withValues(alpha: 0.2)
                    : FluuixColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isActive ? l10n.rielActive : l10n.noContract,
                style: TextStyle(
                  color: isActive ? FluuixColors.success : FluuixColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
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
