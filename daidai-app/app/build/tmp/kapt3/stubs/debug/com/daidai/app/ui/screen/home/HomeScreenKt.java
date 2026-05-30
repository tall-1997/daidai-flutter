package com.daidai.app.ui.screen.home;

import androidx.compose.foundation.layout.*;
import androidx.compose.foundation.text.KeyboardOptions;
import androidx.compose.material.icons.Icons;
import androidx.compose.material.icons.filled.*;
import androidx.compose.material3.*;
import androidx.compose.runtime.*;
import androidx.compose.ui.Alignment;
import androidx.compose.ui.Modifier;
import androidx.compose.ui.graphics.vector.ImageVector;
import androidx.compose.ui.text.font.FontWeight;
import androidx.compose.ui.text.input.KeyboardType;
import com.daidai.app.data.remote.model.Dependency;
import com.daidai.app.data.remote.model.Env;
import com.daidai.app.data.remote.model.Script;
import com.daidai.app.data.remote.model.Task;
import com.daidai.app.data.remote.model.TaskLog;
import com.daidai.app.ui.screen.dependency.DependencyViewModel;
import com.daidai.app.ui.screen.env.EnvViewModel;
import com.daidai.app.ui.screen.log.LogViewModel;
import com.daidai.app.ui.screen.script.ScriptViewModel;
import com.daidai.app.ui.screen.system.SystemViewModel;

