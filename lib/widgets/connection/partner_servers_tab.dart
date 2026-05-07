import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../util/featured_servers.dart';
import '../../services/server_status_service.dart';

class PartnerServersTab extends StatefulWidget {
  const PartnerServersTab({
    super.key,
    required this.partnerServersFuture,
    required this.ipController,
    required this.portController,
  });

  final Future<List<FeaturedServer>>? partnerServersFuture;
  final TextEditingController ipController;
  final TextEditingController portController;

  @override
  State<PartnerServersTab> createState() => _PartnerServersTabState();
}

class _PartnerServersTabState extends State<PartnerServersTab> {
  List<FeaturedServer>? _shuffled;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FeaturedServer>>(
      future: widget.partnerServersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Column(
              children: [
                Icon(
                  Icons.handshake_outlined,
                  size: 26,
                  color: AppTheme.textMuted,
                ),
                SizedBox(height: 10),
                Text(
                  'No partner servers available yet.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          );
        }

        _shuffled ??= List.from(snapshot.data!)..shuffle(Random());
        final servers = _shuffled!;

        return Column(
          children: List.generate(servers.length, (i) {
            return _PartnerServerTile(
              server: servers[i],
              isLast: i == servers.length - 1,
              onPlay: () {
                widget.ipController.text = servers[i].address;
                widget.portController.text = servers[i].port.toString();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(
                        context,
                      )!.selectedFeaturedServer(servers[i].name),
                    ),
                    backgroundColor: AppTheme.success,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.all(12),
                  ),
                );
              },
            );
          }),
        );
      },
    );
  }
}

class _PartnerServerTile extends StatelessWidget {
  const _PartnerServerTile({
    required this.server,
    required this.isLast,
    required this.onPlay,
  });

  final FeaturedServer server;
  final bool isLast;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppTheme.borderDim)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: server.iconUrl != null && server.iconUrl!.isNotEmpty
                ? Image.network(
                    server.iconUrl!,
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallbackIcon(),
                  )
                : _fallbackIcon(),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        server.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(address: server.address, port: server.port),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${server.address}:${server.port}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (server.websiteUrl != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => launchUrl(
                      Uri.parse(server.websiteUrl!),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceRaised,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderGray),
                      ),
                      child: const Icon(
                        Icons.language_rounded,
                        size: 15,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
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
                        size: 14,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Play',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fallbackIcon() => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: AppTheme.surfaceRaised,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppTheme.borderGray),
    ),
    child: const Icon(Icons.dns_rounded, size: 17, color: AppTheme.textMuted),
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
        if (!snapshot.hasData) {
          return _pill(dot: AppTheme.textMuted, label: '...', sub: null);
        }
        final status = snapshot.data!;
        if (!status.isOnline) {
          return _pill(dot: AppTheme.textMuted, label: 'Offline', sub: null);
        }
        final sub = (status.players != null && status.maxPlayers != null)
            ? '${status.players}/${status.maxPlayers}'
            : null;
        return _pill(dot: AppTheme.success, label: 'Online', sub: sub);
      },
    );
  }

  Widget _pill({
    required Color dot,
    required String label,
    required String? sub,
  }) {
    final online = dot == AppTheme.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: online
            ? AppTheme.success.withOpacity(0.08)
            : AppTheme.surfaceRaised,
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
          if (sub != null) ...[
            const SizedBox(width: 3),
            Text(
              sub,
              style: TextStyle(
                color: AppTheme.success.withOpacity(0.70),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
