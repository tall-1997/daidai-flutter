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
    Widget card = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: glassCardColor(isLight: isLight),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isLight ? AppColors.slate200 : AppColors.darkBorder,
        ),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: AppColors.slate900.withAlpha(8),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: child,
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
      child: Container(
        decoration: BoxDecoration(
          color: glassCardColor(isLight: isLight),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isLight ? AppColors.slate200 : AppColors.darkBorder,
          ),
        ),
        child: ListTile(
          leading: Icon(icon, size: 20),
          title: Text(title),
          trailing: trailing ??
              Icon(Icons.chevron_right,
                  size: 18,
                  color: isLight ? AppColors.slate400 : AppColors.slate600),
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
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
