import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:reown_core/reown_core.dart';
import 'package:reown_sign/reown_sign.dart';

import '../domain/arc.dart';

/// All session capabilities are rechecked before a signature request is sent.
class WalletSession extends ChangeNotifier {
  ReownSignClient? _client;
  SessionData? _session;
  String? _address;
  int? _chainId;
  int _revision = 0;
  bool _closed = false;
  Future<String>? _pendingRequest;
  String? _lastHash;

  bool get configured => _client != null;
  bool get connected => _session != null;
  bool get requestPending => _pendingRequest != null;
  String? get lastHash => _lastHash;
  String? get address => _address;
  String? get topic => _session?.topic;
  int? get chainId => _chainId;
  int get revision => _revision;
  bool get supportsArc =>
      _session != null &&
      _address != null &&
      _chainId == ArcNetwork.chainId &&
      _permitted(_session!, ArcNetwork.caip2, 'eth_sendTransaction', _address!);

  Future<void> configure(String projectId) async {
    if (!RegExp(r'^[a-fA-F0-9]{32}$').hasMatch(projectId.trim())) {
      throw const FormatException(
        'Enter the 32-character Reown / WalletConnect Project ID.',
      );
    }
    if (_pendingRequest != null) {
      throw StateError('A wallet request is still unresolved.');
    }
    await _releaseClient();
    final client = await ReownSignClient.createInstance(
      projectId: projectId.trim(),
      // Session encryption material stays in RAM; reconnect after process exit.
      memoryStore: true,
      logLevel: LogLevel.nothing,
      metadata: const PairingMetadata(
        name: 'FluuiX',
        description: 'Caja USDC en Arc Testnet. La wallet externa firma.',
        url: 'https://github.com/hnasar99/AW',
        icons: [],
        redirect: Redirect(native: 'awallet://callback'),
      ),
    ).timeout(const Duration(seconds: 30));
    if (_closed) {
      client.core.heartbeat.stop();
      await client.core.relayClient.disconnect();
      return;
    }
    _client = client;
    client.onSessionUpdate.subscribe(_onUpdate);
    client.onSessionEvent.subscribe(_onEvent);
    client.onSessionDelete.subscribe(_onDelete);
    client.onSessionExpire.subscribe(_onExpire);
    _notify();
  }

  Future<void> connect(Future<void> Function(Uri) showPairing) async {
    final client = _client;
    if (client == null) {
      throw StateError('Save a WalletConnect Project ID first.');
    }
    if (_pendingRequest != null) {
      throw StateError('A wallet request is still unresolved.');
    }
    final response = await client.connect(
      optionalNamespaces: {
        'eip155': const RequiredNamespace(
          chains: [ArcNetwork.caip2, 'eip155:1'],
          methods: ['eth_sendTransaction', 'wallet_addEthereumChain'],
          events: ['accountsChanged', 'chainChanged'],
        ),
      },
    );
    // Attach the future before opening an external wallet to handle rejection.
    final approval = response.session.future;
    unawaited(
      approval.then<void>((_) {}, onError: (Object _, StackTrace __) {}),
    );
    if (response.uri != null) await showPairing(response.uri!);
    final session = await approval.timeout(const Duration(minutes: 3));
    if (_closed || client != _client) return;
    _selectSession(session);
    _notify();
  }

  void _selectSession(SessionData session) {
    if (session.expiry <= DateTime.now().millisecondsSinceEpoch ~/ 1000) {
      throw StateError('The wallet session has expired. Reconnect.');
    }
    final accounts = session.namespaces.values
        .expand((ns) => ns.accounts)
        .toSet();
    final arc = accounts.where((a) => a.startsWith('${ArcNetwork.caip2}:'));
    final fallback = accounts.where((a) => a.startsWith('eip155:1:'));
    final account = arc.isNotEmpty
        ? arc.first
        : (fallback.isNotEmpty ? fallback.first : null);
    if (account == null) {
      throw StateError('The wallet did not approve an EVM account.');
    }
    final parts = account.split(':');
    if (parts.length != 3) {
      throw const FormatException('Invalid wallet account.');
    }
    _address = validateAddress(parts[2]);
    _chainId = int.parse(parts[1]);
    _session = session;
    _revision++;
  }

  bool _permitted(
    SessionData session,
    String chain,
    String method,
    String address,
  ) {
    final account = '$chain:${address.toLowerCase()}';
    return session.expiry > DateTime.now().millisecondsSinceEpoch ~/ 1000 &&
        session.namespaces.entries.any(
          (entry) =>
              (entry.key == 'eip155' || entry.key == chain) &&
              entry.value.methods.contains(method) &&
              entry.value.accounts.any((a) => a.toLowerCase() == account),
        );
  }

