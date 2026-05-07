import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../util/user_servers.dart';
import '../../services/server_status_service.dart';

class MyServersTab extends StatefulWidget {
  const MyServersTab({
    super.key,
    required this.savedServers,
    required this.ipController,
    required this.portController,
    required this.onServerSelected,
    required this.broadcasting,
  });

  final List<UserServer> savedServers;
  final TextEditingController ipController;
  final TextEditingController portController;
  final Function(UserServer) onServerSelected;
  final bool broadcasting;

  @override
  State<MyServersTab> createState() => _MyServersTabState();
}

class _MyServersTabState extends State<MyServersTab> {
  UserServer? _selectedServer;

  @override
  Widget build(BuildContext context) {
    if (widget.savedServers.isEmpty) return _emptyState();

    return Column(
      children: List.generate(widget.savedServers.length, (i) {
        final server = widget.savedServers[i];
        final isLast = i == widget.savedServers.length - 1;
        final isSelected =
            _selectedServer?.address == server.address &&
            _selectedServer?.port == server.port;

        return _ServerTile(
          server: server,
          isSelected: isSelected,
          isLast: isLast,
          onTap: widget.broadcasting
              ? null
              : () {
                  setState(() => _selectedServer = server);
                  widget.onServerSelected(server);
                  widget.ipController.text = server.address;
                  widget.portController.text = server.port.toString();
                },
        );
      }),
    );
  }

  Widget _emptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(Icons.dns_outlined, size: 26, color: AppTheme.textMuted),
          SizedBox(height: 10),
          Text(
            'No saved servers yet.\nTap Manage to add one.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServerTile extends StatelessWidget {
  const _ServerTile({
    required this.server,
    required this.isSelected,
    required this.isLast,
    required this.onTap,
  });

  final UserServer server;
  final bool isSelected;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.surfaceLight : Colors.transparent,
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: AppTheme.borderDim)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.surfaceRaised,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderGray),
              ),
              child: const Icon(
                Icons.dns_rounded,
                size: 17,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    server.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
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

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatusBadge(address: server.address, port: server.port),
                const SizedBox(width: 8),
                if (isSelected)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.success.withOpacity(0.5),
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 11,
                      color: AppTheme.success,
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppTheme.textMuted,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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

        final playerText = (status.players != null && status.maxPlayers != null)
            ? '${status.players}/${status.maxPlayers}'
            : null;

        return _pill(dot: AppTheme.success, label: 'Online', sub: playerText);
      },
    );
  }

  Widget _pill({
    required Color dot,
    required String label,
    required String? sub,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: dot == AppTheme.success
            ? AppTheme.success.withOpacity(0.08)
            : AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dot == AppTheme.success
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
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: dot == AppTheme.success
                  ? AppTheme.success
                  : AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(width: 4),
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
