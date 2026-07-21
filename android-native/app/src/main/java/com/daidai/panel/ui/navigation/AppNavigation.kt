package com.daidai.panel.ui.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.ui.Modifier
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import com.daidai.panel.core.auth.AuthStatus
import com.daidai.panel.core.auth.AuthViewModel
import com.daidai.panel.ui.dashboard.DashboardPage
import com.daidai.panel.ui.deps.DepListPage
import com.daidai.panel.ui.envs.EnvFormPage
import com.daidai.panel.ui.envs.EnvListPage
import com.daidai.panel.ui.login.BootPage
import com.daidai.panel.ui.login.LoginPage
import com.daidai.panel.ui.login.ServerConfigPage
import com.daidai.panel.ui.logs.LogListPage
import com.daidai.panel.ui.logs.LogStreamPage
import com.daidai.panel.ui.main.MainScaffold
import com.daidai.panel.ui.notifications.LocalNotificationSettingsPage
import com.daidai.panel.ui.notifications.NotificationListPage
import com.daidai.panel.ui.openapi.OpenApiPage
import com.daidai.panel.ui.scripts.ScriptListPage
import com.daidai.panel.ui.scripts.ScriptViewPage
import com.daidai.panel.ui.security.SecurityPage
import com.daidai.panel.ui.settings.AboutPage
import com.daidai.panel.ui.settings.AppLockSettingsPage
import com.daidai.panel.ui.settings.MorePage
import com.daidai.panel.ui.settings.SponsorPage
import com.daidai.panel.ui.subscriptions.SubscriptionListPage
import com.daidai.panel.ui.system.BackupPage
import com.daidai.panel.ui.system.PanelLogPage
import com.daidai.panel.ui.system.SystemSettingsPage
import com.daidai.panel.ui.tasks.TaskFormPage
import com.daidai.panel.ui.tasks.TaskListPage
import com.daidai.panel.ui.users.UserListPage

sealed class Screen(val route: String) {
    object Boot : Screen("boot")
    object ServerConfig : Screen("serverConfig")
    object Login : Screen("login?needsServerUrl={needsServerUrl}") {
        fun createRoute(needsServerUrl: Boolean = false) = "login?needsServerUrl=$needsServerUrl"
    }
    object Main : Screen("main/{tab}") {
        fun createRoute(tab: String = "dashboard") = "main/$tab"
    }
    object Dashboard : Screen("dashboard")
    object Tasks : Screen("tasks")
    object Logs : Screen("logs")
    object Envs : Screen("envs")
    object More : Screen("more")
    object TaskForm : Screen("taskForm?taskId={taskId}") {
        fun createRoute(taskId: Int? = null) =
            if (taskId != null) "taskForm?taskId=$taskId" else "taskForm"
    }
    object LogStream : Screen("logStream/{logId}") {
        fun createRoute(logId: Int) = "logStream/$logId"
    }
    object Subscriptions : Screen("subscriptions")
    object Scripts : Screen("scripts")
    object ScriptView : Screen("scriptView/{filePath}") {
        fun createRoute(filePath: String) = "scriptView/${java.net.URLEncoder.encode(filePath, "UTF-8")}"
    }
    object Notifications : Screen("notifications")
    object LocalNotifications : Screen("localNotifications")
    object Deps : Screen("deps")
    object Users : Screen("users")
    object Security : Screen("security")
    object SystemSettings : Screen("systemSettings")
    object PanelLog : Screen("panelLog")
    object Backup : Screen("backup")
    object OpenApi : Screen("openApi")
    object AppLock : Screen("appLock")
    object Sponsors : Screen("sponsors")
    object About : Screen("about")
    object EnvForm : Screen("envForm?envId={envId}") {
        fun createRoute(envId: Int? = null) =
            if (envId != null) "envForm?envId=$envId" else "envForm"
    }
}

