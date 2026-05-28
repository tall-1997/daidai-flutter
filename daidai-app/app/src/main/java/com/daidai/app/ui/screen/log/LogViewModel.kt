package com.daidai.app.ui.screen.log

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.daidai.app.data.remote.model.LogDetailResponse
import com.daidai.app.data.remote.model.TaskLog
import com.daidai.app.data.repository.LogRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class LogListUiState(
    val isLoading: Boolean = false,
    val logs: List<TaskLog> = emptyList(),
    val error: String? = null,
    val currentPage: Int = 1,
    val hasMore: Boolean = true,
    val selectedLog: LogDetailResponse? = null,
    val isLoadingDetail: Boolean = false
)

@HiltViewModel
class LogViewModel @Inject constructor(
    private val logRepository: LogRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow(LogListUiState())
    val uiState: StateFlow<LogListUiState> = _uiState.asStateFlow()

    init {
        loadLogs()
    }

    fun loadLogs(refresh: Boolean = false) {
        if (refresh) {
            _uiState.value = _uiState.value.copy(currentPage = 1)
        }

        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            
            logRepository.getLogs(page = _uiState.value.currentPage)
                .onSuccess { logListResponse ->
                    val newLogs = if (refresh) {
                        logListResponse.data ?: emptyList()
                    } else {
                        _uiState.value.logs + (logListResponse.data ?: emptyList())
                    }
                    
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        logs = newLogs,
                        hasMore = newLogs.size < logListResponse.total
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

    fun loadLogDetail(logId: Int) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoadingDetail = true, error = null)
            
            logRepository.getLog(logId)
                .onSuccess { logDetail ->
                    _uiState.value = _uiState.value.copy(
                        isLoadingDetail = false,
                        selectedLog = logDetail
                    )
                }
                .onFailure { exception ->
                    _uiState.value = _uiState.value.copy(
                        isLoadingDetail = false,
                        error = exception.message
                    )
                }
        }
    }

    fun clearSelectedLog() {
        _uiState.value = _uiState.value.copy(selectedLog = null)
    }

    fun loadMore() {
        if (_uiState.value.isLoading || !_uiState.value.hasMore) return
        
        _uiState.value = _uiState.value.copy(currentPage = _uiState.value.currentPage + 1)
        loadLogs()
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }
}
