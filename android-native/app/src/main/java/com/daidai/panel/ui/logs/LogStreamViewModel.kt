package com.daidai.panel.ui.logs

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.daidai.panel.core.network.ApiEndpoints
import com.daidai.panel.core.network.NetworkModule
import com.daidai.panel.core.network.SseClient
import com.daidai.panel.data.model.TaskLog
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class LogStreamState(
    val log: TaskLog? = null,
    val logLines: List<String> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null,
    val isDone: Boolean = false,
    val status: String = ""
) {
    val content: String
        get() = if (logLines.isNotEmpty()) {
            logLines.joinToString("\n").let { raw ->
                try {
                    val decoded = android.util.Base64.decode(raw, android.util.Base64.DEFAULT)
                    String(decoded, Charsets.UTF_8)
                } catch (_: Exception) {
                    raw
                }
            }
        } else {
            log?.content?.let { raw ->
                try {
                    val decoded = android.util.Base64.decode(raw, android.util.Base64.DEFAULT)
                    String(decoded, Charsets.UTF_8)
                } catch (_: Exception) {
                    raw
                }
            } ?: ""
        }

    val durationText: String
        get() = log?.durationText ?: ""
}

@HiltViewModel
class LogStreamViewModel @Inject constructor(
    private val networkModule: NetworkModule,
    private val sseClient: SseClient,
    savedStateHandle: SavedStateHandle
) : ViewModel() {

    private val logId: Int = savedStateHandle.get<Int>("logId") ?: 0
    val logIdValue: Int get() = logId

    private val _state = MutableStateFlow(LogStreamState())
    val state: StateFlow<LogStreamState> = _state.asStateFlow()

    init {
        load()
    }

    fun load() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            try {
                val api = networkModule.getApiService()
                val restResponse = api.getLog(logId)
                if (restResponse.isSuccessful) {
                    val body = restResponse.body()
                    if (body?.isSuccess == true && body.data != null) {
                        _state.value = _state.value.copy(
                            log = body.data,
                            isLoading = false
                        )
                        return@launch
                    }
                }
                startSseStream()
            } catch (e: Exception) {
                startSseStream()
            }
        }
    }

    private fun startSseStream() {
        viewModelScope.launch {
            try {
                sseClient.stream(ApiEndpoints.logStream(logId)).collect { data ->
                    if (data == "done") {
                        _state.value = _state.value.copy(
                            isDone = true,
                            isLoading = false
                        )
                        return@collect
                    }
                    val currentLines = _state.value.logLines.toMutableList()
                    currentLines.add(data)
                    val status = when {
                        _state.value.isDone -> _state.value.status
                        data.contains("finished", ignoreCase = true) -> "已完成"
                        data.contains("failed", ignoreCase = true) -> "失败"
                        else -> "运行中"
                    }
                    _state.value = _state.value.copy(
                        logLines = currentLines,
                        status = status,
                        isLoading = false
                    )
                }
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isLoading = false,
                    error = e.message ?: "日志加载失败"
                )
            }
        }
    }
}
