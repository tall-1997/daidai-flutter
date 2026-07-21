package com.daidai.panel.ui.system

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
import androidx.compose.material.icons.filled.Backup
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.CloudDownload
import androidx.compose.material.icons.filled.CloudUpload
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Restore
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CheckboxDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.daidai.panel.core.theme.AppColors
import com.daidai.panel.ui.components.GlassCard

@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun BackupPage(
    onBack: () -> Unit,
    viewModel: SystemViewModel = hiltViewModel()
) {
    val isLight = !isSystemInDarkTheme()
    val state by viewModel.state.collectAsState()
    var showRestoreSheet by remember { mutableStateOf<String?>(null) }
    var showDeleteDialog by remember { mutableStateOf<String?>(null) }
    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(Unit) {
        viewModel.loadBackups()
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
                        "备份恢复",
                        style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold)
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "返回")
                    }
                },
                actions = {
                    IconButton(onClick = { viewModel.loadBackups() }) {
                        Icon(Icons.Default.Refresh, contentDescription = "刷新")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Transparent,
                    titleContentColor = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                )
            )

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Button(
                    onClick = { viewModel.createBackup() },
                    enabled = !state.isSaving,
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(containerColor = AppColors.primary),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Icon(Icons.Default.Add, null, modifier = Modifier.padding(end = 4.dp))
                    Text(if (state.isSaving) "创建中..." else "创建备份")
                }
                Button(
                    onClick = { },
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(containerColor = AppColors.blue500),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Icon(Icons.Default.CloudUpload, null, modifier = Modifier.padding(end = 4.dp))
                    Text("上传备份")
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            if (state.backups.isEmpty() && !state.isLoading) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            Icons.Default.Backup,
                            contentDescription = null,
                            modifier = Modifier.size(64.dp),
                            tint = AppColors.slate400
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            "暂无备份",
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
                    items(state.backups) { backup ->
                        BackupCard(
                            backup = backup,
                            isRestoring = state.isSaving,
                            onDownload = {
                                viewModel.downloadBackup(backup["name"] as? String ?: "")
                            },
                            onRestore = { showRestoreSheet = backup["name"] as? String },
                            onDelete = { showDeleteDialog = backup["name"] as? String }
                        )
                    }
                }
            }
        }
    }

    showRestoreSheet?.let { backupName ->
        RestoreSheet(
            backupName = backupName,
            isRestoring = state.isSaving,
            onDismiss = { showRestoreSheet = null },
            onConfirm = { options ->
                viewModel.restoreBackup(backupName, options)
                showRestoreSheet = null
            }
        )
    }

    showDeleteDialog?.let { name ->
        AlertDialog(
            onDismissRequest = { showDeleteDialog = null },
            title = { Text("确认删除") },
            text = { Text("确定要删除备份「$name」吗？") },
            confirmButton = {
                TextButton(onClick = { showDeleteDialog = null }) {
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
}

@Composable
private fun BackupCard(
    backup: Map<String, Any>,
    isRestoring: Boolean,
    onDownload: () -> Unit,
    onRestore: () -> Unit,
    onDelete: () -> Unit
) {
    val isLight = !isSystemInDarkTheme()

    GlassCard(
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    Icons.Default.Backup,
                    contentDescription = null,
                    tint = AppColors.primary,
                    modifier = Modifier.size(24.dp)
                )
                Spacer(modifier = Modifier.width(12.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = backup["name"] as? String ?: "",
                        style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.SemiBold),
                        color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                    )
                    Row {
                        Text(
                            text = backup["size"] as? String ?: "",
                            style = MaterialTheme.typography.bodySmall,
                            color = if (isLight) AppColors.slate500 else AppColors.slate400
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = backup["created_at"] as? String ?: "",
                            style = MaterialTheme.typography.bodySmall,
                            color = if (isLight) AppColors.slate400 else AppColors.slate500
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                IconButton(onClick = onDownload) {
                    Icon(
                        Icons.Default.CloudDownload,
                        "下载",
                        tint = AppColors.primary
                    )
                }
                IconButton(onClick = onRestore) {
                    Icon(
                        Icons.Default.Restore,
                        "恢复",
                        tint = AppColors.amber500
                    )
                }
                IconButton(onClick = onDelete) {
                    Icon(
                        Icons.Default.Delete,
                        "删除",
                        tint = AppColors.red500
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun RestoreSheet(
    backupName: String,
    isRestoring: Boolean,
    onDismiss: () -> Unit,
    onConfirm: (String) -> Unit
) {
    var restoreTasks by remember { mutableStateOf(true) }
    var restoreEnvs by remember { mutableStateOf(true) }
    var restoreScripts by remember { mutableStateOf(true) }
    var restoreConfig by remember { mutableStateOf(true) }

    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Text(
                "恢复备份",
                style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold)
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "从「$backupName」恢复",
                style = MaterialTheme.typography.bodyMedium,
                color = if (androidx.compose.foundation.isSystemInDarkTheme()) AppColors.slate400 else AppColors.slate500
            )
            Spacer(modifier = Modifier.height(16.dp))

            Text(
                "选择要恢复的内容：",
                style = MaterialTheme.typography.titleSmall,
                color = if (androidx.compose.foundation.isSystemInDarkTheme()) AppColors.slate400 else AppColors.slate500
            )
            Spacer(modifier = Modifier.height(8.dp))

            Row(verticalAlignment = Alignment.CenterVertically) {
                Checkbox(
                    checked = restoreTasks,
                    onCheckedChange = { restoreTasks = it },
                    colors = CheckboxDefaults.colors(checkedColor = AppColors.primary)
                )
                Text("任务")
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                Checkbox(
                    checked = restoreEnvs,
                    onCheckedChange = { restoreEnvs = it },
                    colors = CheckboxDefaults.colors(checkedColor = AppColors.primary)
                )
                Text("环境变量")
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                Checkbox(
                    checked = restoreScripts,
                    onCheckedChange = { restoreScripts = it },
                    colors = CheckboxDefaults.colors(checkedColor = AppColors.primary)
                )
                Text("脚本")
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                Checkbox(
                    checked = restoreConfig,
                    onCheckedChange = { restoreConfig = it },
                    colors = CheckboxDefaults.colors(checkedColor = AppColors.primary)
                )
                Text("配置")
            }

            Spacer(modifier = Modifier.height(16.dp))

            if (isRestoring) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center
                ) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        strokeWidth = 2.dp,
                        color = AppColors.primary
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("恢复中...")
                }
                Spacer(modifier = Modifier.height(16.dp))
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.End
            ) {
                TextButton(onClick = onDismiss) {
                    Text("取消")
                }
                Spacer(modifier = Modifier.width(8.dp))
                Button(
                    onClick = {
                        val options = buildList {
                            if (restoreTasks) add("tasks")
                            if (restoreEnvs) add("envs")
                            if (restoreScripts) add("scripts")
                            if (restoreConfig) add("config")
                        }.joinToString(",")
                        onConfirm(options)
                    },
                    enabled = !isRestoring && (restoreTasks || restoreEnvs || restoreScripts || restoreConfig),
                    colors = ButtonDefaults.buttonColors(containerColor = AppColors.primary),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Text("开始恢复")
                }
            }
            Spacer(modifier = Modifier.height(16.dp))
        }
    }
}
