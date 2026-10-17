import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/arc.dart';
import '../domain/inference_config.dart';
import '../domain/treasury_policy.dart';
import '../services/arc_rpc.dart';
import '../services/wallet_session.dart';

/// Manages wallet connection, balance, and transaction state.
class WalletNotifier extends ChangeNotifier {
  WalletNotifier({
    ArcRpc? rpc,
    WalletSession? session,
  })  : _rpc = rpc ?? (awLabTextOnly ? null : ArcRpc()),
        _session = session ?? (awLabTextOnly ? null : WalletSession()) {
    _session?.addListener(_onSessionChanged);
  }

  final ArcRpc? _rpc;
  final WalletSession? _session;

  ArcRpc get rpc =>
      _rpc ?? (throw StateError('Arc is disabled in lab mode.'));
  WalletSession get session =>
      _session ?? (throw StateError('Wallet is disabled in lab mode.'));

  bool _networkVerified = false;
  String _networkStatus = 'connectionPending';
  BigInt? _balance;
  String? _error;
  String? _lastWalletAddress;
  bool _busy = false;
  bool _requestUncertain = false;
  bool _polling = false;
  TransactionResult? _transaction;
  TransferReview? _lastReview;
  TreasuryDayLedger _ledger = TreasuryDayLedger.empty();

  bool get networkVerified => _networkVerified;
  String get networkStatus => _networkStatus;
  BigInt? get balance => _balance;
  String? get error => _error;
  bool get busy => _busy;
  bool get requestUncertain => _requestUncertain;
  TransactionResult? get transaction => _transaction;
  TransferReview? get lastReview => _lastReview;
  TreasuryDayLedger get ledger => _ledger;

  bool get connected => _session?.connected ?? false;
  bool get configured => _session?.configured ?? false;
  bool get supportsArc => _session?.supportsArc ?? false;
  String? get address => _session?.address;
  String? get topic => _session?.topic;
  int? get chainId => _session?.chainId;
  int get revision => _session?.revision ?? 0;
  bool get requestPending => _session?.requestPending ?? false;

  bool get transferBlocked =>
      awLabTextOnly ||
      _requestUncertain ||
      requestPending ||
      (_transaction != null &&
          _transaction!.state != TransactionState.confirmed &&
          _transaction!.state != TransactionState.reverted);

  void _onSessionChanged() {
    final address = _session?.address;
    if (_lastWalletAddress != address) {
      _lastWalletAddress = address;
      _balance = null;
      unawaited(refreshBalance());
    }
    final hash = _session?.lastHash;
    if (hash != null && hash != _transaction?.hash) {
      _transaction = TransactionResult(hash, TransactionState.submitted);
      _requestUncertain = false;
      unawaited(_pollReceipt());
    }
    notifyListeners();
  }

  Future<void> checkNetwork() async {
    if (awLabTextOnly) return;
    try {
      await rpc.verifyNetwork();
      _networkVerified = true;
      _networkStatus = 'rpcVerified';
      notifyListeners();
      await refreshBalance();
    } catch (e) {
      _networkVerified = false;
      _networkStatus = _safeError(e);
      notifyListeners();
    }
  }

  Future<void> refreshBalance() async {
    if (awLabTextOnly) return;
    final address = _session?.address;
    if (address == null) return;
    try {
      await rpc.verifyNetwork();
      final balance = await rpc.nativeBalance(address);
      if (address == _session?.address) {
        _balance = balance;
        _networkVerified = true;
        notifyListeners();
      }
    } catch (e) {
      if (address == _session?.address) {
        _error = _safeError(e);
        notifyListeners();
      }
    }
  }

  Future<void> connect(Future<void> Function(Uri) showPairing) async {
    if (awLabTextOnly) return;
    if (!configured) return;
    if (_busy) return;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await session.connect(showPairing);
      if (!supportsArc) {
        _error = 'sessionNotAuthorizedArc';
      }
      await refreshBalance();
    } catch (e) {
      _error = _safeError(e);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    if (awLabTextOnly) return;
    try {
      await session.disconnect();
    } catch (e) {
      _error = _safeError(e);
      notifyListeners();
    }
  }

