import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Setup Guide',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntroCard(theme),
            const SizedBox(height: 32),
            Text(
              'Step-by-Step Instructions',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            _buildStep(
              theme,
              step: 1,
              title: 'Open Preferences',
              content:
                  'Launch VLC Media Player on your computer. Go to the top menu bar, click "Tools", and select "Preferences" (or press Ctrl+P).',
              icon: Icons.settings_rounded,
            ),
            _buildConnector(theme),
            _buildStep(
              theme,
              step: 2,
              title: 'Show All Settings',
              content:
                  'This is the most important step! Look at the BOTTOM LEFT corner of the Preferences window. You will see two radio buttons: "Simple" and "All".\n\nClick "All" to switch to the advanced settings view.',
              icon: Icons.tune_rounded,
              isImportant: true,
            ),
            _buildConnector(theme),
            _buildStep(
              theme,
              step: 3,
              title: 'Enable Web Interface',
              content:
                  'In the left sidebar menu, scroll down to find "Interface". Click on "Main interfaces".\n\nIn the right panel, check the box labeled "Web" to enable the remote control interface.',
              icon: Icons.web_rounded,
            ),
            _buildConnector(theme),
            _buildStep(
              theme,
              step: 4,
              title: 'Set Your Password',
              content:
                  'Back in the left sidebar, click the small arrow/triangle next to "Main interfaces" to expand it. Click on "Lua".\n\nOn the right side, find the "Lua HTTP" section. Enter a password of your choice in the "Password" field.',
              icon: Icons.lock_outline_rounded,
              isImportant: true,
            ),
            _buildConnector(theme),
            _buildStep(
              theme,
              step: 5,
              title: 'Save & Restart',
              content:
                  'Click the "Save" button at the bottom right. Now, completely CLOSE VLC and open it again for the changes to take effect.',
              icon: Icons.restart_alt_rounded,
            ),
            _buildConnector(theme),
            _buildStep(
              theme,
              step: 6,
              title: 'Find Your IP Address',
              content:
                  'You need your computer\'s local IP address to connect.\n\n• Windows: Open Command Prompt, type "ipconfig" and look for "IPv4 Address".\n',
              icon: Icons.wifi_find_rounded,
            ),
            const SizedBox(height: 32),
            _buildInfoCard(
              theme,
              title: 'About Port 8080',
              content:
                  'The "Port" number is like a door number for programs to talk to each other. VLC uses 8080 by default. You usually don\'t need to change this unless another app is already using it.',
              icon: Icons.numbers_rounded,
            ),
            const SizedBox(height: 24),
            _buildFirewallNote(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.tertiary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cast_connected_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Connect VLC to your phone',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'To control VLC remotely, we need to enable the "Web Interface" feature on your computer. It takes less than a minute!',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(
    ThemeData theme, {
    required int step,
    required String title,
    required String content,
    required IconData icon,
    bool isImportant = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isImportant
            ? theme.colorScheme.primary.withValues(alpha: 0.05)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: isImportant
            ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3), width: 1.5)
            : Border.all(color: Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isImportant ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    step.toString(),
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isImportant ? Colors.white : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isImportant)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'IMPORTANT',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnector(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 39, top: 4, bottom: 4),
      child: Container(
        width: 2,
        height: 24,
        color: theme.colorScheme.surfaceContainerHighest,
      ),
    );
  }

  Widget _buildFirewallNote(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_outlined,
            color: theme.colorScheme.secondary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Firewall Warning',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'If connection fails, your computer\'s firewall might be blocking VLC. When you restart VLC, you may see a firewall popup. Make sure to click "Allow Access".',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, {required String title, required String content, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
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
