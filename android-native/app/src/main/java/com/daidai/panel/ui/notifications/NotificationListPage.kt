package com.daidai.panel.ui.notifications

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
import androidx.compose.material.icons.filled.AlternateEmail
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.MailOutline
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Send
import androidx.compose.material.icons.filled.SmartToy
import androidx.compose.material.icons.filled.Webhook
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
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.daidai.panel.core.theme.AppColors
import com.daidai.panel.data.model.NotifyChannel
import com.daidai.panel.ui.components.GlassCard
import com.daidai.panel.ui.components.StatusBadge
import com.daidai.panel.ui.components.BadgeStatus

@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun NotificationListPage(
    onBack: () -> Unit,
    viewModel: NotificationViewModel = hiltViewModel()
) {
    val isLight = !isSystemInDarkTheme()
    val state by viewModel.state.collectAsState()
    var showAddSheet by remember { mutableStateOf(false) }
    var showDeleteDialog by remember { mutableStateOf<NotifyChannel?>(null) }
    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(state.testResult) {
        state.testResult?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearTestResult()
        }
    }

    LaunchedEffect(state.error) {
        state.error?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearError()
        }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { padding ->
        Column(modifier = Modifier.fillMaxSize().padding(padding)) {
            TopAppBar(
                title = {
                    Text(
                        "通知管理",
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

            if (state.channels.isEmpty() && !state.isLoading) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            Icons.Default.Notifications,
                            contentDescription = null,
                            modifier = Modifier.size(64.dp),
                            tint = AppColors.slate400
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            "暂无通知渠道",
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
                    items(state.channels, key = { it.id }) { channel ->
                        NotificationChannelCard(
                            channel = channel,
                            onTest = { viewModel.test(channel.id) },
                            onToggleEnabled = {
                                if (channel.enabled) viewModel.disable(channel.id)
                                else viewModel.enable(channel.id)
                            },
                            onDelete = { showDeleteDialog = channel }
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
            Icon(Icons.Default.Add, contentDescription = "添加渠道")
        }
    }

    if (showAddSheet) {
        AddChannelSheet(
            types = state.types,
            onDismiss = { showAddSheet = false },
            onConfirm = { name, type, config ->
                viewModel.create(
                    mapOf("name" to name, "type" to type, "config" to config)
                ) { showAddSheet = false }
            }
        )
    }

    showDeleteDialog?.let { channel ->
        AlertDialog(
            onDismissRequest = { showDeleteDialog = null },
            title = { Text("确认删除") },
            text = { Text("确定要删除通知渠道「${channel.name}」吗？") },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.delete(channel.id)
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
private fun NotificationChannelCard(
    channel: NotifyChannel,
    onTest: () -> Unit,
    onToggleEnabled: () -> Unit,
    onDelete: () -> Unit
) {
    val isLight = !isSystemInDarkTheme()
    var showMenu by remember { mutableStateOf(false) }

    GlassCard(
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    getChannelIcon(channel.type),
                    contentDescription = null,
                    tint = AppColors.primary,
                    modifier = Modifier.size(24.dp)
                )
                Spacer(modifier = Modifier.width(12.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = channel.name,
                        style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.SemiBold),
                        color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                    )
                    Text(
                        text = channel.type.uppercase(),
                        style = MaterialTheme.typography.labelSmall,
                        color = AppColors.primary
                    )
                }

                Switch(
                    checked = channel.enabled,
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
                            text = { Text("测试发送") },
                            leadingIcon = { Icon(Icons.Default.Send, null) },
                            onClick = { showMenu = false; onTest() }
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
}

private fun getChannelIcon(type: String): ImageVector {
    return when (type.lowercase()) {
        "webhook" -> Icons.Default.Webhook
        "email" -> Icons.Default.Email
        "telegram" -> Icons.Default.Send
        "dingtalk" -> Icons.Default.SmartToy
        "wechat" -> Icons.Default.WeChat
        "bark" -> Icons.Default.NotificationsActive
        "pushplus" -> Icons.Default.MailOutline
        "serverchan" -> Icons.Default.AlternateEmail
        else -> Icons.Default.Notifications
    }
}

private val Icons.Filled.WeChat: ImageVector
    get() = Icons.Filled.Notifications

@OptIn(ExperimentalMaterial3Api::class, androidx.compose.foundation.layout.ExperimentalLayoutApi::class)
@Composable
private fun AddChannelSheet(
    types: List<Map<String, Any>>,
    onDismiss: () -> Unit,
    onConfirm: (name: String, type: String, config: Map<String, String>) -> Unit
) {
    var name by remember { mutableStateOf("") }
    var selectedType by remember { mutableStateOf("") }
    var webhookUrl by remember { mutableStateOf("") }

    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Text(
                "添加通知渠道",
                style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold)
            )
            Spacer(modifier = Modifier.height(16.dp))

            OutlinedTextField(
                value = name,
                onValueChange = { name = it },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("渠道名称") },
                singleLine = true,
                shape = RoundedCornerShape(12.dp)
            )
            Spacer(modifier = Modifier.height(12.dp))

            Text(
                "渠道类型",
                style = MaterialTheme.typography.titleSmall,
                color = if (androidx.compose.foundation.isSystemInDarkTheme()) AppColors.slate400 else AppColors.slate500
            )
            Spacer(modifier = Modifier.height(8.dp))

            val channelTypes = listOf(
                "webhook", "email", "telegram", "dingtalk", "wechat", "bark", "pushplus", "serverchan"
            )
            androidx.compose.foundation.layout.FlowRow(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                channelTypes.forEach { type ->
                    androidx.compose.material3.FilterChip(
                        selected = selectedType == type,
                        onClick = { selectedType = type },
                        label = { Text(type) }
                    )
                }
            }

            if (selectedType == "webhook") {
                Spacer(modifier = Modifier.height(12.dp))
                OutlinedTextField(
                    value = webhookUrl,
                    onValueChange = { webhookUrl = it },
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text("Webhook URL") },
                    singleLine = true,
                    shape = RoundedCornerShape(12.dp)
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
                    onClick = {
                        val config = if (selectedType == "webhook") mapOf("url" to webhookUrl)
                        else emptyMap()
                        onConfirm(name, selectedType, config)
                    },
                    enabled = name.isNotBlank() && selectedType.isNotBlank(),
                    colors = ButtonDefaults.buttonColors(containerColor = AppColors.primary),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Text("添加")
                }
            }
            Spacer(modifier = Modifier.height(16.dp))
        }
    }
}
