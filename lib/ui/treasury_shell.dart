part of '../main.dart';

extension _TreasuryShell on _WalletHomeState {
  Widget _treasuryScaffold() {
    final item = treasuryItem(_screen);
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(item.label),
        leading: IconButton(
          tooltip: 'Menú',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          icon: const Icon(Icons.menu),
        ),
        actions: [
          IconButton(
            onPressed: _busy ? null : _checkNetwork,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar caja',
          ),
        ],
      ),
      drawer: _treasuryDrawer(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              key: const Key('treasury-body'),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                ..._screenBody(),
                const SizedBox(height: 28),
                const Text(
                  'La firma la hace la cuenta de la empresa. Esta app no pide la frase semilla.',
                  style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _treasuryDrawer() {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: Text(
                'FluuiX',
                style: TextStyle(
                  color: fluuixAccent,
                  fontSize: 13,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (final group in TreasuryGroup.values) ...[
              ExpansionTile(
                key: ValueKey('${group.name}-${_menuGroup.name}'),
                initiallyExpanded: group == _menuGroup,
                tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: Text(
                  treasuryGroupLabel(group),
                  style: const TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onExpansionChanged: (open) {
                  if (open) _rememberMenuGroup(group);
                },
                children: [
                  for (final item in treasuryMenu.where((entry) => entry.group == group))
                    ListTile(
                      dense: true,
                      selected: item.screen == _screen,
                      selectedColor: fluuixAccent,
                      title: Text(item.label),
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen(item.screen);
                      },
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _screenBody() => switch (_screen) {
    TreasuryScreen.dashboard => _dashboardBody(),
    TreasuryScreen.alerts => _alertsBody(),
    TreasuryScreen.boxDollars ||
    TreasuryScreen.boxLocal ||
    TreasuryScreen.boxEntry ||
    TreasuryScreen.boxReserve ||
    TreasuryScreen.boxTrust ||
    TreasuryScreen.boxFund ||
    TreasuryScreen.boxTender ||
    TreasuryScreen.boxDonation ||
    TreasuryScreen.boxCrowd => _boxBody(_screen),
    TreasuryScreen.forecast => _forecastBody(),
    TreasuryScreen.collections => _collectionsBody(),
    TreasuryScreen.payments => _paymentsBody(),
    TreasuryScreen.convert => _convertBody(),
    TreasuryScreen.international => _internationalBody(),
    TreasuryScreen.reconcile => _reconcileBody(),
    TreasuryScreen.caps => _capsBody(),
    TreasuryScreen.tokenInventory => _inventoryBody(),
    TreasuryScreen.factoring => _factoringBody(),
    TreasuryScreen.quotes => _quotesBody(),
    TreasuryScreen.assistant => _agentView(),
    TreasuryScreen.account => _accountBody(),
    _ => _chapterBody(_screen),
  };

}
