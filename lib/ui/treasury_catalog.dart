enum TreasuryGroup { today, boxes, treasury, token, fluuix, account }

enum TreasuryScreen {
  dashboard,
  alerts,
  boxDollars,
  boxLocal,
  boxEntry,
  boxReserve,
  boxTrust,
  boxFund,
  boxTender,
  boxDonation,
  boxCrowd,
  forecast,
  collections,
  payments,
  convert,
  international,
  reconcile,
  caps,
  tokenInventory,
  tokenShares,
  tokenEscrow,
  tokenContracts,
  tokenDocuments,
  tokenProperty,
  tokenZone,
  tokenTtn,
  schemeAllOrNothing,
  schemeBidBond,
  schemeProgress,
  schemeMilestoneGift,
  schemeNavFund,
  factoring,
  quotes,
  assistant,
  account,
}

class TreasuryItem {
  const TreasuryItem(this.screen, this.group, this.label);
  final TreasuryScreen screen;
  final TreasuryGroup group;
  final String label;
}

const treasuryMenu = <TreasuryItem>[
  TreasuryItem(TreasuryScreen.dashboard, TreasuryGroup.today, 'Posición'),
  TreasuryItem(TreasuryScreen.alerts, TreasuryGroup.today, 'Avisos'),
  TreasuryItem(TreasuryScreen.boxDollars, TreasuryGroup.boxes, 'Caja en dólares'),
  TreasuryItem(TreasuryScreen.boxLocal, TreasuryGroup.boxes, 'Riel local'),
  TreasuryItem(TreasuryScreen.boxEntry, TreasuryGroup.boxes, 'Entrada de dólares'),
  TreasuryItem(TreasuryScreen.boxReserve, TreasuryGroup.boxes, 'Reserva'),
  TreasuryItem(TreasuryScreen.boxTrust, TreasuryGroup.boxes, 'Fideicomiso'),
  TreasuryItem(TreasuryScreen.boxFund, TreasuryGroup.boxes, 'Fondo'),
  TreasuryItem(TreasuryScreen.boxTender, TreasuryGroup.boxes, 'Licitación'),
  TreasuryItem(TreasuryScreen.boxDonation, TreasuryGroup.boxes, 'Donación'),
  TreasuryItem(TreasuryScreen.boxCrowd, TreasuryGroup.boxes, 'Crowdfunding'),
  TreasuryItem(TreasuryScreen.forecast, TreasuryGroup.treasury, 'Previsión'),
  TreasuryItem(TreasuryScreen.collections, TreasuryGroup.treasury, 'Cobros'),
  TreasuryItem(TreasuryScreen.payments, TreasuryGroup.treasury, 'Pagos'),
  TreasuryItem(TreasuryScreen.convert, TreasuryGroup.treasury, 'Conversión a USDC'),
  TreasuryItem(TreasuryScreen.international, TreasuryGroup.treasury, 'Exterior'),
  TreasuryItem(TreasuryScreen.reconcile, TreasuryGroup.treasury, 'Conciliación'),
  TreasuryItem(TreasuryScreen.caps, TreasuryGroup.treasury, 'Topes'),
  TreasuryItem(TreasuryScreen.tokenInventory, TreasuryGroup.token, 'Inventario'),
  TreasuryItem(TreasuryScreen.tokenShares, TreasuryGroup.token, 'Participaciones'),
  TreasuryItem(TreasuryScreen.tokenEscrow, TreasuryGroup.token, 'Escrow para inversores'),
  TreasuryItem(TreasuryScreen.tokenContracts, TreasuryGroup.token, 'Contratos'),
  TreasuryItem(TreasuryScreen.tokenDocuments, TreasuryGroup.token, 'Documentos'),
  TreasuryItem(TreasuryScreen.tokenProperty, TreasuryGroup.token, 'Inmuebles'),
  TreasuryItem(TreasuryScreen.tokenZone, TreasuryGroup.token, 'Zona Franca'),
  TreasuryItem(TreasuryScreen.tokenTtn, TreasuryGroup.token, 'TTN'),
  TreasuryItem(TreasuryScreen.schemeAllOrNothing, TreasuryGroup.token, 'Todo o nada'),
  TreasuryItem(TreasuryScreen.schemeBidBond, TreasuryGroup.token, 'Garantía de oferta'),
  TreasuryItem(TreasuryScreen.schemeProgress, TreasuryGroup.token, 'Pago por avance'),
  TreasuryItem(TreasuryScreen.schemeMilestoneGift, TreasuryGroup.token, 'Donación por hito'),
  TreasuryItem(TreasuryScreen.schemeNavFund, TreasuryGroup.token, 'Fondo contra valor'),
  TreasuryItem(TreasuryScreen.factoring, TreasuryGroup.fluuix, 'Factoring'),
  TreasuryItem(TreasuryScreen.quotes, TreasuryGroup.fluuix, 'Fondos y cotizaciones'),
  TreasuryItem(TreasuryScreen.assistant, TreasuryGroup.fluuix, 'Asistente'),
  TreasuryItem(TreasuryScreen.account, TreasuryGroup.account, 'Cuenta'),
];

String treasuryGroupLabel(TreasuryGroup group) => switch (group) {
  TreasuryGroup.today => 'Hoy',
  TreasuryGroup.boxes => 'Cajas',
  TreasuryGroup.treasury => 'Tesorería',
  TreasuryGroup.token => 'Tokenización',
  TreasuryGroup.fluuix => 'Fluuix',
  TreasuryGroup.account => 'Cuenta',
};

TreasuryItem treasuryItem(TreasuryScreen screen) =>
    treasuryMenu.firstWhere((item) => item.screen == screen);

const treasuryNotOnPhone = 'Este paso no sale del teléfono todavía.';
