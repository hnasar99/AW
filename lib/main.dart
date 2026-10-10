import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'openhuman_bridge.dart';

const arcChainId = 5042002;
const arcRpc = 'https://rpc.testnet.arc.network';
const arcExplorer = 'https://testnet.arcscan.app';
const usdcAddress = '0x3600000000000000000000000000000000000000';
const walletConnectProjectId = String.fromEnvironment('WALLETCONNECT_PROJECT_ID');

void main() => runApp(const ArcWalletApp());

class ArcRpc {
  int _id = 0;

  Future<dynamic> call(String method, List<dynamic> params) async {
    final response = await http.post(
      Uri.parse(arcRpc),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': ++_id,
        'method': method,
        'params': params,
      }),
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Arc RPC HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (decoded['error'] != null) {
      throw Exception(decoded['error']['message'] ?? 'Arc RPC error');
    }
    return decoded['result'];
  }

  Future<int> chainId() async =>
      int.parse((await call('eth_chainId', const [])) as String);

  Future<BigInt> nativeBalance(String address) async =>
      BigInt.parse((await call('eth_getBalance', [address, 'latest'])) as String);

  Future<BigInt> usdcBalance(String address) async {
    final clean = address.toLowerCase().replaceFirst('0x', '');
    final data = '0x70a08231${clean.padLeft(64, '0')}';
    final result = await call('eth_call', [
      {'to': usdcAddress, 'data': data},
      'latest',
    ]) as String;
    return BigInt.parse(result.replaceFirst('0x', '').isEmpty ? '0' : result.replaceFirst('0x', ''), radix: 16);
  }

  Future<String> estimateGas(Map<String, String> tx) async =>
      await call('eth_estimateGas', [tx]) as String;
}

String formatUnits(BigInt value, int decimals, {int places = 4}) {
  final base = BigInt.from(10).pow(decimals);
  final whole = value ~/ base;
  final fraction = (value % base).toString().padLeft(decimals, '0');
  final shown = fraction.substring(0, places.clamp(0, decimals).toInt()).replaceFirst(RegExp(r'0+$'), '');
  return shown.isEmpty ? whole.toString() : '$whole.$shown';
}

String shorten(String value) =>
    value.length < 14 ? value : '${value.substring(0, 7)}…${value.substring(value.length - 5)}';

class ArcWalletApp extends StatelessWidget {
  const ArcWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arc Wallet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff6d5dfc), brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xff0d0d13),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xff191923),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ),
      home: const WalletHome(),
    );
  }
}

class WalletHome extends StatefulWidget {
  const WalletHome({super.key});

  @override
  State<WalletHome> createState() => _WalletHomeState();
}

class _WalletHomeState extends State<WalletHome> {
  final ArcRpc _rpc = ArcRpc();
  final OpenHumanBridge _agentBridge = OpenHumanBridge();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final _agentEndpoint = TextEditingController(text: 'https://api.openai.com/v1');
  final _agentModel = TextEditingController(text: 'gpt-4o-mini');
  final _agentKey = TextEditingController();
  final _agentPrompt = TextEditingController(text: 'Help me prepare a 1 USDC transfer on Arc Testnet. Ask me for any missing details; do not send anything.');
  final _recipient = TextEditingController();
  final _amount = TextEditingController(text: '1');
  Web3App? _wc;
  SessionData? _session;
  String? _address;
  String _networkStatus = 'Checking Arc Testnet…';
  String? _lastTx;
  String? _error;
  String? _pairingUri;
  BigInt? _usdc;
  BigInt? _native;
  BigInt? _estimatedGas;
  bool _busy = false;
  bool _agentBusy = false;
  bool _agentReady = false;
  String _agentStatus = 'OpenHuman is not initialized';
  String? _agentReply;
  String? _agentSessionId;
  String? _agentError;

  @override
  void initState() {
    super.initState();
    _checkNetwork();
    _initWalletConnect();
    _loadAgentKey();
  }

  @override
  void dispose() {
    _recipient.dispose();
    _amount.dispose();
    _agentEndpoint.dispose();
    _agentModel.dispose();
    _agentKey.dispose();
    _agentPrompt.dispose();
    super.dispose();
  }

