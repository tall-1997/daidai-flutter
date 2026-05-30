package com.daidai.app.ui.screen.notification

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.daidai.app.data.remote.model.CreateNotificationRequest
import com.daidai.app.data.remote.model.Notification
import com.daidai.app.data.remote.model.UpdateNotificationRequest
import com.daidai.app.data.repository.NotificationRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class NotificationListUiState(
    val isLoading: Boolean = false,
    val notifications: List<Notification> = emptyList(),
    val error: String? = null,
    val successMessage: String? = null
)

@HiltViewModel
class NotificationViewModel @Inject constructor(
    private val notificationRepository: NotificationRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow(NotificationListUiState())
    val uiState: StateFlow<NotificationListUiState> = _uiState.asStateFlow()

    init {
        loadNotifications()
    }

    fun loadNotifications() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            
            notificationRepository.getNotifications()
                .onSuccess { response ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        notifications = response.data ?: emptyList()
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

    fun createNotification(name: String, type: String, config: Map<String, Any?>) {
        viewModelScope.launch {
            notificationRepository.createNotification(CreateNotificationRequest(name, type, config))
                .onSuccess {
                    _uiState.value = _uiState.value.copy(successMessage = "通知创建成功")
                    loadNotifications()
                }
                .onFailure { exception ->
                    _uiState.value = _uiState.value.copy(error = exception.message)
                }
        }
    }

    fun updateNotification(id: Int, name: String?, config: Map<String, Any?>?) {
        viewModelScope.launch {
            notificationRepository.updateNotification(id, UpdateNotificationRequest(name, config))
                .onSuccess {
                    _uiState.value = _uiState.value.copy(successMessage = "通知更新成功")
                    loadNotifications()
                }
                .onFailure { exception ->
                    _uiState.value = _uiState.value.copy(error = exception.message)
                }
        }
    }

    fun deleteNotification(id: Int) {
        viewModelScope.launch {
            notificationRepository.deleteNotification(id)
                .onSuccess {
                    _uiState.value = _uiState.value.copy(successMessage = "通知删除成功")
                    loadNotifications()
                }
                .onFailure { exception ->
                    _uiState.value = _uiState.value.copy(error = exception.message)
                }
        }
    }

    fun toggleNotification(id: Int, enabled: Boolean) {
        viewModelScope.launch {
            if (enabled) {
                notificationRepository.enableNotification(id)
                    .onSuccess {
                        _uiState.value = _uiState.value.copy(successMessage = "通知已启用")
                        loadNotifications()
                    }
                    .onFailure { exception ->
                        _uiState.value = _uiState.value.copy(error = exception.message)
                    }
            } else {
                notificationRepository.disableNotification(id)
                    .onSuccess {
                        _uiState.value = _uiState.value.copy(successMessage = "通知已禁用")
                        loadNotifications()
                    }
                    .onFailure { exception ->
                        _uiState.value = _uiState.value.copy(error = exception.message)
                    }
            }
        }
    }

    fun testNotification(id: Int) {
        viewModelScope.launch {
            notificationRepository.testNotification(id)
                .onSuccess {
                    _uiState.value = _uiState.value.copy(successMessage = "测试通知已发送")
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
