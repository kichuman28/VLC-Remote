import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/vlc_provider.dart';
import '../widgets/big_control_button.dart';
import '../widgets/volume_slider.dart';
import '../widgets/seek_buttons.dart';
import '../widgets/media_settings_sheet.dart';
import 'setup_screen.dart';
import 'file_browser_screen.dart';
import 'playlists_screen.dart';

/// Remote Screen
///
/// Main remote control with clean, minimal design.
/// Optimized for couch usage with large touch targets.
class RemoteScreen extends StatefulWidget {
  const RemoteScreen({super.key});

  @override
  State<RemoteScreen> createState() => _RemoteScreenState();
}

class _RemoteScreenState extends State<RemoteScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final provider = context.read<VlcProvider>();

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        provider.pausePolling();
        break;
      case AppLifecycleState.resumed:
        provider.resumePolling();
        break;
    }
  }

  void _disconnect() {
    final provider = context.read<VlcProvider>();
    provider.disconnect();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const SetupScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _openFileBrowser() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const FileBrowserScreen(),
      ),
    );
  }

  void _openPlaylists() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PlaylistsScreen(),
      ),
    );
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    await context.read<VlcProvider>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Consumer<VlcProvider>(
            builder: (context, provider, _) {
              if (!provider.isConnected) {
                return _buildDisconnectedState(context, provider);
              }

              return RefreshIndicator(
                onRefresh: _onRefresh,
                color: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.surface,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // App Bar
                    SliverAppBar(
                      floating: true,
                      backgroundColor: Colors.transparent,
                      leading: IconButton(
                        icon: const Icon(Icons.folder_open_rounded, size: 22),
                        onPressed: _openFileBrowser,
                        tooltip: 'Browse Files',
                      ),
                      title: _buildConnectionStatus(context, provider),
                      centerTitle: true,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.queue_music_rounded, size: 22),
                          onPressed: _openPlaylists,
                          tooltip: 'Playlists',
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded, size: 20),
                          onPressed: _disconnect,
                          tooltip: 'Disconnect',
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),

                    // Content
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          children: [
                            const Spacer(flex: 1),
                            _buildMediaInfo(context, provider),
                            const Spacer(flex: 2),
                            _buildTrackControls(context, provider),
                            const SizedBox(height: 20),
                            _buildMainControls(context, provider),
                            const Spacer(flex: 2),
                            _buildVolumeControl(context, provider),
                            const SizedBox(height: 24),
                            _buildBottomActions(context, provider),
                            const Spacer(flex: 1),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(BuildContext context, VlcProvider provider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: provider.isConnected
                ? const Color(0xFF00D4AA)
                : const Color(0xFFFF5252),
            boxShadow: provider.isConnected
                ? [
                    BoxShadow(
                      color: const Color(0xFF00D4AA).withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          provider.host,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDisconnectedState(BuildContext context, VlcProvider provider) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 36,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Connection Lost',
              style: GoogleFonts.manrope(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage.isNotEmpty
                  ? provider.errorMessage
                  : 'Unable to reach VLC',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _disconnect,
              child: const Text('Go to Setup'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaInfo(BuildContext context, VlcProvider provider) {
    final theme = Theme.of(context);
    final status = provider.status;

    return Column(
      children: [
        // Title
        Text(
          status.title,
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),

        // Seek Bar
        if (status.hasMedia) ...[
          _buildSeekBar(context, provider, status),
        ] else ...[
           Padding(
             padding: const EdgeInsets.symmetric(vertical: 20),
             child: Text(
               'No media',
               style: GoogleFonts.manrope(
                 fontSize: 14,
                 color: theme.colorScheme.onSurfaceVariant,
               ),
             ),
           ),
        ],
      ],
    );
  }

  // Local state for seeking to prevent jumping while dragging
  double? _dragValue;

  Widget _buildSeekBar(BuildContext context, VlcProvider provider, dynamic status) {
    final theme = Theme.of(context);
    final length = status.length.toDouble();
    final time = status.time.toDouble();
    
    // Safety check for invalid length
    final max = length > 0 ? length : 1.0;
    final value = (_dragValue ?? time).clamp(0.0, max);
    
    String formatTime(int seconds) {
      final duration = Duration(seconds: seconds);
      final h = duration.inHours;
      final m = duration.inMinutes.remainder(60);
      final s = duration.inSeconds.remainder(60);
      if (h > 0) {
        return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      }
      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }

    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
            thumbColor: theme.colorScheme.primary,
          ),
          child: Slider(
            value: value,
            min: 0,
            max: max,
            onChanged: (val) {
              setState(() {
                _dragValue = val;
              });
            },
            onChangeEnd: (val) {
              provider.seekTo(val.toInt());
              setState(() {
                _dragValue = null;
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatTime(value.toInt()),
                style: GoogleFonts.manrope(
                   fontSize: 12,
                   color: theme.colorScheme.onSurfaceVariant,
                   fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                formatTime(length.toInt()),
                style: GoogleFonts.manrope(
                   fontSize: 12,
                   color: theme.colorScheme.onSurfaceVariant,
                   fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Previous/Next track buttons
  Widget _buildTrackControls(BuildContext context, VlcProvider provider) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous track
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            provider.playPrevious();
          },
          icon: const Icon(Icons.skip_previous_rounded),
          iconSize: 32,
          color: theme.colorScheme.onSurfaceVariant,
          tooltip: 'Previous',
        ),
        const SizedBox(width: 48),
        // Next track
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            provider.playNext();
          },
          icon: const Icon(Icons.skip_next_rounded),
          iconSize: 32,
          color: theme.colorScheme.onSurfaceVariant,
          tooltip: 'Next',
        ),
      ],
    );
  }

  Widget _buildMainControls(BuildContext context, VlcProvider provider) {
    final status = provider.status;
    final hasMedia = status.hasMedia;

    return Column(
      children: [
        // Seek buttons
        SeekButtons(
          onSeekBackward: hasMedia ? () => provider.seekBackward() : null,
          onSeekForward: hasMedia ? () => provider.seekForward() : null,
          enabled: hasMedia,
        ),
        const SizedBox(height: 32),

        // Play/Pause
        BigControlButton(
          icon: status.isPlaying
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          onPressed: hasMedia ? () => provider.togglePlayPause() : null,
          isPrimary: true,
        ),
      ],
    );
  }

  Widget _buildVolumeControl(BuildContext context, VlcProvider provider) {
    return VolumeSlider(
      volumePercent: provider.status.volumePercent,
      onChanged: (value) => provider.setVolume(value),
      enabled: true,
    );
  }

  Widget _buildBottomActions(BuildContext context, VlcProvider provider) {
    final theme = Theme.of(context);
    final status = provider.status;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Browse Files button
          _buildActionButton(
            icon: Icons.folder_open_rounded,
            label: 'Browse',
            onPressed: _openFileBrowser,
            theme: theme,
          ),
          const SizedBox(width: 8),
          // Playlists button
          _buildActionButton(
            icon: Icons.queue_music_rounded,
            label: 'Playlists',
            onPressed: _openPlaylists,
            theme: theme,
          ),
          const SizedBox(width: 8),
          // Settings button (audio, subtitles, speed)
          _buildActionButton(
            icon: Icons.tune_rounded,
            label: 'Settings',
            onPressed: status.hasMedia ? () => MediaSettingsSheet.show(context) : null,
            theme: theme,
          ),
          const SizedBox(width: 8),
          // Fullscreen button
          _buildActionButton(
            icon: status.fullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
            label: 'Fullscreen',
            onPressed: status.hasMedia
                ? () {
                    HapticFeedback.lightImpact();
                    provider.toggleFullscreen();
                  }
                : null,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required ThemeData theme,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: theme.colorScheme.onSurfaceVariant,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

