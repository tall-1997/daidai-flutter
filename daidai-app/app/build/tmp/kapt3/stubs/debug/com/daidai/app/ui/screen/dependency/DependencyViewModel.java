package com.daidai.app.ui.screen.dependency;

import androidx.lifecycle.ViewModel;
import com.daidai.app.data.remote.model.Dependency;
import com.daidai.app.data.repository.DependencyRepository;
import dagger.hilt.android.lifecycle.HiltViewModel;
import kotlinx.coroutines.flow.StateFlow;
import javax.inject.Inject;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000:\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\u0002\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0003\n\u0002\u0010\b\n\u0002\b\u0003\b\u0007\u0018\u00002\u00020\u0001B\u000f\b\u0007\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\u0004J\u000e\u0010\f\u001a\u00020\r2\u0006\u0010\u000e\u001a\u00020\u000fJ\u0006\u0010\u0010\u001a\u00020\rJ\u000e\u0010\u0011\u001a\u00020\r2\u0006\u0010\u0012\u001a\u00020\u0013J\u0012\u0010\u0014\u001a\u00020\r2\n\b\u0002\u0010\u000e\u001a\u0004\u0018\u00010\u000fJ\u000e\u0010\u0015\u001a\u00020\r2\u0006\u0010\u0012\u001a\u00020\u0013R\u0014\u0010\u0005\u001a\b\u0012\u0004\u0012\u00020\u00070\u0006X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0017\u0010\b\u001a\b\u0012\u0004\u0012\u00020\u00070\t\u00a2\u0006\b\n\u0000\u001a\u0004\b\n\u0010\u000b\u00a8\u0006\u0016"}, d2 = {"Lcom/daidai/app/ui/screen/dependency/DependencyViewModel;", "Landroidx/lifecycle/ViewModel;", "dependencyRepository", "Lcom/daidai/app/data/repository/DependencyRepository;", "(Lcom/daidai/app/data/repository/DependencyRepository;)V", "_uiState", "Lkotlinx/coroutines/flow/MutableStateFlow;", "Lcom/daidai/app/ui/screen/dependency/DependencyListUiState;", "uiState", "Lkotlinx/coroutines/flow/StateFlow;", "getUiState", "()Lkotlinx/coroutines/flow/StateFlow;", "changeType", "", "type", "", "clearError", "deleteDep", "id", "", "loadDeps", "reinstallDep", "app_debug"})
@dagger.hilt.android.lifecycle.HiltViewModel
public final class DependencyViewModel extends androidx.lifecycle.ViewModel {
    @org.jetbrains.annotations.NotNull
    private final com.daidai.app.data.repository.DependencyRepository dependencyRepository = null;
    @org.jetbrains.annotations.NotNull
    private final kotlinx.coroutines.flow.MutableStateFlow<com.daidai.app.ui.screen.dependency.DependencyListUiState> _uiState = null;
    @org.jetbrains.annotations.NotNull
    private final kotlinx.coroutines.flow.StateFlow<com.daidai.app.ui.screen.dependency.DependencyListUiState> uiState = null;
    
    @javax.inject.Inject
    public DependencyViewModel(@org.jetbrains.annotations.NotNull
    com.daidai.app.data.repository.DependencyRepository dependencyRepository) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull
    public final kotlinx.coroutines.flow.StateFlow<com.daidai.app.ui.screen.dependency.DependencyListUiState> getUiState() {
        return null;
    }
    
    public final void loadDeps(@org.jetbrains.annotations.Nullable
    java.lang.String type) {
    }
    
    public final void changeType(@org.jetbrains.annotations.NotNull
    java.lang.String type) {
    }
    
    public final void deleteDep(int id) {
    }
    
    public final void reinstallDep(int id) {
    }
    
    public final void clearError() {
    }
}