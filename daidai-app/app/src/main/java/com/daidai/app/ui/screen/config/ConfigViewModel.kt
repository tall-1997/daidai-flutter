package com.daidai.app.ui.screen.config

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.daidai.app.data.remote.model.*
import com.daidai.app.data.repository.ConfigRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ConfigUiState(
    val isLoading: Boolean = false,
    val configs: List<Config> = emptyList(),
    val platforms: List<Platform> = emptyList(),
    val platformTokens: List<PlatformToken> = emptyList(),
    val error: String? = null,
    val successMessage: String? = null
)

@HiltViewModel
class ConfigViewModel @Inject constructor(
    private val configRepository: ConfigRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow(ConfigUiState())
    val uiState: StateFlow<ConfigUiState> = _uiState.asStateFlow()

    init {
        loadConfigs()
        loadPlatforms()
        loadPlatformTokens()
    }

    fun loadConfigs() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            
            configRepository.getConfigs()
                .onSuccess { configs ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        configs = configs
                    )
                }
                .onFailure { exception ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = exception.message
                    )
                }
        }
    }

    fun setConfig(key: String, value: String) {
        viewModelScope.launch {
            configRepository.setConfig(key, value)
                .onSuccess {
                    _uiState.value = _uiState.value.copy(successMessage = "配置已保存")
                    loadConfigs()
                }
                .onFailure { exception ->
                    _uiState.value = _uiState.value.copy(error = exception.message)
                }
        }
    }

    fun deleteConfig(key: String) {
        viewModelScope.launch {
            configRepository.deleteConfig(key)
                .onSuccess {
                    _uiState.value = _uiState.value.copy(successMessage = "配置已删除")
                    loadConfigs()
                }
                .onFailure { exception ->
                    _uiState.value = _uiState.value.copy(error = exception.message)
                }
        }
    }

    fun loadPlatforms() {
        viewModelScope.launch {
            configRepository.getPlatforms()
                .onSuccess { platforms ->
                    _uiState.value = _uiState.value.copy(platforms = platforms)
                }
                .onFailure { exception ->
                    _uiState.value = _uiState.value.copy(error = exception.message)
                }
        }
    }

    fun createPlatform(name: String, type: String) {
        viewModelScope.launch {
            configRepository.createPlatform(name, type)
                .onSuccess {
                    _uiState.value = _uiState.value.copy(successMessage = "平台创建成功")
                    loadPlatforms()
                }
                .onFailure { exception ->
                    _uiState.value = _uiState.value.copy(error = exception.message)
                }
        }
    }

    fun deletePlatform(id: Int) {
        viewModelScope.launch {
            configRepository.deletePlatform(id)
                .onSuccess {
                    _uiState.value = _uiState.value.copy(successMessage = "平台已删除")
                    loadPlatforms()
                }
                .onFailure { exception ->
                    _uiState.value = _uiState.value.copy(error = exception.message)
                }
        }
    }

    fun loadPlatformTokens() {
        viewModelScope.launch {
            configRepository.getPlatformTokens()
                .onSuccess { tokens ->
                    _uiState.value = _uiState.value.copy(platformTokens = tokens)
                }
                .onFailure { exception ->
                    _uiState.value = _uiState.value.copy(error = exception.message)
                }
        }
    }

    fun createPlatformToken(platformId: Int, name: String, token: String) {
        viewModelScope.launch {
            configRepository.createPlatformToken(platformId, name, token)
                .onSuccess {
                    _uiState.value = _uiState.value.copy(successMessage = "Token创建成功")
                    loadPlatformTokens()
                }
                .onFailure { exception ->
                    _uiState.value = _uiState.value.copy(error = exception.message)
                }
        }
    }

    fun deletePlatformToken(id: Int) {
        viewModelScope.launch {
            configRepository.deletePlatformToken(id)
                .onSuccess {
                    _uiState.value = _uiState.value.copy(successMessage = "Token已删除")
                    loadPlatformTokens()
                }
                .onFailure { exception ->
                    _uiState.value = _uiState.value.copy(error = exception.message)
                }
        }
    }

    fun togglePlatformToken(id: Int, enabled: Boolean) {
        viewModelScope.launch {
            configRepository.togglePlatformToken(id, enabled)
                .onSuccess {
                    _uiState.value = _uiState.value.copy(successMessage = if (enabled) "Token已启用" else "Token已禁用")
                    loadPlatformTokens()
                }
                .onFailure { exception ->
                    _uiState.value = _uiState.value.copy(error = exception.message)
                }
        }
    }

    fun clearMessages() {
        _uiState.value = _uiState.value.copy(error = null, successMessage = null)
    }
}