@kotlin.Metadata(mv = {1, 9, 0}, k = 2, xi = 48, d1 = {"\u0000\u008e\u0001\n\u0000\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0007\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\u0010\b\n\u0002\b\u0005\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0004\n\u0002\u0010\u0006\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0007\n\u0002\u0010 \n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\t\n\u0000\u001a8\u0010\u0000\u001a\u00020\u00012\f\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00010\u00032 \u0010\u0004\u001a\u001c\u0012\u0004\u0012\u00020\u0006\u0012\u0004\u0012\u00020\u0006\u0012\u0006\u0012\u0004\u0018\u00010\u0006\u0012\u0004\u0012\u00020\u00010\u0005H\u0007\u001aZ\u0010\u0007\u001a\u00020\u00012\f\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00010\u00032$\u0010\u0004\u001a \u0012\u0004\u0012\u00020\u0006\u0012\u0004\u0012\u00020\u0006\u0012\u0004\u0012\u00020\u0006\u0012\u0004\u0012\u00020\u0006\u0012\u0004\u0012\u00020\u00010\b2\u001c\b\u0002\u0010\t\u001a\u0016\u0012\u0004\u0012\u00020\u0006\u0012\u0004\u0012\u00020\u0006\u0012\u0004\u0012\u00020\u0001\u0018\u00010\nH\u0007\u001a\u0012\u0010\u000b\u001a\u00020\u00012\b\b\u0002\u0010\f\u001a\u00020\rH\u0007\u001a^\u0010\u000e\u001a\u00020\u00012\u0006\u0010\u000f\u001a\u00020\u00062\b\b\u0002\u0010\u0010\u001a\u00020\u00062\b\b\u0002\u0010\u0011\u001a\u00020\u00062\b\b\u0002\u0010\u0012\u001a\u00020\u00062\f\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00010\u00032 \u0010\u0013\u001a\u001c\u0012\u0004\u0012\u00020\u0006\u0012\u0004\u0012\u00020\u0006\u0012\u0006\u0012\u0004\u0018\u00010\u0006\u0012\u0004\u0012\u00020\u00010\u0005H\u0007\u001a\u0012\u0010\u0014\u001a\u00020\u00012\b\b\u0002\u0010\f\u001a\u00020\u0015H\u0007\u001a>\u0010\u0016\u001a\u00020\u00012\u000e\b\u0002\u0010\u0017\u001a\b\u0012\u0004\u0012\u00020\u00010\u00032\u0014\b\u0002\u0010\u0018\u001a\u000e\u0012\u0004\u0012\u00020\u001a\u0012\u0004\u0012\u00020\u00010\u00192\u000e\b\u0002\u0010\u001b\u001a\b\u0012\u0004\u0012\u00020\u00010\u0003H\u0007\u001a8\u0010\u001c\u001a\u00020\u00012\u0006\u0010\u001d\u001a\u00020\u00062\f\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00010\u00032\u0018\u0010\u001e\u001a\u0014\u0012\u0004\u0012\u00020\u0006\u0012\u0004\u0012\u00020\u0006\u0012\u0004\u0012\u00020\u00010\nH\u0007\u001a\u0012\u0010\u001f\u001a\u00020\u00012\b\b\u0002\u0010\f\u001a\u00020 H\u0007\u001a*\u0010!\u001a\u00020\u00012\f\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00010\u00032\u0012\u0010\"\u001a\u000e\u0012\u0004\u0012\u00020\u0006\u0012\u0004\u0012\u00020\u00010\u0019H\u0007\u001a\u0012\u0010#\u001a\u00020\u00012\b\b\u0002\u0010\f\u001a\u00020$H\u0007\u001a0\u0010%\u001a\u00020\u00012\u0006\u0010&\u001a\u00020\'2\u0006\u0010\u000f\u001a\u00020\u00062\u0006\u0010(\u001a\u00020\u00062\u000e\b\u0002\u0010)\u001a\b\u0012\u0004\u0012\u00020\u00010\u0003H\u0007\u001a,\u0010*\u001a\u00020\u00012\u000e\b\u0002\u0010\u001b\u001a\b\u0012\u0004\u0012\u00020\u00010\u00032\b\b\u0002\u0010\f\u001a\u00020+2\b\b\u0002\u0010,\u001a\u00020-H\u0007\u001a \u0010.\u001a\u00020\u00012\u0006\u0010\u000f\u001a\u00020\u00062\u0006\u0010/\u001a\u00020\u00062\u0006\u0010&\u001a\u00020\'H\u0007\u001a\u0010\u00100\u001a\u00020\u00012\u0006\u00101\u001a\u000202H\u0007\u001a\u0088\u0001\u00103\u001a\u00020\u00012\u0006\u00104\u001a\u0002052\u000e\b\u0002\u0010)\u001a\b\u0012\u0004\u0012\u00020\u00010\u00032\f\u00106\u001a\b\u0012\u0004\u0012\u00020\u00010\u00032\f\u00107\u001a\b\u0012\u0004\u0012\u00020\u00010\u00032\f\u00108\u001a\b\u0012\u0004\u0012\u00020\u00010\u00032\f\u00109\u001a\b\u0012\u0004\u0012\u00020\u00010\u00032\f\u0010:\u001a\b\u0012\u0004\u0012\u00020\u00010\u00032\u0012\u0010;\u001a\u000e\u0012\u0004\u0012\u00020\u001a\u0012\u0004\u0012\u00020\u00010\u00192\f\u0010<\u001a\b\u0012\u0004\u0012\u00020\u00060=H\u0007\u001a2\u0010>\u001a\u00020\u00012\u0014\b\u0002\u0010\u0018\u001a\u000e\u0012\u0004\u0012\u00020\u001a\u0012\u0004\u0012\u00020\u00010\u00192\b\b\u0002\u0010?\u001a\u00020\u00062\b\b\u0002\u0010\f\u001a\u00020@H\u0007\u001a\u000e\u0010A\u001a\u00020\u00062\u0006\u0010B\u001a\u00020C\u00a8\u0006D"}, d2 = {"CreateScriptDialog", "", "onDismiss", "Lkotlin/Function0;", "onCreate", "Lkotlin/Function3;", "", "CreateTaskDialog", "Lkotlin/Function4;", "onUploadScript", "Lkotlin/Function2;", "DependenciesContent", "viewModel", "Lcom/daidai/app/ui/screen/dependency/DependencyViewModel;", "EnvDialog", "title", "initialName", "initialValue", "initialRemark", "onConfirm", "EnvironmentsContent", "Lcom/daidai/app/ui/screen/env/EnvViewModel;", "HomeScreen", "onNavigateToWebHelper", "onNavigateToTaskDetail", "Lkotlin/Function1;", "", "onLogout", "InstallDepDialog", "depType", "onInstall", "LogsContent", "Lcom/daidai/app/ui/screen/log/LogViewModel;", "ScriptSelectorDialog", "onSelect", "ScriptsContent", "Lcom/daidai/app/ui/screen/script/ScriptViewModel;", "SettingItem", "icon", "Landroidx/compose/ui/graphics/vector/ImageVector;", "subtitle", "onClick", "SettingsContent", "Lcom/daidai/app/ui/screen/system/SystemViewModel;", "serverConfigViewModel", "Lcom/daidai/app/ui/screen/home/ServerConfigViewModel;", "StatItem", "value", "StatusChip", "status", "", "TaskItem", "task", "Lcom/daidai/app/data/remote/model/Task;", "onRun", "onStop", "onEnable", "onDisable", "onDelete", "onGetLogs", "taskLogs", "", "TasksContent", "searchQuery", "Lcom/daidai/app/ui/screen/home/TaskViewModel;", "formatFileSize", "bytes", "", "app_debug"})
public final class HomeScreenKt {
    
    @kotlin.OptIn(markerClass = {androidx.compose.material3.ExperimentalMaterial3Api.class})
    @androidx.compose.runtime.Composable
    public static final void HomeScreen(@org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function0<kotlin.Unit> onNavigateToWebHelper, @org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function1<? super java.lang.Integer, kotlin.Unit> onNavigateToTaskDetail, @org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function0<kotlin.Unit> onLogout) {
    }
    
    @androidx.compose.runtime.Composable
    public static final void TasksContent(@org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function1<? super java.lang.Integer, kotlin.Unit> onNavigateToTaskDetail, @org.jetbrains.annotations.NotNull
    java.lang.String searchQuery, @org.jetbrains.annotations.NotNull
    com.daidai.app.ui.screen.home.TaskViewModel viewModel) {
    }
    
