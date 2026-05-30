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

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u00002\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u000b\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\b6\u0018\u00002\u00020\u0001:\u0006\u000b\f\r\u000e\u000f\u0010B\u0017\b\u0004\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u0012\u0006\u0010\u0004\u001a\u00020\u0005\u00a2\u0006\u0002\u0010\u0006R\u0011\u0010\u0004\u001a\u00020\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0007\u0010\bR\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\t\u0010\n\u0082\u0001\u0006\u0011\u0012\u0013\u0014\u0015\u0016\u00a8\u0006\u0017"}, d2 = {"Lcom/daidai/app/ui/screen/home/HomeTab;", "", "title", "", "icon", "Landroidx/compose/ui/graphics/vector/ImageVector;", "(Ljava/lang/String;Landroidx/compose/ui/graphics/vector/ImageVector;)V", "getIcon", "()Landroidx/compose/ui/graphics/vector/ImageVector;", "getTitle", "()Ljava/lang/String;", "Dependencies", "Environments", "Logs", "Scripts", "Settings", "Tasks", "Lcom/daidai/app/ui/screen/home/HomeTab$Dependencies;", "Lcom/daidai/app/ui/screen/home/HomeTab$Environments;", "Lcom/daidai/app/ui/screen/home/HomeTab$Logs;", "Lcom/daidai/app/ui/screen/home/HomeTab$Scripts;", "Lcom/daidai/app/ui/screen/home/HomeTab$Settings;", "Lcom/daidai/app/ui/screen/home/HomeTab$Tasks;", "app_debug"})
public abstract class HomeTab {
    @org.jetbrains.annotations.NotNull
    private final java.lang.String title = null;
    @org.jetbrains.annotations.NotNull
    private final androidx.compose.ui.graphics.vector.ImageVector icon = null;
    
    private HomeTab(java.lang.String title, androidx.compose.ui.graphics.vector.ImageVector icon) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.lang.String getTitle() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull
    public final androidx.compose.ui.graphics.vector.ImageVector getIcon() {
        return null;
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/daidai/app/ui/screen/home/HomeTab$Dependencies;", "Lcom/daidai/app/ui/screen/home/HomeTab;", "()V", "app_debug"})
    public static final class Dependencies extends com.daidai.app.ui.screen.home.HomeTab {
        @org.jetbrains.annotations.NotNull
        public static final com.daidai.app.ui.screen.home.HomeTab.Dependencies INSTANCE = null;
        
        private Dependencies() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/daidai/app/ui/screen/home/HomeTab$Environments;", "Lcom/daidai/app/ui/screen/home/HomeTab;", "()V", "app_debug"})
    public static final class Environments extends com.daidai.app.ui.screen.home.HomeTab {
        @org.jetbrains.annotations.NotNull
        public static final com.daidai.app.ui.screen.home.HomeTab.Environments INSTANCE = null;
        
        private Environments() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/daidai/app/ui/screen/home/HomeTab$Logs;", "Lcom/daidai/app/ui/screen/home/HomeTab;", "()V", "app_debug"})
    public static final class Logs extends com.daidai.app.ui.screen.home.HomeTab {
        @org.jetbrains.annotations.NotNull
        public static final com.daidai.app.ui.screen.home.HomeTab.Logs INSTANCE = null;
        
        private Logs() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/daidai/app/ui/screen/home/HomeTab$Scripts;", "Lcom/daidai/app/ui/screen/home/HomeTab;", "()V", "app_debug"})
    public static final class Scripts extends com.daidai.app.ui.screen.home.HomeTab {
        @org.jetbrains.annotations.NotNull
        public static final com.daidai.app.ui.screen.home.HomeTab.Scripts INSTANCE = null;
        
        private Scripts() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/daidai/app/ui/screen/home/HomeTab$Settings;", "Lcom/daidai/app/ui/screen/home/HomeTab;", "()V", "app_debug"})
    public static final class Settings extends com.daidai.app.ui.screen.home.HomeTab {
        @org.jetbrains.annotations.NotNull
        public static final com.daidai.app.ui.screen.home.HomeTab.Settings INSTANCE = null;
        
        private Settings() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/daidai/app/ui/screen/home/HomeTab$Tasks;", "Lcom/daidai/app/ui/screen/home/HomeTab;", "()V", "app_debug"})
    public static final class Tasks extends com.daidai.app.ui.screen.home.HomeTab {
        @org.jetbrains.annotations.NotNull
        public static final com.daidai.app.ui.screen.home.HomeTab.Tasks INSTANCE = null;
        
        private Tasks() {
        }
    }
}