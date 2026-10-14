part of '../main.dart';

class _CashBox {
  const _CashBox({
    required this.role,
    required this.settle,
    this.live = false,
    this.vehicle = false,
  });

  final String role;
  final String settle;
  final bool live;
  final bool vehicle;
}

_CashBox _cashBox(TreasuryScreen screen) => switch (screen) {
  TreasuryScreen.boxDollars => const _CashBox(
    role: 'Operar pagos y cobros en dólares.',
    settle: 'El comprobante abre el explorador de la caja.',
    live: true,
  ),
  TreasuryScreen.boxLocal => const _CashBox(
    role: 'Cobrar en la zona.',
    settle: 'Se liquida en el riel de la zona.',
  ),
  TreasuryScreen.boxEntry => const _CashBox(
    role: 'Entrada del mismo dólar hacia la caja.',
    settle: 'El pasaje no está conectado.',
  ),
  TreasuryScreen.boxReserve => const _CashBox(
    role: 'Apartar valor que el tope de pagos no gasta.',
    settle: 'Queda fuera del tope de pagos.',
  ),
  TreasuryScreen.boxTrust => const _CashBox(
    role: 'Captar y distribuir con escrow fiduciario.',
    settle: 'Aporte, escrow, liberación y distribución.',
    vehicle: true,
  ),
  TreasuryScreen.boxFund => const _CashBox(
    role: 'Suscribir y rescatar el fondo.',
    settle: 'Aporte, escrow, liberación y distribución.',
    vehicle: true,
  ),
  TreasuryScreen.boxTender => const _CashBox(
    role: 'Garantizar la oferta y pagar por avance.',
    settle: 'Aporte, escrow, liberación y distribución.',
    vehicle: true,
  ),
  TreasuryScreen.boxDonation => const _CashBox(
    role: 'Donar y liberar por hito.',
    settle: 'Aporte, escrow, liberación y distribución.',
    vehicle: true,
  ),
  TreasuryScreen.boxCrowd => const _CashBox(
    role: 'Captar con meta y reembolso.',
    settle: 'Aporte, escrow, liberación y distribución.',
    vehicle: true,
  ),
  _ => const _CashBox(role: '', settle: ''),
};

extension _TreasuryBoxes on _WalletHomeState {
  List<Widget> _boxBody(TreasuryScreen screen) {
    final box = _cashBox(screen);
    final live = box.live && _balance != null;
    return [
      Text(box.role, style: const TextStyle(fontSize: 16, height: 1.4)),
      const SizedBox(height: 18),
      Text(
        live ? formatUnits(_balance!, 18, places: 2) : '—',
        style: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w600,
          height: 1,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
      const SizedBox(height: 8),
      Text(
        live ? 'USDC' : 'Sin lectura',
        style: const TextStyle(color: fluuixAccent),
      ),
      const SizedBox(height: 8),
      Text(
        box.settle,
        style: const TextStyle(color: Colors.white60, height: 1.4),
      ),
      if (box.live && !_networkVerified)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            _networkStatus,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
      if (!box.live) ...[
        const SizedBox(height: 12),
        const Text(
          'Esta caja no se suma a la posición.',
          style: TextStyle(color: Colors.white60, fontSize: 13),
        ),
      ],
      if (box.vehicle) ...[
        const SizedBox(height: 20),
        ..._vehicleSteps(),
      ],
      if (box.live) ...[
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () => _openScreen(TreasuryScreen.payments),
                child: const Text('Pagar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _openScreen(TreasuryScreen.collections),
                child: const Text('Cobrar'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Movimientos', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ..._dollarMovements(),
        if (_error != null) _errorBox(_error!),
      ] else ...[
        const SizedBox(height: 20),
        const Text('Sin movimientos.', style: TextStyle(color: Colors.white70)),
      ],
    ];
  }

  List<Widget> _vehicleSteps() => [
    for (final step in ['Aporte', 'Escrow', 'Liberación', 'Distribución'])
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.radio_button_unchecked, size: 16, color: Colors.white38),
            const SizedBox(width: 8),
            Text(step),
            const Spacer(),
            const Text('Sin movimiento', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
  ];

  List<Widget> _dollarMovements() {
    if (_transaction == null && _savedReceipts.isEmpty) {
      return const [
        Text(
          'Todavía no hay un comprobante en este teléfono.',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
      ];
    }
    return [
      const Text(
        'El comprobante es el recibo de esta caja.',
        style: TextStyle(color: Colors.white60, fontSize: 12),
      ),
      const SizedBox(height: 8),
      if (_transaction != null) _transactionCard(),
      ..._savedReceipts.map(_savedReceiptCard),
    ];
  }
}
