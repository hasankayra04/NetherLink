import 'dart:async';
import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../l10n/app_localizations.dart';
import '../network/socket_handler.dart';
import '../network/broadcast_manager.dart';
import '../util/Logger.dart';
import '../util/user_servers.dart';
import '../util/user_servers_storage.dart';
import '../util/featured_servers.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import '../widgets/connection/connection_panel.dart';
import '../widgets/dialogs/manage_servers_dialog.dart';
import '../widgets/components/global_notice_banner.dart';
import '../widgets/components/app_toast.dart';
import '../services/notification_service.dart';
import '../services/region_detector.dart';
import '../services/featured_servers_service.dart';
import '../network/broadcast_mode.dart';
import '../widgets/navigation/bottom_nav_bar.dart';
import '../widgets/navigation/howto_menu.dart';
import '../widgets/navigation/help_menu.dart';
import '../services/navigation_controller.dart';
import '../services/locale_provider.dart';
import '../widgets/dialogs/howto_dialogs.dart';
import '../widgets/dialogs/help_dialogs.dart';
import 'partner_servers_screen.dart';

enum _ActiveSheet { none, help, howTo, more }

class HomeScreen extends StatefulWidget {
  final RelayPingResult? initialRelay;
  const HomeScreen({super.key, this.initialRelay});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final SocketHandler socketHandler;
  late final BroadcastManager _broadcastManager;
  late final Logger logger;
  late final NavigationController navigationController;
  late final Future<List<FeaturedServer>> _partnerServersFuture;

  final ValueNotifier<bool> _debugEnabledNotifier = ValueNotifier(false);
  final ValueNotifier<List<String>> _logsNotifier = ValueNotifier([]);
  final ValueNotifier<bool> _broadcastingNotifier = ValueNotifier(false);
  final ValueNotifier<List<UserServer>> _userServersNotifier = ValueNotifier(
    [],
  );

  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final ScrollController _logScrollController = ScrollController();
  final ScrollController _mainScrollController = ScrollController();

  bool _nintendoDnsMode = false;
  Map<String, String>? _currentNotice;
  Timer? _noticeTimer;
  int _pageIndex = 0;

  late RelayPingResult _selectedRelay;

  _ActiveSheet _activeSheet = _ActiveSheet.none;
  late final AnimationController _sheetAnimController;
  late final Animation<double> _sheetAnim;

  static String _friendNameForRelay(String relayName) => switch (relayName) {
    'EU Server' => 'NetherLinkEU',
    'US Server' => 'NetherLinkUS',
    _ => '-',
  };

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

    _initializeComponents();
    _loadUserServers();
    _fetchNotification();
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

  void _initializeComponents() {
    logger = Logger(debugEnabled: false, logCallback: _log);
    socketHandler = SocketHandler(logger: logger);
    _broadcastManager = BroadcastManager(
      socketHandler: socketHandler,
      logger: logger,
    );
    _broadcastManager.onAutoDisconnect = _handleAutoDisconnect;
    _broadcastManager.onRelayError = _handleRelayError;
  }

