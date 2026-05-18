import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LandingScreen extends StatelessWidget {
  final VoidCallback onGoToConnector;
  final VoidCallback onGoToSkins;
  final VoidCallback onGoToWiki;

  const LandingScreen({
    super.key,
    required this.onGoToConnector,
    required this.onGoToSkins,
    required this.onGoToWiki,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 28),
          _buildGrid(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accent.withOpacity(0.30)),
              ),
              child: const Center(
                child: Text('⛏️', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NetherLink',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Minecraft Companion',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickCard(
                emoji: '🔌',
                title: 'Connector',
                subtitle: 'Connect to Minecraft servers via relay',
                color: AppTheme.accent,
                onTap: onGoToConnector,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickCard(
                emoji: '👕',
                title: 'Skins',
                subtitle: 'View & download Java Edition skins',
                color: const Color(0xFF42A5F5),
                onTap: onGoToSkins,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _QuickCard(
          emoji: '📖',
          title: 'Wiki',
          subtitle: 'Mobs, items, blocks, crafting recipes and more',
          color: AppTheme.success,
          onTap: onGoToWiki,
        ),
      ],
    );
  }
}

class _QuickCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  height: 1.4,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
