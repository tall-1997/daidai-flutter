package com.daidai.panel.ui.system

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.CloudDownload
import androidx.compose.material.icons.filled.NetworkCheck
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Save
import androidx.compose.material.icons.filled.Update
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.daidai.panel.core.theme.AppColors
import com.daidai.panel.ui.components.GlassCard

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SystemSettingsPage(
    onBack: () -> Unit,
    viewModel: SystemViewModel = hiltViewModel()
) {
    val isLight = !isSystemInDarkTheme()
    val state by viewModel.state.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }

    var concurrentTasks by remember { mutableStateOf("") }
    var logRetentionDays by remember { mutableStateOf("") }
    var proxyUrl by remember { mutableStateOf("") }
    var proxyUsername by remember { mutableStateOf("") }
    var proxyPassword by remember { mutableStateOf("") }
    var dockerMirror by remember { mutableStateOf("") }

    LaunchedEffect(state.settings) {
        if (state.settings.isNotEmpty()) {
            concurrentTasks = (state.settings["concurrent_tasks"] as? Number)?.toInt()?.toString() ?: ""
            logRetentionDays = (state.settings["log_retention_days"] as? Number)?.toInt()?.toString() ?: ""
            proxyUrl = state.settings["proxy_url"] as? String ?: ""
            proxyUsername = state.settings["proxy_username"] as? String ?: ""
            proxyPassword = state.settings["proxy_password"] as? String ?: ""
            dockerMirror = state.settings["docker_mirror"] as? String ?: ""
        }
    }

    LaunchedEffect(state.successMessage) {
        state.successMessage?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearMessages()
        }
    }

    LaunchedEffect(state.error) {
        state.error?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearMessages()
        }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { padding ->
        Column(modifier = Modifier.fillMaxSize().padding(padding)) {
            TopAppBar(
                title = {
                    Text(
                        "系统设置",
                        style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold)
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "返回")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Transparent,
                    titleContentColor = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                )
            )

            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                item {
                    GlassCard(
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        Column {
                            Text(
                                text = "任务配置",
                                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold),
                                color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                            )
                            Spacer(modifier = Modifier.height(12.dp))
                            OutlinedTextField(
                                value = concurrentTasks,
                                onValueChange = { concurrentTasks = it },
                                modifier = Modifier.fillMaxWidth(),
                                label = { Text("并发任务数") },
                                singleLine = true,
                                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                                shape = RoundedCornerShape(12.dp),
                                colors = OutlinedTextFieldDefaults.colors(
                                    focusedBorderColor = AppColors.primary,
                                    cursorColor = AppColors.primary
                                )
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            OutlinedTextField(
                                value = logRetentionDays,
                                onValueChange = { logRetentionDays = it },
                                modifier = Modifier.fillMaxWidth(),
                                label = { Text("日志保留天数") },
                                singleLine = true,
                                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                                shape = RoundedCornerShape(12.dp),
                                colors = OutlinedTextFieldDefaults.colors(
                                    focusedBorderColor = AppColors.primary,
                                    cursorColor = AppColors.primary
                                )
                            )
                        }
                    }
                }

                item {
                    GlassCard(
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        Column {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(
                                    Icons.Default.NetworkCheck,
                                    contentDescription = null,
                                    tint = AppColors.primary
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = "代理设置",
                                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold),
                                    color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                                )
                            }
                            Spacer(modifier = Modifier.height(12.dp))
                            OutlinedTextField(
                                value = proxyUrl,
                                onValueChange = { proxyUrl = it },
                                modifier = Modifier.fillMaxWidth(),
                                label = { Text("代理地址") },
                                placeholder = { Text("http://proxy:port") },
                                singleLine = true,
                                shape = RoundedCornerShape(12.dp),
                                colors = OutlinedTextFieldDefaults.colors(
                                    focusedBorderColor = AppColors.primary,
                                    cursorColor = AppColors.primary
                                )
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            OutlinedTextField(
                                value = proxyUsername,
                                onValueChange = { proxyUsername = it },
                                modifier = Modifier.fillMaxWidth(),
                                label = { Text("用户名") },
                                singleLine = true,
                                shape = RoundedCornerShape(12.dp),
                                colors = OutlinedTextFieldDefaults.colors(
                                    focusedBorderColor = AppColors.primary,
                                    cursorColor = AppColors.primary
                                )
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            OutlinedTextField(
                                value = proxyPassword,
                                onValueChange = { proxyPassword = it },
                                modifier = Modifier.fillMaxWidth(),
                                label = { Text("密码") },
                                singleLine = true,
                                visualTransformation = PasswordVisualTransformation(),
                                shape = RoundedCornerShape(12.dp),
                                colors = OutlinedTextFieldDefaults.colors(
                                    focusedBorderColor = AppColors.primary,
                                    cursorColor = AppColors.primary
                                )
                            )
                        }
                    }
                }

                item {
                    GlassCard(
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        Column {
                            Text(
                                text = "Docker 镜像加速",
                                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold),
                                color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                            )
                            Spacer(modifier = Modifier.height(12.dp))
                            OutlinedTextField(
                                value = dockerMirror,
                                onValueChange = { dockerMirror = it },
                                modifier = Modifier.fillMaxWidth(),
                                label = { Text("镜像加速地址") },
                                placeholder = { Text("https://mirror.example.com") },
                                singleLine = true,
                                shape = RoundedCornerShape(12.dp),
                                colors = OutlinedTextFieldDefaults.colors(
                                    focusedBorderColor = AppColors.primary,
                                    cursorColor = AppColors.primary
                                )
                            )
                        }
                    }
                }

                item {
                    GlassCard(
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        Column {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(
                                    Icons.Default.Update,
                                    contentDescription = null,
                                    tint = AppColors.primary
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = "面板更新",
                                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold),
                                    color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                                )
                            }
                            Spacer(modifier = Modifier.height(12.dp))
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(
                                        text = "当前版本",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = if (isLight) AppColors.slate500 else AppColors.slate400
                                    )
                                    Text(
                                        text = state.currentVersion.ifBlank { "未知" },
                                        style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                                        color = AppColors.primary
                                    )
                                }
                                Button(
                                    onClick = { viewModel.checkUpdate() },
                                    enabled = !state.isLoading,
                                    colors = ButtonDefaults.buttonColors(containerColor = AppColors.primary),
                                    shape = RoundedCornerShape(12.dp)
                                ) {
                                    Icon(Icons.Default.Refresh, null, modifier = Modifier.padding(end = 4.dp))
                                    Text("检查更新")
                                }
                            }

                            if (state.updateInfo.isNotEmpty()) {
                                Spacer(modifier = Modifier.height(8.dp))
                                val latestVersion = state.updateInfo["version"] as? String ?: ""
                                if (latestVersion.isNotBlank()) {
                                    Text(
                                        text = "最新版本: $latestVersion",
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = AppColors.primary
                                    )
                                }
                            }
                        }
                    }
                }

                item {
                    Button(
                        onClick = {
                            viewModel.saveSettings(
                                mapOf(
                                    "concurrent_tasks" to (concurrentTasks.toIntOrNull() ?: 5),
                                    "log_retention_days" to (logRetentionDays.toIntOrNull() ?: 30),
                                    "proxy_url" to proxyUrl,
                                    "proxy_username" to proxyUsername,
                                    "proxy_password" to proxyPassword,
                                    "docker_mirror" to dockerMirror
                                )
                            )
                        },
                        modifier = Modifier.fillMaxWidth(),
                        enabled = !state.isSaving,
                        colors = ButtonDefaults.buttonColors(containerColor = AppColors.primary),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Icon(Icons.Default.Save, null, modifier = Modifier.padding(end = 8.dp))
                        Text(if (state.isSaving) "保存中..." else "保存设置")
                    }
                }

                item { Spacer(modifier = Modifier.height(16.dp)) }
            }
        }
    }
}
