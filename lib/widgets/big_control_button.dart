import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Big Control Button
///
/// Minimal, elegant control button with smooth interactions.
/// Primary button (play/pause) gets enhanced visual treatment.
class BigControlButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final bool isPrimary;

  const BigControlButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 72,
    this.isPrimary = false,
  });

  @override
  State<BigControlButton> createState() => _BigControlButtonState();
}

class _BigControlButtonState extends State<BigControlButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonSize = widget.isPrimary ? widget.size * 1.6 : widget.size;
    final iconSize = widget.isPrimary ? widget.size * 0.75 : widget.size * 0.5;
    final isEnabled = widget.onPressed != null;

    final bgColor = widget.isPrimary
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;

    final iconColor = widget.isPrimary
        ? Colors.white
        : theme.colorScheme.onSurface;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isEnabled ? bgColor : bgColor.withValues(alpha: 0.5),
            boxShadow: widget.isPrimary && isEnabled
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            widget.icon,
            size: iconSize,
            color: isEnabled ? iconColor : iconColor.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
