import 'dart:async';
import 'package:flutter/material.dart';
import '../services/navigation_controller.dart';
import '../services/locale_provider.dart';
import '../services/region_detector.dart';
import '../constants/app_constants.dart';
import '../widgets/navigation/bottom_nav_bar.dart';
import '../widgets/navigation/howto_menu.dart';
import '../widgets/navigation/help_menu.dart';
import '../widgets/dialogs/howto_dialogs.dart';
import '../widgets/dialogs/help_dialogs.dart';
import '../util/Logger.dart';
import '../util/partners_servers.dart';
import '../services/partners_servers_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'partner_servers_screen.dart';

enum _ActiveSheet { none, help, howTo, more }

class AppShell extends StatefulWidget {
  final RelayPingResult? initialRelay;
  const AppShell({super.key, this.initialRelay});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  late final NavigationController navigationController;
  late final Future<List<FeaturedServer>> _partnerServersFuture;
  late final Logger logger;

  final ValueNotifier<bool> _debugEnabledNotifier = ValueNotifier(false);
  final ValueNotifier<List<String>> _logsNotifier = ValueNotifier([]);
  final ScrollController _logScrollController = ScrollController();

  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();

  late RelayPingResult _selectedRelay;
  int _pageIndex = 0;

  _ActiveSheet _activeSheet = _ActiveSheet.none;
  late final AnimationController _sheetAnimController;
  late final Animation<double> _sheetAnim;

