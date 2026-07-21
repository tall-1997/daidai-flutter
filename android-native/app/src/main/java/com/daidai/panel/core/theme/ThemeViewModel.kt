package com.daidai.panel.core.theme

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.daidai.panel.core.storage.ThemePreferences
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ThemeViewModel @Inject constructor(
    private val themePreferences: ThemePreferences
) : ViewModel() {

    private val _themeMode = MutableStateFlow(ThemeMode.SYSTEM)
    val themeMode: StateFlow<ThemeMode> = _themeMode.asStateFlow()

    private val _glassMode = MutableStateFlow(true)
    val glassMode: StateFlow<Boolean> = _glassMode.asStateFlow()

    private val _backgroundImagePath = MutableStateFlow<String?>(null)
    val backgroundImagePath: StateFlow<String?> = _backgroundImagePath.asStateFlow()

    private val _blurIntensity = MutableStateFlow(0.5f)
    val blurIntensity: StateFlow<Float> = _blurIntensity.asStateFlow()

    init {
        viewModelScope.launch {
            themePreferences.themeMode.collect { mode ->
                _themeMode.value = when (mode) {
                    1 -> ThemeMode.LIGHT
                    2 -> ThemeMode.DARK
                    else -> ThemeMode.SYSTEM
                }
            }
        }
        viewModelScope.launch {
            themePreferences.glassMode.collect { enabled ->
                _glassMode.value = enabled
            }
        }
        viewModelScope.launch {
            themePreferences.backgroundImagePath.collect { path ->
                _backgroundImagePath.value = path
            }
        }
        viewModelScope.launch {
            themePreferences.blurIntensity.collect { intensity ->
                _blurIntensity.value = intensity
            }
        }
    }

    fun setThemeMode(mode: ThemeMode) {
        viewModelScope.launch {
            val modeInt = when (mode) {
                ThemeMode.SYSTEM -> 0
                ThemeMode.LIGHT -> 1
                ThemeMode.DARK -> 2
            }
            themePreferences.setThemeMode(modeInt)
        }
    }

    fun setGlassMode(enabled: Boolean) {
        viewModelScope.launch {
            themePreferences.setGlassMode(enabled)
        }
    }

    fun setBackgroundImagePath(path: String?) {
        viewModelScope.launch {
            themePreferences.setBackgroundImagePath(path)
        }
    }

    fun setBlurIntensity(intensity: Float) {
        viewModelScope.launch {
            themePreferences.setBlurIntensity(intensity.coerceIn(0f, 1f))
        }
    }
}
