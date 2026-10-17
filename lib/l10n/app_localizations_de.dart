// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'FluuiX';

  @override
  String get appTitleLab => 'AW · Textlabor';

  @override
  String get taglineDollarBox => 'Dollar-Kasse';

  @override
  String get testnetBadge => 'TESTNET';

  @override
  String get navCaja => 'Kasse';

  @override
  String get navAgente => 'Agent';

  @override
  String get navRed => 'Netzwerk';

  @override
  String get navAjustes => 'Einstellungen';

  @override
  String get connectionPending => 'Verbindung ausstehend';

  @override
  String get rpcVerified => 'RPC verifiziert · Arc Testnet';

  @override
  String get cajaEnDolares => 'Dollar-Kasse';

  @override
  String get balanceUsdc => 'USDC';

  @override
  String get arcTestnetSingleBalance =>
      'Arc Testnet · ein Saldo für Zahlungen und Gebühren. Lokale Schiene und Reserve nicht eingeschlossen.';

  @override
  String get arcVerified => 'Arc verifiziert';

  @override
  String get arcNotVerified => 'Arc nicht verifiziert';

  @override
  String get sessionActive => 'Sitzung aktiv';

  @override
  String get noSession => 'Keine Sitzung';

  @override
  String remainingCapLabel(String amount) {
    return 'Restlimit $amount USDC';
  }

  @override
  String sessionOnArcTestnet(String chainId) {
    return 'Sitzung auf Arc Testnet · Kette $chainId';
  }

  @override
  String get disconnect => 'Trennen';

  @override
  String get viewAccount => 'Konto anzeigen';

  @override
  String get localRail => 'Lokale Schiene';

  @override
  String get reserve => 'Reserve';

  @override
  String get noContract => 'Kein Vertrag';

  @override
  String get notAddedToBox => 'Nicht zur Kasse hinzugefügt.';

  @override
  String get pay => 'Zahlen';

  @override
  String get receive => 'Empfangen';

  @override
  String get passage => 'Brücke';

  @override
  String get cap => 'Limit';

  @override
  String get payTitle => 'Zahlen';

  @override
  String get payDescription =>
      'Der Auftrag wird in FluuiX überprüft und in Ihrer Wallet signiert. Wenn er das Limit überschreitet, wird er nicht erstellt.';

  @override
  String get recipientAddress => 'Empfängeradresse';

  @override
  String get recipientHint => '0x…';

  @override
  String get amount => 'Betrag';

  @override
  String get amountHelper => 'Bis zu 6 Dezimalstellen. Keine Rundung.';

  @override
  String get processing => 'Verarbeitung…';

  @override
  String get reviewTransfer => 'Überweisung prüfen';

  @override
  String get connectWallet => 'Wallet verbinden';

  @override
  String get requestAddArcTestnet => 'Arc Testnet hinzufügen anfordern';

  @override
  String get getTestUsdc => 'Test-USDC erhalten';

  @override
  String get receiveTitle => 'Empfangen';

  @override
  String get receiveConnectPrompt =>
      'Verbinden Sie die Wallet, um die Kassenadresse anzuzeigen. FluuiX erstellt kein eigenes Konto.';

  @override
  String get receiveDescription =>
      'Diese Adresse empfängt USDC auf Arc Testnet. Es ist kein Bankkonto.';

  @override
  String get passageTitle => 'Brücke';

  @override
  String get passageNotConnected =>
      'Die Arbitrum → Arc CCTP-Brücke ist nicht verbunden. Es gibt kein Guthaben von einer anderen Kette auf diesem Bildschirm und keine Brücke wird erstellt.';

  @override
  String get capTitle => 'Limit';

  @override
  String perPaymentCap(String amount) {
    return 'Pro Zahlung: $amount USDC';
  }

  @override
  String perDayCap(String amount) {
    return 'Pro Tag: $amount USDC';
  }

  @override
  String usedToday(String amount) {
    return 'Heute verwendet: $amount USDC';
  }

  @override
  String remainingToday(String amount) {
    return 'Heute verbleibend: $amount USDC';
  }

  @override
  String get capPolicyExplanation =>
      'Lokale Richtlinie dieser App, gezählt mit bestätigten Belegen auf diesem Telefon. Kein Circle Agent Wallet. Wenn der Betrag überschritten wird, wird der Auftrag nicht erstellt.';

  @override
  String get activity => 'Aktivität';

  @override
  String get noReceiptSaved =>
      'Noch kein Beleg auf diesem Telefon gespeichert.';

  @override
  String get hashIsReceipt =>
      'Der Hash ist der Beleg. Er ersetzt keinen Kontoauszug.';

  @override
  String get unresolvedRequest => 'Ungelöste Anfrage';

  @override
  String get checkWalletHistory =>
      'Überprüfen Sie den Verlauf und die Anfragen in Ihrer Wallet vor einem weiteren Senden. Wenn es einen Hash gibt, fügen Sie ihn zur Überprüfung ein.';

  @override
  String get transactionHashLabel => 'Transaktions-Hash 0x…';

  @override
  String get checkHash => 'Hash prüfen';

  @override
  String get requestCancelledOrRejected =>
      'Anfrage wurde abgebrochen oder abgelehnt';

  @override
  String get txSubmitted => 'Gesendet · warte auf Beleg';

  @override
  String get txConfirmed => 'Bestätigt · erfolgreiche Ausführung';

  @override
  String get txReverted =>
      'Zurückgesetzt · Operation im Netzwerk fehlgeschlagen';

  @override
  String get txPending => 'Ausstehend · noch kein Beleg';

  @override
  String get txUnknown => 'Nicht verifizierter Status · Explorer prüfen';

  @override
  String get confirmed => 'Bestätigt';

  @override
  String blockLabel(String number) {
    return 'Block $number';
  }

  @override
  String get checkReceipt => 'Beleg prüfen';

  @override
  String get openExplorer => 'Explorer öffnen';

  @override
  String get dailyOrders => 'Tagesaufträge';

  @override
  String get ordersExplanation =>
      'Jedes Element spiegelt ein bereits in dieser Sitzung beobachtetes Ereignis wider. Keine simulierte Überweisung.';

  @override
  String get orderVerifyArc => 'Arc Testnet verifizieren';

  @override
  String get orderExecuteRust => 'Rust auf dem Gerät ausführen';

  @override
  String get orderActivateOpenHuman => 'OpenHuman aktivieren';

  @override
  String get orderConnectArcAccount => 'Arc-Konto verbinden';

  @override
  String get orderConfirmTransfer => 'Echte Testnet-Überweisung bestätigen';

  @override
  String get agentBoxTitle => 'Kassenagent';

  @override
  String get agentLabTitle => 'Laborabfrage';

  @override
  String get agentVerifyStatus =>
      'Runtime überprüfen und Inferenz konfigurieren';

  @override
  String get agentDescription =>
      'Der Agent schlägt Aufträge mit arc_network_status und arc_balance vor. Ein ausgeführtes Tool zeigt die von Rust gelesenen Daten. Modelltext autorisiert oder signiert nicht.';

  @override
  String get agentLabDescription =>
      'OpenHuman koordiniert die Abfrage innerhalb von AW. Das Modell muss in Ihrem Labor laufen, über den von Ihnen konfigurierten Loopback-Endpoint. Keine Blockchain-Abfrage wird gestartet.';

  @override
  String get verifyNativeRust => 'Native Rust-Ausführung verifizieren';

  @override
  String libraryExecuted(String os, String arch) {
    return 'Bibliothek ausgeführt: $os / $arch';
  }

  @override
  String allowedTools(String tools) {
    return 'Erlaubte Tools: $tools';
  }

  @override
  String get noTools => 'keine';

  @override
  String get runtimeNotInitialized =>
      'Runtime nicht initialisiert. Tool-Richtlinie wird bei Initialisierung geprüft.';

  @override
  String nativePolicy(String mode) {
    return 'Native Richtlinie: $mode';
  }

  @override
  String get notStarted => 'nicht gestartet';

  @override
  String agentBudget(String tokens) {
    return 'Agentenbudget: $tokens Token. Zertifiziert nicht die tatsächliche Modellkapazität.';
  }

  @override
  String get localTestDisclaimer =>
      'Dieser lokale Test impliziert nicht, dass Inferenz oder eine Überweisung verifiziert wurde.';

  @override
  String get labTestDisclaimer =>
      'Das Ausführen dieser Bibliothek verifiziert noch nicht das Labormodell.';

  @override
  String get configureLabButton => 'Labor konfigurieren';

  @override
  String get configureProviderButton =>
      'Anbieter konfigurieren und Agent starten';

  @override
  String get queryLabel => 'Ihre Anfrage an den Agenten';

  @override
  String get presetArcStatus => 'Echter Arc-Status';

  @override
  String get presetMyBalance => 'Mein Guthaben prüfen';

  @override
  String get agentWorking => 'Agent arbeitet…';

  @override
  String get queryOpenHuman => 'OpenHuman abfragen';

  @override
  String get cancelTurn => 'Runde abbrechen';

  @override
  String get modelText => 'Modelltext';

  @override
  String get modelTextDisclaimer =>
      'Das ist Modelltext. Es ist keine Netzwerklesung oder Signatur.';

  @override
  String toolsExecuted(String tools) {
    return 'Ausgeführte Tools: $tools';
  }

  @override
  String liveReadTool(String tool) {
    return 'Ausgeführte Lesung · $tool';
  }

  @override
  String blockNumber(String number) {
    return 'Block: $number';
  }

  @override
  String balanceUsdcLabel(String balance) {
    return 'USDC-Guthaben: $balance';
  }

  @override
  String observationUnix(String timestamp) {
    return 'UNIX-Beobachtung: $timestamp';
  }

  @override
  String get toolResultOk => 'Ergebnis vom Rust-Tool erhalten';

  @override
  String get toolResultFailed => 'Das Tool konnte die Lesung nicht abschließen';

  @override
  String get applyProposal => 'Vorschlag ins Formular übernehmen';

  @override
  String get agentResponseDisclaimer =>
      'Eine Modellantwort ist keine Zahlungsbestätigung. Der Agent schlägt nur vor; die Signatur erfordert Ihre Überprüfung in der Wallet.';

  @override
  String get labResponseDisclaimer =>
      'Modellausgabe ist nicht vertrauenswürdiger Text. Sie wird nicht als Anweisung interpretiert und aktiviert keine Aktionen.';

  @override
  String get lastQueryLog => 'Letztes Abfrageprotokoll';

  @override
  String get logMetadataNote =>
      'Nur Client-Metadaten. Vergleichen Sie diese ID mit der tatsächlichen Verarbeitung auf Ihrem Server und mit der sichtbaren Antwort. Nachrichten und Schlüssel nicht enthalten.';

  @override
  String get copyLogWithoutKeys =>
      'Protokoll ohne Nachrichten oder Schlüssel kopieren';

  @override
  String get restartAfterInterrupted => 'Nach unterbrochener Runde neu starten';

  @override
  String get networkTitle => 'FluuiX-Netzwerk';

  @override
  String get networkDescription =>
      'Jedes Modul hat keinen Vertrag, bis der Betreiber Endpoint, Authentifizierung und Katalog bereitstellt. Es gibt keine Salden, Kurse oder Darlehen.';

  @override
  String get zonaBankTitle => 'ZonaBank';

  @override
  String get zonaBankDesc =>
      'Konten, Kontakte, Intents und Abrechnungsschienen. ZonaBank speichert keine Schlüssel und ist keine lizenzierte Bank.';

  @override
  String get lendingTitle => 'Lending';

  @override
  String get lendingDesc =>
      'Die öffentliche Karte erwähnt Finanzierung gegen tokenisierte Sicherheiten. Es gibt keinen Katalog, keinen Kurs und kein Darlehen in dieser App.';

  @override
  String get zonaFrancaTitle => 'ZonaFranca';

  @override
  String get zonaFrancaDesc =>
      'Registrierung und Rückverfolgbarkeit von Waren und Logistik. Nur Lesen, wenn Katalog verfügbar.';

  @override
  String get ttnTitle => 'TTN';

  @override
  String get ttnDesc =>
      'Bereits von TokenizaTuNegocio ausgegebene Instrumente. Ein Token auszugeben ist kein Telefonauftrag.';

  @override
  String get capitalSection => 'Kapital';

  @override
  String get fideicomisosTitle => 'Treuhandfonds';

  @override
  String get fideicomisosDesc =>
      'Kapitalvehikel des gleichen Motors. Keine Position anzuzeigen.';

  @override
  String get fondosTitle => 'Fonds';

  @override
  String get fondosDesc =>
      'Kapitalvehikel des gleichen Motors. Keine Position anzuzeigen.';

  @override
  String get crowdTitle => 'Crowd';

  @override
  String get crowdDesc => 'Community-Finanzierung. Keine Kampagne geladen.';

  @override
  String get licitacionesTitle => 'Ausschreibungen';

  @override
  String get licitacionesDesc =>
      'Käufe mit überprüfbarem Beleg. Kein Prozess geladen.';

  @override
  String get donacionesTitle => 'Spenden';

  @override
  String get donacionesDesc =>
      'Spende mit Rückverfolgbarkeit. Keine Kampagne geladen.';

  @override
  String get academiaTitle => 'Akademie';

  @override
  String get academiaDesc => 'TokenizaTuNegocio-Schulung. Bewegt keine Gelder.';

  @override
  String get whatProductPublishes => 'Was das Produkt veröffentlicht';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsLabTitle => 'Laborkonfiguration';

  @override
  String get walletConnectTitle => 'WalletConnect / Reown';

  @override
  String get walletConnectDescription =>
      'Geben Sie die Project ID Ihres Projekts ein. Kann ohne Neukompilierung geändert werden. Die Wallet-Sitzung bleibt nur im Speicher; beim Neustart der App wird neu verbunden. FluuiX fragt nicht nach Seed-Phrase oder privatem Schlüssel.';

  @override
  String get projectIdLabel => 'Project ID';

  @override
  String get projectIdHint => '32 hexadezimale Zeichen';

  @override
  String get connecting => 'Verbinden…';

  @override
  String get saveAndConnectReown => 'Speichern und Reown verbinden';

  @override
  String get reownClientInitialized => 'Reown-Client initialisiert';

  @override
  String get inferenceTitle => 'Inferenz für OpenHuman';

  @override
  String get inferenceLabTitle => 'Lokaler Textserver';

  @override
  String get inferenceDescription =>
      'Wählen Sie einen OpenAI-kompatiblen Endpoint und das von Ihrem Anbieter aktivierte Modell. Das Modell nutzt das Internet; die Rust-Runtime läuft auf dem Telefon.';

  @override
  String get inferenceLabDescription =>
      'Geben Sie die wörtliche Loopback-IP und den /v1-Pfad des Transports ein, den Sie zu Ihrem autorisierten Server eingerichtet haben. Wählen Sie ein dort bereits installiertes Modell. Kein Standard-Endpoint oder -Modell.';

  @override
  String get endpointLabel => 'HTTPS-Endpoint';

  @override
  String get endpointLabLabel => 'Loopback-Endpoint /v1';

  @override
  String get endpointHint => 'https://anbieter.beispiel/v1';

  @override
  String get endpointLabHint =>
      'Vervollständigen Sie Ihren autorisierten Endpoint';

  @override
  String get modelLabel => 'Modell-ID';

  @override
  String get modelHint => 'Von Ihrem Anbieter aktiviertes Modell';

  @override
  String get modelLabHint => 'Exakte ID des lokal installierten Modells';

  @override
  String get apiKeyLabel => 'Inferenz-API-Schlüssel';

  @override
  String get apiKeyLabLabel => 'Serverschlüssel oder Marker';

  @override
  String get apiKeyLabHelper =>
      'Ein synthetischer Marker schützt oder authentifiziert den Server nicht.';

  @override
  String get rememberKey => 'Schlüssel im sicheren Systemspeicher merken';

  @override
  String queriesSentTo(String host) {
    return 'Beim Aktivieren und Abfragen senden Sie Ihre Nachrichten und den erforderlichen Kontext an $host.';
  }

  @override
  String get labQueriesNote =>
      'Abfragen werden nur an den angegebenen Endpoint gesendet. Laboreinstellungen werden getrennt vom Arc-Modus gespeichert.';

  @override
  String get initializing => 'Initialisierung…';

  @override
  String get startLabButton => 'Textlabor starten';

  @override
  String get activateOpenHumanButton =>
      'OpenHuman mit diesem Anbieter aktivieren';

  @override
  String get stopAgentForgetKey => 'Agent stoppen und Schlüssel vergessen';

  @override
  String get addArcTestnetManually => 'Arc Testnet manuell hinzufügen';

  @override
  String get arcManualInfo =>
      'Name: Arc Testnet\nChain ID: 5042002\nNative Währung: USDC · 18 Dezimalstellen';

  @override
  String get arcManualInstructions =>
      'Fügen Sie das Netzwerk in Ihrer Wallet hinzu, dann verbinden Sie sich erneut und autorisieren Sie Arc Testnet. Das Hinzufügen eines Netzwerks erweitert nicht automatisch die Berechtigungen einer bestehenden Sitzung.';

  @override
  String get officialDocs => 'Offizielle Dokumentation';

  @override
  String get retrySecureStorage => 'Sicheren Zustand erneut lesen';

  @override
  String get connectYourWallet => 'Verbinden Sie Ihre Wallet';

  @override
  String get scanFromOtherScreen =>
      'Scannen Sie von einem anderen Bildschirm oder öffnen Sie eine WalletConnect-kompatible Wallet. Kehren Sie nach der Genehmigung zu FluuiX zurück.';

  @override
  String get walletMustHaveArc =>
      'Die Wallet muss Arc Testnet konfiguriert haben. Die Verbindung sendet keine Gelder.';

  @override
  String get goBack => 'Zurück';

  @override
  String get copyUri => 'URI kopieren';

  @override
  String get openWallet => 'Wallet öffnen';

  @override
  String get uriCopied =>
      'URI kopiert. Fügen Sie sie in WalletConnect in Ihrer Wallet ein.';

  @override
  String get useCopyUriOrQr =>
      'Verwenden Sie URI kopieren und fügen Sie sie in Ihrer Wallet ein, oder scannen Sie den QR.';

  @override
  String get noWalletForLink =>
      'Keine Wallet für diesen Link gefunden. Verwenden Sie den QR oder kopieren Sie die URI.';

  @override
  String get reviewTransferTitle => 'Überweisung prüfen';

  @override
  String get arcTestnetTestFunds => 'Arc Testnet · Testgelder';

  @override
  String get from => 'Von';

  @override
  String get recipient => 'Empfänger';

  @override
  String maxFee(String amount) {
    return 'Maximale Gebühr: $amount USDC';
  }

  @override
  String maxTotal(String amount) {
    return 'Maximale Summe: $amount USDC';
  }

  @override
  String get reviewExpiry =>
      'Die Überprüfung läuft in 2 Minuten ab. Überprüfen Sie in Ihrer Wallet, dass Netzwerk, Empfänger, Betrag und Gebühr übereinstimmen. Ihre Wallet fordert die endgültige Signatur an.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get requestApproval => 'Genehmigung anfordern';

  @override
  String get confirmWalletState => 'Bestätigen Sie den Status in Ihrer Wallet';

  @override
  String get confirmNoSendMessage =>
      'Fahren Sie nur fort, wenn Sie überprüft haben, dass die vorherige Anfrage abgelehnt oder abgebrochen wurde und keine ausstehende oder gesendete Überweisung existiert. Ein erneutes Senden kann die Zahlung verdoppeln.';

  @override
  String get verifiedNotSent => 'Verifiziert, dass nicht gesendet wurde';

  @override
  String get proposalValidatedCopied =>
      'Vorschlag validiert und kopiert. Überprüfen Sie Empfänger, Betrag und Gebühr vor dem Signieren.';

  @override
  String get couldNotOpenLink => 'Link konnte nicht geöffnet werden.';

  @override
  String get footerArcTestnet =>
      'Arc Testnet · Test-USDC\nDie externe Wallet kontrolliert Ihre Schlüssel und fordert die Signatur an. FluuiX fragt nicht nach Seed-Phrasen oder privaten Schlüsseln.';

  @override
  String get footerLab =>
      'AW wechselt nicht automatisch den Anbieter. Bestätigen Sie, dass der autorisierte Server ein lokales Modell ausführt; Text zu empfangen beweist allein nicht dessen Herkunft.';

  @override
  String get labBannerTitle => 'Labor · nur Text';

  @override
  String get labBannerDesc =>
      'Wallet, Zahlungen, Vorschläge und Arc-Abfragen deaktiviert. Der Agent hat keine Tools. Dieser Modus ist beim Kompilieren festgelegt.';

  @override
  String get ordersViewTooltip => 'Kassenansicht';

  @override
  String get missionViewTooltip => 'Tagesaufträge';

  @override
  String get refreshArcTooltip => 'Arc aktualisieren';

  @override
  String get agentStoppedStatus =>
      'Agent gestoppt und lokale Konversation verworfen';

  @override
  String openHumanLocalActive(String host) {
    return 'OpenHuman lokal aktiv · Inferenz auf $host';
  }

  @override
  String labReadyStatus(String endpoint, String model) {
    return 'Labor bereit · Endpoint $endpoint · angefordertes Modell $model';
  }

  @override
  String get turnCompletedStatus => 'Runde von OpenHuman abgeschlossen';

  @override
  String get labResponseReceivedStatus =>
      'Antwort erhalten · vergleichen Sie die ID mit Ihrem Serverprotokoll';

  @override
  String rustExecutedStatus(String os, String arch) {
    return 'Rust ausgeführt auf $os/$arch · ABI 1';
  }

  @override
  String get contextBarLayer => 'Schicht';

  @override
  String get contextBarDisconnected => 'Getrennt';

  @override
  String get contextBarConnected => 'Verbunden';

  @override
  String get languageSettings => 'Sprache';

  @override
  String get languageAuto => 'Automatisch (System)';

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

  @override
  String get navInicio => 'Start';

  @override
  String get navRieles => 'Schienen';

  @override
  String get navMas => 'Mehr';

  @override
  String get homeWelcome => 'Willkommen bei FluuiX';

  @override
  String get homeConnectedStatus => 'Wallet verbunden';

  @override
  String get homeDisconnectedStatus => 'Wallet getrennt';

  @override
  String get homeLayers => 'Ebenen';

  @override
  String get homeLayerAgentes => 'Agenten';

  @override
  String get homeLayerAgentesDesc => 'KI, die Operationen vorschlägt';

  @override
  String get homeLayerRieles => 'Schienen';

  @override
  String get homeLayerRielesDesc => 'Lokale Instrumente';

  @override
  String get homeLayerContratos => 'Verträge';

  @override
  String get homeLayerContratosDesc => 'Smart Contracts';

  @override
  String get homeLayerWallets => 'Wallets';

  @override
  String get homeLayerWalletsDesc => 'Wallet-Verwaltung';

  @override
  String get homeLayerSettlement => 'Abwicklung';

  @override
  String get homeLayerSettlementDesc => 'Endabwicklung';

  @override
  String get homeLayerMultichain => 'Multichain';

  @override
  String get homeLayerMultichainDesc => 'Cross-Chain-Brücken';

  @override
  String get layerStateActive => 'Aktiv';

  @override
  String get layerStatePartial => 'Teilweise';

  @override
  String get homeQuickActions => 'Schnellaktionen';

  @override
  String get homeAskAgent => 'Fragen';

  @override
  String get homeSystemStatus => 'Systemstatus';

  @override
  String get passageComingSoon => 'Demnächst';

  @override
  String get passageDescription =>
      'Die CCTP-Brücke ermöglicht native USDC-Bewegung zwischen Chains. Wenn aktiv, können Sie Gelder von Arbitrum oder anderen Netzwerken übertragen.';

  @override
  String get capPolicyTitle => 'Limitrichtlinie';

  @override
  String get rielesTitle => 'Schienen';

  @override
  String get rielesDescription =>
      'Schienen verbinden verschiedene Instrumente mit der Kasse. Jede Schiene hat ihr eigenes Guthaben und Bedingungen.';

  @override
  String get rielUsdcNative => 'Natives USDC';

  @override
  String get rielActive => 'Aktiv';

  @override
  String get rielesHowItWorks => 'Wie Schienen funktionieren';

  @override
  String get rielesExplanation =>
      'Eine Schiene ist ein Abwicklungskanal zwischen der Kasse und einem Instrument. Die lokale Schiene (Twin) ermöglicht Operationen mit tokenisierten Pesos. Die Reserve (cirBTC) ist ein Sparinstrument. USDC ist das native Guthaben von Arc.';

  @override
  String get paymentChecklist => 'Checkliste';

  @override
  String get checkRpcConnected => 'RPC verbunden';

  @override
  String get checkWalletConnected => 'Wallet verbunden';

  @override
  String get checkArcSupported => 'Arc autorisiert';

  @override
  String get checkWithinLimit => 'Innerhalb des Tageslimits';

  @override
  String get paymentSheetDisclaimer =>
      'FluuiX bereitet die Bestellung vor und zeigt sie zur Überprüfung an. Ihre externe Wallet fordert die Unterschrift an. Modelltext autorisiert oder signiert keine Zahlungen.';

  @override
  String get sheetChainRail => 'Chain und Schiene';

  @override
  String get sheetNoAuthNoSign => 'Autorisiert oder signiert nicht';

  @override
  String get proposalSheetTitle => 'Agentenvorschlag';

  @override
  String get proposalFromAgent => 'OpenHuman schlägt diese Überweisung vor';

  @override
  String get proposalNotFound => 'Vorschlag nicht gefunden';

  @override
  String get proposalDisclaimer =>
      'Der Agent schlägt nur vor. Die Unterschrift erfordert Ihre Überprüfung in der Wallet. Überprüfen Sie Empfänger, Betrag und Gebühr vor der Genehmigung.';

  @override
  String get proposalCopyToForm => 'Zum Formular kopieren';
}
