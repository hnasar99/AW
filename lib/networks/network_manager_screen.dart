import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../domain/arc.dart' show formatUnits;
import 'evm_network.dart';
import 'network_controller.dart';

class NetworkManagerScreen extends StatefulWidget {
  const NetworkManagerScreen({super.key, this.controller, this.autoLoad = true,
    this.openArcWorkspace});
  final NetworkController? controller;
  final bool autoLoad;
  final ValueChanged<BuildContext>? openArcWorkspace;
  @override
  State<NetworkManagerScreen> createState() => _NetworkManagerScreenState();
}

class _NetworkManagerScreenState extends State<NetworkManagerScreen> {
  late final NetworkController c;
  final address = TextEditingController();
  @override
  void initState() {
    super.initState();
    c = widget.controller ?? NetworkController();
    c.addListener(_changed);
    if (widget.autoLoad) c.load();
  }
  void _changed() { if (mounted) setState(() {}); }
  @override
  void dispose() {
    c.removeListener(_changed);
    if (widget.controller == null) c.dispose();
    address.dispose();
    super.dispose();
  }
  bool get disabled => c.busy || !c.loaded || c.storageFault;

  Future<void> _edit([EvmNetwork? profile]) async {
    final result = await Navigator.of(context).push<EvmNetwork>(MaterialPageRoute(
      builder: (_) => NetworkEditor(profile: profile),
    ));
    if (!mounted || result == null) return;
    await c.saveAndConnect(result, replaceExisting: profile != null);
  }
  Future<void> _reset() async {
    final accepted = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(
      title: const Text('Restablecer sólo redes'),
      content: const Text('Se eliminarán los perfiles RPC guardados y se restaurarán Arc y Monad mediante Fluuix. No se borran datos de wallet, pagos ni proveedor de inferencia.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Restablecer redes')),
      ],
    ));
    if (accepted == true && mounted) await c.resetProfiles();
  }
  Future<void> _explorer() async {
    final base = c.selected.explorerUrl;
    if (base.isEmpty) return;
    try {
      final opened = await launchUrl(Uri.parse(base), mode: LaunchMode.externalApplication);
      if (!opened && mounted) _message('No se pudo abrir el explorador.');
    } catch (_) { if (mounted) _message('No se pudo abrir el explorador.'); }
  }
  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Widget _section(String title, List<Widget> children) => Card(
    child: Padding(padding: const EdgeInsets.all(18), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14), ...children],
    )),
  );

  @override
  Widget build(BuildContext context) {
    final current = c.selected;
    final result = c.snapshot;
    return Scaffold(
      appBar: AppBar(title: const Text('Fluuix · Redes EVM'), actions: [
        IconButton(onPressed: c.busy ? null : _reset,
          icon: const Icon(Icons.settings_backup_restore), tooltip: 'Restablecer redes'),
      ]),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const Text('Conectá tu RPC', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Agregá una red EVM, verificá su chain ID y consultá su saldo nativo. No se firma ni se envía una transacción desde esta pantalla.'),
          if (c.busy) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: LinearProgressIndicator()),
          if (c.error != null) Card(child: Padding(padding: const EdgeInsets.all(16),
            child: Text(c.error!, key: const Key('network-error')))),
          _section('Red seleccionada', [
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Red para consultas'),
              child: DropdownButtonHideUnderline(child: DropdownButton<int>(
                key: const Key('network-selector'),
                value: c.book.selectedId,
                isExpanded: true,
                items: c.book.profiles.map((p) => DropdownMenuItem(
                  value: p.chainId,
                  child: Text('${p.name} · ${p.chainId}', overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: disabled ? null : (id) { if (id != null) c.select(id); },
              )),
            ),
            const SizedBox(height: 12),
            Text('${current.testnet ? 'TESTNET' : 'MAINNET / RED DECLARADA'} · ${current.symbol} · ${current.decimals} decimales'),
            const SizedBox(height: 8),
            Text('Origen RPC: ${current.rpcOrigin}'),
            Text(current.viaFluuix ? 'Ruta: Fluuix. ZonaFranca no está configurada.' : 'Ruta: RPC personalizado directo desde este dispositivo.'),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              FilledButton.icon(key: const Key('verify-network'), onPressed: disabled ? null : () => c.refresh(),
                icon: const Icon(Icons.network_check), label: const Text('Verificar conexión')),
              OutlinedButton.icon(key: const Key('add-network'), onPressed: disabled ? null : () => _edit(),
                icon: const Icon(Icons.add), label: const Text('Agregar red')),
              TextButton(onPressed: disabled ? null : () => _edit(current), child: const Text('Editar RPC')),
            ]),
            const SizedBox(height: 12),
            Text(result == null ? 'Sin verificación actual' : 'RPC verificado · chain ${result.network.chainId}',
              key: const Key('connection-state'), style: const TextStyle(fontWeight: FontWeight.bold)),
            if (result != null) ...[
              Text('Bloque ${result.block} · ${result.duration.inMilliseconds} ms'),
              Text('Observado ${result.observedAt.toIso8601String()}'),
              const Text('Es una observación del proveedor, no una garantía de disponibilidad ni una verificación independiente del consenso.'),
            ],
          ]),
          _section('Saldo nativo · sólo lectura', [
            TextField(controller: address, key: const Key('balance-address'),
              autocorrect: false, enableSuggestions: false,
              decoration: const InputDecoration(labelText: 'Dirección pública 0x', hintText: '0x…')),
            const SizedBox(height: 12),
            FilledButton(onPressed: disabled ? null : () => c.refresh(address: address.text.trim()),
              child: const Text('Consultar saldo')),
            if (result?.balance != null) ...[
              const SizedBox(height: 14),
              SelectableText('${formatUnits(result!.balance!, result.network.decimals)} ${result.network.symbol}',
                key: const Key('native-balance'), style: Theme.of(context).textTheme.headlineSmall),
              Text('Dirección consultada: ${result.address}'),
              Text('Unidades mínimas exactas: ${result.balance}'),
            ],
            if (current.explorerUrl.isNotEmpty)
              TextButton(onPressed: _explorer, child: const Text('Abrir explorador configurado')),
            const SizedBox(height: 8),
            const Text('Ingresá sólo direcciones públicas. El RPC recibe la dirección y la conexión de este dispositivo. Nunca ingreses semillas o claves privadas.'),
          ]),
          _section('Perfiles guardados', [
            for (final profile in c.book.profiles) ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(profile.name), subtitle: Text('Chain ${profile.chainId} · ${profile.rpcOrigin}'),
              trailing: IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Eliminar ${profile.name}',
                onPressed: disabled || profile.chainId == current.chainId ? null : () => c.remove(profile.chainId)),
            ),
          ]),
          _section('Alcance de la conexión', [
            const Text('La selección de esta pantalla aplica a consultas RPC y saldo nativo. No cambia los permisos de WalletConnect, la red de Caja ni las herramientas arc_* del agente existente.'),
            const SizedBox(height: 8),
            const Text('Fluuix es la ruta inicial de Arc y Monad Testnet. Un RPC personalizado no pasa por Fluuix. No hay conmutación automática a otro proveedor o a ZonaFranca.'),
            if (widget.openArcWorkspace != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: c.busy ? null : () => widget.openArcWorkspace!(context),
                child: const Text('Abrir Caja y Agente · Arc Testnet')),
            ],
          ]),
          const SizedBox(height: 24),
        ]),
      ))),
    );
  }
}

