part of '../main.dart';

extension _TreasuryShell on _WalletHomeState {
  Widget _treasuryScaffold() {
    final item = treasuryItem(_screen);
    return TreasuryAtmosphere(
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(item.label),
              leading: IconButton(
                tooltip: 'Menú',
                onPressed: _toggleTreasuryNav,
                icon: const Icon(FluuixIcons.list),
              ),
              actions: [
                if (_screen == TreasuryScreen.dashboard ||
                    _screen == TreasuryScreen.boxDollars ||
                    _booksKey(_screen) != null)
                  IconButton(
                    onPressed: _busy
                        ? null
                        : () {
                            if (!awLabTextOnly) unawaited(_checkNetwork());
                            unawaited(_reloadZonafranca());
                          },
                    icon: const Icon(FluuixIcons.arrowsClockwise),
                    tooltip: 'Actualizar',
                  ),
              ],
            ),
            body: SafeArea(
              child: TreasuryScreenSwitch(
                screenKey: ValueKey(_screen),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ListView(
                      key: const Key('treasury-body'),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                      children: [
                        ..._screenBody(),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_navOpen) _treasuryNav(),
        ],
      ),
    );
  }

  Widget _treasuryNav() {
    final top = MediaQuery.paddingOf(context).top + kToolbarHeight;
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      bottom: 0,
      child: Row(
        children: [
          SizedBox(
            width: 300,
            child: Material(
              color: const Color(0xff0c0e14),
              child: _treasuryDrawer(),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _closeTreasuryNav,
              behavior: HitTestBehavior.opaque,
              child: const ColoredBox(
                color: Color(0xB3000000),
                child: SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _treasuryDrawer() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 8, 8),
          child: Row(
            children: [
              const BrandMark(size: 36),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'FluuiX',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    letterSpacing: 2.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Cerrar',
                onPressed: _closeTreasuryNav,
                icon: const Icon(FluuixIcons.x),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            children: [
              for (final group in TreasuryGroup.values)
                if (group != TreasuryGroup.account)
                  ExpansionTile(
                    key: ValueKey('${group.name}-${_menuGroup.name}'),
                    initiallyExpanded: group == _menuGroup,
                    shape: const Border(),
                    collapsedShape: const Border(),
                    tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                    childrenPadding: const EdgeInsets.only(bottom: 4),
                    leading: TreasuryIcon(
                      icon: treasuryGroupIcon(group),
                      selected: group == _menuGroup,
                    ),
                    title: Text(
                      treasuryGroupLabel(group),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onExpansionChanged: (open) {
                      if (open) _rememberMenuGroup(group);
                    },
                    children: [
                      for (final item in treasuryMenu.where(
                        (entry) => entry.group == group,
                      ))
                        ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          selected: item.screen == _screen,
                          selectedTileColor: fluuixGold.withValues(alpha: 0.12),
                          leading: TreasuryIcon(
                            icon: treasuryScreenIcon(item.screen),
                            size: 20,
                            selected: item.screen == _screen,
                          ),
                          title: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 14,
                              color: item.screen == _screen
                                  ? Colors.white
                                  : const Color(0xffc8ccd6),
                            ),
                          ),
                          onTap: () {
                            _closeTreasuryNav();
                            _openScreen(item.screen);
                          },
                        ),
                    ],
                  ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0x14ffffff)),
        ListTile(
          leading: TreasuryIcon(
            icon: treasuryScreenIcon(TreasuryScreen.account),
            selected: _screen == TreasuryScreen.account,
          ),
          title: const Text('Cuenta'),
          selected: _screen == TreasuryScreen.account,
          selectedTileColor: fluuixGold.withValues(alpha: 0.12),
          onTap: () {
            _closeTreasuryNav();
            _openScreen(TreasuryScreen.account);
          },
        ),
      ],
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
