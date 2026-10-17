import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/arc.dart';
import '../l10n/app_localizations.dart';
import '../router.dart';
import '../ui/context_bar.dart';
import '../ui/theme.dart';

class CajaScreen extends StatelessWidget {
  const CajaScreen({super.key, required this.appState});

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
              activeLayer: l10n.navCaja,
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
                    _buildBalanceCard(context, l10n),
                    const SizedBox(height: 12),
                    _buildRailsRow(context, l10n),
                    const SizedBox(height: 16),
                    _buildActionsRow(context, l10n),
                    const SizedBox(height: 20),
                    _buildActivitySection(context, l10n),
                    if (appState.requestUncertain) ...[
                      const SizedBox(height: 16),
                      _buildUnresolvedCard(context, l10n),
                    ],
                    if (appState.error != null) ...[
                      const SizedBox(height: 14),
                      _errorBox(appState.error!),
                    ],
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

  Widget _buildBalanceCard(BuildContext context, AppLocalizations l10n) {
    return _card(
      children: [
        Text(
          l10n.cajaEnDolares,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          appState.networkVerified ? l10n.rpcVerified : l10n.connectionPending,
          style: const TextStyle(color: FluuixColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Text(
          appState.balance == null
              ? '—'
              : formatUnits(appState.balance!, 18, places: 6),
          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700),
        ),
        Text(
          l10n.balanceUsdc,
          style: const TextStyle(color: FluuixColors.gold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.arcTestnetSingleBalance,
          style: const TextStyle(
            color: FluuixColors.textMuted,
            fontSize: 12,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _statusChip(
              appState.networkVerified ? l10n.arcVerified : l10n.arcNotVerified,
              appState.networkVerified,
            ),
            _statusChip(
              appState.walletConnected ? l10n.sessionActive : l10n.noSession,
              appState.walletConnected,
            ),
            _statusChip(
              l10n.remainingCapLabel(
                formatUnits(appState.ledger?.remaining ?? BigInt.zero, 6),
              ),
              (appState.ledger?.remaining ?? BigInt.zero) > BigInt.zero,
            ),
          ],
        ),
        if (appState.walletAddress != null) ...[
          const Divider(height: 28),
          SelectableText(appState.walletAddress!),
          Text(
            l10n.sessionOnArcTestnet(appState.chainId?.toString() ?? '?'),
            style: const TextStyle(color: FluuixColors.textMuted, fontSize: 12),
          ),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: appState.busy ? null : appState.disconnect,
                child: Text(l10n.disconnect),
              ),
              TextButton(
                onPressed: () => appState.open(
                  '${ArcNetwork.explorer}/address/${appState.walletAddress}',
                ),
                child: Text(l10n.viewAccount),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildRailsRow(BuildContext context, AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _railCard(l10n.localRail, 'Twin · ARGt', l10n)),
        const SizedBox(width: 12),
        Expanded(child: _railCard(l10n.reserve, 'cirBTC', l10n)),
      ],
    );
  }

  Widget _railCard(String title, String instrument, AppLocalizations l10n) =>
      _card(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(instrument, style: const TextStyle(color: FluuixColors.textMuted)),
          const SizedBox(height: 8),
          Text(l10n.noContract, style: const TextStyle(color: FluuixColors.gold)),
          const SizedBox(height: 4),
          Text(
            l10n.notAddedToBox,
            style: const TextStyle(color: FluuixColors.textMuted, fontSize: 12),
          ),
        ],
      );

  Widget _buildActionsRow(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            context,
            icon: Icons.send,
            label: l10n.pay,
            onTap: () => context.go('/caja/pagar'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _actionButton(
            context,
            icon: Icons.qr_code,
            label: l10n.receive,
            onTap: () => context.go('/caja/recibir'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _actionButton(
            context,
            icon: Icons.swap_horiz,
            label: l10n.passage,
            onTap: () => context.go('/caja/pasar'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _actionButton(
            context,
            icon: Icons.speed,
            label: l10n.cap,
            onTap: () => context.go('/caja/tope'),
          ),
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

  Widget _buildActivitySection(BuildContext context, AppLocalizations l10n) {
    final savedReceipts = _getSavedReceipts();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.activity, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (appState.transaction == null && savedReceipts.isEmpty)
          Text(
            l10n.noReceiptSaved,
            style: const TextStyle(color: FluuixColors.textMuted),
          )
        else ...[
          Text(
            l10n.hashIsReceipt,
            style: const TextStyle(color: FluuixColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (appState.transaction != null) _transactionCard(context, l10n),
          ...savedReceipts.map((h) => _savedReceiptCard(h, l10n)),
        ],
      ],
    );
  }

  List<String> _getSavedReceipts() {
    final current = appState.transaction?.hash?.toLowerCase();
    final hashes = appState.ledger?.forToday()?.hashes ?? <String>[];
    return hashes.where((hash) => hash != current).toList()..sort();
  }

  Widget _transactionCard(BuildContext context, AppLocalizations l10n) {
    final result = appState.transaction!;
    final state = result.state as TransactionState;
    final label = switch (state) {
      TransactionState.submitted => l10n.txSubmitted,
      TransactionState.confirmed => l10n.txConfirmed,
      TransactionState.reverted => l10n.txReverted,
      TransactionState.pending => l10n.txPending,
      TransactionState.unknown => l10n.txUnknown,
    };
    return _card(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SelectableText(result.hash),
        if (result.blockNumber != null)
          Text(l10n.blockLabel(result.blockNumber.toString())),
        Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: () => appState.open(
                '${ArcNetwork.explorer}/tx/${result.hash}',
              ),
              child: Text(l10n.openExplorer),
            ),
          ],
        ),
      ],
    );
  }

  Widget _savedReceiptCard(String hash, AppLocalizations l10n) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: _card(
      children: [
        Text(l10n.confirmed, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SelectableText(hash),
        TextButton(
          onPressed: () => appState.open('${ArcNetwork.explorer}/tx/$hash'),
          child: Text(l10n.openExplorer),
        ),
      ],
    ),
  );

  Widget _buildUnresolvedCard(BuildContext context, AppLocalizations l10n) {
    return _card(
      children: [
        Text(
          l10n.unresolvedRequest,
          style: const TextStyle(
            color: FluuixColors.warning,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(l10n.checkWalletHistory),
        const SizedBox(height: 10),
        TextField(
          controller: appState.recoverHashController,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l10n.transactionHashLabel,
          ),
        ),
        TextButton(
          onPressed: appState.recoverTransaction,
          child: Text(l10n.checkHash),
        ),
        TextButton(
          onPressed: appState.requestPending ? null : appState.acknowledgeNoSend,
          child: Text(l10n.requestCancelledOrRejected),
        ),
      ],
    );
  }

  Widget _statusChip(String label, bool on) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: FluuixColors.surfaceElevated,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: on ? FluuixColors.success : FluuixColors.border,
      ),
    ),
    child: Text(label, style: const TextStyle(fontSize: 12)),
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

  Widget _errorBox(String message) => Container(
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
  );
}
