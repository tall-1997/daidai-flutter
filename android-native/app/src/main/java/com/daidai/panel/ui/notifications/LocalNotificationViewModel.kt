package com.daidai.panel.ui.notifications

import android.Manifest
import android.app.NotificationManager
import android.content.Context
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class LocalNotificationState(
    val taskEnabled: Boolean = true,
    val systemEnabled: Boolean = true,
    val permissionGranted: Boolean = false,
    val testResult: String? = null
)

@HiltViewModel
class LocalNotificationViewModel @Inject constructor(
    @ApplicationContext private val context: Context
) : ViewModel() {

    private val prefs: SharedPreferences =
        context.getSharedPreferences("local_notifications", Context.MODE_PRIVATE)

    private val _state = MutableStateFlow(LocalNotificationState())
    val state: StateFlow<LocalNotificationState> = _state.asStateFlow()

    init {
        _state.value = _state.value.copy(
            taskEnabled = prefs.getBoolean("task_channel", true),
            systemEnabled = prefs.getBoolean("system_channel", true),
            permissionGranted = isPermissionGranted()
        )
    }

    fun isPermissionGranted(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                context, Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    fun refreshPermission() {
        _state.value = _state.value.copy(permissionGranted = isPermissionGranted())
    }

    fun setTaskEnabled(enabled: Boolean) {
        prefs.edit().putBoolean("task_channel", enabled).apply()
        _state.value = _state.value.copy(taskEnabled = enabled)
    }

    fun setSystemEnabled(enabled: Boolean) {
        prefs.edit().putBoolean("system_channel", enabled).apply()
        _state.value = _state.value.copy(systemEnabled = enabled)
    }

    fun sendTestNotification(type: String) {
        viewModelScope.launch {
            try {
                val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                val channelId = when (type) {
                    "task" -> "daidai_task_channel"
                    "system" -> "daidai_system_channel"
                    else -> return@launch
                }

                val label = if (type == "task") "任务通知" else "系统通知"
                val notification = NotificationCompat.Builder(context, channelId)
                    .setSmallIcon(android.R.drawable.ic_dialog_info)
                    .setContentTitle("测试通知")
                    .setContentText("这是一条来自 $label 渠道的测试通知")
                    .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                    .setAutoCancel(true)
                    .build()

                manager.notify(channelId.hashCode(), notification)
                _state.value = _state.value.copy(testResult = "测试通知已发送")
            } catch (e: Exception) {
                _state.value = _state.value.copy(testResult = "发送失败: ${e.message}")
            }
        }
    }

    fun clearTestResult() {
        _state.value = _state.value.copy(testResult = null)
    }
}
