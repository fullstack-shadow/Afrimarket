import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

enum AppButtonVariant { primary, secondary }

class AppButton extends StatefulWidget {
  final String? label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool animateTap;
  final Duration animationDuration;
  final AppButtonVariant variant;

  const AppButton.primary({
    Key? key,
    this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 48,
    this.borderRadius = 8,
    this.padding,
    this.animateTap = true,
    this.animationDuration = const Duration(milliseconds: 100),
  }) : variant = AppButtonVariant.primary, super(key: key);

  const AppButton.secondary({
    Key? key,
    this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 48,
    this.borderRadius = 8,
    this.padding,
    this.animateTap = true,
    this.animationDuration = const Duration(milliseconds: 100),
  }) : variant = AppButtonVariant.secondary, super(key: key);

  const AppButton.text({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    Color? textColor,
  }) : this.secondary(
          label: label,
          onPressed: onPressed,
          isLoading: isLoading,
          icon: icon,
          backgroundColor: Colors.transparent,
          textColor: textColor,
          height: 40,
        );

  const AppButton.icon({
    Key? key,
    required IconData icon,
    VoidCallback? onPressed,
    bool isLoading = false,
    Color? backgroundColor,
    Color? iconColor,
    double size = 48,
  }) : this.primary(
          label: null,
          onPressed: onPressed,
          isLoading: isLoading,
          icon: icon,
          backgroundColor: backgroundColor,
          textColor: iconColor,
          width: size,
          height: size,
        );

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
      lowerBound: 0.95,
      upperBound: 1.0,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (widget.animateTap) {
      await _controller.forward();
      await _controller.reverse();
    }
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = SchedulerBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;

    final child = _buildButtonContent(theme);

    return GestureDetector(
      onTapDown: (_) => widget.animateTap ? _controller.forward() : null,
      onTapUp: (_) => widget.animateTap ? _controller.reverse() : null,
      onTapCancel: () => widget.animateTap ? _controller.reverse() : null,
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildButtonContainer(theme, isDark, child),
      ),
    );
  }

  Widget _buildButtonContainer(ThemeData theme, bool isDark, Widget child) {
    final isPrimary = widget.variant == AppButtonVariant.primary;
    final isSecondary = widget.variant == AppButtonVariant.secondary;
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        color: widget.backgroundColor ?? (isPrimary ? theme.primaryColor : null),
        border: isSecondary ? Border.all(color: theme.primaryColor) : null,
      ),
      child: Center(child: child),
    );
  }

  Widget _buildButtonContent(ThemeData theme) {
    final isPrimary = widget.variant == AppButtonVariant.primary;
    final isSecondary = widget.variant == AppButtonVariant.secondary;
    if (widget.isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (widget.label == null && widget.icon != null) {
      return Icon(
        widget.icon,
        size: 24,
        color: widget.textColor ?? (isPrimary ? Colors.white : theme.primaryColor),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(
            widget.icon,
            size: 20,
            color: widget.textColor ?? (isPrimary ? Colors.white : theme.primaryColor),
          ),
          const SizedBox(width: 8),
        ],
        if (widget.label != null)
          Text(
            widget.label!,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: widget.textColor ?? (isPrimary ? Colors.white : theme.primaryColor),
            ),
          ),
      ],
    );
  }
}