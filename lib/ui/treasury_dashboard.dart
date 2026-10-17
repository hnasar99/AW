part of '../main.dart';

class _Notice {
  const _Notice(this.title, this.detail, this.screen);
  final String title;
  final String detail;
  final TreasuryScreen screen;
}

extension _TreasuryDashboard on _WalletHomeState {
  int get _unreadBoxCount =>
      (_zf?.signedIn == true ? 1 : 8) + (_balance == null ? 1 : 0);

  bool get _paymentAwaiting =>
      _wallet.requestPending ||
      (_transaction != null &&
          _transaction!.state != TransactionState.confirmed &&
          _transaction!.state != TransactionState.reverted);

  PaymentMark? get _liabilityMark {
    if (_wallet.requestPending) return PaymentMark.awaitingSignature;
    final current = _transaction;
    if (current != null) {
      return switch (current.state) {
        TransactionState.submitted ||
        TransactionState.pending => PaymentMark.awaitingReceipt,
        TransactionState.unknown => PaymentMark.uncertain,
        TransactionState.confirmed => PaymentMark.confirmed,
        TransactionState.reverted => PaymentMark.reverted,
      };
    }
    if (_requestUncertain) return PaymentMark.uncertain;
    return null;
  }

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
    const Row(
      children: [
        BrandMark(size: 52),
        SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TESORERÍA',
              style: TextStyle(
                color: fluuixGold,
                fontSize: 11,
                letterSpacing: 2.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text('Posición de la empresa', style: TextStyle(fontSize: 16)),
          ],
        ),
      ],
    ),
    const SizedBox(height: 22),
    LedgerPlate(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Caja en dólares',
            style: TextStyle(
              color: fluuixGold,
              fontSize: 12,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          if (_balance == null)
            const Text(
              'Sin lectura',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
            )
          else
            HonestFigure(
              text: formatUnits(_balance!, 18, places: 2),
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w500,
                height: 1,
                letterSpacing: -1.2,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          const SizedBox(height: 14),
          const BrandRule(),
          const SizedBox(height: 12),
          Row(
            children: [
              const UnreadVessel(size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$_unreadBoxCount cajas sin lectura',
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CapacityGauge(
            remaining: _ledger.remaining,
            capacity: TreasuryPolicy.perDay,
            nearLimit: _capNearLimit,
          ),
          const SizedBox(height: 6),
          Text(
            'Firma restante ${formatUnits(_ledger.remaining, 6)} USDC',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          if (_liabilityMark != null) ...[
            const SizedBox(height: 16),
            LiabilityRow(mark: _liabilityMark!),
          ],
          const SizedBox(height: 18),
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
        ],
      ),
    ),
    const SizedBox(height: 28),
    Text('Libros de la empresa', style: Theme.of(context).textTheme.titleMedium),
    const SizedBox(height: 10),
    ..._booksBlock('position'),
    const SizedBox(height: 28),
    Text('Avisos', style: Theme.of(context).textTheme.titleMedium),
    const SizedBox(height: 10),
    ..._decisionNotices().map(_noticeTile),
  ];

  Iterable<_Notice> _decisionNotices() =>
      _notices.where((notice) => notice.title != 'Cajas sin lectura');

  List<Widget> _alertsBody() {
    final items = _notices;
    if (items.isEmpty) {
      return [
        const Text(
          'No hay avisos que pidan una decisión.',
          style: TextStyle(color: Colors.white70, height: 1.45),
        ),
        const SizedBox(height: 16),
        ..._booksBlock('incoming'),
      ];
    }
    return [
      const Text(
        'Hechos de esta app. No hay alertas de mercado.',
        style: TextStyle(color: Colors.white60, height: 1.45),
      ),
      const SizedBox(height: 12),
      ...items.map(_noticeTile),
      const SizedBox(height: 16),
      ..._booksBlock('incoming'),
    ];
  }

  Widget? _noticeMark(_Notice notice) => switch (notice.title) {
    'Cajas sin lectura' || 'Caja sin lectura' => const UnreadVessel(size: 26),
    'Pago pendiente de firma' => PaymentMarkView(
      mark: _liabilityMark ?? PaymentMark.awaitingReceipt,
      size: 26,
    ),
    'Solicitud sin resolver' => const PaymentMarkView(
      mark: PaymentMark.uncertain,
      size: 26,
    ),
    'Tope del día' => CapSeal(
      remaining: _ledger.remaining,
      capacity: TreasuryPolicy.perDay,
      nearLimit: true,
    ),
    'La caja informó un problema' => const FaultMark(size: 26),
    _ => null,
  };

  Widget _noticeTile(_Notice notice) => LedgerRow(
    title: notice.title,
    subtitle: notice.detail,
    leading: _noticeMark(notice),
    onTap: () => _openScreen(notice.screen),
  );
}
