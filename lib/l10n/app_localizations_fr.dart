// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'FluuiX';

  @override
  String get appTitleLab => 'AW · Laboratoire de texte';

  @override
  String get taglineDollarBox => 'Caisse en dollars';

  @override
  String get testnetBadge => 'TESTNET';

  @override
  String get navCaja => 'Caisse';

  @override
  String get navAgente => 'Agent';

  @override
  String get navRed => 'Réseau';

  @override
  String get navAjustes => 'Paramètres';

  @override
  String get connectionPending => 'Connexion en attente';

  @override
  String get rpcVerified => 'RPC vérifié · Arc Testnet';

  @override
  String get cajaEnDolares => 'Caisse en dollars';

  @override
  String get balanceUsdc => 'USDC';

  @override
  String get arcTestnetSingleBalance =>
      'Arc Testnet · solde unique pour paiements et frais. N\'inclut pas le rail local ni la réserve.';

  @override
  String get arcVerified => 'Arc vérifié';

  @override
  String get arcNotVerified => 'Arc non vérifié';

  @override
  String get sessionActive => 'Session active';

  @override
  String get noSession => 'Sans session';

  @override
  String remainingCapLabel(String amount) {
    return 'Plafond restant $amount USDC';
  }

  @override
  String sessionOnArcTestnet(String chainId) {
    return 'Session sur Arc Testnet · chaîne $chainId';
  }

  @override
  String get disconnect => 'Déconnecter';

  @override
  String get viewAccount => 'Voir le compte';

  @override
  String get localRail => 'Rail local';

  @override
  String get reserve => 'Réserve';

  @override
  String get noContract => 'Sans contrat';

  @override
  String get notAddedToBox => 'Non ajouté à la caisse.';

  @override
  String get pay => 'Payer';

  @override
  String get receive => 'Recevoir';

  @override
  String get passage => 'Passerelle';

  @override
  String get cap => 'Plafond';

  @override
  String get payTitle => 'Payer';

  @override
  String get payDescription =>
      'L\'ordre est révisé dans FluuiX et signé dans votre portefeuille. S\'il dépasse le plafond, il ne sera pas assemblé.';

  @override
  String get recipientAddress => 'Adresse du destinataire';

  @override
  String get recipientHint => '0x…';

  @override
  String get amount => 'Montant';

  @override
  String get amountHelper => 'Jusqu\'à 6 décimales. Pas d\'arrondi.';

  @override
  String get processing => 'Traitement…';

  @override
  String get reviewTransfer => 'Réviser le transfert';

  @override
  String get connectWallet => 'Connecter le portefeuille';

  @override
  String get requestAddArcTestnet => 'Demander l\'ajout d\'Arc Testnet';

  @override
  String get getTestUsdc => 'Obtenir des USDC de test';

  @override
  String get receiveTitle => 'Recevoir';

  @override
  String get receiveConnectPrompt =>
      'Connectez le portefeuille pour afficher l\'adresse de la caisse. FluuiX ne génère pas son propre compte.';

  @override
  String get receiveDescription =>
      'Cette adresse reçoit des USDC sur Arc Testnet. Ce n\'est pas un compte bancaire.';

  @override
  String get passageTitle => 'Passerelle';

  @override
  String get passageNotConnected =>
      'La passerelle Arbitrum → Arc via CCTP n\'est pas connectée. Il n\'y a pas de solde d\'une autre chaîne sur cet écran et aucune passerelle n\'est assemblée.';

  @override
  String get capTitle => 'Plafond';

  @override
  String perPaymentCap(String amount) {
    return 'Par paiement : $amount USDC';
  }

  @override
  String perDayCap(String amount) {
    return 'Par jour : $amount USDC';
  }

  @override
  String usedToday(String amount) {
    return 'Utilisé aujourd\'hui : $amount USDC';
  }

  @override
  String remainingToday(String amount) {
    return 'Restant aujourd\'hui : $amount USDC';
  }

  @override
  String get capPolicyExplanation =>
      'Politique locale de cette application, comptée avec les reçus confirmés sur ce téléphone. Pas un Agent Wallet de Circle. Si le montant le dépasse, l\'ordre ne sera pas assemblé.';

  @override
  String get activity => 'Activité';

  @override
  String get noReceiptSaved => 'Aucun reçu enregistré sur ce téléphone.';

  @override
  String get hashIsReceipt =>
      'Le hash est le reçu. Il ne remplace pas un relevé bancaire.';

  @override
  String get unresolvedRequest => 'Demande non résolue';

  @override
  String get checkWalletHistory =>
      'Vérifiez l\'historique et les demandes dans votre portefeuille avant un autre envoi. S\'il y a un hash, collez-le pour vérifier.';

  @override
  String get transactionHashLabel => 'Hash de transaction 0x…';

  @override
  String get checkHash => 'Vérifier le hash';

  @override
  String get requestCancelledOrRejected =>
      'La demande a été annulée ou rejetée';

  @override
  String get txSubmitted => 'Envoyée · en attente de reçu';

  @override
  String get txConfirmed => 'Confirmée · exécution réussie';

  @override
  String get txReverted => 'Annulée · l\'opération a échoué sur le réseau';

  @override
  String get txPending => 'En attente · toujours sans reçu';

  @override
  String get txUnknown => 'État non vérifié · consultez l\'explorateur';

  @override
  String get confirmed => 'Confirmée';

  @override
  String blockLabel(String number) {
    return 'Bloc $number';
  }

  @override
  String get checkReceipt => 'Vérifier le reçu';

  @override
  String get openExplorer => 'Ouvrir l\'explorateur';

  @override
  String get dailyOrders => 'Ordres du jour';

  @override
  String get ordersExplanation =>
      'Chaque élément reflète un événement déjà observé dans cette session. Ce n\'est pas un transfert simulé.';

  @override
  String get orderVerifyArc => 'Vérifier Arc Testnet';

  @override
  String get orderExecuteRust => 'Exécuter Rust sur l\'appareil';

  @override
  String get orderActivateOpenHuman => 'Activer OpenHuman';

  @override
  String get orderConnectArcAccount => 'Connecter un compte Arc';

  @override
  String get orderConfirmTransfer => 'Confirmer un vrai transfert testnet';

  @override
  String get agentBoxTitle => 'Agent de la caisse';

  @override
  String get agentLabTitle => 'Requête au laboratoire';

  @override
  String get agentVerifyStatus =>
      'Vérifiez le runtime et configurez l\'inférence';

  @override
  String get agentDescription =>
      'L\'agent propose des ordres avec arc_network_status et arc_balance. Un outil exécuté montre les données que Rust a lues. Le texte du modèle n\'autorise ni ne signe.';

  @override
  String get agentLabDescription =>
      'OpenHuman coordonne la requête dans AW. Le modèle doit s\'exécuter dans votre laboratoire, via le endpoint loopback que vous configurez. Aucune requête blockchain n\'est initiée.';

  @override
  String get verifyNativeRust => 'Vérifier l\'exécution native de Rust';

  @override
  String libraryExecuted(String os, String arch) {
    return 'Bibliothèque exécutée : $os / $arch';
  }

  @override
  String allowedTools(String tools) {
    return 'Outils autorisés : $tools';
  }

  @override
  String get noTools => 'aucun';

  @override
  String get runtimeNotInitialized =>
      'Runtime non initialisé. La politique d\'outils est vérifiée à l\'initialisation.';

  @override
  String nativePolicy(String mode) {
    return 'Politique native : $mode';
  }

  @override
  String get notStarted => 'non démarré';

  @override
  String agentBudget(String tokens) {
    return 'Budget de l\'agent : $tokens tokens. Ne certifie pas la capacité réelle du modèle.';
  }

  @override
  String get localTestDisclaimer =>
      'Ce test local n\'implique pas que l\'inférence ou un transfert a été vérifié.';

  @override
  String get labTestDisclaimer =>
      'Exécuter cette bibliothèque ne vérifie pas encore le modèle du laboratoire.';

  @override
  String get configureLabButton => 'Configurer le laboratoire';

  @override
  String get configureProviderButton =>
      'Configurer le fournisseur et démarrer l\'agent';

  @override
  String get queryLabel => 'Votre requête à l\'agent';

  @override
  String get presetArcStatus => 'État réel d\'Arc';

  @override
  String get presetMyBalance => 'Consulter mon solde';

  @override
  String get agentWorking => 'Agent en cours…';

  @override
  String get queryOpenHuman => 'Interroger OpenHuman';

  @override
  String get cancelTurn => 'Annuler le tour';

  @override
  String get modelText => 'Texte du modèle';

  @override
  String get modelTextDisclaimer =>
      'C\'est du texte de modèle. Ce n\'est pas une lecture réseau ni une signature.';

  @override
  String toolsExecuted(String tools) {
    return 'Outils exécutés : $tools';
  }

  @override
  String liveReadTool(String tool) {
    return 'Lecture exécutée · $tool';
  }

  @override
  String blockNumber(String number) {
    return 'Bloc : $number';
  }

  @override
  String balanceUsdcLabel(String balance) {
    return 'Solde USDC : $balance';
  }

  @override
  String observationUnix(String timestamp) {
    return 'Observation UNIX : $timestamp';
  }

  @override
  String get toolResultOk => 'Résultat obtenu par l\'outil Rust';

  @override
  String get toolResultFailed => 'L\'outil n\'a pas pu terminer la lecture';

  @override
  String get applyProposal => 'Appliquer la proposition au formulaire';

  @override
  String get agentResponseDisclaimer =>
      'Une réponse du modèle n\'est pas une confirmation de paiement. L\'agent ne fait que proposer ; la signature nécessite votre révision dans le portefeuille.';

  @override
  String get labResponseDisclaimer =>
      'La sortie du modèle est un texte non fiable. Elle n\'est pas interprétée comme une instruction ni n\'active d\'actions.';

  @override
  String get lastQueryLog => 'Journal de la dernière requête';

  @override
  String get logMetadataNote =>
      'Métadonnées client uniquement. Comparez cet ID avec le traitement réel sur votre serveur et avec la réponse visible. Messages et clés non inclus.';

  @override
  String get copyLogWithoutKeys => 'Copier le journal sans messages ni clés';

  @override
  String get restartAfterInterrupted => 'Redémarrer après le tour interrompu';

  @override
  String get networkTitle => 'Réseau FluuiX';

  @override
  String get networkDescription =>
      'Chaque module est sans contrat jusqu\'à ce que l\'opérateur fournisse endpoint, authentification et catalogue. Il n\'y a ni soldes, ni taux, ni prêts.';

  @override
  String get zonaBankTitle => 'ZonaBank';

  @override
  String get zonaBankDesc =>
      'Comptes, contacts, intents et rails de règlement. ZonaBank ne stocke pas de clés et n\'est pas une banque agréée.';

  @override
  String get lendingTitle => 'Lending';

  @override
  String get lendingDesc =>
      'La carte publique mentionne le financement contre collatéral tokenisé. Il n\'y a ni catalogue, ni taux, ni prêt dans cette app.';

  @override
  String get zonaFrancaTitle => 'ZonaFranca';

  @override
  String get zonaFrancaDesc =>
      'Enregistrement et traçabilité des marchandises et de la logistique. Lecture seule quand le catalogue est disponible.';

  @override
  String get ttnTitle => 'TTN';

  @override
  String get ttnDesc =>
      'Instruments déjà émis par TokenizaTuNegocio. Émettre un token n\'est pas un ordre du téléphone.';

  @override
  String get capitalSection => 'Capital';

  @override
  String get fideicomisosTitle => 'Fiducies';

  @override
  String get fideicomisosDesc =>
      'Véhicule de capital du même moteur. Aucune position à afficher.';

  @override
  String get fondosTitle => 'Fonds';

  @override
  String get fondosDesc =>
      'Véhicule de capital du même moteur. Aucune position à afficher.';

  @override
  String get crowdTitle => 'Crowd';

  @override
  String get crowdDesc => 'Financement communautaire. Aucune campagne chargée.';

  @override
  String get licitacionesTitle => 'Appels d\'offres';

  @override
  String get licitacionesDesc =>
      'Achats avec reçu vérifiable. Aucun processus chargé.';

  @override
  String get donacionesTitle => 'Dons';

  @override
  String get donacionesDesc => 'Don avec traçabilité. Aucune campagne chargée.';

  @override
  String get academiaTitle => 'Académie';

  @override
  String get academiaDesc =>
      'Formation TokenizaTuNegocio. Ne déplace pas de fonds.';

  @override
  String get whatProductPublishes => 'Ce que le produit publie';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsLabTitle => 'Configuration du laboratoire';

  @override
  String get walletConnectTitle => 'WalletConnect / Reown';

  @override
  String get walletConnectDescription =>
      'Entrez le Project ID de votre projet. Peut être modifié sans recompiler. La session du portefeuille reste uniquement en mémoire ; au redémarrage de l\'app, elle se reconnecte. FluuiX ne demande pas de phrase de récupération ni de clé privée.';

  @override
  String get projectIdLabel => 'Project ID';

  @override
  String get projectIdHint => '32 caractères hexadécimaux';

  @override
  String get connecting => 'Connexion…';

  @override
  String get saveAndConnectReown => 'Enregistrer et connecter Reown';

  @override
  String get reownClientInitialized => 'Client Reown initialisé';

  @override
  String get inferenceTitle => 'Inférence pour OpenHuman';

  @override
  String get inferenceLabTitle => 'Serveur de texte local';

  @override
  String get inferenceDescription =>
      'Choisissez un endpoint compatible OpenAI et le modèle activé par votre fournisseur. Le modèle utilise Internet ; le runtime Rust s\'exécute sur le téléphone.';

  @override
  String get inferenceLabDescription =>
      'Entrez l\'IP loopback littérale et le chemin /v1 du transport que vous avez établi vers votre serveur autorisé. Choisissez un modèle déjà installé là-bas. Pas d\'endpoint ni de modèle par défaut.';

  @override
  String get endpointLabel => 'Endpoint HTTPS';

  @override
  String get endpointLabLabel => 'Endpoint loopback /v1';

  @override
  String get endpointHint => 'https://fournisseur.exemple/v1';

  @override
  String get endpointLabHint => 'Complétez votre endpoint autorisé';

  @override
  String get modelLabel => 'ID du modèle';

  @override
  String get modelHint => 'Modèle activé par votre fournisseur';

  @override
  String get modelLabHint => 'ID exact du modèle local installé';

  @override
  String get apiKeyLabel => 'Clé API d\'inférence';

  @override
  String get apiKeyLabLabel => 'Clé ou marqueur du serveur';

  @override
  String get apiKeyLabHelper =>
      'Un marqueur synthétique ne protège ni n\'authentifie le serveur.';

  @override
  String get rememberKey =>
      'Mémoriser la clé dans le stockage sécurisé du système';

  @override
  String queriesSentTo(String host) {
    return 'En activant et en interrogeant, vous envoyez vos messages et le contexte nécessaire à $host.';
  }

  @override
  String get labQueriesNote =>
      'Les requêtes sont envoyées uniquement à l\'endpoint indiqué. Les paramètres du laboratoire sont enregistrés séparément du mode Arc.';

  @override
  String get initializing => 'Initialisation…';

  @override
  String get startLabButton => 'Démarrer le laboratoire de texte';

  @override
  String get activateOpenHumanButton => 'Activer OpenHuman avec ce fournisseur';

  @override
  String get stopAgentForgetKey => 'Arrêter l\'agent et oublier la clé';

  @override
  String get addArcTestnetManually => 'Ajouter Arc Testnet manuellement';

  @override
  String get arcManualInfo =>
      'Nom : Arc Testnet\nChain ID : 5042002\nMonnaie native : USDC · 18 décimales';

  @override
  String get arcManualInstructions =>
      'Ajoutez le réseau dans votre portefeuille, puis reconnectez-vous en autorisant Arc Testnet. Ajouter un réseau n\'étend pas automatiquement les permissions d\'une session existante.';

  @override
  String get officialDocs => 'Documentation officielle';

  @override
  String get retrySecureStorage => 'Réessayer de lire l\'état sécurisé';

  @override
  String get connectYourWallet => 'Connectez votre portefeuille';

  @override
  String get scanFromOtherScreen =>
      'Scannez depuis un autre écran ou ouvrez un portefeuille compatible WalletConnect. Revenez à FluuiX après approbation.';

  @override
  String get walletMustHaveArc =>
      'Le portefeuille doit avoir Arc Testnet configuré. La connexion n\'envoie pas de fonds.';

  @override
  String get goBack => 'Retour';

  @override
  String get copyUri => 'Copier l\'URI';

  @override
  String get openWallet => 'Ouvrir le portefeuille';

  @override
  String get uriCopied =>
      'URI copiée. Collez-la dans WalletConnect dans votre portefeuille.';

  @override
  String get useCopyUriOrQr =>
      'Utilisez Copier l\'URI et collez-la dans votre portefeuille, ou scannez le QR.';

  @override
  String get noWalletForLink =>
      'Aucun portefeuille trouvé pour ce lien. Utilisez le QR ou copiez l\'URI.';

  @override
  String get reviewTransferTitle => 'Révisez le transfert';

  @override
  String get arcTestnetTestFunds => 'Arc Testnet · fonds de test';

  @override
  String get from => 'De';

  @override
  String get recipient => 'Destinataire';

  @override
  String maxFee(String amount) {
    return 'Frais maximum : $amount USDC';
  }

  @override
  String maxTotal(String amount) {
    return 'Total maximum : $amount USDC';
  }

  @override
  String get reviewExpiry =>
      'La révision expire dans 2 minutes. Vérifiez dans votre portefeuille que le réseau, le destinataire, le montant et les frais correspondent. Votre portefeuille demande la signature finale.';

  @override
  String get cancel => 'Annuler';

  @override
  String get requestApproval => 'Demander l\'approbation';

  @override
  String get confirmWalletState => 'Confirmez l\'état dans votre portefeuille';

  @override
  String get confirmNoSendMessage =>
      'Continuez uniquement si vous avez vérifié que la demande précédente a été rejetée ou annulée et qu\'il n\'existe pas de transfert en attente ou envoyé. Répéter un envoi peut dupliquer le paiement.';

  @override
  String get verifiedNotSent => 'Vérifié qu\'il n\'a pas été envoyé';

  @override
  String get proposalValidatedCopied =>
      'Proposition validée et copiée. Révisez le destinataire, le montant et les frais avant de signer.';

  @override
  String get couldNotOpenLink => 'Impossible d\'ouvrir le lien.';

  @override
  String get footerArcTestnet =>
      'Arc Testnet · USDC de test\nLe portefeuille externe contrôle vos clés et demande la signature. FluuiX ne demande pas de phrases de récupération ni de clés privées.';

  @override
  String get footerLab =>
      'AW ne change pas de fournisseur automatiquement. Confirmez que le serveur autorisé exécute un modèle local ; recevoir du texte seul ne prouve pas son origine.';

  @override
  String get labBannerTitle => 'Laboratoire · texte uniquement';

  @override
  String get labBannerDesc =>
      'Portefeuille, paiements, propositions et requêtes Arc désactivés. L\'agent n\'a pas d\'outils. Ce mode est fixé à la compilation.';

  @override
  String get ordersViewTooltip => 'Vue caisse';

  @override
  String get missionViewTooltip => 'Ordres du jour';

  @override
  String get refreshArcTooltip => 'Actualiser Arc';

  @override
  String get agentStoppedStatus =>
      'Agent arrêté et conversation locale supprimée';

  @override
  String openHumanLocalActive(String host) {
    return 'OpenHuman local actif · inférence sur $host';
  }

  @override
  String labReadyStatus(String endpoint, String model) {
    return 'Laboratoire prêt · endpoint $endpoint · modèle demandé $model';
  }

  @override
  String get turnCompletedStatus => 'Tour complété par OpenHuman';

  @override
  String get labResponseReceivedStatus =>
      'Réponse reçue · comparez l\'ID avec le journal de votre serveur';

  @override
  String rustExecutedStatus(String os, String arch) {
    return 'Rust exécuté sur $os/$arch · ABI 1';
  }

  @override
  String get contextBarLayer => 'Couche';

  @override
  String get contextBarDisconnected => 'Déconnecté';

  @override
  String get contextBarConnected => 'Connecté';

  @override
  String get languageSettings => 'Langue';

  @override
  String get languageAuto => 'Automatique (système)';

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
