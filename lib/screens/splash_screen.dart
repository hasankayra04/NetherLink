import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/region_detector.dart';
import '../widgets/components/app_painters.dart';
import 'home_screen.dart';

class _TipData {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _TipData({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}

const _tips = [
  _TipData(
    icon: Icons.wifi_rounded,
    color: AppTheme.info,
    title: 'Same Wi-Fi Network',
    body:
        'The device running NetherLink MUST be on the same Wi-Fi network as the console you play Minecraft on.',
  ),
  _TipData(
    icon: Icons.card_membership_rounded,
    color: AppTheme.modeFriends,
    title: 'Online Subscription Required',
    body:
        'Each console needs its own active online subscription (Xbox Live, PS Plus, NSO). Without it, NetherLink won\'t appear.',
  ),
];

// ── Gedeelde splash wave-config ───────────────────────────────────────────────
const _splashWaves = [
  WaveConfig(
    yFraction: 0.35,
    amplitude: 22,
    frequency: 2.2,
    phase: 0.4,
    color: AppTheme.accent,
    opacity: 0.08,
    strokeWidth: 1.5,
  ),
  WaveConfig(
    yFraction: 0.55,
    amplitude: 14,
    frequency: 3.5,
    phase: 1.6,
    color: AppTheme.accent,
    opacity: 0.05,
    strokeWidth: 1.2,
  ),
  WaveConfig(
    yFraction: 0.75,
    amplitude: 10,
    frequency: 4.8,
    phase: 0.8,
    color: Colors.white,
    opacity: 0.03,
    strokeWidth: 1.0,
  ),
  WaveConfig(
    yFraction: 0.88,
    amplitude: 6,
    frequency: 6.0,
    phase: 2.1,
    color: AppTheme.accent,
    opacity: 0.04,
    strokeWidth: 0.8,
  ),
];

bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<AnimationController> _tipControllers = [];
  final List<Animation<double>> _tipAnimations = [];

  RelayPingResult? _detectedRelay;
  String _appVersion = '';
  bool _pendingUpdate = false;

  static const String _androidStoreUrl =
      'https://play.google.com/store/apps/details?id=net.netherdev.netherLink';
  static const String _iosStoreUrl =
      'https://apps.apple.com/be/app/netherlink/id6747323142';
  static const String _windowsStoreUrl =
      'https://apps.microsoft.com/detail/9NSFPT6D8PTR';
  static const String _fallbackUrl = 'https://netherlink.net/';

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    for (int i = 0; i < _tips.length; i++) {
      final ctrl = AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      );
      _tipControllers.add(ctrl);
      _tipAnimations.add(CurvedAnimation(parent: ctrl, curve: Curves.easeOut));
    }

