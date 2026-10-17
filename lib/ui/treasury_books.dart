part of '../main.dart';

const _zfSessionKey = 'zf_session_v1';

extension _TreasuryBooks on _WalletHomeState {
  bool get _zfPreview => widget.zonafrancaPreview != null;

  String? _booksKey(TreasuryScreen screen) => switch (screen) {
    TreasuryScreen.boxLocal => 'balances',
    TreasuryScreen.boxReserve => 'vault',
    TreasuryScreen.boxTrust => 'trusts',
    TreasuryScreen.boxFund => 'funds',
    TreasuryScreen.boxTender => 'tenders',
    TreasuryScreen.boxDonation => 'donations',
    TreasuryScreen.boxCrowd => 'campaigns',
    TreasuryScreen.collections => 'incoming',
    TreasuryScreen.payments => 'history',
    TreasuryScreen.international => 'crossBorder',
    TreasuryScreen.reconcile => 'history',
    TreasuryScreen.caps => 'caps',
    TreasuryScreen.quotes => 'funds',
    TreasuryScreen.tokenInventory || TreasuryScreen.tokenZone => 'zone',
    TreasuryScreen.tokenShares => 'shares',
    TreasuryScreen.tokenEscrow => 'escrow',
    TreasuryScreen.tokenContracts => 'contracts',
    TreasuryScreen.tokenDocuments => 'documents',
    TreasuryScreen.tokenProperty => 'property',
    TreasuryScreen.tokenTtn => 'instruments',
    TreasuryScreen.dashboard => 'position',
    TreasuryScreen.alerts => 'incoming',
    _ => null,
  };

  bool _apiBox(TreasuryScreen screen) => switch (screen) {
    TreasuryScreen.boxLocal ||
    TreasuryScreen.boxReserve ||
    TreasuryScreen.boxTrust ||
    TreasuryScreen.boxFund ||
    TreasuryScreen.boxTender ||
    TreasuryScreen.boxDonation ||
    TreasuryScreen.boxCrowd => true,
    _ => false,
  };

  Future<void> _restoreZonafranca() async {
    if (_zfPreview || awLabTextOnly) return;
    try {
      final raw = await _storage.read(key: _zfSessionKey);
      if (raw == null) return;
      final session = ZonafrancaSession.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (session == null || !mounted) return;
      _zfSession = session;
      _zfEmail.text = session.email;
      _zfApiBase.text = session.apiBase;
      _zfAnon.text = session.anonKey;
      await _reloadZonafranca();
    } catch (_) {
      if (mounted) {
        _mutate(() => _zfError = 'No se pudo restaurar la sesión de Zonafranca');
      }
    }
  }

