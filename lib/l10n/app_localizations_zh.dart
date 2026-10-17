// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'FluuiX';

  @override
  String get appTitleLab => 'AW · 文本实验室';

  @override
  String get taglineDollarBox => '美元钱箱';

  @override
  String get testnetBadge => '测试网';

  @override
  String get navCaja => '钱箱';

  @override
  String get navAgente => '代理';

  @override
  String get navRed => '网络';

  @override
  String get navAjustes => '设置';

  @override
  String get connectionPending => '连接等待中';

  @override
  String get rpcVerified => 'RPC 已验证 · Arc 测试网';

  @override
  String get cajaEnDolares => '美元钱箱';

  @override
  String get balanceUsdc => 'USDC';

  @override
  String get arcTestnetSingleBalance => 'Arc 测试网 · 支付和费用的单一余额。不包括本地轨道和储备金。';

  @override
  String get arcVerified => 'Arc 已验证';

  @override
  String get arcNotVerified => 'Arc 未验证';

  @override
  String get sessionActive => '会话活跃';

  @override
  String get noSession => '无会话';

  @override
  String remainingCapLabel(String amount) {
    return '剩余限额 $amount USDC';
  }

  @override
  String sessionOnArcTestnet(String chainId) {
    return 'Arc 测试网会话 · 链 $chainId';
  }

  @override
  String get disconnect => '断开连接';

  @override
  String get viewAccount => '查看账户';

  @override
  String get localRail => '本地轨道';

  @override
  String get reserve => '储备金';

  @override
  String get noContract => '无合约';

  @override
  String get notAddedToBox => '未添加到钱箱。';

  @override
  String get pay => '支付';

  @override
  String get receive => '接收';

  @override
  String get passage => '桥接';

  @override
  String get cap => '限额';

  @override
  String get payTitle => '支付';

  @override
  String get payDescription => '订单在 FluuiX 中审核并在您的钱包中签名。如果超过限额，将不会组装。';

  @override
  String get recipientAddress => '收款人地址';

  @override
  String get recipientHint => '0x…';

  @override
  String get amount => '金额';

  @override
  String get amountHelper => '最多6位小数。无舍入。';

  @override
  String get processing => '处理中…';

  @override
  String get reviewTransfer => '审核转账';

  @override
  String get connectWallet => '连接钱包';

  @override
  String get requestAddArcTestnet => '请求添加 Arc 测试网';

  @override
  String get getTestUsdc => '获取测试 USDC';

  @override
  String get receiveTitle => '接收';

  @override
  String get receiveConnectPrompt => '连接钱包以显示钱箱地址。FluuiX 不生成自己的账户。';

  @override
  String get receiveDescription => '此地址在 Arc 测试网上接收 USDC。这不是银行账户。';

  @override
  String get passageTitle => '桥接';

  @override
  String get passageNotConnected =>
      'Arbitrum → Arc CCTP 桥接未连接。此屏幕上没有来自其他链的余额，也没有组装桥接。';

  @override
  String get capTitle => '限额';

  @override
  String perPaymentCap(String amount) {
    return '每笔支付：$amount USDC';
  }

  @override
  String perDayCap(String amount) {
    return '每日：$amount USDC';
  }

  @override
  String usedToday(String amount) {
    return '今日已用：$amount USDC';
  }

  @override
  String remainingToday(String amount) {
    return '今日剩余：$amount USDC';
  }

  @override
  String get capPolicyExplanation =>
      '此应用的本地策略，根据此手机上确认的收据计算。不是 Circle Agent Wallet。如果金额超过，订单将不会组装。';

  @override
  String get activity => '活动';

  @override
  String get noReceiptSaved => '此手机上尚未保存收据。';

  @override
  String get hashIsReceipt => '哈希就是收据。它不能替代银行对账单。';

  @override
  String get unresolvedRequest => '未解决的请求';

  @override
  String get checkWalletHistory => '在再次发送之前，请检查钱包中的历史记录和请求。如果有哈希，请粘贴以验证。';

  @override
  String get transactionHashLabel => '交易哈希 0x…';

  @override
  String get checkHash => '检查哈希';

  @override
  String get requestCancelledOrRejected => '请求已取消或拒绝';

  @override
  String get txSubmitted => '已提交 · 等待收据';

  @override
  String get txConfirmed => '已确认 · 执行成功';

  @override
  String get txReverted => '已回滚 · 链上操作失败';

  @override
  String get txPending => '待处理 · 仍无收据';

  @override
  String get txUnknown => '未验证状态 · 请查看浏览器';

  @override
  String get confirmed => '已确认';

  @override
  String blockLabel(String number) {
    return '区块 $number';
  }

  @override
  String get checkReceipt => '检查收据';

  @override
  String get openExplorer => '打开浏览器';

  @override
  String get dailyOrders => '每日订单';

  @override
  String get ordersExplanation => '每个项目反映此会话中已观察到的事件。不是模拟转账。';

  @override
  String get orderVerifyArc => '验证 Arc 测试网';

  @override
  String get orderExecuteRust => '在设备上执行 Rust';

  @override
  String get orderActivateOpenHuman => '激活 OpenHuman';

  @override
  String get orderConnectArcAccount => '连接 Arc 账户';

  @override
  String get orderConfirmTransfer => '确认真实测试网转账';

  @override
  String get agentBoxTitle => '钱箱代理';

  @override
  String get agentLabTitle => '实验室查询';

  @override
  String get agentVerifyStatus => '验证运行时并配置推理';

  @override
  String get agentDescription =>
      '代理使用 arc_network_status 和 arc_balance 提出订单。执行的工具显示 Rust 读取的数据。模型文本不授权或签名。';

  @override
  String get agentLabDescription =>
      'OpenHuman 在 AW 内协调查询。模型必须在您的实验室中运行，通过您配置的回环端点。不启动区块链查询。';

  @override
  String get verifyNativeRust => '验证原生 Rust 执行';

  @override
  String libraryExecuted(String os, String arch) {
    return '库已执行：$os / $arch';
  }

  @override
  String allowedTools(String tools) {
    return '允许的工具：$tools';
  }

  @override
  String get noTools => '无';

  @override
  String get runtimeNotInitialized => '运行时未初始化。工具策略在初始化时检查。';

  @override
  String nativePolicy(String mode) {
    return '原生策略：$mode';
  }

  @override
  String get notStarted => '未启动';

  @override
  String agentBudget(String tokens) {
    return '代理预算：$tokens 代币。不证明模型的实际容量。';
  }

  @override
  String get localTestDisclaimer => '此本地测试并不意味着推理或转账已被验证。';

  @override
  String get labTestDisclaimer => '运行此库尚未验证实验室模型。';

  @override
  String get configureLabButton => '配置实验室';

  @override
  String get configureProviderButton => '配置提供商并启动代理';

  @override
  String get queryLabel => '您对代理的查询';

  @override
  String get presetArcStatus => '真实 Arc 状态';

  @override
  String get presetMyBalance => '查询我的余额';

  @override
  String get agentWorking => '代理工作中…';

  @override
  String get queryOpenHuman => '查询 OpenHuman';

  @override
  String get cancelTurn => '取消回合';

  @override
  String get modelText => '模型文本';

  @override
  String get modelTextDisclaimer => '这是模型文本。它不是网络读取或签名。';

  @override
  String toolsExecuted(String tools) {
    return '已执行的工具：$tools';
  }

  @override
  String liveReadTool(String tool) {
    return '已执行读取 · $tool';
  }

  @override
  String blockNumber(String number) {
    return '区块：$number';
  }

  @override
  String balanceUsdcLabel(String balance) {
    return 'USDC 余额：$balance';
  }

  @override
  String observationUnix(String timestamp) {
    return 'UNIX 观察：$timestamp';
  }

  @override
  String get toolResultOk => 'Rust 工具获取的结果';

  @override
  String get toolResultFailed => '工具无法完成读取';

  @override
  String get applyProposal => '将提案应用到表单';

  @override
  String get agentResponseDisclaimer => '模型响应不是付款确认。代理只提出建议；签名需要您在钱包中审核。';

  @override
  String get labResponseDisclaimer => '模型输出是不受信任的文本。它不被解释为指令，也不启用操作。';

  @override
  String get lastQueryLog => '上次查询日志';

  @override
  String get logMetadataNote => '仅客户端元数据。将此 ID 与服务器上的实际处理和可见响应进行比较。不包括消息和密钥。';

  @override
  String get copyLogWithoutKeys => '复制不含消息或密钥的日志';

  @override
  String get restartAfterInterrupted => '中断回合后重新启动';

  @override
  String get networkTitle => 'FluuiX 网络';

  @override
  String get networkDescription => '每个模块都没有合约，直到运营商提供端点、身份验证和目录。没有余额、费率或贷款。';

  @override
  String get zonaBankTitle => 'ZonaBank';

  @override
  String get zonaBankDesc => '账户、联系人、意图和结算轨道。ZonaBank 不存储密钥，不是持牌银行。';

  @override
  String get lendingTitle => '借贷';

  @override
  String get lendingDesc => '公开地图提到针对代币化抵押品的融资。此应用中没有目录、费率或贷款。';

  @override
  String get zonaFrancaTitle => 'ZonaFranca';

  @override
  String get zonaFrancaDesc => '商品和物流的注册和可追溯性。目录可用时只读。';

  @override
  String get ttnTitle => 'TTN';

  @override
  String get ttnDesc => 'TokenizaTuNegocio 已发行的工具。发行代币不是手机订单。';

  @override
  String get capitalSection => '资本';

  @override
  String get fideicomisosTitle => '信托';

  @override
  String get fideicomisosDesc => '同一引擎的资本工具。无头寸可显示。';

  @override
  String get fondosTitle => '基金';

  @override
  String get fondosDesc => '同一引擎的资本工具。无头寸可显示。';

  @override
  String get crowdTitle => '众筹';

  @override
  String get crowdDesc => '社区融资。未加载活动。';

  @override
  String get licitacionesTitle => '招标';

  @override
  String get licitacionesDesc => '可验证收据的采购。未加载流程。';

  @override
  String get donacionesTitle => '捐赠';

  @override
  String get donacionesDesc => '可追溯的捐赠。未加载活动。';

  @override
  String get academiaTitle => '学院';

  @override
  String get academiaDesc => 'TokenizaTuNegocio 培训。不移动资金。';

  @override
  String get whatProductPublishes => '产品发布内容';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsLabTitle => '实验室配置';

  @override
  String get walletConnectTitle => 'WalletConnect / Reown';

  @override
  String get walletConnectDescription =>
      '输入您项目的 Project ID。可以在不重新编译的情况下更改。钱包会话仅保留在内存中；重启应用时会重新连接。FluuiX 不要求助记词或私钥。';

  @override
  String get projectIdLabel => 'Project ID';

  @override
  String get projectIdHint => '32 个十六进制字符';

  @override
  String get connecting => '连接中…';

  @override
  String get saveAndConnectReown => '保存并连接 Reown';

  @override
  String get reownClientInitialized => 'Reown 客户端已初始化';

  @override
  String get inferenceTitle => 'OpenHuman 推理';

  @override
  String get inferenceLabTitle => '本地文本服务器';

  @override
  String get inferenceDescription =>
      '选择与 OpenAI 兼容的端点和您的提供商启用的模型。模型使用互联网；Rust 运行时在手机上运行。';

  @override
  String get inferenceLabDescription =>
      '输入字面回环 IP 和您建立到授权服务器的传输的 /v1 路径。选择已在那里安装的模型。没有默认端点或模型。';

  @override
  String get endpointLabel => 'HTTPS 端点';

  @override
  String get endpointLabLabel => '回环端点 /v1';

  @override
  String get endpointHint => 'https://provider.example/v1';

  @override
  String get endpointLabHint => '完成您的授权端点';

  @override
  String get modelLabel => '模型 ID';

  @override
  String get modelHint => '您的提供商启用的模型';

  @override
  String get modelLabHint => '本地安装模型的确切 ID';

  @override
  String get apiKeyLabel => '推理 API 密钥';

  @override
  String get apiKeyLabLabel => '服务器密钥或标记';

  @override
  String get apiKeyLabHelper => '合成标记不保护或验证服务器。';

  @override
  String get rememberKey => '在系统安全存储中记住密钥';

  @override
  String queriesSentTo(String host) {
    return '激活和查询时，您将消息和必要的上下文发送到 $host。';
  }

  @override
  String get labQueriesNote => '查询仅发送到指定的端点。实验室设置与 Arc 模式分开保存。';

  @override
  String get initializing => '初始化中…';

  @override
  String get startLabButton => '启动文本实验室';

  @override
  String get activateOpenHumanButton => '使用此提供商激活 OpenHuman';

  @override
  String get stopAgentForgetKey => '停止代理并忘记密钥';

  @override
  String get addArcTestnetManually => '手动添加 Arc 测试网';

  @override
  String get arcManualInfo => '名称：Arc 测试网\n链 ID：5042002\n原生货币：USDC · 18 位小数';

  @override
  String get arcManualInstructions =>
      '在您的钱包中添加网络，然后重新连接并授权 Arc 测试网。添加网络不会自动扩展现有会话的权限。';

  @override
  String get officialDocs => '官方文档';

  @override
  String get retrySecureStorage => '重试读取安全状态';

  @override
  String get connectYourWallet => '连接您的钱包';

  @override
  String get scanFromOtherScreen =>
      '从另一个屏幕扫描或打开与 WalletConnect 兼容的钱包。批准后返回 FluuiX。';

  @override
  String get walletMustHaveArc => '钱包必须配置 Arc 测试网。连接不发送资金。';

  @override
  String get goBack => '返回';

  @override
  String get copyUri => '复制 URI';

  @override
  String get openWallet => '打开钱包';

  @override
  String get uriCopied => 'URI 已复制。将其粘贴到钱包中的 WalletConnect。';

  @override
  String get useCopyUriOrQr => '使用复制 URI 并粘贴到您的钱包，或扫描 QR。';

  @override
  String get noWalletForLink => '未找到此链接的钱包。使用 QR 或复制 URI。';

  @override
  String get reviewTransferTitle => '审核转账';

  @override
  String get arcTestnetTestFunds => 'Arc 测试网 · 测试资金';

  @override
  String get from => '从';

  @override
  String get recipient => '收款人';

  @override
  String maxFee(String amount) {
    return '最大费用：$amount USDC';
  }

  @override
  String maxTotal(String amount) {
    return '最大总额：$amount USDC';
  }

  @override
  String get reviewExpiry =>
      '审核将在 2 分钟后过期。在您的钱包中验证网络、收款人、金额和费用是否匹配。您的钱包请求最终签名。';

  @override
  String get cancel => '取消';

  @override
  String get requestApproval => '请求批准';

  @override
  String get confirmWalletState => '确认钱包中的状态';

  @override
  String get confirmNoSendMessage =>
      '仅当您验证先前的请求已被拒绝或取消且不存在待处理或已发送的转账时才继续。重复发送可能会重复付款。';

  @override
  String get verifiedNotSent => '已验证未发送';

  @override
  String get proposalValidatedCopied => '提案已验证并复制。签名前请检查收款人、金额和费用。';

  @override
  String get couldNotOpenLink => '无法打开链接。';

  @override
  String get footerArcTestnet =>
      'Arc 测试网 · 测试 USDC\n外部钱包控制您的密钥并请求签名。FluuiX 不要求助记词或私钥。';

  @override
  String get footerLab => 'AW 不会自动切换提供商。确认授权服务器运行本地模型；仅接收文本并不能证明其来源。';

  @override
  String get labBannerTitle => '实验室 · 仅文本';

  @override
  String get labBannerDesc => '钱包、支付、提案和 Arc 查询已禁用。代理没有工具。此模式在编译时固定。';

  @override
  String get ordersViewTooltip => '钱箱视图';

  @override
  String get missionViewTooltip => '每日订单';

  @override
  String get refreshArcTooltip => '刷新 Arc';

  @override
  String get agentStoppedStatus => '代理已停止，本地对话已丢弃';

  @override
  String openHumanLocalActive(String host) {
    return 'OpenHuman 本地活跃 · 在 $host 上推理';
  }

  @override
  String labReadyStatus(String endpoint, String model) {
    return '实验室就绪 · 端点 $endpoint · 请求的模型 $model';
  }

  @override
  String get turnCompletedStatus => 'OpenHuman 已完成回合';

  @override
  String get labResponseReceivedStatus => '已收到响应 · 将 ID 与您的服务器日志进行比较';

  @override
  String rustExecutedStatus(String os, String arch) {
    return 'Rust 在 $os/$arch 上执行 · ABI 1';
  }

  @override
  String get contextBarLayer => '层';

  @override
  String get contextBarDisconnected => '已断开';

  @override
  String get contextBarConnected => '已连接';

  @override
  String get languageSettings => '语言';

  @override
  String get languageAuto => '自动（系统）';

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
