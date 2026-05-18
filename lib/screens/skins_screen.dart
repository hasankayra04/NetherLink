import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

class _GeyserSkin {
  final int id;
  final bool isSteve;
  final String textureId;
  String get textureUrl => 'https://textures.minecraft.net/texture/$textureId';
  const _GeyserSkin({
    required this.id,
    required this.isSteve,
    required this.textureId,
  });
}

class _SkinFaceImage extends StatefulWidget {
  final String textureUrl;
  final double size;
  const _SkinFaceImage({required this.textureUrl, this.size = 64});

  @override
  State<_SkinFaceImage> createState() => _SkinFaceImageState();
}

class _SkinFaceImageState extends State<_SkinFaceImage> {
  ui.Image? _image;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_SkinFaceImage old) {
    super.didUpdateWidget(old);
    if (old.textureUrl != widget.textureUrl) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _image = null;
    });
    try {
      final resp = await http
          .get(
            Uri.parse(widget.textureUrl),
            headers: {'User-Agent': 'NetherLinkApp/1.0'},
          )
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      final codec = await ui.instantiateImageCodec(resp.bodyBytes);
      final frame = await codec.getNextFrame();
      if (mounted)
        setState(() {
          _image = frame.image;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    if (_loading) {
      return SizedBox(
        width: s,
        height: s,
        child: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.accent,
            strokeWidth: 2,
          ),
        ),
      );
    }
    if (_image == null) {
      return SizedBox(
        width: s,
        height: s,
        child: const Center(
          child: FaIcon(
            FontAwesomeIcons.user,
            color: AppTheme.textMuted,
            size: 22,
          ),
        ),
      );
    }
    return CustomPaint(size: Size(s, s), painter: _FacePainter(_image!));
  }
}

class _FacePainter extends CustomPainter {
  final ui.Image image;
  _FacePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final sc = image.width / 64.0;
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    final dst = Offset.zero & size;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(8 * sc, 8 * sc, 8 * sc, 8 * sc),
      dst,
      paint,
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(40 * sc, 8 * sc, 8 * sc, 8 * sc),
      dst,
      paint,
    );
  }

  @override
  bool shouldRepaint(_FacePainter old) => old.image != image;
}

// ── Full-body skin image ───────────────────────────────────────────────────────

class _SkinBodyImage extends StatefulWidget {
  final String textureUrl;
  final double height;
  const _SkinBodyImage({required this.textureUrl, this.height = 128});

  @override
  State<_SkinBodyImage> createState() => _SkinBodyImageState();
}

class _SkinBodyImageState extends State<_SkinBodyImage> {
  ui.Image? _image;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_SkinBodyImage old) {
    super.didUpdateWidget(old);
    if (old.textureUrl != widget.textureUrl) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _image = null;
    });
    try {
      final resp = await http
          .get(
            Uri.parse(widget.textureUrl),
            headers: {'User-Agent': 'NetherLinkApp/1.0'},
          )
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      final codec = await ui.instantiateImageCodec(resp.bodyBytes);
      final frame = await codec.getNextFrame();
      if (mounted)
        setState(() {
          _image = frame.image;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.height;
    final w = h / 2.0; // character aspect ratio 16:32
    if (_loading)
      return SizedBox(
        width: w,
        height: h,
        child: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.accent,
            strokeWidth: 2,
          ),
        ),
      );
    if (_image == null)
      return SizedBox(
        width: w,
        height: h,
        child: const Center(
          child: FaIcon(
            FontAwesomeIcons.personRunning,
            color: AppTheme.textMuted,
            size: 28,
          ),
        ),
      );
    return CustomPaint(size: Size(w, h), painter: _BodyPainter(_image!));
  }
}

class _BodyPainter extends CustomPainter {
  final ui.Image image;
  _BodyPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    // Character model is 16 units wide × 32 units tall (front view)
    // UV coordinates are for a 64×64 skin; sc handles 128×128 Bedrock skins
    final sc = image.width / 64.0;
    final px = size.width / 16.0; // pixels per character unit
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;