    _startSequence();
  }

  Future<void> _startSequence() async {
    _fadeController.forward();

    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = info.version);

    for (int i = 0; i < _tips.length; i++) {
      await Future.delayed(Duration(milliseconds: i == 0 ? 600 : 1400));
      if (mounted) _tipControllers[i].forward();
    }

    await Future.wait([
      _detectRelayAndCheckUpdate().then((hasUpdate) {
        _pendingUpdate = hasUpdate;
      }),
      Future.delayed(const Duration(milliseconds: 4200)),
    ]);

    if (!mounted) return;

    if (_pendingUpdate) {
      final shouldContinue = await _showUpdateDialog();
      if (!mounted) return;
      if (!shouldContinue) return;
    }

    _navigateToHome();
  }

  Future<bool> _detectRelayAndCheckUpdate() async {
    try {
      _detectedRelay = await RegionDetector.detectBestRelay();
      String? remoteVersion = _detectedRelay?.version;
      if (remoteVersion == null && _detectedRelay != null) {
        remoteVersion = await _fetchVersionFallback(_detectedRelay!.base);
      }
      if (remoteVersion != null && _appVersion.isNotEmpty) {
        return _isNewerVersion(_appVersion, remoteVersion);
      }
    } catch (_) {}
    return false;
  }

  Future<String?> _fetchVersionFallback(String base) async {
    try {
      final response = await http
          .get(Uri.parse('$base/api/version'))
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['version'] as String?;
      }
    } catch (_) {}
    return null;
  }

  bool _isNewerVersion(String current, String remote) {
    final c = current.split('.').map(int.tryParse).toList();
    final r = remote.split('.').map(int.tryParse).toList();
    final len = c.length > r.length ? c.length : r.length;
    for (int i = 0; i < len; i++) {
      final cv = i < c.length ? (c[i] ?? 0) : 0;
      final rv = i < r.length ? (r[i] ?? 0) : 0;
      if (rv > cv) return true;
      if (rv < cv) return false;
    }
    return false;
  }

  String get _storeUrl {
    if (kIsWeb) return _fallbackUrl;
    if (Platform.isAndroid) return _androidStoreUrl;
    if (Platform.isIOS) return _iosStoreUrl;
    if (Platform.isWindows) return _windowsStoreUrl;
    return _fallbackUrl;
  }

  Future<void> _openStore() async {
    final uri = Uri.parse(_storeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<bool> _showUpdateDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppTheme.surfaceRaised,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderGray),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withOpacity(0.15),
                blurRadius: 40,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.35)),
                ),
                child: Center(
                  child: Icon(
                    Icons.system_update_rounded,
                    color: AppTheme.accent,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Update Available',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'A new version of the app is available.\nUpdate now for the latest features and fixes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: AppTheme.textSecondary,
                        side: const BorderSide(color: AppTheme.borderGray),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Later'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop(false);
                        _openStore();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Update Now',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? true;
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) =>
            HomeScreen(initialRelay: _detectedRelay),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    for (final c in _tipControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _versionBadge({bool white = false}) {
    if (_appVersion.isEmpty) return const SizedBox.shrink();
    return AnimatedOpacity(
      opacity: _appVersion.isEmpty ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: white
              ? Colors.white.withOpacity(0.10)
              : AppTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: white ? Colors.white.withOpacity(0.15) : AppTheme.borderGray,
          ),
        ),
        child: Text(
          'v$_appVersion',
          style: TextStyle(
            fontSize: 11,
            color: white ? Colors.white.withOpacity(0.5) : AppTheme.textMuted,
            letterSpacing: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _tipsSection({bool white = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 13,
                  color: white
                      ? Colors.white.withOpacity(0.5)
                      : AppTheme.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  'BEFORE YOU START',
                  style: TextStyle(
                    color: white
                        ? Colors.white.withOpacity(0.5)
                        : AppTheme.textMuted.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(_tips.length, (i) {
            return AnimatedBuilder(
              animation: _tipAnimations[i],
              builder: (context, _) {
                final t = _tipAnimations[i].value;
                return Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - t)),
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: i < _tips.length - 1 ? 10 : 0,
                      ),
                      child: _TipCard(tip: _tips[i], darkMode: white),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isMobile) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/images/splash.png', fit: BoxFit.cover),
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.45, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Color(0xF0000000),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _versionBadge(white: true),
                    ),
                    const Spacer(),
                    _tipsSection(white: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(
              painter: AppNoisePainter(
                color: AppTheme.accent,
                opacity: 0.045,
                seed: 77,
                count: 400,
              ),
            ),
            const CustomPaint(
              painter: AppNoisePainter(
                color: Colors.white,
                opacity: 0.018,
                seed: 177,
                count: 200,
              ),
            ),
            const CustomPaint(painter: AppWavePainter(waves: _splashWaves)),

            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _versionBadge(),
                  ),
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        height: 200,
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  _tipsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final _TipData tip;
  final bool darkMode;
  const _TipCard({required this.tip, this.darkMode = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: darkMode
            ? Colors.black.withOpacity(0.55)
            : tip.color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: darkMode
              ? Colors.white.withOpacity(0.12)
              : tip.color.withOpacity(0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tip.color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(tip.icon, color: tip.color, size: 19),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.title,
                  style: TextStyle(
                    color: darkMode ? Colors.white : tip.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip.body,
                  style: TextStyle(
                    color: darkMode
                        ? Colors.white.withOpacity(0.65)
                        : AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.55,
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
