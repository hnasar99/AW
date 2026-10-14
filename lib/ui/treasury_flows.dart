part of '../main.dart';

extension _TreasuryFlows on _WalletHomeState {
  List<Widget> _forecastBody() => const [
    Text(
      'Horizonte de cobros y pagos de la empresa.',
      style: TextStyle(fontSize: 16, height: 1.4),
    ),
    SizedBox(height: 16),
    Text(
      'No hay agenda de cobros ni pagos cargada.',
      style: TextStyle(color: Colors.white70, height: 1.45),
    ),
  ];

  List<Widget> _collectionsBody() => [
    const Text(
      'Para que te paguen en dólares en la caja.',
      style: TextStyle(fontSize: 16, height: 1.4),
    ),
    const SizedBox(height: 16),
    ..._receivePanel(),
  ];

  List<Widget> _paymentsBody() => [
    const Text(
      'Empresa de la zona, motivo y firma. Si supera el tope, la orden no se arma.',
      style: TextStyle(color: Colors.white70, height: 1.45),
    ),
    const SizedBox(height: 16),
    ..._payForm(),
    if (_error != null) _errorBox(_error!),
  ];

  List<Widget> _convertBody() => [
    const Text(
      'Cualquier stable hacia la caja en dólares. El costo y la llegada se muestran antes de confirmar.',
      style: TextStyle(height: 1.45),
    ),
    const SizedBox(height: 18),
    _pocketLine('Caja en dólares', _balance == null ? 'Sin lectura' : 'Origen posible'),
    _pocketLine('Riel local', 'Sin lectura'),
    _pocketLine('Entrada de dólares', 'Sin lectura'),
    const SizedBox(height: 16),
    const Text('Hacia la caja en dólares'),
    const SizedBox(height: 8),
    const Text('Llegada: sin cotización', style: TextStyle(color: Colors.white70)),
    const Text('Costo: sin cotización', style: TextStyle(color: Colors.white70)),
    const SizedBox(height: 16),
    const Text(
      'El pasaje no está conectado. No se arma una conversión.',
      style: TextStyle(color: Colors.white70, height: 1.45),
    ),
  ];

  Widget _pocketLine(String name, String state) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(name)),
        Text(state, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      ],
    ),
  );

  List<Widget> _internationalBody() => [
    const Text(
      'Un pago fuera de la zona es un corredor y una moneda. No se marca liquidado.',
      style: TextStyle(height: 1.45),
    ),
    const SizedBox(height: 16),
    Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Carta de crédito'),
          selected: _corridor == 'Carta de crédito',
          onSelected: (_) => _setCorridor('Carta de crédito'),
        ),
        ChoiceChip(
          label: const Text('Entre zonas'),
          selected: _corridor == 'Entre zonas',
          onSelected: (_) => _setCorridor('Entre zonas'),
        ),
      ],
    ),
    const SizedBox(height: 16),
    Text('Corredor: $_corridor', style: const TextStyle(color: Colors.white70)),
    const SizedBox(height: 8),
    const Text('Moneda de llegada: sin cotización', style: TextStyle(color: Colors.white70)),
    const SizedBox(height: 16),
    const Text(treasuryNotOnPhone, style: TextStyle(color: fluuixAccent, height: 1.4)),
  ];

  List<Widget> _reconcileBody() => [
    const Text(
      'El comprobante guardado en este teléfono, contra el movimiento. Sin extracto bancario.',
      style: TextStyle(height: 1.45),
    ),
    const SizedBox(height: 16),
    if (_transaction == null && _savedReceipts.isEmpty)
      const Text(
        'Todavía no hay un comprobante en este teléfono.',
        style: TextStyle(color: Colors.white70),
      )
    else ...[
      if (_transaction != null) _transactionCard(),
      ..._savedReceipts.map(_savedReceiptCard),
    ],
    if (_requestUncertain) ...[
      const SizedBox(height: 16),
      const Text(
        'Solicitud sin resolver',
        style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      const Text(
        'Revisá el historial y las solicitudes en la cuenta de la empresa antes de otro envío. Si hay un comprobante, pegalo para comprobarlo.',
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _recoverHash,
        autocorrect: false,
        decoration: const InputDecoration(labelText: 'Comprobante 0x…'),
      ),
      Wrap(
        spacing: 8,
        children: [
          TextButton(onPressed: _recoverTransaction, child: const Text('Comprobar')),
          TextButton(
            onPressed: _wallet.requestPending ? null : _acknowledgeNoSend,
            child: const Text('La solicitud fue cancelada o rechazada'),
          ),
        ],
      ),
    ],
  ];

  List<Widget> _capsBody() => [
    const Text(
      'Poder de firma de quien opera la caja. La caja y la reserva no son de esa persona.',
      style: TextStyle(height: 1.45),
    ),
    const SizedBox(height: 16),
    ..._capPanel(),
  ];
}
