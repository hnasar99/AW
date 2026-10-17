import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/arc.dart';
import '../l10n/app_localizations.dart';
import '../router.dart';
import '../ui/context_bar.dart';
import '../ui/theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.appState});

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
              activeLayer: l10n.navInicio,
              chainName: 'Arc Testnet',
              rpcConnected: appState.networkVerified,
              railName: 'Twin · ARGt',
              walletConnected: appState.walletConnected,
              walletAddress: appState.walletAddress,
              isTestnet: true,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await appState.checkNetwork();
                  await appState.refreshBalance();
                },
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildWelcomeCard(context, l10n),
                    const SizedBox(height: 16),
                    _buildLayersSection(context, l10n),
                    const SizedBox(height: 16),
                    _buildQuickActionsCard(context, l10n),
                    const SizedBox(height: 16),
                    _buildStatusCard(context, l10n),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, AppLocalizations l10n) {
    return _card(
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: FluuixColors.gold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: FluuixColors.gold,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.homeWelcome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appState.walletConnected
                        ? l10n.homeConnectedStatus
                        : l10n.homeDisconnectedStatus,
                    style: TextStyle(
                      color: FluuixColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (appState.walletConnected && appState.balance != null) ...[
          const SizedBox(height: 16),
          Text(
            formatUnits(appState.balance!, 18, places: 6),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            l10n.balanceUsdc,
            style: TextStyle(
              color: FluuixColors.gold,
              fontSize: 16,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLayersSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homeLayers,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _layerCard(
                context,
                icon: Icons.account_balance_wallet,
                title: l10n.navCaja,
                subtitle: l10n.homeLayerCajaDesc,
                color: FluuixColors.gold,
                onTap: () => context.go('/caja'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _layerCard(
                context,
                icon: Icons.swap_horiz,
                title: l10n.navRieles,
                subtitle: l10n.homeLayerRielesDesc,
                color: FluuixColors.lightBlue,
                onTap: () => context.go('/rieles'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _layerCard(
                context,
                icon: Icons.psychology,
                title: l10n.navAgente,
                subtitle: l10n.homeLayerAgenteDesc,
                color: FluuixColors.success,
                onTap: () => context.go('/agente'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _layerCard(
                context,
                icon: Icons.hub,
                title: l10n.homeLayerRedTitle,
                subtitle: l10n.homeLayerRedDesc,
                color: FluuixColors.navy,
                onTap: () => context.go('/mas'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _layerCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: FluuixColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FluuixColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: FluuixColors.textMuted,
                  fontSize: 12,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context, AppLocalizations l10n) {
    return _card(
      children: [
        Text(
          l10n.homeQuickActions,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _actionButton(
                context,
                icon: Icons.send,
                label: l10n.pay,
                onTap: () => context.go('/caja/pagar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _actionButton(
                context,
                icon: Icons.qr_code,
                label: l10n.receive,
                onTap: () => context.go('/caja/recibir'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _actionButton(
                context,
                icon: Icons.psychology,
                label: l10n.homeAskAgent,
                onTap: () => context.go('/agente'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: FluuixColors.surfaceElevated,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: FluuixColors.lightBlue),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, AppLocalizations l10n) {
    final steps = <(String, bool)>[
      (l10n.orderVerifyArc, appState.networkVerified),
      (l10n.orderExecuteRust, appState.nativeStatus != null),
      (l10n.orderActivateOpenHuman, appState.agentReady),
      (l10n.orderConnectArcAccount, appState.supportsArc),
    ];

    return _card(
      children: [
        Text(
          l10n.homeSystemStatus,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ...steps.map(
          (step) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  step.$2 ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 18,
                  color: step.$2 ? FluuixColors.success : FluuixColors.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(step.$1, style: const TextStyle(fontSize: 14))),
              ],
            ),
          ),
        ),
        if (!appState.walletConnected) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: appState.busy ? null : appState.connect,
              child: Text(l10n.connectWallet),
            ),
          ),
        ],
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
