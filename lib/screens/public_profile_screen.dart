import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class PublicProfileScreen extends StatefulWidget {
  final String username;
  const PublicProfileScreen({super.key, required this.username});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  UserModel? _user;
  bool _loading = true;
  String? _friendStatus;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      UserService.getProfile(widget.username),
      UserService.getFriendshipStatus(widget.username),
    ]);
    if (!mounted) return;
    setState(() {
      _user = results[0] as UserModel?;
      _friendStatus = results[1] as String;
      _loading = false;
    });
  }

  Future<void> _sendRequest() async {
    setState(() => _actionLoading = true);
    final error = await UserService.sendFriendRequest(widget.username);
    if (!mounted) return;
    setState(() => _actionLoading = false);
    if (error == null) {
      setState(() => _friendStatus = 'pending_sent');
      _showToast(
        'Friend request sent',
        AppTheme.success,
        Icons.check_circle_rounded,
      );
    } else {
      final msg = switch (error) {
        'already_friends' => 'You are already friends.',
        'request_pending' => 'There is already a pending request.',
        'not_found' => 'User not found.',
        'blocked' => 'Cannot send a request to this user.',
        _ => 'Something went wrong.',
      };
      _showToast(msg, AppTheme.error, Icons.error_outline_rounded);
    }
  }

  Future<void> _acceptRequest() async {
    setState(() => _actionLoading = true);
    final ok = await UserService.acceptFriendRequest(widget.username);
    if (!mounted) return;
    setState(() {
      _actionLoading = false;
      if (ok) _friendStatus = 'friends';
    });
    if (ok)
      _showToast(
        'Now friends with @${widget.username}',
        AppTheme.success,
        Icons.check_circle_rounded,
      );
  }

  Future<void> _removeFriend() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderGray),
        ),
        title: const Text('Remove friend'),
        content: Text(
          'Remove @${widget.username} as a friend?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _actionLoading = true);
    final ok = await UserService.removeFriend(widget.username);
    if (!mounted) return;
    setState(() {
      _actionLoading = false;
      if (ok) _friendStatus = 'none';
    });
  }

  void _showToast(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Text(
          _user != null ? '@${_user!.username}' : 'Profile',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.accent,
                strokeWidth: 2,
              ),
            )
          : _user == null
          ? _buildNotFound()
          : _buildProfile(),
    );
  }

  Widget _buildNotFound() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_off_rounded,
            color: AppTheme.textDisabled,
            size: 48,
          ),
          SizedBox(height: 12),
          Text(
            'User not found',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    final u = _user!;
    const xboxGreen = Color(0xFF107C10);

    return RefreshIndicator(
      color: AppTheme.accent,
      backgroundColor: AppTheme.surfaceRaised,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                _Avatar(initials: u.initials, size: 72),
                const SizedBox(height: 14),
                Text(
                  u.displayLabel,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${u.username}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildFriendButton(),
          const SizedBox(height: 16),

          _InfoCard(
            icon: Icons.person_rounded,
            label: 'Profile',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileRow(
                  label: 'Display name',
                  value: u.displayName?.isNotEmpty == true
                      ? u.displayName!
                      : '—',
                ),
                const SizedBox(height: 8),
                _ProfileRow(label: 'Username', value: '@${u.username}'),
                if (u.lastSeenAt != null) ...[
                  const SizedBox(height: 8),
                  _ProfileRow(
                    label: 'Last seen',
                    value: _formatDate(u.lastSeenAt!),
                  ),
                ],
              ],
            ),
          ),

          if (u.bio?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            _InfoCard(
              icon: Icons.info_outline_rounded,
              label: 'About',
              child: Text(
                u.bio!,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ],

          if (u.xboxGamertag != null) ...[
            const SizedBox(height: 12),
            _InfoCard(
              icon: Icons.sports_esports_rounded,
              iconColor: xboxGreen,
              label: 'Xbox / Bedrock',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    u.xboxGamertag!,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (u.xboxXuid != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      u.xboxXuid!,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          if (u.javaUsername != null) ...[
            const SizedBox(height: 12),
            _InfoCard(
              icon: Icons.videogame_asset_rounded,
              iconColor: const Color(0xFF1565C0),
              label: 'Java Edition',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    u.javaUsername!,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (u.javaUuid != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      u.javaUuid!,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFriendButton() {
    if (_actionLoading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: AppTheme.accent,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return switch (_friendStatus) {
      'friends' => OutlinedButton.icon(
        onPressed: _removeFriend,
        icon: const Icon(Icons.person_remove_rounded, size: 16),
        label: const Text('Remove friend'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.error,
          side: BorderSide(color: AppTheme.error.withOpacity(0.40)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
      'pending_sent' => OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.hourglass_top_rounded, size: 16),
        label: const Text('Request sent'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textMuted,
          side: const BorderSide(color: AppTheme.borderGray),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
      'pending_received' => ElevatedButton.icon(
        onPressed: _acceptRequest,
        icon: const Icon(Icons.check_rounded, size: 16),
        label: const Text(
          'Accept request',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.success,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
      _ => ElevatedButton.icon(
        onPressed: _sendRequest,
        icon: const Icon(Icons.person_add_rounded, size: 16),
        label: const Text(
          'Add friend',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    };
  }
}

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _ctrl = TextEditingController();
  List<UserModel> _results = [];
  bool _loading = false;
  bool _searched = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _searched = true;
    });
    final results = await UserService.searchUsers(q);
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  void _openProfile(String username) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(username: username),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Find user',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    autofocus: true,
                    autocorrect: false,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Username, gamertag or Java name…',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _loading ? null : _search,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  child: const Text(
                    'Search',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.accent,
          strokeWidth: 2,
        ),
      );
    }
    if (!_searched) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.manage_search_rounded,
              color: AppTheme.textDisabled,
              size: 48,
            ),
            SizedBox(height: 12),
            Text(
              'Search by username, Xbox gamertag or Java name',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }
    if (_results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_off_rounded,
              color: AppTheme.textDisabled,
              size: 48,
            ),
            SizedBox(height: 12),
            Text(
              'No users found',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final u = _results[i];
        return GestureDetector(
          onTap: () => _openProfile(u.username),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceRaised,
              borderRadius: BorderRadius.circular(12),
              border: const Border.fromBorderSide(
                BorderSide(color: AppTheme.borderGray),
              ),
            ),
            child: Row(
              children: [
                _Avatar(initials: u.initials, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.displayLabel,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '@${u.username}',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      if (u.xboxGamertag != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.sports_esports_rounded,
                              size: 11,
                              color: Color(0xFF107C10),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              u.xboxGamertag!,
                              style: const TextStyle(
                                color: Color(0xFF107C10),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (u.javaUsername != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.videogame_asset_rounded,
                              size: 11,
                              color: Color(0xFF1565C0),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              u.javaUsername!,
                              style: const TextStyle(
                                color: Color(0xFF1565C0),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textMuted,
                  size: 18,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _formatDate(String iso) {
  try {
    final dt = DateTime.parse(iso).toLocal();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 2) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  } catch (_) {
    return '—';
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  final double size;
  const _Avatar({required this.initials, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.accent.withOpacity(0.30)),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: AppTheme.accent,
            fontSize: size * 0.33,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final Widget child;
  const _InfoCard({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(
          BorderSide(color: AppTheme.borderGray),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor ?? AppTheme.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
