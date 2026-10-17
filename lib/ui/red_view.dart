part of '../main.dart';

extension _RedView on _WalletHomeState {
  List<Widget> _redView(AppLocalizations l10n) => [
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.networkTitle, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          l10n.networkDescription,
          style: TextStyle(color: FluuixColors.textMuted, height: 1.45),
        ),
        const SizedBox(height: 16),
        _module(
          l10n.zonaBankTitle,
          l10n.zonaBankDesc,
          'https://fluuix.com/zonabank',
          l10n,
        ),
        _module(
          l10n.lendingTitle,
          l10n.lendingDesc,
          'https://fluuix.com/ecosystem',
          l10n,
        ),
        _module(
          l10n.zonaFrancaTitle,
          l10n.zonaFrancaDesc,
          'https://fluuix.com/zf',
          l10n,
        ),
        _module(
          l10n.ttnTitle,
          l10n.ttnDesc,
          'https://fluuix.com/ttn',
          l10n,
        ),
        const SizedBox(height: 8),
        Text(l10n.capitalSection, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        _module(
          l10n.fideicomisosTitle,
          l10n.fideicomisosDesc,
          'https://fluuix.com/fideicomiso',
          l10n,
        ),
        _module(
          l10n.fondosTitle,
          l10n.fondosDesc,
          'https://fluuix.com/fondos',
          l10n,
        ),
        _module(
          l10n.crowdTitle,
          l10n.crowdDesc,
          'https://fluuix.com/financiamiento',
          l10n,
        ),
        _module(
          l10n.licitacionesTitle,
          l10n.licitacionesDesc,
          'https://fluuix.com/licitaciones',
          l10n,
        ),
        _module(
          l10n.donacionesTitle,
          l10n.donacionesDesc,
          'https://fluuix.com/donaciones',
          l10n,
        ),
        _module(
          l10n.academiaTitle,
          l10n.academiaDesc,
          'https://fluuix.com/academia',
          l10n,
        ),
      ],
    ),
  ];

  Widget _module(String title, String body, String url, AppLocalizations l10n) => Padding(
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
            Text(
              l10n.noContract,
              style: TextStyle(color: FluuixColors.gold, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(body, style: TextStyle(color: FluuixColors.textMuted, height: 1.4)),
        TextButton(
          onPressed: () => _open(url),
          child: Text(l10n.whatProductPublishes),
        ),
      ],
    ),
  );
}
