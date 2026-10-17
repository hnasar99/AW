import 'package:flutter/material.dart';

import 'theme.dart';

/// Always-visible context bar showing current layer, chain status, rail, and wallet.
class FluuixContextBar extends StatelessWidget {
  const FluuixContextBar({
    super.key,
    required this.activeLayer,
    required this.chainName,
    required this.rpcConnected,
    required this.railName,
    required this.walletConnected,
    this.walletAddress,
    this.isTestnet = true,
  });

  final String activeLayer;
  final String chainName;
  final bool rpcConnected;
  final String railName;
  final bool walletConnected;
  final String? walletAddress;
  final bool isTestnet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: FluuixColors.surface,
        border: Border(
          bottom: BorderSide(color: FluuixColors.border),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (isTestnet) ...[
              _TestnetBadge(),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _ContextChip(
                      icon: Icons.layers_outlined,
                      label: activeLayer,
                      color: FluuixColors.lightBlue,
                    ),
                    const SizedBox(width: 6),
                    _ContextChip(
                      icon: rpcConnected
                          ? Icons.link
                          : Icons.link_off,
                      label: chainName,
                      color: rpcConnected
                          ? FluuixColors.success
                          : FluuixColors.warning,
                      statusDot: true,
                      statusColor: rpcConnected
                          ? FluuixColors.success
                          : FluuixColors.error,
                    ),
                    const SizedBox(width: 6),
                    _ContextChip(
                      icon: Icons.account_balance_outlined,
                      label: railName,
                      color: FluuixColors.gold,
                    ),
                    const SizedBox(width: 6),
                    _ContextChip(
                      icon: walletConnected
                          ? Icons.account_balance_wallet
                          : Icons.account_balance_wallet_outlined,
                      label: walletConnected
                          ? _shortenAddress(walletAddress)
                          : 'Disconnected',
                      color: walletConnected
                          ? FluuixColors.success
                          : FluuixColors.textMuted,
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

  String _shortenAddress(String? address) {
    if (address == null || address.length < 12) return 'Connected';
    return '${address.substring(0, 6)}…${address.substring(address.length - 4)}';
  }
}

class _TestnetBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: FluuixColors.testnetBadge,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: FluuixColors.testnetBadge.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.science_outlined,
            size: 14,
            color: Colors.white,
          ),
          SizedBox(width: 4),
          Text(
            'TESTNET',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextChip extends StatelessWidget {
  const _ContextChip({
    required this.icon,
    required this.label,
    required this.color,
    this.statusDot = false,
    this.statusColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool statusDot;
  final Color? statusColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: FluuixColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FluuixColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (statusDot && statusColor != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