  void _initNavigationController() {
    navigationController = NavigationController(
      websiteUrl: AppConstants.websiteUrl,
      discordUrl: AppConstants.discordUrl,
      appLocaleNotifier: appLocale,
      logsNotifier: _logsNotifier,
      logsScrollController: _logScrollController,
      debugEnabledNotifier: _debugEnabledNotifier,
      toggleDebugCallback: _toggleDebugMode,
      copyLogsCallback: _copyLogsToClipboard,
      clearLogsCallback: _clearLogs,
      showXboxHelpCallback: _showXboxHelp,
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

  @override
  void dispose() {
    _noticeTimer?.cancel();
    _sheetAnimController.dispose();
    _ipController.dispose();
    _portController.dispose();
    _logScrollController.dispose();
    _mainScrollController.dispose();
    _logsNotifier.dispose();
    _broadcastingNotifier.dispose();
    _debugEnabledNotifier.dispose();
    _userServersNotifier.dispose();
    navigationController.consoleOpen.dispose();
    unawaited(_broadcastManager.stopBroadcast());
    super.dispose();
  }

  Future<void> _fetchNotification() async {
    final notice = await NotificationService.fetchNotice(_selectedRelay.base);
    if (!mounted || notice == null) return;
    setState(() => _currentNotice = notice);
    _noticeTimer?.cancel();
    _noticeTimer = Timer(const Duration(seconds: 20), () {
      if (mounted) setState(() => _currentNotice = null);
    });
  }

  Future<void> _loadUserServers() async {
    try {
      final servers = await UserServersStorage.loadServers();
      if (servers.isNotEmpty) {
        logger.debug('Loaded ${servers.length} saved server(s)');
      }
      _userServersNotifier.value = servers;
      _setDefaultServerIfNeeded(servers);
    } catch (e) {
      logger.error('Failed to load user servers: $e');
    }
  }

  void _setDefaultServerIfNeeded(List<UserServer> servers) {
    if (_ipController.text.trim().isNotEmpty || servers.isEmpty) return;
    _ipController.text = servers.first.address;
    _portController.text = servers.first.port.toString();
  }

  void _log(String message) {
    final current = _logsNotifier.value;
    final next = [
      if (current.length >= AppConstants.maxLogEntries)
        ...current.skip(current.length - AppConstants.maxLogEntries + 1),
      if (current.length < AppConstants.maxLogEntries) ...current,
      message,
    ];
    _logsNotifier.value = next;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients && mounted) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: AppConstants.animationDuration,
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  void _clearLogs() {
    _logsNotifier.value = [];
    logger.info('Console cleared');
  }

  Future<void> _copyLogsToClipboard() async {
    final loc = AppLocalizations.of(context)!;
    final logs = _logsNotifier.value;
    if (logs.isEmpty) {
      _snack(loc.noLogsToCopy, AppTheme.surfaceLight);
      return;
    }
    await Clipboard.setData(ClipboardData(text: logs.join('\n')));
    if (!mounted) return;
    _snack(
      loc.copiedLogs(logs.length),
      AppTheme.success,
      icon: Icons.check_circle_outline_rounded,
    );
  }

  Future<void> _startBroadcast(PanelMode mode) async {
    final loc = AppLocalizations.of(context)!;
    final remoteHost = _ipController.text.trim();
    final remotePortParsed = int.tryParse(_portController.text);

    if (remoteHost.isEmpty) {
      _snack(
        loc.pleaseEnterServer,
        AppTheme.warning,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }
    if (remotePortParsed == null ||
        remotePortParsed < 1 ||
        remotePortParsed > 65535) {
      _snack(
        loc.invalidPort,
        AppTheme.error,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    if (mode == PanelMode.nintendo || mode == PanelMode.friends) {
      await _handleDnsMode(mode, remoteHost, remotePortParsed, loc);
      return;
    }
    await _handleBroadcastMode(mode, remoteHost, remotePortParsed, loc);
  }

  Future<void> _handleDnsMode(
    PanelMode mode,
    String remoteHost,
    int remotePort,
    AppLocalizations loc,
  ) async {
    final ok = await _broadcastManager.sendRelayConfigOnly(
      remoteHost,
      remotePort,
      relayIp: _selectedRelay.ip,
      relayBase: _selectedRelay.base,
      mode: BroadcastMode.values[mode.index],
    );
    if (!ok) return;
    final relayName = _selectedRelay.name;
    if (mode == PanelMode.nintendo) {
      await HowToDialogs.showNintendoInstructions(
        context,
        relayName: relayName,
        relayIp: _selectedRelay.ip,
      );
    } else {
      await HowToDialogs.showFriendsInstructions(
        context,
        friendName: _friendNameForRelay(relayName),
      );
    }
  }

  Future<void> _handleBroadcastMode(
    PanelMode mode,
    String remoteHost,
    int remotePort,
    AppLocalizations loc,
  ) async {
    logger.info('Starting NetherLink');
    try {
      await WakelockPlus.enable();
    } catch (e) {
      logger.error('Failed to enable wakelock: $e');
    }
    final success = await _broadcastManager.startBroadcast(
      remoteHost,
      remotePort,
      relayIp: _selectedRelay.ip,
      relayBase: _selectedRelay.base,
      isJava: mode == PanelMode.java,
      mode: BroadcastMode.values[mode.index],
    );
    _broadcastingNotifier.value = success;
  }

  Future<void> _stopBroadcast() async {
    await _broadcastManager.stopBroadcast();
    _broadcastingNotifier.value = false;
  }

  void _handleAutoDisconnect() {
    if (!mounted) return;
    _broadcastingNotifier.value = false;
    _snack(
      AppLocalizations.of(context)!.clientDisconnected,
      AppTheme.info,
      icon: Icons.info_outline_rounded,
    );
    logger.info('Auto-disconnect: All clients inactive');
  }

  void _handleRelayError(String message) {
    if (!mounted) return;
    _snack(message, AppTheme.error, icon: Icons.error_outline_rounded);
  }

  void _toggleDebugMode() {
    final loc = AppLocalizations.of(context)!;
    final newVal = !_debugEnabledNotifier.value;
    _debugEnabledNotifier.value = newVal;
    logger.debugEnabled = newVal;
    logger.info('Debug mode ${newVal ? "enabled" : "disabled"}');
    _snack(
      newVal ? loc.debugEnabled : loc.debugDisabled,
      newVal ? AppTheme.success : AppTheme.surfaceLight,
      icon: newVal ? Icons.bug_report_rounded : Icons.bug_report_outlined,
    );
  }

  void _onUserServerSelected(UserServer server) {
    _ipController.text = server.address;
    _portController.text = server.port.toString();
    logger.info('Selected saved server: ${server.name}');
    _snack(
      AppLocalizations.of(context)!.selectedServer(server.name),
      AppTheme.accent,
      icon: Icons.bookmark_rounded,
    );
  }

  Future<void> _showManageServersDialog() async {
    await showDialog(
      context: context,
      builder: (_) => const ManageServersDialog(),
    );
    await _loadUserServers();
  }

  void _showXboxHelp() => HowToDialogs.showXboxInstructions(context);

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
    logger.info('Relay manually changed to: $ip');
  }

  void _snack(String message, Color color, {IconData? icon}) {
    if (!mounted) return;
    AppToast.show(context, message: message, icon: icon, color: color);
  }

  void _openPartnerServers() {
    setState(() => _pageIndex = 1);
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
            _openPartnerServers();
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                    child: SingleChildScrollView(
                      controller: _mainScrollController,
                      physics: const ClampingScrollPhysics(),
                      child: ValueListenableBuilder<List<UserServer>>(
                        valueListenable: _userServersNotifier,
                        builder: (context, userServers, _) => ConnectionPanel(
                          ipController: _ipController,
                          portController: _portController,
                          broadcastingNotifier: _broadcastingNotifier,
                          onStartBroadcast: _startBroadcast,
                          onStopBroadcast: _stopBroadcast,
                          savedServers: userServers,
                          onServerSelected: _onUserServerSelected,
                          onManageServers: _showManageServersDialog,
                          selectedRelayIp: _selectedRelay.ip,
                          onRelayChanged: _onRelayChanged,
                          nintendoDnsMode: _nintendoDnsMode,
                          onNintendoDnsModeChanged: (value) =>
                              setState(() => _nintendoDnsMode = value),
                          navigationController: navigationController,
                          partnerServersFuture: _partnerServersFuture,
                          onOpenPartnerServers: () =>
                              setState(() => _pageIndex = 1),
                        ),
                      ),
                    ),
                  ),
                  PartnerServersScreen(
                    partnerServersFuture: _partnerServersFuture,
                    ipController: _ipController,
                    portController: _portController,
                    onBack: () => setState(() => _pageIndex = 0),
                  ),
                ],
              ),

              if (_currentNotice != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: GlobalNoticeBanner(
                    message: _currentNotice!['message']!,
                    type: _currentNotice!['type'] ?? 'info',
                    onDismiss: () {
                      _noticeTimer?.cancel();
                      setState(() => _currentNotice = null);
                    },
                  ),
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
            _showXboxHelp();
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
