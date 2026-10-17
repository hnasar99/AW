// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'FluuiX';

  @override
  String get appTitleLab => 'AW · Laboratorio de texto';

  @override
  String get taglineDollarBox => 'Caja en dólares';

  @override
  String get testnetBadge => 'TESTNET';

  @override
  String get navCaja => 'Caja';

  @override
  String get navAgente => 'Agente';

  @override
  String get navRed => 'Red';

  @override
  String get navAjustes => 'Ajustes';

  @override
  String get connectionPending => 'Conexión pendiente';

  @override
  String get rpcVerified => 'RPC verificado · Arc Testnet';

  @override
  String get cajaEnDolares => 'Caja en dólares';

  @override
  String get balanceUsdc => 'USDC';

  @override
  String get arcTestnetSingleBalance =>
      'Arc Testnet · un solo saldo para pagos y comisiones. No incluye el riel local ni la reserva.';

  @override
  String get arcVerified => 'Arc verificado';

  @override
  String get arcNotVerified => 'Arc sin verificar';

  @override
  String get sessionActive => 'Sesión activa';

  @override
  String get noSession => 'Sin sesión';

  @override
  String remainingCapLabel(String amount) {
    return 'Tope restante $amount USDC';
  }

  @override
  String sessionOnArcTestnet(String chainId) {
    return 'Sesión en Arc Testnet · cadena $chainId';
  }

  @override
  String get disconnect => 'Desconectar';

  @override
  String get viewAccount => 'Ver cuenta';

  @override
  String get localRail => 'Riel local';

  @override
  String get reserve => 'Reserva';

  @override
  String get noContract => 'Sin contrato';

  @override
  String get notAddedToBox => 'No se suma a la caja.';

  @override
  String get pay => 'Pagar';

  @override
  String get receive => 'Recibir';

  @override
  String get passage => 'Pasar';

  @override
  String get cap => 'Tope';

  @override
  String get payTitle => 'Pagar';

  @override
  String get payDescription =>
      'La orden se revisa en FluuiX y se firma en tu wallet. Si supera el tope, no se arma.';

  @override
  String get recipientAddress => 'Dirección del destinatario';

  @override
  String get recipientHint => '0x…';

  @override
  String get amount => 'Importe';

  @override
  String get amountHelper => 'Hasta 6 decimales. No se redondea.';

  @override
  String get processing => 'Procesando…';

  @override
  String get reviewTransfer => 'Revisar transferencia';

  @override
  String get connectWallet => 'Conectar wallet';

  @override
  String get requestAddArcTestnet => 'Solicitar agregar Arc Testnet';

  @override
  String get getTestUsdc => 'Obtener USDC de prueba';

  @override
  String get receiveTitle => 'Recibir';

  @override
  String get receiveConnectPrompt =>
      'Conectá la wallet para mostrar la dirección de la caja. FluuiX no genera una cuenta propia.';

  @override
  String get receiveDescription =>
      'Esta dirección recibe USDC en Arc Testnet. No es una cuenta bancaria.';

  @override
  String get passageTitle => 'Pasar';

  @override
  String get passageNotConnected =>
      'El pasaje Arbitrum → Arc por CCTP no está conectado. No hay saldo de otra cadena en esta pantalla y no se arma un puente.';

  @override
  String get capTitle => 'Tope';

  @override
  String perPaymentCap(String amount) {
    return 'Por pago: $amount USDC';
  }

  @override
  String perDayCap(String amount) {
    return 'Por día: $amount USDC';
  }

  @override
  String usedToday(String amount) {
    return 'Usado hoy: $amount USDC';
  }

  @override
  String remainingToday(String amount) {
    return 'Restante hoy: $amount USDC';
  }

  @override
  String get capPolicyExplanation =>
      'Política local de esta app, contada con recibos confirmados en este teléfono. No es un Agent Wallet de Circle. Si el importe la supera, la orden no se arma.';

  @override
  String get activity => 'Actividad';

  @override
  String get noReceiptSaved =>
      'Todavía no hay un recibo guardado en este teléfono.';

  @override
  String get hashIsReceipt =>
      'El hash es el recibo. No reemplaza el extracto del banco.';

  @override
  String get unresolvedRequest => 'Solicitud sin resolver';

  @override
  String get checkWalletHistory =>
      'Revisá el historial y las solicitudes en tu wallet antes de otro envío. Si hay un hash, pegalo para comprobarlo.';

  @override
  String get transactionHashLabel => 'Hash de transacción 0x…';

  @override
  String get checkHash => 'Comprobar hash';

  @override
  String get requestCancelledOrRejected =>
      'La solicitud fue cancelada o rechazada';

  @override
  String get txSubmitted => 'Enviada · esperando recibo';

  @override
  String get txConfirmed => 'Confirmada · ejecución exitosa';

  @override
  String get txReverted => 'Revertida · la operación falló en la red';

  @override
  String get txPending => 'Pendiente · todavía sin recibo';

  @override
  String get txUnknown => 'Estado no verificado · consultá el explorador';

  @override
  String get confirmed => 'Confirmada';

  @override
  String blockLabel(String number) {
    return 'Bloque $number';
  }

  @override
  String get checkReceipt => 'Comprobar recibo';

  @override
  String get openExplorer => 'Abrir explorador';

  @override
  String get dailyOrders => 'Órdenes del día';

  @override
  String get ordersExplanation =>
      'Cada ítem refleja un evento ya observado en esta sesión. No es una transferencia simulada.';

  @override
  String get orderVerifyArc => 'Verificar Arc Testnet';

  @override
  String get orderExecuteRust => 'Ejecutar Rust en el dispositivo';

  @override
  String get orderActivateOpenHuman => 'Activar OpenHuman';

  @override
  String get orderConnectArcAccount => 'Conectar una cuenta en Arc';

  @override
  String get orderConfirmTransfer =>
      'Confirmar una transferencia real de testnet';

  @override
  String get agentBoxTitle => 'Agente de la caja';

  @override
  String get agentLabTitle => 'Consulta al laboratorio';

  @override
  String get agentVerifyStatus =>
      'Verificá el runtime y configurá la inferencia';

  @override
  String get agentDescription =>
      'El agente propone órdenes con arc_network_status y arc_balance. Una herramienta ejecutada muestra el dato que leyó Rust. El texto del modelo no autoriza ni firma.';

  @override
  String get agentLabDescription =>
      'OpenHuman coordina la consulta dentro de AW. El modelo debe ejecutarse en tu laboratorio, a través del endpoint loopback que configures. No se inicia ninguna consulta de blockchain.';

  @override
  String get verifyNativeRust => 'Verificar ejecución nativa de Rust';

  @override
  String libraryExecuted(String os, String arch) {
    return 'Biblioteca ejecutada: $os / $arch';
  }

  @override
  String allowedTools(String tools) {
    return 'Herramientas permitidas: $tools';
  }

  @override
  String get noTools => 'ninguna';

  @override
  String get runtimeNotInitialized =>
      'Runtime sin inicializar. La política de herramientas se comprueba al inicializar.';

  @override
  String nativePolicy(String mode) {
    return 'Política nativa: $mode';
  }

  @override
  String get notStarted => 'sin iniciar';

  @override
  String agentBudget(String tokens) {
    return 'Presupuesto del agente: $tokens tokens. No acredita la capacidad real del modelo.';
  }

  @override
  String get localTestDisclaimer =>
      'Esta prueba local no implica que la inferencia o una transferencia hayan sido verificadas.';

  @override
  String get labTestDisclaimer =>
      'Ejecutar esta biblioteca no verifica todavía el modelo del laboratorio.';

  @override
  String get configureLabButton => 'Configurar laboratorio';

  @override
  String get configureProviderButton => 'Configurar proveedor e iniciar agente';

  @override
  String get queryLabel => 'Tu consulta al agente';

  @override
  String get presetArcStatus => 'Estado real de Arc';

  @override
  String get presetMyBalance => 'Consultar mi saldo';

  @override
  String get agentWorking => 'Agente trabajando…';

  @override
  String get queryOpenHuman => 'Consultar OpenHuman';

  @override
  String get cancelTurn => 'Cancelar turno';

  @override
  String get modelText => 'Texto del modelo';

  @override
  String get modelTextDisclaimer =>
      'Eso es texto del modelo. No es una lectura de red ni una firma.';

  @override
  String toolsExecuted(String tools) {
    return 'Herramientas ejecutadas: $tools';
  }

  @override
  String liveReadTool(String tool) {
    return 'Lectura ejecutada · $tool';
  }

  @override
  String blockNumber(String number) {
    return 'Bloque: $number';
  }

  @override
  String balanceUsdcLabel(String balance) {
    return 'Saldo USDC: $balance';
  }

  @override
  String observationUnix(String timestamp) {
    return 'Observación UNIX: $timestamp';
  }

  @override
  String get toolResultOk => 'Resultado obtenido por la herramienta Rust';

  @override
  String get toolResultFailed => 'La herramienta no pudo completar la lectura';

  @override
  String get applyProposal => 'Llevar propuesta al formulario';

  @override
  String get agentResponseDisclaimer =>
      'Una respuesta del modelo no es una confirmación de pago. El agente sólo propone; la firma requiere tu revisión en la wallet.';

  @override
  String get labResponseDisclaimer =>
      'La salida del modelo es texto no confiable. No se interpreta como una instrucción ni habilita acciones.';

  @override
  String get lastQueryLog => 'Registro de la última consulta';

  @override
  String get logMetadataNote =>
      'Sólo metadatos del cliente. Cotejá este ID con el procesamiento real en tu servidor y con la respuesta visible. No se incluyen mensajes ni claves.';

  @override
  String get copyLogWithoutKeys => 'Copiar registro sin mensajes ni claves';

  @override
  String get restartAfterInterrupted =>
      'Reiniciar después del turno interrumpido';

  @override
  String get networkTitle => 'Red FluuiX';

  @override
  String get networkDescription =>
      'Cada módulo está sin contrato hasta que el operador entregue endpoint, autenticación y catálogo. No hay saldos, tasas ni préstamos.';

  @override
  String get zonaBankTitle => 'ZonaBank';

  @override
  String get zonaBankDesc =>
      'Cuentas, contactos, intents y rieles de liquidación. ZonaBank no guarda claves y no es un banco licenciado.';

  @override
  String get lendingTitle => 'Lending';

  @override
  String get lendingDesc =>
      'El mapa público habla de financiamiento contra colateral tokenizado. No hay catálogo, tasa ni préstamo en esta app.';

  @override
  String get zonaFrancaTitle => 'ZonaFranca';

  @override
  String get zonaFrancaDesc =>
      'Registro y trazabilidad de mercancía y logística. Solo lectura cuando haya catálogo.';

  @override
  String get ttnTitle => 'TTN';

  @override
  String get ttnDesc =>
      'Instrumentos ya emitidos por TokenizaTuNegocio. Emitir un token no es una orden del teléfono.';

  @override
  String get capitalSection => 'Capital';

  @override
  String get fideicomisosTitle => 'Fideicomisos';

  @override
  String get fideicomisosDesc =>
      'Vehículo de capital del mismo motor. Sin posición que mostrar.';

  @override
  String get fondosTitle => 'Fondos';

  @override
  String get fondosDesc =>
      'Vehículo de capital del mismo motor. Sin posición que mostrar.';

  @override
  String get crowdTitle => 'Crowd';

  @override
  String get crowdDesc =>
      'Financiamiento con la comunidad. Sin campaña cargada.';

  @override
  String get licitacionesTitle => 'Licitaciones';

  @override
  String get licitacionesDesc =>
      'Compras con recibo verificable. Sin proceso cargado.';

  @override
  String get donacionesTitle => 'Donaciones';

  @override
  String get donacionesDesc =>
      'Donación con trazabilidad. Sin campaña cargada.';

  @override
  String get academiaTitle => 'Academia';

  @override
  String get academiaDesc => 'Formación de TokenizaTuNegocio. No mueve fondos.';

  @override
  String get whatProductPublishes => 'Qué publica el producto';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsLabTitle => 'Configuración del laboratorio';

  @override
  String get walletConnectTitle => 'WalletConnect / Reown';

  @override
  String get walletConnectDescription =>
      'Ingresá el Project ID de tu proyecto. Se puede cambiar sin recompilar. La sesión de wallet permanece sólo en memoria; al reiniciar la app se vuelve a conectar. FluuiX no pide la frase semilla ni la clave privada.';

  @override
  String get projectIdLabel => 'Project ID';

  @override
  String get projectIdHint => '32 caracteres hexadecimales';

  @override
  String get connecting => 'Conectando…';

  @override
  String get saveAndConnectReown => 'Guardar y conectar Reown';

  @override
  String get reownClientInitialized => 'Cliente Reown inicializado';

  @override
  String get inferenceTitle => 'Inferencia para OpenHuman';

  @override
  String get inferenceLabTitle => 'Servidor de texto local';

  @override
  String get inferenceDescription =>
      'Elegí un endpoint compatible con OpenAI y el modelo habilitado por tu proveedor. El modelo usa Internet; el runtime Rust se ejecuta en el teléfono.';

  @override
  String get inferenceLabDescription =>
      'Ingresá la IP loopback literal y la ruta /v1 del transporte que estableciste hacia tu servidor autorizado. Elegí un modelo que ya esté instalado allí. No hay endpoint ni modelo predeterminados.';

  @override
  String get endpointLabel => 'Endpoint HTTPS';

  @override
  String get endpointLabLabel => 'Endpoint loopback /v1';

  @override
  String get endpointHint => 'https://provider.example/v1';

  @override
  String get endpointLabHint => 'Completá tu endpoint autorizado';

  @override
  String get modelLabel => 'ID del modelo';

  @override
  String get modelHint => 'Modelo habilitado en tu proveedor';

  @override
  String get modelLabHint => 'ID exacto del modelo local instalado';

  @override
  String get apiKeyLabel => 'API key de inferencia';

  @override
  String get apiKeyLabLabel => 'Clave o marcador del servidor';

  @override
  String get apiKeyLabHelper =>
      'Un marcador sintético no protege ni autentica el servidor.';

  @override
  String get rememberKey =>
      'Recordar la clave en el almacenamiento seguro del sistema';

  @override
  String queriesSentTo(String host) {
    return 'Al activar y consultar, enviás tus mensajes y el contexto necesario a $host.';
  }

  @override
  String get labQueriesNote =>
      'Las consultas se envían únicamente al endpoint indicado. Los ajustes del laboratorio se guardan separados de los del modo Arc.';

  @override
  String get initializing => 'Inicializando…';

  @override
  String get startLabButton => 'Iniciar laboratorio de texto';

  @override
  String get activateOpenHumanButton => 'Activar OpenHuman con este proveedor';

  @override
  String get stopAgentForgetKey => 'Detener agente y olvidar la clave';

  @override
  String get addArcTestnetManually => 'Agregar Arc Testnet manualmente';

  @override
  String get arcManualInfo =>
      'Nombre: Arc Testnet\nChain ID: 5042002\nMoneda nativa: USDC · 18 decimales';

  @override
  String get arcManualInstructions =>
      'Agregá la red en tu wallet, luego reconectá autorizando Arc Testnet. Agregar una red no amplía automáticamente los permisos de una sesión existente.';

  @override
  String get officialDocs => 'Documentación oficial';

  @override
  String get retrySecureStorage => 'Volver a leer el estado seguro';

  @override
  String get connectYourWallet => 'Conectá tu wallet';

  @override
  String get scanFromOtherScreen =>
      'Escaneá desde otra pantalla o abrí una wallet compatible con WalletConnect. Volvé a FluuiX después de aprobar.';

  @override
  String get walletMustHaveArc =>
      'La wallet debe tener Arc Testnet configurada. La conexión no envía fondos.';

  @override
  String get goBack => 'Volver';

  @override
  String get copyUri => 'Copiar URI';

  @override
  String get openWallet => 'Abrir wallet';

  @override
  String get uriCopied =>
      'URI copiada. Pegala en WalletConnect dentro de tu wallet.';

  @override
  String get useCopyUriOrQr =>
      'Usá Copiar URI y pegala en tu wallet, o escaneá el QR.';

  @override
  String get noWalletForLink =>
      'No se encontró una wallet para este enlace. Usá el QR o copiá la URI.';

  @override
  String get reviewTransferTitle => 'Revisá la transferencia';

  @override
  String get arcTestnetTestFunds => 'Arc Testnet · fondos de prueba';

  @override
  String get from => 'Desde';

  @override
  String get recipient => 'Destinatario';

  @override
  String maxFee(String amount) {
    return 'Comisión máxima: $amount USDC';
  }

  @override
  String maxTotal(String amount) {
    return 'Total máximo: $amount USDC';
  }

  @override
  String get reviewExpiry =>
      'La revisión vence en 2 minutos. Verificá en tu wallet que la red, el destinatario, el importe y la comisión coincidan. Tu wallet solicita la firma final.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get requestApproval => 'Solicitar aprobación';

  @override
  String get confirmWalletState => 'Confirmá el estado en tu wallet';

  @override
  String get confirmNoSendMessage =>
      'Continuá sólo si verificaste que la solicitud anterior fue rechazada o cancelada y que no existe una transferencia pendiente o enviada. Repetir un envío puede duplicar el pago.';

  @override
  String get verifiedNotSent => 'Verifiqué que no se envió';

  @override
  String get proposalValidatedCopied =>
      'Propuesta validada y copiada. Revisá destinatario, importe y comisión antes de firmar.';

  @override
  String get couldNotOpenLink => 'No se pudo abrir el enlace.';

  @override
  String get footerArcTestnet =>
      'Arc Testnet · USDC de prueba\nLa wallet externa controla tus claves y pide la firma. FluuiX no solicita frases semilla ni claves privadas.';

  @override
  String get footerLab =>
      'AW no cambia de proveedor automáticamente. Confirmá que el servidor autorizado ejecuta un modelo local; recibir texto no demuestra por sí solo su procedencia.';

  @override
  String get labBannerTitle => 'Laboratorio · sólo texto';

  @override
  String get labBannerDesc =>
      'Wallet, pagos, propuestas y consultas Arc deshabilitados. El agente no dispone de herramientas. Este modo queda fijo al compilar la app.';

  @override
  String get ordersViewTooltip => 'Vista de caja';

  @override
  String get missionViewTooltip => 'Órdenes del día';

  @override
  String get refreshArcTooltip => 'Actualizar Arc';

  @override
  String get agentStoppedStatus =>
      'Agente detenido y conversación local descartada';

  @override
  String openHumanLocalActive(String host) {
    return 'OpenHuman local activo · inferencia en $host';
  }

  @override
  String labReadyStatus(String endpoint, String model) {
    return 'Laboratorio listo · endpoint $endpoint · modelo solicitado $model';
  }

  @override
  String get turnCompletedStatus => 'Turno completado por OpenHuman';

  @override
  String get labResponseReceivedStatus =>
      'Respuesta recibida · cotejá el ID con el registro de tu servidor';

  @override
  String rustExecutedStatus(String os, String arch) {
    return 'Rust ejecutado en $os/$arch · ABI 1';
  }

  @override
  String get contextBarLayer => 'Capa';

  @override
  String get contextBarDisconnected => 'Desconectada';

  @override
  String get contextBarConnected => 'Conectada';

  @override
  String get languageSettings => 'Idioma';

  @override
  String get languageAuto => 'Automático (sistema)';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageChinese => '中文';
}
