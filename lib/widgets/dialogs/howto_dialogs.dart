import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class HowToDialogs {
  static Future<void> showXboxInstructions(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _push(
      context,
      icon: FontAwesomeIcons.xbox,
      color: AppTheme.modeXbox,
      title: loc.howToXboxTitle,
      subtitle: loc.howToXboxSubtitle,
      body: loc.howToXboxBody,
    );
  }

  static Future<void> showNintendoInstructions(
    BuildContext context, {
    String? relayName,
    String? relayIp,
  }) {
    final loc = AppLocalizations.of(context)!;
    return _push(
      context,
      icon: FontAwesomeIcons.gamepad,
      color: AppTheme.modeNintendo,
      title: loc.howToNintendoTitle,
      subtitle: loc.howToNintendoSubtitle,
      body: loc.playInstructionsSwitch(relayName ?? '-', relayIp ?? '-'),
    );
  }

  static Future<void> showFriendsInstructions(
    BuildContext context, {
    String? friendName,
  }) {
    final loc = AppLocalizations.of(context)!;
    return _push(
      context,
      icon: FontAwesomeIcons.userGroup,
      color: AppTheme.modeFriends,
      title: loc.howToFriendsTitle,
      subtitle: loc.howToFriendsSubtitle,
      body: loc.playInstructionsFriends(friendName ?? '-'),
    );
  }

  static Future<void> showJavaInstructions(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _push(
      context,
      icon: FontAwesomeIcons.java,
      color: AppTheme.modeJava,
      title: loc.howToJavaTitle,
      subtitle: loc.howToJavaSubtitle,
      body: loc.howToJavaBody,
    );
  }

  static Future<void> _push(
    BuildContext context, {
    required FaIconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String body,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => InstructionPage(
          icon: icon,
          color: color,
          title: title,
          subtitle: subtitle,
          body: body,
        ),
      ),
    );
  }
}

class InstructionPage extends StatelessWidget {
  final FaIconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String body;

  const InstructionPage({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppTheme.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.30),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withOpacity(0.28),
                          color.withOpacity(0.08),
                          AppTheme.surface,
                        ],
                      ),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.bottomCenter,
                    child: Divider(height: 1, color: AppTheme.borderGray),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 90, 20, 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: color.withOpacity(0.38)),
                          ),
                          child: Center(
                            child: FaIcon(icon, color: color, size: 22),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  color: color.withOpacity(0.85),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            sliver: SliverToBoxAdapter(
              child: StepContent(body: body, color: color),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: AppTheme.surface,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  loc.iUnderstand,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StepContent extends StatelessWidget {
  final String body;
  final Color color;

  const StepContent({super.key, required this.body, required this.color});

  @override
  Widget build(BuildContext context) {
    final lines = body.split('\n');
    final widgets = <Widget>[];

    for (int idx = 0; idx < lines.length; idx++) {
      final raw = lines[idx];
      final line = raw.trim();

      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      final stepMatch = RegExp(r'^(\d+)\.\s+(.+)$').firstMatch(line);
      if (stepMatch != null) {
        widgets.add(
          _StepCard(
            number: int.parse(stepMatch.group(1)!),
            text: stepMatch.group(2)!,
            color: color,
          ),
        );
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      if (line.startsWith('- ') ||
          line.startsWith('– ') ||
          line.startsWith('• ')) {
        final text = line.substring(line.startsWith('• ') ? 2 : 2);
        widgets.add(_BulletCard(text: text, color: color));
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      if (line.endsWith(':') ||
          (line == line.toUpperCase() &&
              line.length > 2 &&
              !line.contains('.'))) {
        widgets.add(_SectionHeader(text: line, color: color));
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      if (line.startsWith('⚠️') ||
          line.startsWith('✅') ||
          line.startsWith('📱') ||
          line.startsWith('🔄')) {
        widgets.add(_NoteBubble(text: line, color: color));
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      widgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderDim),
          ),
          child: Text(
            line,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.65,
            ),
          ),
        ),
      );
      widgets.add(const SizedBox(height: 8));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

class _StepCard extends StatelessWidget {
  final int number;
  final String text;
  final Color color;

  const _StepCard({
    required this.number,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.40)),
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                text,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletCard extends StatelessWidget {
  final String text;
  final Color color;

  const _BulletCard({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderDim),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: color.withOpacity(0.65),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.60,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  final Color color;

  const _SectionHeader({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteBubble extends StatelessWidget {
  final String text;
  final Color color;

  const _NoteBubble({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final isWarning = text.startsWith('⚠️');
    final bubbleColor = isWarning ? AppTheme.warning : AppTheme.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: bubbleColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bubbleColor.withOpacity(0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: bubbleColor,
          fontSize: 13,
          height: 1.6,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
