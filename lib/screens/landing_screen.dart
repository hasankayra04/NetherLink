import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import '../util/partners_servers.dart';
import '../widgets/featured_server_hero.dart';

class LandingScreen extends StatelessWidget {
  final VoidCallback onGoToConnector;
  final VoidCallback onGoToSkins;
  final VoidCallback onGoToWiki;
  final VoidCallback onGoToPartners;
  final VoidCallback onGoToPlayerLookup;
  final Future<List<FeaturedServer>>? partnerServersFuture;
  final TextEditingController ipController;
  final TextEditingController portController;
  final VoidCallback? onWebsiteTap;
  final VoidCallback? onDiscordTap;
  final VoidCallback? onLanguageTap;

  const LandingScreen({
    super.key,
    required this.onGoToConnector,
    required this.onGoToSkins,
    required this.onGoToWiki,
    required this.onGoToPartners,
    required this.onGoToPlayerLookup,
    required this.partnerServersFuture,
    required this.ipController,
    required this.portController,
    this.onWebsiteTap,
    this.onDiscordTap,
    this.onLanguageTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
                      child: Row(
                        children: [
                          const Text(
                            'Home',
                            style: TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          _HeaderIconButton(
                            icon: FontAwesomeIcons.earthEurope,
                            tooltip: 'Website',
                            onTap: onWebsiteTap,
                          ),
                          _HeaderIconButton(
                            icon: FontAwesomeIcons.discord,
                            tooltip: 'Discord',
                            onTap: onDiscordTap,
                          ),
                          _HeaderIconButton(
                            icon: FontAwesomeIcons.language,
                            tooltip: 'Language',
                            onTap: onLanguageTap,
                          ),
                        ],
                      ),
                    ),
                    _buildFeaturedServers(context),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildGrid(context),
                ),
                const SizedBox(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickCard(
                title: 'Connector',
                subtitle: 'Connect to servers via relay',
                color: AppTheme.accent,
                imagePath: 'assets/images/tunnel.png',
                onTap: onGoToConnector,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickCard(
                title: 'Skins',
                subtitle: 'View & edit Java skins',
                color: const Color(0xFF42A5F5),
                imagePath: 'assets/images/skin.png',
                onTap: onGoToSkins,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickCard(
                title: 'Wiki',
                subtitle: 'Mobs, blocks, recipes & more',
                color: AppTheme.success,
                imagePath: 'assets/images/wiki.png',
                onTap: onGoToWiki,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickCard(
                title: 'Featured',
                subtitle: 'Partner Minecraft servers',
                color: const Color(0xFFFFB300),
                imagePath: 'assets/images/feature.png',
                onTap: onGoToPartners,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _QuickCard(
          title: 'Players',
          subtitle: 'Look up Java & Bedrock profiles',
          color: const Color(0xFF7B61FF),
          imagePath: 'assets/images/players.png',
          onTap: onGoToPlayerLookup,
        ),
      ],
    );
  }

  Widget _buildFeaturedServers(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: FeaturedServerHero(
        partnerServersFuture: partnerServersFuture,
        ipController: ipController,
        portController: portController,
        onSelected: onGoToConnector,
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final FaIconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: FaIcon(
            icon,
            size: 16,
            color: AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}

class _QuickCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final Color color;
  final String imagePath;
  final VoidCallback onTap;

  const _QuickCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.imagePath,
    required this.onTap,
  });

  @override
  State<_QuickCard> createState() => _QuickCardState();
}

class _QuickCardState extends State<_QuickCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
          scale: _pressed ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 130,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(widget.imagePath, fit: BoxFit.cover),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.4, 1.0],
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(_pressed ? 0.35 : 0.25),
                          Colors.black.withOpacity(_pressed ? 0.85 : 0.72),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.9),
                                blurRadius: 12,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 10,
                            height: 1.4,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.95),
                                blurRadius: 10,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}

