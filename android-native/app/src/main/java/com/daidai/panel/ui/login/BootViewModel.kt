package com.daidai.panel.ui.login

import androidx.compose.runtime.mutableStateOf
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.daidai.panel.core.auth.AuthRepository
import com.daidai.panel.core.storage.SecureStorage
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject

sealed class BootState {
    object Loading : BootState()
    object NoServer : BootState()
    object NeedLogin : BootState()
    object Authenticated : BootState()
    data class Error(val message: String) : BootState()
}

@HiltViewModel
class BootViewModel @Inject constructor(
    private val secureStorage: SecureStorage,
    private val authRepository: AuthRepository
) : ViewModel() {

    val state = mutableStateOf<BootState>(BootState.Loading)

    fun checkBootState() {
        viewModelScope.launch {
            state.value = BootState.Loading
            try {
                val serverUrl = secureStorage.getServerUrl()
                if (serverUrl.isNullOrBlank()) {
                    state.value = BootState.NoServer
                    return@launch
                }

                val healthResult = authRepository.checkHealth()
                if (healthResult.isFailure) {
                    state.value = BootState.Error(
                        "无法连接到服务器 ($serverUrl)，请检查地址是否正确"
                    )
                    return@launch
                }

                val token = secureStorage.getAccessToken()
                if (token.isNullOrEmpty()) {
                    state.value = BootState.NeedLogin
                    return@launch
                }

                if (authRepository.isTrustedLogin(serverUrl)) {
                    val userResult = authRepository.getUser()
                    if (userResult.isSuccess) {
                        state.value = BootState.Authenticated
                        return@launch
                    }
                }

                state.value = BootState.NeedLogin
            } catch (e: Exception) {
                state.value = BootState.Error(e.message ?: "Unknown error")
            }
        }
    }
}
