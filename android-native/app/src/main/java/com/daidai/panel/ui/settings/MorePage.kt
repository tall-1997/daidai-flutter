package com.daidai.panel.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ExitToApp
import androidx.compose.material.icons.filled.AdminPanelSettings
import androidx.compose.material.icons.filled.Api
import androidx.compose.material.icons.filled.Backup
import androidx.compose.material.icons.filled.BugReport
import androidx.compose.material.icons.filled.ColorLens
import androidx.compose.material.icons.filled.Dashboard
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Computer
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.Security
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Subscriptions
import androidx.compose.material.icons.filled.Terminal
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.daidai.panel.core.auth.AuthViewModel
import com.daidai.panel.core.theme.AppColors
import com.daidai.panel.ui.components.AppListTile
import com.daidai.panel.ui.components.GlassCard

@Composable
fun MorePage(
    contentPadding: PaddingValues,
    glassMode: Boolean,
    onNavigate: (String) -> Unit,
    onLogout: () -> Unit,
    authViewModel: AuthViewModel = hiltViewModel()
) {
    val authState by authViewModel.authState.collectAsState()
    val isLight = !isSystemInDarkTheme()
    var showLogoutDialog by remember { mutableStateOf(false) }
    val user = authState.user

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(contentPadding),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // User info
        item {
            GlassCard(
                modifier = Modifier.fillMaxWidth(),
                padding = PaddingValues(16.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    val avatarUrl = user?.avatarUrl
                    if (!avatarUrl.isNullOrEmpty()) {
                        AsyncImage(
                            model = avatarUrl,
                            contentDescription = null,
                            modifier = Modifier
                                .size(52.dp)
                                .clip(CircleShape)
                        )
                    } else {
                        Box(
                            modifier = Modifier
                                .size(52.dp)
                                .clip(CircleShape)
                                .background(AppColors.primary),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = (user?.username ?: "U").take(1).uppercase(),
                                style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold),
                                color = AppColors.white
                            )
                        }
                    }
                    Spacer(modifier = Modifier.width(16.dp))
                    Column {
                        Text(
                            text = user?.username ?: "未登录",
                            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold),
                            color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                        )
                        Text(
                            text = if (user?.isAdmin == true) "管理员" else "操作员",
                            style = MaterialTheme.typography.bodySmall,
                            color = AppColors.primary
                        )
                    }
                }
            }
        }

        // App settings section
        item {
            SectionHeader("应用设置", isLight)
        }

        item {
            AppListTile(
                icon = Icons.Default.Computer,
                title = "服务器管理",
                onClick = { onNavigate("serverConfig") }
            )
        }

        item {
            AppListTile(
                icon = Icons.Default.Description,
                title = "环境变量",
                onClick = { onNavigate("envs") }
            )
        }

        item {
            AppListTile(
                icon = Icons.Default.Lock,
                title = "应用锁",
                onClick = { onNavigate("appLock") }
            )
        }

        item {
            AppListTile(
                icon = Icons.Default.Notifications,
                title = "通知管理",
                onClick = { onNavigate("notifications") }
            )
        }

        item {
            AppListTile(
                icon = Icons.Default.Notifications,
                title = "本地通知",
                onClick = { onNavigate("localNotifications") }
            )
        }

        // System management section
        item {
            SectionHeader("系统管理", isLight)
        }

        item {
            AppListTile(
                icon = Icons.Default.Subscriptions,
                title = "订阅管理",
                onClick = { onNavigate("subscriptions") }
            )
        }

        item {
            AppListTile(
                icon = Icons.Default.Terminal,
                title = "脚本管理",
                onClick = { onNavigate("scripts") }
            )
        }

        item {
            AppListTile(
                icon = Icons.Default.Description,
                title = "依赖管理",
                onClick = { onNavigate("deps") }
            )
        }

        if (user?.isAdmin == true) {
            item {
                AppListTile(
                    icon = Icons.Default.People,
                    title = "用户管理",
                    onClick = { onNavigate("users") }
                )
            }

            item {
                AppListTile(
                    icon = Icons.Default.Security,
                    title = "安全管理",
                    onClick = { onNavigate("security") }
                )
            }

            item {
                AppListTile(
                    icon = Icons.Default.Settings,
                    title = "系统设置",
                    onClick = { onNavigate("systemSettings") }
                )
            }

            item {
                AppListTile(
                    icon = Icons.Default.BugReport,
                    title = "面板日志",
                    onClick = { onNavigate("panelLog") }
                )
            }

            item {
                AppListTile(
                    icon = Icons.Default.Backup,
                    title = "备份恢复",
                    onClick = { onNavigate("backup") }
                )
            }

            item {
                AppListTile(
                    icon = Icons.Default.Api,
                    title = "Open API",
                    onClick = { onNavigate("openApi") }
                )
            }
        }

        // Other
        item {
            SectionHeader("其他", isLight)
        }

        item {
            AppListTile(
                icon = Icons.Default.Favorite,
                title = "支持者",
                onClick = { onNavigate("sponsors") }
            )
        }

        item {
            AppListTile(
                icon = Icons.Default.Info,
                title = "关于",
                onClick = { onNavigate("about") },
                trailing = {
                    Text(
                        text = "v1.0.0",
                        style = MaterialTheme.typography.labelSmall,
                        color = AppColors.slate400
                    )
                }
            )
        }

        // Logout
        item {
            Spacer(modifier = Modifier.height(8.dp))
            AppListTile(
                icon = Icons.AutoMirrored.Filled.ExitToApp,
                title = "退出登录",
                onClick = { showLogoutDialog = true },
                modifier = Modifier.fillMaxWidth()
            )
        }

        item { Spacer(modifier = Modifier.height(16.dp)) }
    }

    if (showLogoutDialog) {
        AlertDialog(
            onDismissRequest = { showLogoutDialog = false },
            title = { Text("确认退出") },
            text = { Text("确定要退出登录吗？") },
            confirmButton = {
                TextButton(onClick = {
                    showLogoutDialog = false
                    onLogout()
                }) {
                    Text("退出", color = AppColors.red500)
                }
            },
            dismissButton = {
                TextButton(onClick = { showLogoutDialog = false }) {
                    Text("取消")
                }
            }
        )
    }
}

@Composable
private fun SectionHeader(title: String, isLight: Boolean) {
    Text(
        text = title,
        style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.SemiBold),
        color = if (isLight) AppColors.slate500 else AppColors.slate400,
        modifier = Modifier.padding(top = 4.dp)
    )
}
