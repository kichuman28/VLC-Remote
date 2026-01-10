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

        // Slider track
        SliderTheme(
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
      ],
    );
  }
}
