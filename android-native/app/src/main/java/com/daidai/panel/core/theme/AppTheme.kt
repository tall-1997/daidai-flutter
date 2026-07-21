package com.daidai.panel.core.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.platform.LocalContext
import androidx.hilt.navigation.compose.hiltViewModel

private val LightColorScheme = lightColorScheme(
    primary = AppColors.primary,
    onPrimary = AppColors.white,
    primaryContainer = AppColors.primaryContainer,
    onPrimaryContainer = AppColors.onPrimaryContainer,
    secondary = AppColors.blue500,
    onSecondary = AppColors.white,
    tertiary = AppColors.purple500,
    onTertiary = AppColors.white,
    error = AppColors.red500,
    onError = AppColors.white,
    background = AppColors.lightBackground,
    onBackground = AppColors.lightOnBackground,
    surface = AppColors.lightSurface,
    onSurface = AppColors.lightOnSurface,
    surfaceVariant = AppColors.lightSurfaceVariant,
    onSurfaceVariant = AppColors.lightOnSurfaceVariant,
    outline = AppColors.lightOutline,
    outlineVariant = AppColors.slate200
)

private val DarkColorScheme = darkColorScheme(
    primary = AppColors.primaryLight,
    onPrimary = AppColors.slate900,
    primaryContainer = AppColors.primaryDark,
    onPrimaryContainer = AppColors.primaryLight,
    secondary = AppColors.blue500,
    onSecondary = AppColors.white,
    tertiary = AppColors.purple500,
    onTertiary = AppColors.white,
    error = AppColors.red500,
    onError = AppColors.white,
    background = AppColors.darkBackground,
    onBackground = AppColors.darkOnBackground,
    surface = AppColors.darkSurface,
    onSurface = AppColors.darkOnSurface,
    surfaceVariant = AppColors.darkSurfaceVariant,
    onSurfaceVariant = AppColors.darkOnSurfaceVariant,
    outline = AppColors.darkOutline,
    outlineVariant = AppColors.slate700
)

@Composable
fun AppTheme(
    themeViewModel: ThemeViewModel = hiltViewModel(),
    content: @Composable () -> Unit
) {
    val themeMode by themeViewModel.themeMode.collectAsState()
    val glassMode by themeViewModel.glassMode.collectAsState()

    val isDarkTheme = when (themeMode) {
        ThemeMode.LIGHT -> false
        ThemeMode.DARK -> true
        ThemeMode.SYSTEM -> isSystemInDarkTheme()
    }

    val colorScheme = if (isDarkTheme) DarkColorScheme else LightColorScheme

    MaterialTheme(
        colorScheme = colorScheme,
        typography = AppTypography,
        content = content
    )
}

enum class ThemeMode {
    SYSTEM, LIGHT, DARK
}
