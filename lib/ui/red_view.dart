part of '../main.dart';

extension _RedView on _WalletHomeState {
  List<Widget> _redView() => [
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Red FluuiX', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(
          'Cada módulo está sin contrato hasta que el operador entregue '
          'endpoint, autenticación y catálogo. No hay saldos, tasas ni préstamos.',
          style: TextStyle(color: Colors.white70, height: 1.45),
        ),
        const SizedBox(height: 16),
        _module(
          'ZonaBank',
          'Cuentas, contactos, intents y rieles de liquidación. '
              'ZonaBank no guarda claves y no es un banco licenciado.',
          'https://fluuix.com/zonabank',
        ),
        _module(
          'Lending',
          'El mapa público habla de financiamiento contra colateral tokenizado. '
              'No hay catálogo, tasa ni préstamo en esta app.',
          'https://fluuix.com/ecosystem',
        ),
        _module(
          'ZonaFranca',
          'Registro y trazabilidad de mercancía y logística. Solo lectura cuando haya catálogo.',
          'https://fluuix.com/zf',
        ),
        _module(
          'TTN',
          'Instrumentos ya emitidos por TokenizaTuNegocio. '
              'Emitir un token no es una orden del teléfono.',
          'https://fluuix.com/ttn',
        ),
        const SizedBox(height: 8),
        Text('Capital', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        _module(
          'Fideicomisos',
          'Vehículo de capital del mismo motor. Sin posición que mostrar.',
          'https://fluuix.com/fideicomiso',
        ),
        _module(
          'Fondos',
          'Vehículo de capital del mismo motor. Sin posición que mostrar.',
          'https://fluuix.com/fondos',
        ),
        _module(
          'Crowd',
          'Financiamiento con la comunidad. Sin campaña cargada.',
          'https://fluuix.com/financiamiento',
        ),
        _module(
          'Licitaciones',
          'Compras con recibo verificable. Sin proceso cargado.',
          'https://fluuix.com/licitaciones',
        ),
        _module(
          'Donaciones',
          'Donación con trazabilidad. Sin campaña cargada.',
          'https://fluuix.com/donaciones',
        ),
        _module(
          'Academia',
          'Formación de TokenizaTuNegocio. No mueve fondos.',
          'https://fluuix.com/academia',
        ),
      ],
    ),
  ];

  Widget _module(String title, String body, String url) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: _card(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const Text(
              'Sin contrato',
              style: TextStyle(color: Color(0xffe4d3b0), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(body, style: const TextStyle(color: Colors.white70, height: 1.4)),
        TextButton(
          onPressed: () => _open(url),
          child: const Text('Qué publica el producto'),
        ),
      ],
    ),
  );
}
