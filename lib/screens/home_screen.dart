import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../l10n/app_localizations.dart';
import '../network/socket_handler.dart';
import '../network/broadcast_manager.dart';
import '../util/Logger.dart';
import '../util/user_servers.dart';
import '../util/user_servers_storage.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import '../widgets/connection/connection_panel.dart';
import '../widgets/dialogs/manage_servers_dialog.dart';
import '../widgets/components/global_notice_banner.dart';
import '../services/notification_service.dart';
import '../services/region_detector.dart';
import '../network/broadcast_mode.dart';
import '../widgets/navigation/bottom_nav_bar.dart';
import '../widgets/navigation/howto_menu.dart';
import '../widgets/navigation/help_menu.dart';
import '../services/navigation_controller.dart';
import '../services/locale_provider.dart';
import '../widgets/dialogs/howto_dialogs.dart';
import '../widgets/dialogs/help_dialogs.dart';

class HomeScreen extends StatefulWidget {
  final RelayPingResult? initialRelay;
  const HomeScreen({super.key, this.initialRelay});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final SocketHandler socketHandler;
  late final BroadcastManager _broadcastManager;
  late final Logger logger;

  final ValueNotifier<bool> _debugEnabledNotifier = ValueNotifier(false);
  bool _nintendoDnsMode = false;

  Map<String, String>? _currentNotice;
  Timer? _noticeTimer;

  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final ScrollController _logScrollController = ScrollController();
  final ScrollController _mainScrollController = ScrollController();

  final ValueNotifier<List<String>> _logsNotifier = ValueNotifier([]);
  final ValueNotifier<bool> _broadcastingNotifier = ValueNotifier(false);
  final ValueNotifier<List<UserServer>> _userServersNotifier = ValueNotifier(
    [],
  );

  late RelayPingResult _selectedRelay;
  late final NavigationController navigationController;

