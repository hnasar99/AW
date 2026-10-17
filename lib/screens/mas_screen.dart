import 'package:flutter/material.dart';

import '../domain/arc.dart';
import '../domain/inference_config.dart';
import '../l10n/app_localizations.dart';
import '../router.dart';
import '../ui/context_bar.dart';
import '../ui/theme.dart';

class MasScreen extends StatelessWidget {
  const MasScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) => SafeArea(
        child: Column(
          children: [
            if (!awLabTextOnly)
              FluuixContextBar(
                activeLayer: l10n.navMas,
                chainName: 'Arc Testnet',
                rpcConnected: appState.networkVerified,
                railName: 'Twin · ARGt',
                walletConnected: appState.walletConnected,
                walletAddress: appState.walletAddress,
                isTestnet: true,
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    awLabTextOnly ? l10n.settingsLabTitle : l10n.settingsTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _buildLanguageCard(context, l10n),
                  const SizedBox(height: 16),
                  if (!awLabTextOnly) _buildWalletConnectCard(context, l10n),
                  if (!awLabTextOnly) const SizedBox(height: 16),
                  _buildInferenceCard(context, l10n),
                  const SizedBox(height: 16),
                  if (!awLabTextOnly) _buildArcManualCard(context, l10n),
                  if (appState.settingsError != null)
                    _errorBox(appState.settingsError!),
                  if (!appState.storageReady && !appState.busy)
                    TextButton(
                      onPressed: appState.loadSettings,
                      child: Text(l10n.retrySecureStorage),
                    ),
                  if (appState.agentError != null)
                    _errorBox(appState.agentError!),
                  const SizedBox(height: 16),
                  _buildNetworkModulesSection(context, l10n),
                  const SizedBox(height: 24),
                  Text(
                    awLabTextOnly ? l10n.footerLab : l10n.footerArcTestnet,
                    style: const TextStyle(
                      color: FluuixColors.textMuted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard(BuildContext context, AppLocalizations l10n) {
    return _card(
      children: [
        Text(
          l10n.languageSettings,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: appState.selectedLocale?.languageCode,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(l10n.languageAuto),
            ),
            DropdownMenuItem<String>(value: 'es', child: Text(l10n.languageSpanish)),
            DropdownMenuItem<String>(value: 'en', child: Text(l10n.languageEnglish)),
            DropdownMenuItem<String>(value: 'pt', child: Text(l10n.languagePortuguese)),
            DropdownMenuItem<String>(value: 'fr', child: Text(l10n.languageFrench)),
            DropdownMenuItem<String>(value: 'de', child: Text(l10n.languageGerman)),
            DropdownMenuItem<String>(value: 'it', child: Text(l10n.languageItalian)),
            DropdownMenuItem<String>(value: 'zh', child: Text(l10n.languageChinese)),
          ],
          onChanged: (value) {
            appState.saveLocale(value == null ? null : Locale(value));
          },
        ),
      ],
    );
  }

  Widget _buildWalletConnectCard(BuildContext context, AppLocalizations l10n) {
    return _card(
      children: [
        Text(
          l10n.walletConnectTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text(l10n.walletConnectDescription),
        const SizedBox(height: 12),
        TextField(
          controller: appState.projectIdController,
          autocorrect: false,
          enableSuggestions: false,
          enabled: !appState.busy && !appState.requestPending,
          decoration: InputDecoration(
            labelText: l10n.projectIdLabel,
            hintText: l10n.projectIdHint,
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: appState.busy || appState.requestPending
              ? null
              : () => appState.configureWallet(),
          child: Text(appState.busy ? l10n.connecting : l10n.saveAndConnectReown),
        ),
        if (appState.configured)
          Text(
            l10n.reownClientInitialized,
            style: const TextStyle(color: FluuixColors.success),
          ),
      ],
    );
  }

  Widget _buildInferenceCard(BuildContext context, AppLocalizations l10n) {
    return _card(
      children: [
        Text(
          awLabTextOnly ? l10n.inferenceLabTitle : l10n.inferenceTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text(
          awLabTextOnly
              ? l10n.inferenceLabDescription
              : l10n.inferenceDescription,
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('inference-endpoint'),
          controller: appState.endpointController,
          enabled: !appState.agentReady && !appState.agentBusy,
          autocorrect: false,
          keyboardType: TextInputType.url,
          enableSuggestions: false,
          onChanged: (_) => appState.noteEndpointEdited(),
          decoration: InputDecoration(
            labelText:
                awLabTextOnly ? l10n.endpointLabLabel : l10n.endpointLabel,
            hintText: awLabTextOnly ? l10n.endpointLabHint : l10n.endpointHint,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('inference-model'),
          controller: appState.modelController,
          enabled: !appState.agentReady && !appState.agentBusy,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: l10n.modelLabel,
            hintText: awLabTextOnly ? l10n.modelLabHint : l10n.modelHint,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('inference-key'),
          controller: appState.keyController,
          enabled: !appState.agentReady && !appState.agentBusy,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: awLabTextOnly ? l10n.apiKeyLabLabel : l10n.apiKeyLabel,
            helperText: awLabTextOnly ? l10n.apiKeyLabHelper : null,
            helperMaxLines: 2,
          ),
        ),
        Material(
          color: Colors.transparent,
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: appState.rememberKey,
            onChanged:
                appState.agentReady || appState.agentBusy
                    ? null
                    : appState.setRememberKey,
            title: Text(l10n.rememberKey),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          awLabTextOnly
              ? l10n.labQueriesNote
              : l10n.queriesSentTo(
                  Uri.tryParse(appState.endpointController.text)?.host ??
                      'your provider',
                ),
          style: const TextStyle(color: FluuixColors.textMuted),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed:
              appState.agentReady || appState.agentBusy
                  ? null
                  : appState.startAgent,
          child: Text(
            appState.agentBusy
                ? l10n.initializing
                : awLabTextOnly
                    ? l10n.startLabButton
                    : l10n.activateOpenHumanButton,
          ),
        ),
        OutlinedButton(
          onPressed: appState.agentBusy ? null : appState.resetAgent,
          child: Text(l10n.stopAgentForgetKey),
        ),
      ],
    );
  }

  Widget _buildArcManualCard(BuildContext context, AppLocalizations l10n) {
    return ExpansionTile(
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
                  appState.open('https://docs.arc.io/arc/references/connect-to-arc'),
              child: Text(l10n.officialDocs),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNetworkModulesSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.networkTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.networkDescription,
          style: const TextStyle(color: FluuixColors.textMuted, height: 1.45),
        ),
        const SizedBox(height: 16),
        _module(l10n.zonaBankTitle, l10n.zonaBankDesc, 'https://fluuix.com/zonabank', l10n),
        _module(l10n.lendingTitle, l10n.lendingDesc, 'https://fluuix.com/ecosystem', l10n),
        _module(l10n.zonaFrancaTitle, l10n.zonaFrancaDesc, 'https://fluuix.com/zf', l10n),
        _module(l10n.ttnTitle, l10n.ttnDesc, 'https://fluuix.com/ttn', l10n),
        const SizedBox(height: 8),
        Text(l10n.capitalSection, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        _module(l10n.fideicomisosTitle, l10n.fideicomisosDesc, 'https://fluuix.com/fideicomiso', l10n),
        _module(l10n.fondosTitle, l10n.fondosDesc, 'https://fluuix.com/fondos', l10n),
        _module(l10n.crowdTitle, l10n.crowdDesc, 'https://fluuix.com/financiamiento', l10n),
        _module(l10n.licitacionesTitle, l10n.licitacionesDesc, 'https://fluuix.com/licitaciones', l10n),
        _module(l10n.donacionesTitle, l10n.donacionesDesc, 'https://fluuix.com/donaciones', l10n),
        _module(l10n.academiaTitle, l10n.academiaDesc, 'https://fluuix.com/academia', l10n),
      ],
    );
  }

  Widget _module(String title, String body, String url, AppLocalizations l10n) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _card(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                Text(
                  l10n.noContract,
                  style: const TextStyle(color: FluuixColors.gold, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(body, style: const TextStyle(color: FluuixColors.textMuted, height: 1.4)),
            TextButton(
              onPressed: () => appState.open(url),
              child: Text(l10n.whatProductPublishes),
            ),
          ],
        ),
      );

  Widget _card({required List<Widget> children}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: FluuixColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: FluuixColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );

  Widget _errorBox(String message) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FluuixColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FluuixColors.error.withValues(alpha: 0.3)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: FluuixColors.error, height: 1.4),
      ),
    ),
  );
}
