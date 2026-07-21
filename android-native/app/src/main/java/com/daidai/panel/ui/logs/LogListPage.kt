package com.daidai.panel.ui.logs

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
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
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.CleaningServices
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.SelectAll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.AssistChip
import androidx.compose.material3.AssistChipDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.daidai.panel.core.theme.AppColors
import com.daidai.panel.data.model.TaskLog
import com.daidai.panel.ui.components.BadgeStatus
import com.daidai.panel.ui.components.GlassCard
import com.daidai.panel.ui.components.SearchBar
import com.daidai.panel.ui.components.StatusBadge

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class, ExperimentalFoundationApi::class)
@Composable
fun LogListPage(
    contentPadding: PaddingValues,
    glassMode: Boolean,
    onNavigate: (String) -> Unit,
    viewModel: LogViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()
    val isLight = !isSystemInDarkTheme()
    val snackbarHostState = remember { SnackbarHostState() }
    var deleteTarget by remember { mutableStateOf<TaskLog?>(null) }
    var showCleanDialog by remember { mutableStateOf(false) }
    var showFilters by remember { mutableStateOf(false) }

    Scaffold(
        modifier = Modifier.padding(contentPadding),
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            if (state.isBatchMode) {
                TopAppBar(
                    title = { Text("已选 ${state.selectedIds.size} 项") },
                    navigationIcon = {
                        IconButton(onClick = { viewModel.toggleBatchMode() }) {
                            Icon(Icons.Default.Close, contentDescription = "退出批量模式")
                        }
                    },
                    actions = {
                        IconButton(onClick = { viewModel.selectAll() }) {
                            Icon(Icons.Default.SelectAll, contentDescription = "全选")
                        }
                        IconButton(onClick = { viewModel.batchDelete() }) {
                            Icon(Icons.Default.Delete, contentDescription = "批量删除", tint = AppColors.red500)
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = if (isLight) AppColors.primaryContainer else AppColors.primaryDark
                    )
                )
            }
        }
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            // Search + clean button
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    SearchBar(
                        query = state.keyword,
                        onQueryChange = { viewModel.updateKeyword(it) },
                        modifier = Modifier.weight(1f),
                        glassMode = glassMode,
                        placeholder = "搜索日志..."
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    IconButton(onClick = { showFilters = !showFilters }) {
                        Icon(
                            Icons.Default.FilterList,
                            contentDescription = "筛选",
                            tint = if (showFilters) AppColors.primary else AppColors.slate400
                        )
                    }
                    IconButton(onClick = { showCleanDialog = true }) {
                        Icon(
                            Icons.Default.CleaningServices,
                            contentDescription = "清理日志",
                            tint = AppColors.red500
                        )
                    }
                }
            }

            // Status filters
            item {
                AnimatedVisibility(visible = showFilters) {
                    FlowRow(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        val filters = listOf(
                            -1 to "全部",
                            0 to "成功",
                            1 to "失败",
                            2 to "运行中",
                            3 to "超时"
                        )
                        filters.forEach { (status, label) ->
                            AssistChip(
                                onClick = { viewModel.updateStatusFilter(status) },
                                label = { Text(label, style = MaterialTheme.typography.labelSmall) },
                                shape = RoundedCornerShape(20.dp),
                                colors = AssistChipDefaults.assistChipColors(
                                    containerColor = if (state.statusFilter == status)
                                        AppColors.primary.copy(alpha = 0.15f)
                                    else MaterialTheme.colorScheme.surfaceVariant,
                                    labelColor = if (state.statusFilter == status)
                                        AppColors.primary
                                    else if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                                )
                            )
                        }
                    }
                }
            }

            // Loading
            if (state.isLoading && state.logs.isEmpty()) {
                item {
                    Box(
                        modifier = Modifier.fillMaxWidth().height(200.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator(color = AppColors.primary)
                    }
                }
            }

            // Log list
            items(state.filteredLogs, key = { it.id }) { log ->
                LogCard(
                    log = log,
                    glassMode = glassMode,
                    isBatchMode = state.isBatchMode,
                    isSelected = state.selectedIds.contains(log.id),
                    onClick = {
                        if (state.isBatchMode) {
                            viewModel.toggleSelection(log.id)
                        } else {
                            onNavigate("logStream/${log.id}")
                        }
                    },
                    onLongClick = {
                        if (!state.isBatchMode) {
                            viewModel.toggleBatchMode()
                            viewModel.toggleSelection(log.id)
                        }
                    },
                    onDelete = { deleteTarget = log }
                )
            }

            // Empty
            if (!state.isLoading && state.filteredLogs.isEmpty()) {
                item {
                    Box(
                        modifier = Modifier.fillMaxWidth().height(200.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            if (state.logs.isEmpty()) "暂无日志" else "无匹配结果",
                            style = MaterialTheme.typography.bodyLarge,
                            color = AppColors.slate500
                        )
                    }
                }
            }

            item { Spacer(modifier = Modifier.height(16.dp)) }
        }
    }

    deleteTarget?.let { log ->
        AlertDialog(
            onDismissRequest = { deleteTarget = null },
            title = { Text("确认删除") },
            text = { Text("确定要删除该日志记录吗？") },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.deleteLog(log.id)
                    deleteTarget = null
                }) {
                    Text("删除", color = AppColors.red500)
                }
            },
            dismissButton = {
                TextButton(onClick = { deleteTarget = null }) { Text("取消") }
            }
        )
    }

    if (showCleanDialog) {
        AlertDialog(
            onDismissRequest = { showCleanDialog = false },
            title = { Text("清理全部日志") },
            text = { Text("确定要清理所有日志吗？此操作不可恢复。") },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.cleanAll()
                    showCleanDialog = false
                }) {
                    Text("清理", color = AppColors.red500)
                }
            },
            dismissButton = {
                TextButton(onClick = { showCleanDialog = false }) { Text("取消") }
            }
        )
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun LogCard(
    log: TaskLog,
    glassMode: Boolean,
    isBatchMode: Boolean,
    isSelected: Boolean,
    onClick: () -> Unit,
    onLongClick: () -> Unit,
    onDelete: () -> Unit
) {
    val isLight = !isSystemInDarkTheme()
    val badgeStatus = when {
        log.isRunning -> BadgeStatus.RUNNING
        log.isSuccess -> BadgeStatus.SUCCESS
        log.isFailed -> BadgeStatus.FAILED
        log.status == 3 -> BadgeStatus.FAILED
        else -> BadgeStatus.DISABLED
    }

    GlassCard(
        modifier = Modifier
            .fillMaxWidth()
            .combinedClickable(onClick = onClick, onLongClick = onLongClick),
        glassMode = glassMode,
        padding = PaddingValues(16.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = log.taskName.ifEmpty { "任务#${log.taskId}" },
                        style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.SemiBold),
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f, fill = false),
                        color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                    )
                    StatusBadge(status = badgeStatus)
                }

                Spacer(modifier = Modifier.height(4.dp))

                Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                    if (log.durationText.isNotEmpty()) {
                        Text(
                            text = log.durationText,
                            style = MaterialTheme.typography.bodySmall,
                            color = if (isLight) AppColors.slate500 else AppColors.slate400
                        )
                    }
                    if (log.startedAt.isNotEmpty()) {
                        Text(
                            text = log.startedAt,
                            style = MaterialTheme.typography.bodySmall,
                            color = if (isLight) AppColors.slate400 else AppColors.slate500
                        )
                    }
                }
            }

            if (isBatchMode) {
                if (isSelected) {
                    Icon(
                        Icons.Default.CheckCircle,
                        contentDescription = "已选",
                        tint = AppColors.primary,
                        modifier = Modifier.size(24.dp)
                    )
                }
            } else {
                IconButton(onClick = onDelete, modifier = Modifier.size(36.dp)) {
                    Icon(
                        Icons.Default.Delete,
                        contentDescription = "删除",
                        tint = AppColors.red500.copy(alpha = 0.7f),
                        modifier = Modifier.size(18.dp)
                    )
                }
            }
        }
    }
}
