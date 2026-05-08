import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../util/featured_servers.dart';
import '../../services/server_status_service.dart';
import '../../services/navigation_controller.dart';
import '../../widgets/components/app_toast.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';

class PartnerServersScreen extends StatefulWidget {
  const PartnerServersScreen({
    super.key,
    required this.partnerServersFuture,
    required this.ipController,
    required this.portController,
    required this.navigationController,
  });

  final Future<List<FeaturedServer>>? partnerServersFuture;
  final TextEditingController ipController;
  final TextEditingController portController;
  final NavigationController navigationController;

  @override
  State<PartnerServersScreen> createState() => _PartnerServersScreenState();
}

class _PartnerServersScreenState extends State<PartnerServersScreen> {
  List<FeaturedServer>? _shuffled;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Partner Servers',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderGray),
        ),
      ),
      bottomNavigationBar: BottomGlassSimpleNavBar(
        navigationController: widget.navigationController,
        dark: true,
        selectedRelayIp: null,
        onRelayChanged: null,
      ),
      body: FutureBuilder<List<FeaturedServer>>(
        future: widget.partnerServersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppTheme.textMuted,
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceRaised,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderGray),
                    ),
                    child: const Icon(
                      Icons.handshake_outlined,
                      size: 24,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'No partner servers available yet.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Check back later.',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                ],
              ),
            );
          }

          _shuffled ??= List.from(snapshot.data!)..shuffle(Random());
          final servers = _shuffled!;

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: servers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _PartnerServerCard(
              server: servers[i],
              onPlay: () {
                widget.ipController.text = servers[i].address;
                widget.portController.text = servers[i].port.toString();
                AppToast.show(
                  context,
                  message: AppLocalizations.of(
                    context,
                  )!.selectedFeaturedServer(servers[i].name),
                  icon: Icons.play_arrow_rounded,
                  color: AppTheme.success,
                  duration: const Duration(seconds: 2),
                );
                Navigator.of(context).pop();
              },
            ),
          );
        },
      ),
    );
  }
}

class _PartnerServerCard extends StatelessWidget {
  const _PartnerServerCard({required this.server, required this.onPlay});

  final FeaturedServer server;
  final VoidCallback onPlay;

  bool get _hasIcon => server.iconUrl != null && server.iconUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 80,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_hasIcon)
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                  child: Image.network(
                    server.iconUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _solidBg(),
                  ),
                ),
              )
            else
              _solidBg(),

            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppTheme.surface.withOpacity(0.82),
                      AppTheme.surface.withOpacity(0.60),
                    ],
                  ),
                ),
              ),
            ),

            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderGray),
                ),
              ),
            ),

            Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(11),
                  ),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: _hasIcon
                        ? Image.network(
                            server.iconUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _iconFallback(),
                          )
                        : _iconFallback(),
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                server.name,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _StatusBadge(
                              address: server.address,
                              port: server.port,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${server.address}:${server.port}',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                          ),
                        ),
                        if (server.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            server.description,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              height: 1.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: onPlay,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_arrow_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Play',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (server.websiteUrl != null) ...[
                        const SizedBox(height: 5),
                        GestureDetector(
                          onTap: () => launchUrl(
                            Uri.parse(server.websiteUrl!),
                            mode: LaunchMode.externalApplication,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceRaised.withOpacity(0.80),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.borderGray),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.language_rounded,
                                  size: 11,
                                  color: AppTheme.textSecondary,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Website',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _solidBg() => Container(color: AppTheme.surface);

  Widget _iconFallback() => Container(
    color: AppTheme.surfaceRaised,
    child: const Icon(Icons.dns_rounded, size: 24, color: AppTheme.textMuted),
  );
}

class _StatusBadge extends StatefulWidget {
  final String address;
  final int port;
  const _StatusBadge({required this.address, required this.port});

  @override
  State<_StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<_StatusBadge> {
  late Future<ServerStatus> _statusFuture;

  @override
  void initState() {
    super.initState();
    _statusFuture = ServerStatusService.getStatus(widget.address, widget.port);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ServerStatus>(
      future: _statusFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return _pill(dot: AppTheme.textMuted, label: '...');
        final status = snapshot.data!;
        if (!status.isOnline)
          return _pill(dot: AppTheme.textMuted, label: 'Offline');
        final sub = (status.players != null && status.maxPlayers != null)
            ? ' ${status.players}/${status.maxPlayers}'
            : '';
        return _pill(dot: AppTheme.success, label: 'Online$sub');
      },
    );
  }

  Widget _pill({required Color dot, required String label}) {
    final online = dot == AppTheme.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: online
            ? AppTheme.success.withOpacity(0.08)
            : AppTheme.surfaceRaised.withOpacity(0.80),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: online
              ? AppTheme.success.withOpacity(0.30)
              : AppTheme.borderGray,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: online ? AppTheme.success : AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