  @override
  void initState() {
    super.initState();
    _selectedRelay = widget.initialRelay ?? _fallbackRelay();
    _initializeComponents();
    _loadUserServers();
    _fetchNotification();

    navigationController = NavigationController(
      websiteUrl: AppConstants.websiteUrl,
      discordUrl: AppConstants.discordUrl,
      appLocaleNotifier: appLocale,
      logsNotifier: _logsNotifier,
      logsScrollController: _logScrollController,
      debugEnabledNotifier: _debugEnabledNotifier,
      toggleDebugCallback: () async => _toggleDebugMode(),
      copyLogsCallback: () async => _copyLogsToClipboard(),
      clearLogsCallback: _clearLogs,
      showXboxHelpCallback: _showXboxHelp,
      showHowToMenuCallback: (ctx) {
        final relayName = _selectedRelay.name;
        final relayIp = _selectedRelay.ip;
        final friendName = relayName == 'EU Server'
            ? 'NetherLinkEU'
            : relayName == 'US Server'
            ? 'NetherLinkUS'
            : '-';
        HowToMenu.show(
          ctx,
          onXbox: _showXboxHelp,
          onNintendo: () => HowToDialogs.showNintendoInstructions(
            context,
            relayName: relayName,
            relayIp: relayIp,
          ),
          onFriends: () => HowToDialogs.showFriendsInstructions(
            context,
            friendName: friendName,
          ),
          onJava: () => HowToDialogs.showJavaInstructions(context),
        );
      },
      showHelpMenuCallback: (ctx) {
        HelpMenu.show(
          ctx,
          onNetherLink: () => HelpDialogs.showNetherlinkNotAppearing(ctx),
          onMultiplayerFailed: () =>
              HelpDialogs.showMultiplayerConnectionFailed(ctx),
          onNintendoDns: () => HelpDialogs.showNintendoDns(ctx),
          onFriendsMode: () => HelpDialogs.showFriendsMode(ctx),
        );
      },
    );
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

  @override
  void dispose() {
    _noticeTimer?.cancel();
    _ipController.dispose();
    _portController.dispose();
    _logScrollController.dispose();
    _mainScrollController.dispose();
    _logsNotifier.dispose();
    _broadcastingNotifier.dispose();
    _debugEnabledNotifier.dispose();
    _userServersNotifier.dispose();
    navigationController.consoleOpen.dispose();
    _broadcastManager.stopBroadcast();
    super.dispose();
  }

  void _initializeComponents() {
    logger = Logger(
      debugEnabled: _debugEnabledNotifier.value,
      logCallback: _log,
    );
    socketHandler = SocketHandler(logger: logger);
    _broadcastManager = BroadcastManager(
      socketHandler: socketHandler,
      logger: logger,
    );
    _broadcastManager.onAutoDisconnect = _handleAutoDisconnect;
    _broadcastManager.onRelayError = _handleRelayError;
  }

  Future<void> _fetchNotification() async {
    final notice = await NotificationService.fetchNotice(_selectedRelay.base);
    if (mounted && notice != null) {
      setState(() => _currentNotice = notice);
      _noticeTimer?.cancel();
      _noticeTimer = Timer(const Duration(seconds: 20), () {
        if (mounted) setState(() => _currentNotice = null);
      });
    }
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
    if (_ipController.text.trim().isNotEmpty) return;
    if (servers.isNotEmpty) {
      _ipController.text = servers.first.address;
      _portController.text = servers.first.port.toString();
    }
  }

  void _log(String message) {
    final logs = List<String>.from(_logsNotifier.value)..add(message);
    if (logs.length > AppConstants.maxLogEntries) {
      logs.removeRange(0, logs.length - AppConstants.maxLogEntries);
    }
    _logsNotifier.value = logs;
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
      final ok = await _broadcastManager.sendRelayConfigOnly(
        remoteHost,
        remotePortParsed,
        relayIp: _selectedRelay.ip,
        relayBase: _selectedRelay.base,
        mode: BroadcastMode.values[mode.index],
      );
      if (ok) {
        _snack(
          loc.dnsConfigSent,
          AppTheme.accent,
          icon: Icons.check_circle_outline_rounded,
        );
        final relayName = _selectedRelay.name;
        final relayIp = _selectedRelay.ip;
        final friendName = relayName == 'EU Server'
            ? 'NetherLinkEU'
            : relayName == 'US Server'
            ? 'NetherLinkUS'
            : '-';
        if (mode == PanelMode.nintendo) {
          await HowToDialogs.showNintendoInstructions(
            context,
            relayName: relayName,
            relayIp: relayIp,
          );
        } else {
          await HowToDialogs.showFriendsInstructions(
            context,
            friendName: friendName,
          );
        }
      }
      return;
    }

    logger.info('Starting NetherLink');
    try {
      await WakelockPlus.enable();
    } catch (e) {
      logger.error('Failed to enable wakelock: $e');
    }

    final success = await _broadcastManager.startBroadcast(
      remoteHost,
      remotePortParsed,
      relayIp: _selectedRelay.ip,
      relayBase: _selectedRelay.base,
      isJava: mode == PanelMode.java,
      mode: BroadcastMode.values[mode.index],
    );
    _broadcastingNotifier.value = _broadcastManager.isBroadcasting;

    if (_broadcastManager.isBroadcasting && success) {
      _snack(
        AppLocalizations.of(context)!.broadcastingStarted,
        AppTheme.success,
        icon: Icons.check_circle_outline_rounded,
      );
    }
  }

  Future<void> _stopBroadcast() async {
    await _broadcastManager.stopBroadcast();
    _broadcastingNotifier.value = false;
    if (mounted) {
      _snack(
        AppLocalizations.of(context)!.broadcastStopped,
        AppTheme.surfaceLight,
        icon: Icons.stop_circle_outlined,
      );
    }
  }

  void _handleAutoDisconnect() {
    if (!mounted) return;
    setState(() => _broadcastingNotifier.value = false);
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
    setState(() {});
    logger.debugEnabled = newVal;
    logger.info('Debug mode ${newVal ? "enabled" : "disabled"}');
    _snack(
      newVal ? loc.debugEnabled : loc.debugDisabled,
      newVal ? AppTheme.success : AppTheme.surfaceLight,
      icon: newVal ? Icons.bug_report_rounded : Icons.bug_report_outlined,
    );
  }

  void _onUserServerSelected(UserServer server) {
    setState(() {
      _ipController.text = server.address;
      _portController.text = server.port.toString();
    });
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
    _loadUserServers();
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            if (_currentNotice != null)
              GlobalNoticeBanner(
                message: _currentNotice!['message']!,
                type: _currentNotice!['type'] ?? 'info',
                onDismiss: () {
                  _noticeTimer?.cancel();
                  setState(() => _currentNotice = null);
                },
              ),

            Expanded(
              child: Padding(
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
                    ),
                  ),
                ),
              ),
            ),

            BottomGlassSimpleNavBar(
              navigationController: navigationController,
              dark: true,
              selectedRelayIp: _selectedRelay.ip,
              onRelayChanged: _onRelayChanged,
            ),
          ],
        ),
      ),
    );
  }
}
