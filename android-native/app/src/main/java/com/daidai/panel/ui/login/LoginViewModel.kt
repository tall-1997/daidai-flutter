package com.daidai.panel.ui.login

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.daidai.panel.core.storage.SecureStorage
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class LoginUiState(
    val username: String = "",
    val password: String = "",
    val passwordVisible: Boolean = false,
    val rememberPassword: Boolean = false,
    val autoLogin: Boolean = false,
    val totpCode: String = "",
    val showTotp: Boolean = false,
    val servers: List<Map<String, Any>> = emptyList(),
    val currentServerUrl: String = "",
    val currentServerName: String = "",
    val directServerUrl: String = ""
)

@HiltViewModel
class LoginViewModel @Inject constructor(
    private val secureStorage: SecureStorage
) : ViewModel() {

    private val _loginState = MutableStateFlow(LoginUiState())
    val loginState: StateFlow<LoginUiState> = _loginState.asStateFlow()

    init {
        loadSavedCredentials()
        loadServers()
    }

    private fun loadSavedCredentials() {
        viewModelScope.launch {
            val config = secureStorage.getAppLockConfig()
            val savedUsername = config?.get("saved_username") as? String ?: ""
            val savedPassword = config?.get("saved_password") as? String ?: ""
            val remember = config?.get("remember_password") as? Boolean ?: false
            val autoLogin = config?.get("auto_login") as? Boolean ?: false

            _loginState.value = _loginState.value.copy(
                username = if (remember) savedUsername else "",
                password = if (remember) savedPassword else "",
                rememberPassword = remember,
                autoLogin = autoLogin
            )
        }
    }

    private fun loadServers() {
        viewModelScope.launch {
            val servers = secureStorage.getPanelsConfig()
            val currentUrl = secureStorage.getServerUrl() ?: ""
            val currentServer = servers.find { it["url"] == currentUrl }
            _loginState.value = _loginState.value.copy(
                servers = servers,
                currentServerUrl = currentUrl,
                currentServerName = currentServer?.get("name") as? String ?: ""
            )
        }
    }

    fun updateUsername(value: String) {
        _loginState.value = _loginState.value.copy(username = value)
    }

    fun updatePassword(value: String) {
        _loginState.value = _loginState.value.copy(password = value)
    }

    fun updateTotpCode(value: String) {
        _loginState.value = _loginState.value.copy(totpCode = value)
    }

    fun togglePasswordVisibility() {
        _loginState.value = _loginState.value.copy(
            passwordVisible = !_loginState.value.passwordVisible
        )
    }

    fun toggleRememberPassword() {
        val new = !_loginState.value.rememberPassword
        _loginState.value = _loginState.value.copy(rememberPassword = new)
        if (!new) {
            _loginState.value = _loginState.value.copy(autoLogin = false)
        }
        saveCredentials()
    }

    fun toggleAutoLogin() {
        val new = !_loginState.value.autoLogin
        _loginState.value = _loginState.value.copy(autoLogin = new)
        if (new) {
            _loginState.value = _loginState.value.copy(rememberPassword = true)
        }
        saveCredentials()
    }

    fun selectServer(url: String) {
        viewModelScope.launch {
            secureStorage.saveServerUrl(url)
            val server = _loginState.value.servers.find { it["url"] == url }
            _loginState.value = _loginState.value.copy(
                currentServerUrl = url,
                currentServerName = server?.get("name") as? String ?: ""
            )
        }
    }

    fun showTotpField() {
        _loginState.value = _loginState.value.copy(showTotp = true)
    }

    fun hideTotpField() {
        _loginState.value = _loginState.value.copy(showTotp = false, totpCode = "")
    }

    fun updateDirectServerUrl(value: String) {
        _loginState.value = _loginState.value.copy(directServerUrl = value)
    }

    fun setupDirectServerUrl(url: String) {
        viewModelScope.launch {
            secureStorage.saveServerUrl(url)
            saveServerToPanelList(url)
            _loginState.value = _loginState.value.copy(currentServerUrl = url, currentServerName = url)
        }
    }

    private suspend fun saveServerToPanelList(url: String) {
        val servers = _loginState.value.servers.toMutableList()
        val exists = servers.any { it["url"] == url }
        if (!exists) {
            servers.add(mapOf("name" to url, "url" to url))
            secureStorage.savePanelsConfig(servers)
            _loginState.value = _loginState.value.copy(servers = servers)
        }
    }

    private fun saveCredentials() {
        viewModelScope.launch {
            val state = _loginState.value
            val config = mapOf(
                "saved_username" to if (state.rememberPassword) state.username else "",
                "saved_password" to if (state.rememberPassword) state.password else "",
                "remember_password" to state.rememberPassword,
                "auto_login" to state.autoLogin
            )
            secureStorage.saveAppLockConfig(config)
        }
    }
}
