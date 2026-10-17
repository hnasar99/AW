part of '../main.dart';

extension _AjustesView on _WalletHomeState {
  List<Widget> _settingsView() => [
    Text(
      awLabTextOnly ? 'Configuración del laboratorio' : 'Firma e inferencia',
      style: Theme.of(context).textTheme.headlineSmall,
    ),
    const SizedBox(height: 16),
    if (!awLabTextOnly)
      _card(
        children: [
          const Text(
            'WalletConnect / Reown',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ingresá el Project ID de tu proyecto. Se puede cambiar sin recompilar. La sesión de wallet permanece sólo en memoria; al reiniciar la app se vuelve a conectar. FluuiX no pide la frase semilla ni la clave privada.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _projectId,
            autocorrect: false,
            enableSuggestions: false,
            enabled: !_settingsBusy && !_busy && !_wallet.requestPending,
            onChanged: (_) => _settingsTouched = true,
            decoration: const InputDecoration(
              labelText: 'Project ID',
              hintText: '32 caracteres hexadecimales',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _settingsBusy || _busy || _wallet.requestPending
                ? null
                : _configureWallet,
            child: Text(
              _settingsBusy ? 'Conectando…' : 'Guardar y conectar Reown',
            ),
          ),
          if (_wallet.configured)
            const Text(
              'Cliente Reown inicializado',
              style: TextStyle(color: Colors.greenAccent),
            ),
        ],
      ),
    const SizedBox(height: 16),
    _card(
      children: [
        const Text(
          awLabTextOnly
              ? 'Servidor de texto local'
              : 'Inferencia para OpenHuman',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        const Text(
          awLabTextOnly
              ? 'Ingresá la IP loopback literal y la ruta /v1 del transporte que estableciste hacia tu servidor autorizado. Elegí un modelo que ya esté instalado allí. No hay endpoint ni modelo predeterminados.'
              : 'El modelo es opcional. Podés dejar Kimi para la narrativa de Monad, usar Ollama en loopback u otro endpoint compatible con /v1. OpenHuman corre en el teléfono: el modelo propone y no firma. Ninguna API key viene en la app.',
        ),
        if (!awLabTextOnly) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            key: const Key('use-kimi-engine'),
            onPressed: _agentReady || _agentBusy ? null : _useKimiEngine,
            child: const Text('Completar con Kimi (opcional)'),
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          key: const Key('inference-endpoint'),
          controller: _endpoint,
          enabled: !_agentReady && !_agentBusy,
          autocorrect: false,
          keyboardType: TextInputType.url,
          enableSuggestions: false,
          onChanged: (_) => _noteEndpointEdited(),
          decoration: const InputDecoration(
            labelText: awLabTextOnly
                ? 'Endpoint loopback /v1'
                : 'Endpoint HTTPS',
            hintText: awLabTextOnly
                ? 'Completá tu endpoint autorizado'
                : 'https://…/v1 o http://127.0.0.1:11434/v1',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('inference-model'),
          controller: _model,
          enabled: !_agentReady && !_agentBusy,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (_) => _settingsTouched = true,
          decoration: const InputDecoration(
            labelText: 'ID del modelo',
            hintText: awLabTextOnly
                ? 'ID exacto del modelo local instalado'
                : 'kimi-k3, un modelo de Ollama u otro ID',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('inference-key'),
          controller: _key,
          enabled: !_agentReady && !_agentBusy,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (_) => _settingsTouched = true,
          decoration: const InputDecoration(
            labelText: awLabTextOnly
                ? 'Clave o marcador del servidor'
                : 'API key de inferencia',
            helperText: awLabTextOnly
                ? 'Un marcador sintético no protege ni autentica el servidor.'
                : null,
            helperMaxLines: 2,
          ),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _rememberKey,
          onChanged: _agentReady || _agentBusy ? null : _setRememberKey,
          title: const Text(
            'Recordar la clave en el almacenamiento seguro del sistema',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          awLabTextOnly
              ? 'Las consultas se envían únicamente al endpoint indicado. Los ajustes del laboratorio se guardan separados de los del modo Arc.'
              : 'Al activar y consultar, enviás tus mensajes y el contexto necesario a ${Uri.tryParse(_endpoint.text)?.host ?? 'tu proveedor'}.',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: _agentReady || _agentBusy ? null : _startAgent,
          child: Text(
            _agentBusy
                ? 'Inicializando…'
                : awLabTextOnly
                ? 'Iniciar laboratorio de texto'
                : 'Activar OpenHuman con este proveedor',
          ),
        ),
        OutlinedButton(
          onPressed: _agentBusy ? null : _resetAgent,
          child: const Text('Detener agente y olvidar la clave'),
        ),
      ],
    ),
    const SizedBox(height: 16),
    if (!awLabTextOnly)
      ExpansionTile(
        title: const Text('Agregar Arc Testnet manualmente'),
        children: [
          _card(
            children: [
              const Text(
                'Nombre: Arc Testnet\nChain ID: 5042002\nMoneda nativa: USDC · 18 decimales',
              ),
              const SelectableText(
                'RPC: ${ArcNetwork.rpc}\nExplorador: ${ArcNetwork.explorer}',
              ),
              const SizedBox(height: 8),
              const Text(
                'Agregá la red en tu wallet, luego reconectá autorizando Arc Testnet. Agregar una red no amplía automáticamente los permisos de una sesión existente.',
              ),
              TextButton(
                onPressed: () =>
                    _open('https://docs.arc.io/arc/references/connect-to-arc'),
                child: const Text('Documentación oficial'),
              ),
            ],
          ),
        ],
      ),
    if (_settingsError != null) _errorBox(_settingsError!),
    if (!_storageReady && !_settingsBusy)
      TextButton(
        onPressed: _loadSettings,
        child: const Text('Volver a leer el estado seguro'),
      ),
    if (_agentError != null) _errorBox(_agentError!),
  ];
}
