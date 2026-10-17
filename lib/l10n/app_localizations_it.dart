// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'FluuiX';

  @override
  String get appTitleLab => 'AW · Laboratorio di testo';

  @override
  String get taglineDollarBox => 'Cassa in dollari';

  @override
  String get testnetBadge => 'TESTNET';

  @override
  String get navCaja => 'Cassa';

  @override
  String get navAgente => 'Agente';

  @override
  String get navRed => 'Rete';

  @override
  String get navAjustes => 'Impostazioni';

  @override
  String get connectionPending => 'Connessione in attesa';

  @override
  String get rpcVerified => 'RPC verificato · Arc Testnet';

  @override
  String get cajaEnDolares => 'Cassa in dollari';

  @override
  String get balanceUsdc => 'USDC';

  @override
  String get arcTestnetSingleBalance =>
      'Arc Testnet · saldo unico per pagamenti e commissioni. Non include il binario locale né la riserva.';

  @override
  String get arcVerified => 'Arc verificato';

  @override
  String get arcNotVerified => 'Arc non verificato';

  @override
  String get sessionActive => 'Sessione attiva';

  @override
  String get noSession => 'Nessuna sessione';

  @override
  String remainingCapLabel(String amount) {
    return 'Limite residuo $amount USDC';
  }

  @override
  String sessionOnArcTestnet(String chainId) {
    return 'Sessione su Arc Testnet · catena $chainId';
  }

  @override
  String get disconnect => 'Disconnetti';

  @override
  String get viewAccount => 'Visualizza account';

  @override
  String get localRail => 'Binario locale';

  @override
  String get reserve => 'Riserva';

  @override
  String get noContract => 'Nessun contratto';

  @override
  String get notAddedToBox => 'Non aggiunto alla cassa.';

  @override
  String get pay => 'Paga';

  @override
  String get receive => 'Ricevi';

  @override
  String get passage => 'Ponte';

  @override
  String get cap => 'Limite';

  @override
  String get payTitle => 'Paga';

  @override
  String get payDescription =>
      'L\'ordine viene rivisto in FluuiX e firmato nel tuo portafoglio. Se supera il limite, non verrà assemblato.';

  @override
  String get recipientAddress => 'Indirizzo del destinatario';

  @override
  String get recipientHint => '0x…';

  @override
  String get amount => 'Importo';

  @override
  String get amountHelper => 'Fino a 6 decimali. Nessun arrotondamento.';

  @override
  String get processing => 'Elaborazione…';

  @override
  String get reviewTransfer => 'Rivedi trasferimento';

  @override
  String get connectWallet => 'Connetti portafoglio';

  @override
  String get requestAddArcTestnet => 'Richiedi aggiunta Arc Testnet';

  @override
  String get getTestUsdc => 'Ottieni USDC di test';

  @override
  String get receiveTitle => 'Ricevi';

  @override
  String get receiveConnectPrompt =>
      'Connetti il portafoglio per mostrare l\'indirizzo della cassa. FluuiX non genera un proprio account.';

  @override
  String get receiveDescription =>
      'Questo indirizzo riceve USDC su Arc Testnet. Non è un conto bancario.';

  @override
  String get passageTitle => 'Ponte';

  @override
  String get passageNotConnected =>
      'Il ponte Arbitrum → Arc via CCTP non è connesso. Non c\'è saldo da un\'altra catena su questa schermata e nessun ponte viene assemblato.';

  @override
  String get capTitle => 'Limite';

  @override
  String perPaymentCap(String amount) {
    return 'Per pagamento: $amount USDC';
  }

  @override
  String perDayCap(String amount) {
    return 'Per giorno: $amount USDC';
  }

  @override
  String usedToday(String amount) {
    return 'Usato oggi: $amount USDC';
  }

  @override
  String remainingToday(String amount) {
    return 'Residuo oggi: $amount USDC';
  }

  @override
  String get capPolicyExplanation =>
      'Politica locale di questa app, contata con ricevute confermate su questo telefono. Non è un Agent Wallet di Circle. Se l\'importo lo supera, l\'ordine non verrà assemblato.';

  @override
  String get activity => 'Attività';

  @override
  String get noReceiptSaved => 'Nessuna ricevuta salvata su questo telefono.';

  @override
  String get hashIsReceipt =>
      'L\'hash è la ricevuta. Non sostituisce un estratto conto bancario.';

  @override
  String get unresolvedRequest => 'Richiesta non risolta';

  @override
  String get checkWalletHistory =>
      'Controlla la cronologia e le richieste nel tuo portafoglio prima di un altro invio. Se c\'è un hash, incollalo per verificare.';

  @override
  String get transactionHashLabel => 'Hash transazione 0x…';

  @override
  String get checkHash => 'Verifica hash';

  @override
  String get requestCancelledOrRejected =>
      'La richiesta è stata annullata o rifiutata';

  @override
  String get txSubmitted => 'Inviata · in attesa di ricevuta';

  @override
  String get txConfirmed => 'Confermata · esecuzione riuscita';

  @override
  String get txReverted => 'Annullata · operazione fallita sulla rete';

  @override
  String get txPending => 'In attesa · ancora senza ricevuta';

  @override
  String get txUnknown => 'Stato non verificato · consulta l\'explorer';

  @override
  String get confirmed => 'Confermata';

  @override
  String blockLabel(String number) {
    return 'Blocco $number';
  }

  @override
  String get checkReceipt => 'Verifica ricevuta';

  @override
  String get openExplorer => 'Apri explorer';

  @override
  String get dailyOrders => 'Ordini del giorno';

  @override
  String get ordersExplanation =>
      'Ogni elemento riflette un evento già osservato in questa sessione. Non è un trasferimento simulato.';

  @override
  String get orderVerifyArc => 'Verifica Arc Testnet';

  @override
  String get orderExecuteRust => 'Esegui Rust sul dispositivo';

  @override
  String get orderActivateOpenHuman => 'Attiva OpenHuman';

  @override
  String get orderConnectArcAccount => 'Connetti un account Arc';

  @override
  String get orderConfirmTransfer => 'Conferma un vero trasferimento testnet';

  @override
  String get agentBoxTitle => 'Agente della cassa';

  @override
  String get agentLabTitle => 'Query al laboratorio';

  @override
  String get agentVerifyStatus =>
      'Verifica il runtime e configura l\'inferenza';

  @override
  String get agentDescription =>
      'L\'agente propone ordini con arc_network_status e arc_balance. Uno strumento eseguito mostra i dati letti da Rust. Il testo del modello non autorizza né firma.';

  @override
  String get agentLabDescription =>
      'OpenHuman coordina la query all\'interno di AW. Il modello deve essere eseguito nel tuo laboratorio, tramite l\'endpoint loopback che configuri. Nessuna query blockchain viene avviata.';

  @override
  String get verifyNativeRust => 'Verifica esecuzione nativa di Rust';

  @override
  String libraryExecuted(String os, String arch) {
    return 'Libreria eseguita: $os / $arch';
  }

  @override
  String allowedTools(String tools) {
    return 'Strumenti consentiti: $tools';
  }

  @override
  String get noTools => 'nessuno';

  @override
  String get runtimeNotInitialized =>
      'Runtime non inizializzato. La politica degli strumenti viene verificata all\'inizializzazione.';

  @override
  String nativePolicy(String mode) {
    return 'Politica nativa: $mode';
  }

  @override
  String get notStarted => 'non avviato';

  @override
  String agentBudget(String tokens) {
    return 'Budget dell\'agente: $tokens token. Non certifica la capacità effettiva del modello.';
  }

  @override
  String get localTestDisclaimer =>
      'Questo test locale non implica che l\'inferenza o un trasferimento sia stato verificato.';

  @override
  String get labTestDisclaimer =>
      'L\'esecuzione di questa libreria non verifica ancora il modello del laboratorio.';

  @override
  String get configureLabButton => 'Configura laboratorio';

  @override
  String get configureProviderButton => 'Configura fornitore e avvia agente';

  @override
  String get queryLabel => 'La tua query all\'agente';

  @override
  String get presetArcStatus => 'Stato reale di Arc';

  @override
  String get presetMyBalance => 'Consulta il mio saldo';

  @override
  String get agentWorking => 'Agente in lavoro…';

  @override
  String get queryOpenHuman => 'Interroga OpenHuman';

  @override
  String get cancelTurn => 'Annulla turno';

  @override
  String get modelText => 'Testo del modello';

  @override
  String get modelTextDisclaimer =>
      'Quello è testo del modello. Non è una lettura di rete né una firma.';

  @override
  String toolsExecuted(String tools) {
    return 'Strumenti eseguiti: $tools';
  }

  @override
  String liveReadTool(String tool) {
    return 'Lettura eseguita · $tool';
  }

  @override
  String blockNumber(String number) {
    return 'Blocco: $number';
  }

  @override
  String balanceUsdcLabel(String balance) {
    return 'Saldo USDC: $balance';
  }

  @override
  String observationUnix(String timestamp) {
    return 'Osservazione UNIX: $timestamp';
  }

  @override
  String get toolResultOk => 'Risultato ottenuto dallo strumento Rust';

  @override
  String get toolResultFailed =>
      'Lo strumento non è riuscito a completare la lettura';

  @override
  String get applyProposal => 'Applica proposta al modulo';

  @override
  String get agentResponseDisclaimer =>
      'Una risposta del modello non è una conferma di pagamento. L\'agente propone solo; la firma richiede la tua revisione nel portafoglio.';

  @override
  String get labResponseDisclaimer =>
      'L\'output del modello è testo non affidabile. Non viene interpretato come istruzione né abilita azioni.';

  @override
  String get lastQueryLog => 'Log dell\'ultima query';

  @override
  String get logMetadataNote =>
      'Solo metadati del client. Confronta questo ID con l\'elaborazione effettiva sul tuo server e con la risposta visibile. Messaggi e chiavi non inclusi.';

  @override
  String get copyLogWithoutKeys => 'Copia log senza messaggi o chiavi';

  @override
  String get restartAfterInterrupted => 'Riavvia dopo turno interrotto';

  @override
  String get networkTitle => 'Rete FluuiX';

  @override
  String get networkDescription =>
      'Ogni modulo è senza contratto finché l\'operatore non fornisce endpoint, autenticazione e catalogo. Non ci sono saldi, tassi o prestiti.';

  @override
  String get zonaBankTitle => 'ZonaBank';

  @override
  String get zonaBankDesc =>
      'Conti, contatti, intent e binari di regolamento. ZonaBank non memorizza chiavi e non è una banca autorizzata.';

  @override
  String get lendingTitle => 'Lending';

  @override
  String get lendingDesc =>
      'La mappa pubblica menziona finanziamento contro collaterale tokenizzato. Non c\'è catalogo, tasso o prestito in questa app.';

  @override
  String get zonaFrancaTitle => 'ZonaFranca';

  @override
  String get zonaFrancaDesc =>
      'Registrazione e tracciabilità di merci e logistica. Solo lettura quando il catalogo è disponibile.';

  @override
  String get ttnTitle => 'TTN';

  @override
  String get ttnDesc =>
      'Strumenti già emessi da TokenizaTuNegocio. Emettere un token non è un ordine del telefono.';

  @override
  String get capitalSection => 'Capitale';

  @override
  String get fideicomisosTitle => 'Trust';

  @override
  String get fideicomisosDesc =>
      'Veicolo di capitale dello stesso motore. Nessuna posizione da mostrare.';

  @override
  String get fondosTitle => 'Fondi';

  @override
  String get fondosDesc =>
      'Veicolo di capitale dello stesso motore. Nessuna posizione da mostrare.';

  @override
  String get crowdTitle => 'Crowd';

  @override
  String get crowdDesc =>
      'Finanziamento comunitario. Nessuna campagna caricata.';

  @override
  String get licitacionesTitle => 'Gare d\'appalto';

  @override
  String get licitacionesDesc =>
      'Acquisti con ricevuta verificabile. Nessun processo caricato.';

  @override
  String get donacionesTitle => 'Donazioni';

  @override
  String get donacionesDesc =>
      'Donazione con tracciabilità. Nessuna campagna caricata.';

  @override
  String get academiaTitle => 'Accademia';

  @override
  String get academiaDesc => 'Formazione TokenizaTuNegocio. Non muove fondi.';

  @override
  String get whatProductPublishes => 'Cosa pubblica il prodotto';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsLabTitle => 'Configurazione del laboratorio';

  @override
  String get walletConnectTitle => 'WalletConnect / Reown';

  @override
  String get walletConnectDescription =>
      'Inserisci il Project ID del tuo progetto. Può essere modificato senza ricompilare. La sessione del portafoglio rimane solo in memoria; al riavvio dell\'app si riconnette. FluuiX non chiede frase seed o chiave privata.';

  @override
  String get projectIdLabel => 'Project ID';

  @override
  String get projectIdHint => '32 caratteri esadecimali';

  @override
  String get connecting => 'Connessione…';

  @override
  String get saveAndConnectReown => 'Salva e connetti Reown';

  @override
  String get reownClientInitialized => 'Client Reown inizializzato';

  @override
  String get inferenceTitle => 'Inferenza per OpenHuman';

  @override
  String get inferenceLabTitle => 'Server di testo locale';

  @override
  String get inferenceDescription =>
      'Scegli un endpoint compatibile con OpenAI e il modello abilitato dal tuo fornitore. Il modello usa Internet; il runtime Rust viene eseguito sul telefono.';

  @override
  String get inferenceLabDescription =>
      'Inserisci l\'IP loopback letterale e il percorso /v1 del trasporto che hai stabilito verso il tuo server autorizzato. Scegli un modello già installato lì. Nessun endpoint o modello predefinito.';

  @override
  String get endpointLabel => 'Endpoint HTTPS';

  @override
  String get endpointLabLabel => 'Endpoint loopback /v1';

  @override
  String get endpointHint => 'https://fornitore.esempio/v1';

  @override
  String get endpointLabHint => 'Completa il tuo endpoint autorizzato';

  @override
  String get modelLabel => 'ID del modello';

  @override
  String get modelHint => 'Modello abilitato dal tuo fornitore';

  @override
  String get modelLabHint => 'ID esatto del modello locale installato';

  @override
  String get apiKeyLabel => 'Chiave API di inferenza';

  @override
  String get apiKeyLabLabel => 'Chiave o marker del server';

  @override
  String get apiKeyLabHelper =>
      'Un marker sintetico non protegge né autentica il server.';

  @override
  String get rememberKey =>
      'Ricorda la chiave nell\'archivio sicuro del sistema';

  @override
  String queriesSentTo(String host) {
    return 'Attivando e interrogando, invii i tuoi messaggi e il contesto necessario a $host.';
  }

  @override
  String get labQueriesNote =>
      'Le query vengono inviate solo all\'endpoint indicato. Le impostazioni del laboratorio vengono salvate separatamente dalla modalità Arc.';

  @override
  String get initializing => 'Inizializzazione…';

  @override
  String get startLabButton => 'Avvia laboratorio di testo';

  @override
  String get activateOpenHumanButton => 'Attiva OpenHuman con questo fornitore';

  @override
  String get stopAgentForgetKey => 'Ferma agente e dimentica la chiave';

  @override
  String get addArcTestnetManually => 'Aggiungi Arc Testnet manualmente';

  @override
  String get arcManualInfo =>
      'Nome: Arc Testnet\nChain ID: 5042002\nValuta nativa: USDC · 18 decimali';

  @override
  String get arcManualInstructions =>
      'Aggiungi la rete nel tuo portafoglio, poi riconnettiti autorizzando Arc Testnet. Aggiungere una rete non estende automaticamente i permessi di una sessione esistente.';

  @override
  String get officialDocs => 'Documentazione ufficiale';

  @override
  String get retrySecureStorage => 'Riprova a leggere lo stato sicuro';

  @override
  String get connectYourWallet => 'Connetti il tuo portafoglio';

  @override
  String get scanFromOtherScreen =>
      'Scansiona da un altro schermo o apri un portafoglio compatibile con WalletConnect. Torna a FluuiX dopo l\'approvazione.';

  @override
  String get walletMustHaveArc =>
      'Il portafoglio deve avere Arc Testnet configurato. La connessione non invia fondi.';

  @override
  String get goBack => 'Indietro';

  @override
  String get copyUri => 'Copia URI';

  @override
  String get openWallet => 'Apri portafoglio';

  @override
  String get uriCopied =>
      'URI copiata. Incollala in WalletConnect nel tuo portafoglio.';

  @override
  String get useCopyUriOrQr =>
      'Usa Copia URI e incollala nel tuo portafoglio, o scansiona il QR.';

  @override
  String get noWalletForLink =>
      'Nessun portafoglio trovato per questo link. Usa il QR o copia l\'URI.';

  @override
  String get reviewTransferTitle => 'Rivedi il trasferimento';

  @override
  String get arcTestnetTestFunds => 'Arc Testnet · fondi di test';

  @override
  String get from => 'Da';

  @override
  String get recipient => 'Destinatario';

  @override
  String maxFee(String amount) {
    return 'Commissione massima: $amount USDC';
  }

  @override
  String maxTotal(String amount) {
    return 'Totale massimo: $amount USDC';
  }

  @override
  String get reviewExpiry =>
      'La revisione scade in 2 minuti. Verifica nel tuo portafoglio che rete, destinatario, importo e commissione corrispondano. Il tuo portafoglio richiede la firma finale.';

  @override
  String get cancel => 'Annulla';

  @override
  String get requestApproval => 'Richiedi approvazione';

  @override
  String get confirmWalletState => 'Conferma lo stato nel tuo portafoglio';

  @override
  String get confirmNoSendMessage =>
      'Continua solo se hai verificato che la richiesta precedente è stata rifiutata o annullata e che non esiste un trasferimento in sospeso o inviato. Ripetere un invio può duplicare il pagamento.';

  @override
  String get verifiedNotSent => 'Verificato che non è stato inviato';

  @override
  String get proposalValidatedCopied =>
      'Proposta validata e copiata. Rivedi destinatario, importo e commissione prima di firmare.';

  @override
  String get couldNotOpenLink => 'Impossibile aprire il link.';

  @override
  String get footerArcTestnet =>
      'Arc Testnet · USDC di test\nIl portafoglio esterno controlla le tue chiavi e richiede la firma. FluuiX non richiede frasi seed o chiavi private.';

  @override
  String get footerLab =>
      'AW non cambia fornitore automaticamente. Conferma che il server autorizzato esegue un modello locale; ricevere testo non prova da solo la sua origine.';

  @override
  String get labBannerTitle => 'Laboratorio · solo testo';

  @override
  String get labBannerDesc =>
      'Portafoglio, pagamenti, proposte e query Arc disabilitati. L\'agente non ha strumenti. Questa modalità è fissata alla compilazione.';

  @override
  String get ordersViewTooltip => 'Vista cassa';

  @override
  String get missionViewTooltip => 'Ordini del giorno';

  @override
  String get refreshArcTooltip => 'Aggiorna Arc';

  @override
  String get agentStoppedStatus =>
      'Agente fermato e conversazione locale scartata';

  @override
  String openHumanLocalActive(String host) {
    return 'OpenHuman locale attivo · inferenza su $host';
  }

  @override
  String labReadyStatus(String endpoint, String model) {
    return 'Laboratorio pronto · endpoint $endpoint · modello richiesto $model';
  }

  @override
  String get turnCompletedStatus => 'Turno completato da OpenHuman';

  @override
  String get labResponseReceivedStatus =>
      'Risposta ricevuta · confronta l\'ID con il log del tuo server';

  @override
  String rustExecutedStatus(String os, String arch) {
    return 'Rust eseguito su $os/$arch · ABI 1';
  }

  @override
  String get contextBarLayer => 'Livello';

  @override
  String get contextBarDisconnected => 'Disconnesso';

  @override
  String get contextBarConnected => 'Connesso';

  @override
  String get languageSettings => 'Lingua';

  @override
  String get languageAuto => 'Automatico (sistema)';

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
