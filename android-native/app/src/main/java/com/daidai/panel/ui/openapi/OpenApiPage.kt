package com.daidai.panel.ui.openapi

import androidx.compose.foundation.ExperimentalFoundationApi
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
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Api
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Key
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
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
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.daidai.panel.core.theme.AppColors
import com.daidai.panel.ui.components.GlassCard

@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun OpenApiPage(
    onBack: () -> Unit,
    viewModel: OpenApiViewModel = hiltViewModel()
) {
    val isLight = !isSystemInDarkTheme()
    val state by viewModel.state.collectAsState()
    var showCreateSheet by remember { mutableStateOf(false) }
    var showSecretDialog by remember { mutableStateOf(false) }
    var showDeleteDialog by remember { mutableStateOf<Map<String, Any>?>(null) }
    var showLogsSheet by remember { mutableStateOf<Int?>(null) }
    val snackbarHostState = remember { SnackbarHostState() }
    val clipboardManager = LocalClipboardManager.current

    LaunchedEffect(state.error) {
        state.error?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearError()
        }
    }

    LaunchedEffect(state.secret) {
        if (state.secret != null) {
            showSecretDialog = true
        }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { padding ->
        Column(modifier = Modifier.fillMaxSize().padding(padding)) {
            TopAppBar(
                title = {
                    Text(
                        "Open API",
                        style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold)
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "返回")
                    }
                },
                actions = {
                    IconButton(onClick = { viewModel.load() }) {
                        Icon(Icons.Default.Refresh, contentDescription = "刷新")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Transparent,
                    titleContentColor = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                )
            )

            if (state.apps.isEmpty() && !state.isLoading) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            Icons.Default.Api,
                            contentDescription = null,
                            modifier = Modifier.size(64.dp),
                            tint = AppColors.slate400
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            "暂无 API 应用",
                            style = MaterialTheme.typography.titleMedium,
                            color = AppColors.slate400
                        )
                    }
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(state.apps) { app ->
                        OpenApiAppCard(
                            app = app,
                            onToggleEnabled = {
                                val id = (app["id"] as? Number)?.toInt() ?: return@OpenApiAppCard
                                if (app["enabled"] as? Boolean == true) viewModel.disable(id)
                                else viewModel.enable(id)
                            },
                            onViewSecret = {
                                val id = (app["id"] as? Number)?.toInt() ?: return@OpenApiAppCard
                                viewModel.viewSecret(id)
                            },
                            onResetSecret = {
                                val id = (app["id"] as? Number)?.toInt() ?: return@OpenApiAppCard
                                viewModel.resetSecret(id)
                            },
                            onViewLogs = {
                                val id = (app["id"] as? Number)?.toInt() ?: return@OpenApiAppCard
                                showLogsSheet = id
                                viewModel.loadLogs(id)
                            },
                            onDelete = { showDeleteDialog = app }
                        )
                    }
                }
            }
        }
    }

    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.BottomEnd
    ) {
        FloatingActionButton(
            onClick = { showCreateSheet = true },
            modifier = Modifier.padding(16.dp),
            containerColor = AppColors.primary,
            contentColor = AppColors.white
        ) {
            Icon(Icons.Default.Add, contentDescription = "创建应用")
        }
    }

    if (showCreateSheet) {
        CreateAppSheet(
            onDismiss = { showCreateSheet = false },
            onConfirm = { name ->
                viewModel.create(name) { showCreateSheet = false }
            }
        )
    }

    if (showSecretDialog && state.secret != null) {
        AlertDialog(
            onDismissRequest = {
                showSecretDialog = false
                viewModel.clearSecret()
            },
            title = { Text("应用 Secret") },
            text = {
                Column {
                    Text("请妥善保管，Secret 只显示一次：")
                    Spacer(modifier = Modifier.height(8.dp))
                    GlassCard(
                        modifier = Modifier.fillMaxWidth(),
                        padding = PaddingValues(12.dp)
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                text = state.secret ?: "",
                                style = MaterialTheme.typography.bodySmall,
                                modifier = Modifier.weight(1f)
                            )
                            IconButton(onClick = {
                                clipboardManager.setText(AnnotatedString(state.secret ?: ""))
                            }) {
                                Icon(Icons.Default.ContentCopy, "复制", tint = AppColors.primary)
                            }
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = {
                    showSecretDialog = false
                    viewModel.clearSecret()
                }) {
                    Text("关闭")
                }
            }
        )
    }

    showDeleteDialog?.let { app ->
        AlertDialog(
            onDismissRequest = { showDeleteDialog = null },
            title = { Text("确认删除") },
            text = { Text("确定要删除应用「${app["name"]}」吗？") },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.delete((app["id"] as? Number)?.toInt() ?: 0)
                    showDeleteDialog = null
                }) {
                    Text("删除", color = AppColors.red500)
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = null }) {
                    Text("取消")
                }
            }
        )
    }

    showLogsSheet?.let { appId ->
        ModalBottomSheet(onDismissRequest = { showLogsSheet = null }) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                Text(
                    "调用日志",
                    style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold)
                )
                Spacer(modifier = Modifier.height(16.dp))

                if (state.logs.isEmpty()) {
                    Text("暂无调用记录", color = AppColors.slate400)
                } else {
                    LazyColumn {
                        items(state.logs) { log ->
                            GlassCard(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 4.dp),
                                padding = PaddingValues(12.dp)
                            ) {
                                Column {
                                    Text(
                                        text = log["path"] as? String ?: "",
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                                    )
                                    Row {
                                        Text(
                                            text = log["method"] as? String ?: "",
                                            style = MaterialTheme.typography.labelSmall,
                                            color = AppColors.primary
                                        )
                                        Spacer(modifier = Modifier.width(8.dp))
                                        Text(
                                            text = log["time"] as? String ?: "",
                                            style = MaterialTheme.typography.labelSmall,
                                            color = if (isLight) AppColors.slate400 else AppColors.slate500
                                        )
                                    }
                                }
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))
                Button(
                    onClick = { showLogsSheet = null },
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(containerColor = AppColors.primary),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Text("关闭")
                }
            }
        }
    }
}

