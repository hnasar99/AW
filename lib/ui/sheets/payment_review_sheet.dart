import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/arc.dart';
import '../../l10n/app_localizations.dart';
import '../../router.dart';
import '../theme.dart';

class PaymentReviewSheet extends StatefulWidget {
  const PaymentReviewSheet({super.key, required this.appState});

  final AppState appState;

  @override
  State<PaymentReviewSheet> createState() => _PaymentReviewSheetState();
}

class _PaymentReviewSheetState extends State<PaymentReviewSheet> {
  static const _expiryDuration = Duration(minutes: 2);
  late DateTime _expiresAt;
  Timer? _timer;
  Duration _remaining = _expiryDuration;

  @override
  void initState() {
    super.initState();
    _expiresAt = DateTime.now().add(_expiryDuration);
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  void _tick(Timer timer) {
    final now = DateTime.now();
    if (now.isAfter(_expiresAt)) {
      timer.cancel();
      if (mounted) {
        Navigator.of(context).pop(false);
      }
      return;
    }
    setState(() {
      _remaining = _expiresAt.difference(now);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final amountText = widget.appState.amountController.text;
    BigInt units;
    try {
      units = parseUsdc(amountText);
    } catch (_) {
      units = BigInt.zero;
    }

    final recipient = widget.appState.recipientController.text;
    final sender = widget.appState.walletAddress ?? '';
    final remaining = widget.appState.ledger?.remaining ?? BigInt.zero;
    final withinLimit = units > BigInt.zero && units <= remaining;

    return Container(
      decoration: const BoxDecoration(
        color: FluuixColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: FluuixColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.reviewTransferTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  _buildCountdown(),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: FluuixColors.testnetBadge.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.arcTestnetTestFunds,
                  style: const TextStyle(
                    color: FluuixColors.testnetBadge,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Text(
                      '${formatUnits(units, 6)} USDC',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Arc Testnet',
                      style: TextStyle(
                        color: FluuixColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildInfoRow(l10n.from, sender, Icons.account_balance_wallet),
              const SizedBox(height: 12),
              _buildInfoRow(l10n.recipient, recipient, Icons.person),
              const SizedBox(height: 12),
              _buildInfoRow(
                l10n.sheetChainRail,
                'Arc Testnet · Twin · ARGt',
                Icons.hub,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _checkItem(l10n.checkRpcConnected, widget.appState.networkVerified),
                    _checkItem(l10n.checkWalletConnected, widget.appState.walletConnected),
                    _checkItem(l10n.checkArcSupported, widget.appState.supportsArc),
                    _checkItem(l10n.checkWithinLimit, withinLimit),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FluuixColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: FluuixColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: FluuixColors.warning, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.sheetNoAuthNoSign,
                        style: const TextStyle(
                          color: FluuixColors.warning,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.reviewExpiry,
                style: const TextStyle(
                  color: FluuixColors.textMuted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _remaining.inSeconds > 0
                          ? () => Navigator.of(context).pop(true)
                          : null,
                      child: Text(l10n.requestApproval),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdown() {
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;
    final isLow = _remaining.inSeconds < 30;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isLow
            ? FluuixColors.error.withValues(alpha: 0.2)
            : FluuixColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLow ? FluuixColors.error : FluuixColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 16,
            color: isLow ? FluuixColors.error : FluuixColors.textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: isLow ? FluuixColors.error : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: FluuixColors.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: FluuixColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(
                value,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
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
}
