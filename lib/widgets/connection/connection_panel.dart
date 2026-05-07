import 'dart:async';
import 'dart:math' as Math;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../util/user_servers.dart';
import '../../util/featured_servers.dart';
import '../../services/featured_servers_service.dart';
import '../../services/server_status_service.dart';
import 'my_servers_tab.dart';
import 'partner_servers_tab.dart';

enum PanelMode { lan, nintendo, friends, java }

class _ModeConfig {
  final PanelMode mode;
  final FaIconData icon;
  final Color color;
  const _ModeConfig({
    required this.mode,
    required this.icon,
    required this.color,
  });
}

class ConnectionPanel extends StatefulWidget {
  const ConnectionPanel({
    super.key,
    required this.ipController,
    required this.portController,
    required this.broadcastingNotifier,
    required this.onStartBroadcast,
    required this.onStopBroadcast,
    required this.savedServers,
    required this.onServerSelected,
    required this.onManageServers,
    required this.selectedRelayIp,
    required this.onRelayChanged,
    required this.nintendoDnsMode,
    required this.onNintendoDnsModeChanged,
  });

  final TextEditingController ipController;
  final TextEditingController portController;
  final ValueNotifier<bool> broadcastingNotifier;
  final Future<void> Function(PanelMode) onStartBroadcast;
  final VoidCallback onStopBroadcast;
  final List<UserServer> savedServers;
  final Function(UserServer) onServerSelected;
  final VoidCallback onManageServers;
  final String? selectedRelayIp;
  final void Function(String?) onRelayChanged;
  final bool nintendoDnsMode;
  final ValueChanged<bool> onNintendoDnsModeChanged;

  @override
  State<ConnectionPanel> createState() => _ConnectionPanelState();
}

class _ConnectionPanelState extends State<ConnectionPanel> {
  PanelMode _mode = PanelMode.lan;
  int _tab = 0;

  Future<List<FeaturedServer>>? _featuredFuture;
  List<FeaturedServer> _featuredServers = [];
  late final PageController _heroBgController;
  int _heroBgPage = 0;
  Timer? _heroTimer;

  final Map<String, Future<ServerStatus>> _statusCache = {};

  Future<ServerStatus> _getHeroStatus(FeaturedServer server) {
    final key = '${server.address}:${server.port}';
    return _statusCache.putIfAbsent(
      key,
      () => ServerStatusService.getStatus(server.address, server.port),
    );
  }

  static const _modes = [
    _ModeConfig(
      mode: PanelMode.lan,
      icon: FontAwesomeIcons.xbox,
      color: AppTheme.modeXbox,
    ),
    _ModeConfig(
      mode: PanelMode.nintendo,
      icon: FontAwesomeIcons.gamepad,
      color: AppTheme.modeNintendo,
    ),
    _ModeConfig(
      mode: PanelMode.friends,
      icon: FontAwesomeIcons.userGroup,
      color: AppTheme.modeFriends,
    ),
    _ModeConfig(
      mode: PanelMode.java,
      icon: FontAwesomeIcons.java,
      color: AppTheme.modeJava,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _heroBgController = PageController();
    _mode = widget.nintendoDnsMode ? PanelMode.nintendo : PanelMode.lan;

    _featuredFuture = FeaturedServersService.fetchFeaturedServers();
    _featuredFuture!.then((list) {
      if (!mounted || list.isEmpty) return;
      setState(() => _featuredServers = List.from(list)..shuffle(Random()));
      _startHeroTimer();
    });
  }

  void _startHeroTimer() {
    _heroTimer?.cancel();
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _featuredServers.isEmpty) return;
      final next = (_heroBgPage + 1) % _featuredServers.length;
      _heroBgController.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _heroBgController.dispose();
    _heroTimer?.cancel();
    super.dispose();
  }

  FeaturedServer? get _currentHeroServer => _featuredServers.isEmpty
      ? null
      : _featuredServers[_heroBgPage % _featuredServers.length];

