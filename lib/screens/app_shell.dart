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
import 'manage_servers_screen.dart';

enum _ActiveSheet { none, help, howTo, more }

const int _pageHome = 0;
const int _pagePartners = 1;
const int _pageManageServers = 2;
const int _pageAddEditServer = 3;

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

  final GlobalKey<ManageServersScreenState> _manageServersKey = GlobalKey();

  late RelayPingResult _selectedRelay;
  int _pageIndex = _pageHome;
  int? _editingServerIndex;

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
    if (_activeSheet == sheet) {
      _closeSheet();
      return;
    }
    setState(() => _activeSheet = sheet);
    _sheetAnimController.forward(from: 0);
  }

  Future<void> _closeSheet() async {
    if (_activeSheet == _ActiveSheet.none) return;
    await _sheetAnimController.reverse();
    if (mounted) setState(() => _activeSheet = _ActiveSheet.none);
  }

  void _closeSheetInstant() {
    _sheetAnimController.stop();
    _sheetAnimController.value = 0;
    setState(() => _activeSheet = _ActiveSheet.none);
  }

  void _goTo(int page) {
    _closeSheetInstant();
    setState(() => _pageIndex = page);
  }

  void _openManageServers() => _goTo(_pageManageServers);

  void _openAddServer() {
    setState(() {
      _editingServerIndex = null;
      _pageIndex = _pageAddEditServer;
    });
  }

  void _openEditServer(int index) {
    setState(() {
      _editingServerIndex = index;
      _pageIndex = _pageAddEditServer;
    });
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

  String? get _activeNavItem {
    if (_pageIndex == _pageHome && _activeSheet == _ActiveSheet.none) {
      return 'home';
    }
    if (_pageIndex == _pagePartners) return 'partners';
    switch (_activeSheet) {
      case _ActiveSheet.help:
        return 'support';
      case _ActiveSheet.more:
        return 'more';
      case _ActiveSheet.howTo:
      case _ActiveSheet.none:
        return null;
    }
  }

  bool get _canPop =>
      _pageIndex == _pageHome && _activeSheet == _ActiveSheet.none;

  void _handlePop() {
    if (_activeSheet != _ActiveSheet.none) {
      _closeSheet();
    } else if (_pageIndex == _pageAddEditServer) {
      setState(() => _pageIndex = _pageManageServers);
    } else if (_pageIndex != _pageHome) {
      _goTo(_pageHome);
    }
  }

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
      canPop: _canPop,
      onPopInvoked: (didPop) {
        if (!didPop) _handlePop();
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        bottomNavigationBar: BottomGlassSimpleNavBar(
          navigationController: navigationController,
          dark: true,
          selectedRelayIp: _selectedRelay.ip,
          onRelayChanged: _onRelayChanged,
          activeItem: _activeNavItem,
          onHomeTap: () => _goTo(_pageHome),
          onPartnerServersTap: () => _goTo(_pagePartners),
          onAnyTap: null,
          onHelpTapOverride: () {
            if (_activeSheet == _ActiveSheet.help) {
              _closeSheet();
            } else {
              _closeSheetInstant();
              _openSheet(_ActiveSheet.help);
            }
          },
          onMoreTapOverride: () {
            if (_activeSheet == _ActiveSheet.more) {
              _closeSheet();
            } else {
              _closeSheetInstant();
              _openSheet(_ActiveSheet.more);
            }
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
                    onOpenPartnerServers: () => _goTo(_pagePartners),
                    onOpenManageServers: _openManageServers,
                    ipController: _ipController,
                    portController: _portController,
                  ),
                  PartnerServersScreen(
                    partnerServersFuture: _partnerServersFuture,
                    ipController: _ipController,
                    portController: _portController,
                    onBack: () => _goTo(_pageHome),
                  ),
                  ManageServersScreen(
                    key: _manageServersKey,
                    onBack: () => _goTo(_pageHome),
                    onAddServer: _openAddServer,
                    onEditServer: _openEditServer,
                  ),
                  AddEditServerScreen(
                    editingIndex: _editingServerIndex,
                    onSaved: () {
                      _manageServersKey.currentState?.reload();
                      setState(() => _pageIndex = _pageManageServers);
                    },
                    onCancel: () =>
                        setState(() => _pageIndex = _pageManageServers),
                  ),
                ],
              ),

              if (_activeSheet != _ActiveSheet.none) ...[
                AnimatedBuilder(
                  animation: _sheetAnim,
                  builder: (_, __) => GestureDetector(
                    onTap: _closeSheet,
                    child: Container(
                      color: Colors.black.withOpacity(0.45 * _sheetAnim.value),
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
            _closeSheetInstant();
            HelpDialogs.showNetherlinkNotAppearing(context);
          },
          onMultiplayerFailed: () {
            _closeSheetInstant();
            HelpDialogs.showMultiplayerConnectionFailed(context);
          },
          onNintendoDns: () {
            _closeSheetInstant();
            HelpDialogs.showNintendoDns(context);
          },
          onFriendsMode: () {
            _closeSheetInstant();
            HelpDialogs.showFriendsMode(context);
          },
        );
      case _ActiveSheet.howTo:
        return HowToSheetContent(
          loc: loc,
          onClose: _closeSheet,
          onXbox: () {
            _closeSheetInstant();
            HowToDialogs.showXboxInstructions(context);
          },
          onNintendo: () {
            _closeSheetInstant();
            HowToDialogs.showNintendoInstructions(
              context,
              relayName: _selectedRelay.name,
              relayIp: _selectedRelay.ip,
            );
          },
          onFriends: () {
            _closeSheetInstant();
            HowToDialogs.showFriendsInstructions(
              context,
              friendName: _friendNameForRelay(_selectedRelay.name),
            );
          },
          onJava: () {
            _closeSheetInstant();
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
            _closeSheetInstant();
            _onRelayChanged(ip);
          },
          onHowTo: () {
            _closeSheetInstant();
            Future.delayed(
              const Duration(milliseconds: 50),
              () => _openSheet(_ActiveSheet.howTo),
            );
          },
          onDiscord: () {
            _closeSheetInstant();
            navigationController.openDiscord(context);
          },
          onConsole: () {
            _closeSheetInstant();
            navigationController.showConsole(context);
          },
          onWebsite: () {
            _closeSheetInstant();
            navigationController.openWebsite(context);
          },
          onLanguage: () {
            _closeSheetInstant();
            navigationController.showLanguageDialog(context);
          },
          onAternos: () {
            _closeSheetInstant();
            navigationController.openWebsiteWithCustomUrl(
              context,
              'https://aternos.org/',
            );
          },
        );
      case _ActiveSheet.none:
        return const SizedBox.shrink();
    }
  }
}
