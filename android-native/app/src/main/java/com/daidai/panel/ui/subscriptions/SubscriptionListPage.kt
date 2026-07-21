package com.daidai.panel.ui.subscriptions

import androidx.compose.foundation.ExperimentalFoundationApi
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
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.CloudDownload
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Error
import androidx.compose.material3.FilterChip
import androidx.compose.material.icons.filled.Code
import androidx.compose.material.icons.filled.InsertDriveFile
import androidx.compose.material.icons.filled.Link
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.SelectAll
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
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.daidai.panel.core.theme.AppColors
import com.daidai.panel.data.model.Subscription
import com.daidai.panel.ui.components.GlassCard
import com.daidai.panel.ui.components.StatusBadge
import com.daidai.panel.ui.components.BadgeStatus

@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun SubscriptionListPage(
    onBack: () -> Unit,
    viewModel: SubscriptionViewModel = hiltViewModel()
) {
    val isLight = !isSystemInDarkTheme()
    val state by viewModel.state.collectAsState()
    var showAddSheet by remember { mutableStateOf(false) }
    var showDeleteDialog by remember { mutableStateOf<Subscription?>(null) }

    Column(modifier = Modifier.fillMaxSize()) {
        TopAppBar(
            title = {
                Text(
                    "订阅管理",
                    style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold)
                )
            },
            navigationIcon = {
                IconButton(onClick = onBack) {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "返回")
                }
            },
            actions = {
                if (state.isBatchMode) {
                    IconButton(onClick = { viewModel.toggleBatchMode() }) {
                        Text("取消", color = AppColors.primary)
                    }
                    IconButton(onClick = { viewModel.batchDelete() }) {
                        Icon(Icons.Default.Delete, contentDescription = "批量删除", tint = AppColors.red500)
                    }
                } else {
                    IconButton(onClick = { viewModel.toggleBatchMode() }) {
                        Icon(Icons.Default.SelectAll, contentDescription = "多选")
                    }
                    IconButton(onClick = { viewModel.load() }) {
                        Icon(Icons.Default.Refresh, contentDescription = "刷新")
                    }
                }
            },
            colors = TopAppBarDefaults.topAppBarColors(
                containerColor = Color.Transparent,
                titleContentColor = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
            )
        )

        PullToRefreshBox(
            isRefreshing = state.isLoading,
            onRefresh = { viewModel.load() },
            modifier = Modifier.fillMaxSize()
        ) {
            if (state.subscriptions.isEmpty() && !state.isLoading) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            Icons.Default.CloudDownload,
                            contentDescription = null,
                            modifier = Modifier.size(64.dp),
                            tint = AppColors.slate400
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            "暂无订阅",
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
                    items(state.subscriptions, key = { it.id }) { sub ->
                        SubscriptionCard(
                            subscription = sub,
                            isBatchMode = state.isBatchMode,
                            isSelected = state.selectedIds.contains(sub.id),
                            onToggleSelection = { viewModel.toggleSelection(sub.id) },
                            onPull = { viewModel.pull(sub.id) },
                            onToggleEnabled = {
                                if (sub.enabled) viewModel.disable(sub.id)
                                else viewModel.enable(sub.id)
                            },
                            onDelete = { showDeleteDialog = sub }
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
            onClick = { showAddSheet = true },
            modifier = Modifier.padding(16.dp),
            containerColor = AppColors.primary,
            contentColor = AppColors.white
        ) {
            Icon(Icons.Default.Add, contentDescription = "添加订阅")
        }
    }

    if (showAddSheet) {
        AddSubscriptionSheet(
            onDismiss = { showAddSheet = false },
            onConfirm = { name, url, type ->
                viewModel.create(
                    mapOf("name" to name, "url" to url, "type" to type)
                ) { showAddSheet = false }
            }
        )
    }

    showDeleteDialog?.let { sub ->
        AlertDialog(
            onDismissRequest = { showDeleteDialog = null },
            title = { Text("确认删除") },
            text = { Text("确定要删除订阅「${sub.name}」吗？") },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.delete(sub.id)
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
}

@Composable
private fun SubscriptionCard(
    subscription: Subscription,
    isBatchMode: Boolean,
    isSelected: Boolean,
    onToggleSelection: () -> Unit,
    onPull: () -> Unit,
    onToggleEnabled: () -> Unit,
    onDelete: () -> Unit
) {
    val isLight = !isSystemInDarkTheme()
    var showMenu by remember { mutableStateOf(false) }

    GlassCard(
        modifier = Modifier.fillMaxWidth(),
        onClick = if (isBatchMode) onToggleSelection else null
    ) {
        Column {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (isBatchMode) {
                    Box(
                        modifier = Modifier
                            .size(24.dp)
                            .background(
                                if (isSelected) AppColors.primary else Color.Transparent,
                                RoundedCornerShape(4.dp)
                            )
                            .padding(2.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        if (isSelected) {
                            Icon(
                                Icons.Default.CheckCircle,
                                contentDescription = null,
                                tint = AppColors.white,
                                modifier = Modifier.size(18.dp)
                            )
                        }
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                }

                Icon(
                    if (subscription.isGitRepo) Icons.Default.Code else Icons.Default.InsertDriveFile,
                    contentDescription = null,
                    tint = AppColors.primary,
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = subscription.name,
                        style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.SemiBold),
                        color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    Text(
                        text = subscription.typeLabel,
                        style = MaterialTheme.typography.labelSmall,
                        color = AppColors.primary
                    )
                }

                StatusBadge(
                    status = when (subscription.status) {
                        1 -> BadgeStatus.RUNNING
                        2 -> BadgeStatus.SUCCESS
                        3 -> BadgeStatus.FAILED
                        else -> if (subscription.enabled) BadgeStatus.SUCCESS else BadgeStatus.DISABLED
                    }
                )

                if (!isBatchMode) {
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
                                text = { Text("拉取") },
                                leadingIcon = { Icon(Icons.Default.Refresh, null) },
                                onClick = { showMenu = false; onPull() }
                            )
                            DropdownMenuItem(
                                text = { Text(if (subscription.enabled) "禁用" else "启用") },
                                leadingIcon = {
                                    Icon(
                                        if (subscription.enabled) Icons.Default.Pause else Icons.Default.PlayArrow,
                                        null
                                    )
                                },
                                onClick = { showMenu = false; onToggleEnabled() }
                            )
                            DropdownMenuItem(
                                text = { Text("删除", color = AppColors.red500) },
                                leadingIcon = {
                                    Icon(Icons.Default.Delete, null, tint = AppColors.red500)
                                },
                                onClick = { showMenu = false; onDelete() }
                            )
                        }
                    }
                }
            }

            if (subscription.url.isNotBlank()) {
                Spacer(modifier = Modifier.height(8.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Default.Link,
                        contentDescription = null,
                        tint = if (isLight) AppColors.slate400 else AppColors.slate500,
                        modifier = Modifier.size(14.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = subscription.url,
                        style = MaterialTheme.typography.bodySmall,
                        color = if (isLight) AppColors.slate400 else AppColors.slate500,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }

            if (subscription.lastPullAt.isNotBlank()) {
                Spacer(modifier = Modifier.height(4.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Default.Schedule,
                        contentDescription = null,
                        tint = if (isLight) AppColors.slate400 else AppColors.slate500,
                        modifier = Modifier.size(14.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "上次拉取: ${subscription.lastPullAt}",
                        style = MaterialTheme.typography.bodySmall,
                        color = if (isLight) AppColors.slate400 else AppColors.slate500
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AddSubscriptionSheet(
    onDismiss: () -> Unit,
    onConfirm: (name: String, url: String, type: Int) -> Unit
) {
    var name by remember { mutableStateOf("") }
    var url by remember { mutableStateOf("") }
    var type by remember { mutableStateOf(0) }

    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Text(
                "添加订阅",
                style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold)
            )
            Spacer(modifier = Modifier.height(16.dp))

            OutlinedTextField(
                value = name,
                onValueChange = { name = it },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("名称") },
                singleLine = true,
                shape = RoundedCornerShape(12.dp)
            )
            Spacer(modifier = Modifier.height(12.dp))

            OutlinedTextField(
                value = url,
                onValueChange = { url = it },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("URL") },
                singleLine = true,
                shape = RoundedCornerShape(12.dp)
            )
            Spacer(modifier = Modifier.height(16.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                FilterChip(
                    selected = type == 0,
                    onClick = { type = 0 },
                    label = { Text("Git 仓库") },
                    modifier = Modifier.weight(1f)
                )
                FilterChip(
                    selected = type == 1,
                    onClick = { type = 1 },
                    label = { Text("单文件") },
                    modifier = Modifier.weight(1f)
                )
            }
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
                    onClick = { onConfirm(name, url, type) },
                    enabled = name.isNotBlank() && url.isNotBlank(),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = AppColors.primary
                    ),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Text("添加")
                }
            }
            Spacer(modifier = Modifier.height(16.dp))
        }
    }
}
