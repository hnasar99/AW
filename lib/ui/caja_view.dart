part of '../main.dart';

enum CajaPanel { pay, receive, passage, cap }

extension _CajaView on _WalletHomeState {
  List<Widget> _cajaView() => [
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card(
          children: [
            const Text(
              'Caja en dólares',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              _networkStatus,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Text(
              _balance == null ? '—' : formatUnits(_balance!, 18, places: 6),
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700),
            ),
            const Text(
              'USDC',
              style: TextStyle(color: Color(0xffe4d3b0), fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Arc Testnet · un solo saldo para pagos y comisiones. '
              'No incluye el riel local ni la reserva.',
              style: TextStyle(
                color: Colors.white60,
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
                  _networkVerified ? 'Arc verificado' : 'Arc sin verificar',
                  _networkVerified,
                ),
                _statusChip(
                  _wallet.connected ? 'Sesión activa' : 'Sin sesión',
                  _wallet.connected,
                ),
                _statusChip(
                  'Tope restante ${formatUnits(_ledger.remaining, 6)} USDC',
                  _ledger.remaining > BigInt.zero,
                ),
              ],
            ),
            if (_wallet.address != null) ...[
              const Divider(height: 28),
              SelectableText(_wallet.address!),
              Text(
                'Sesión en Arc Testnet · cadena ${_wallet.chainId}',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: _busy ? null : _disconnect,
                    child: const Text('Desconectar'),
                  ),
                  TextButton(
                    onPressed: () => _open(
                      '${ArcNetwork.explorer}/address/${_wallet.address}',
                    ),
                    child: const Text('Ver cuenta'),
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
            Expanded(child: _railCard('Riel local', 'Twin · ARGt')),
            const SizedBox(width: 12),
            Expanded(child: _railCard('Reserva', 'cirBTC')),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _panelButton('Pagar', CajaPanel.pay),
            _panelButton('Recibir', CajaPanel.receive),
            _panelButton('Pasar', CajaPanel.passage),
            _panelButton('Tope', CajaPanel.cap),
          ],
        ),
        const SizedBox(height: 16),
        ...switch (_cajaPanel) {
          CajaPanel.pay => _payForm(),
          CajaPanel.receive => _receivePanel(),
          CajaPanel.passage => _passagePanel(),
          CajaPanel.cap => _capPanel(),
        },
        const SizedBox(height: 20),
        Text('Actividad', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (_transaction == null && _savedReceipts.isEmpty)
          const Text(
            'Todavía no hay un recibo guardado en este teléfono.',
            style: TextStyle(color: Colors.white60),
          )
        else ...[
          const Text(
            'El hash es el recibo. No reemplaza el extracto del banco.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (_transaction != null) _transactionCard(),
          ..._savedReceipts.map(_savedReceiptCard),
        ],
        if (_requestUncertain) ...[
          const SizedBox(height: 16),
          _card(
            children: [
              const Text(
                'Solicitud sin resolver',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Revisá el historial y las solicitudes en tu wallet antes de otro envío. Si hay un hash, pegalo para comprobarlo.',
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _recoverHash,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Hash de transacción 0x…',
                ),
              ),
              TextButton(
                onPressed: _recoverTransaction,
                child: const Text('Comprobar hash'),
              ),
              TextButton(
                onPressed: _wallet.requestPending ? null : _acknowledgeNoSend,
                child: const Text('La solicitud fue cancelada o rechazada'),
              ),
            ],
          ),
        ],
        if (_error != null) _errorBox(_error!),
      ],
    ),
  ];

  Widget _railCard(String title, String instrument) => _card(
    children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Text(instrument, style: const TextStyle(color: Colors.white70)),
      const SizedBox(height: 8),
      const Text('Sin contrato', style: TextStyle(color: Color(0xffe4d3b0))),
      const SizedBox(height: 4),
      const Text(
        'No se suma a la caja.',
        style: TextStyle(color: Colors.white60, fontSize: 12),
      ),
    ],
  );

  Widget _statusChip(String label, bool on) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xff20202c),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: on ? const Color(0xff8d9a78) : const Color(0xff353347),
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

  List<Widget> _payForm() => [
    Text('Pagar', style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 8),
    const Text(
      'La orden se revisa en FluuiX y se firma en tu wallet. '
      'Si supera el tope, no se arma.',
      style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
    ),
    const SizedBox(height: 12),
    TextField(
      controller: _recipient,
      enabled: !_busy,
      autocorrect: false,
      enableSuggestions: false,
      decoration: const InputDecoration(
        labelText: 'Dirección del destinatario',
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
            ? 'Revisar transferencia'
            : 'Conectar wallet',
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
    Text('Recibir', style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 8),
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

  List<Widget> _passagePanel() => [
    Text('Pasar', style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 8),
    const Text(
      'El pasaje Arbitrum → Arc por CCTP no está conectado. '
      'No hay saldo de otra cadena en esta pantalla y no se arma un puente.',
      style: TextStyle(color: Colors.white70, height: 1.45),
    ),
  ];

  List<Widget> _capPanel() => [
    Text('Tope', style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 8),
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

  Widget _ordenesCard() {
    final steps = <(String, bool)>[
      ('Verificar Arc Testnet', _networkVerified),
      ('Ejecutar Rust en el dispositivo', _nativeStatus != null),
      ('Activar OpenHuman', _agentReady),
      ('Conectar una cuenta en Arc', _wallet.supportsArc),
      (
        'Confirmar una transferencia real de testnet',
        _transaction?.state == TransactionState.confirmed,
      ),
    ];
    return _card(
      children: [
        const Text(
          'Órdenes del día',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Cada ítem refleja un evento ya observado en esta sesión. '
          'No es una transferencia simulada.',
          style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
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
                  color: step.$2 ? Colors.greenAccent : Colors.white38,
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
