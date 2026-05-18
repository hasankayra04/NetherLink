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
  final Future<List<FeaturedServer>>? partnerServersFuture;
  final TextEditingController ipController;
  final TextEditingController portController;
  final VoidCallback onWebsite;
  final VoidCallback onDiscord;
  final VoidCallback onAternos;
  final VoidCallback onLanguage;

  const LandingScreen({
    super.key,
    required this.onGoToConnector,
    required this.onGoToSkins,
    required this.onGoToWiki,
    required this.onGoToPartners,
    required this.partnerServersFuture,
    required this.ipController,
    required this.portController,
    required this.onWebsite,
    required this.onDiscord,
    required this.onAternos,
    required this.onLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeaturedServers(context),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildGrid(context),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildLinks(),
          ),
        ],
      ),
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
      ],
    );
  }

  Widget _buildFeaturedServers(BuildContext context) {
    return FeaturedServerHero(
      partnerServersFuture: partnerServersFuture,
      ipController: ipController,
      portController: portController,
      onSelected: onGoToConnector,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
    );
  }

  Widget _buildLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Links',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _LinkButton(
                icon: FontAwesomeIcons.globe,
                label: 'Website',
                color: const Color(0xFF42A5F5),
                onTap: onWebsite,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LinkButton(
                icon: FontAwesomeIcons.discord,
                label: 'Discord',
                color: const Color(0xFF7289DA),
                onTap: onDiscord,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LinkButton(
                icon: FontAwesomeIcons.server,
                label: 'Aternos',
                color: const Color(0xFF7AC74F),
                onTap: onAternos,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LinkButton(
                icon: FontAwesomeIcons.language,
                label: 'Language',
                color: AppTheme.textSecondary,
                onTap: onLanguage,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LinkButton extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _LinkButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(icon, size: 16, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 130,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(imagePath, fit: BoxFit.cover),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.4, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.25),
                        Colors.black.withOpacity(0.72),
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
                        title,
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
                        subtitle,
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