  @override
  void initState() {
    super.initState();
    _selectedRelay = widget.initialRelay ?? _fallbackRelay();
    _partnerServersFuture = FeaturedServersService.fetchFeaturedServers();

    _sheetAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _sheetAnim = CurvedAnimation(
      parent: _sheetAnimController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    logger = Logger(debugEnabled: false, logCallback: (_) {});
    _initNavigationController();
  }

  RelayPingResult _fallbackRelay() {
    final first = AppConstants.relayServers[0];
    return RelayPingResult(
      ip: first['ip']!,
      base: first['base']!,
      name: first['name']!,
      latencyMs: 999999,
    );
  }

  void _initNavigationController() {
    navigationController = NavigationController(
      websiteUrl: AppConstants.websiteUrl,
      discordUrl: AppConstants.discordUrl,
      appLocaleNotifier: appLocale,
      logsNotifier: _logsNotifier,
      logsScrollController: _logScrollController,
      debugEnabledNotifier: _debugEnabledNotifier,
      showHowToMenuCallback: (_) => _openSheet(_ActiveSheet.howTo),
      showHelpMenuCallback: (_) => _openSheet(_ActiveSheet.help),
    );
  }

  void _openSheet(_ActiveSheet sheet) {
    if (_activeSheet == sheet) return;
    setState(() => _activeSheet = sheet);
    _sheetAnimController.forward(from: 0);
  }

  Future<void> _closeSheet() async {
    if (_activeSheet == _ActiveSheet.none) return;
    await _sheetAnimController.reverse();
    if (mounted) setState(() => _activeSheet = _ActiveSheet.none);
  }

  void _onRelayChanged(String? ip) {
    if (ip == null) return;
    final matched = AppConstants.relayServers.firstWhere(
      (e) => e['ip'] == ip,
      orElse: () => AppConstants.relayServers[0],
    );
    setState(() {
      _selectedRelay = RelayPingResult(
        ip: matched['ip']!,
        base: matched['base']!,
        name: matched['name']!,
        latencyMs: 0,
      );
    });
  }

  static String _friendNameForRelay(String relayName) => switch (relayName) {
        'EU Server' => 'NetherLinkEU',
        'US Server' => 'NetherLinkUS',
        _ => '-',
      };

  @override
  void dispose() {
    _sheetAnimController.dispose();
    _logScrollController.dispose();
    _logsNotifier.dispose();
    _debugEnabledNotifier.dispose();
    _ipController.dispose();
    _portController.dispose();
    navigationController.consoleOpen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return PopScope(
      canPop: _pageIndex == 0 && _activeSheet == _ActiveSheet.none,
      onPopInvoked: (didPop) {
        if (!didPop) {
          if (_activeSheet != _ActiveSheet.none) {
            _closeSheet();
          } else {
            setState(() => _pageIndex = 0);
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        bottomNavigationBar: BottomGlassSimpleNavBar(
          navigationController: navigationController,
          dark: true,
          selectedRelayIp: _selectedRelay.ip,
          onRelayChanged: _onRelayChanged,
          onPartnerServersTap: () async {
            await _closeSheet();
            setState(() => _pageIndex = 1);
          },
          onAnyTap: _closeSheet,
          onHelpTapOverride: () async {
            if (_activeSheet == _ActiveSheet.help) return;
            await _closeSheet();
            _openSheet(_ActiveSheet.help);
          },
          onHowToTapOverride: () async {
            if (_activeSheet == _ActiveSheet.howTo) return;
            await _closeSheet();
            _openSheet(_ActiveSheet.howTo);
          },
          onMoreTapOverride: () async {
            if (_activeSheet == _ActiveSheet.more) return;
            await _closeSheet();
            _openSheet(_ActiveSheet.more);
          },
        ),
        body: SafeArea(
          top: true,
          bottom: false,
          child: Stack(
            children: [
              IndexedStack(
                index: _pageIndex,
                children: [
                  HomeScreen(
                    selectedRelay: _selectedRelay,
                    onRelayChanged: _onRelayChanged,
                    navigationController: navigationController,
                    partnerServersFuture: _partnerServersFuture,
                    onOpenPartnerServers: () =>
                        setState(() => _pageIndex = 1),
                    ipController: _ipController,
                    portController: _portController,
                  ),
                  PartnerServersScreen(
                    partnerServersFuture: _partnerServersFuture,
                    ipController: _ipController,
                    portController: _portController,
                    onBack: () => setState(() => _pageIndex = 0),
                  ),
                ],
              ),

              if (_activeSheet != _ActiveSheet.none) ...[
                AnimatedBuilder(
                  animation: _sheetAnim,
                  builder: (_, __) => GestureDetector(
                    onTap: _closeSheet,
                    child: Container(
                      color:
                          Colors.black.withOpacity(0.45 * _sheetAnim.value),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedBuilder(
                    animation: _sheetAnim,
                    builder: (_, child) => FractionalTranslation(
                      translation: Offset(0, 1 - _sheetAnim.value),
                      child: child,
                    ),
                    child: _buildActiveSheetContent(loc),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSheetContent(AppLocalizations loc) {
    switch (_activeSheet) {
      case _ActiveSheet.help:
        return HelpSheetContent(
          loc: loc,
          onClose: _closeSheet,
          onNetherLink: () {
            _closeSheet();
            HelpDialogs.showNetherlinkNotAppearing(context);
          },
          onMultiplayerFailed: () {
            _closeSheet();
            HelpDialogs.showMultiplayerConnectionFailed(context);
          },
          onNintendoDns: () {
            _closeSheet();
            HelpDialogs.showNintendoDns(context);
          },
          onFriendsMode: () {
            _closeSheet();
            HelpDialogs.showFriendsMode(context);
          },
        );
      case _ActiveSheet.howTo:
        return HowToSheetContent(
          loc: loc,
          onClose: _closeSheet,
          onXbox: () {
            _closeSheet();
            HowToDialogs.showXboxInstructions(context);
          },
          onNintendo: () {
            _closeSheet();
            HowToDialogs.showNintendoInstructions(
              context,
              relayName: _selectedRelay.name,
              relayIp: _selectedRelay.ip,
            );
          },
          onFriends: () {
            _closeSheet();
            HowToDialogs.showFriendsInstructions(
              context,
              friendName: _friendNameForRelay(_selectedRelay.name),
            );
          },
          onJava: () {
            _closeSheet();
            HowToDialogs.showJavaInstructions(context);
          },
        );
      case _ActiveSheet.more:
        return MoreSheetContent(
          loc: loc,
          navigationController: navigationController,
          selectedRelayIp: _selectedRelay.ip,
          onClose: _closeSheet,
          onRelayChanged: (ip) {
            _closeSheet();
            _onRelayChanged(ip);
          },
          onHowTo: () {
            _closeSheet();
            Future.delayed(
              const Duration(milliseconds: 200),
              () => _openSheet(_ActiveSheet.howTo),
            );
          },
        );
      case _ActiveSheet.none:
        return const SizedBox.shrink();
    }
  }
}