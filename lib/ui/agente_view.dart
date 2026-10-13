part of '../main.dart';

extension _AgenteView on _WalletHomeState {
  List<Widget> _agentView() => [
    Text(
      awLabTextOnly ? 'Consulta al laboratorio' : 'Agente de la caja',
      style: Theme.of(context).textTheme.headlineSmall,
    ),
    const SizedBox(height: 10),
    Text(_agentStatus),
    const SizedBox(height: 10),
    const Text(
      awLabTextOnly
          ? 'OpenHuman coordina la consulta dentro de AW. El modelo debe ejecutarse en tu laboratorio, a través del endpoint loopback que configures. No se inicia ninguna consulta de blockchain.'
          : 'El agente propone órdenes con arc_network_status y arc_balance. '
                'Una herramienta ejecutada muestra el dato que leyó Rust. '
                'El texto del modelo no autoriza ni firma.',
      style: TextStyle(color: Colors.white70, height: 1.5),
    ),
    const SizedBox(height: 16),
    OutlinedButton.icon(
      onPressed: _agentBusy ? null : _probeNative,
      icon: const Icon(Icons.memory),
      label: const Text('Verificar ejecución nativa de Rust'),
    ),
    if (_nativeStatus != null) ...[
      const SizedBox(height: 10),
      _card(
        children: [
          Text(
            'Biblioteca ejecutada: ${_nativeStatus!.os} / ${_nativeStatus!.arch}',
          ),
          Text('OpenHuman ${shorten(_nativeStatus!.commit)}'),
          if (_nativeStatus!.initialized)
            Text(
              'Herramientas permitidas: ${_nativeStatus!.tools.isEmpty ? 'ninguna' : _nativeStatus!.tools.join(', ')}',
            )
          else
            const Text(
              'Runtime sin inicializar. La política de herramientas se comprueba al inicializar.',
            ),
          if (awLabTextOnly && _nativeStatus!.initialized)
            Text('Política nativa: ${_nativeStatus!.mode ?? 'sin iniciar'}'),
          if (awLabTextOnly && _nativeStatus!.labContextTokens != null)
            Text(
              'Presupuesto del agente: ${_nativeStatus!.labContextTokens} tokens. No acredita la capacidad real del modelo.',
            ),
          const Text(
            awLabTextOnly
                ? 'Ejecutar esta biblioteca no verifica todavía el modelo del laboratorio.'
                : 'Esta prueba local no implica que la inferencia o una transferencia hayan sido verificadas.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    ],
    const SizedBox(height: 16),
    if (!_agentReady)
      FilledButton(
        onPressed: _openSettingsTab,
        child: const Text(
          awLabTextOnly
              ? 'Configurar laboratorio'
              : 'Configurar proveedor e iniciar agente',
        ),
      ),
    if (_agentReady) ...[
      TextField(
        controller: _prompt,
        minLines: 3,
        maxLines: 8,
        enabled: !_agentBusy,
        decoration: const InputDecoration(labelText: 'Tu consulta al agente'),
      ),
      const SizedBox(height: 10),
      if (!awLabTextOnly)
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              label: const Text('Estado real de Arc'),
              onPressed: _agentBusy
                  ? null
                  : () => _prompt.text =
                        'Usá arc_network_status y explicame el estado real de Arc Testnet.',
            ),
            if (_wallet.address != null)
              ActionChip(
                label: const Text('Consultar mi saldo'),
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
        label: Text(_agentBusy ? 'Agente trabajando…' : 'Consultar OpenHuman'),
      ),
      if (_agentBusy) ...[
        const SizedBox(height: 8),
        const LinearProgressIndicator(),
        TextButton(
          onPressed: _cancelAgent,
          child: const Text('Cancelar turno'),
        ),
      ],
    ],
    if (_agentReply != null) ...[
      const SizedBox(height: 18),
      _card(
        children: [
          if (!awLabTextOnly) ...[
            const Text(
              'Texto del modelo',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
          ],
          SelectableText(_agentReply!, style: const TextStyle(height: 1.5)),
        ],
      ),
      if (!awLabTextOnly)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Eso es texto del modelo. No es una lectura de red ni una firma.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ),
      if (!awLabTextOnly && _toolCalls.isNotEmpty)
        Text('Herramientas ejecutadas: ${_toolCalls.join(', ')}'),
      if (!awLabTextOnly)
        ..._liveReads.map(
          (read) => Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _card(
              children: [
                Text(
                  'Lectura ejecutada · ${read.tool}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (read.result['block_number'] != null)
                  Text('Bloque: ${read.result['block_number']}'),
                if (read.result['balance_usdc'] != null)
                  Text('Saldo USDC: ${read.result['balance_usdc']}'),
                if (read.result['observed_at_unix'] != null)
                  Text('Observación UNIX: ${read.result['observed_at_unix']}'),
                Text(
                  read.result['ok'] == true
                      ? 'Resultado obtenido por la herramienta Rust'
                      : 'La herramienta no pudo completar la lectura',
                ),
              ],
            ),
          ),
        ),
      if (!awLabTextOnly && _proposal != null)
        OutlinedButton.icon(
          onPressed: _busy ? null : _applyProposal,
          icon: const Icon(Icons.assignment_return_outlined),
          label: const Text('Llevar propuesta al formulario'),
        ),
      const SizedBox(height: 8),
      const Text(
        awLabTextOnly
            ? 'La salida del modelo es texto no confiable. No se interpreta como una instrucción ni habilita acciones.'
            : 'Una respuesta del modelo no es una confirmación de pago. El agente sólo propone; la firma requiere tu revisión en la wallet.',
        style: TextStyle(color: Colors.white60, fontSize: 12),
      ),
    ],
    if (awLabTextOnly && _labRequestAudit != null) ...[
      const SizedBox(height: 16),
      _card(
        children: [
          const Text('Registro de la última consulta'),
          const SizedBox(height: 8),
          SelectableText(
            const JsonEncoder.withIndent('  ').convert(_labRequestAudit),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sólo metadatos del cliente. Cotejá este ID con el procesamiento real en tu servidor y con la respuesta visible. No se incluyen mensajes ni claves.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          TextButton(
            onPressed: () => Clipboard.setData(
              ClipboardData(text: jsonEncode(_labRequestAudit)),
            ),
            child: const Text('Copiar registro sin mensajes ni claves'),
          ),
        ],
      ),
    ],
    if (_agentError != null) _errorBox(_agentError!),
    if (_nativeStatus?.requiresReset == true ||
        (awLabTextOnly && _nativeStatus?.initialized == true && !_agentReady))
      OutlinedButton(
        onPressed: _agentBusy ? null : _resetAgent,
        child: const Text('Reiniciar después del turno interrumpido'),
      ),
  ];
}
