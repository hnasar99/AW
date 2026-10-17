// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'FluuiX';

  @override
  String get appTitleLab => 'AW · Laboratório de texto';

  @override
  String get taglineDollarBox => 'Caixa em dólares';

  @override
  String get testnetBadge => 'TESTNET';

  @override
  String get navCaja => 'Caixa';

  @override
  String get navAgente => 'Agente';

  @override
  String get navRed => 'Rede';

  @override
  String get navAjustes => 'Ajustes';

  @override
  String get connectionPending => 'Conexão pendente';

  @override
  String get rpcVerified => 'RPC verificado · Arc Testnet';

  @override
  String get cajaEnDolares => 'Caixa em dólares';

  @override
  String get balanceUsdc => 'USDC';

  @override
  String get arcTestnetSingleBalance =>
      'Arc Testnet · saldo único para pagamentos e taxas. Não inclui trilho local nem reserva.';

  @override
  String get arcVerified => 'Arc verificado';

  @override
  String get arcNotVerified => 'Arc não verificado';

  @override
  String get sessionActive => 'Sessão ativa';

  @override
  String get noSession => 'Sem sessão';

  @override
  String remainingCapLabel(String amount) {
    return 'Limite restante $amount USDC';
  }

  @override
  String sessionOnArcTestnet(String chainId) {
    return 'Sessão em Arc Testnet · cadeia $chainId';
  }

  @override
  String get disconnect => 'Desconectar';

  @override
  String get viewAccount => 'Ver conta';

  @override
  String get localRail => 'Trilho local';

  @override
  String get reserve => 'Reserva';

  @override
  String get noContract => 'Sem contrato';

  @override
  String get notAddedToBox => 'Não é somado à caixa.';

  @override
  String get pay => 'Pagar';

  @override
  String get receive => 'Receber';

  @override
  String get passage => 'Passar';

  @override
  String get cap => 'Limite';

  @override
  String get payTitle => 'Pagar';

  @override
  String get payDescription =>
      'A ordem é revisada no FluuiX e assinada na sua carteira. Se exceder o limite, não será montada.';

  @override
  String get recipientAddress => 'Endereço do destinatário';

  @override
  String get recipientHint => '0x…';

  @override
  String get amount => 'Valor';

  @override
  String get amountHelper => 'Até 6 casas decimais. Sem arredondamento.';

  @override
  String get processing => 'Processando…';

  @override
  String get reviewTransfer => 'Revisar transferência';

  @override
  String get connectWallet => 'Conectar carteira';

  @override
  String get requestAddArcTestnet => 'Solicitar adicionar Arc Testnet';

  @override
  String get getTestUsdc => 'Obter USDC de teste';

  @override
  String get receiveTitle => 'Receber';

  @override
  String get receiveConnectPrompt =>
      'Conecte a carteira para mostrar o endereço da caixa. FluuiX não gera conta própria.';

  @override
  String get receiveDescription =>
      'Este endereço recebe USDC em Arc Testnet. Não é uma conta bancária.';

  @override
  String get passageTitle => 'Passar';

  @override
  String get passageNotConnected =>
      'A ponte Arbitrum → Arc via CCTP não está conectada. Não há saldo de outra cadeia nesta tela e nenhuma ponte é montada.';

  @override
  String get capTitle => 'Limite';

  @override
  String perPaymentCap(String amount) {
    return 'Por pagamento: $amount USDC';
  }

  @override
  String perDayCap(String amount) {
    return 'Por dia: $amount USDC';
  }

  @override
  String usedToday(String amount) {
    return 'Usado hoje: $amount USDC';
  }

  @override
  String remainingToday(String amount) {
    return 'Restante hoje: $amount USDC';
  }

  @override
  String get capPolicyExplanation =>
      'Política local deste app, contada com recibos confirmados neste telefone. Não é um Agent Wallet da Circle. Se o valor exceder, a ordem não será montada.';

  @override
  String get activity => 'Atividade';

  @override
  String get noReceiptSaved => 'Ainda não há recibo salvo neste telefone.';

  @override
  String get hashIsReceipt =>
      'O hash é o recibo. Não substitui extrato bancário.';

  @override
  String get unresolvedRequest => 'Solicitação não resolvida';

  @override
  String get checkWalletHistory =>
      'Verifique o histórico e as solicitações na sua carteira antes de outro envio. Se houver um hash, cole para verificar.';

  @override
  String get transactionHashLabel => 'Hash da transação 0x…';

  @override
  String get checkHash => 'Verificar hash';

  @override
  String get requestCancelledOrRejected =>
      'A solicitação foi cancelada ou rejeitada';

  @override
  String get txSubmitted => 'Enviada · aguardando recibo';

  @override
  String get txConfirmed => 'Confirmada · execução bem-sucedida';

  @override
  String get txReverted => 'Revertida · operação falhou na rede';

  @override
  String get txPending => 'Pendente · ainda sem recibo';

  @override
  String get txUnknown => 'Estado não verificado · consulte o explorador';

  @override
  String get confirmed => 'Confirmada';

  @override
  String blockLabel(String number) {
    return 'Bloco $number';
  }

  @override
  String get checkReceipt => 'Verificar recibo';

  @override
  String get openExplorer => 'Abrir explorador';

  @override
  String get dailyOrders => 'Ordens do dia';

  @override
  String get ordersExplanation =>
      'Cada item reflete um evento já observado nesta sessão. Não é uma transferência simulada.';

  @override
  String get orderVerifyArc => 'Verificar Arc Testnet';

  @override
  String get orderExecuteRust => 'Executar Rust no dispositivo';

  @override
  String get orderActivateOpenHuman => 'Ativar OpenHuman';

  @override
  String get orderConnectArcAccount => 'Conectar uma conta em Arc';

  @override
  String get orderConfirmTransfer =>
      'Confirmar uma transferência real de testnet';

  @override
  String get agentBoxTitle => 'Agente da caixa';

  @override
  String get agentLabTitle => 'Consulta ao laboratório';

  @override
  String get agentVerifyStatus =>
      'Verifique o runtime e configure a inferência';

  @override
  String get agentDescription =>
      'O agente propõe ordens com arc_network_status e arc_balance. Uma ferramenta executada mostra o dado que o Rust leu. Texto do modelo não autoriza nem assina.';

  @override
  String get agentLabDescription =>
      'OpenHuman coordena a consulta dentro do AW. O modelo deve rodar no seu laboratório, através do endpoint loopback que você configurar. Nenhuma consulta blockchain é iniciada.';

  @override
  String get verifyNativeRust => 'Verificar execução nativa do Rust';

  @override
  String libraryExecuted(String os, String arch) {
    return 'Biblioteca executada: $os / $arch';
  }

  @override
  String allowedTools(String tools) {
    return 'Ferramentas permitidas: $tools';
  }

  @override
  String get noTools => 'nenhuma';

  @override
  String get runtimeNotInitialized =>
      'Runtime não inicializado. A política de ferramentas é verificada na inicialização.';

  @override
  String nativePolicy(String mode) {
    return 'Política nativa: $mode';
  }

  @override
  String get notStarted => 'não iniciado';

  @override
  String agentBudget(String tokens) {
    return 'Orçamento do agente: $tokens tokens. Não certifica a capacidade real do modelo.';
  }

  @override
  String get localTestDisclaimer =>
      'Este teste local não implica que a inferência ou uma transferência foram verificadas.';

  @override
  String get labTestDisclaimer =>
      'Executar esta biblioteca ainda não verifica o modelo do laboratório.';

  @override
  String get configureLabButton => 'Configurar laboratório';

  @override
  String get configureProviderButton => 'Configurar provedor e iniciar agente';

  @override
  String get queryLabel => 'Sua consulta ao agente';

  @override
  String get presetArcStatus => 'Status real do Arc';

  @override
  String get presetMyBalance => 'Consultar meu saldo';

  @override
  String get agentWorking => 'Agente trabalhando…';

  @override
  String get queryOpenHuman => 'Consultar OpenHuman';

  @override
  String get cancelTurn => 'Cancelar turno';

  @override
  String get modelText => 'Texto do modelo';

  @override
  String get modelTextDisclaimer =>
      'Isso é texto do modelo. Não é uma leitura de rede nem uma assinatura.';

  @override
  String toolsExecuted(String tools) {
    return 'Ferramentas executadas: $tools';
  }

  @override
  String liveReadTool(String tool) {
    return 'Leitura executada · $tool';
  }

  @override
  String blockNumber(String number) {
    return 'Bloco: $number';
  }

  @override
  String balanceUsdcLabel(String balance) {
    return 'Saldo USDC: $balance';
  }

  @override
  String observationUnix(String timestamp) {
    return 'Observação UNIX: $timestamp';
  }

  @override
  String get toolResultOk => 'Resultado obtido pela ferramenta Rust';

  @override
  String get toolResultFailed =>
      'A ferramenta não conseguiu completar a leitura';

  @override
  String get applyProposal => 'Levar proposta ao formulário';

  @override
  String get agentResponseDisclaimer =>
      'Uma resposta do modelo não é uma confirmação de pagamento. O agente só propõe; a assinatura requer sua revisão na carteira.';

  @override
  String get labResponseDisclaimer =>
      'A saída do modelo é texto não confiável. Não é interpretada como instrução nem habilita ações.';

  @override
  String get lastQueryLog => 'Registro da última consulta';

  @override
  String get logMetadataNote =>
      'Apenas metadados do cliente. Compare este ID com o processamento real no seu servidor e com a resposta visível. Mensagens e chaves não incluídas.';

  @override
  String get copyLogWithoutKeys => 'Copiar registro sem mensagens nem chaves';

  @override
  String get restartAfterInterrupted => 'Reiniciar após turno interrompido';

  @override
  String get networkTitle => 'Rede FluuiX';

  @override
  String get networkDescription =>
      'Cada módulo está sem contrato até que o operador forneça endpoint, autenticação e catálogo. Não há saldos, taxas nem empréstimos.';

  @override
  String get zonaBankTitle => 'ZonaBank';

  @override
  String get zonaBankDesc =>
      'Contas, contatos, intents e trilhos de liquidação. ZonaBank não guarda chaves e não é um banco licenciado.';

  @override
  String get lendingTitle => 'Lending';

  @override
  String get lendingDesc =>
      'O mapa público menciona financiamento contra colateral tokenizado. Não há catálogo, taxa nem empréstimo neste app.';

  @override
  String get zonaFrancaTitle => 'ZonaFranca';

  @override
  String get zonaFrancaDesc =>
      'Registro e rastreabilidade de mercadoria e logística. Somente leitura quando houver catálogo.';

  @override
  String get ttnTitle => 'TTN';

  @override
  String get ttnDesc =>
      'Instrumentos já emitidos por TokenizaTuNegocio. Emitir um token não é uma ordem do telefone.';

  @override
  String get capitalSection => 'Capital';

  @override
  String get fideicomisosTitle => 'Fideicomissos';

  @override
  String get fideicomisosDesc =>
      'Veículo de capital do mesmo motor. Sem posição para mostrar.';

  @override
  String get fondosTitle => 'Fundos';

  @override
  String get fondosDesc =>
      'Veículo de capital do mesmo motor. Sem posição para mostrar.';

  @override
  String get crowdTitle => 'Crowd';

  @override
  String get crowdDesc =>
      'Financiamento com a comunidade. Sem campanha carregada.';

  @override
  String get licitacionesTitle => 'Licitações';

  @override
  String get licitacionesDesc =>
      'Compras com recibo verificável. Sem processo carregado.';

  @override
  String get donacionesTitle => 'Doações';

  @override
  String get donacionesDesc =>
      'Doação com rastreabilidade. Sem campanha carregada.';

  @override
  String get academiaTitle => 'Academia';

  @override
  String get academiaDesc =>
      'Formação da TokenizaTuNegocio. Não movimenta fundos.';

  @override
  String get whatProductPublishes => 'O que o produto publica';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsLabTitle => 'Configuração do laboratório';

  @override
  String get walletConnectTitle => 'WalletConnect / Reown';

  @override
  String get walletConnectDescription =>
      'Insira o Project ID do seu projeto. Pode ser alterado sem recompilar. A sessão da carteira permanece apenas na memória; ao reiniciar o app, reconecta. FluuiX não pede frase semente nem chave privada.';

  @override
  String get projectIdLabel => 'Project ID';

  @override
  String get projectIdHint => '32 caracteres hexadecimais';

  @override
  String get connecting => 'Conectando…';

  @override
  String get saveAndConnectReown => 'Salvar e conectar Reown';

  @override
  String get reownClientInitialized => 'Cliente Reown inicializado';

  @override
  String get inferenceTitle => 'Inferência para OpenHuman';

  @override
  String get inferenceLabTitle => 'Servidor de texto local';

  @override
  String get inferenceDescription =>
      'Escolha um endpoint compatível com OpenAI e o modelo habilitado pelo seu provedor. O modelo usa a Internet; o runtime Rust roda no telefone.';

  @override
  String get inferenceLabDescription =>
      'Insira o IP loopback literal e o caminho /v1 do transporte que você estabeleceu para seu servidor autorizado. Escolha um modelo já instalado lá. Não há endpoint nem modelo padrão.';

  @override
  String get endpointLabel => 'Endpoint HTTPS';

  @override
  String get endpointLabLabel => 'Endpoint loopback /v1';

  @override
  String get endpointHint => 'https://provedor.exemplo/v1';

  @override
  String get endpointLabHint => 'Complete seu endpoint autorizado';

  @override
  String get modelLabel => 'ID do modelo';

  @override
  String get modelHint => 'Modelo habilitado pelo seu provedor';

  @override
  String get modelLabHint => 'ID exato do modelo local instalado';

  @override
  String get apiKeyLabel => 'Chave API de inferência';

  @override
  String get apiKeyLabLabel => 'Chave ou marcador do servidor';

  @override
  String get apiKeyLabHelper =>
      'Um marcador sintético não protege nem autentica o servidor.';

  @override
  String get rememberKey => 'Lembrar chave no armazenamento seguro do sistema';

  @override
  String queriesSentTo(String host) {
    return 'Ao ativar e consultar, você envia suas mensagens e contexto necessário para $host.';
  }

  @override
  String get labQueriesNote =>
      'Consultas são enviadas apenas para o endpoint indicado. Ajustes do laboratório são salvos separadamente do modo Arc.';

  @override
  String get initializing => 'Inicializando…';

  @override
  String get startLabButton => 'Iniciar laboratório de texto';

  @override
  String get activateOpenHumanButton => 'Ativar OpenHuman com este provedor';

  @override
  String get stopAgentForgetKey => 'Parar agente e esquecer chave';

  @override
  String get addArcTestnetManually => 'Adicionar Arc Testnet manualmente';

  @override
  String get arcManualInfo =>
      'Nome: Arc Testnet\nChain ID: 5042002\nMoeda nativa: USDC · 18 decimais';

  @override
  String get arcManualInstructions =>
      'Adicione a rede na sua carteira, depois reconecte autorizando Arc Testnet. Adicionar uma rede não estende automaticamente as permissões de uma sessão existente.';

  @override
  String get officialDocs => 'Documentação oficial';

  @override
  String get retrySecureStorage => 'Tentar ler estado seguro novamente';

  @override
  String get connectYourWallet => 'Conecte sua carteira';

  @override
  String get scanFromOtherScreen =>
      'Escaneie de outra tela ou abra uma carteira compatível com WalletConnect. Volte ao FluuiX após aprovar.';

  @override
  String get walletMustHaveArc =>
      'A carteira deve ter Arc Testnet configurada. A conexão não envia fundos.';

  @override
  String get goBack => 'Voltar';

  @override
  String get copyUri => 'Copiar URI';

  @override
  String get openWallet => 'Abrir carteira';

  @override
  String get uriCopied =>
      'URI copiada. Cole no WalletConnect dentro da sua carteira.';

  @override
  String get useCopyUriOrQr =>
      'Use Copiar URI e cole na sua carteira, ou escaneie o QR.';

  @override
  String get noWalletForLink =>
      'Nenhuma carteira encontrada para este link. Use o QR ou copie a URI.';

  @override
  String get reviewTransferTitle => 'Revise a transferência';

  @override
  String get arcTestnetTestFunds => 'Arc Testnet · fundos de teste';

  @override
  String get from => 'De';

  @override
  String get recipient => 'Destinatário';

  @override
  String maxFee(String amount) {
    return 'Taxa máxima: $amount USDC';
  }

  @override
  String maxTotal(String amount) {
    return 'Total máximo: $amount USDC';
  }

  @override
  String get reviewExpiry =>
      'A revisão expira em 2 minutos. Verifique na sua carteira que rede, destinatário, valor e taxa coincidem. Sua carteira solicita a assinatura final.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get requestApproval => 'Solicitar aprovação';

  @override
  String get confirmWalletState => 'Confirme o estado na sua carteira';

  @override
  String get confirmNoSendMessage =>
      'Continue apenas se verificou que a solicitação anterior foi rejeitada ou cancelada e que não existe transferência pendente ou enviada. Repetir um envio pode duplicar o pagamento.';

  @override
  String get verifiedNotSent => 'Verifiquei que não foi enviado';

  @override
  String get proposalValidatedCopied =>
      'Proposta validada e copiada. Revise destinatário, valor e taxa antes de assinar.';

  @override
  String get couldNotOpenLink => 'Não foi possível abrir o link.';

  @override
  String get footerArcTestnet =>
      'Arc Testnet · USDC de teste\nA carteira externa controla suas chaves e pede a assinatura. FluuiX não solicita frases semente nem chaves privadas.';

  @override
  String get footerLab =>
      'AW não muda de provedor automaticamente. Confirme que o servidor autorizado executa um modelo local; receber texto não prova por si só sua origem.';

  @override
  String get labBannerTitle => 'Laboratório · apenas texto';

  @override
  String get labBannerDesc =>
      'Carteira, pagamentos, propostas e consultas Arc desabilitados. O agente não dispõe de ferramentas. Este modo fica fixo ao compilar o app.';

  @override
  String get ordersViewTooltip => 'Vista da caixa';

  @override
  String get missionViewTooltip => 'Ordens do dia';

  @override
  String get refreshArcTooltip => 'Atualizar Arc';

  @override
  String get agentStoppedStatus => 'Agente parado e conversa local descartada';

  @override
  String openHumanLocalActive(String host) {
    return 'OpenHuman local ativo · inferência em $host';
  }

  @override
  String labReadyStatus(String endpoint, String model) {
    return 'Laboratório pronto · endpoint $endpoint · modelo solicitado $model';
  }

  @override
  String get turnCompletedStatus => 'Turno completado pelo OpenHuman';

  @override
  String get labResponseReceivedStatus =>
      'Resposta recebida · compare o ID com o registro do seu servidor';

  @override
  String rustExecutedStatus(String os, String arch) {
    return 'Rust executado em $os/$arch · ABI 1';
  }

  @override
  String get contextBarLayer => 'Camada';

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

  @override
  String get navInicio => 'Início';

  @override
  String get navRieles => 'Trilhos';

  @override
  String get navMas => 'Mais';

  @override
  String get homeWelcome => 'Bem-vindo ao FluuiX';

  @override
  String get homeConnectedStatus => 'Carteira conectada';

  @override
  String get homeDisconnectedStatus => 'Carteira desconectada';

  @override
  String get homeLayers => 'Camadas';

  @override
  String get homeLayerAgentes => 'Agentes';

  @override
  String get homeLayerAgentesDesc => 'IA que propõe operações';

  @override
  String get homeLayerRieles => 'Trilhos';

  @override
  String get homeLayerRielesDesc => 'Instrumentos locais';

  @override
  String get homeLayerContratos => 'Contratos';

  @override
  String get homeLayerContratosDesc => 'Contratos inteligentes';

  @override
  String get homeLayerWallets => 'Carteiras';

  @override
  String get homeLayerWalletsDesc => 'Gestão de carteiras';

  @override
  String get homeLayerSettlement => 'Liquidação';

  @override
  String get homeLayerSettlementDesc => 'Liquidação final';

  @override
  String get homeLayerMultichain => 'Multicadeia';

  @override
  String get homeLayerMultichainDesc => 'Pontes entre cadeias';

  @override
  String get layerStateActive => 'Ativo';

  @override
  String get layerStatePartial => 'Parcial';

  @override
  String get homeQuickActions => 'Ações rápidas';

  @override
  String get homeAskAgent => 'Perguntar';

  @override
  String get homeSystemStatus => 'Status do sistema';

  @override
  String get passageComingSoon => 'Em breve';

  @override
  String get passageDescription =>
      'A ponte CCTP permite mover USDC nativamente entre cadeias. Quando ativo, você poderá passar fundos do Arbitrum ou outras redes.';

  @override
  String get capPolicyTitle => 'Política de limites';

  @override
  String get rielesTitle => 'Trilhos';

  @override
  String get rielesDescription =>
      'Os trilhos conectam diferentes instrumentos com a caixa. Cada trilho tem seu próprio saldo e condições.';

  @override
  String get rielUsdcNative => 'USDC nativo';

  @override
  String get rielActive => 'Ativo';

  @override
  String get rielesHowItWorks => 'Como funcionam os trilhos';

  @override
  String get rielesExplanation =>
      'Um trilho é um canal de liquidação entre a caixa e um instrumento. O trilho local (Twin) permite operar com pesos tokenizados. A reserva (cirBTC) é um instrumento de poupança. USDC é o saldo nativo do Arc.';

  @override
  String get paymentChecklist => 'Lista de verificação';

  @override
  String get checkRpcConnected => 'RPC conectado';

  @override
  String get checkWalletConnected => 'Carteira conectada';

  @override
  String get checkArcSupported => 'Arc autorizado';

  @override
  String get checkWithinLimit => 'Dentro do limite diário';

  @override
  String get paymentSheetDisclaimer =>
      'FluuiX prepara a ordem e a exibe para revisão. Sua carteira externa solicita a assinatura. O texto do modelo não autoriza nem assina pagamentos.';

  @override
  String get sheetChainRail => 'Cadeia e trilho';

  @override
  String get sheetNoAuthNoSign => 'Não autoriza nem assina';

  @override
  String get proposalSheetTitle => 'Proposta do agente';

  @override
  String get proposalFromAgent => 'OpenHuman propõe esta transferência';

  @override
  String get proposalNotFound => 'Proposta não encontrada';

  @override
  String get proposalDisclaimer =>
      'O agente apenas propõe. A assinatura requer sua revisão na carteira. Verifique destinatário, valor e taxa antes de aprovar.';

  @override
  String get proposalCopyToForm => 'Copiar para formulário';
}
