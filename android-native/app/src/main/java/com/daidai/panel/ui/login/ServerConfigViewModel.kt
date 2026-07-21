package com.daidai.panel.ui.login

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.daidai.panel.core.auth.AuthRepository
import com.daidai.panel.core.network.NetworkModule
import com.daidai.panel.core.network.RetrofitClient
import com.daidai.panel.core.storage.SecureStorage
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ServerConfigViewModel @Inject constructor(
    private val secureStorage: SecureStorage,
    private val authRepository: AuthRepository
) : ViewModel() {

    private val _panels = MutableStateFlow<List<Map<String, Any>>>(emptyList())
    val panels: StateFlow<List<Map<String, Any>>> = _panels.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    private val _healthCheckResult = MutableStateFlow<Pair<String, Boolean>?>(null)
    val healthCheckResult: StateFlow<Pair<String, Boolean>?> = _healthCheckResult.asStateFlow()

    init {
        loadPanels()
    }

    private fun loadPanels() {
        viewModelScope.launch {
            _panels.value = secureStorage.getPanelsConfig()
        }
    }

    fun addServer(name: String, url: String) {
        viewModelScope.launch {
            val cleanUrl = normalizeServerUrl(url)
            val current = _panels.value.toMutableList()
            val exists = current.any { it["url"] == cleanUrl }
            if (exists) {
                _error.value = "该服务器已存在"
                return@launch
            }
            current.add(mapOf("name" to name.trim(), "url" to cleanUrl))
            secureStorage.savePanelsConfig(current)
            _panels.value = current
        }
    }

    fun deleteServer(url: String) {
        viewModelScope.launch {
            val current = _panels.value.toMutableList()
            current.removeAll { it["url"] == url }
            secureStorage.savePanelsConfig(current)
            _panels.value = current
        }
    }

    fun selectServer(url: String) {
        viewModelScope.launch {
            secureStorage.saveServerUrl(url)
        }
    }

    fun healthCheck(url: String) {
        viewModelScope.launch {
            _isLoading.value = true
            _healthCheckResult.value = null
            try {
                val cleanUrl = url.trim().trimEnd('/')
                val retrofit = RetrofitClient.createPlainRetrofit(cleanUrl)
                val api = retrofit.create(com.daidai.panel.core.network.ApiService::class.java)
                val response = api.health()
                _healthCheckResult.value = url to (response.isSuccessful)
            } catch (e: Exception) {
                _healthCheckResult.value = url to false
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun clearError() {
        _error.value = null
    }

    companion object {
        private val ipPattern = Regex(
            """^(\d{1,3}\.){3}\d{1,3}(:\d+)?${'$'}|""" +
            """^\[.*\](:\d+)?${'$'}|""" +
            """^localhost(:\d+)?${'$'}"""
        )

        fun normalizeServerUrl(rawUrl: String): String {
            var url = rawUrl.trim()
            if (!url.startsWith("http://") && !url.startsWith("https://")) {
                val hostPart = url.split("/").first()
                url = if (ipPattern.matches(hostPart)) "http://$url" else "https://$url"
            }
            if (url.endsWith("/")) {
                url = url.substring(0, url.length - 1)
            }
            return url
        }
    }
}
