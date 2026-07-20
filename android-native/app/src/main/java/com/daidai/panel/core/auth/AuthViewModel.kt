package com.daidai.panel.core.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.daidai.panel.core.storage.SecureStorage
import com.daidai.panel.data.model.User
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

enum class AuthStatus {
    UNKNOWN, UNAUTHENTICATED, AUTHENTICATED
}

data class AuthState(
    val status: AuthStatus = AuthStatus.UNKNOWN,
    val user: User? = null,
    val needsInit: Boolean = false,
    val error: String? = null
)

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val secureStorage: SecureStorage
) : ViewModel() {

    private val _authState = MutableStateFlow(AuthState())
    val authState: StateFlow<AuthState> = _authState.asStateFlow()

    fun checkAuthStatus() {
        viewModelScope.launch {
            _authState.value = _authState.value.copy(status = AuthStatus.UNKNOWN)

            try {
                val healthResult = authRepository.checkHealth()
                if (healthResult.isFailure) {
                    _authState.value = _authState.value.copy(
                        status = AuthStatus.UNAUTHENTICATED,
                        error = "Server unreachable"
                    )
                    return@launch
                }

                val initResult = authRepository.needsInitialization()
                if (initResult.isSuccess && initResult.getOrDefault(false)) {
                    _authState.value = _authState.value.copy(
                        status = AuthStatus.UNAUTHENTICATED,
                        needsInit = true
                    )
                    return@launch
                }

                val token = secureStorage.getAccessToken()
                if (token.isNullOrEmpty()) {
                    _authState.value = _authState.value.copy(
                        status = AuthStatus.UNAUTHENTICATED
                    )
                    return@launch
                }

                val userResult = authRepository.getUser()
                if (userResult.isSuccess) {
                    _authState.value = _authState.value.copy(
                        status = AuthStatus.AUTHENTICATED,
                        user = userResult.getOrNull()
                    )
                } else {
                    // Fallback: try to restore user from local cache
                    val cachedUser = restoreUserFromCache()
                    if (cachedUser != null) {
                        _authState.value = _authState.value.copy(
                            status = AuthStatus.AUTHENTICATED,
                            user = cachedUser
                        )
                    } else {
                        secureStorage.clearAuth()
                        _authState.value = _authState.value.copy(
                            status = AuthStatus.UNAUTHENTICATED
                        )
                    }
                }
            } catch (e: Exception) {
                _authState.value = _authState.value.copy(
                    status = AuthStatus.UNAUTHENTICATED,
                    error = e.message
                )
            }
        }
    }

    fun login(username: String, password: String, captchaCode: String? = null, captchaId: String? = null, totpCode: String? = null) {
        viewModelScope.launch {
            _authState.value = _authState.value.copy(error = null)
            val result = authRepository.login(username, password, captchaCode, captchaId, totpCode)
            if (result.isSuccess) {
                _authState.value = _authState.value.copy(
                    status = AuthStatus.AUTHENTICATED,
                    user = result.getOrNull()
                )
            } else {
                _authState.value = _authState.value.copy(
                    error = result.exceptionOrNull()?.message ?: "Login failed"
                )
            }
        }
    }

    fun initAdmin(username: String, password: String) {
        viewModelScope.launch {
            _authState.value = _authState.value.copy(error = null)
            val result = authRepository.initAdmin(username, password)
            if (result.isSuccess) {
                _authState.value = _authState.value.copy(needsInit = false)
                login(username, password)
            } else {
                _authState.value = _authState.value.copy(
                    error = result.exceptionOrNull()?.message ?: "Init failed"
                )
            }
        }
    }

    fun logout() {
        viewModelScope.launch {
            authRepository.logout()
            _authState.value = AuthState(status = AuthStatus.UNAUTHENTICATED)
        }
    }

    fun clearError() {
        _authState.value = _authState.value.copy(error = null)
    }

    fun restoreSession() {
        viewModelScope.launch {
            val serverUrl = secureStorage.getServerUrl()
            if (serverUrl != null && authRepository.isTrustedLogin(serverUrl)) {
                val token = secureStorage.getAccessToken()
                if (!token.isNullOrEmpty()) {
                    val userResult = authRepository.getUser()
                    if (userResult.isSuccess) {
                        _authState.value = _authState.value.copy(
                            status = AuthStatus.AUTHENTICATED,
                            user = userResult.getOrNull()
                        )
                        return@launch
                    }
                    // Fallback: try to restore user from local cache
                    val cachedUser = restoreUserFromCache()
                    if (cachedUser != null) {
                        _authState.value = _authState.value.copy(
                            status = AuthStatus.AUTHENTICATED,
                            user = cachedUser
                        )
                        return@launch
                    }
                }
            }
            checkAuthStatus()
        }
    }

    private suspend fun restoreUserFromCache(): User? {
        val cached = secureStorage.getAuthUser() ?: return null
        return try {
            User(
                id = (cached["id"] as? Number)?.toInt() ?: 0,
                username = cached["username"] as? String ?: "",
                role = cached["role"] as? String ?: "viewer"
            )
        } catch (_: Exception) {
            null
        }
    }
}
