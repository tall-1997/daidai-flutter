import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../../core/theme/app_theme.dart';

class AppCard extends ConsumerWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool stableForScrolling;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.onTap,
    this.stableForScrolling = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    Widget card = LiquidGlassLens(
      style: appLiquidGlassStyle(
        isLight: isLight,
        borderRadius: borderRadius,
        performanceMode: stableForScrolling,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    if (onTap != null) {
      card = GestureDetector(onTap: onTap, child: card);
    }

    if (margin != null) {
      return Padding(padding: margin!, child: card);
    }
    return card;
  }
}

class AppListTile extends ConsumerWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  const AppListTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: LiquidGlassLens(
        style: appLiquidGlassStyle(
          isLight: isLight,
          borderRadius: 14,
          performanceMode: true,
        ),
        child: ListTile(
          leading: Icon(icon, size: 20),
          title: Text(title),
          trailing: trailing ??
              Icon(
                Icons.chevron_right,
                size: 18,
                color: isLight ? AppColors.slate400 : AppColors.slate600,
              ),
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            ),
        ),
      ),
    );
  }
}

class AppGlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color accentColor;
  final double iconSize;

  const AppGlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.accentColor = AppColors.primary,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final button = SizedBox(
      width: 44,
      height: 44,
      child: Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: LiquidGlassLens(
            style: appLiquidGlassStyle(
              isLight: isLight,
              borderRadius: 18,
              accentColor: accentColor,
              selected: true,
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: Icon(icon, size: iconSize, color: accentColor),
              ),
            ),
          ),
        ),
      ),
    );
    if (tooltip == null) {
      return button;
    }
    return Tooltip(message: tooltip!, child: button);
  }
}

class AppLiquidGlassSurface extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? accentColor;
  final bool selected;
  final bool performanceMode;

  const AppLiquidGlassSurface({
    super.key,
    required this.child,
    this.onTap,
    this.padding = EdgeInsets.zero,
    this.borderRadius = 16,
    this.accentColor,
    this.selected = false,
    this.performanceMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return LiquidGlassLens(
      style: appLiquidGlassStyle(
        isLight: isLight,
        borderRadius: borderRadius,
        accentColor: accentColor,
        selected: selected,
        performanceMode: performanceMode,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class AppLiquidGlassInput extends StatelessWidget {
  final Widget child;
  final double borderRadius;

  const AppLiquidGlassInput({
    super.key,
    required this.child,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppLiquidGlassSurface(
      borderRadius: borderRadius,
      performanceMode: true,
      child: Theme(
        data: theme.copyWith(
          inputDecorationTheme: theme.inputDecorationTheme.copyWith(
            filled: true,
            fillColor: Colors.transparent,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
          ),
        ),
        child: child,
      ),
    );
  }
}

class AppLiquidGlassToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color activeColor;

  const AppLiquidGlassToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: IgnorePointer(
        ignoring: !enabled,
        child: LiquidGlassToggle(
          value: value,
          onChanged: onChanged ?? (_) {},
          activeColor: activeColor,
          inactiveColor: Theme.of(context).brightness == Brightness.light
              ? const Color(0x66708090)
              : const Color(0x88506678),
          pixelRatio: 0.8,
        ),
      ),
    );
  }
}

enum AppLiquidGlassButtonVariant { primary, secondary, danger, warning }

class AppLiquidGlassButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double? width;
  final double height;
  final bool loading;
  final AppLiquidGlassButtonVariant variant;
  final bool performanceMode;

  const AppLiquidGlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.width,
    this.height = 48,
    this.loading = false,
    this.variant = AppLiquidGlassButtonVariant.primary,
    this.performanceMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final color = switch (variant) {
      AppLiquidGlassButtonVariant.primary => AppColors.primary,
      AppLiquidGlassButtonVariant.secondary =>
        isLight ? AppColors.slate600 : AppColors.slate300,
      AppLiquidGlassButtonVariant.danger => AppColors.red500,
      AppLiquidGlassButtonVariant.warning => AppColors.amber500,
    };
    if (loading) {
      return SizedBox(
        width: width,
        height: height,
        child: AppLiquidGlassSurface(
          borderRadius: height / 2,
          accentColor: color,
          selected: true,
          performanceMode: performanceMode,
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            ),
          ),
        ),
      );
    }
    return LiquidGlassButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      width: width,
      height: height,
      foregroundColor: onPressed == null ? AppColors.slate400 : color,
      style: appLiquidGlassStyle(
        isLight: isLight,
        borderRadius: height / 2,
        accentColor: color,
        selected: onPressed != null,
        performanceMode: performanceMode,
      ),
    );
  }
}

LiquidGlassStyle appLiquidGlassStyle({
  required bool isLight,
  double borderRadius = 16,
  Color? accentColor,
  bool selected = false,
  bool performanceMode = false,
}) {
  final accent = accentColor ?? AppColors.primary;
  final tint = selected
      ? Color.alphaBlend(
          accent.withAlpha(isLight ? 18 : 28),
          isLight ? const Color(0x32FFFFFF) : const Color(0x66111C2D),
        )
      : (isLight ? const Color(0x2EFFFFFF) : const Color(0x5C111C2D));
  return LiquidGlassStyle(
    shape: LiquidGlassShape.roundedRectangle(
      cornerRadius: borderRadius,
      borderWidth: selected ? 1.2 : 1,
      borderColor: selected
          ? accent.withAlpha(isLight ? 110 : 145)
          : (isLight ? const Color(0x70FFFFFF) : AppColors.darkBorder),
      lightIntensity: performanceMode ? 0.65 : 1.05,
      lightDirection: 80,
      borderType: OpticalBorder(
        borderSaturation: selected ? 1.35 : 1.05,
        ambientIntensity: performanceMode ? 0.65 : 0.9,
        borderSolidity: selected ? 0.35 : 0.2,
      ),
    ),
    appearance: LiquidGlassAppearance(
      color: tint,
      blur: LiquidGlassBlur(
        sigmaX: performanceMode ? 1.5 : 3,
        sigmaY: performanceMode ? 1.5 : 3,
      ),
      saturation: isLight ? 1.02 : 1.08,
    ),
    refraction: LiquidGlassRefraction(
      distortion: performanceMode ? 0.025 : 0.065,
      distortionWidth: performanceMode ? 10 : 24,
      chromaticAberration: performanceMode ? 0 : 0.001,
    ),
  );
}

Color glassCardColor({
  required bool isLight,
  Color? lightColor,
  Color? darkColor,
}) {
  return isLight
      ? (lightColor ?? AppColors.lightSurface)
      : (darkColor ?? AppColors.darkSurface);
}

Color glassFillColor({
  required bool isLight,
}) {
  return isLight
      ? AppColors.lightSurfaceMuted
      : AppColors.darkSurfaceMuted;
}
