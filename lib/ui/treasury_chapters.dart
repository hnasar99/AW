part of '../main.dart';

extension _TreasuryChapters on _WalletHomeState {
  List<Widget> _inventoryBody() => [
    const Text(
      'Lo que la empresa puede representar. Cada tipo abre su ficha.',
      style: TextStyle(height: 1.45),
    ),
    const SizedBox(height: 8),
    _fichaLink(
      TreasuryScreen.tokenZone,
      'Mercadería',
      'Logística y entrega en la zona.',
    ),
    _fichaLink(
      TreasuryScreen.tokenContracts,
      'Contratos',
      'Un acuerdo que puede quedar en garantía.',
    ),
    _fichaLink(
      TreasuryScreen.tokenDocuments,
      'Documentos',
      'Un papel que pasa a ser verificable.',
    ),
    _fichaLink(
      TreasuryScreen.tokenProperty,
      'Inmuebles',
      'Un inmueble que admite participaciones.',
    ),
    _fichaLink(
      TreasuryScreen.tokenShares,
      'Participaciones',
      'Quién entra al capital o al fondo.',
    ),
    const SizedBox(height: 16),
    ..._booksBlock('assets'),
  ];

  Widget _fichaLink(TreasuryScreen screen, String title, String subtitle) =>
      LedgerRow(
        title: title,
        subtitle: subtitle,
        onTap: () => _openScreen(screen),
      );

