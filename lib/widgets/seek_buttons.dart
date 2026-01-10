import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Seek Buttons
///
/// Clean, minimal ±10 second seek controls.
class SeekButtons extends StatelessWidget {
  final VoidCallback? onSeekBackward;
  final VoidCallback? onSeekForward;
  final bool enabled;

  const SeekButtons({
    super.key,
    this.onSeekBackward,
    this.onSeekForward,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SeekButton(
          icon: Icons.replay_10_rounded,
          onPressed: enabled ? onSeekBackward : null,
        ),
        const SizedBox(width: 64),
        _SeekButton(
          icon: Icons.forward_10_rounded,
          onPressed: enabled ? onSeekForward : null,
        ),
      ],
    );
  }
}

class _SeekButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _SeekButton({
    required this.icon,
    this.onPressed,
  });

  @override
  State<_SeekButton> createState() => _SeekButtonState();
}

class _SeekButtonState extends State<_SeekButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = widget.onPressed != null;

    return GestureDetector(
      onTapDown: (_) {
        if (isEnabled) _controller.forward();
      },
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: isEnabled
          ? () {
              HapticFeedback.lightImpact();
              widget.onPressed!();
            }
          : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            widget.icon,
            size: 28,
            color: isEnabled
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}