  Future<void> requestArcNetwork() async {
    if (awLabTextOnly) return;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await session.requestArcNetwork();
      _error = 'networkRequestedReconnect';
    } catch (e) {
      _error = _safeError(e);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<TransferReview?> prepareTransfer({
    required String recipient,
    required BigInt units,
  }) async {
    if (awLabTextOnly || _busy || transferBlocked) return null;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      TreasuryPolicy.assertOrderAllowed(
        units: units,
        spentToday: _ledger.forToday().spent,
      );
      final sender = address;
      final currentTopic = topic;
      if (sender == null || currentTopic == null || !supportsArc) {
        throw StateError('Connect a wallet that authorizes Arc Testnet.');
      }
      final review = await rpc.prepare(
        sender: sender,
        recipient: validateAddress(recipient, recipient: true),
        units: units,
        topic: currentTopic,
        sessionRevision: revision,
      );
      session.verifyReview(review);
      return review;
    } catch (e) {
      _error = _safeError(e);
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> executeTransfer(TransferReview review) async {
    if (awLabTextOnly || _busy) return;
    _busy = true;
    _error = null;
    notifyListeners();
    var requested = false;
    try {
      await rpc.verifyNetwork();
      await rpc.verifyFunds(review);
      session.verifyReview(review);
      _lastReview = review;
      _transaction = null;
      _requestUncertain = true;
      requested = true;
      final hash = await session.send(review);
      _transaction = TransactionResult(hash, TransactionState.submitted);
      _requestUncertain = false;
      await _pollReceipt();
    } catch (e) {
      if (!requested) _requestUncertain = false;
      _error = requested
          ? '${_safeError(e)}\nCheck status in your wallet.'
          : _safeError(e);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _pollReceipt() async {
    if (awLabTextOnly || _polling || _transaction == null) return;
    _polling = true;
    final hash = _transaction!.hash;
    try {
      final deadline = DateTime.now().add(const Duration(seconds: 60));
      while (_transaction?.hash == hash && DateTime.now().isBefore(deadline)) {
        await checkReceipt();
        final state = _transaction?.state;
        if (state == TransactionState.confirmed ||
            state == TransactionState.reverted ||
            state == TransactionState.unknown) {
          break;
        }
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    } finally {
      _polling = false;
    }
  }

  Future<void> checkReceipt() async {
    if (awLabTextOnly) return;
    final current = _transaction;
    if (current == null) return;
    try {
      await rpc.verifyNetwork();
      final result = await rpc.receipt(current.hash, review: _lastReview);
      if (_transaction?.hash != current.hash) return;
      _transaction = result;
      if (_lastReview != null &&
          (result.state == TransactionState.confirmed ||
              result.state == TransactionState.reverted)) {
        _requestUncertain = false;
      }
      if (result.state == TransactionState.confirmed && _lastReview != null) {
        _ledger = _ledger.recordConfirmed(
          hash: result.hash,
          units: _lastReview!.units,
        );
      }
      if (result.state == TransactionState.confirmed ||
          result.state == TransactionState.reverted) {
        await refreshBalance();
      }
      notifyListeners();
    } catch (e) {
      if (_transaction?.hash == current.hash) {
        _transaction = TransactionResult(
          current.hash,
          TransactionState.unknown,
        );
        _error = _safeError(e);
        notifyListeners();
      }
    }
  }

  Future<void> recoverTransaction(String hash) async {
    if (awLabTextOnly) return;
    try {
      final validHash = validateTransactionHash(hash.trim());
      _transaction = TransactionResult(validHash, TransactionState.pending);
      _error = null;
      notifyListeners();
      await checkReceipt();
    } catch (e) {
      _error = _safeError(e);
      notifyListeners();
    }
  }

  void acknowledgeNoSend() {
    if (awLabTextOnly) return;
    if (requestPending) return;
    _requestUncertain = false;
    _error = null;
    _lastReview = null;
    _transaction = null;
    notifyListeners();
  }

  void setLedger(TreasuryDayLedger ledger) {
    _ledger = ledger;
    notifyListeners();
  }

  void setRequestUncertain(bool value) {
    _requestUncertain = value;
    notifyListeners();
  }

  void setLastReview(TransferReview? review) {
    _lastReview = review;
  }

  void setTransaction(TransactionResult? tx) {
    _transaction = tx;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reconcile() {
    if (awLabTextOnly) return;
    _session?.reconcile();
  }

  String _safeError(Object error) {
    var text = error.toString();
    text = text.replaceAll(
      RegExp(r'Bearer\s+\S+', caseSensitive: false),
      'Bearer [redacted]',
    );
    return text.length > 600 ? '${text.substring(0, 600)}…' : text;
  }

  @override
  void dispose() {
    _session?.removeListener(_onSessionChanged);
    _session?.dispose();
    _rpc?.close();
    super.dispose();
  }
}
