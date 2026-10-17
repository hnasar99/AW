import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'l10n/app_localizations.dart';

import 'screens/home_screen.dart';
import 'screens/caja_screen.dart';
import 'screens/agente_screen.dart';
import 'screens/rieles_screen.dart';
import 'screens/mas_screen.dart';
import 'screens/caja_pay_screen.dart';
import 'screens/caja_receive_screen.dart';
import 'screens/caja_passage_screen.dart';
import 'screens/caja_cap_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

GoRouter createRouter({
  required AppState appState,
  String? initialLocation,
}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation ?? '/inicio',
    debugLogDiagnostics: false,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return FluuixShell(
            navigationShell: navigationShell,
            appState: appState,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inicio',
                name: 'inicio',
                builder: (context, state) => HomeScreen(appState: appState),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/caja',
                name: 'caja',
                builder: (context, state) => CajaScreen(appState: appState),
                routes: [
                  GoRoute(
                    path: 'pagar',
                    name: 'caja-pagar',
                    builder: (context, state) =>
                        CajaPayScreen(appState: appState),
                  ),
                  GoRoute(
                    path: 'recibir',
                    name: 'caja-recibir',
                    builder: (context, state) =>
                        CajaReceiveScreen(appState: appState),
                  ),
                  GoRoute(
                    path: 'pasar',
                    name: 'caja-pasar',
                    builder: (context, state) =>
                        CajaPassageScreen(appState: appState),
                  ),
                  GoRoute(
                    path: 'tope',
                    name: 'caja-tope',
                    builder: (context, state) =>
                        CajaCapScreen(appState: appState),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/agente',
                name: 'agente',
                builder: (context, state) => AgenteScreen(appState: appState),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/rieles',
                name: 'rieles',
                builder: (context, state) => RielesScreen(appState: appState),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/mas',
                name: 'mas',
                builder: (context, state) => MasScreen(appState: appState),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class FluuixShell extends StatelessWidget {
  const FluuixShell({
    super.key,
    required this.navigationShell,
    required this.appState,
  });

  final StatefulNavigationShell navigationShell;
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.navInicio,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet),
            label: l10n.navCaja,
          ),
          NavigationDestination(
            icon: const Icon(Icons.psychology_outlined),
            selectedIcon: const Icon(Icons.psychology),
            label: l10n.navAgente,
          ),
          NavigationDestination(
            icon: const Icon(Icons.swap_horiz_outlined),
            selectedIcon: const Icon(Icons.swap_horiz),
            label: l10n.navRieles,
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz_outlined),
            selectedIcon: const Icon(Icons.more_horiz),
            label: l10n.navMas,
          ),
        ],
      ),
    );
  }
}

abstract class AppState extends ChangeNotifier {
  bool get networkVerified;
  bool get walletConnected;
  String? get walletAddress;
  int? get chainId;
  bool get supportsArc;
  BigInt? get balance;
  bool get busy;
  bool get agentReady;
  bool get agentBusy;
  bool get transferBlocked;
  bool get requestUncertain;
  dynamic get ledger;
  dynamic get transaction;
  dynamic get lastReview;
  dynamic get nativeStatus;
  String? get agentReply;
  List<String> get toolCalls;
  List<dynamic> get liveReads;
  dynamic get proposal;
  String? get error;
  String? get agentError;
  String? get settingsError;
  bool get configured;
  bool get storageReady;
  bool get requestPending;
  Locale? get selectedLocale;

  TextEditingController get recipientController;
  TextEditingController get amountController;
  TextEditingController get promptController;
  TextEditingController get projectIdController;
  TextEditingController get endpointController;
  TextEditingController get modelController;
  TextEditingController get keyController;
  TextEditingController get recoverHashController;
  bool get rememberKey;

  Future<void> checkNetwork();
  Future<void> refreshBalance();
  Future<void> connect();
  Future<void> disconnect();
  Future<void> addArc();
  Future<void> reviewAndSend();
  Future<void> recoverTransaction();
  Future<void> acknowledgeNoSend();
  Future<void> probeNative();
  Future<void> startAgent();
  Future<void> askAgent();
  Future<void> cancelAgent();
  Future<void> resetAgent();
  Future<void> configureWallet({bool persist = true});
  Future<void> saveLocale(Locale? locale);
  void applyProposal();
  Future<void> open(String url);
  void setRememberKey(bool? value);
  void noteEndpointEdited();
  Future<void> loadSettings();
}
