package com.daidai.app.ui.screen.dependency

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.daidai.app.data.remote.model.Dependency
import com.daidai.app.data.repository.DependencyRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class DependencyListUiState(
    val isLoading: Boolean = false,
    val dependencies: List<Dependency> = emptyList(),
    val selectedType: String = Dependency.TYPE_NODEJS,
    val error: String? = null
)

@HiltViewModel
class DependencyViewModel @Inject constructor(
    private val dependencyRepository: DependencyRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow(DependencyListUiState())
    val uiState: StateFlow<DependencyListUiState> = _uiState.asStateFlow()

    init {
        loadDeps()
    }

    fun loadDeps(type: String? = null) {
        val depType = type ?: _uiState.value.selectedType
        _uiState.value = _uiState.value.copy(selectedType = depType)
        
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            
            dependencyRepository.getDeps(depType)
                .onSuccess { response ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        dependencies = response.data ?: emptyList()
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

    fun changeType(type: String) {
        loadDeps(type)
    }

    fun deleteDep(id: Int) {
        viewModelScope.launch {
            dependencyRepository.deleteDep(id)
                .onSuccess {
                    loadDeps()
                }
                .onFailure { exception ->
                    _uiState.value = _uiState.value.copy(error = exception.message)
                }
        }
    }

    fun reinstallDep(id: Int) {
        viewModelScope.launch {
            dependencyRepository.reinstallDep(id)
                .onSuccess {
                    loadDeps()
                }
                .onFailure { exception ->
                    _uiState.value = _uiState.value.copy(error = exception.message)
                }
        }
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }
}
