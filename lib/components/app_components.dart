import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/design_system.dart';

/// Apple-inspired UI components for consistent design
/// Clean, polished, and highly reusable

/// Primary action button with brand styling
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.isEnabled = true,
    this.size = AppButtonSize.standard,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final bool isEnabled;
  final AppButtonSize size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size.height,
      child: ElevatedButton(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppDesignSystem.primaryNavy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppDesignSystem.systemGray4,
          disabledForegroundColor: AppDesignSystem.systemGray,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignSystem.radiusMd),
          ),
          minimumSize: Size(double.infinity, size.height),
          textStyle: size.textStyle,
        ),
        child: isLoading
            ? SizedBox(
                height: AppDesignSystem.iconMd,
                width: AppDesignSystem.iconMd,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : child,
      ),
    );
  }
}

/// Secondary action button with outline styling
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.isEnabled = true,
    this.size = AppButtonSize.standard,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final bool isEnabled;
  final AppButtonSize size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size.height,
      child: OutlinedButton(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppDesignSystem.primaryNavy,
          disabledForegroundColor: AppDesignSystem.systemGray,
          side: BorderSide(
            color: isEnabled ? AppDesignSystem.primaryNavy : AppDesignSystem.systemGray4,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignSystem.radiusMd),
          ),
          minimumSize: Size(double.infinity, size.height),
          textStyle: size.textStyle,
        ),
        child: isLoading
            ? SizedBox(
                height: AppDesignSystem.iconMd,
                width: AppDesignSystem.iconMd,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isEnabled ? AppDesignSystem.primaryNavy : AppDesignSystem.systemGray,
                  ),
                ),
              )
            : child,
      ),
    );
  }
}

/// Text button for tertiary actions
class AppTextButton extends StatelessWidget {
  const AppTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isEnabled = true,
    this.size = AppButtonSize.standard,
    this.color,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool isEnabled;
  final AppButtonSize size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size.height,
      child: TextButton(
        onPressed: isEnabled ? onPressed : null,
        style: TextButton.styleFrom(
          foregroundColor: color ?? AppDesignSystem.primaryOrange,
          disabledForegroundColor: AppDesignSystem.systemGray,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignSystem.radiusMd),
          ),
          minimumSize: Size(double.infinity, size.height),
          textStyle: size.textStyle,
        ),
        child: child,
      ),
    );
  }
}

/// Button size configuration
enum AppButtonSize {
  small,
  standard,
  large;

  double get height {
    switch (this) {
      case AppButtonSize.small:
        return 36.0;
      case AppButtonSize.standard:
        return AppDesignSystem.touchTargetMin;
      case AppButtonSize.large:
        return AppDesignSystem.touchTargetLarge;
    }
  }

  TextStyle get textStyle {
    switch (this) {
      case AppButtonSize.small:
        return AppDesignSystem.footnote.copyWith(fontWeight: FontWeight.w600);
      case AppButtonSize.standard:
        return AppDesignSystem.headline;
      case AppButtonSize.large:
        return AppDesignSystem.title3.copyWith(fontWeight: FontWeight.w600);
    }
  }
}

/// Card component with Apple-style design
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation = 0,
    this.isSelected = false,
    this.border,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double elevation;
  final bool isSelected;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin ?? const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spacingMd,
        vertical: AppDesignSystem.spacingSm,
      ),
      decoration: BoxDecoration(
        color: isSelected 
            ? Colors.green[50] 
            : backgroundColor ?? AppDesignSystem.secondarySystemGroupedBackground,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusMd),
        border: border,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: const Color(0x14000000),
                  offset: Offset(0, elevation),
                  blurRadius: elevation * 2,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppDesignSystem.spacingMd),
        child: child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusMd),
          child: card,
        ),
      );
    }

    return card;
  }
}

/// List tile component with Apple-style design
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.backgroundColor,
    this.showDivider = true,
  });

  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesignSystem.spacingMd,
            vertical: AppDesignSystem.spacingMd,
          ),
          decoration: showDivider
              ? const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppDesignSystem.separator,
                      width: 0.5,
                    ),
                  ),
                )
              : null,
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppDesignSystem.spacingMd),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle(
                      style: AppDesignSystem.body,
                      child: title,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppDesignSystem.spacing2xs),
                      DefaultTextStyle(
                        style: AppDesignSystem.footnote.copyWith(
                          color: AppDesignSystem.labelSecondary,
                        ),
                        child: subtitle!,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppDesignSystem.spacingMd),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Search bar component
class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppDesignSystem.spacingMd),
      decoration: BoxDecoration(
        color: AppDesignSystem.tertiarySystemGroupedBackground,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusMd),
        boxShadow: const [AppDesignSystem.shadowSm],
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: AppDesignSystem.body,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(
            Icons.search,
            color: AppDesignSystem.systemGray,
            size: AppDesignSystem.iconMd,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: AppDesignSystem.systemGray,
                    size: AppDesignSystem.iconMd,
                  ),
                  onPressed: () {
                    controller.clear();
                    onChanged?.call('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDesignSystem.spacingMd,
            vertical: AppDesignSystem.spacingMd,
          ),
        ),
      ),
    );
  }
}

/// Progress indicator component
class AppProgressIndicator extends StatelessWidget {
  const AppProgressIndicator({
    super.key,
    this.value,
    this.backgroundColor,
    this.valueColor,
    this.strokeWidth = 3.0,
  });

  final double? value;
  final Color? backgroundColor;
  final Color? valueColor;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(
      value: value,
      backgroundColor: backgroundColor ?? AppDesignSystem.systemGray5,
      valueColor: AlwaysStoppedAnimation<Color>(
        valueColor ?? AppDesignSystem.primaryOrange,
      ),
      strokeWidth: strokeWidth,
    );
  }
}

/// Loading overlay component
class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  final bool isLoading;
  final Widget child;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(AppDesignSystem.spacingLg),
                decoration: BoxDecoration(
                  color: AppDesignSystem.secondarySystemGroupedBackground,
                  borderRadius: BorderRadius.circular(AppDesignSystem.radiusMd),
                  boxShadow: const [AppDesignSystem.shadowLg],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppProgressIndicator(),
                    if (message != null) ...[
                      const SizedBox(height: AppDesignSystem.spacingMd),
                      Text(
                        message!,
                        style: AppDesignSystem.callout,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Icon button with proper touch targets
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = AppDesignSystem.touchTargetMin,
    this.iconSize = AppDesignSystem.iconMd,
    this.color,
    this.backgroundColor,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? color;
  final Color? backgroundColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: size,
      height: size,
      child: Material(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(size / 2),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(size / 2),
          child: Center(
            child: Icon(
              icon,
              size: iconSize,
              color: color ?? AppDesignSystem.labelSecondary,
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}

/// Haptic feedback helper
class AppHaptics {
  static void light() {
    HapticFeedback.lightImpact();
  }

  static void medium() {
    HapticFeedback.mediumImpact();
  }

  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  static void selection() {
    HapticFeedback.selectionClick();
  }
}