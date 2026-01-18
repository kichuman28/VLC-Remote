import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Volume Slider
///
/// Minimal, clean volume control with debounced updates.
class VolumeSlider extends StatefulWidget {
  final int volumePercent;
  final ValueChanged<int>? onChanged;
  final bool enabled;

  const VolumeSlider({
    super.key,
    required this.volumePercent,
    this.onChanged,
    this.enabled = true,
  });

  @override
  State<VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<VolumeSlider> {
  late double _localValue;
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _localValue = widget.volumePercent.toDouble();
  }

  @override
  void didUpdateWidget(VolumeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_debounceTimer == null || !_debounceTimer!.isActive) {
      _localValue = widget.volumePercent.toDouble();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onChanged(double value) {
    setState(() => _localValue = value);

    // Haptic at boundaries
    if (value.round() == 0 || value.round() == 100) {
      HapticFeedback.selectionClick();
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      widget.onChanged?.call(value.round());
    });
  }

  void _incrementVolume() {
    final newValue = (_localValue + 5).clamp(0.0, 200.0);
    setState(() => _localValue = newValue);
    HapticFeedback.lightImpact();
    widget.onChanged?.call(newValue.round());
  }

  void _decrementVolume() {
    final newValue = (_localValue - 5).clamp(0.0, 200.0);
    setState(() => _localValue = newValue);
    HapticFeedback.lightImpact();
    widget.onChanged?.call(newValue.round());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMuted = _localValue < 1;
    final isBoost = _localValue > 100;

    IconData volumeIcon;
    if (isMuted) {
      volumeIcon = Icons.volume_off_rounded;
    } else if (_localValue < 50) {
      volumeIcon = Icons.volume_down_rounded;
    } else {
      volumeIcon = Icons.volume_up_rounded;
    }

    final activeColor = isBoost
        ? const Color(0xFFFFB020)
        : theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Volume indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              volumeIcon,
              color: isMuted
                  ? theme.colorScheme.onSurfaceVariant
                  : activeColor,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              '${_localValue.round()}%',
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isBoost
                    ? const Color(0xFFFFB020)
                    : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Volume control row with +/- buttons and slider
        Row(
          children: [
            // Decrement button (-5)
            _buildVolumeButton(
              icon: Icons.remove_rounded,
              onPressed: widget.enabled && widget.onChanged != null
                  ? _decrementVolume
                  : null,
              theme: theme,
            ),
            
            // Slider track
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: activeColor,
                  inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
                  thumbColor: activeColor,
                  overlayColor: activeColor.withValues(alpha: 0.15),
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                ),
                child: Slider(
                  value: _localValue.clamp(0, 200),
                  min: 0,
                  max: 200,
                  onChanged:
                      widget.enabled && widget.onChanged != null ? _onChanged : null,
                ),
              ),
            ),
            
            // Increment button (+5)
            _buildVolumeButton(
              icon: Icons.add_rounded,
              onPressed: widget.enabled && widget.onChanged != null
                  ? _incrementVolume
                  : null,
              theme: theme,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVolumeButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required ThemeData theme,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: onPressed != null
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
