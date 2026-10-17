part of '../main.dart';

enum CajaPanel { pay, receive, passage, cap }

extension _CajaView on _WalletHomeState {
  List<Widget> _cajaView(AppLocalizations l10n) => [
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card(
          children: [
            Text(
              l10n.cajaEnDolares,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              _getNetworkStatusText(l10n),
              style: const TextStyle(color: FluuixColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Text(
              _balance == null ? '—' : formatUnits(_balance!, 18, places: 6),
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
                  _networkVerified ? l10n.arcVerified : l10n.arcNotVerified,
                  _networkVerified,
                ),
                _statusChip(
                  _wallet.connected ? l10n.sessionActive : l10n.noSession,
                  _wallet.connected,
                ),
                _statusChip(
                  l10n.remainingCapLabel(formatUnits(_ledger.remaining, 6)),
                  _ledger.remaining > BigInt.zero,
                ),
              ],
            ),
            if (_wallet.address != null) ...[
              const Divider(height: 28),
              SelectableText(_wallet.address!),
              Text(
                l10n.sessionOnArcTestnet(_wallet.chainId?.toString() ?? '?'),
                style: const TextStyle(color: FluuixColors.textMuted, fontSize: 12),
              ),
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: _busy ? null : _disconnect,
                    child: Text(l10n.disconnect),
                  ),
                  TextButton(
                    onPressed: () => _open(
                      '${ArcNetwork.explorer}/address/${_wallet.address}',
                    ),
                    child: Text(l10n.viewAccount),
                  ),
                ],
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _railCard(l10n.localRail, 'Twin · ARGt', l10n)),
            const SizedBox(width: 12),
            Expanded(child: _railCard(l10n.reserve, 'cirBTC', l10n)),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _panelButton(l10n.pay, CajaPanel.pay),
            _panelButton(l10n.receive, CajaPanel.receive),
            _panelButton(l10n.passage, CajaPanel.passage),
            _panelButton(l10n.cap, CajaPanel.cap),
          ],
        ),
        const SizedBox(height: 16),
        ...switch (_cajaPanel) {
          CajaPanel.pay => _payForm(l10n),
          CajaPanel.receive => _receivePanel(l10n),
          CajaPanel.passage => _passagePanel(l10n),
          CajaPanel.cap => _capPanel(l10n),
        },
        const SizedBox(height: 20),
        Text(l10n.activity, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (_transaction == null && _savedReceipts.isEmpty)
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
          if (_transaction != null) _transactionCard(l10n),
          ..._savedReceipts.map((h) => _savedReceiptCard(h, l10n)),
        ],
        if (_requestUncertain) ...[
          const SizedBox(height: 16),
          _card(
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
                controller: _recoverHash,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.transactionHashLabel,
                ),
              ),
              TextButton(
                onPressed: _recoverTransaction,
                child: Text(l10n.checkHash),
              ),
              TextButton(
                onPressed: _wallet.requestPending ? null : _acknowledgeNoSend,
                child: Text(l10n.requestCancelledOrRejected),
              ),
            ],
          ),
        ],
        if (_error != null) _errorBox(_error!),
      ],
    ),
  ];

  Widget _railCard(String title, String instrument, AppLocalizations l10n) => _card(
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

  Widget _panelButton(String label, CajaPanel panel) {
    final selected = _cajaPanel == panel;
    return selected
        ? FilledButton(
            onPressed: () => _showCajaPanel(panel),
            child: Text(label),
          )
        : OutlinedButton(
            onPressed: () => _showCajaPanel(panel),
            child: Text(label),
          );
  }

  List<Widget> _payForm(AppLocalizations l10n) => [
    Text(l10n.payTitle, style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 8),
    Text(
      l10n.payDescription,
      style: const TextStyle(color: FluuixColors.textMuted, fontSize: 12, height: 1.4),
    ),
    const SizedBox(height: 12),
    TextField(
      controller: _recipient,
      enabled: !_busy,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        labelText: l10n.recipientAddress,
        hintText: l10n.recipientHint,
      ),
    ),
    const SizedBox(height: 12),
    TextField(
      controller: _amount,
      enabled: !_busy,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: l10n.amount,
        suffixText: l10n.balanceUsdc,
        helperText: l10n.amountHelper,
      ),
    ),
    const SizedBox(height: 12),
    FilledButton.icon(
      onPressed:
          _busy ||
          _wallet.requestPending ||
          (_wallet.connected && _transferBlocked)
      ? null
      : (_wallet.connected ? _reviewAndSend : _connect),
      icon: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.fact_check_outlined),
      label: Text(
        _busy
            ? l10n.processing
            : _wallet.connected
            ? l10n.reviewTransfer
            : l10n.connectWallet,
      ),
    ),
    if (_wallet.connected && !_wallet.supportsArc)
      OutlinedButton(
        onPressed: _busy ? null : _addArc,
        child: Text(l10n.requestAddArcTestnet),
      ),
    TextButton(
      onPressed: () => _open('https://faucet.circle.com/'),
      child: Text(l10n.getTestUsdc),
    ),
  ];

  List<Widget> _receivePanel(AppLocalizations l10n) => [
    Text(l10n.receiveTitle, style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 8),
    if (_wallet.address == null)
      Text(
        l10n.receiveConnectPrompt,
        style: const TextStyle(color: FluuixColors.textMuted, height: 1.4),
      )
    else ...[
      Text(
        l10n.receiveDescription,
        style: const TextStyle(color: FluuixColors.textMuted, height: 1.4),
      ),
      const SizedBox(height: 12),
      Center(
        child: QrImageView(
          data: _wallet.address!,
          size: 180,
          backgroundColor: Colors.white,
        ),
      ),
      const SizedBox(height: 12),
      SelectableText(_wallet.address!),
    ],
  ];

  List<Widget> _passagePanel(AppLocalizations l10n) => [
    Text(l10n.passageTitle, style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 8),
    Text(
      l10n.passageNotConnected,
      style: const TextStyle(color: FluuixColors.textMuted, height: 1.45),
    ),
  ];

  List<Widget> _capPanel(AppLocalizations l10n) => [
    Text(l10n.capTitle, style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 8),
    Text(l10n.perPaymentCap(formatUnits(TreasuryPolicy.perPayment, 6))),
    Text(l10n.perDayCap(formatUnits(TreasuryPolicy.perDay, 6))),
    Text(l10n.usedToday(formatUnits(_ledger.forToday().spent, 6))),
    Text(l10n.remainingToday(formatUnits(_ledger.remaining, 6))),
    const SizedBox(height: 8),
    Text(
      l10n.capPolicyExplanation,
      style: const TextStyle(color: FluuixColors.textMuted, fontSize: 12, height: 1.45),
    ),
  ];

  List<String> get _savedReceipts {
    final current = _transaction?.hash.toLowerCase();
    return _ledger.forToday().hashes.where((hash) => hash != current).toList()
      ..sort();
  }

  Widget _savedReceiptCard(String hash, AppLocalizations l10n) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: _card(
      children: [
        Text(l10n.confirmed, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SelectableText(hash),
        TextButton(
          onPressed: () => _open('${ArcNetwork.explorer}/tx/$hash'),
          child: Text(l10n.openExplorer),
        ),
      ],
    ),
  );

  Widget _transactionCard(AppLocalizations l10n) {
    final result = _transaction!;
    final label = switch (result.state) {
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
        if (result.blockNumber != null) Text(l10n.blockLabel(result.blockNumber.toString())),
        Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: _checkReceipt,
              child: Text(l10n.checkReceipt),
            ),
            TextButton(
              onPressed: () =>
                  _open('${ArcNetwork.explorer}/tx/${result.hash}'),
              child: Text(l10n.openExplorer),
            ),
          ],
        ),
      ],
    );
  }

  Widget _ordenesCard(AppLocalizations l10n) {
    final steps = <(String, bool)>[
      (l10n.orderVerifyArc, _networkVerified),
      (l10n.orderExecuteRust, _nativeStatus != null),
      (l10n.orderActivateOpenHuman, _agentReady),
      (l10n.orderConnectArcAccount, _wallet.supportsArc),
      (
        l10n.orderConfirmTransfer,
        _transaction?.state == TransactionState.confirmed,
      ),
    ];
    return _card(
      children: [
        Text(
          l10n.dailyOrders,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.ordersExplanation,
          style: const TextStyle(color: FluuixColors.textMuted, fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 8),
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
                Expanded(child: Text(step.$1)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