  Future<void> _checkNetwork() async {
    try {
      final id = await _rpc.chainId();
      if (!mounted) return;
      setState(() => _networkStatus = id == arcChainId
          ? 'Arc Testnet connected'
          : 'Unexpected chain ID: $id');
      if (_address != null) await _refreshBalances();
    } catch (e) {
      if (mounted) setState(() => _networkStatus = 'Arc RPC unavailable: $e');
    }
  }

  Future<void> _initWalletConnect() async {
    if (walletConnectProjectId.isEmpty) return;
    try {
      final app = await Web3App.createInstance(
        projectId: walletConnectProjectId,
        metadata: const PairingMetadata(
          name: 'Arc Wallet',
          description: 'A user-controlled wallet experience for Arc Testnet',
          url: 'https://testnet.arcscan.app',
          icons: ['https://avatars.githubusercontent.com/u/0?v=4'],
        ),
      );
      if (mounted) setState(() => _wc = app);
    } catch (e) {
      if (mounted) setState(() => _error = 'WalletConnect initialization failed: $e');
    }
  }

  Future<void> _connectWallet() async {
    if (_wc == null) {
      setState(() => _error = 'Configure WALLETCONNECT_PROJECT_ID at build time first.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final response = await _wc!.connect(
        requiredNamespaces: {
          'eip155': RequiredNamespace(
            chains: const ['eip155:5042002'],
            methods: const ['eth_sendTransaction', 'personal_sign'],
            events: const ['accountsChanged', 'chainChanged'],
          ),
        },
      );
      final uri = response.uri;
      if (uri != null && mounted) {
        setState(() => _pairingUri = uri.toString());
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Connect your wallet'),
            content: SelectableText(uri.toString()),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
              FilledButton(
                onPressed: () async {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Open wallet'),
              ),
            ],
          ),
        );
      }
      final session = await response.session.future;
      if (session == null) throw Exception('WalletConnect session was not approved.');
      final accounts = session.namespaces['eip155']?.accounts ?? [];
      final matching = accounts.where((a) => a.startsWith('eip155:$arcChainId:')).toList();
      if (matching.isEmpty) throw Exception('Wallet did not approve Arc Testnet (chain $arcChainId).');
      final address = matching.first.split(':').last;
      if (!mounted) return;
      setState(() {
        _session = session;
        _address = address;
        _pairingUri = null;
      });
      await _refreshBalances();
    } catch (e) {
      if (mounted) setState(() => _error = 'Connection failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadAgentKey() async {
    try {
      final key = await _secureStorage.read(key: 'openhuman_inference_api_key');
      if (mounted && key != null) setState(() => _agentKey.text = key);
    } catch (_) {
      if (mounted) setState(() => _agentError = 'Secure storage is unavailable on this device.');
    }
  }

  Future<void> _startAgent() async {
    final endpoint = _agentEndpoint.text.trim();
    final model = _agentModel.text.trim();
    final key = _agentKey.text.trim();
    if (endpoint.isEmpty || model.isEmpty || key.isEmpty) {
      setState(() => _agentError = 'Enter an OpenAI-compatible HTTPS endpoint, model, and API key.');
      return;
    }
    setState(() { _agentBusy = true; _agentError = null; _agentStatus = 'Starting embedded OpenHuman runtime…'; });
    try {
      await _secureStorage.write(key: 'openhuman_inference_api_key', value: key);
      final support = await getApplicationSupportDirectory();
      final workspace = Directory('${support.path}/openhuman_arc_wallet');
      await workspace.create(recursive: true);
      await _agentBridge.initialize(
        endpoint: endpoint,
        apiKey: key,
        model: model,
        workspace: workspace.path,
      );
      if (!mounted) return;
      setState(() { _agentReady = true; _agentStatus = 'Embedded OpenHuman ready · read-only'; _agentError = null; });
    } catch (e) {
      if (mounted) setState(() {
        _agentReady = false;
        _agentStatus = 'Runtime unavailable';
        _agentError = 'Could not start OpenHuman: $e. Check that the native Rust library is built and packaged for this platform.';
      });
    } finally {
      if (mounted) setState(() => _agentBusy = false);
    }
  }

  Future<void> _askAgent() async {
    if (!_agentReady) {
      setState(() => _agentError = 'Initialize OpenHuman first.');
      return;
    }
    if (_agentPrompt.text.trim().isEmpty) return;
    setState(() { _agentBusy = true; _agentError = null; });
    try {
      final result = await _agentBridge.sendTurn(
        prompt: _agentPrompt.text.trim(),
        sessionId: _agentSessionId ?? '',
      );
      if (!mounted) return;
      setState(() {
        _agentReply = result['reply'] as String? ?? '(empty reply)';
        _agentSessionId = result['session_id'] as String?;
        _agentStatus = 'OpenHuman turn completed';
      });
    } catch (e) {
      if (mounted) setState(() => _agentError = 'Agent turn failed: $e');
    } finally {
      if (mounted) setState(() => _agentBusy = false);
    }
  }

  void _applyAgentProposal() {
    final reply = _agentReply;
    if (reply == null) return;
    try {
      final clean = reply.replaceAll('```json', '').replaceAll('```', '').trim();
      final parsed = jsonDecode(clean) as Map<String, dynamic>;
      if (parsed['intent'] != 'transfer_usdc') throw const FormatException('No transfer proposal found.');
      final recipient = (parsed['recipient'] as String? ?? '').trim();
      final amount = (parsed['amount'] as String? ?? '').trim();
      if (!RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(recipient)) throw const FormatException('Proposal recipient is not a valid EVM address.');
      final value = double.tryParse(amount);
      if (value == null || value <= 0 || !value.isFinite) throw const FormatException('Proposal amount is invalid.');
      setState(() { _recipient.text = recipient; _amount.text = amount; _agentError = null; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proposal copied into the transaction form. Review and sign separately.')));
    } catch (e) {
      setState(() => _agentError = 'Cannot use this reply as a transfer proposal: $e');
    }
  }

  bool get _hasTransferProposal {
    final reply = _agentReply;
    if (reply == null) return false;
    try {
      final clean = reply.replaceAll('```json', '').replaceAll('```', '').trim();
      final parsed = jsonDecode(clean) as Map<String, dynamic>;
      return parsed['intent'] == 'transfer_usdc' &&
          RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch((parsed['recipient'] as String? ?? '').trim()) &&
          (double.tryParse((parsed['amount'] as String? ?? '').trim()) ?? 0) > 0;
    } catch (_) { return false; }
  }

  Future<void> _refreshBalances() async {
    final address = _address;
    if (address == null) return;
    try {
      final values = await Future.wait([
        _rpc.usdcBalance(address),
        _rpc.nativeBalance(address),
      ]);
      if (mounted) setState(() {
        _usdc = values[0];
        _native = values[1];
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not load balances: $e');
    }
  }

  String _encodeTransfer(String recipient, BigInt amount) {
    final address = recipient.toLowerCase().replaceFirst('0x', '');
    return '0xa9059cbb${address.padLeft(64, '0')}${amount.toRadixString(16).padLeft(64, '0')}';
  }

  Future<void> _reviewAndSend() async {
    final from = _address;
    final to = _recipient.text.trim();
    final amount = double.tryParse(_amount.text.trim());
    if (from == null || _session == null) {
      setState(() => _error = 'Connect a wallet before sending.');
      return;
    }
    if (!RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(to)) {
      setState(() => _error = 'Recipient must be a valid EVM address.');
      return;
    }
    if (amount == null || amount <= 0 || !amount.isFinite) {
      setState(() => _error = 'Enter an amount greater than zero.');
      return;
    }
    final units = BigInt.from((amount * 1000000).round());
    if (_usdc != null && units > _usdc!) {
      setState(() => _error = 'Insufficient USDC balance.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Review transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Network: Arc Testnet ($arcChainId)'),
            const SizedBox(height: 8),
            Text('Asset: USDC'),
            Text('Amount: ${amount.toStringAsFixed(6)} USDC'),
            Text('To: $to'),
            const SizedBox(height: 8),
            const Text('Your wallet will show the final transaction and request signature.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue to wallet')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() { _busy = true; _error = null; _estimatedGas = null; });
    try {
      final tx = <String, String>{
        'from': from,
        'to': usdcAddress,
        'data': _encodeTransfer(to, units),
        'value': '0x0',
      };
      final gas = await _rpc.estimateGas(tx);
      if (mounted) setState(() => _estimatedGas = BigInt.parse(gas));
      final result = await _wc!.request(
        topic: _session!.topic,
        chainId: 'eip155:$arcChainId',
        request: SessionRequestParams(
          method: 'eth_sendTransaction',
          params: [tx],
        ),
      );
      final hash = result.toString();
      if (!RegExp(r'^0x[a-fA-F0-9]{64}$').hasMatch(hash)) {
        throw Exception('Wallet returned an unexpected transaction hash: $hash');
      }
      if (mounted) setState(() => _lastTx = hash);
      await _waitForReceipt(hash);
      await _refreshBalances();
    } catch (e) {
      if (mounted) setState(() => _error = 'Transaction failed or was rejected: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _waitForReceipt(String hash) async {
    for (var i = 0; i < 30; i++) {
      await Future<void>.delayed(const Duration(seconds: 2));
      final receipt = await _rpc.call('eth_getTransactionReceipt', [hash]);
      if (receipt != null) {
        final status = (receipt as Map<String, dynamic>)['status'] as String?;
        if (status != null && int.parse(status.startsWith('0x') ? status.substring(2) : status, radix: status.startsWith('0x') ? 16 : 10) == 0) {
          throw Exception('Transaction reverted. See ArcScan for details.');
        }
        return;
      }
    }
    if (mounted) setState(() => _error = 'Transaction submitted; receipt is still pending. Check ArcScan.');
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final address = _address;
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.account_balance_wallet_rounded, color: Color(0xff9b8cff)),
          SizedBox(width: 10),
          Text('Arc Wallet', style: TextStyle(fontWeight: FontWeight.w700)),
        ]),
        actions: [
          IconButton(onPressed: _busy ? null : _checkNetwork, icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _networkCard(),
                const SizedBox(height: 16),
                _balanceCard(address),
                const SizedBox(height: 20),
                _openHumanCard(),
                const SizedBox(height: 20),
                Text('Send USDC', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: _recipient,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: 'Recipient address', hintText: '0x…', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount', suffixText: 'USDC', prefixIcon: Icon(Icons.payments_outlined)),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : (address == null ? _connectWallet : _reviewAndSend),
                    icon: _busy
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(address == null ? Icons.link : Icons.send_rounded),
                    label: Text(_busy ? 'Working…' : address == null ? 'Connect wallet' : 'Review and send'),
                  ),
                ),
                if (address != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _refreshBalances,
                    icon: const Icon(Icons.sync),
                    label: const Text('Refresh balances'),
                  ),
                ],
                if (_estimatedGas != null) ...[
                  const SizedBox(height: 12),
                  _infoTile('Estimated gas', _estimatedGas.toString()),
                ],
                if (_lastTx != null) ...[
                  const SizedBox(height: 16),
                  _infoTile('Transaction submitted', shorten(_lastTx!)),
                  OutlinedButton.icon(
                    onPressed: () => _openUrl('$arcExplorer/tx/$_lastTx'),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('View transaction on ArcScan'),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: const Color(0xff3a2028), borderRadius: BorderRadius.circular(14)),
                    child: Text(_error!, style: const TextStyle(color: Color(0xffffc3cc))),
                  ),
                ],
                const SizedBox(height: 24),
                const Text(
                  'Testnet MVP • The wallet controls the private key and signs transactions. This app never asks for or stores a seed phrase.',
                  style: TextStyle(color: Colors.white54, height: 1.5),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _openUrl('https://faucet.circle.com/'),
                  child: const Text('Get testnet USDC from Circle Faucet ↗'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _openHumanCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xff191923),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xff47406e)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.psychology_alt_outlined, color: Color(0xffb9adff), size: 26),
        const SizedBox(width: 10),
        const Expanded(child: Text('OpenHuman Agent', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        Container(width: 8, height: 8, decoration: BoxDecoration(
          shape: BoxShape.circle, color: _agentReady ? const Color(0xff55d6a2) : Colors.orangeAccent)),
      ]),
      const SizedBox(height: 6),
      Text(_agentStatus, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      const SizedBox(height: 12),
      TextField(controller: _agentEndpoint, autocorrect: false,
        enabled: !_agentReady && !_agentBusy,
        decoration: const InputDecoration(labelText: 'OpenAI-compatible endpoint', hintText: 'https://provider.example/v1')),
      const SizedBox(height: 10),
      TextField(controller: _agentModel, autocorrect: false,
        enabled: !_agentReady && !_agentBusy,
        decoration: const InputDecoration(labelText: 'Model ID', hintText: 'gpt-4o-mini')),
      const SizedBox(height: 10),
      TextField(controller: _agentKey, obscureText: true, autocorrect: false,
        enabled: !_agentReady && !_agentBusy,
        decoration: const InputDecoration(labelText: 'Inference API key', helperText: 'Stored in OS secure storage; never shown in logs.')),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(
        onPressed: _agentBusy || _agentReady ? null : _startAgent,
        icon: const Icon(Icons.memory), label: Text(_agentBusy ? 'Starting…' : 'Initialize Rust runtime'),
      )),
      const Divider(height: 28, color: Colors.white12),
      TextField(controller: _agentPrompt, minLines: 2, maxLines: 4,
        enabled: _agentReady && !_agentBusy,
        decoration: const InputDecoration(labelText: 'Ask your wallet agent', hintText: 'Prepare a USDC transfer…')),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity, child: FilledButton.icon(
        onPressed: _agentReady && !_agentBusy ? _askAgent : null,
        icon: _agentBusy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome),
        label: Text(_agentBusy ? 'Agent working…' : 'Ask OpenHuman'),
      )),
      if (_agentReply != null) ...[
        const SizedBox(height: 12),
        Container(width: double.infinity, padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xff101018), borderRadius: BorderRadius.circular(12)),
          child: SelectableText(_agentReply!, style: const TextStyle(height: 1.45))),
        if (_hasTransferProposal) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: _applyAgentProposal,
            icon: const Icon(Icons.assignment_return_outlined),
            label: const Text('Copy proposal into USDC form')),
        ],
      ],
      if (_agentError != null) ...[
        const SizedBox(height: 10),
        Text(_agentError!, style: const TextStyle(color: Color(0xffffc3cc), fontSize: 12)),
      ],
      const SizedBox(height: 8),
      const Text('The agent can draft a proposal only. It cannot access wallet keys or sign; every transfer still requires your separate review and wallet approval.',
        style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4)),
    ]),
  );

  Widget _networkCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xff28224d), Color(0xff191923)]),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xff47406e)),
    ),
    child: Row(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: const Color(0xff6d5dfc).withOpacity(.2), borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.hub_outlined, color: Color(0xffb9adff)),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('ARC TESTNET', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        const SizedBox(height: 4),
        Text(_networkStatus, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        const Text('Chain ID 5042002 • USDC gas', style: TextStyle(color: Colors.white54, fontSize: 12)),
      ])),
      const Icon(Icons.circle, color: Color(0xff55d6a2), size: 10),
    ]),
  );

  Widget _balanceCard(String? address) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: const Color(0xff191923), borderRadius: BorderRadius.circular(18)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Text('Wallet balance', style: TextStyle(color: Colors.white70))),
        if (address != null)
          IconButton(
            onPressed: () => _openUrl('$arcExplorer/address/$address'),
            icon: const Icon(Icons.open_in_new, size: 18),
            tooltip: 'View address',
          ),
      ]),
      Text(_usdc == null ? '—' : formatUnits(_usdc!, 6, places: 4),
        style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1)),
      const Text('USDC', style: TextStyle(color: Color(0xffb9adff), fontWeight: FontWeight.w600)),
      const SizedBox(height: 14),
      const Divider(color: Colors.white12),
      Row(children: [
        const Icon(Icons.account_circle_outlined, size: 18, color: Colors.white54),
        const SizedBox(width: 8),
        Expanded(child: Text(address == null ? 'No wallet connected' : shorten(address), style: const TextStyle(color: Colors.white70))),
        if (address != null)
          IconButton(
            onPressed: () => setState(() { _address = null; _session = null; _usdc = null; _native = null; }),
            icon: const Icon(Icons.logout, size: 18),
            tooltip: 'Disconnect locally',
          ),
      ]),
      if (_native != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('Native gas balance: ${formatUnits(_native!, 18, places: 8)} USDC units',
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ),
    ]),
  );

  Widget _infoTile(String title, String value) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xff191923), borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      Expanded(child: Text(title, style: const TextStyle(color: Colors.white70))),
      Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600))),
    ]),
  );
}