@Composable
private fun OpenApiAppCard(
    app: Map<String, Any>,
    onToggleEnabled: () -> Unit,
    onViewSecret: () -> Unit,
    onResetSecret: () -> Unit,
    onViewLogs: () -> Unit,
    onDelete: () -> Unit
) {
    val isLight = !isSystemInDarkTheme()
    var showMenu by remember { mutableStateOf(false) }

    GlassCard(
        modifier = Modifier.fillMaxWidth(),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                Icons.Default.Api,
                contentDescription = null,
                tint = AppColors.primary,
                modifier = Modifier.size(24.dp)
            )
            Spacer(modifier = Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = app["name"] as? String ?: "",
                    style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.SemiBold),
                    color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    text = "创建于 ${app["created_at"] as? String ?: ""}",
                    style = MaterialTheme.typography.labelSmall,
                    color = if (isLight) AppColors.slate400 else AppColors.slate500
                )
            }

            Switch(
                checked = app["enabled"] as? Boolean ?: false,
                onCheckedChange = { onToggleEnabled() },
                colors = SwitchDefaults.colors(
                    checkedThumbColor = AppColors.white,
                    checkedTrackColor = AppColors.primary,
                    uncheckedThumbColor = if (isLight) AppColors.slate400 else AppColors.slate500,
                    uncheckedTrackColor = if (isLight) AppColors.slate200 else AppColors.slate700
                )
            )

            Box {
                IconButton(onClick = { showMenu = true }) {
                    Icon(
                        Icons.Default.MoreVert,
                        contentDescription = "更多",
                        tint = if (isLight) AppColors.slate400 else AppColors.slate500
                    )
                }
                DropdownMenu(
                    expanded = showMenu,
                    onDismissRequest = { showMenu = false }
                ) {
                    DropdownMenuItem(
                        text = { Text("查看 Secret") },
                        leadingIcon = { Icon(Icons.Default.Visibility, null) },
                        onClick = { showMenu = false; onViewSecret() }
                    )
                    DropdownMenuItem(
                        text = { Text("重置 Secret") },
                        leadingIcon = { Icon(Icons.Default.Refresh, null) },
                        onClick = { showMenu = false; onResetSecret() }
                    )
                    DropdownMenuItem(
                        text = { Text("调用日志") },
                        leadingIcon = { Icon(Icons.Default.History, null) },
                        onClick = { showMenu = false; onViewLogs() }
                    )
                    DropdownMenuItem(
                        text = { Text("删除", color = AppColors.red500) },
                        leadingIcon = { Icon(Icons.Default.Delete, null, tint = AppColors.red500) },
                        onClick = { showMenu = false; onDelete() }
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun CreateAppSheet(
    onDismiss: () -> Unit,
    onConfirm: (String) -> Unit
) {
    var appName by remember { mutableStateOf("") }

    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Text(
                "创建 API 应用",
                style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold)
            )
            Spacer(modifier = Modifier.height(16.dp))

            OutlinedTextField(
                value = appName,
                onValueChange = { appName = it },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("应用名称") },
                singleLine = true,
                shape = RoundedCornerShape(12.dp)
            )
            Spacer(modifier = Modifier.height(16.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.End
            ) {
                TextButton(onClick = onDismiss) {
                    Text("取消")
                }
                Spacer(modifier = Modifier.width(8.dp))
                Button(
                    onClick = { onConfirm(appName) },
                    enabled = appName.isNotBlank(),
                    colors = ButtonDefaults.buttonColors(containerColor = AppColors.primary),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Text("创建")
                }
            }
            Spacer(modifier = Modifier.height(16.dp))
        }
    }
}
