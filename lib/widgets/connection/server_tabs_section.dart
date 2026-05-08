import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../util/user_servers.dart';
import '../../util/featured_servers.dart';
import '../../services/navigation_controller.dart';
import 'my_servers_tab.dart';
import '../../screens/partner_servers_screen.dart';

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTabHeader(),
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

  Widget _buildTabHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: const Text(
              'My Servers',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _openPartnerServers,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Partner Servers',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: widget.broadcasting ? null : widget.onManageServers,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceRaised,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderGray),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.settings_rounded,
                    size: 12,
                    color: widget.broadcasting
                        ? AppTheme.textDisabled
                        : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Manage',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: widget.broadcasting
                          ? AppTheme.textDisabled
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
