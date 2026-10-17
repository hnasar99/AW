import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/arc.dart';
import '../l10n/app_localizations.dart';
import '../router.dart';
import '../ui/context_bar.dart';
import '../ui/sheets/payment_review_sheet.dart';
import '../ui/theme.dart';

class CajaPayScreen extends StatelessWidget {
  const CajaPayScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(l10n.payTitle),
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
                          l10n.payTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.payDescription,
                          style: const TextStyle(
                            color: FluuixColors.textMuted,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: appState.recipientController,
                          enabled: !appState.busy,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                            labelText: l10n.recipientAddress,
                            hintText: l10n.recipientHint,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: appState.amountController,
                          enabled: !appState.busy,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.amount,
                            suffixText: l10n.balanceUsdc,
                            helperText: l10n.amountHelper,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildLimitsChecklist(context, l10n),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: appState.busy ||
                                    appState.requestPending ||
                                    (appState.walletConnected &&
                                        appState.transferBlocked)
                                ? null
                                : (appState.walletConnected
                                    ? () => _showReviewSheet(context)
                                    : appState.connect),
                            icon: appState.busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.fact_check_outlined),
                            label: Text(
                              appState.busy
                                  ? l10n.processing
                                  : appState.walletConnected
                                      ? l10n.reviewTransfer
                                      : l10n.connectWallet,
                            ),
                          ),
                        ),
                        if (appState.walletConnected && !appState.supportsArc)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: OutlinedButton(
                              onPressed: appState.busy ? null : appState.addArc,
                              child: Text(l10n.requestAddArcTestnet),
                            ),
                          ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () =>
                              appState.open('https://faucet.circle.com/'),
                          child: Text(l10n.getTestUsdc),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.paymentSheetDisclaimer,
                      style: const TextStyle(
                        color: FluuixColors.textMuted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    if (appState.error != null) ...[
                      const SizedBox(height: 14),
                      _errorBox(appState.error!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLimitsChecklist(BuildContext context, AppLocalizations l10n) {
    final amountText = appState.amountController.text;
    BigInt? amount;
    try {
      amount = parseUsdc(amountText);
    } catch (_) {
      amount = null;
    }

    final remaining = appState.ledger?.remaining ?? BigInt.zero;
    final withinLimit =
        amount != null && amount > BigInt.zero && amount <= remaining;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FluuixColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FluuixColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.paymentChecklist,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _checkItem(
            l10n.checkRpcConnected,
            appState.networkVerified,
          ),
          _checkItem(
            l10n.checkWalletConnected,
            appState.walletConnected,
          ),
          _checkItem(
            l10n.checkArcSupported,
            appState.supportsArc,
          ),
          _checkItem(
            l10n.checkWithinLimit,
            withinLimit,
          ),
        ],
      ),
    );
  }

  Widget _checkItem(String label, bool checked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: checked ? FluuixColors.success : FluuixColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: checked ? null : FluuixColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showReviewSheet(BuildContext context) async {
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentReviewSheet(appState: appState),
    );

    if (accepted == true && context.mounted) {
      await appState.reviewAndSend();
    }
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