  String _modeLabel(PanelMode mode, AppLocalizations loc) {
    switch (mode) {
      case PanelMode.lan:
        return loc.labelXbox;
      case PanelMode.nintendo:
        return loc.labelNintendo;
      case PanelMode.friends:
        return loc.labelFriends;
      case PanelMode.java:
        return loc.labelJava;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ValueListenableBuilder<bool>(
          valueListenable: widget.broadcastingNotifier,
          builder: (context, broadcasting, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHero(broadcasting, loc),
              const SizedBox(height: 22),
              _sectionLabel('SELECT MODE'),
              const SizedBox(height: 10),
              _buildModeChips(broadcasting, loc),
              const SizedBox(height: 12),
              _buildBroadcastCard(broadcasting, loc),
              const SizedBox(height: 22),
              _buildServersHeader(broadcasting),
              const SizedBox(height: 10),
              _buildServersBody(broadcasting),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(bool broadcasting, AppLocalizations loc) {
    final server = _currentHeroServer;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 230,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _featuredServers.isEmpty
                ? _defaultHeroBg()
                : PageView.builder(
                    controller: _heroBgController,
                    onPageChanged: (i) => setState(() => _heroBgPage = i),
                    itemCount: _featuredServers.length,
                    itemBuilder: (_, i) {
                      final url = _featuredServers[i].iconUrl;
                      if (url != null && url.isNotEmpty) {
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            _defaultHeroBg(),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Image.network(
                                url,
                                height: double.infinity,
                                fit: BoxFit.fitHeight,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  stops: [0.0, 0.45, 0.72, 1.0],
                                  colors: [
                                    Color(0xFF0D0B1E),
                                    Color(0xEE0D0B1E),
                                    Color(0x660D0B1E),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return _defaultHeroBg();
                    },
                  ),

            const CustomPaint(painter: _HeroNoisePainter()),
            const CustomPaint(painter: _HeroWavePainter()),

            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.4, 1.0],
                  colors: [
                    Color(0x55000000),
                    Color(0x00000000),
                    Color(0xBB000000),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _heroBadge(
                        icon: Icons.star_rounded,
                        label: 'FEATURED SERVER',
                      ),
                      const Spacer(),
                      if (_featuredServers.length > 1)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            _featuredServers.length.clamp(0, 6),
                            (i) {
                              final active =
                                  i == _heroBgPage % _featuredServers.length;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(left: 4),
                                width: active ? 14 : 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: active
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),

                  const Spacer(),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              server?.name ?? 'NetherLink',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                color: Colors.white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 220),
                              child: Text(
                                server?.description.isNotEmpty == true
                                    ? server!.description
                                    : 'Connect and start your adventure.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.60),
                                  fontSize: 11,
                                  height: 1.5,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 10),

                            if (server != null)
                              _HeroStatusBadge(
                                statusFuture: _getHeroStatus(server),
                              )
                            else
                              _staticStatusBadge(
                                dot: AppTheme.textMuted,
                                label: '...',
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      GestureDetector(
                        onTap: server == null || broadcasting
                            ? null
                            : () {
                                widget.ipController.text = server.address;
                                widget.portController.text = server.port
                                    .toString();
                                widget.onStartBroadcast(_mode);
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(
                              server == null || broadcasting ? 0.08 : 0.15,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(
                                server == null || broadcasting ? 0.10 : 0.30,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Connect',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(
                                    server == null || broadcasting ? 0.35 : 1.0,
                                  ),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white.withOpacity(
                                  server == null || broadcasting ? 0.35 : 1.0,
                                ),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultHeroBg() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0D0D28), Color(0xFF16113A), Color(0xFF0A1830)],
      ),
    ),
  );

  Widget _heroBadge({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppTheme.accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _staticStatusBadge({required Color dot, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChips(bool broadcasting, AppLocalizations loc) {
    return Row(
      children: List.generate(_modes.length, (i) {
        final cfg = _modes[i];
        final isSelected = cfg.mode == _mode;
        final dimmed = broadcasting && !isSelected;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < _modes.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: broadcasting || isSelected
                  ? null
                  : () {
                      setState(() => _mode = cfg.mode);
                      widget.onNintendoDnsModeChanged(
                        cfg.mode == PanelMode.nintendo ||
                            cfg.mode == PanelMode.friends,
                      );
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 84,
                decoration: BoxDecoration(
                  color: isSelected
                      ? cfg.color.withOpacity(0.10)
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? cfg.color.withOpacity(0.45)
                        : AppTheme.borderGray,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      cfg.icon,
                      size: 24,
                      color: isSelected
                          ? cfg.color
                          : dimmed
                          ? AppTheme.textDisabled
                          : AppTheme.textMuted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _modeLabel(cfg.mode, loc),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? cfg.color
                            : dimmed
                            ? AppTheme.textDisabled
                            : AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBroadcastCard(bool broadcasting, AppLocalizations loc) {
    final cfg = _modes.firstWhere((c) => c.mode == _mode);
    final color = broadcasting ? AppTheme.error : cfg.color;

    String buttonLabel;
    if (broadcasting) {
      buttonLabel = loc.stopBroadcasting;
    } else {
      switch (_mode) {
        case PanelMode.lan:
          buttonLabel = loc.startBroadcasting;
          break;
        case PanelMode.nintendo:
          buttonLabel = loc.startNintendoMode;
          break;
        case PanelMode.friends:
          buttonLabel = loc.startFriendsMode;
          break;
        case PanelMode.java:
          buttonLabel = loc.startJavaMode;
          break;
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 80,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: color.withOpacity(0.07)),
            CustomPaint(painter: _NoisePainter(color: color)),
            CustomPaint(painter: _WavePainter(color: color)),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.22)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: color.withOpacity(0.28)),
                    ),
                    child: Icon(
                      broadcasting
                          ? Icons.stop_circle_outlined
                          : Icons.sensors_rounded,
                      color: color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      broadcasting ? 'Broadcasting Active' : buttonLabel,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: broadcasting
                        ? widget.onStopBroadcast
                        : () => widget.onStartBroadcast(_mode),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            broadcasting
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            broadcasting ? loc.stopBroadcasting : loc.start,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildServersHeader(bool broadcasting) {
    return Row(
      children: [
        _tabChip(label: 'My Servers', index: 0),
        const SizedBox(width: 6),
        _tabChip(label: 'Partner Servers', index: 1),
        const Spacer(),
        if (_tab == 0)
          GestureDetector(
            onTap: broadcasting ? null : widget.onManageServers,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: broadcasting
                    ? AppTheme.surfaceRaised
                    : AppTheme.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: broadcasting
                      ? AppTheme.borderGray
                      : AppTheme.accent.withOpacity(0.40),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_rounded,
                    size: 12,
                    color: broadcasting
                        ? AppTheme.textDisabled
                        : AppTheme.accent,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Add / Edit Servers',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: broadcasting
                          ? AppTheme.textDisabled
                          : AppTheme.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _tabChip({required String label, required int index}) {
    final isActive = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.surfaceLight : AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppTheme.borderLight : AppTheme.borderGray,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildServersBody(bool broadcasting) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderGray),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _tab == 0
            ? MyServersTab(
                key: const ValueKey(0),
                savedServers: widget.savedServers,
                ipController: widget.ipController,
                portController: widget.portController,
                onServerSelected: widget.onServerSelected,
                broadcasting: broadcasting,
              )
            : PartnerServersTab(
                key: const ValueKey(1),
                partnerServersFuture: _featuredFuture,
                ipController: widget.ipController,
                portController: widget.portController,
              ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: AppTheme.textMuted,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
    ),
  );
}

class _HeroStatusBadge extends StatelessWidget {
  final Future<ServerStatus> statusFuture;
  const _HeroStatusBadge({required this.statusFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ServerStatus>(
      future: statusFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _badge(
            dot: Colors.white.withOpacity(0.40),
            label: '...',
            sub: null,
          );
        }

        final status = snapshot.data!;
        if (!status.isOnline) {
          return _badge(
            dot: AppTheme.error.withOpacity(0.80),
            label: 'Offline',
            sub: null,
          );
        }

        final playerText = (status.players != null && status.maxPlayers != null)
            ? '${status.players} / ${status.maxPlayers}'
            : null;

        return _badge(
          dot: const Color(0xFF4ADE80),
          label: 'Online',
          sub: playerText,
        );
      },
    );
  }

  Widget _badge({
    required Color dot,
    required String label,
    required String? sub,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (sub != null) ...[
            Container(
              width: 1,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 7),
              color: Colors.white.withOpacity(0.25),
            ),
            const Icon(Icons.people_rounded, size: 11, color: Colors.white70),
            const SizedBox(width: 4),
            Text(
              sub,
              style: TextStyle(
                color: Colors.white.withOpacity(0.80),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroNoisePainter extends CustomPainter {
  const _HeroNoisePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Math.Random(99);
    final paint = Paint()..color = Colors.white.withOpacity(0.030);
    for (int i = 0; i < 320; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        rng.nextDouble() * 1.4 + 0.2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HeroNoisePainter old) => false;
}

class _HeroWavePainter extends CustomPainter {
  const _HeroWavePainter();
  @override
  void paint(Canvas canvas, Size size) {
    void wave(
      double yFrac,
      double amp,
      double freq,
      double phase,
      Color color,
      double sw,
    ) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw;
      final path = Path();
      path.moveTo(0, size.height * yFrac);
      for (double x = 0; x <= size.width; x += 1) {
        path.lineTo(
          x,
          size.height * yFrac +
              amp * Math.sin((x / size.width) * freq * Math.pi + phase),
        );
      }
      canvas.drawPath(path, paint);
    }

    wave(0.72, 18, 2.5, 0.3, AppTheme.accent.withOpacity(0.12), 1.8);
    wave(0.55, 10, 3.8, 1.8, AppTheme.accent.withOpacity(0.07), 1.2);
    wave(0.88, 7, 5.0, 0.9, Colors.white.withOpacity(0.04), 1.0);
  }

  @override
  bool shouldRepaint(_HeroWavePainter old) => false;
}

class _WavePainter extends CustomPainter {
  final Color color;
  const _WavePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    void wave(
      double yFrac,
      double amp,
      double freq,
      double phase,
      double opacity,
      double sw,
    ) {
      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw;
      final path = Path();
      path.moveTo(0, size.height * yFrac);
      for (double x = 0; x <= size.width; x += 1) {
        path.lineTo(
          x,
          size.height * yFrac +
              amp * Math.sin((x / size.width) * freq * Math.pi + phase),
        );
      }
      canvas.drawPath(path, paint);
    }

    wave(0.45, 12, 3.0, 0.5, 0.18, 1.5);
    wave(0.65, 8, 4.0, 1.2, 0.09, 1.0);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.color != color;
}

class _NoisePainter extends CustomPainter {
  final Color color;
  const _NoisePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Math.Random(42);
    final paint = Paint()..color = color.withOpacity(0.055);
    for (int i = 0; i < 180; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        rng.nextDouble() * 1.2 + 0.3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_NoisePainter old) => old.color != color;
}