  List<Widget> _chapterBody(TreasuryScreen screen) {
    final copy = _chapterCopy(screen);
    final books = _booksKey(screen);
    return [
      if (books != null) ..._booksBlock(books),
      if (books != null) const SizedBox(height: 16),
      LedgerPlate(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              copy.$1,
              style: const TextStyle(
                fontSize: 18,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              copy.$2,
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 16),
            const BrandRule(),
            const SizedBox(height: 12),
            const PhoneBoundLine(),
          ],
        ),
      ),
    ];
  }

  (String, String) _chapterCopy(TreasuryScreen screen) => switch (screen) {
    TreasuryScreen.tokenShares => (
      'Quién entra al capital o al fondo, y qué recibe.',
      'La participación queda registrada como instrumento. Emitir no es un botón de esta pantalla.',
    ),
    TreasuryScreen.tokenEscrow => (
      'El activo queda en garantía y el inversor entra contra esa condición.',
      'Sirve para financiar un bien que la empresa ya tiene, sin mezclarlo con la caja operativa.',
    ),
    TreasuryScreen.tokenContracts => (
      'Un contrato de la empresa puede representarse y usarse como garantía.',
      'La ficha prepara el acto. No despliega un contrato.',
    ),
    TreasuryScreen.tokenDocuments => (
      'Un documento operativo pasa a ser un comprobante verificable.',
      'La empresa lo prepara aquí. La emisión queda en TTN.',
    ),
    TreasuryScreen.tokenProperty => (
      'Un inmueble admite participaciones sin vender el activo entero.',
      'Los inversores entran sobre la ficha. No hay un saldo de demostración.',
    ),
    TreasuryScreen.tokenZone => (
      'Flete, almacenaje y derechos, con escrow contra la entrega.',
      'Zona Franca registra la mercadería. Esta pantalla no da de alta un activo.',
    ),
    TreasuryScreen.tokenTtn => (
      'Instrumentos ya emitidos por la empresa.',
      'Emitir un instrumento no es una orden del teléfono.',
    ),
    TreasuryScreen.schemeAllOrNothing => (
      'La captación se devuelve si no se alcanza la meta.',
      'El aporte espera en escrow. Sin meta, no hay liberación.',
    ),
    TreasuryScreen.schemeBidBond => (
      'La garantía de la oferta queda bloqueada hasta el resultado.',
      'La licitación usa esa garantía. No se ejecuta un bloqueo desde aquí.',
    ),
    TreasuryScreen.schemeProgress => (
      'El pago sale cuando hay un certificado de avance.',
      'La obra y el comprobante van juntos. No se marca pagado.',
    ),
    TreasuryScreen.schemeMilestoneGift => (
      'La donación se libera cuando el hito de impacto está verificado.',
      'El donante ve el destino. No hay una campaña cargada.',
    ),
    TreasuryScreen.schemeNavFund => (
      'Se suscribe y se rescata contra el valor del fondo.',
      'El motor no publica una cotización en esta pantalla.',
    ),
    _ => ('', ''),
  };

  List<Widget> _factoringBody() => [
    const Text(
      'Adelantar liquidez sobre un activo tokenizado. No es un desembolso.',
      style: TextStyle(height: 1.45),
    ),
    const SizedBox(height: 16),
    DropdownButtonFormField<String>(
      initialValue: _factorAsset,
      decoration: const InputDecoration(labelText: 'Activo'),
      items: const [
        DropdownMenuItem(value: 'Mercadería', child: Text('Mercadería')),
        DropdownMenuItem(value: 'Contrato', child: Text('Contrato')),
        DropdownMenuItem(value: 'Documento', child: Text('Documento')),
        DropdownMenuItem(value: 'Inmueble', child: Text('Inmueble')),
      ],
      onChanged: (value) {
        if (value != null) _setFactorAsset(value);
      },
    ),
    const SizedBox(height: 16),
    Text(
      'Activo elegido: $_factorAsset',
      style: const TextStyle(color: Colors.white70),
    ),
    const SizedBox(height: 8),
    const Text(
      'Liquidez que se podría adelantar: sin cotización.',
      style: TextStyle(color: Colors.white70, height: 1.4),
    ),
    const SizedBox(height: 8),
    const Text(
      'No hay tasa y no queda desembolsado.',
      style: TextStyle(color: Colors.white70, height: 1.4),
    ),
    const SizedBox(height: 16),
    const PhoneBoundLine(color: fluuixAccent),
  ];

  List<Widget> _quotesBody() => [
    const Text(
      'El motor de agentes monitorea la caja y dice cuando no hay precio.',
      style: TextStyle(height: 1.45),
    ),
    const SizedBox(height: 18),
    Text('Lecturas', style: Theme.of(context).textTheme.titleMedium),
    const SizedBox(height: 8),
    Text(
      _balance != null
          ? 'La caja en dólares tiene lectura.'
          : 'La caja en dólares no tiene lectura.',
      style: const TextStyle(color: Colors.white70),
    ),
    if (_balance != null)
      Row(
        children: [
          const ReadingMark(size: 18),
          const SizedBox(width: 8),
          Text(
            formatUnits(_balance!, 18, places: 2),
            style: const TextStyle(
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    const SizedBox(height: 18),
    Text('Fondos de la empresa', style: Theme.of(context).textTheme.titleMedium),
    const SizedBox(height: 8),
    ..._booksBlock('funds'),
    const SizedBox(height: 18),
    Text('Cotizaciones', style: Theme.of(context).textTheme.titleMedium),
    const SizedBox(height: 8),
    const Text(
      'No hay cotización.',
      style: TextStyle(color: Colors.white70, height: 1.4),
    ),
    const SizedBox(height: 12),
    const AbsentSeries(),
    const SizedBox(height: 16),
    OutlinedButton(
      onPressed: () => _openScreen(TreasuryScreen.assistant),
      child: const Text('Preguntar al asistente'),
    ),
  ];

  List<Widget> _accountBody() => [
    ..._zonafrancaAccountCard(),
    ..._portalsBoard(),
    if (_wallet.connected)
      TextButton(
        onPressed: _busy ? null : _disconnect,
        child: const Text('Desconectar la cuenta'),
      ),
    ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Redes de lectura'),
      subtitle: const Text(
        'Consultas de red. No cambian la firma ni la caja en dólares.',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const NetworkManagerScreen()),
        );
      },
    ),
    const SizedBox(height: 8),
    ..._settingsView(),
  ];
}
