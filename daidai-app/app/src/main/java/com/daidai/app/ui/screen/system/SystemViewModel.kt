package com.daidai.app.ui.screen.system

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.daidai.app.data.remote.model.*
import com.daidai.app.data.repository.SystemRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class SystemUiState(
    val isLoading: Boolean = false,
    val systemInfo: SystemInfo? = null,
    val dashboardData: DashboardData? = null,
    val statsData: StatsData? = null,
    val versionData: VersionData? = null,
    val healthCheckItems: List<HealthCheckItem>? = null,
    val panelLogs: List<String>? = null,
    val lastHealthCheckAt: String? = null,
    val error: String? = null,
    val successMessage: String? = null
)

@HiltViewModel
class SystemViewModel @Inject constructor(
    private val systemRepository: SystemRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow(SystemUiState())
    val uiState: StateFlow<SystemUiState> = _uiState.asStateFlow()

    init {
        loadSystemInfo()
        loadDashboard()
        loadVersion()
    }

    fun loadSystemInfo() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            
            systemRepository.getSystemInfo()
                .onSuccess { info ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        systemInfo = info
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

    fun loadDashboard() {
        viewModelScope.launch {
            systemRepository.getDashboard()
                .onSuccess { data ->
                    _uiState.value = _uiState.value.copy(dashboardData = data)
                }
                .onFailure { exception ->
                    _uiState.value = _uiState.value.copy(error = exception.message)
                }
        }
    }

    fun loadStats() {
        viewModelScope.launch {
            systemRepository.getStats()
                .onSuccess { data ->
                    _uiState.value = _uiState.value.copy(statsData = data)
                }
                .onFailure { exception ->
                    _uiState.value = _uiState.value.copy(error = exception.message)
                }
        }
    }

    fun loadVersion() {
        viewModelScope.launch {
            systemRepository.getVersion()
                .onSuccess { data ->
                    _uiState.value = _uiState.value.copy(versionData = data)
                }
                .onFailure { exception ->
                    _uiState.value = _uiState.value.copy(error = exception.message)
                }
        }
    }

    fun checkUpdate() {
        viewModelScope.launch {
            systemRepository.checkUpdate()
                .onSuccess { data ->
                    if (data.hasUpdate == true) {
                        _uiState.value = _uiState.value.copy(
                            successMessage = "发现新版本: ${data.latestVersion}"
                        )
                    } else {
                        _uiState.value = _uiState.value.copy(
                            successMessage = "当前已是最新版本"
                        )
                    }
                }
                .onFailure { exception ->
                    _uiState.value = _uiState.value.copy(error = exception.message)
                }
        }
    }

    fun doHealthCheck() {
        viewModelScope.launch {
            systemRepository.doHealthCheck()
                .onSuccess { response ->
                    _uiState.value = _uiState.value.copy(
                        healthCheckItems = response.items,
                        lastHealthCheckAt = response.lastCheckedAt,
                        successMessage = "健康检查完成"
                    )
                }
                .onFailure { exception ->
                    _uiState.value = _uiState.value.copy(error = exception.message)
                }
        }
    }

    fun getMachineCode() {
        viewModelScope.launch {
            systemRepository.getMachineCode()
                .onSuccess { code ->
                    _uiState.value = _uiState.value.copy(
                        successMessage = "机器码: $code"
                    )
                }
                .onFailure { exception ->
                    _uiState.value = _uiState.value.copy(error = exception.message)
                }
        }
    }

    fun updatePanel() {
        viewModelScope.launch {
            systemRepository.updatePanel()
                .onSuccess {
                    _uiState.value = _uiState.value.copy(successMessage = "面板更新已开始")
                }
                .onFailure { exception ->
                    _uiState.value = _uiState.value.copy(error = exception.message)
                }
        }
    }

    fun restartPanel() {
        viewModelScope.launch {
            systemRepository.restartPanel()
                .onSuccess {
                    _uiState.value = _uiState.value.copy(successMessage = "面板重启已开始")
                }
                .onFailure { exception ->
                    _uiState.value = _uiState.value.copy(error = exception.message)
                }
        }
    }

    fun loadPanelLog() {
        viewModelScope.launch {
            systemRepository.getPanelLog()
                .onSuccess { response ->
                    _uiState.value = _uiState.value.copy(
                        panelLogs = response.data?.logs
                    )
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
