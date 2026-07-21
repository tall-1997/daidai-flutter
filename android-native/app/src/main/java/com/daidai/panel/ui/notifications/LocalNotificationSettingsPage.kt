package com.daidai.panel.ui.notifications

import android.Manifest
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.NotificationsOff
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.daidai.panel.core.theme.AppColors
import com.daidai.panel.ui.components.GlassCard
import kotlinx.coroutines.flow.collectLatest

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LocalNotificationSettingsPage(
    onBack: () -> Unit,
    viewModel: LocalNotificationViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()
    val isLight = !isSystemInDarkTheme()
    val context = LocalContext.current
    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(Unit) {
        viewModel.refreshPermission()
        viewModel.state.collectLatest { s ->
            s.testResult?.let { result ->
                snackbarHostState.showSnackbar(result)
                viewModel.clearTestResult()
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("本地通知") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "返回",
                            tint = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = if (isLight) AppColors.white else AppColors.black
                )
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item {
                GlassCard(
                    modifier = Modifier.fillMaxWidth(),
                    padding = PaddingValues(16.dp)
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = if (state.permissionGranted) Icons.Default.CheckCircle
                            else Icons.Default.NotificationsOff,
                            contentDescription = null,
                            tint = if (state.permissionGranted) AppColors.primary else AppColors.amber500,
                            modifier = Modifier.size(24.dp)
                        )
                        Spacer(modifier = Modifier.width(12.dp))
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                "通知权限",
                                style = MaterialTheme.typography.bodyLarge.copy(fontWeight = FontWeight.SemiBold),
                                color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                            )
                            Text(
                                if (state.permissionGranted) "已授予" else "未授予",
                                fontSize = 13.sp,
                                color = if (state.permissionGranted) AppColors.primary else AppColors.amber500
                            )
                        }
                        if (!state.permissionGranted && Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            Button(
                                onClick = {
                                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                        data = Uri.parse("package:${context.packageName}")
                                    }
                                    context.startActivity(intent)
                                },
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = AppColors.primary
                                ),
                                shape = RoundedCornerShape(8.dp)
                            ) {
                                Text("去设置", fontSize = 13.sp)
                            }
                        }
                    }
                }
            }

            item {
                Text(
                    "通知渠道",
                    fontSize = 13.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(top = 4.dp)
                )
            }

            item {
                GlassCard(
                    modifier = Modifier.fillMaxWidth(),
                    padding = PaddingValues(16.dp)
                ) {
                    Column {
                        NotificationChannelRow(
                            icon = Icons.Default.Notifications,
                            title = "任务通知",
                            subtitle = "任务执行完成或失败时触发",
                            enabled = state.taskEnabled,
                            onToggle = { viewModel.setTaskEnabled(it) },
                            onTest = { viewModel.sendTestNotification("task") },
                            isLight = isLight
                        )
                        HorizontalDivider(
                            modifier = Modifier.padding(vertical = 12.dp),
                            thickness = 1.dp,
                            color = if (isLight) AppColors.glassDivider else AppColors.slate800
                        )
                        NotificationChannelRow(
                            icon = Icons.Default.Notifications,
                            title = "系统通知",
                            subtitle = "面板系统事件和安全相关通知",
                            enabled = state.systemEnabled,
                            onToggle = { viewModel.setSystemEnabled(it) },
                            onTest = { viewModel.sendTestNotification("system") },
                            isLight = isLight
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun NotificationChannelRow(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    subtitle: String,
    enabled: Boolean,
    onToggle: (Boolean) -> Unit,
    onTest: () -> Unit,
    isLight: Boolean
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(40.dp)
                .padding(8.dp),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = if (enabled) AppColors.primary else AppColors.slate400,
                modifier = Modifier.size(24.dp)
            )
        }
        Spacer(modifier = Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                title,
                fontSize = 15.sp,
                fontWeight = FontWeight.Medium,
                color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
            )
            Text(
                subtitle,
                fontSize = 12.sp,
                color = if (isLight) AppColors.slate500 else AppColors.slate400
            )
        }
        Spacer(modifier = Modifier.width(8.dp))
        Button(
            onClick = onTest,
            enabled = enabled,
            colors = ButtonDefaults.buttonColors(
                containerColor = AppColors.primary.copy(alpha = 0.1f),
                contentColor = AppColors.primary
            ),
            shape = RoundedCornerShape(8.dp),
            contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp)
        ) {
            Icon(Icons.Default.Send, contentDescription = null, modifier = Modifier.size(16.dp))
            Spacer(modifier = Modifier.width(4.dp))
            Text("测试", fontSize = 12.sp)
        }
        Spacer(modifier = Modifier.width(4.dp))
        Switch(
            checked = enabled,
            onCheckedChange = onToggle,
            colors = SwitchDefaults.colors(
                checkedThumbColor = AppColors.white,
                checkedTrackColor = AppColors.primary,
                uncheckedThumbColor = AppColors.white,
                uncheckedTrackColor = AppColors.slate300
            )
        )
    }
}
