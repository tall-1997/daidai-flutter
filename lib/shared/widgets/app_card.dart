import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: appGlassDecoration(
          isLight: isLight,
          borderRadius: borderRadius,
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: appGlassDecoration(
            isLight: isLight,
            borderRadius: 14,
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
        child: ClipOval(
          child: Material(
            color: Colors.transparent,
            child: Ink(
              width: 34,
              height: 34,
              decoration: appGlassDecoration(
                isLight: isLight,
                borderRadius: 17,
                accentColor: accentColor,
                selected: true,
              ),
              child: InkWell(
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

BoxDecoration appGlassDecoration({
  required bool isLight,
  double borderRadius = 16,
  Color? accentColor,
  bool selected = false,
}) {
  final accent = accentColor ?? AppColors.primary;
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isLight
          ? [
              AppColors.lightControlPressed,
              AppColors.lightControl,
            ]
          : [
              selected
                  ? Color.alphaBlend(
                      accent.withAlpha(28),
                      AppColors.darkControlPressed,
                    )
                  : AppColors.darkControlPressed,
              AppColors.darkControl,
            ],
    ),
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: selected
          ? accent.withAlpha(isLight ? 120 : 150)
          : (isLight ? AppColors.lightBorder : AppColors.darkBorder),
      width: selected ? 1.2 : 1,
    ),
    boxShadow: isLight
        ? [
            BoxShadow(
              color: Colors.white.withAlpha(110),
              blurRadius: 10,
              offset: const Offset(0, -1),
            ),
            BoxShadow(
              color: AppColors.slate900.withAlpha(8),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ]
        : [
            BoxShadow(
              color: accent.withAlpha(selected ? 20 : 8),
              blurRadius: selected ? 14 : 8,
            ),
          ],
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
