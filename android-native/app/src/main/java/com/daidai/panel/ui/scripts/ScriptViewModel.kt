package com.daidai.panel.ui.scripts

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.daidai.panel.core.network.NetworkModule
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ScriptTreeNode(
    val name: String = "",
    val path: String = "",
    val isDirectory: Boolean = false,
    val children: List<ScriptTreeNode> = emptyList(),
    val isExpanded: Boolean = false
)

data class ScriptState(
    val tree: List<ScriptTreeNode> = emptyList(),
    val currentPath: String = "",
    val currentContent: String = "",
    val isBinary: Boolean = false,
    val isLoading: Boolean = false,
    val isSaving: Boolean = false,
    val error: String? = null,
    val versions: List<Map<String, Any>> = emptyList(),
    val runResult: String = "",
    val isRunning: Boolean = false,
    val searchQuery: String = ""
)

@HiltViewModel
class ScriptViewModel @Inject constructor(
    private val networkModule: NetworkModule
) : ViewModel() {

    private val _state = MutableStateFlow(ScriptState())
    val state: StateFlow<ScriptState> = _state.asStateFlow()

    init {
        loadTree()
    }

    fun loadTree() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            try {
                val api = networkModule.getApiService()
                val response = api.getScriptsTree(emptyMap())
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    @Suppress("UNCHECKED_CAST")
                    val rawTree = response.body()?.data as? List<Map<String, Any>> ?: emptyList()
                    _state.value = _state.value.copy(
                        tree = rawTree.map { parseNode(it) },
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

    @Suppress("UNCHECKED_CAST")
    private fun parseNode(map: Map<String, Any>): ScriptTreeNode {
        val childrenRaw = map["children"]
        val children = when (childrenRaw) {
            is List<*> -> childrenRaw.mapNotNull { item ->
                when (item) {
                    is Map<*, *> -> parseNode(item as Map<String, Any>)
                    else -> null
                }
            }
            else -> emptyList()
        }
        return ScriptTreeNode(
            name = (map["title"] as? String) ?: (map["name"] as? String) ?: "",
            path = (map["key"] as? String) ?: (map["path"] as? String) ?: "",
            isDirectory = (map["type"] as? String) == "directory"
                || (map["is_directory"] as? Boolean) == true
                || (map["isLeaf"] as? Boolean) == false,
            children = children
        )
    }

    fun toggleExpand(path: String) {
        _state.value = _state.value.copy(
            tree = toggleNode(_state.value.tree, path)
        )
    }

    private fun toggleNode(nodes: List<ScriptTreeNode>, path: String): List<ScriptTreeNode> {
        return nodes.map { node ->
            if (node.path == path) {
                node.copy(isExpanded = !node.isExpanded)
            } else if (node.children.isNotEmpty()) {
                node.copy(children = toggleNode(node.children, path))
            } else {
                node
            }
        }
    }

    fun loadContent(path: String) {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, currentPath = path, error = null, isBinary = false)
            try {
                val api = networkModule.getApiService()
                val response = api.getScriptContent(mapOf("path" to path))
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    val data = response.body()?.data ?: emptyMap()
                    val isBinary = data["binary"] == true || data["is_binary"] == true
                    val content = if (isBinary) "" else (data["content"] as? String) ?: ""
                    _state.value = _state.value.copy(
                        currentContent = content,
                        isBinary = isBinary,
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

    fun save(path: String, content: String) {
        viewModelScope.launch {
            _state.value = _state.value.copy(isSaving = true, error = null)
            try {
                val api = networkModule.getApiService()
                val response = api.putScriptContent(
                    mapOf("path" to path, "content" to content, "message" to "")
                )
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    _state.value = _state.value.copy(isSaving = false, isBinary = false)
                } else {
                    _state.value = _state.value.copy(
                        isSaving = false,
                        error = response.body()?.message ?: "保存失败"
                    )
                }
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isSaving = false,
                    error = e.message ?: "网络错误"
                )
            }
        }
    }

    fun upload(path: String, fileName: String, fileBytes: ByteArray) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                val part = okhttp3.MultipartBody.Part.createFormData(
                    "file", fileName,
                    okhttp3.RequestBody.create(null, fileBytes)
                )
                val pathBody = okhttp3.RequestBody.create(null, path)
                api.uploadScript(part, pathBody)
                loadTree()
            } catch (_: Exception) {}
        }
    }

    fun createDirectory(path: String) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.createDirectory(mapOf("path" to path))
                loadTree()
            } catch (_: Exception) {}
        }
    }

    fun rename(oldPath: String, newName: String) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.renameScript(mapOf("path" to oldPath, "new_name" to newName))
                loadTree()
            } catch (_: Exception) {}
        }
    }

    fun move(fromPath: String, toPath: String) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.moveScript(mapOf("from" to fromPath, "to" to toPath))
                loadTree()
            } catch (_: Exception) {}
        }
    }

    fun copy(fromPath: String, toPath: String) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.copyScript(mapOf("from" to fromPath, "to" to toPath))
                loadTree()
            } catch (_: Exception) {}
        }
    }

    fun delete(path: String) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                api.batchScripts(mapOf("action" to "delete", "paths" to listOf(path)))
                if (_state.value.currentPath == path) {
                    _state.value = _state.value.copy(currentPath = "", currentContent = "")
                }
                loadTree()
            } catch (_: Exception) {}
        }
    }

    fun download(path: String) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                val response = api.downloadScript(mapOf("path" to path))
                if (response.isSuccessful) {
                    _state.value = _state.value.copy(error = null)
                }
            } catch (e: Exception) {
                _state.value = _state.value.copy(error = e.message)
            }
        }
    }

    fun run(path: String) {
        viewModelScope.launch {
            _state.value = _state.value.copy(isRunning = true, runResult = "", error = null)
            try {
                val api = networkModule.getApiService()
                api.runScript(mapOf("path" to path))
                loadRunLogs(path)
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isRunning = false,
                    error = e.message ?: "运行失败"
                )
            }
        }
    }

    private fun loadRunLogs(path: String) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                val response = api.getRunLogs(mapOf("path" to path))
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    @Suppress("UNCHECKED_CAST")
                    val data = response.body()?.data as? Map<String, Any>
                    val output = data?.get("output") as? String ?: ""
                    val status = data?.get("status") as? Int ?: 0
                    _state.value = _state.value.copy(
                        runResult = output,
                        isRunning = status == 0
                    )
                }
            } catch (_: Exception) {}
        }
    }

    fun format(path: String) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                val response = api.formatScript(mapOf("path" to path))
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    _state.value = _state.value.copy(
                        currentContent = response.body()?.data ?: _state.value.currentContent
                    )
                }
            } catch (_: Exception) {}
        }
    }

    fun loadVersions(path: String) {
        viewModelScope.launch {
            try {
                val api = networkModule.getApiService()
                val response = api.getScriptVersions(mapOf("path" to path))
                if (response.isSuccessful && response.body()?.isSuccess == true) {
                    @Suppress("UNCHECKED_CAST")
                    _state.value = _state.value.copy(
                        versions = response.body()?.data as? List<Map<String, Any>> ?: emptyList()
                    )
                }
            } catch (_: Exception) {}
        }
    }

    fun updateSearchQuery(query: String) {
        _state.value = _state.value.copy(searchQuery = query)
    }

    fun clearError() {
        _state.value = _state.value.copy(error = null)
    }
}