    void draw(
      double dx,
      double dy,
      double dw,
      double dh,
      double sx,
      double sy,
      double sw,
      double sh,
    ) {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(sx * sc, sy * sc, sw * sc, sh * sc),
        Rect.fromLTWH(dx * px, dy * px, dw * px, dh * px),
        paint,
      );
    }

    // ── Head ──────────────────────────────────────────────
    draw(4, 0, 8, 8, 8, 8, 8, 8); // base face
    draw(4, 0, 8, 8, 40, 8, 8, 8); // hat overlay

    // ── Body ──────────────────────────────────────────────
    draw(4, 8, 8, 12, 20, 20, 8, 12); // base
    draw(4, 8, 8, 12, 20, 36, 8, 12); // jacket overlay

    // ── Right arm (appears on left) ───────────────────────
    draw(0, 8, 4, 12, 44, 20, 4, 12); // base
    draw(0, 8, 4, 12, 44, 36, 4, 12); // sleeve overlay

    // ── Left arm (appears on right) ───────────────────────
    draw(12, 8, 4, 12, 36, 52, 4, 12); // base
    draw(12, 8, 4, 12, 52, 52, 4, 12); // sleeve overlay

    // ── Right leg (appears on left) ───────────────────────
    draw(4, 20, 4, 12, 4, 20, 4, 12); // base
    draw(4, 20, 4, 12, 4, 36, 4, 12); // trouser overlay

    // ── Left leg (appears on right) ───────────────────────
    draw(8, 20, 4, 12, 20, 52, 4, 12); // base
    draw(8, 20, 4, 12, 4, 52, 4, 12); // trouser overlay
  }

  @override
  bool shouldRepaint(_BodyPainter old) => old.image != image;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class SkinsScreen extends StatefulWidget {
  const SkinsScreen({super.key});

  @override
  State<SkinsScreen> createState() => _SkinsScreenState();
}

class _SkinsScreenState extends State<SkinsScreen> {
  StreamSubscription<User?>? _authSub;

  UserModel? _me;
  bool _loading = true;

  final _searchController = TextEditingController();
  UserModel? _searchResult;
  bool _searching = false;
  String? _searchError;

  // Recent skins from GeyserMC
  List<_GeyserSkin> _recentSkins = [];
  int _page = 0;
  int _totalPages = 10;
  bool _loadingRecent = false;

  @override
  void initState() {
    super.initState();
    _authSub = AuthService.userStream.listen((_) => _loadMe());
    _loadMe();
    _loadRecentSkins(0);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMe() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _me = null;
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    final me = await UserService.getMe();
    if (!mounted) return;
    setState(() {
      _me = me;
      _loading = false;
    });
  }

