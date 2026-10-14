part of '../main.dart';

extension _CajaView on _WalletHomeState {
  List<Widget> _payForm() => [
    TextField(
      controller: _company,
      enabled: !_busy,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(labelText: 'Empresa de la zona'),
    ),
    const SizedBox(height: 12),
    TextField(
      controller: _purpose,
      enabled: !_busy,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(labelText: 'Motivo'),
    ),
    const SizedBox(height: 12),
    TextField(
      controller: _recipient,
      enabled: !_busy,
      autocorrect: false,
      enableSuggestions: false,
      decoration: const InputDecoration(
        labelText: 'Cuenta de destino',
        hintText: '0x…',
      ),
    ),
    const SizedBox(height: 12),
    TextField(
      controller: _amount,
      enabled: !_busy,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Importe',
        suffixText: 'USDC',
        helperText: 'Hasta 6 decimales. No se redondea.',
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
            ? 'Procesando…'
            : _wallet.connected
            ? 'Revisar y firmar'
            : 'Conectar la cuenta de la empresa',
      ),
    ),
    if (_wallet.connected && !_wallet.supportsArc)
      OutlinedButton(
        onPressed: _busy ? null : _addArc,
        child: const Text('Solicitar agregar Arc Testnet'),
      ),
    TextButton(
      onPressed: () => _open('https://faucet.circle.com/'),
      child: const Text('Obtener USDC de prueba'),
    ),
  ];

  List<Widget> _receivePanel() => [
    if (_wallet.address == null)
      const Text(
        'Conectá la wallet para mostrar la dirección de la caja. '
        'FluuiX no genera una cuenta propia.',
        style: TextStyle(color: Colors.white70, height: 1.4),
      )
    else ...[
      const Text(
        'Esta dirección recibe USDC en Arc Testnet. No es una cuenta bancaria.',
        style: TextStyle(color: Colors.white70, height: 1.4),
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

  List<Widget> _capPanel() => [
    Text('Por pago: ${formatUnits(TreasuryPolicy.perPayment, 6)} USDC'),
    Text('Por día: ${formatUnits(TreasuryPolicy.perDay, 6)} USDC'),
    Text('Usado hoy: ${formatUnits(_ledger.forToday().spent, 6)} USDC'),
    Text('Restante hoy: ${formatUnits(_ledger.remaining, 6)} USDC'),
    const SizedBox(height: 8),
    const Text(
      'Política local de esta app, contada con recibos confirmados en este teléfono. '
      'No es un Agent Wallet de Circle. Si el importe la supera, la orden no se arma.',
      style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.45),
    ),
  ];

  List<String> get _savedReceipts {
    final current = _transaction?.hash.toLowerCase();
    return _ledger.forToday().hashes.where((hash) => hash != current).toList()
      ..sort();
  }

  Widget _savedReceiptCard(String hash) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: _card(
      children: [
        const Text('Confirmada', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SelectableText(hash),
        TextButton(
          onPressed: () => _open('${ArcNetwork.explorer}/tx/$hash'),
          child: const Text('Abrir explorador'),
        ),
      ],
    ),
  );

  Widget _transactionCard() {
    final result = _transaction!;
    final label = switch (result.state) {
      TransactionState.submitted => 'Enviada · esperando recibo',
      TransactionState.confirmed => 'Confirmada · ejecución exitosa',
      TransactionState.reverted => 'Revertida · la operación falló en la red',
      TransactionState.pending => 'Pendiente · todavía sin recibo',
      TransactionState.unknown =>
        'Estado no verificado · consultá el explorador',
    };
    return _card(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SelectableText(result.hash),
        if (result.blockNumber != null) Text('Bloque ${result.blockNumber}'),
        Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: _checkReceipt,
              child: const Text('Comprobar recibo'),
            ),
            TextButton(
              onPressed: () =>
                  _open('${ArcNetwork.explorer}/tx/${result.hash}'),
              child: const Text('Abrir explorador'),
            ),
          ],
        ),
      ],
    );
  }

}
