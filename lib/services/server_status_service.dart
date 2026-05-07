import 'package:mc_server_info/mc_server_info.dart';

class ServerStatus {
  final bool isOnline;
  final int? players;
  final int? maxPlayers;

  const ServerStatus({
    required this.isOnline,
    this.players,
    this.maxPlayers,
  });

  static const ServerStatus offline = ServerStatus(isOnline: false);
}

class ServerStatusService {
  ServerStatusService._();

  static final Map<String, ServerStatus> _cache     = {};
  static final Map<String, DateTime>     _lastFetch = {};
  static const Duration _cacheDuration = Duration(minutes: 2);
  static const Duration _timeout       = Duration(seconds: 5);

  static Future<ServerStatus> getStatus(String address, int port) async {
    final key = '$address:$port';
    final now = DateTime.now();

    final cached   = _cache[key];
    final fetchedAt = _lastFetch[key];
    if (cached != null &&
        fetchedAt != null &&
        now.difference(fetchedAt) < _cacheDuration) {
      return cached;
    }

    try {
      final info = await MinecraftServerInfo.get(
        host: address,
        port: port,
        timeout: _timeout,
      );
      final status = ServerStatus(
        isOnline:   info.isOnline,
        players:    info.isOnline ? info.players    : null,
        maxPlayers: info.isOnline ? info.maxPlayers : null,
      );
      _cache[key]     = status;
      _lastFetch[key] = now;
      return status;
    } catch (_) {
      _cache[key]     = ServerStatus.offline;
      _lastFetch[key] = now;
      return ServerStatus.offline;
    }
  }

  static void invalidate(String address, int port) {
    _cache.remove('$address:$port');
    _lastFetch.remove('$address:$port');
  }

  static void clearAll() {
    _cache.clear();
    _lastFetch.clear();
  }
}