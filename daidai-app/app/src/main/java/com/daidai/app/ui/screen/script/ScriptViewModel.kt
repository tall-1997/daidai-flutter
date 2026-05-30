package com.daidai.app.ui.screen.script

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.daidai.app.data.remote.model.CreateScriptRequest
import com.daidai.app.data.remote.model.RunScriptRequest
import com.daidai.app.data.remote.model.Script
import com.daidai.app.data.remote.model.UpdateScriptRequest
import com.daidai.app.data.repository.ScriptRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ScriptListUiState(
    val isLoading: Boolean = false,
    val scripts: List<Script> = emptyList(),
    val error: String? = null,
    val successMessage: String? = null
)

@HiltViewModel
class ScriptViewModel @Inject constructor(
    private val scriptRepository: ScriptRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow(ScriptListUiState())
    val uiState: StateFlow<ScriptListUiState> = _uiState.asStateFlow()

    init {
        loadScripts()
    }

    fun loadScripts() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            
            scriptRepository.getScripts()
                .onSuccess { scriptListResponse ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        scripts = scriptListResponse.data ?: emptyList()
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

    fun createScript(name: String, content: String, description: String? = null) {
        viewModelScope.launch {
            scriptRepository.createScript(CreateScriptRequest(name, content, description))
                .onSuccess {
                    _uiState.value = _uiState.value.copy(successMessage = "脚本创建成功")
                    loadScripts()
                }
                .onFailure { exception ->
                    _uiState.value = _uiState.value.copy(error = exception.message)
                }
        }
    }

    fun updateScript(id: Int, name: String, content: String, description: String? = null) {
        viewModelScope.launch {
            scriptRepository.updateScript(id, UpdateScriptRequest(name, content, description))
                .onSuccess {
                    _uiState.value = _uiState.value.copy(successMessage = "脚本更新成功")
                    loadScripts()
                }
                .onFailure { exception ->
                    _uiState.value = _uiState.value.copy(error = exception.message)
                }
        }
    }

    fun deleteScript(path: String) {
        viewModelScope.launch {
            scriptRepository.deleteScript(path)
                .onSuccess {
                    _uiState.value = _uiState.value.copy(successMessage = "脚本删除成功")
                    loadScripts()
                }
                .onFailure { exception ->
                    _uiState.value = _uiState.value.copy(error = exception.message)
                }
        }
    }

    fun runScript(path: String) {
        viewModelScope.launch {
            scriptRepository.runScript(RunScriptRequest(path))
                .onSuccess {
                    _uiState.value = _uiState.value.copy(successMessage = "脚本已开始执行")
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
