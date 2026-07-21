package com.daidai.panel.ui.tasks

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.daidai.panel.core.network.NetworkModule
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import javax.inject.Inject

data class TaskFormState(
    val name: String = "",
    val command: String = "",
    val type: String = "manual",
    val cron: String = "",
    val timeout: Int = 300,
    val retryCount: Int = 0,
    val directory: String = "",
    val tags: String = "",
    val isSaving: Boolean = false,
    val error: String? = null,
    val saved: Boolean = false
)

@HiltViewModel
class TaskFormViewModel @Inject constructor(
    private val networkModule: NetworkModule
) : ViewModel() {

    private val _state = MutableStateFlow(TaskFormState())
    val state: StateFlow<TaskFormState> = _state.asStateFlow()

    fun updateName(value: String) { _state.value = _state.value.copy(name = value) }
    fun updateCommand(value: String) { _state.value = _state.value.copy(command = value) }
    fun updateType(value: String) { _state.value = _state.value.copy(type = value) }
    fun updateCron(value: String) { _state.value = _state.value.copy(cron = value) }
    fun updateTimeout(value: Int) { _state.value = _state.value.copy(timeout = value) }
    fun updateRetryCount(value: Int) { _state.value = _state.value.copy(retryCount = value) }
    fun updateDirectory(value: String) { _state.value = _state.value.copy(directory = value) }
    fun updateTags(value: String) { _state.value = _state.value.copy(tags = value) }

    fun loadTask(taskId: Int) {
        viewModelScope.launch(Dispatchers.IO) {
            try {
                val api = networkModule.getApiService()
                val response = api.getTask(taskId)
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    val task = response.body()?.data
                    if (task != null) {
                        withContext(Dispatchers.Main) {
                            _state.value = _state.value.copy(
                                name = task.name,
                                command = task.command,
                                type = task.taskType.ifEmpty { "manual" },
                                cron = task.cronExpression,
                                timeout = task.timeout,
                                retryCount = task.maxRetries,
                                directory = ""
                            )
                        }
                    }
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    _state.value = _state.value.copy(error = e.message)
                }
            }
        }
    }

    fun save() {
        val s = _state.value
        if (s.name.isBlank() || s.command.isBlank()) return

        viewModelScope.launch(Dispatchers.IO) {
            _state.value = _state.value.copy(isSaving = true, error = null)
            try {
                val api = networkModule.getApiService()
                val body = mutableMapOf<String, Any>(
                    "name" to s.name.trim(),
                    "command" to s.command.trim(),
                    "type" to s.type,
                    "timeout" to s.timeout,
                    "retry_count" to s.retryCount,
                    "directory" to s.directory.trim(),
                    "tags" to s.tags.split(",").map { it.trim() }.filter { it.isNotEmpty() }
                )
                if (s.type == "cron" && s.cron.isNotBlank()) {
                    body["cron"] = s.cron.trim()
                }

                val response = api.createTask(body)
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    withContext(Dispatchers.Main) {
                        _state.value = _state.value.copy(isSaving = false, saved = true)
                    }
                } else {
                    withContext(Dispatchers.Main) {
                        _state.value = _state.value.copy(
                            isSaving = false,
                            error = response.body()?.message ?: "创建失败"
                        )
                    }
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    _state.value = _state.value.copy(
                        isSaving = false,
                        error = e.message ?: "网络错误"
                    )
                }
            }
        }
    }
}
