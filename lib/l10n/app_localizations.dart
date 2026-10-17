import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('pt'),
    Locale('zh'),
  ];

  /// Application title
  ///
  /// In es, this message translates to:
  /// **'FluuiX'**
  String get appTitle;

  /// Application title in lab mode
  ///
  /// In es, this message translates to:
  /// **'AW · Laboratorio de texto'**
  String get appTitleLab;

  /// Main tagline shown in splash
  ///
  /// In es, this message translates to:
  /// **'Caja en dólares'**
  String get taglineDollarBox;

  /// Badge indicating testnet environment
  ///
  /// In es, this message translates to:
  /// **'TESTNET'**
  String get testnetBadge;

  /// Bottom navigation: wallet/box tab
  ///
  /// In es, this message translates to:
  /// **'Caja'**
  String get navCaja;

  /// Bottom navigation: agent tab
  ///
  /// In es, this message translates to:
  /// **'Agente'**
  String get navAgente;

  /// Bottom navigation: network tab
  ///
  /// In es, this message translates to:
  /// **'Red'**
  String get navRed;

  /// Bottom navigation: settings tab
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get navAjustes;

  /// Status when RPC connection is pending
  ///
  /// In es, this message translates to:
  /// **'Conexión pendiente'**
  String get connectionPending;

  /// Status when RPC is verified
  ///
  /// In es, this message translates to:
  /// **'RPC verificado · Arc Testnet'**
  String get rpcVerified;

  /// Dollar box section title
  ///
  /// In es, this message translates to:
  /// **'Caja en dólares'**
  String get cajaEnDolares;

  /// USDC token symbol
  ///
  /// In es, this message translates to:
  /// **'USDC'**
  String get balanceUsdc;

  /// Explanation of Arc Testnet balance
  ///
  /// In es, this message translates to:
  /// **'Arc Testnet · un solo saldo para pagos y comisiones. No incluye el riel local ni la reserva.'**
  String get arcTestnetSingleBalance;

  /// Status chip: Arc verified
  ///
  /// In es, this message translates to:
  /// **'Arc verificado'**
  String get arcVerified;

  /// Status chip: Arc not verified
  ///
  /// In es, this message translates to:
  /// **'Arc sin verificar'**
  String get arcNotVerified;

  /// Status chip: session active
  ///
  /// In es, this message translates to:
  /// **'Sesión activa'**
  String get sessionActive;

  /// Status chip: no session
  ///
  /// In es, this message translates to:
  /// **'Sin sesión'**
  String get noSession;

  /// Status chip showing remaining cap
  ///
  /// In es, this message translates to:
  /// **'Tope restante {amount} USDC'**
  String remainingCapLabel(String amount);

  /// Session info with chain ID
  ///
  /// In es, this message translates to:
  /// **'Sesión en Arc Testnet · cadena {chainId}'**
  String sessionOnArcTestnet(String chainId);

  /// Button to disconnect wallet
  ///
  /// In es, this message translates to:
  /// **'Desconectar'**
  String get disconnect;

  /// Button to view account in explorer
  ///
  /// In es, this message translates to:
  /// **'Ver cuenta'**
  String get viewAccount;

  /// Local rail card title
  ///
  /// In es, this message translates to:
  /// **'Riel local'**
  String get localRail;

  /// Reserve card title
  ///
  /// In es, this message translates to:
  /// **'Reserva'**
  String get reserve;

  /// Status when no contract is deployed
  ///
  /// In es, this message translates to:
  /// **'Sin contrato'**
  String get noContract;

  /// Note that rail is not added to box
  ///
  /// In es, this message translates to:
  /// **'No se suma a la caja.'**
  String get notAddedToBox;

  /// Pay panel button
  ///
  /// In es, this message translates to:
  /// **'Pagar'**
  String get pay;

  /// Receive panel button
  ///
  /// In es, this message translates to:
  /// **'Recibir'**
  String get receive;

  /// Bridge/passage panel button
  ///
  /// In es, this message translates to:
  /// **'Pasar'**
  String get passage;

  /// Cap/limit panel button
  ///
  /// In es, this message translates to:
  /// **'Tope'**
  String get cap;

  /// Pay form title
  ///
  /// In es, this message translates to:
  /// **'Pagar'**
  String get payTitle;

  /// Pay form description
  ///
  /// In es, this message translates to:
  /// **'La orden se revisa en FluuiX y se firma en tu wallet. Si supera el tope, no se arma.'**
  String get payDescription;

  /// Recipient address field label
  ///
  /// In es, this message translates to:
  /// **'Dirección del destinatario'**
  String get recipientAddress;

  /// Recipient address field hint
  ///
  /// In es, this message translates to:
  /// **'0x…'**
  String get recipientHint;

  /// Amount field label
  ///
  /// In es, this message translates to:
  /// **'Importe'**
  String get amount;

  /// Amount field helper text
  ///
  /// In es, this message translates to:
  /// **'Hasta 6 decimales. No se redondea.'**
  String get amountHelper;

  /// Processing state text
  ///
  /// In es, this message translates to:
  /// **'Procesando…'**
  String get processing;

  /// Button to review transfer
  ///
  /// In es, this message translates to:
  /// **'Revisar transferencia'**
  String get reviewTransfer;

  /// Button to connect wallet
  ///
  /// In es, this message translates to:
  /// **'Conectar wallet'**
  String get connectWallet;

  /// Button to request adding Arc Testnet to wallet
  ///
  /// In es, this message translates to:
  /// **'Solicitar agregar Arc Testnet'**
  String get requestAddArcTestnet;

  /// Link to get test USDC from faucet
  ///
  /// In es, this message translates to:
  /// **'Obtener USDC de prueba'**
  String get getTestUsdc;

  /// Receive panel title
  ///
  /// In es, this message translates to:
  /// **'Recibir'**
  String get receiveTitle;

  /// Prompt to connect wallet to see address
  ///
  /// In es, this message translates to:
  /// **'Conectá la wallet para mostrar la dirección de la caja. FluuiX no genera una cuenta propia.'**
  String get receiveConnectPrompt;

  /// Receive address description
  ///
  /// In es, this message translates to:
  /// **'Esta dirección recibe USDC en Arc Testnet. No es una cuenta bancaria.'**
  String get receiveDescription;

  /// Passage/bridge panel title
  ///
  /// In es, this message translates to:
  /// **'Pasar'**
  String get passageTitle;

  /// Passage not connected message
  ///
  /// In es, this message translates to:
  /// **'El pasaje Arbitrum → Arc por CCTP no está conectado. No hay saldo de otra cadena en esta pantalla y no se arma un puente.'**
  String get passageNotConnected;

  /// Cap panel title
  ///
  /// In es, this message translates to:
  /// **'Tope'**
  String get capTitle;

  /// Per-payment cap display
  ///
  /// In es, this message translates to:
  /// **'Por pago: {amount} USDC'**
  String perPaymentCap(String amount);

  /// Per-day cap display
  ///
  /// In es, this message translates to:
  /// **'Por día: {amount} USDC'**
  String perDayCap(String amount);

  /// Amount used today
  ///
  /// In es, this message translates to:
  /// **'Usado hoy: {amount} USDC'**
  String usedToday(String amount);

  /// Remaining amount today
  ///
  /// In es, this message translates to:
  /// **'Restante hoy: {amount} USDC'**
  String remainingToday(String amount);

  /// Explanation of local cap policy
  ///
  /// In es, this message translates to:
  /// **'Política local de esta app, contada con recibos confirmados en este teléfono. No es un Agent Wallet de Circle. Si el importe la supera, la orden no se arma.'**
  String get capPolicyExplanation;

  /// Activity section title
  ///
  /// In es, this message translates to:
  /// **'Actividad'**
  String get activity;

  /// Message when no receipts are saved
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay un recibo guardado en este teléfono.'**
  String get noReceiptSaved;

  /// Note about transaction hash
  ///
  /// In es, this message translates to:
  /// **'El hash es el recibo. No reemplaza el extracto del banco.'**
  String get hashIsReceipt;

  /// Unresolved request warning title
  ///
  /// In es, this message translates to:
  /// **'Solicitud sin resolver'**
  String get unresolvedRequest;

  /// Instructions to check wallet history
  ///
  /// In es, this message translates to:
  /// **'Revisá el historial y las solicitudes en tu wallet antes de otro envío. Si hay un hash, pegalo para comprobarlo.'**
  String get checkWalletHistory;

  /// Transaction hash input label
  ///
  /// In es, this message translates to:
  /// **'Hash de transacción 0x…'**
  String get transactionHashLabel;

  /// Button to check hash
  ///
  /// In es, this message translates to:
  /// **'Comprobar hash'**
  String get checkHash;

  /// Button to acknowledge cancelled request
  ///
  /// In es, this message translates to:
  /// **'La solicitud fue cancelada o rechazada'**
  String get requestCancelledOrRejected;

  /// Transaction state: submitted
  ///
  /// In es, this message translates to:
  /// **'Enviada · esperando recibo'**
  String get txSubmitted;

  /// Transaction state: confirmed
  ///
  /// In es, this message translates to:
  /// **'Confirmada · ejecución exitosa'**
  String get txConfirmed;

  /// Transaction state: reverted
  ///
  /// In es, this message translates to:
  /// **'Revertida · la operación falló en la red'**
  String get txReverted;

  /// Transaction state: pending
  ///
  /// In es, this message translates to:
  /// **'Pendiente · todavía sin recibo'**
  String get txPending;

  /// Transaction state: unknown
  ///
  /// In es, this message translates to:
  /// **'Estado no verificado · consultá el explorador'**
  String get txUnknown;

  /// Confirmed status label
  ///
  /// In es, this message translates to:
  /// **'Confirmada'**
  String get confirmed;

  /// Block number display
  ///
  /// In es, this message translates to:
  /// **'Bloque {number}'**
  String blockLabel(String number);

  /// Button to check receipt
  ///
  /// In es, this message translates to:
  /// **'Comprobar recibo'**
  String get checkReceipt;

  /// Button to open block explorer
  ///
  /// In es, this message translates to:
  /// **'Abrir explorador'**
  String get openExplorer;

  /// Daily orders/missions title
  ///
  /// In es, this message translates to:
  /// **'Órdenes del día'**
  String get dailyOrders;

  /// Explanation of daily orders checklist
  ///
  /// In es, this message translates to:
  /// **'Cada ítem refleja un evento ya observado en esta sesión. No es una transferencia simulada.'**
  String get ordersExplanation;

  /// Order: verify Arc Testnet
  ///
  /// In es, this message translates to:
  /// **'Verificar Arc Testnet'**
  String get orderVerifyArc;

  /// Order: execute Rust on device
  ///
  /// In es, this message translates to:
  /// **'Ejecutar Rust en el dispositivo'**
  String get orderExecuteRust;

  /// Order: activate OpenHuman agent
  ///
  /// In es, this message translates to:
  /// **'Activar OpenHuman'**
  String get orderActivateOpenHuman;

  /// Order: connect Arc account
  ///
  /// In es, this message translates to:
  /// **'Conectar una cuenta en Arc'**
  String get orderConnectArcAccount;

  /// Order: confirm real testnet transfer
  ///
  /// In es, this message translates to:
  /// **'Confirmar una transferencia real de testnet'**
  String get orderConfirmTransfer;

  /// Agent section title
  ///
  /// In es, this message translates to:
  /// **'Agente de la caja'**
  String get agentBoxTitle;

  /// Agent section title in lab mode
  ///
  /// In es, this message translates to:
  /// **'Consulta al laboratorio'**
  String get agentLabTitle;

  /// Initial agent status message
  ///
  /// In es, this message translates to:
  /// **'Verificá el runtime y configurá la inferencia'**
  String get agentVerifyStatus;

  /// Agent description
  ///
  /// In es, this message translates to:
  /// **'El agente propone órdenes con arc_network_status y arc_balance. Una herramienta ejecutada muestra el dato que leyó Rust. El texto del modelo no autoriza ni firma.'**
  String get agentDescription;

  /// Agent description in lab mode
  ///
  /// In es, this message translates to:
  /// **'OpenHuman coordina la consulta dentro de AW. El modelo debe ejecutarse en tu laboratorio, a través del endpoint loopback que configures. No se inicia ninguna consulta de blockchain.'**
  String get agentLabDescription;

  /// Button to verify native Rust execution
  ///
  /// In es, this message translates to:
  /// **'Verificar ejecución nativa de Rust'**
  String get verifyNativeRust;

  /// Library execution info
  ///
  /// In es, this message translates to:
  /// **'Biblioteca ejecutada: {os} / {arch}'**
  String libraryExecuted(String os, String arch);

  /// Allowed tools list
  ///
  /// In es, this message translates to:
  /// **'Herramientas permitidas: {tools}'**
  String allowedTools(String tools);

  /// No tools allowed
  ///
  /// In es, this message translates to:
  /// **'ninguna'**
  String get noTools;

  /// Runtime not initialized message
  ///
  /// In es, this message translates to:
  /// **'Runtime sin inicializar. La política de herramientas se comprueba al inicializar.'**
  String get runtimeNotInitialized;

  /// Native policy mode
  ///
  /// In es, this message translates to:
  /// **'Política nativa: {mode}'**
  String nativePolicy(String mode);

  /// Not started status
  ///
  /// In es, this message translates to:
  /// **'sin iniciar'**
  String get notStarted;

  /// Agent token budget
  ///
  /// In es, this message translates to:
  /// **'Presupuesto del agente: {tokens} tokens. No acredita la capacidad real del modelo.'**
  String agentBudget(String tokens);

  /// Disclaimer about local test
  ///
  /// In es, this message translates to:
  /// **'Esta prueba local no implica que la inferencia o una transferencia hayan sido verificadas.'**
  String get localTestDisclaimer;

  /// Lab test disclaimer
  ///
  /// In es, this message translates to:
  /// **'Ejecutar esta biblioteca no verifica todavía el modelo del laboratorio.'**
  String get labTestDisclaimer;

  /// Button to configure lab
  ///
  /// In es, this message translates to:
  /// **'Configurar laboratorio'**
  String get configureLabButton;

  /// Button to configure provider
  ///
  /// In es, this message translates to:
  /// **'Configurar proveedor e iniciar agente'**
  String get configureProviderButton;

  /// Agent query input label
  ///
  /// In es, this message translates to:
  /// **'Tu consulta al agente'**
  String get queryLabel;

  /// Preset query: Arc status
  ///
  /// In es, this message translates to:
  /// **'Estado real de Arc'**
  String get presetArcStatus;

  /// Preset query: check balance
  ///
  /// In es, this message translates to:
  /// **'Consultar mi saldo'**
  String get presetMyBalance;

  /// Agent busy status
  ///
  /// In es, this message translates to:
  /// **'Agente trabajando…'**
  String get agentWorking;

  /// Button to query agent
  ///
  /// In es, this message translates to:
  /// **'Consultar OpenHuman'**
  String get queryOpenHuman;

  /// Button to cancel agent turn
  ///
  /// In es, this message translates to:
  /// **'Cancelar turno'**
  String get cancelTurn;

  /// Model text section title
  ///
  /// In es, this message translates to:
  /// **'Texto del modelo'**
  String get modelText;

  /// Model text disclaimer
  ///
  /// In es, this message translates to:
  /// **'Eso es texto del modelo. No es una lectura de red ni una firma.'**
  String get modelTextDisclaimer;

  /// Executed tools list
  ///
  /// In es, this message translates to:
  /// **'Herramientas ejecutadas: {tools}'**
  String toolsExecuted(String tools);

  /// Live read tool name
  ///
  /// In es, this message translates to:
  /// **'Lectura ejecutada · {tool}'**
  String liveReadTool(String tool);

  /// Block number
  ///
  /// In es, this message translates to:
  /// **'Bloque: {number}'**
  String blockNumber(String number);

  /// USDC balance label
  ///
  /// In es, this message translates to:
  /// **'Saldo USDC: {balance}'**
  String balanceUsdcLabel(String balance);

  /// Unix timestamp observation
  ///
  /// In es, this message translates to:
  /// **'Observación UNIX: {timestamp}'**
  String observationUnix(String timestamp);

  /// Tool result success
  ///
  /// In es, this message translates to:
  /// **'Resultado obtenido por la herramienta Rust'**
  String get toolResultOk;

  /// Tool result failure
  ///
  /// In es, this message translates to:
  /// **'La herramienta no pudo completar la lectura'**
  String get toolResultFailed;

  /// Button to apply agent proposal
  ///
  /// In es, this message translates to:
  /// **'Llevar propuesta al formulario'**
  String get applyProposal;

  /// Agent response disclaimer
  ///
  /// In es, this message translates to:
  /// **'Una respuesta del modelo no es una confirmación de pago. El agente sólo propone; la firma requiere tu revisión en la wallet.'**
  String get agentResponseDisclaimer;

  /// Lab response disclaimer
  ///
  /// In es, this message translates to:
  /// **'La salida del modelo es texto no confiable. No se interpreta como una instrucción ni habilita acciones.'**
  String get labResponseDisclaimer;

  /// Last query log title
  ///
  /// In es, this message translates to:
  /// **'Registro de la última consulta'**
  String get lastQueryLog;

  /// Log metadata note
  ///
  /// In es, this message translates to:
  /// **'Sólo metadatos del cliente. Cotejá este ID con el procesamiento real en tu servidor y con la respuesta visible. No se incluyen mensajes ni claves.'**
  String get logMetadataNote;

  /// Button to copy log without sensitive data
  ///
  /// In es, this message translates to:
  /// **'Copiar registro sin mensajes ni claves'**
  String get copyLogWithoutKeys;

  /// Button to restart after interrupted turn
  ///
  /// In es, this message translates to:
  /// **'Reiniciar después del turno interrumpido'**
  String get restartAfterInterrupted;

  /// Network section title
  ///
  /// In es, this message translates to:
  /// **'Red FluuiX'**
  String get networkTitle;

  /// Network section description
  ///
  /// In es, this message translates to:
  /// **'Cada módulo está sin contrato hasta que el operador entregue endpoint, autenticación y catálogo. No hay saldos, tasas ni préstamos.'**
  String get networkDescription;

  /// ZonaBank module title
  ///
  /// In es, this message translates to:
  /// **'ZonaBank'**
  String get zonaBankTitle;

  /// ZonaBank module description
  ///
  /// In es, this message translates to:
  /// **'Cuentas, contactos, intents y rieles de liquidación. ZonaBank no guarda claves y no es un banco licenciado.'**
  String get zonaBankDesc;

  /// Lending module title
  ///
  /// In es, this message translates to:
  /// **'Lending'**
  String get lendingTitle;

  /// Lending module description
  ///
  /// In es, this message translates to:
  /// **'El mapa público habla de financiamiento contra colateral tokenizado. No hay catálogo, tasa ni préstamo en esta app.'**
  String get lendingDesc;

  /// ZonaFranca module title
  ///
  /// In es, this message translates to:
  /// **'ZonaFranca'**
  String get zonaFrancaTitle;

  /// ZonaFranca module description
  ///
  /// In es, this message translates to:
  /// **'Registro y trazabilidad de mercancía y logística. Solo lectura cuando haya catálogo.'**
  String get zonaFrancaDesc;

  /// TTN module title
  ///
  /// In es, this message translates to:
  /// **'TTN'**
  String get ttnTitle;

  /// TTN module description
  ///
  /// In es, this message translates to:
  /// **'Instrumentos ya emitidos por TokenizaTuNegocio. Emitir un token no es una orden del teléfono.'**
  String get ttnDesc;

  /// Capital section title
  ///
  /// In es, this message translates to:
  /// **'Capital'**
  String get capitalSection;

  /// Fideicomisos module title
  ///
  /// In es, this message translates to:
  /// **'Fideicomisos'**
  String get fideicomisosTitle;

  /// Fideicomisos module description
  ///
  /// In es, this message translates to:
  /// **'Vehículo de capital del mismo motor. Sin posición que mostrar.'**
  String get fideicomisosDesc;

  /// Fondos module title
  ///
  /// In es, this message translates to:
  /// **'Fondos'**
  String get fondosTitle;

  /// Fondos module description
  ///
  /// In es, this message translates to:
  /// **'Vehículo de capital del mismo motor. Sin posición que mostrar.'**
  String get fondosDesc;

  /// Crowd module title
  ///
  /// In es, this message translates to:
  /// **'Crowd'**
  String get crowdTitle;

  /// Crowd module description
  ///
  /// In es, this message translates to:
  /// **'Financiamiento con la comunidad. Sin campaña cargada.'**
  String get crowdDesc;

  /// Licitaciones module title
  ///
  /// In es, this message translates to:
  /// **'Licitaciones'**
  String get licitacionesTitle;

  /// Licitaciones module description
  ///
  /// In es, this message translates to:
  /// **'Compras con recibo verificable. Sin proceso cargado.'**
  String get licitacionesDesc;

  /// Donaciones module title
  ///
  /// In es, this message translates to:
  /// **'Donaciones'**
  String get donacionesTitle;

  /// Donaciones module description
  ///
  /// In es, this message translates to:
  /// **'Donación con trazabilidad. Sin campaña cargada.'**
  String get donacionesDesc;

  /// Academia module title
  ///
  /// In es, this message translates to:
  /// **'Academia'**
  String get academiaTitle;

  /// Academia module description
  ///
  /// In es, this message translates to:
  /// **'Formación de TokenizaTuNegocio. No mueve fondos.'**
  String get academiaDesc;

  /// Link to product public page
  ///
  /// In es, this message translates to:
  /// **'Qué publica el producto'**
  String get whatProductPublishes;

  /// Settings section title
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settingsTitle;

  /// Settings title in lab mode
  ///
  /// In es, this message translates to:
  /// **'Configuración del laboratorio'**
  String get settingsLabTitle;

  /// WalletConnect settings section
  ///
  /// In es, this message translates to:
  /// **'WalletConnect / Reown'**
  String get walletConnectTitle;

  /// WalletConnect settings description
  ///
  /// In es, this message translates to:
  /// **'Ingresá el Project ID de tu proyecto. Se puede cambiar sin recompilar. La sesión de wallet permanece sólo en memoria; al reiniciar la app se vuelve a conectar. FluuiX no pide la frase semilla ni la clave privada.'**
  String get walletConnectDescription;

  /// Project ID input label
  ///
  /// In es, this message translates to:
  /// **'Project ID'**
  String get projectIdLabel;

  /// Project ID input hint
  ///
  /// In es, this message translates to:
  /// **'32 caracteres hexadecimales'**
  String get projectIdHint;

  /// Connecting state
  ///
  /// In es, this message translates to:
  /// **'Conectando…'**
  String get connecting;

  /// Button to save and connect Reown
  ///
  /// In es, this message translates to:
  /// **'Guardar y conectar Reown'**
  String get saveAndConnectReown;

  /// Reown client initialized status
  ///
  /// In es, this message translates to:
  /// **'Cliente Reown inicializado'**
  String get reownClientInitialized;

  /// Inference settings section
  ///
  /// In es, this message translates to:
  /// **'Inferencia para OpenHuman'**
  String get inferenceTitle;

  /// Inference settings title in lab mode
  ///
  /// In es, this message translates to:
  /// **'Servidor de texto local'**
  String get inferenceLabTitle;

  /// Inference settings description
  ///
  /// In es, this message translates to:
  /// **'Elegí un endpoint compatible con OpenAI y el modelo habilitado por tu proveedor. El modelo usa Internet; el runtime Rust se ejecuta en el teléfono.'**
  String get inferenceDescription;

  /// Inference settings description in lab mode
  ///
  /// In es, this message translates to:
  /// **'Ingresá la IP loopback literal y la ruta /v1 del transporte que estableciste hacia tu servidor autorizado. Elegí un modelo que ya esté instalado allí. No hay endpoint ni modelo predeterminados.'**
  String get inferenceLabDescription;

  /// Endpoint input label
  ///
  /// In es, this message translates to:
  /// **'Endpoint HTTPS'**
  String get endpointLabel;

  /// Endpoint input label in lab mode
  ///
  /// In es, this message translates to:
  /// **'Endpoint loopback /v1'**
  String get endpointLabLabel;

  /// Endpoint input hint
  ///
  /// In es, this message translates to:
  /// **'https://provider.example/v1'**
  String get endpointHint;

  /// Endpoint input hint in lab mode
  ///
  /// In es, this message translates to:
  /// **'Completá tu endpoint autorizado'**
  String get endpointLabHint;

  /// Model ID input label
  ///
  /// In es, this message translates to:
  /// **'ID del modelo'**
  String get modelLabel;

  /// Model ID input hint
  ///
  /// In es, this message translates to:
  /// **'Modelo habilitado en tu proveedor'**
  String get modelHint;

  /// Model ID input hint in lab mode
  ///
  /// In es, this message translates to:
  /// **'ID exacto del modelo local instalado'**
  String get modelLabHint;

  /// API key input label
  ///
  /// In es, this message translates to:
  /// **'API key de inferencia'**
  String get apiKeyLabel;

  /// API key input label in lab mode
  ///
  /// In es, this message translates to:
  /// **'Clave o marcador del servidor'**
  String get apiKeyLabLabel;

  /// API key helper text in lab mode
  ///
  /// In es, this message translates to:
  /// **'Un marcador sintético no protege ni autentica el servidor.'**
  String get apiKeyLabHelper;

  /// Remember key checkbox label
  ///
  /// In es, this message translates to:
  /// **'Recordar la clave en el almacenamiento seguro del sistema'**
  String get rememberKey;

  /// Note about where queries are sent
  ///
  /// In es, this message translates to:
  /// **'Al activar y consultar, enviás tus mensajes y el contexto necesario a {host}.'**
  String queriesSentTo(String host);

  /// Lab queries note
  ///
  /// In es, this message translates to:
  /// **'Las consultas se envían únicamente al endpoint indicado. Los ajustes del laboratorio se guardan separados de los del modo Arc.'**
  String get labQueriesNote;

  /// Initializing state
  ///
  /// In es, this message translates to:
  /// **'Inicializando…'**
  String get initializing;

  /// Button to start lab
  ///
  /// In es, this message translates to:
  /// **'Iniciar laboratorio de texto'**
  String get startLabButton;

  /// Button to activate OpenHuman
  ///
  /// In es, this message translates to:
  /// **'Activar OpenHuman con este proveedor'**
  String get activateOpenHumanButton;

  /// Button to stop agent and forget key
  ///
  /// In es, this message translates to:
  /// **'Detener agente y olvidar la clave'**
  String get stopAgentForgetKey;

  /// Expansion tile: add Arc manually
  ///
  /// In es, this message translates to:
  /// **'Agregar Arc Testnet manualmente'**
  String get addArcTestnetManually;

  /// Arc Testnet manual configuration info
  ///
  /// In es, this message translates to:
  /// **'Nombre: Arc Testnet\nChain ID: 5042002\nMoneda nativa: USDC · 18 decimales'**
  String get arcManualInfo;

  /// Arc Testnet manual configuration instructions
  ///
  /// In es, this message translates to:
  /// **'Agregá la red en tu wallet, luego reconectá autorizando Arc Testnet. Agregar una red no amplía automáticamente los permisos de una sesión existente.'**
  String get arcManualInstructions;

  /// Link to official documentation
  ///
  /// In es, this message translates to:
  /// **'Documentación oficial'**
  String get officialDocs;

  /// Button to retry reading secure storage
  ///
  /// In es, this message translates to:
  /// **'Volver a leer el estado seguro'**
  String get retrySecureStorage;

  /// Dialog title: connect wallet
  ///
  /// In es, this message translates to:
  /// **'Conectá tu wallet'**
  String get connectYourWallet;

  /// Wallet connect dialog instructions
  ///
  /// In es, this message translates to:
  /// **'Escaneá desde otra pantalla o abrí una wallet compatible con WalletConnect. Volvé a FluuiX después de aprobar.'**
  String get scanFromOtherScreen;

  /// Wallet connect dialog note
  ///
  /// In es, this message translates to:
  /// **'La wallet debe tener Arc Testnet configurada. La conexión no envía fondos.'**
  String get walletMustHaveArc;

  /// Button: go back
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get goBack;

  /// Button: copy URI
  ///
  /// In es, this message translates to:
  /// **'Copiar URI'**
  String get copyUri;

  /// Button: open wallet
  ///
  /// In es, this message translates to:
  /// **'Abrir wallet'**
  String get openWallet;

  /// Snackbar: URI copied
  ///
  /// In es, this message translates to:
  /// **'URI copiada. Pegala en WalletConnect dentro de tu wallet.'**
  String get uriCopied;

  /// Snackbar: use copy or QR
  ///
  /// In es, this message translates to:
  /// **'Usá Copiar URI y pegala en tu wallet, o escaneá el QR.'**
  String get useCopyUriOrQr;

  /// Snackbar: no wallet for link
  ///
  /// In es, this message translates to:
  /// **'No se encontró una wallet para este enlace. Usá el QR o copiá la URI.'**
  String get noWalletForLink;

  /// Review dialog title
  ///
  /// In es, this message translates to:
  /// **'Revisá la transferencia'**
  String get reviewTransferTitle;

  /// Review dialog: testnet funds note
  ///
  /// In es, this message translates to:
  /// **'Arc Testnet · fondos de prueba'**
  String get arcTestnetTestFunds;

  /// Review dialog: from label
  ///
  /// In es, this message translates to:
  /// **'Desde'**
  String get from;

  /// Review dialog: recipient label
  ///
  /// In es, this message translates to:
  /// **'Destinatario'**
  String get recipient;

  /// Review dialog: max fee
  ///
  /// In es, this message translates to:
  /// **'Comisión máxima: {amount} USDC'**
  String maxFee(String amount);

  /// Review dialog: max total
  ///
  /// In es, this message translates to:
  /// **'Total máximo: {amount} USDC'**
  String maxTotal(String amount);

  /// Review dialog: expiry note
  ///
  /// In es, this message translates to:
  /// **'La revisión vence en 2 minutos. Verificá en tu wallet que la red, el destinatario, el importe y la comisión coincidan. Tu wallet solicita la firma final.'**
  String get reviewExpiry;

  /// Button: cancel
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// Button: request approval
  ///
  /// In es, this message translates to:
  /// **'Solicitar aprobación'**
  String get requestApproval;

  /// Dialog title: confirm wallet state
  ///
  /// In es, this message translates to:
  /// **'Confirmá el estado en tu wallet'**
  String get confirmWalletState;

  /// Confirm no send dialog message
  ///
  /// In es, this message translates to:
  /// **'Continuá sólo si verificaste que la solicitud anterior fue rechazada o cancelada y que no existe una transferencia pendiente o enviada. Repetir un envío puede duplicar el pago.'**
  String get confirmNoSendMessage;

  /// Button: verified not sent
  ///
  /// In es, this message translates to:
  /// **'Verifiqué que no se envió'**
  String get verifiedNotSent;

  /// Snackbar: proposal validated
  ///
  /// In es, this message translates to:
  /// **'Propuesta validada y copiada. Revisá destinatario, importe y comisión antes de firmar.'**
  String get proposalValidatedCopied;

  /// Snackbar: could not open link
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el enlace.'**
  String get couldNotOpenLink;

  /// Footer disclaimer
  ///
  /// In es, this message translates to:
  /// **'Arc Testnet · USDC de prueba\nLa wallet externa controla tus claves y pide la firma. FluuiX no solicita frases semilla ni claves privadas.'**
  String get footerArcTestnet;

  /// Footer disclaimer in lab mode
  ///
  /// In es, this message translates to:
  /// **'AW no cambia de proveedor automáticamente. Confirmá que el servidor autorizado ejecuta un modelo local; recibir texto no demuestra por sí solo su procedencia.'**
  String get footerLab;

  /// Lab banner title
  ///
  /// In es, this message translates to:
  /// **'Laboratorio · sólo texto'**
  String get labBannerTitle;

  /// Lab banner description
  ///
  /// In es, this message translates to:
  /// **'Wallet, pagos, propuestas y consultas Arc deshabilitados. El agente no dispone de herramientas. Este modo queda fijo al compilar la app.'**
  String get labBannerDesc;

  /// Tooltip: orders view
  ///
  /// In es, this message translates to:
  /// **'Vista de caja'**
  String get ordersViewTooltip;

  /// Tooltip: mission view
  ///
  /// In es, this message translates to:
  /// **'Órdenes del día'**
  String get missionViewTooltip;

  /// Tooltip: refresh Arc
  ///
  /// In es, this message translates to:
  /// **'Actualizar Arc'**
  String get refreshArcTooltip;

  /// Agent stopped status
  ///
  /// In es, this message translates to:
  /// **'Agente detenido y conversación local descartada'**
  String get agentStoppedStatus;

  /// OpenHuman active status
  ///
  /// In es, this message translates to:
  /// **'OpenHuman local activo · inferencia en {host}'**
  String openHumanLocalActive(String host);

  /// Lab ready status
  ///
  /// In es, this message translates to:
  /// **'Laboratorio listo · endpoint {endpoint} · modelo solicitado {model}'**
  String labReadyStatus(String endpoint, String model);

  /// Turn completed status
  ///
  /// In es, this message translates to:
  /// **'Turno completado por OpenHuman'**
  String get turnCompletedStatus;

  /// Lab response received status
  ///
  /// In es, this message translates to:
  /// **'Respuesta recibida · cotejá el ID con el registro de tu servidor'**
  String get labResponseReceivedStatus;

  /// Rust executed status
  ///
  /// In es, this message translates to:
  /// **'Rust ejecutado en {os}/{arch} · ABI 1'**
  String rustExecutedStatus(String os, String arch);

  /// Context bar: layer label
  ///
  /// In es, this message translates to:
  /// **'Capa'**
  String get contextBarLayer;

  /// Context bar: disconnected
  ///
  /// In es, this message translates to:
  /// **'Desconectada'**
  String get contextBarDisconnected;

  /// Context bar: connected
  ///
  /// In es, this message translates to:
  /// **'Conectada'**
  String get contextBarConnected;

  /// Language settings section
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get languageSettings;

  /// Automatic language option
  ///
  /// In es, this message translates to:
  /// **'Automático (sistema)'**
  String get languageAuto;

  /// Spanish language option
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// English language option
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Portuguese language option
  ///
  /// In es, this message translates to:
  /// **'Português'**
  String get languagePortuguese;

  /// French language option
  ///
  /// In es, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// German language option
  ///
  /// In es, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// Italian language option
  ///
  /// In es, this message translates to:
  /// **'Italiano'**
  String get languageItalian;

  /// Chinese language option
  ///
  /// In es, this message translates to:
  /// **'中文'**
  String get languageChinese;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'it',
    'pt',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'pt':
      return AppLocalizationsPt();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