@Composable
fun AppNavigation(
    navController: NavHostController,
    authViewModel: AuthViewModel = hiltViewModel()
) {
    val authState by authViewModel.authState.collectAsState()

    NavHost(
        navController = navController,
        startDestination = Screen.Boot.route
    ) {
        composable(Screen.Boot.route) {
            BootPage(
                onNavigateToServerConfig = {
                    navController.navigate(Screen.ServerConfig.route) {
                        popUpTo(Screen.Boot.route) { inclusive = true }
                    }
                },
                onNavigateToLogin = {
                    navController.navigate(Screen.Login.createRoute(needsServerUrl = true)) {
                        popUpTo(Screen.Boot.route) { inclusive = true }
                    }
                },
                onNavigateToMain = {
                    navController.navigate(Screen.Main.createRoute()) {
                        popUpTo(Screen.Boot.route) { inclusive = true }
                    }
                }
            )
        }

        composable(Screen.ServerConfig.route) {
            ServerConfigPage(
                onServerSelected = {
                    navController.navigate(Screen.Login.route) {
                        popUpTo(Screen.ServerConfig.route) { inclusive = true }
                    }
                }
            )
        }

        composable(
            route = Screen.Login.route,
            arguments = listOf(navArgument("needsServerUrl") {
                type = NavType.BoolType
                defaultValue = false
            })
        ) { backStackEntry ->
            val needsServerUrl = backStackEntry.arguments?.getBoolean("needsServerUrl") ?: false
            if (authState.status == AuthStatus.AUTHENTICATED) {
                navController.navigate(Screen.Main.createRoute()) {
                    popUpTo(Screen.Login.route) { inclusive = true }
                }
            } else {
                LoginPage(
                    needsServerUrl = needsServerUrl,
                    onLoginSuccess = {
                        navController.navigate(Screen.Main.createRoute()) {
                            popUpTo(Screen.Login.route) { inclusive = true }
                        }
                    },
                    onNavigateToServerConfig = {
                        navController.navigate(Screen.ServerConfig.route)
                    }
                )
            }
        }

        composable(
            route = Screen.Main.route,
            arguments = listOf(navArgument("tab") {
                type = NavType.StringType
                defaultValue = "dashboard"
            })
        ) { backStackEntry ->
            val tab = backStackEntry.arguments?.getString("tab") ?: "dashboard"
            MainScaffold(
                initialTab = tab,
                onNavigateToSubPage = { route ->
                    navController.navigate(route)
                },
                onLogout = {
                    authViewModel.logout()
                    navController.navigate(Screen.Login.route) {
                        popUpTo(0) { inclusive = true }
                    }
                }
            )
        }

        composable(
            route = Screen.TaskForm.route,
            arguments = listOf(navArgument("taskId") {
                type = NavType.IntType
                defaultValue = -1
            })
        ) { backStackEntry ->
            val taskId = backStackEntry.arguments?.getInt("taskId")?.takeIf { it > 0 }
            TaskFormPage(
                taskId = taskId,
                onBack = { navController.popBackStack() }
            )
        }

        composable(
            route = Screen.LogStream.route,
            arguments = listOf(navArgument("logId") { type = NavType.IntType })
        ) {
            LogStreamPage(onBack = { navController.popBackStack() })
        }

        composable(Screen.Subscriptions.route) {
            SubscriptionListPage(onBack = { navController.popBackStack() })
        }
        composable(Screen.Scripts.route) {
            ScriptListPage(
                onBack = { navController.popBackStack() },
                onOpenFile = { path -> navController.navigate(Screen.ScriptView.createRoute(path)) }
            )
        }
        composable(
            route = Screen.ScriptView.route,
            arguments = listOf(navArgument("filePath") { type = NavType.StringType })
        ) { backStackEntry ->
            val filePath = java.net.URLDecoder.decode(
                backStackEntry.arguments?.getString("filePath") ?: "",
                "UTF-8"
            )
            ScriptViewPage(
                filePath = filePath,
                onBack = { navController.popBackStack() }
            )
        }
        composable(Screen.Notifications.route) {
            NotificationListPage(onBack = { navController.popBackStack() })
        }
        composable(Screen.LocalNotifications.route) {
            LocalNotificationSettingsPage(onBack = { navController.popBackStack() })
        }
        composable(Screen.Deps.route) {
            DepListPage(onBack = { navController.popBackStack() })
        }
        composable(Screen.Users.route) {
            UserListPage(onBack = { navController.popBackStack() })
        }
        composable(Screen.Security.route) {
            SecurityPage(onBack = { navController.popBackStack() })
        }
        composable(Screen.SystemSettings.route) {
            SystemSettingsPage(onBack = { navController.popBackStack() })
        }
        composable(Screen.PanelLog.route) {
            PanelLogPage(onBack = { navController.popBackStack() })
        }
        composable(Screen.Backup.route) {
            BackupPage(onBack = { navController.popBackStack() })
        }
        composable(Screen.OpenApi.route) {
            OpenApiPage(onBack = { navController.popBackStack() })
        }
        composable(Screen.AppLock.route) {
            AppLockSettingsPage(onBack = { navController.popBackStack() })
        }
        composable(Screen.Sponsors.route) {
            SponsorPage(onBack = { navController.popBackStack() })
        }
        composable(Screen.About.route) {
            AboutPage(onBack = { navController.popBackStack() })
        }
        composable(
            route = Screen.EnvForm.route,
            arguments = listOf(navArgument("envId") {
                type = NavType.IntType
                defaultValue = -1
            })
        ) {
            EnvFormPage(onBack = { navController.popBackStack() })
        }
    }
}

@Composable
private fun PlaceholderPage(title: String) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = androidx.compose.ui.Alignment.Center
    ) {
        androidx.compose.material3.Text(
            text = title,
            style = androidx.compose.material3.MaterialTheme.typography.headlineMedium
        )
    }
}