    @kotlin.OptIn(markerClass = {androidx.compose.material3.ExperimentalMaterial3Api.class})
    @androidx.compose.runtime.Composable
    public static final void CreateTaskDialog(@org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function0<kotlin.Unit> onDismiss, @org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function4<? super java.lang.String, ? super java.lang.String, ? super java.lang.String, ? super java.lang.String, kotlin.Unit> onCreate, @org.jetbrains.annotations.Nullable
    kotlin.jvm.functions.Function2<? super java.lang.String, ? super java.lang.String, kotlin.Unit> onUploadScript) {
    }
    
    @androidx.compose.runtime.Composable
    public static final void ScriptSelectorDialog(@org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function0<kotlin.Unit> onDismiss, @org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function1<? super java.lang.String, kotlin.Unit> onSelect) {
    }
    
    @androidx.compose.runtime.Composable
    public static final void EnvironmentsContent(@org.jetbrains.annotations.NotNull
    com.daidai.app.ui.screen.env.EnvViewModel viewModel) {
    }
    
    @androidx.compose.runtime.Composable
    public static final void EnvDialog(@org.jetbrains.annotations.NotNull
    java.lang.String title, @org.jetbrains.annotations.NotNull
    java.lang.String initialName, @org.jetbrains.annotations.NotNull
    java.lang.String initialValue, @org.jetbrains.annotations.NotNull
    java.lang.String initialRemark, @org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function0<kotlin.Unit> onDismiss, @org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function3<? super java.lang.String, ? super java.lang.String, ? super java.lang.String, kotlin.Unit> onConfirm) {
    }
    
    @kotlin.OptIn(markerClass = {androidx.compose.material3.ExperimentalMaterial3Api.class})
    @androidx.compose.runtime.Composable
    public static final void DependenciesContent(@org.jetbrains.annotations.NotNull
    com.daidai.app.ui.screen.dependency.DependencyViewModel viewModel) {
    }
    
    @kotlin.OptIn(markerClass = {androidx.compose.material3.ExperimentalMaterial3Api.class})
    @androidx.compose.runtime.Composable
    public static final void InstallDepDialog(@org.jetbrains.annotations.NotNull
    java.lang.String depType, @org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function0<kotlin.Unit> onDismiss, @org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function2<? super java.lang.String, ? super java.lang.String, kotlin.Unit> onInstall) {
    }
    
    @org.jetbrains.annotations.NotNull
    public static final java.lang.String formatFileSize(long bytes) {
        return null;
    }
    
    @androidx.compose.runtime.Composable
    public static final void ScriptsContent(@org.jetbrains.annotations.NotNull
    com.daidai.app.ui.screen.script.ScriptViewModel viewModel) {
    }
    
    @androidx.compose.runtime.Composable
    public static final void CreateScriptDialog(@org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function0<kotlin.Unit> onDismiss, @org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function3<? super java.lang.String, ? super java.lang.String, ? super java.lang.String, kotlin.Unit> onCreate) {
    }
    
    @androidx.compose.runtime.Composable
    public static final void LogsContent(@org.jetbrains.annotations.NotNull
    com.daidai.app.ui.screen.log.LogViewModel viewModel) {
    }
    
    @kotlin.OptIn(markerClass = {androidx.compose.material3.ExperimentalMaterial3Api.class})
    @androidx.compose.runtime.Composable
    public static final void SettingsContent(@org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function0<kotlin.Unit> onLogout, @org.jetbrains.annotations.NotNull
    com.daidai.app.ui.screen.system.SystemViewModel viewModel, @org.jetbrains.annotations.NotNull
    com.daidai.app.ui.screen.home.ServerConfigViewModel serverConfigViewModel) {
    }
    
    @androidx.compose.runtime.Composable
    public static final void StatItem(@org.jetbrains.annotations.NotNull
    java.lang.String title, @org.jetbrains.annotations.NotNull
    java.lang.String value, @org.jetbrains.annotations.NotNull
    androidx.compose.ui.graphics.vector.ImageVector icon) {
    }
    
    @androidx.compose.runtime.Composable
    public static final void SettingItem(@org.jetbrains.annotations.NotNull
    androidx.compose.ui.graphics.vector.ImageVector icon, @org.jetbrains.annotations.NotNull
    java.lang.String title, @org.jetbrains.annotations.NotNull
    java.lang.String subtitle, @org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function0<kotlin.Unit> onClick) {
    }
    
    @androidx.compose.runtime.Composable
    public static final void TaskItem(@org.jetbrains.annotations.NotNull
    com.daidai.app.data.remote.model.Task task, @org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function0<kotlin.Unit> onClick, @org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function0<kotlin.Unit> onRun, @org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function0<kotlin.Unit> onStop, @org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function0<kotlin.Unit> onEnable, @org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function0<kotlin.Unit> onDisable, @org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function0<kotlin.Unit> onDelete, @org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function1<? super java.lang.Integer, kotlin.Unit> onGetLogs, @org.jetbrains.annotations.NotNull
    java.util.List<java.lang.String> taskLogs) {
    }
    
    @androidx.compose.runtime.Composable
    public static final void StatusChip(double status) {
    }
}