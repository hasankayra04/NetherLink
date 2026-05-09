import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../util/user_servers.dart';
import '../../util/featured_servers.dart';
import '../../services/navigation_controller.dart';
import 'my_servers_tab.dart';
import '../../screens/partner_servers_screen.dart';
import '../../l10n/app_localizations.dart';

class ServerTabsSection extends StatefulWidget {
  const ServerTabsSection({
    super.key,
    required this.savedServers,
    required this.partnerServersFuture,
    required this.ipController,
    required this.portController,
    required this.onServerSelected,
    required this.onManageServers,
    required this.broadcasting,
    required this.navigationController,
  });

  final List<UserServer> savedServers;
  final Future<List<FeaturedServer>>? partnerServersFuture;
  final TextEditingController ipController;
  final TextEditingController portController;
  final Function(UserServer) onServerSelected;
  final VoidCallback onManageServers;
  final bool broadcasting;
  final NavigationController navigationController;

  @override
  State<ServerTabsSection> createState() => _ServerTabsSectionState();
}

class _ServerTabsSectionState extends State<ServerTabsSection> {
  void _openPartnerServers() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PartnerServersScreen(
          partnerServersFuture: widget.partnerServersFuture,
          ipController: widget.ipController,
          portController: widget.portController,
          navigationController: widget.navigationController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTabHeader(loc),
        const Divider(height: 1, thickness: 1, color: AppTheme.borderDim),
        MyServersTab(
          savedServers: widget.savedServers,
          ipController: widget.ipController,
          portController: widget.portController,
          onServerSelected: widget.onServerSelected,
          broadcasting: widget.broadcasting,
        ),
      ],
    );
  }

  Widget _buildTabHeader(AppLocalizations loc) {
    final bool disabled = widget.broadcasting;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          _TabButton(
            label: 'Partner Servers',
            trailing: Icons.arrow_forward_ios_rounded,
            onTap: _openPartnerServers,
          ),
          const Spacer(),
          _TabButton(
            label: loc.manageServers,
            icon: Icons.settings_rounded,
            disabled: disabled,
            onTap: disabled ? null : widget.onManageServers,
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool disabled;
  final IconData? icon;
  final IconData? trailing;
  final VoidCallback? onTap;

  const _TabButton({
    required this.label,
    this.disabled = false,
    this.icon,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg =
        disabled ? AppTheme.textDisabled : AppTheme.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderGray),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: fg),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: fg,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              Icon(trailing, size: 10, color: fg),
            ],
          ],
        ),
      ),
    );
  }
}