  Future<void> _loadRecentSkins(int page) async {
    if (_loadingRecent) return;
    setState(() => _loadingRecent = true);
    try {
      final resp = await http
          .get(
            Uri.parse(
              'https://api.geysermc.org/v2/skin/bedrock/recent?page=$page',
            ),
            headers: {'User-Agent': 'NetherLinkApp/1.0'},
          )
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        final data = (json['data'] as List?) ?? [];
        final total = json['total_pages'] as int? ?? 10;
        final skins = data
            .map(
              (e) => _GeyserSkin(
                id: e['id'] as int,
                isSteve: e['is_steve'] as bool? ?? false,
                textureId: e['texture_id'] as String,
              ),
            )
            .toList();
        setState(() {
          _recentSkins = skins;
          _page = page;
          _totalPages = total;
          _loadingRecent = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingRecent = false);
  }

  String? _extractTextureUrl(String body) {
    try {
      final props = (jsonDecode(body)['properties'] as List?) ?? [];
      for (final p in props) {
        if (p['name'] == 'textures') {
          final decoded = jsonDecode(
            utf8.decode(base64.decode(p['value'] as String)),
          );
          return decoded['textures']?['SKIN']?['url'] as String?;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _searching = true;
      _searchError = null;
      _searchResult = null;
    });
    final profile = await UserService.getProfile(query);
    if (!mounted) return;
    if (profile == null) {
      setState(() {
        _searchError = 'No player found for "$query"';
        _searching = false;
      });
    } else if (profile.javaUuid == null) {
      setState(() {
        _searchError = '${profile.username} has no Java Edition linked.';
        _searching = false;
      });
    } else {
      setState(() {
        _searchResult = profile;
        _searching = false;
      });
    }
  }

  void _openGeyserDetail(String textureUrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SkinDetailSheet(textureUrl: textureUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Skins',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'View and download Minecraft skins.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          _buildYourSkins(),
          const SizedBox(height: 28),
          _sectionLabel('RECENT SKINS'),
          const SizedBox(height: 10),
          _buildRecentSkins(),
          const SizedBox(height: 28),
          _sectionLabel('LOOK UP A PLAYER'),
          const SizedBox(height: 10),
          _SearchBar(
            controller: _searchController,
            searching: _searching,
            onSearch: _search,
          ),
          if (_searchError != null) ...[
            const SizedBox(height: 12),
            Text(
              _searchError!,
              style: const TextStyle(color: AppTheme.error, fontSize: 13),
            ),
          ],
          if (_searchResult != null) ...[
            const SizedBox(height: 16),
            _JavaSkinCard(
              username: _searchResult!.javaUsername ?? _searchResult!.username,
              javaUuid: _searchResult!.javaUuid!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildYourSkins() {
    final hasJava = _me?.javaUuid != null;
    final hasBedrock = _me?.xboxXuid != null && _me?.xboxGamertag != null;

    if (_me == null) return const _NotLoggedInCard();
    if (!hasJava && !hasBedrock) return const _NoAccountsCard();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('YOUR SKINS'),
        const SizedBox(height: 10),
        if (hasJava && hasBedrock)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _JavaSkinCard(
                  username: _me!.javaUsername ?? _me!.username,
                  javaUuid: _me!.javaUuid!,
                  badge: 'Java',
                  badgeColor: const Color(0xFF42A5F5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BedrockSkinCard(
                  gamertag: _me!.xboxGamertag!,
                  xuid: _me!.xboxXuid!,
                ),
              ),
            ],
          )
        else if (hasJava)
          _JavaSkinCard(
            username: _me!.javaUsername ?? _me!.username,
            javaUuid: _me!.javaUuid!,
          )
        else
          _BedrockSkinCard(gamertag: _me!.xboxGamertag!, xuid: _me!.xboxXuid!),
      ],
    );
  }

  Widget _buildRecentSkins() {
    return Column(
      children: [
        if (_loadingRecent)
          const SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(
                color: AppTheme.accent,
                strokeWidth: 2,
              ),
            ),
          )
        else if (_recentSkins.isEmpty)
          const SizedBox(
            height: 80,
            child: Center(
              child: Text(
                'Could not load skins',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: _recentSkins.length,
            itemBuilder: (_, i) {
              final skin = _recentSkins[i];
              return _GeyserSkinChip(
                skin: skin,
                onTap: () => _openGeyserDetail(skin.textureUrl),
              );
            },
          ),
        const SizedBox(height: 12),
        _buildPagination(),
      ],
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: (_page > 0 && !_loadingRecent)
              ? () => _loadRecentSkins(_page - 1)
              : null,
          icon: const FaIcon(FontAwesomeIcons.chevronLeft, size: 13),
          style: IconButton.styleFrom(
            foregroundColor: AppTheme.accent,
            disabledForegroundColor: AppTheme.textMuted,
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Page ${_page + 1} / $_totalPages',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: (_page < _totalPages - 1 && !_loadingRecent)
              ? () => _loadRecentSkins(_page + 1)
              : null,
          icon: const FaIcon(FontAwesomeIcons.chevronRight, size: 13),
          style: IconButton.styleFrom(
            foregroundColor: AppTheme.accent,
            disabledForegroundColor: AppTheme.textMuted,
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: AppTheme.textMuted,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    ),
  );
}

// ── GeyserMC skin chip (grid cell) ───────────────────────────────────────────

class _GeyserSkinChip extends StatelessWidget {
  final _GeyserSkin skin;
  final VoidCallback onTap;
  const _GeyserSkinChip({required this.skin, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderGray),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Center(
                  child: _SkinFaceImage(textureUrl: skin.textureUrl, size: 40),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
              child: Text(
                skin.isSteve ? 'Steve' : 'Alex',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skin detail bottom sheet ──────────────────────────────────────────────────

class _SkinDetailSheet extends StatelessWidget {
  final String? username;
  final String? javaUuid;
  final String? textureUrl;
  const _SkinDetailSheet({this.username, this.javaUuid, this.textureUrl});

  String? get _downloadUrl =>
      textureUrl ??
      (javaUuid != null ? 'https://visage.surgeplay.com/skin/$javaUuid' : null);

  Future<void> _download() async {
    final url = _downloadUrl;
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppTheme.borderGray)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppTheme.borderLight,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          if (username != null)
            Text(
              username!,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (username != null) const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Center(
              child: textureUrl != null
                  ? _SkinBodyImage(textureUrl: textureUrl!, height: 196)
                  : const FaIcon(
                      FontAwesomeIcons.personRunning,
                      color: AppTheme.textMuted,
                      size: 40,
                    ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _downloadUrl != null ? _download : null,
              icon: const FaIcon(FontAwesomeIcons.download, size: 13),
              label: const Text('Download skin PNG'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Java skin card ────────────────────────────────────────────────────────────

class _JavaSkinCard extends StatefulWidget {
  final String username;
  final String javaUuid;
  final String? badge;
  final Color? badgeColor;
  const _JavaSkinCard({
    required this.username,
    required this.javaUuid,
    this.badge,
    this.badgeColor,
  });

  @override
  State<_JavaSkinCard> createState() => _JavaSkinCardState();
}

class _JavaSkinCardState extends State<_JavaSkinCard> {
  String? _textureUrl;

  @override
  void initState() {
    super.initState();
    _fetchTexture();
  }

  Future<void> _fetchTexture() async {
    try {
      final resp = await http
          .get(
            Uri.parse(
              'https://sessionserver.mojang.com/session/minecraft/profile/${widget.javaUuid}',
            ),
            headers: {'User-Agent': 'NetherLinkApp/1.0'},
          )
          .timeout(const Duration(seconds: 8));
      if (!mounted || resp.statusCode != 200) return;
      final url = _extractTextureUrl(resp.body);
      if (url != null && mounted) setState(() => _textureUrl = url);
    } catch (_) {}
  }

  String? _extractTextureUrl(String body) {
    try {
      final props = (jsonDecode(body)['properties'] as List?) ?? [];
      for (final p in props) {
        if (p['name'] == 'textures') {
          final decoded = jsonDecode(
            utf8.decode(base64.decode(p['value'] as String)),
          );
          return decoded['textures']?['SKIN']?['url'] as String?;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _download() async {
    final url =
        _textureUrl ?? 'https://visage.surgeplay.com/skin/${widget.javaUuid}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _openDetail() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SkinDetailSheet(
        username: widget.username,
        javaUuid: widget.javaUuid,
        textureUrl: _textureUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final badge = widget.badge;
    final badgeColor = widget.badgeColor ?? AppTheme.accent;

    return GestureDetector(
      onTap: _openDetail,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderGray),
        ),
        child: Column(
          children: [
            if (badge != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              height: 140,
              child: Center(
                child: _textureUrl != null
                    ? _SkinBodyImage(textureUrl: _textureUrl!, height: 136)
                    : const CircularProgressIndicator(
                        color: AppTheme.accent,
                        strokeWidth: 2,
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.username,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _download,
                icon: const FaIcon(FontAwesomeIcons.download, size: 11),
                label: const Text('Download'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accent,
                  side: const BorderSide(color: AppTheme.accent),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bedrock skin card ─────────────────────────────────────────────────────────

class _BedrockSkinCard extends StatefulWidget {
  final String gamertag;
  final String xuid;
  const _BedrockSkinCard({required this.gamertag, required this.xuid});

  @override
  State<_BedrockSkinCard> createState() => _BedrockSkinCardState();
}

class _BedrockSkinCardState extends State<_BedrockSkinCard> {
  String? _textureUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final resp = await http
          .get(
            Uri.parse('https://api.geysermc.org/v2/skin/${widget.xuid}'),
            headers: {'User-Agent': 'NetherLinkApp/1.0'},
          )
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final id = jsonDecode(resp.body)['texture_id'] as String?;
        if (id != null) {
          setState(() {
            _textureUrl = 'https://textures.minecraft.net/texture/$id';
            _loading = false;
          });
          return;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _download() async {
    if (_textureUrl == null) return;
    final uri = Uri.parse(_textureUrl!);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _openDetail() {
    if (_textureUrl == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          _SkinDetailSheet(username: widget.gamertag, textureUrl: _textureUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openDetail,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderGray),
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Bedrock',
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 140,
              child: Center(
                child: _loading
                    ? const CircularProgressIndicator(
                        color: AppTheme.accent,
                        strokeWidth: 2,
                      )
                    : _textureUrl != null
                    ? _SkinBodyImage(textureUrl: _textureUrl!, height: 136)
                    : const FaIcon(
                        FontAwesomeIcons.personRunning,
                        color: AppTheme.textMuted,
                        size: 28,
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.gamertag,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _textureUrl != null ? _download : null,
                icon: const FaIcon(FontAwesomeIcons.download, size: 11),
                label: const Text('Download'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4CAF50),
                  side: const BorderSide(color: Color(0xFF4CAF50)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool searching;
  final VoidCallback onSearch;
  const _SearchBar({
    required this.controller,
    required this.searching,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onSubmitted: (_) => onSearch(),
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Java username or NetherLink username…',
              hintStyle: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 13,
              ),
              filled: true,
              fillColor: AppTheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.borderGray),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.borderGray),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.accent,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 46,
          child: FilledButton(
            onPressed: searching ? null : onSearch,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: searching
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const FaIcon(FontAwesomeIcons.magnifyingGlass, size: 14),
          ),
        ),
      ],
    );
  }
}

// ── Empty state cards ─────────────────────────────────────────────────────────

class _NoAccountsCard extends StatelessWidget {
  const _NoAccountsCard();

  @override
  Widget build(BuildContext context) => _InfoCard(
    icon: FontAwesomeIcons.shirt,
    iconColor: const Color(0xFF42A5F5),
    title: 'No accounts linked',
    subtitle: 'Link Java or Bedrock in Profile to see your skin.',
  );
}

class _NotLoggedInCard extends StatelessWidget {
  const _NotLoggedInCard();

  @override
  Widget build(BuildContext context) => _InfoCard(
    icon: FontAwesomeIcons.user,
    iconColor: AppTheme.accent,
    title: 'Sign in to see your skin',
    subtitle: 'Create an account and link Java or Bedrock in Profile.',
  );
}

class _InfoCard extends StatelessWidget {
  final FaIconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGray),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: FaIcon(icon, color: iconColor, size: 18)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
