import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../../services/navigation_controller.dart';
import '../../constants/app_constants.dart';
import '../../theme/app_theme.dart';

class BottomGlassSimpleNavBar extends StatelessWidget {
  final NavigationController navigationController;
  final VoidCallback? onHowToTapOverride;
  final VoidCallback? onHelpTapOverride;
  final bool dark;
  final String? selectedRelayIp;
  final void Function(String?)? onRelayChanged;

  const BottomGlassSimpleNavBar({
    super.key,
    required this.navigationController,
    this.onHowToTapOverride,
    this.onHelpTapOverride,
    this.dark = true,
    this.selectedRelayIp,
    this.onRelayChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.borderGray, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              _NavItem(
                icon: FontAwesomeIcons.discord,
                label: loc.discord,
                accentColor: const Color(0xFF5865F2),
                onTap: () => navigationController.openDiscord(context),
              ),
              _NavItem(
                icon: FontAwesomeIcons.bookOpen,
                label: loc.howToUseMenu,
                onTap: () => onHowToTapOverride != null
                    ? onHowToTapOverride!()
                    : navigationController.showHowToMenu(context),
              ),
              _NavItem(
                icon: FontAwesomeIcons.headset,
                label: loc.support,
                onTap: () => onHelpTapOverride != null
                    ? onHelpTapOverride!()
                    : navigationController.showHelpMenu(context),
              ),
              _NavItem(
                icon: FontAwesomeIcons.ellipsis,
                label: loc.more,
                onTap: () => _showMoreSheet(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MoreSheet(
        navigationController: navigationController,
        selectedRelayIp: selectedRelayIp,
        onRelayChanged: onRelayChanged,
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? accentColor;

  const _NavItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppTheme.textSecondary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(icon, size: 18, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreSheet extends StatelessWidget {
  final NavigationController navigationController;
  final String? selectedRelayIp;
  final void Function(String?)? onRelayChanged;

  const _MoreSheet({
    required this.navigationController,
    this.selectedRelayIp,
    this.onRelayChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppTheme.borderGray)),
      ),
      padding: EdgeInsets.fromLTRB(16, 0, 16, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.borderLight,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.25)),
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.ellipsis,
                    color: AppTheme.accent,
                    size: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                loc.more,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          _RegionSelector(
            selectedIp: selectedRelayIp,
            onChanged: (ip) {
              onRelayChanged?.call(ip);
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.borderDim, height: 1),
          const SizedBox(height: 12),

          _SheetTile(
            icon: FontAwesomeIcons.terminal,
            color: AppTheme.info,
            label: loc.console,
            onTap: () {
              Navigator.of(context).pop();
              navigationController.showConsole(context);
            },
          ),
          const SizedBox(height: 8),
          _SheetTile(
            icon: FontAwesomeIcons.globe,
            color: AppTheme.success,
            label: loc.website,
            onTap: () {
              Navigator.of(context).pop();
              navigationController.openWebsite(context);
            },
          ),
          const SizedBox(height: 8),
          _SheetTile(
            icon: FontAwesomeIcons.language,
            color: AppTheme.warning,
            label: loc.changeLanguage,
            onTap: () {
              Navigator.of(context).pop();
              navigationController.showLanguageDialog(context);
            },
          ),
          const SizedBox(height: 8),
          _SheetTile(
            icon: FontAwesomeIcons.server,
            color: const Color(0xFF52CAFF),
            label: 'Aternos',
            subtitle: loc.aternosSubtext,
            onTap: () {
              Navigator.of(context).pop();
              navigationController.openWebsiteWithCustomUrl(
                context,
                'https://aternos.org/',
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final FaIconData icon;
  final Color color;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _SheetTile({
    required this.icon,
    required this.color,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: color.withOpacity(0.20)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(child: FaIcon(icon, color: color, size: 15)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: color.withOpacity(0.45),
                size: 13,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegionSelector extends StatelessWidget {
  final String? selectedIp;
  final void Function(String?) onChanged;

  const _RegionSelector({required this.selectedIp, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'NETHERLINK SERVER',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: AppConstants.relayServers.map((relay) {
            final ip = relay['ip'] as String;
            final name = relay['name'] as String;
            final isSelected = selectedIp == ip;
            final isFirst = relay == AppConstants.relayServers.first;

            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(ip),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(
                    right: isFirst ? 6 : 0,
                    left: isFirst ? 0 : 6,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 13,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accent.withOpacity(0.10)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.accent.withOpacity(0.45)
                          : AppTheme.borderGray,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.success
                              : AppTheme.textDisabled,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        name,
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
