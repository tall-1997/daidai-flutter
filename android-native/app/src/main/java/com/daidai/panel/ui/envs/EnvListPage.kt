package com.daidai.panel.ui.envs

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
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.PushPin
import androidx.compose.material.icons.filled.SelectAll
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.AssistChip
import androidx.compose.material3.AssistChipDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
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
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.daidai.panel.core.theme.AppColors
import com.daidai.panel.data.model.EnvVar
import com.daidai.panel.ui.components.GlassCard
import com.daidai.panel.ui.components.SearchBar

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class, ExperimentalFoundationApi::class)
@Composable
fun EnvListPage(
    contentPadding: PaddingValues,
    glassMode: Boolean,
    onNavigate: (String) -> Unit,
    viewModel: EnvViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()
    val isLight = !isSystemInDarkTheme()
    val snackbarHostState = remember { SnackbarHostState() }
    var deleteTarget by remember { mutableStateOf<EnvVar?>(null) }
    var showFilters by remember { mutableStateOf(false) }
    val clipboardManager = LocalClipboardManager.current

    Scaffold(
        modifier = Modifier.padding(contentPadding),
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            if (state.isBatchMode) {
                TopAppBar(
                    title = { Text("已选 ${state.selectedIds.size} 项") },
                    navigationIcon = {
                        IconButton(onClick = { viewModel.toggleBatchMode() }) {
                            Icon(Icons.Default.Close, contentDescription = "退出")
                        }
                    },
                    actions = {
                        IconButton(onClick = { viewModel.selectAll() }) {
                            Icon(Icons.Default.SelectAll, contentDescription = "全选")
                        }
                        IconButton(onClick = { viewModel.batchEnable() }) {
                            Icon(Icons.Default.CheckCircle, contentDescription = "批量启用", tint = AppColors.primary)
                        }
                        IconButton(onClick = { viewModel.batchDisable() }) {
                            Icon(Icons.Default.VisibilityOff, contentDescription = "批量禁用", tint = AppColors.amber500)
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
        },
        floatingActionButton = {
            if (!state.isBatchMode) {
                FloatingActionButton(
                    onClick = { onNavigate("envForm") },
                    containerColor = AppColors.primary
                ) {
                    Icon(Icons.Default.Add, contentDescription = "新建变量", tint = AppColors.white)
                }
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
            // Search
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
                        placeholder = "搜索变量..."
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    IconButton(onClick = { showFilters = !showFilters }) {
                        Icon(
                            Icons.Default.FilterList,
                            contentDescription = "筛选",
                            tint = if (showFilters) AppColors.primary else AppColors.slate400
                        )
                    }
                }
            }

            // Group filter
            item {
                AnimatedVisibility(visible = showFilters && state.groups.isNotEmpty()) {
                    FlowRow(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        state.groups.forEach { group ->
                            AssistChip(
                                onClick = { viewModel.updateSelectedGroup(group) },
                                label = { Text(group, style = MaterialTheme.typography.labelSmall) },
                                shape = RoundedCornerShape(20.dp),
                                colors = AssistChipDefaults.assistChipColors(
                                    containerColor = if (state.selectedGroup == group)
                                        AppColors.primary.copy(alpha = 0.15f)
                                    else MaterialTheme.colorScheme.surfaceVariant,
                                    labelColor = if (state.selectedGroup == group)
                                        AppColors.primary
                                    else if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                                )
                            )
                        }
                    }
                }
            }

            // Loading
            if (state.isLoading && state.envs.isEmpty()) {
                item {
                    Box(
                        modifier = Modifier.fillMaxWidth().height(200.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator(color = AppColors.primary)
                    }
                }
            }

            // Env list
            items(state.filteredEnvs, key = { it.id }) { env ->
                EnvCard(
                    env = env,
                    glassMode = glassMode,
                    isBatchMode = state.isBatchMode,
                    isSelected = state.selectedIds.contains(env.id),
                    onClick = {
                        if (state.isBatchMode) {
                            viewModel.toggleSelection(env.id)
                        } else {
                            onNavigate("envForm?envId=${env.id}")
                        }
                    },
                    onLongClick = {
                        if (!state.isBatchMode) {
                            viewModel.toggleBatchMode()
                            viewModel.toggleSelection(env.id)
                        }
                    },
                    onToggle = {
                        if (env.enabled) viewModel.disableEnv(env.id)
                        else viewModel.enableEnv(env.id)
                    },
                    onCopy = {
                        clipboardManager.setText(AnnotatedString(env.value))
                    },
                    onPin = {
                        if (env.isPinned) viewModel.cancelTop(env.id)
                        else viewModel.moveTop(env.id)
                    },
                    onDelete = { deleteTarget = env }
                )
            }

            // Empty
            if (!state.isLoading && state.filteredEnvs.isEmpty()) {
                item {
                    Box(
                        modifier = Modifier.fillMaxWidth().height(200.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                if (state.envs.isEmpty()) "暂无变量" else "无匹配结果",
                                style = MaterialTheme.typography.bodyLarge,
                                color = AppColors.slate500
                            )
                            if (state.envs.isEmpty()) {
                                Spacer(modifier = Modifier.height(8.dp))
                                Text(
                                    "点击右下角按钮创建变量",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = AppColors.slate400
                                )
                            }
                        }
                    }
                }
            }

            item { Spacer(modifier = Modifier.height(80.dp)) }
        }
    }

    deleteTarget?.let { env ->
        AlertDialog(
            onDismissRequest = { deleteTarget = null },
            title = { Text("确认删除") },
            text = { Text("确定要删除变量 \"${env.name}\" 吗？") },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.deleteEnv(env.id)
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
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun EnvCard(
    env: EnvVar,
    glassMode: Boolean,
    isBatchMode: Boolean,
    isSelected: Boolean,
    onClick: () -> Unit,
    onLongClick: () -> Unit,
    onToggle: () -> Unit,
    onCopy: () -> Unit,
    onPin: () -> Unit,
    onDelete: () -> Unit
) {
    val isLight = !isSystemInDarkTheme()
    var showValue by remember { mutableStateOf(false) }

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
                    if (env.isPinned) {
                        Icon(
                            Icons.Default.PushPin,
                            contentDescription = "已置顶",
                            tint = AppColors.amber500,
                            modifier = Modifier.size(14.dp)
                        )
                    }
                    Text(
                        text = env.name,
                        style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.SemiBold),
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                    )
                    if (env.groups.isNotEmpty()) {
                        env.groups.take(2).forEach { group ->
                            androidx.compose.material3.Surface(
                                shape = RoundedCornerShape(4.dp),
                                color = AppColors.blue500.copy(alpha = 0.08f)
                            ) {
                                Text(
                                    text = group,
                                    style = MaterialTheme.typography.labelSmall,
                                    color = AppColors.blue500,
                                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(4.dp))

                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = if (showValue) env.value else maskValue(env.value),
                        style = MaterialTheme.typography.bodySmall,
                        color = if (isLight) AppColors.slate500 else AppColors.slate400,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f, fill = false)
                    )
                    IconButton(
                        onClick = { showValue = !showValue },
                        modifier = Modifier.size(28.dp)
                    ) {
                        Icon(
                            if (showValue) Icons.Default.Visibility else Icons.Default.VisibilityOff,
                            contentDescription = null,
                            tint = AppColors.slate400,
                            modifier = Modifier.size(16.dp)
                        )
                    }
                }

                if (!env.remarks.isNullOrEmpty()) {
                    Text(
                        text = env.remarks ?: "",
                        style = MaterialTheme.typography.labelSmall,
                        color = if (isLight) AppColors.slate400 else AppColors.slate500,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
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
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Switch(
                        checked = env.enabled,
                        onCheckedChange = { onToggle() },
                        modifier = Modifier.height(24.dp),
                        colors = SwitchDefaults.colors(
                            checkedThumbColor = AppColors.primary,
                            checkedTrackColor = AppColors.primary.copy(alpha = 0.3f)
                        )
                    )
                    Row {
                        IconButton(onClick = onCopy, modifier = Modifier.size(28.dp)) {
                            Icon(
                                Icons.Default.ContentCopy,
                                contentDescription = "复制",
                                tint = AppColors.slate400,
                                modifier = Modifier.size(16.dp)
                            )
                        }
                        IconButton(onClick = onPin, modifier = Modifier.size(28.dp)) {
                            Icon(
                                Icons.Default.PushPin,
                                contentDescription = if (env.isPinned) "取消置顶" else "置顶",
                                tint = if (env.isPinned) AppColors.amber500 else AppColors.slate400,
                                modifier = Modifier.size(16.dp)
                            )
                        }
                        IconButton(onClick = onDelete, modifier = Modifier.size(28.dp)) {
                            Icon(
                                Icons.Default.Delete,
                                contentDescription = "删除",
                                tint = AppColors.red500.copy(alpha = 0.7f),
                                modifier = Modifier.size(16.dp)
                            )
                        }
                    }
                }
            }
        }
    }
}

private fun maskValue(value: String): String {
    return when {
        value.length <= 6 -> "******"
        else -> value.take(3) + "***" + value.takeLast(3)
    }
}
