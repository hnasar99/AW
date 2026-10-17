// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FluuiX';

  @override
  String get appTitleLab => 'AW · Text Laboratory';

  @override
  String get taglineDollarBox => 'Dollar box';

  @override
  String get testnetBadge => 'TESTNET';

  @override
  String get navCaja => 'Box';

  @override
  String get navAgente => 'Agent';

  @override
  String get navRed => 'Network';

  @override
  String get navAjustes => 'Settings';

  @override
  String get connectionPending => 'Connection pending';

  @override
  String get rpcVerified => 'RPC verified · Arc Testnet';

  @override
  String get cajaEnDolares => 'Dollar box';

  @override
  String get balanceUsdc => 'USDC';

  @override
  String get arcTestnetSingleBalance =>
      'Arc Testnet · single balance for payments and fees. Does not include local rail or reserve.';

  @override
  String get arcVerified => 'Arc verified';

  @override
  String get arcNotVerified => 'Arc not verified';

  @override
  String get sessionActive => 'Session active';

  @override
  String get noSession => 'No session';

  @override
  String remainingCapLabel(String amount) {
    return 'Remaining cap $amount USDC';
  }

  @override
  String sessionOnArcTestnet(String chainId) {
    return 'Session on Arc Testnet · chain $chainId';
  }

  @override
  String get disconnect => 'Disconnect';

  @override
  String get viewAccount => 'View account';

  @override
  String get localRail => 'Local rail';

  @override
  String get reserve => 'Reserve';

  @override
  String get noContract => 'No contract';

  @override
  String get notAddedToBox => 'Not added to box.';

  @override
  String get pay => 'Pay';

  @override
  String get receive => 'Receive';

  @override
  String get passage => 'Bridge';

  @override
  String get cap => 'Cap';

  @override
  String get payTitle => 'Pay';

  @override
  String get payDescription =>
      'The order is reviewed in FluuiX and signed in your wallet. If it exceeds the cap, it won\'t be assembled.';

  @override
  String get recipientAddress => 'Recipient address';

  @override
  String get recipientHint => '0x…';

  @override
  String get amount => 'Amount';

  @override
  String get amountHelper => 'Up to 6 decimals. No rounding.';

  @override
  String get processing => 'Processing…';

  @override
  String get reviewTransfer => 'Review transfer';

  @override
  String get connectWallet => 'Connect wallet';

  @override
  String get requestAddArcTestnet => 'Request to add Arc Testnet';

  @override
  String get getTestUsdc => 'Get test USDC';

  @override
  String get receiveTitle => 'Receive';

  @override
  String get receiveConnectPrompt =>
      'Connect the wallet to display the box address. FluuiX does not generate its own account.';

  @override
  String get receiveDescription =>
      'This address receives USDC on Arc Testnet. It is not a bank account.';

  @override
  String get passageTitle => 'Bridge';

  @override
  String get passageNotConnected =>
      'The Arbitrum → Arc CCTP bridge is not connected. There is no balance from another chain on this screen and no bridge is assembled.';

  @override
  String get capTitle => 'Cap';

  @override
  String perPaymentCap(String amount) {
    return 'Per payment: $amount USDC';
  }

  @override
  String perDayCap(String amount) {
    return 'Per day: $amount USDC';
  }

  @override
  String usedToday(String amount) {
    return 'Used today: $amount USDC';
  }

  @override
  String remainingToday(String amount) {
    return 'Remaining today: $amount USDC';
  }

  @override
  String get capPolicyExplanation =>
      'Local policy of this app, counted with confirmed receipts on this phone. Not a Circle Agent Wallet. If the amount exceeds it, the order won\'t be assembled.';

  @override
  String get activity => 'Activity';

  @override
  String get noReceiptSaved => 'No receipt saved on this phone yet.';

  @override
  String get hashIsReceipt =>
      'The hash is the receipt. It does not replace a bank statement.';

  @override
  String get unresolvedRequest => 'Unresolved request';

  @override
  String get checkWalletHistory =>
      'Check the history and requests in your wallet before another send. If there\'s a hash, paste it to verify.';

  @override
  String get transactionHashLabel => 'Transaction hash 0x…';

  @override
  String get checkHash => 'Check hash';

  @override
  String get requestCancelledOrRejected => 'Request was cancelled or rejected';

  @override
  String get txSubmitted => 'Submitted · waiting for receipt';

  @override
  String get txConfirmed => 'Confirmed · successful execution';

  @override
  String get txReverted => 'Reverted · operation failed on chain';

  @override
  String get txPending => 'Pending · still no receipt';

  @override
  String get txUnknown => 'Unverified state · check the explorer';

  @override
  String get confirmed => 'Confirmed';

  @override
  String blockLabel(String number) {
    return 'Block $number';
  }

  @override
  String get checkReceipt => 'Check receipt';

  @override
  String get openExplorer => 'Open explorer';

  @override
  String get dailyOrders => 'Daily orders';

  @override
  String get ordersExplanation =>
      'Each item reflects an event already observed in this session. Not a simulated transfer.';

  @override
  String get orderVerifyArc => 'Verify Arc Testnet';

  @override
  String get orderExecuteRust => 'Execute Rust on device';

  @override
  String get orderActivateOpenHuman => 'Activate OpenHuman';

  @override
  String get orderConnectArcAccount => 'Connect an Arc account';

  @override
  String get orderConfirmTransfer => 'Confirm a real testnet transfer';

  @override
  String get agentBoxTitle => 'Box agent';

  @override
  String get agentLabTitle => 'Laboratory query';

  @override
  String get agentVerifyStatus => 'Verify the runtime and configure inference';

  @override
  String get agentDescription =>
      'The agent proposes orders with arc_network_status and arc_balance. An executed tool shows the data that Rust read. Model text does not authorize or sign.';

  @override
  String get agentLabDescription =>
      'OpenHuman coordinates the query within AW. The model must run in your laboratory, through the loopback endpoint you configure. No blockchain query is initiated.';

  @override
  String get verifyNativeRust => 'Verify native Rust execution';

  @override
  String libraryExecuted(String os, String arch) {
    return 'Library executed: $os / $arch';
  }

  @override
  String allowedTools(String tools) {
    return 'Allowed tools: $tools';
  }

  @override
  String get noTools => 'none';

  @override
  String get runtimeNotInitialized =>
      'Runtime not initialized. Tool policy is checked at initialization.';

  @override
  String nativePolicy(String mode) {
    return 'Native policy: $mode';
  }

  @override
  String get notStarted => 'not started';

  @override
  String agentBudget(String tokens) {
    return 'Agent budget: $tokens tokens. Does not certify the actual model capacity.';
  }

  @override
  String get localTestDisclaimer =>
      'This local test does not imply that inference or a transfer has been verified.';

  @override
  String get labTestDisclaimer =>
      'Running this library does not yet verify the laboratory model.';

  @override
  String get configureLabButton => 'Configure laboratory';

  @override
  String get configureProviderButton => 'Configure provider and start agent';

  @override
  String get queryLabel => 'Your query to the agent';

  @override
  String get presetArcStatus => 'Real Arc status';

  @override
  String get presetMyBalance => 'Check my balance';

  @override
  String get agentWorking => 'Agent working…';

  @override
  String get queryOpenHuman => 'Query OpenHuman';

  @override
  String get cancelTurn => 'Cancel turn';

  @override
  String get modelText => 'Model text';

  @override
  String get modelTextDisclaimer =>
      'That is model text. It is not a network read or a signature.';

  @override
  String toolsExecuted(String tools) {
    return 'Tools executed: $tools';
  }

  @override
  String liveReadTool(String tool) {
    return 'Executed read · $tool';
  }

  @override
  String blockNumber(String number) {
    return 'Block: $number';
  }

  @override
  String balanceUsdcLabel(String balance) {
    return 'USDC balance: $balance';
  }

  @override
  String observationUnix(String timestamp) {
    return 'UNIX observation: $timestamp';
  }

  @override
  String get toolResultOk => 'Result obtained by the Rust tool';

  @override
  String get toolResultFailed => 'The tool could not complete the read';

  @override
  String get applyProposal => 'Apply proposal to form';

  @override
  String get agentResponseDisclaimer =>
      'A model response is not a payment confirmation. The agent only proposes; signature requires your review in the wallet.';

  @override
  String get labResponseDisclaimer =>
      'Model output is untrusted text. It is not interpreted as an instruction nor enables actions.';

  @override
  String get lastQueryLog => 'Last query log';

  @override
  String get logMetadataNote =>
      'Client metadata only. Match this ID with the actual processing on your server and with the visible response. Messages and keys are not included.';

  @override
  String get copyLogWithoutKeys => 'Copy log without messages or keys';

  @override
  String get restartAfterInterrupted => 'Restart after interrupted turn';

  @override
  String get networkTitle => 'FluuiX Network';

  @override
  String get networkDescription =>
      'Each module has no contract until the operator provides endpoint, authentication, and catalog. There are no balances, rates, or loans.';

  @override
  String get zonaBankTitle => 'ZonaBank';

  @override
  String get zonaBankDesc =>
      'Accounts, contacts, intents, and settlement rails. ZonaBank does not store keys and is not a licensed bank.';

  @override
  String get lendingTitle => 'Lending';

  @override
  String get lendingDesc =>
      'The public map mentions financing against tokenized collateral. There is no catalog, rate, or loan in this app.';

  @override
  String get zonaFrancaTitle => 'ZonaFranca';

  @override
  String get zonaFrancaDesc =>
      'Registration and traceability of merchandise and logistics. Read-only when catalog is available.';

  @override
  String get ttnTitle => 'TTN';

  @override
  String get ttnDesc =>
      'Instruments already issued by TokenizaTuNegocio. Issuing a token is not a phone order.';

  @override
  String get capitalSection => 'Capital';

  @override
  String get fideicomisosTitle => 'Trusts';

  @override
  String get fideicomisosDesc =>
      'Capital vehicle of the same engine. No position to show.';

  @override
  String get fondosTitle => 'Funds';

  @override
  String get fondosDesc =>
      'Capital vehicle of the same engine. No position to show.';

  @override
  String get crowdTitle => 'Crowd';

  @override
  String get crowdDesc => 'Community financing. No campaign loaded.';

  @override
  String get licitacionesTitle => 'Bids';

  @override
  String get licitacionesDesc =>
      'Purchases with verifiable receipt. No process loaded.';

  @override
  String get donacionesTitle => 'Donations';

  @override
  String get donacionesDesc =>
      'Donation with traceability. No campaign loaded.';

  @override
  String get academiaTitle => 'Academy';

  @override
  String get academiaDesc => 'TokenizaTuNegocio training. Does not move funds.';

  @override
  String get whatProductPublishes => 'What the product publishes';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLabTitle => 'Laboratory configuration';

  @override
  String get walletConnectTitle => 'WalletConnect / Reown';

  @override
  String get walletConnectDescription =>
      'Enter your project\'s Project ID. Can be changed without recompiling. The wallet session remains only in memory; when the app restarts, it reconnects. FluuiX does not ask for seed phrase or private key.';

  @override
  String get projectIdLabel => 'Project ID';

  @override
  String get projectIdHint => '32 hexadecimal characters';

  @override
  String get connecting => 'Connecting…';

  @override
  String get saveAndConnectReown => 'Save and connect Reown';

  @override
  String get reownClientInitialized => 'Reown client initialized';

  @override
  String get inferenceTitle => 'Inference for OpenHuman';

  @override
  String get inferenceLabTitle => 'Local text server';

  @override
  String get inferenceDescription =>
      'Choose an OpenAI-compatible endpoint and the model enabled by your provider. The model uses the Internet; the Rust runtime runs on the phone.';

  @override
  String get inferenceLabDescription =>
      'Enter the literal loopback IP and the /v1 path of the transport you established to your authorized server. Choose a model already installed there. No default endpoint or model.';

  @override
  String get endpointLabel => 'HTTPS Endpoint';

  @override
  String get endpointLabLabel => 'Loopback endpoint /v1';

  @override
  String get endpointHint => 'https://provider.example/v1';

  @override
  String get endpointLabHint => 'Complete your authorized endpoint';

  @override
  String get modelLabel => 'Model ID';

  @override
  String get modelHint => 'Model enabled by your provider';

  @override
  String get modelLabHint => 'Exact ID of locally installed model';

  @override
  String get apiKeyLabel => 'Inference API key';

  @override
  String get apiKeyLabLabel => 'Server key or marker';

  @override
  String get apiKeyLabHelper =>
      'A synthetic marker does not protect or authenticate the server.';

  @override
  String get rememberKey => 'Remember key in system secure storage';

  @override
  String queriesSentTo(String host) {
    return 'When activating and querying, you send your messages and necessary context to $host.';
  }

  @override
  String get labQueriesNote =>
      'Queries are sent only to the indicated endpoint. Laboratory settings are saved separately from Arc mode.';

  @override
  String get initializing => 'Initializing…';

  @override
  String get startLabButton => 'Start text laboratory';

  @override
  String get activateOpenHumanButton => 'Activate OpenHuman with this provider';

  @override
  String get stopAgentForgetKey => 'Stop agent and forget key';

  @override
  String get addArcTestnetManually => 'Add Arc Testnet manually';

  @override
  String get arcManualInfo =>
      'Name: Arc Testnet\nChain ID: 5042002\nNative currency: USDC · 18 decimals';

  @override
  String get arcManualInstructions =>
      'Add the network in your wallet, then reconnect authorizing Arc Testnet. Adding a network does not automatically extend the permissions of an existing session.';

  @override
  String get officialDocs => 'Official documentation';

  @override
  String get retrySecureStorage => 'Retry reading secure state';

  @override
  String get connectYourWallet => 'Connect your wallet';

  @override
  String get scanFromOtherScreen =>
      'Scan from another screen or open a WalletConnect-compatible wallet. Return to FluuiX after approving.';

  @override
  String get walletMustHaveArc =>
      'The wallet must have Arc Testnet configured. The connection does not send funds.';

  @override
  String get goBack => 'Go back';

  @override
  String get copyUri => 'Copy URI';

  @override
  String get openWallet => 'Open wallet';

  @override
  String get uriCopied =>
      'URI copied. Paste it in WalletConnect inside your wallet.';

  @override
  String get useCopyUriOrQr =>
      'Use Copy URI and paste it in your wallet, or scan the QR.';

  @override
  String get noWalletForLink =>
      'No wallet found for this link. Use the QR or copy the URI.';

  @override
  String get reviewTransferTitle => 'Review transfer';

  @override
  String get arcTestnetTestFunds => 'Arc Testnet · test funds';

  @override
  String get from => 'From';

  @override
  String get recipient => 'Recipient';

  @override
  String maxFee(String amount) {
    return 'Maximum fee: $amount USDC';
  }

  @override
  String maxTotal(String amount) {
    return 'Maximum total: $amount USDC';
  }

  @override
  String get reviewExpiry =>
      'The review expires in 2 minutes. Verify in your wallet that network, recipient, amount, and fee match. Your wallet requests the final signature.';

  @override
  String get cancel => 'Cancel';

  @override
  String get requestApproval => 'Request approval';

  @override
  String get confirmWalletState => 'Confirm state in your wallet';

  @override
  String get confirmNoSendMessage =>
      'Continue only if you verified that the previous request was rejected or cancelled and that no pending or sent transfer exists. Repeating a send may duplicate payment.';

  @override
  String get verifiedNotSent => 'Verified it was not sent';

  @override
  String get proposalValidatedCopied =>
      'Proposal validated and copied. Review recipient, amount, and fee before signing.';

  @override
  String get couldNotOpenLink => 'Could not open link.';

  @override
  String get footerArcTestnet =>
      'Arc Testnet · test USDC\nThe external wallet controls your keys and requests signature. FluuiX does not request seed phrases or private keys.';

  @override
  String get footerLab =>
      'AW does not switch providers automatically. Confirm that the authorized server runs a local model; receiving text alone does not prove its origin.';

  @override
  String get labBannerTitle => 'Laboratory · text only';

  @override
  String get labBannerDesc =>
      'Wallet, payments, proposals, and Arc queries disabled. The agent has no tools. This mode is fixed at compile time.';

  @override
  String get ordersViewTooltip => 'Box view';

  @override
  String get missionViewTooltip => 'Daily orders';

  @override
  String get refreshArcTooltip => 'Refresh Arc';

  @override
  String get agentStoppedStatus =>
      'Agent stopped and local conversation discarded';

  @override
  String openHumanLocalActive(String host) {
    return 'OpenHuman local active · inference on $host';
  }

  @override
  String labReadyStatus(String endpoint, String model) {
    return 'Laboratory ready · endpoint $endpoint · requested model $model';
  }

  @override
  String get turnCompletedStatus => 'Turn completed by OpenHuman';

  @override
  String get labResponseReceivedStatus =>
      'Response received · match the ID with your server log';

  @override
  String rustExecutedStatus(String os, String arch) {
    return 'Rust executed on $os/$arch · ABI 1';
  }

  @override
  String get contextBarLayer => 'Layer';

  @override
  String get contextBarDisconnected => 'Disconnected';

  @override
  String get contextBarConnected => 'Connected';

  @override
  String get languageSettings => 'Language';

  @override
  String get languageAuto => 'Automatic (system)';

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
  String get navInicio => 'Home';

  @override
  String get navRieles => 'Rails';

  @override
  String get navMas => 'More';

  @override
  String get homeWelcome => 'Welcome to FluuiX';

  @override
  String get homeConnectedStatus => 'Wallet connected';

  @override
  String get homeDisconnectedStatus => 'Wallet disconnected';

  @override
  String get homeLayers => 'Layers';

  @override
  String get homeLayerCajaDesc => 'Payments and balance';

  @override
  String get homeLayerRielesDesc => 'Local instruments';

  @override
  String get homeLayerAgenteDesc => 'Smart assistant';

  @override
  String get homeLayerRedTitle => 'Network';

  @override
  String get homeLayerRedDesc => 'FluuiX modules';

  @override
  String get homeQuickActions => 'Quick actions';

  @override
  String get homeAskAgent => 'Ask';

  @override
  String get homeSystemStatus => 'System status';

  @override
  String get passageComingSoon => 'Coming soon';

  @override
  String get passageDescription =>
      'The CCTP bridge enables native USDC movement between chains. When active, you can pass funds from Arbitrum or other networks.';

  @override
  String get capPolicyTitle => 'Limit policy';

  @override
  String get rielesTitle => 'Rails';

  @override
  String get rielesDescription =>
      'Rails connect different instruments with the box. Each rail has its own balance and conditions.';

  @override
  String get rielUsdcNative => 'Native USDC';

  @override
  String get rielActive => 'Active';

  @override
  String get rielesHowItWorks => 'How rails work';

  @override
  String get rielesExplanation =>
      'A rail is a settlement channel between the box and an instrument. The local rail (Twin) enables operations with tokenized pesos. The reserve (cirBTC) is a savings instrument. USDC is Arc\'s native balance.';

  @override
  String get paymentChecklist => 'Checklist';

  @override
  String get checkRpcConnected => 'RPC connected';

  @override
  String get checkWalletConnected => 'Wallet connected';

  @override
  String get checkArcSupported => 'Arc authorized';

  @override
  String get checkWithinLimit => 'Within daily limit';

  @override
  String get paymentSheetDisclaimer =>
      'FluuiX prepares the order and displays it for review. Your external wallet requests the signature. Model text does not authorize or sign payments.';

  @override
  String get sheetChainRail => 'Chain and rail';

  @override
  String get sheetNoAuthNoSign => 'Does not authorize or sign';

  @override
  String get proposalSheetTitle => 'Agent proposal';

  @override
  String get proposalFromAgent => 'OpenHuman proposes this transfer';

  @override
  String get proposalNotFound => 'Proposal not found';

  @override
  String get proposalDisclaimer =>
      'The agent only proposes. Signature requires your review in the wallet. Verify recipient, amount, and fee before approving.';

  @override
  String get proposalCopyToForm => 'Copy to form';
}