class NetworkEditor extends StatefulWidget {
  const NetworkEditor({super.key, this.profile});
  final EvmNetwork? profile;
  @override
  State<NetworkEditor> createState() => _NetworkEditorState();
}
class _NetworkEditorState extends State<NetworkEditor> {
  late final name = TextEditingController(text: widget.profile?.name ?? '');
  late final rpc = TextEditingController(text: widget.profile?.rpcUrl ?? '');
  late final chain = TextEditingController(text: widget.profile?.chainId.toString() ?? '');
  late final symbol = TextEditingController(text: widget.profile?.symbol ?? '');
  late final decimals = TextEditingController(text: '${widget.profile?.decimals ?? 18}');
  late final explorer = TextEditingController(text: widget.profile?.explorerUrl ?? '');
  late bool testnet = widget.profile?.testnet ?? true;
  bool consent = false;
  bool revealRpc = false;
  String? error;
  @override
  void dispose() {
    for (final field in [name, rpc, chain, symbol, decimals, explorer]) { field.dispose(); }
    super.dispose();
  }
  void _submit() {
    try {
      final count = int.tryParse(decimals.text.trim());
      if (count == null) throw const FormatException('Decimales enteros requeridos.');
      final profile = EvmNetwork(name: name.text, rpcUrl: rpc.text,
        chainId: parseChainId(chain.text), symbol: symbol.text,
        decimals: count, explorerUrl: explorer.text, testnet: testnet);
      Navigator.pop(context, profile);
    } on FormatException catch (e) { setState(() => error = e.message); }
    catch (_) { setState(() => error = 'Revisá los parámetros de la red.'); }
  }
  Widget _field(String label, TextEditingController controller, {bool readOnly = false}) =>
    Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: TextField(
      controller: controller, readOnly: readOnly, autocorrect: false, enableSuggestions: false,
      decoration: InputDecoration(labelText: label),
    ));
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.profile == null ? 'Agregar red EVM' : 'Editar red EVM')),
    body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 700),
      child: ListView(padding: const EdgeInsets.all(20), children: [
        _field('Nombre de la red', name),
        TextField(controller: rpc, obscureText: !revealRpc, autocorrect: false,
          enableSuggestions: false, keyboardType: TextInputType.url,
          decoration: InputDecoration(labelText: 'URL RPC HTTPS',
            suffixIcon: IconButton(onPressed: () => setState(() => revealRpc = !revealRpc),
              tooltip: revealRpc ? 'Ocultar RPC' : 'Mostrar RPC',
              icon: Icon(revealRpc ? Icons.visibility_off : Icons.visibility)))),
        _field('Chain ID decimal o 0x', chain, readOnly: widget.profile != null),
        _field('Símbolo de moneda nativa', symbol),
        _field('Decimales de moneda nativa', decimals),
        _field('Explorador HTTPS (opcional)', explorer),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Red de pruebas (testnet)'),
          value: testnet, onChanged: (value) => setState(() => testnet = value)),
        const Text('HTTPS es obligatorio. No se importan claves privadas. Una URL RPC puede contener una clave de acceso del proveedor: queda en el almacenamiento seguro de esta app y no se muestra en diagnósticos.'),
        CheckboxListTile(contentPadding: EdgeInsets.zero, value: consent,
          onChanged: (value) => setState(() => consent = value ?? false),
          title: const Text('Confío en este RPC y autorizo consultarlo desde el dispositivo.'),
          subtitle: const Text('El proveedor puede registrar la IP y las direcciones consultadas. Un RPC malicioso puede mentir aunque su chain ID coincida.')),
        if (error != null) Padding(padding: const EdgeInsets.all(12), child: Text(error!)),
        const SizedBox(height: 12),
        FilledButton(key: const Key('save-network'), onPressed: consent ? _submit : null,
          child: const Text('Verificar y guardar')),
        const SizedBox(height: 24),
      ]),
    ))),
  );
}