  /// Adding a network is a separate permission from allowing that chain in WC.
  Future<void> requestArcNetwork() async {
    final client = _client;
    final session = _session;
    final address = _address;
    final chain = 'eip155:$_chainId';
    if (client == null ||
        session == null ||
        address == null ||
        !_permitted(session, chain, 'wallet_addEthereumChain', address)) {
      throw StateError(
        'Add Arc Testnet manually in the wallet, then reconnect and approve chain 5042002.',
      );
    }
    await client
        .request(
          topic: session.topic,
          chainId: chain,
          request: SessionRequestParams(
            method: 'wallet_addEthereumChain',
            params: [
              {
                'chainId': hexQuantity(BigInt.from(ArcNetwork.chainId)),
                'chainName': ArcNetwork.name,
                'nativeCurrency': {
                  'name': 'USDC',
                  'symbol': 'USDC',
                  'decimals': 18,
                },
                'rpcUrls': [ArcNetwork.rpc],
                'blockExplorerUrls': [ArcNetwork.explorer],
              },
            ],
          ),
        )
        .timeout(const Duration(minutes: 2));
    _revision++;
    _notify();
  }

  /// The underlying request remains tracked after a UI timeout. No auto-resend.
  Future<String> send(TransferReview review) async {
    if (_pendingRequest != null) {
      throw StateError('Another wallet request is unresolved.');
    }
    final client = _client;
    if (client == null) throw StateError('Reconnect the wallet.');
    verifyReview(review);
    final pending = client
        .request(
          topic: review.topic,
          chainId: ArcNetwork.caip2,
          request: SessionRequestParams(
            method: 'eth_sendTransaction',
            params: [review.transaction],
          ),
        )
        .then(validateTransactionHash);
    _pendingRequest = pending;
    _lastHash = null;
    _notify();
    // Keep a listener alive even if the visible wait times out or app resumes.
    unawaited(
      pending.then<void>(
        (hash) {
          _lastHash = hash;
          _pendingRequest = null;
          _notify();
        },
        onError: (Object _, StackTrace __) {
          _pendingRequest = null;
          _notify();
        },
      ),
    );
    return pending.timeout(
      const Duration(minutes: 2),
      onTimeout: () {
        throw TimeoutException(
          'Wallet response is unknown. Check the wallet before doing anything else; '
          'this app keeps waiting and will not resend the transfer.',
        );
      },
    );
  }

  void verifyReview(TransferReview review) {
    reconcile();
    review.verifyConsent(
      currentSender: _address,
      currentTopic: topic,
      currentRevision: _revision,
      now: DateTime.now(),
    );
    if (!supportsArc) {
      throw StateError(
        'The wallet has not approved Arc Testnet for this account.',
      );
    }
  }

  void reconcile() {
    final session = _session;
    if (session == null) return;
    final current = _client?.sessions.get(session.topic);
    if (current == null ||
        current.expiry <= DateTime.now().millisecondsSinceEpoch ~/ 1000) {
      _clearSession();
      return;
    }
    // Freezed equality compares namespaces and methods structurally. Missed
    // events after a background transition cannot leave old grants active.
    if (current != session) {
      _session = current;
      _revision++;
      final address = _address;
      if (address == null ||
          !_permitted(
            current,
            'eip155:$_chainId',
            'eth_sendTransaction',
            address,
          )) {
        _clearSession();
      } else {
        _notify();
      }
    }
  }

  void _onUpdate(SessionUpdate? event) {
    if (event == null || event.topic != topic) return;
    try {
      final session = _client?.sessions.get(event.topic);
      if (session == null) {
        _clearSession();
        return;
      }
      _selectSession(session);
    } catch (_) {
      _clearSession();
    }
    _notify();
  }

  void _onEvent(SessionEvent? event) {
    if (event == null || event.topic != topic) return;
    _revision++;
    if (event.name == 'chainChanged') {
      final data = event.data;
      _chainId = data is int
          ? data
          : (data is String ? int.tryParse(data) : null);
    } else if (event.name == 'accountsChanged') {
      final data = event.data;
      final session = _session;
      if (data is! List ||
          data.isEmpty ||
          data.first is! String ||
          session == null) {
        _clearSession();
        return;
      }
      try {
        final address = validateAddress(data.first as String);
        if (!_permitted(
          session,
          'eip155:$_chainId',
          'eth_sendTransaction',
          address,
        )) {
          _clearSession();
          return;
        }
        _address = address;
      } catch (_) {
        _clearSession();
        return;
      }
    }
    _notify();
  }

  void _onDelete(SessionDelete? event) {
    if (event?.topic == topic) _clearSession();
  }

  void _onExpire(SessionExpire? event) {
    if (event?.topic == topic) _clearSession();
  }

  void _clearSession() {
    _session = null;
    _address = null;
    _chainId = null;
    _revision++;
    _notify();
  }

  Future<void> disconnect() async {
    final session = _session;
    _clearSession();
    if (session != null) {
      await _client?.disconnect(
        topic: session.topic,
        reason: const ReownSignError(code: 6000, message: 'User disconnected.'),
      );
    }
  }

  void _notify() {
    if (!_closed) notifyListeners();
  }

  Future<void> _releaseClient() async {
    final client = _client;
    if (client == null) return;
    await disconnect();
    client.onSessionUpdate.unsubscribe(_onUpdate);
    client.onSessionEvent.unsubscribe(_onEvent);
    client.onSessionDelete.unsubscribe(_onDelete);
    client.onSessionExpire.unsubscribe(_onExpire);
    client.core.heartbeat.stop();
    await client.core.relayClient.disconnect();
    _client = null;
  }

  @override
  void dispose() {
    _closed = true;
    unawaited(_releaseClient().catchError((Object _) {}));
    super.dispose();
  }
}
