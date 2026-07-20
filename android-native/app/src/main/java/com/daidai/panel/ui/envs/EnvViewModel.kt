package com.daidai.panel.ui.envs

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.daidai.panel.core.network.ApiEndpoints
import com.daidai.panel.core.network.NetworkModule
import com.daidai.panel.data.model.EnvVar
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class EnvListState(
    val envs: List<EnvVar> = emptyList(),
    val total: Int = 0,
    val isLoading: Boolean = false,
    val error: String? = null,
    val keyword: String = "",
    val groups: List<String> = emptyList(),
    val selectedGroup: String = "",
    val selectedIds: Set<Int> = emptySet(),
    val isBatchMode: Boolean = false
) {
    val filteredEnvs: List<EnvVar>
        get() {
            var result = envs
            if (keyword.isNotBlank()) {
                result = result.filter {
                    it.name.contains(keyword, ignoreCase = true) ||
                            it.value.contains(keyword, ignoreCase = true) ||
                            it.remarks?.contains(keyword, ignoreCase = true)
                }
            }
            if (selectedGroup.isNotBlank()) {
                result = result.filter { it.groups.contains(selectedGroup) }
            }
            return result
        }
}

@HiltViewModel
class EnvViewModel @Inject constructor(
    private val networkModule: NetworkModule
) : ViewModel() {

    private val _state = MutableStateFlow(EnvListState())
    val state: StateFlow<EnvListState> = _state.asStateFlow()

    init {
        load()
        loadGroups()
    }

    fun load() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            try {
                val api = networkModule.getApiService()
                val params = mutableMapOf<String, String>()
                val response = api.getEnvVars(params)
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    _state.value = _state.value.copy(
                        envs = response.body()?.data ?: emptyList(),
                        total = response.body()?.total ?: 0,
                        isLoading = false
                    )
                } else {
                    _state.value = _state.value.copy(
                        isLoading = false,
                        error = response.body()?.message ?: "加载失败"
                    )
                }
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isLoading = false,
                    error = e.message ?: "网络错误"
                )
            }
        }
    }

    private fun loadGroups() {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                val response = api.getEnvGroups()
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    _state.value = _state.value.copy(
                        groups = response.body()?.data ?: emptyList()
                    )
                }
            } catch (_: Exception) {}
        }
    }

    fun updateKeyword(value: String) {
        _state.value = _state.value.copy(keyword = value)
    }

    fun updateSelectedGroup(group: String) {
        _state.value = _state.value.copy(
            selectedGroup = if (_state.value.selectedGroup == group) "" else group
        )
    }

    fun toggleBatchMode() {
        val newMode = !_state.value.isBatchMode
        _state.value = _state.value.copy(
            isBatchMode = newMode,
            selectedIds = if (!newMode) emptySet() else _state.value.selectedIds
        )
    }

    fun toggleSelection(envId: Int) {
        val current = _state.value.selectedIds.toMutableSet()
        if (current.contains(envId)) current.remove(envId) else current.add(envId)
        _state.value = _state.value.copy(selectedIds = current)
    }

    fun selectAll() {
        _state.value = _state.value.copy(
            selectedIds = _state.value.filteredEnvs.map { it.id }.toSet()
        )
    }

    fun enableEnv(id: Int) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.enableEnvVar(ApiEndpoints.envEnable(id))
                load()
            } catch (_: Exception) {}
        }
    }

    fun disableEnv(id: Int) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.disableEnvVar(ApiEndpoints.envDisable(id))
                load()
            } catch (_: Exception) {}
        }
    }

    fun moveTop(id: Int) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.moveTopEnvVar(ApiEndpoints.envMoveTop(id))
                load()
            } catch (_: Exception) {}
        }
    }

    fun cancelTop(id: Int) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.cancelTopEnvVar(ApiEndpoints.envCancelTop(id))
                load()
            } catch (_: Exception) {}
        }
    }

    fun deleteEnv(id: Int) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.deleteEnvVar(id)
                load()
            } catch (_: Exception) {}
        }
    }

    fun batchDelete() {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.batchEnvVars(mapOf("action" to "delete", "ids" to _state.value.selectedIds.toList()))
                _state.value = _state.value.copy(selectedIds = emptySet(), isBatchMode = false)
                load()
            } catch (_: Exception) {}
        }
    }

    fun batchEnable() {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.batchEnvVars(mapOf("action" to "enable", "ids" to _state.value.selectedIds.toList()))
                _state.value = _state.value.copy(selectedIds = emptySet(), isBatchMode = false)
                load()
            } catch (_: Exception) {}
        }
    }

    fun batchDisable() {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.batchEnvVars(mapOf("action" to "disable", "ids" to _state.value.selectedIds.toList()))
                _state.value = _state.value.copy(selectedIds = emptySet(), isBatchMode = false)
                load()
            } catch (_: Exception) {}
        }
    }
}
