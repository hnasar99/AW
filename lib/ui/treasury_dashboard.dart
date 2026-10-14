part of '../main.dart';

class _Notice {
  const _Notice(this.title, this.detail, this.screen);
  final String title;
  final String detail;
  final TreasuryScreen screen;
}

extension _TreasuryDashboard on _WalletHomeState {
  int get _unreadBoxCount => 8 + (_balance == null ? 1 : 0);

  bool get _paymentAwaiting =>
      _wallet.requestPending ||
      (_transaction != null &&
          _transaction!.state != TransactionState.confirmed &&
          _transaction!.state != TransactionState.reverted);

  bool get _capNearLimit {
    final today = _ledger.forToday();
    if (today.spent <= BigInt.zero) return false;
    return _ledger.remaining <= TreasuryPolicy.perDay ~/ BigInt.from(5);
  }

  List<_Notice> get _notices {
    final items = <_Notice>[
      const _Notice(
        'Cajas sin lectura',
        'Ocho cajas de rieles y vehículos siguen sin saldo leído. No entran en la posición.',
        TreasuryScreen.boxLocal,
      ),
    ];
    if (_balance == null) {
      items.insert(
        0,
        const _Notice(
          'Caja sin lectura',
          'La caja en dólares no tiene un saldo leído.',
          TreasuryScreen.boxDollars,
        ),
      );
    }
    if (_paymentAwaiting) {
      items.add(
        const _Notice(
          'Pago pendiente de firma',
          'Hay una orden que todavía no tiene comprobante.',
          TreasuryScreen.payments,
        ),
      );
    }
    if (_requestUncertain) {
      items.add(
        const _Notice(
          'Solicitud sin resolver',
          'Revisá la cuenta de la empresa antes de otro envío.',
          TreasuryScreen.reconcile,
        ),
      );
    }
    if (_capNearLimit) {
      items.add(
        const _Notice(
          'Tope del día',
          'El poder de firma de hoy está cerca del límite.',
          TreasuryScreen.caps,
        ),
      );
    }
    if (_error != null) {
      items.add(
        const _Notice(
          'La caja informó un problema',
          'El detalle está en la caja en dólares.',
          TreasuryScreen.boxDollars,
        ),
      );
    }
    return items;
  }

  List<Widget> _dashboardBody() => [
    const Text(
      'Posición',
      style: TextStyle(color: Colors.white60, fontSize: 13, letterSpacing: 1.2),
    ),
    const SizedBox(height: 8),
    Text(
      _balance == null ? '—' : formatUnits(_balance!, 18, places: 2),
      style: const TextStyle(
        fontSize: 56,
        fontWeight: FontWeight.w600,
        height: 1,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    ),
    const SizedBox(height: 8),
    const Text(
      'Caja en dólares',
      style: TextStyle(color: fluuixAccent, fontSize: 16),
    ),
    const SizedBox(height: 6),
    Text(
      '$_unreadBoxCount cajas sin lectura',
      style: const TextStyle(color: Colors.white60, fontSize: 13),
    ),
    const SizedBox(height: 22),
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
    const SizedBox(height: 28),
    Text('Avisos', style: Theme.of(context).textTheme.titleMedium),
    const SizedBox(height: 8),
    ..._decisionNotices().map(_noticeTile),
  ];

  Iterable<_Notice> _decisionNotices() => _notices.where(
    (notice) => notice.title != 'Cajas sin lectura',
  );

  List<Widget> _alertsBody() {
    final items = _notices;
    if (items.isEmpty) {
      return const [
        Text(
          'No hay avisos que pidan una decisión.',
          style: TextStyle(color: Colors.white70, height: 1.45),
        ),
      ];
    }
    return [
      const Text(
        'Hechos de esta app. No hay alertas de mercado.',
        style: TextStyle(color: Colors.white60, height: 1.45),
      ),
      const SizedBox(height: 12),
      ...items.map(_noticeTile),
    ];
  }

  Widget _noticeTile(_Notice notice) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(notice.title),
      subtitle: Text(notice.detail),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _openScreen(notice.screen),
    ),
  );
}
