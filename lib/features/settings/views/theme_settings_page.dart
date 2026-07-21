import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';

class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appStyleProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      appBar: AppBar(
        title: const Text('主题设置'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _buildSectionTitle('主题模式', isLight),
          const SizedBox(height: 8),
          GlassCard(
            useOwnLayer: true,
            padding: EdgeInsets.zero,
            child: _ThemeModeSelector(
              isLight: isLight,
              currentMode: settings.themeMode,
              onChanged: (mode) =>
                  ref.read(appStyleProvider.notifier).setThemeMode(mode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isLight) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isLight ? AppColors.slate500 : AppColors.slate400,
        ),
      ),
    );
  }
}

class _ThemeModeSelector extends ConsumerWidget {
  final bool isLight;
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeModeSelector({
    required this.isLight,
    required this.currentMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: ThemeMode.values.map((mode) {
        final isSelected = mode == currentMode;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isLight
                        ? AppColors.primary.withAlpha(20)
                        : AppColors.primary.withAlpha(30))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _modeIcon(mode),
                    size: 22,
                    color: isSelected
                        ? AppColors.primary
                        : (isLight ? AppColors.slate400 : AppColors.slate500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _modeLabel(mode),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? AppColors.primary
                          : (isLight ? AppColors.slate500 : AppColors.slate400),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _modeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return '浅色';
      case ThemeMode.dark:
        return '深色';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  IconData _modeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.settings_brightness;
    }
  }
}