import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/arc.dart';
import '../l10n/app_localizations.dart';
import '../router.dart';
import '../ui/context_bar.dart';
import '../ui/theme.dart';

enum _LayerState { active, partial, sinContrato }

class _LayerData {
  const _LayerData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.state,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final _LayerState state;
  final VoidCallback onTap;
}

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
                      style: const TextStyle(
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
                    style: const TextStyle(
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
            style: const TextStyle(
              color: FluuixColors.gold,
              fontSize: 16,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLayersSection(BuildContext context, AppLocalizations l10n) {
    final layers = <_LayerData>[
      _LayerData(
        icon: Icons.psychology,
        title: l10n.homeLayerAgentes,
        subtitle: l10n.homeLayerAgentesDesc,
        color: FluuixColors.success,
        state: appState.agentReady
            ? _LayerState.active
            : _LayerState.partial,
        onTap: () => context.go('/agente'),
      ),
      _LayerData(
        icon: Icons.swap_horiz,
        title: l10n.homeLayerRieles,
        subtitle: l10n.homeLayerRielesDesc,
        color: FluuixColors.lightBlue,
        state: _LayerState.active,
        onTap: () => context.go('/rieles'),
      ),
      _LayerData(
        icon: Icons.description,
        title: l10n.homeLayerContratos,
        subtitle: l10n.homeLayerContratosDesc,
        color: FluuixColors.textMuted,
        state: _LayerState.sinContrato,
        onTap: () => context.go('/mas'),
      ),
      _LayerData(
        icon: Icons.account_balance_wallet,
        title: l10n.homeLayerWallets,
        subtitle: l10n.homeLayerWalletsDesc,
        color: FluuixColors.gold,
        state: appState.walletConnected
            ? _LayerState.active
            : _LayerState.partial,
        onTap: () => context.go('/caja'),
      ),
      _LayerData(
        icon: Icons.check_circle_outline,
        title: l10n.homeLayerSettlement,
        subtitle: l10n.homeLayerSettlementDesc,
        color: FluuixColors.textMuted,
        state: _LayerState.sinContrato,
        onTap: () => context.go('/mas'),
      ),
      _LayerData(
        icon: Icons.hub,
        title: l10n.homeLayerMultichain,
        subtitle: l10n.homeLayerMultichainDesc,
        color: FluuixColors.textMuted,
        state: _LayerState.sinContrato,
        onTap: () => context.go('/mas'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homeLayers,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < layers.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _layerCardFromData(context, layers[i], l10n)),
              const SizedBox(width: 12),
              if (i + 1 < layers.length)
                Expanded(child: _layerCardFromData(context, layers[i + 1], l10n))
              else
                const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ],
    );
  }

  Widget _layerCardFromData(BuildContext context, _LayerData data, AppLocalizations l10n) {
    final stateColor = switch (data.state) {
      _LayerState.active => FluuixColors.success,
      _LayerState.partial => FluuixColors.gold,
      _LayerState.sinContrato => FluuixColors.textMuted,
    };
    final stateText = switch (data.state) {
      _LayerState.active => l10n.layerStateActive,
      _LayerState.partial => l10n.layerStatePartial,
      _LayerState.sinContrato => l10n.noContract,
    };
    final iconColor = data.state == _LayerState.sinContrato
        ? FluuixColors.textMuted
        : data.color;

    return Material(
      color: FluuixColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: data.onTap,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(data.icon, color: iconColor, size: 22),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: stateColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      stateText,
                      style: TextStyle(
                        color: stateColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                data.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.subtitle,
                style: const TextStyle(
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
