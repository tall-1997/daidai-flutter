package com.daidai.panel.ui.deps

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.daidai.panel.core.network.ApiEndpoints
import com.daidai.panel.core.network.NetworkModule
import com.daidai.panel.data.model.Dependency
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class DepListState(
    val deps: List<Dependency> = emptyList(),
    val pythonRuntimes: List<Map<String, Any>> = emptyList(),
    val total: Int = 0,
    val currentPage: Int = 1,
    val pageSize: Int = 20,
    val hasMore: Boolean = false,
    val isLoading: Boolean = false,
    val isLoadingMore: Boolean = false,
    val installingDeps: Set<String> = emptySet(),
    val error: String? = null,
    val installLog: String = "",
    val selectedTab: Int = 0
)

@HiltViewModel
class DepViewModel @Inject constructor(
    private val networkModule: NetworkModule
) : ViewModel() {

    private val _state = MutableStateFlow(DepListState())
    val state: StateFlow<DepListState> = _state.asStateFlow()

    init {
        load()
        loadPythonRuntimes()
    }

    fun load(loadMore: Boolean = false) {
        viewModelScope.launch {
            _state.value = _state.value.copy(
                isLoading = !loadMore,
                isLoadingMore = loadMore,
                error = null
            )
            if (!loadMore) {
                _state.value = _state.value.copy(currentPage = 1)
            }
            try {
                val api = networkModule.getApiService()
                val params = mutableMapOf<String, String>()
                val tab = _state.value.selectedTab
                when (tab) {
                    0 -> params["type"] = "python"
                    1 -> params["type"] = "nodejs"
                    2 -> params["type"] = "linux"
                }
                params["page"] = _state.value.currentPage.toString()
                params["pageSize"] = _state.value.pageSize.toString()
                val response = api.getDependencies(params)
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    val newDeps = response.body()?.data ?: emptyList()
                    val total = response.body()?.total ?: 0
                    _state.value = _state.value.copy(
                        deps = if (loadMore) _state.value.deps + newDeps else newDeps,
                        total = total,
                        hasMore = _state.value.deps.size + newDeps.size < total,
                        isLoading = false,
                        isLoadingMore = false
                    )
                } else {
                    _state.value = _state.value.copy(
                        isLoading = false,
                        isLoadingMore = false,
                        error = response.body()?.message ?: "加载失败"
                    )
                }
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isLoading = false,
                    isLoadingMore = false,
                    error = e.message ?: "网络错误"
                )
            }
        }
    }

    fun loadPythonRuntimes() {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                val response = api.getPythonRuntimes()
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    @Suppress("UNCHECKED_CAST")
                    _state.value = _state.value.copy(
                        pythonRuntimes = response.body()?.data as? List<Map<String, Any>> ?: emptyList()
                    )
                }
            } catch (_: Exception) {}
        }
    }

    fun selectTab(tab: Int) {
        _state.value = _state.value.copy(selectedTab = tab, deps = emptyList())
        load()
    }

    fun loadMore() {
        if (_state.value.hasMore && !_state.value.isLoadingMore) {
            _state.value = _state.value.copy(currentPage = _state.value.currentPage + 1)
            load(loadMore = true)
        }
    }

    fun install(name: String, type: String) {
        viewModelScope.launch {
            val installing = _state.value.installingDeps.toMutableSet()
            installing.add(name)
            _state.value = _state.value.copy(installingDeps = installing, error = null)
            try {
                val api = networkModule.getApiService()
                if (type == "pip") {
                    api.pipInstall(mapOf("name" to name))
                } else if (type == "npm") {
                    api.npmInstall(mapOf("name" to name))
                } else {
                    api.installDep(mapOf("name" to name))
                }
                streamInstallLog(name)
                load()
            } catch (e: Exception) {
                _state.value = _state.value.copy(error = e.message ?: "安装失败")
            } finally {
                val updated = _state.value.installingDeps.toMutableSet()
                updated.remove(name)
                _state.value = _state.value.copy(installingDeps = updated)
            }
        }
    }

    private fun streamInstallLog(name: String) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                val response = api.streamDepLog(ApiEndpoints.depLogStream(0) + "?name=$name")
                if (response.isSuccessful) {
                    val body = response.body()
                    val log = body?.string() ?: ""
                    _state.value = _state.value.copy(installLog = log)
                }
            } catch (_: Exception) {}
        }
    }

    fun uninstall(id: Int) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.deleteDependency(id)
                load()
            } catch (_: Exception) {}
        }
    }

    fun reinstall(id: Int) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.reinstallDep(ApiEndpoints.depReinstall(id))
                load()
            } catch (_: Exception) {}
        }
    }

    fun cancel(name: String) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.cancelDep(ApiEndpoints.depCancel(0) + "?name=$name")
                val updated = _state.value.installingDeps.toMutableSet()
                updated.remove(name)
                _state.value = _state.value.copy(installingDeps = updated)
            } catch (_: Exception) {}
        }
    }

    fun clearError() {
        _state.value = _state.value.copy(error = null)
    }
}
