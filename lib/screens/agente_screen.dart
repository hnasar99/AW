import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/arc.dart';
import '../domain/inference_config.dart';
import '../l10n/app_localizations.dart';
import '../router.dart';
import '../ui/context_bar.dart';
import '../ui/sheets/agent_proposal_sheet.dart';
import '../ui/theme.dart';

class AgenteScreen extends StatelessWidget {
  const AgenteScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) => SafeArea(
        child: Column(
          children: [
            if (!awLabTextOnly)
              FluuixContextBar(
                activeLayer: l10n.navAgente,
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
                  if (awLabTextOnly) ...[
                    _labBanner(l10n),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    awLabTextOnly ? l10n.agentLabTitle : l10n.agentBoxTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(_getAgentStatusText(l10n)),
                  const SizedBox(height: 10),
                  Text(
                    awLabTextOnly
                        ? l10n.agentLabDescription
                        : l10n.agentDescription,
                    style: const TextStyle(color: FluuixColors.textMuted, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: appState.agentBusy ? null : appState.probeNative,
                    icon: const Icon(Icons.memory),
                    label: Text(l10n.verifyNativeRust),
                  ),
                  if (appState.nativeStatus != null) ...[
                    const SizedBox(height: 10),
                    _buildNativeStatusCard(context, l10n),
                  ],
                  const SizedBox(height: 16),
                  if (!appState.agentReady)
                    FilledButton(
                      onPressed: () => context.go('/mas'),
                      child: Text(
                        awLabTextOnly
                            ? l10n.configureLabButton
                            : l10n.configureProviderButton,
                      ),
                    ),
                  if (appState.agentReady) ...[
                    _buildQuerySection(context, l10n),
                  ],
                  if (appState.agentReply != null) ...[
                    const SizedBox(height: 18),
                    _buildReplySection(context, l10n),
                  ],
                  if (appState.agentError != null) _errorBox(appState.agentError!),
                  if (appState.nativeStatus?.requiresReset == true ||
                      (awLabTextOnly &&
                          appState.nativeStatus?.initialized == true &&
                          !appState.agentReady))
                    OutlinedButton(
                      onPressed:
                          appState.agentBusy ? null : appState.resetAgent,
                      child: Text(l10n.restartAfterInterrupted),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    awLabTextOnly ? l10n.footerLab : l10n.footerArcTestnet,
                    style: const TextStyle(
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

  String _getAgentStatusText(AppLocalizations l10n) {
    final status = appState.nativeStatus;
    if (status == null) return l10n.agentVerifyStatus;

    if (appState.agentReady) {
      if (awLabTextOnly) {
        return l10n.labReadyStatus(
          appState.endpointController.text.trim(),
          appState.modelController.text.trim(),
        );
      }
      return l10n.openHumanLocalActive(
        Uri.tryParse(appState.endpointController.text)?.host ?? 'provider',
      );
    }

    return l10n.rustExecutedStatus(status.os, status.arch);
  }

  Widget _buildNativeStatusCard(BuildContext context, AppLocalizations l10n) {
    final status = appState.nativeStatus!;
    return _card(
      children: [
        Text(l10n.libraryExecuted(status.os, status.arch)),
        Text('OpenHuman ${shorten(status.commit)}'),
        if (status.initialized)
          Text(l10n.allowedTools(
            status.tools.isEmpty ? l10n.noTools : status.tools.join(', '),
          ))
        else
          Text(l10n.runtimeNotInitialized),
        if (awLabTextOnly && status.initialized)
          Text(l10n.nativePolicy(status.mode ?? l10n.notStarted)),
        if (awLabTextOnly && status.labContextTokens != null)
          Text(l10n.agentBudget(status.labContextTokens.toString())),
        Text(
          awLabTextOnly ? l10n.labTestDisclaimer : l10n.localTestDisclaimer,
          style: const TextStyle(color: FluuixColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildQuerySection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: appState.promptController,
          minLines: 3,
          maxLines: 8,
          enabled: !appState.agentBusy,
          decoration: InputDecoration(labelText: l10n.queryLabel),
        ),
        const SizedBox(height: 10),
        if (!awLabTextOnly)
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: Text(l10n.presetArcStatus),
                onPressed: appState.agentBusy
                    ? null
                    : () => appState.promptController.text =
                        'Usá arc_network_status y explicame el estado real de Arc Testnet.',
              ),
              if (appState.walletAddress != null)
                ActionChip(
                  label: Text(l10n.presetMyBalance),
                  onPressed: appState.agentBusy
                      ? null
                      : () => appState.promptController.text =
                          'Usá arc_balance para consultar el saldo USDC de ${appState.walletAddress} en Arc Testnet. Explicá que es el mismo saldo que paga gas.',
                ),
            ],
          ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: appState.agentBusy ? null : appState.askAgent,
          icon: const Icon(Icons.psychology_outlined),
          label: Text(appState.agentBusy ? l10n.agentWorking : l10n.queryOpenHuman),
        ),
        if (appState.agentBusy) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
          TextButton(
            onPressed: appState.cancelAgent,
            child: Text(l10n.cancelTurn),
          ),
        ],
      ],
    );
  }

  Widget _buildReplySection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          children: [
            if (!awLabTextOnly) ...[
              Text(
                l10n.modelText,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
            ],
            SelectableText(
              appState.agentReply!,
              style: const TextStyle(height: 1.5),
            ),
          ],
        ),
        if (!awLabTextOnly)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.modelTextDisclaimer,
              style: const TextStyle(color: FluuixColors.textMuted, fontSize: 12),
            ),
          ),
        if (!awLabTextOnly && appState.toolCalls.isNotEmpty)
          Text(l10n.toolsExecuted(appState.toolCalls.join(', '))),
        if (!awLabTextOnly)
          ...appState.liveReads.map(
            (read) => Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _buildLiveReadCard(read, l10n),
            ),
          ),
        if (!awLabTextOnly && appState.proposal != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: appState.busy
                  ? null
                  : () => _showProposalSheet(context),
              icon: const Icon(Icons.assignment_return_outlined),
              label: Text(l10n.applyProposal),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          awLabTextOnly
              ? l10n.labResponseDisclaimer
              : l10n.agentResponseDisclaimer,
          style: const TextStyle(color: FluuixColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildLiveReadCard(dynamic read, AppLocalizations l10n) {
    return _card(
      children: [
        Text(
          l10n.liveReadTool(read.tool),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        if (read.result['block_number'] != null)
          Text(l10n.blockNumber(read.result['block_number'].toString())),
        if (read.result['balance_usdc'] != null)
          Text(l10n.balanceUsdcLabel(read.result['balance_usdc'].toString())),
        if (read.result['observed_at_unix'] != null)
          Text(l10n.observationUnix(read.result['observed_at_unix'].toString())),
        Text(
          read.result['ok'] == true ? l10n.toolResultOk : l10n.toolResultFailed,
        ),
      ],
    );
  }

  Future<void> _showProposalSheet(BuildContext context) async {
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AgentProposalSheet(appState: appState),
    );

    if (accepted == true && context.mounted) {
      appState.applyProposal();
      context.go('/caja/pagar');
    }
  }

  Widget _labBanner(AppLocalizations l10n) => _card(
    children: [
      Text(
        l10n.labBannerTitle,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Text(l10n.labBannerDesc),
    ],
  );

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

  Widget _errorBox(String message) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FluuixColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FluuixColors.error.withValues(alpha: 0.3)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: FluuixColors.error, height: 1.4),
      ),
    ),
  );
}