  Future<void> _reloadZonafranca() async {
    final session = _zfSession;
    if (session == null || _zfPreview) return;
    _mutate(() {
      _zfLoading = true;
      _zfError = null;
    });
    try {
      final api = widget.zonafrancaApi ?? const ZonafrancaAuthApi();
      var current = session;
      ZonafrancaSnapshot snapshot;
      try {
        snapshot = await api.loadBooks(
          current,
          wallet: awLabTextOnly ? null : _wallet.address,
        );
      } on ZonafrancaException {
        current = await api.refresh(session);
        snapshot = await api.loadBooks(
          current,
          wallet: awLabTextOnly ? null : _wallet.address,
        );
        await _persistZonafranca(current);
      }
      if (!mounted) return;
      _mutate(() {
        _zfSession = current;
        _zf = snapshot;
        _zfLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      _mutate(() {
        _zfLoading = false;
        _zfError = _safeError(error);
      });
    }
  }

  Future<void> _connectZonafranca({required bool password}) async {
    final base = _zfApiBase.text.trim();
    final anon = _zfAnon.text.trim();
    final email = _zfEmail.text.trim();
    if (base.isEmpty || anon.isEmpty || email.isEmpty) {
      _mutate(() => _zfError = 'Completá el proyecto, la clave pública y el email');
      return;
    }
    _mutate(() {
      _zfLoading = true;
      _zfError = null;
    });
    try {
      final api = widget.zonafrancaApi ?? const ZonafrancaAuthApi();
      final session = password
          ? await api.signInPassword(
              email: email,
              password: _zfPassword.text,
              apiBase: base,
              anonKey: anon,
            )
          : await api.verifyCode(
              email: email,
              code: _zfCode.text.trim(),
              apiBase: base,
              anonKey: anon,
            );
      await _persistZonafranca(session);
      if (!mounted) return;
      _mutate(() => _zfSession = session);
      await _reloadZonafranca();
    } catch (error) {
      if (!mounted) return;
      _mutate(() {
        _zfLoading = false;
        _zfError = _safeError(error);
      });
    }
  }

  Future<void> _sendZonafrancaCode() async {
    final base = _zfApiBase.text.trim();
    final anon = _zfAnon.text.trim();
    final email = _zfEmail.text.trim();
    if (base.isEmpty || anon.isEmpty || email.isEmpty) {
      _mutate(() => _zfError = 'Completá el proyecto, la clave pública y el email');
      return;
    }
    _mutate(() => _zfError = null);
    try {
      final api = widget.zonafrancaApi ?? const ZonafrancaAuthApi();
      await api.sendCode(email: email, apiBase: base, anonKey: anon);
      if (!mounted) return;
      _mutate(() => _zfError = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código enviado al email de Zonafranca')),
      );
    } catch (error) {
      if (!mounted) return;
      _mutate(() => _zfError = _safeError(error));
    }
  }

  Future<void> _persistZonafranca(ZonafrancaSession session) async {
    try {
      await _storage.write(
        key: _zfSessionKey,
        value: jsonEncode(session.toJson()),
      );
    } catch (_) {
      // Tests and locked storage still keep the session in memory.
    }
  }

  Future<void> _connectCompanyQr(String raw) async {
    final payload = raw.trim();
    if (parseCompanyLinkQr(payload) == null && widget.redeemCompanyLink == null) {
      _mutate(() => _zfError = 'El QR no es de una empresa Fluuix');
      return;
    }
    _mutate(() {
      _zfLoading = true;
      _zfError = null;
      _zf = null;
      _zfSession = null;
    });
    unawaited(() async {
      try {
        await _storage.delete(key: _zfSessionKey);
      } catch (_) {}
    }());
    try {
      final session = widget.redeemCompanyLink != null
          ? await widget.redeemCompanyLink!(payload)
          : await (widget.zonafrancaApi ?? const ZonafrancaAuthApi())
                .redeemCompanyLink(payload);
      if (!mounted) return;
      final linked = widget.linkedPreview;
      _mutate(() {
        _zfSession = session;
        _zfLoading = linked == null;
        _zf = linked == null ? null : adoptCompanyLink(next: linked);
      });
      unawaited(_persistZonafranca(session));
      if (linked != null) return;
      await _reloadZonafranca();
    } catch (error) {
      if (!mounted) return;
      _mutate(() {
        _zfLoading = false;
        _zf = null;
        _zfSession = null;
        _zfError = _safeError(error);
      });
    }
  }

  Future<void> _scanCompanyQr() async {
    final raw = await scanCompanyQr(context);
    if (raw == null || !mounted) return;
    _zfQr.text = raw;
    await _connectCompanyQr(raw);
  }

  Future<void> _disconnectZonafranca() async {
    _mutate(() {
      _zfSession = null;
      _zf = null;
      _zfLoading = false;
      _zfError = null;
    });
    try {
      await _storage.delete(key: _zfSessionKey);
    } catch (_) {}
    if (mounted) _mutate(() {});
  }

  void _useSuggestedZonafranca() {
    _zfApiBase.text = suggestedZonafrancaApiBase;
    _zfAnon.text = suggestedZonafrancaAnonKey;
    _mutate(() => _zfError = null);
  }

  List<Widget> _booksBlock(String key, {String? note}) {
    if (_zfLoading) {
      return const [
        Text('Leyendo Zonafranca…', style: TextStyle(color: Colors.white70)),
      ];
    }
    if (_zf?.signedIn != true) {
      return [
        const Text(
          'Conectá Zonafranca',
          key: Key('zf-connect-prompt'),
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        const Text(
          'Esta sección lee la empresa del usuario. No hay un saldo de relleno.',
          style: TextStyle(color: Colors.white60, height: 1.4),
        ),
      ];
    }
    if (_zfError != null) {
      return [
        Text(_zfError!, style: const TextStyle(color: Colors.redAccent)),
      ];
    }
    final rows = _zf!.rows(key);
    return [
      if (_zf!.error != null)
        Text(_zf!.error!, style: const TextStyle(color: Colors.redAccent)),
      if (note != null)
        Text(note, style: const TextStyle(color: Color(0xff9aa0ae), height: 1.4)),
      if (rows.isEmpty)
        const Text(
          'No hay movimientos.',
          key: Key('zf-empty'),
          style: TextStyle(color: Colors.white70),
        )
      else
        for (final row in rows)
          LedgerRow(title: row.title, subtitle: row.detail, trailing: ''),
    ];
  }

  List<Widget> _portalsBoard() {
    final catalog = _zf?.rows('catalog').length ?? 0;
    return [
      Text('Portales', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      const Text(
        'Fluuix, ZonaFranca, TokenizaTuNegocio y el resto usan la misma sesión.',
        style: TextStyle(color: Colors.white60, height: 1.4),
      ),
      if (catalog > 0) ...[
        const SizedBox(height: 6),
        Text(
          'Catálogo MCP: $catalog herramientas.',
          key: const Key('mcp-catalog-count'),
          style: const TextStyle(color: Colors.white70),
        ),
      ],
      const SizedBox(height: 10),
      for (final portal in ecosystemPortals)
        LedgerRow(
          key: Key('portal-${portal.id}'),
          title: portal.label,
          subtitle: '${portal.blurb} ${portalStatus(portal, _zf)}',
          onTap: _portalScreen(portal.id) == null
              ? null
              : () => _openScreen(_portalScreen(portal.id)!),
        ),
      const SizedBox(height: 8),
    ];
  }

  TreasuryScreen? _portalScreen(String id) => switch (id) {
    'fluuix' => TreasuryScreen.dashboard,
    'zonafranca' => TreasuryScreen.tokenZone,
    'tokenizatunegocio' || 'tokenizeyourbusiness' => TreasuryScreen.tokenTtn,
    'zonabank' => TreasuryScreen.boxLocal,
    'fideicomiso' => TreasuryScreen.boxTrust,
    'fondos' => TreasuryScreen.boxFund,
    'crowdfunding' => TreasuryScreen.boxCrowd,
    'licitaciones' => TreasuryScreen.boxTender,
    'donations' => TreasuryScreen.boxDonation,
    _ => null,
  };

  Future<void> _readMcp(String tool, String label) async {
    final session = _zfSession;
    if (session == null || _zfPreview) {
      _mutate(() {
        _mcpTool = label;
        _mcpBusy = false;
        _mcpBody = _zfPreview
            ? 'La vista de prueba no llama al gateway.'
            : 'Conectá la empresa en Cuenta para leer este portal.';
      });
      return;
    }
    _mutate(() {
      _mcpBusy = true;
      _mcpTool = label;
      _mcpBody = null;
    });
    try {
      final text = await const EcosystemMcp().read(tool, session);
      if (!mounted) return;
      _mutate(() {
        _mcpBusy = false;
        _mcpBody = text.isEmpty ? 'Sin datos.' : text;
      });
    } catch (error) {
      if (!mounted) return;
      _mutate(() {
        _mcpBusy = false;
        _mcpBody = _safeError(error);
      });
    }
  }

  List<Widget> _zonafrancaAccountCard() {
    final snapshot = _zf;
    return [
      Text('Zonafranca', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      if (snapshot?.signedIn == true) ...[
        Text(
          snapshot!.businessName ?? 'Empresa sin nombre',
          key: const Key('zf-business'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          snapshot.email ?? '',
          key: const Key('zf-email'),
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Text(
          snapshot.walletLinked == true
              ? 'Wallet vinculada a la empresa'
              : snapshot.walletLinked == false
              ? 'La wallet de este teléfono no está en la empresa. Los libros igual cargan por el usuario.'
              : 'Todavía no se contrastó la wallet.',
          key: const Key('zf-wallet-link'),
          style: const TextStyle(color: Colors.white60, height: 1.4),
        ),
        TextButton(
          onPressed: _disconnectZonafranca,
          child: const Text('Cerrar sesión de Zonafranca'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Para operar con otra empresa, escaneá su QR. Los datos de esta se borran.',
          style: TextStyle(color: Colors.white60, height: 1.4),
        ),
      ] else ...[
        const Text(
          'El mismo usuario del hub. La clave anónima es pública; el refresh queda en el teléfono.',
          style: TextStyle(color: Colors.white60, height: 1.4),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('zf-api-base'),
          controller: _zfApiBase,
          decoration: const InputDecoration(labelText: 'URL del gateway'),
        ),
        TextField(
          key: const Key('zf-anon'),
          controller: _zfAnon,
          decoration: const InputDecoration(labelText: 'Clave pública anon'),
        ),
        TextField(
          key: const Key('zf-email-field'),
          controller: _zfEmail,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        TextField(
          controller: _zfPassword,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Contraseña'),
        ),
        TextField(
          controller: _zfCode,
          decoration: const InputDecoration(labelText: 'Código'),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: _useSuggestedZonafranca,
              child: const Text('Usar proyecto Zonafranca'),
            ),
            FilledButton(
              key: const Key('zf-password-sign-in'),
              onPressed: _zfLoading
                  ? null
                  : () => _connectZonafranca(password: true),
              child: const Text('Conectar Zonafranca'),
            ),
            TextButton(
              onPressed: _zfLoading ? null : _sendZonafrancaCode,
              child: const Text('Enviar código'),
            ),
            TextButton(
              onPressed: _zfLoading
                  ? null
                  : () => _connectZonafranca(password: false),
              child: const Text('Confirmar código'),
            ),
          ],
        ),
      ],
      const SizedBox(height: 8),
      TextField(
        key: const Key('zf-qr-payload'),
        controller: _zfQr,
        decoration: const InputDecoration(labelText: 'QR de la empresa'),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton(
            key: const Key('zf-qr-scan'),
            onPressed: _zfLoading ? null : _scanCompanyQr,
            child: const Text('Escanear QR'),
          ),
          FilledButton(
            key: const Key('zf-qr-connect'),
            onPressed: _zfLoading ? null : () => _connectCompanyQr(_zfQr.text),
            child: Text(
              snapshot?.signedIn == true
                  ? 'Conectar otra empresa'
                  : 'Conectar con QR',
            ),
          ),
        ],
      ),
      if (_zfError != null)
        Text(_zfError!, style: const TextStyle(color: Colors.redAccent)),
      const SizedBox(height: 16),
    ];
  }
}
