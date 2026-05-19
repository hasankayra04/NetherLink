import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../../services/navigation_controller.dart';
import '../../constants/app_constants.dart';
import '../../theme/app_theme.dart';

class BottomGlassSimpleNavBar extends StatelessWidget {
  final NavigationController navigationController;
  final VoidCallback? onHomeTap;
  final VoidCallback? onConnectorTap;
  final VoidCallback? onSkinsTap;
  final VoidCallback? onWikiTap;
  final VoidCallback? onProfileTap;
  final String? activeItem;
  final bool dark;
  final String? selectedRelayIp;
  final void Function(String?)? onRelayChanged;

  final bool isLandingPage;
  final VoidCallback? onWebsiteTap;
  final VoidCallback? onDiscordTap;
  final VoidCallback? onaternosTap;
  final VoidCallback? onLanguageTap;

  const BottomGlassSimpleNavBar({
    super.key,
    required this.navigationController,
    this.onHomeTap,
    this.onConnectorTap,
    this.onSkinsTap,
    this.onWikiTap,
    this.onProfileTap,
    this.activeItem,
    this.dark = true,
    this.selectedRelayIp,
    this.onRelayChanged,
    this.isLandingPage = false,
    this.onWebsiteTap,
    this.onDiscordTap,
    this.onaternosTap,
    this.onLanguageTap,
  });

  @override
  Widget build(BuildContext context) {
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
            children: isLandingPage
                ? [
                    _NavItem(
                      icon: FontAwesomeIcons.earthEurope,
                      label: 'Website',
                      isActive: false,
                      onTap: onWebsiteTap,
                    ),
                    _NavItem(
                      icon: FontAwesomeIcons.discord,
                      label: 'Discord',
                      isActive: false,
                      onTap: onDiscordTap,
                    ),
                    _NavItem(
                      icon: FontAwesomeIcons.server,
                      label: 'Aternos',
                      isActive: false,
                      onTap: onaternosTap,
                    ),
                    _NavItem(
                      icon: FontAwesomeIcons.language,
                      label: 'Language',
                      isActive: false,
                      onTap: onLanguageTap,
                    ),
                    _NavItem(
                      icon: FontAwesomeIcons.user,
                      label: 'Profile',
                      isActive: activeItem == 'profile',
                      onTap: onProfileTap,
                    ),
                  ]
                : [
                    _NavItem(
                      icon: FontAwesomeIcons.house,
                      label: 'Home',
                      isActive: activeItem == 'home',
                      onTap: onHomeTap,
                    ),
                    _NavItem(
                      icon: FontAwesomeIcons.plug,
                      label: 'Connector',
                      isActive: activeItem == 'connector',
                      onTap: onConnectorTap,
                    ),
                    _NavItem(
                      icon: FontAwesomeIcons.shirt,
                      label: 'Skins',
                      isActive: activeItem == 'skins',
                      onTap: onSkinsTap,
                    ),
                    _NavItem(
                      icon: FontAwesomeIcons.bookOpen,
                      label: 'Wiki',
                      isActive: activeItem == 'wiki',
                      onTap: onWikiTap,
                    ),
                    _NavItem(
                      icon: FontAwesomeIcons.user,
                      label: 'Profile',
                      isActive: activeItem == 'profile',
                      onTap: onProfileTap,
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = AppTheme.accent;
    final Color inactiveColor = AppTheme.textSecondary;
    final Color color = isActive ? activeColor : inactiveColor;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withOpacity(0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
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
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(top: 3),
                width: isActive ? 4 : 0,
                height: isActive ? 4 : 0,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MoreSheetContent extends StatelessWidget {
  final AppLocalizations loc;
  final NavigationController navigationController;
  final String? selectedRelayIp;
  final VoidCallback onClose;
  final void Function(String?) onRelayChanged;
  final VoidCallback onHowTo;
  final VoidCallback? onHelp;
  final VoidCallback? onConsole;

  const MoreSheetContent({
    super.key,
    required this.loc,
    required this.navigationController,
    required this.onClose,
    required this.onRelayChanged,
    required this.onHowTo,
    this.selectedRelayIp,
    this.onHelp,
    this.onConsole,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppTheme.borderGray)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onClose,
              behavior: HitTestBehavior.opaque,
              child: Center(
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
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: AppTheme.accent.withOpacity(0.25),
                      ),
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
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _RegionSelector(
                      selectedIp: selectedRelayIp,
                      onChanged: onRelayChanged,
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.borderDim, height: 1),
                    const SizedBox(height: 12),
                    _SheetTile(
                      icon: FontAwesomeIcons.headset,
                      color: AppTheme.warning,
                      label: loc.support,
                      onTap:
                          onHelp ??
                          () {
                            onClose();
                            navigationController.showHelpMenu(context);
                          },
                    ),
                    const SizedBox(height: 8),
                    _SheetTile(
                      icon: FontAwesomeIcons.bookOpen,
                      color: AppTheme.accent,
                      label: loc.howToUseMenu,
                      onTap: onHowTo,
                    ),
                    const SizedBox(height: 8),
                    _SheetTile(
                      icon: FontAwesomeIcons.terminal,
                      color: AppTheme.info,
                      label: loc.console,
                      onTap:
                          onConsole ??
                          () {
                            onClose();
                            navigationController.showConsole(context);
                          },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AternosTile extends StatelessWidget {
  final String? subtitle;
  final VoidCallback onTap;
  const _AternosTile({this.subtitle, required this.onTap});
  static const _color = Color(0xFF52CAFF);

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
            color: _color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: _color.withOpacity(0.20)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      'assets/icons/aternos.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aternos',
                      style: TextStyle(
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
                color: _color.withOpacity(0.45),
                size: 13,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final FaIconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _SheetTile({
    required this.icon,
    required this.color,
    required this.label,
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
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
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
