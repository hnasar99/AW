part of '../main.dart';

extension _AgenteView on _WalletHomeState {
  String _getAgentStatusText(AppLocalizations l10n) {
    switch (_agentStatus) {
      case 'agentVerifyStatus':
        return l10n.agentVerifyStatus;
      case 'rustExecutedStatus':
        return l10n.rustExecutedStatus(
          _nativeStatus?.os ?? '?',
          _nativeStatus?.arch ?? '?',
        );
      case 'labReadyStatus':
        return l10n.labReadyStatus(
          _endpoint.text.trim(),
          _model.text.trim(),
        );
      case 'openHumanLocalActive':
        return l10n.openHumanLocalActive(
          Uri.tryParse(_endpoint.text)?.host ?? 'provider',
        );
      case 'turnCompletedStatus':
        return l10n.turnCompletedStatus;
      case 'labResponseReceivedStatus':
        return l10n.labResponseReceivedStatus;
      case 'agentStoppedStatus':
        return l10n.agentStoppedStatus;
      default:
        return _agentStatus;
    }
  }

  List<Widget> _agentView(AppLocalizations l10n) => [
    Text(
      awLabTextOnly ? l10n.agentLabTitle : l10n.agentBoxTitle,
      style: Theme.of(context).textTheme.headlineSmall,
    ),
    const SizedBox(height: 10),
    Text(_getAgentStatusText(l10n)),
    const SizedBox(height: 10),
    Text(
      awLabTextOnly ? l10n.agentLabDescription : l10n.agentDescription,
      style: const TextStyle(color: FluuixColors.textMuted, height: 1.5),
    ),
    const SizedBox(height: 16),
    OutlinedButton.icon(
      onPressed: _agentBusy ? null : _probeNative,
      icon: const Icon(Icons.memory),
      label: Text(l10n.verifyNativeRust),
    ),
    if (_nativeStatus != null) ...[
      const SizedBox(height: 10),
      _card(
        children: [
          Text(l10n.libraryExecuted(_nativeStatus!.os, _nativeStatus!.arch)),
          Text('OpenHuman ${shorten(_nativeStatus!.commit)}'),
          if (_nativeStatus!.initialized)
            Text(l10n.allowedTools(
              _nativeStatus!.tools.isEmpty
                  ? l10n.noTools
                  : _nativeStatus!.tools.join(', '),
            ))
          else
            Text(l10n.runtimeNotInitialized),
          if (awLabTextOnly && _nativeStatus!.initialized)
            Text(l10n.nativePolicy(_nativeStatus!.mode ?? l10n.notStarted)),
          if (awLabTextOnly && _nativeStatus!.labContextTokens != null)
            Text(l10n.agentBudget(_nativeStatus!.labContextTokens.toString())),
          Text(
            awLabTextOnly ? l10n.labTestDisclaimer : l10n.localTestDisclaimer,
            style: const TextStyle(color: FluuixColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    ],
    const SizedBox(height: 16),
    if (!_agentReady)
      FilledButton(
        onPressed: _openSettingsTab,
        child: Text(
          awLabTextOnly ? l10n.configureLabButton : l10n.configureProviderButton,
        ),
      ),
    if (_agentReady) ...[
      TextField(
        controller: _prompt,
        minLines: 3,
        maxLines: 8,
        enabled: !_agentBusy,
        decoration: InputDecoration(labelText: l10n.queryLabel),
      ),
      const SizedBox(height: 10),
      if (!awLabTextOnly)
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              label: Text(l10n.presetArcStatus),
              onPressed: _agentBusy
                  ? null
                  : () => _prompt.text =
                        'Usá arc_network_status y explicame el estado real de Arc Testnet.',
            ),
            if (_wallet.address != null)
              ActionChip(
                label: Text(l10n.presetMyBalance),
                onPressed: _agentBusy
                    ? null
                    : () => _prompt.text =
                          'Usá arc_balance para consultar el saldo USDC de ${_wallet.address} en Arc Testnet. Explicá que es el mismo saldo que paga gas.',
              ),
          ],
        ),
      const SizedBox(height: 10),
      FilledButton.icon(
        onPressed: _agentBusy ? null : _askAgent,
        icon: const Icon(Icons.psychology_outlined),
        label: Text(_agentBusy ? l10n.agentWorking : l10n.queryOpenHuman),
      ),
      if (_agentBusy) ...[
        const SizedBox(height: 8),
        const LinearProgressIndicator(),
        TextButton(
          onPressed: _cancelAgent,
          child: Text(l10n.cancelTurn),
        ),
      ],
    ],
    if (_agentReply != null) ...[
      const SizedBox(height: 18),
      _card(
        children: [
          if (!awLabTextOnly) ...[
            Text(
              l10n.modelText,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
          ],
          SelectableText(_agentReply!, style: const TextStyle(height: 1.5)),
        ],
      ),
      if (!awLabTextOnly)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            l10n.modelTextDisclaimer,
            style: const TextStyle(color: FluuixColors.textMuted, fontSize: 12),
          ),
        ),
      if (!awLabTextOnly && _toolCalls.isNotEmpty)
        Text(l10n.toolsExecuted(_toolCalls.join(', '))),
      if (!awLabTextOnly)
        ..._liveReads.map(
          (read) => Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _card(
              children: [
                Text(
                  l10n.liveReadTool(read.tool),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (read.result['block_number'] != null)
                  Text(l10n.blockNumber(read.result['block_number'].toString())),
                if (read.result['balance_usdc'] != null)
                  Text(l10n.balanceUsdcLabel(read.result['balance_usdc'].toString())),
                if (read.result['observed_at_unix'] != null)
                  Text(l10n.observationUnix(read.result['observed_at_unix'].toString())),
                Text(
                  read.result['ok'] == true
                      ? l10n.toolResultOk
                      : l10n.toolResultFailed,
                ),
              ],
            ),
          ),
        ),
      if (!awLabTextOnly && _proposal != null)
        OutlinedButton.icon(
          onPressed: _busy ? null : _applyProposal,
          icon: const Icon(Icons.assignment_return_outlined),
          label: Text(l10n.applyProposal),
        ),
      const SizedBox(height: 8),
      Text(
        awLabTextOnly ? l10n.labResponseDisclaimer : l10n.agentResponseDisclaimer,
        style: const TextStyle(color: FluuixColors.textMuted, fontSize: 12),
      ),
    ],
    if (awLabTextOnly && _labRequestAudit != null) ...[
      const SizedBox(height: 16),
      _card(
        children: [
          Text(l10n.lastQueryLog),
          const SizedBox(height: 8),
          SelectableText(
            const JsonEncoder.withIndent('  ').convert(_labRequestAudit),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.logMetadataNote,
            style: const TextStyle(color: FluuixColors.textMuted, fontSize: 12),
          ),
          TextButton(
            onPressed: () => Clipboard.setData(
              ClipboardData(text: jsonEncode(_labRequestAudit)),
            ),
            child: Text(l10n.copyLogWithoutKeys),
          ),
        ],
      ),
    ],
    if (_agentError != null) _errorBox(_agentError!),
    if (_nativeStatus?.requiresReset == true ||
        (awLabTextOnly && _nativeStatus?.initialized == true && !_agentReady))
      OutlinedButton(
        onPressed: _agentBusy ? null : _resetAgent,
        child: Text(l10n.restartAfterInterrupted),
      ),
  ];
}
