part of '../main.dart';

extension _AjustesView on _WalletHomeState {
  List<Widget> _settingsView(AppLocalizations l10n) => [
    Text(
      awLabTextOnly ? l10n.settingsLabTitle : l10n.settingsTitle,
      style: Theme.of(context).textTheme.headlineSmall,
    ),
    const SizedBox(height: 16),
    _card(
      children: [
        Text(
          l10n.languageSettings,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedLocale?.languageCode,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(l10n.languageAuto),
            ),
            DropdownMenuItem<String>(
              value: 'es',
              child: Text(l10n.languageSpanish),
            ),
            DropdownMenuItem<String>(
              value: 'en',
              child: Text(l10n.languageEnglish),
            ),
            DropdownMenuItem<String>(
              value: 'pt',
              child: Text(l10n.languagePortuguese),
            ),
            DropdownMenuItem<String>(
              value: 'fr',
              child: Text(l10n.languageFrench),
            ),
            DropdownMenuItem<String>(
              value: 'de',
              child: Text(l10n.languageGerman),
            ),
            DropdownMenuItem<String>(
              value: 'it',
              child: Text(l10n.languageItalian),
            ),
            DropdownMenuItem<String>(
              value: 'zh',
              child: Text(l10n.languageChinese),
            ),
          ],
          onChanged: (value) {
            _saveLocale(value == null ? null : Locale(value));
          },
        ),
      ],
    ),
    const SizedBox(height: 16),
    if (!awLabTextOnly)
      _card(
        children: [
          Text(
            l10n.walletConnectTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(l10n.walletConnectDescription),
          const SizedBox(height: 12),
          TextField(
            controller: _projectId,
            autocorrect: false,
            enableSuggestions: false,
            enabled: !_settingsBusy && !_busy && !_wallet.requestPending,
            onChanged: (_) => _settingsTouched = true,
            decoration: InputDecoration(
              labelText: l10n.projectIdLabel,
              hintText: l10n.projectIdHint,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _settingsBusy || _busy || _wallet.requestPending
                ? null
                : _configureWallet,
            child: Text(
              _settingsBusy ? l10n.connecting : l10n.saveAndConnectReown,
            ),
          ),
          if (_wallet.configured)
            Text(
              l10n.reownClientInitialized,
              style: TextStyle(color: FluuixColors.success),
            ),
        ],
      ),
    const SizedBox(height: 16),
    _card(
      children: [
        Text(
          awLabTextOnly ? l10n.inferenceLabTitle : l10n.inferenceTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text(
          awLabTextOnly ? l10n.inferenceLabDescription : l10n.inferenceDescription,
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('inference-endpoint'),
          controller: _endpoint,
          enabled: !_agentReady && !_agentBusy,
          autocorrect: false,
          keyboardType: TextInputType.url,
          enableSuggestions: false,
          onChanged: (_) => _noteEndpointEdited(),
          decoration: InputDecoration(
            labelText: awLabTextOnly ? l10n.endpointLabLabel : l10n.endpointLabel,
            hintText: awLabTextOnly ? l10n.endpointLabHint : l10n.endpointHint,
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
          decoration: InputDecoration(
            labelText: l10n.modelLabel,
            hintText: awLabTextOnly ? l10n.modelLabHint : l10n.modelHint,
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
          decoration: InputDecoration(
            labelText: awLabTextOnly ? l10n.apiKeyLabLabel : l10n.apiKeyLabel,
            helperText: awLabTextOnly ? l10n.apiKeyLabHelper : null,
            helperMaxLines: 2,
          ),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _rememberKey,
          onChanged: _agentReady || _agentBusy ? null : _setRememberKey,
          title: Text(l10n.rememberKey),
        ),
        const SizedBox(height: 6),
        Text(
          awLabTextOnly
              ? l10n.labQueriesNote
              : l10n.queriesSentTo(Uri.tryParse(_endpoint.text)?.host ?? 'your provider'),
          style: TextStyle(color: FluuixColors.textMuted),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: _agentReady || _agentBusy ? null : _startAgent,
          child: Text(
            _agentBusy
                ? l10n.initializing
                : awLabTextOnly
                ? l10n.startLabButton
                : l10n.activateOpenHumanButton,
          ),
        ),
        OutlinedButton(
          onPressed: _agentBusy ? null : _resetAgent,
          child: Text(l10n.stopAgentForgetKey),
        ),
      ],
    ),
    const SizedBox(height: 16),
    if (!awLabTextOnly)
      ExpansionTile(
        title: Text(l10n.addArcTestnetManually),
        children: [
          _card(
            children: [
              Text(l10n.arcManualInfo),
              const SelectableText(
                'RPC: ${ArcNetwork.rpc}\nExplorador: ${ArcNetwork.explorer}',
              ),
              const SizedBox(height: 8),
              Text(l10n.arcManualInstructions),
              TextButton(
                onPressed: () =>
                    _open('https://docs.arc.io/arc/references/connect-to-arc'),
                child: Text(l10n.officialDocs),
              ),
            ],
          ),
        ],
      ),
    if (_settingsError != null) _errorBox(_settingsError!),
    if (!_storageReady && !_settingsBusy)
      TextButton(
        onPressed: _loadSettings,
        child: Text(l10n.retrySecureStorage),
      ),
    if (_agentError != null) _errorBox(_agentError!),
  ];
}
