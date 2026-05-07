import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../util/user_servers.dart';
import '../../util/featured_servers.dart';
import 'my_servers_tab.dart';
import 'partner_servers_tab.dart';

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
  });

  final List<UserServer> savedServers;
  final Future<List<FeaturedServer>>? partnerServersFuture;
  final TextEditingController ipController;
  final TextEditingController portController;
  final Function(UserServer) onServerSelected;
  final VoidCallback onManageServers;
  final bool broadcasting;

  @override
  State<ServerTabsSection> createState() => _ServerTabsSectionState();
}

class _ServerTabsSectionState extends State<ServerTabsSection> {
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTabHeader(),
        const Divider(height: 1, thickness: 1, color: AppTheme.borderDim),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _activeTab == 0
              ? MyServersTab(
                  key: const ValueKey(0),
                  savedServers: widget.savedServers,
                  ipController: widget.ipController,
                  portController: widget.portController,
                  onServerSelected: widget.onServerSelected,
                  broadcasting: widget.broadcasting,
                )
              : PartnerServersTab(
                  key: const ValueKey(1),
                  partnerServersFuture: widget.partnerServersFuture,
                  ipController: widget.ipController,
                  portController: widget.portController,
                ),
        ),
      ],
    );
  }

  Widget _buildTabHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Row(
        children: [
          _tab(label: 'My Servers', index: 0),
          const SizedBox(width: 6),
          _tab(label: 'Partner Servers', index: 1),
          const Spacer(),
          if (_activeTab == 0)
            GestureDetector(
              onTap: widget.broadcasting ? null : widget.onManageServers,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
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

  Widget _tab({required String label, required int index}) {
    final isActive = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.surfaceLight : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppTheme.borderLight : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
