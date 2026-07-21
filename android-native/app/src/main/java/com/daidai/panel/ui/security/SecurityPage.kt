package com.daidai.panel.ui.security

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
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Block
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Computer
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Login
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Security
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.ScrollableTabRow
import androidx.compose.material3.Tab
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
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.daidai.panel.core.theme.AppColors
import com.daidai.panel.ui.components.GlassCard
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun SecurityPage(
    onBack: () -> Unit,
    viewModel: SecurityViewModel = hiltViewModel()
) {
    val isLight = !isSystemInDarkTheme()
    val state by viewModel.state.collectAsState()
    val tabs = listOf("登录日志", "会话管理", "IP 白名单", "2FA 设置", "审计日志")
    val pagerState = rememberPagerState(pageCount = { tabs.size })
    val coroutineScope = rememberCoroutineScope()

    LaunchedEffect(pagerState.currentPage) {
        viewModel.selectTab(pagerState.currentPage)
    }

    Column(modifier = Modifier.fillMaxSize()) {
        TopAppBar(
            title = {
                Text(
                    "安全管理",
                    style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold)
                )
            },
            navigationIcon = {
                IconButton(onClick = onBack) {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "返回")
                }
            },
            actions = {
                IconButton(onClick = { viewModel.selectTab(pagerState.currentPage) }) {
                    Icon(Icons.Default.Refresh, contentDescription = "刷新")
                }
            },
            colors = TopAppBarDefaults.topAppBarColors(
                containerColor = Color.Transparent,
                titleContentColor = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
            )
        )

        ScrollableTabRow(
            selectedTabIndex = pagerState.currentPage,
            containerColor = Color.Transparent,
            contentColor = AppColors.primary,
            edgePadding = 16.dp
        ) {
            tabs.forEachIndexed { index, title ->
                Tab(
                    selected = pagerState.currentPage == index,
                    onClick = { coroutineScope.launch { pagerState.animateScrollToPage(index) } },
                    text = {
                        Text(
                            title,
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = if (pagerState.currentPage == index) FontWeight.SemiBold else FontWeight.Normal
                        )
                    }
                )
            }
        }

        HorizontalPager(
            state = pagerState,
            modifier = Modifier.fillMaxSize()
        ) { page ->
            when (page) {
                0 -> LoginLogsTab(state)
                1 -> SessionsTab(state, viewModel)
                2 -> IpWhitelistTab(state, viewModel)
                3 -> TwoFaTab(state, viewModel)
                4 -> AuditLogsTab(state)
            }
        }
    }
}

@Composable
private fun LoginLogsTab(state: SecurityState) {
    val isLight = !isSystemInDarkTheme()

    if (state.loginLogs.isEmpty()) {
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Text("暂无登录日志", color = AppColors.slate400)
        }
    } else {
        LazyColumn(
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(state.loginLogs) { log ->
                GlassCard(
                    modifier = Modifier.fillMaxWidth(),
                    padding = PaddingValues(12.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            if (log["success"] as? Boolean == true) Icons.Default.CheckCircle else Icons.Default.Warning,
                            contentDescription = null,
                            tint = if (log["success"] as? Boolean == true) AppColors.primary else AppColors.red500,
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = log["ip"] as? String ?: "",
                                style = MaterialTheme.typography.bodyMedium,
                                color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                            )
                            Text(
                                text = log["time"] as? String ?: "",
                                style = MaterialTheme.typography.bodySmall,
                                color = if (isLight) AppColors.slate400 else AppColors.slate500
                            )
                        }
                        Text(
                            text = log["location"] as? String ?: "",
                            style = MaterialTheme.typography.bodySmall,
                            color = if (isLight) AppColors.slate500 else AppColors.slate400
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun SessionsTab(state: SecurityState, viewModel: SecurityViewModel) {
    val isLight = !isSystemInDarkTheme()
    var showKickOthersDialog by remember { mutableStateOf(false) }

    Column {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.End
        ) {
            TextButton(onClick = { showKickOthersDialog = true }) {
                Icon(Icons.Default.Block, null, modifier = Modifier.padding(end = 4.dp))
                Text("踢出其他会话")
            }
        }

        if (state.sessions.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text("暂无活跃会话", color = AppColors.slate400)
            }
        } else {
            LazyColumn(
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(state.sessions) { session ->
                    GlassCard(
                        modifier = Modifier.fillMaxWidth(),
                        padding = PaddingValues(12.dp)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                Icons.Default.Computer,
                                contentDescription = null,
                                tint = AppColors.primary,
                                modifier = Modifier.size(20.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = session["ip"] as? String ?: "",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                                )
                                Text(
                                    text = session["user_agent"] as? String ?: "",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = if (isLight) AppColors.slate400 else AppColors.slate500,
                                    maxLines = 1
                                )
                            }
                            if (session["is_current"] as? Boolean != true) {
                                IconButton(onClick = {
                                    viewModel.kickSession((session["id"] as? Number)?.toInt()?.toString() ?: session["id"] as? String ?: "")
                                }) {
                                    Icon(Icons.Default.Close, "踢出", tint = AppColors.red500)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    if (showKickOthersDialog) {
        AlertDialog(
            onDismissRequest = { showKickOthersDialog = false },
            title = { Text("确认操作") },
            text = { Text("确定要踢出所有其他会话吗？") },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.kickOtherSessions()
                    showKickOthersDialog = false
                }) {
                    Text("确认", color = AppColors.red500)
                }
            },
            dismissButton = {
                TextButton(onClick = { showKickOthersDialog = false }) {
                    Text("取消")
                }
            }
        )
    }
}

@Composable
private fun IpWhitelistTab(state: SecurityState, viewModel: SecurityViewModel) {
    val isLight = !isSystemInDarkTheme()
    var showAddDialog by remember { mutableStateOf(false) }

    Column {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.End
        ) {
            TextButton(onClick = { showAddDialog = true }) {
                Icon(Icons.Default.Add, null, modifier = Modifier.padding(end = 4.dp))
                Text("添加 IP")
            }
        }

        if (state.ipWhitelist.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text("暂无 IP 白名单", color = AppColors.slate400)
            }
        } else {
            LazyColumn(
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(state.ipWhitelist) { entry ->
                    GlassCard(
                        modifier = Modifier.fillMaxWidth(),
                        padding = PaddingValues(12.dp)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = entry["ip"] as? String ?: "",
                                    style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.SemiBold),
                                    color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                                )
                                Text(
                                    text = entry["remark"] as? String ?: "",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = if (isLight) AppColors.slate400 else AppColors.slate500
                                )
                            }
                            IconButton(onClick = {
                                viewModel.removeIpWhitelist((entry["id"] as? Number)?.toInt() ?: 0)
                            }) {
                                Icon(Icons.Default.Delete, "删除", tint = AppColors.red500)
                            }
                        }
                    }
                }
            }
        }
    }

    if (showAddDialog) {
        var ip by remember { mutableStateOf("") }
        var remark by remember { mutableStateOf("") }
        AlertDialog(
            onDismissRequest = { showAddDialog = false },
            title = { Text("添加 IP 白名单") },
            text = {
                Column {
                    OutlinedTextField(
                        value = ip,
                        onValueChange = { ip = it },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text("IP 地址") },
                        singleLine = true,
                        shape = RoundedCornerShape(12.dp)
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(
                        value = remark,
                        onValueChange = { remark = it },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text("备注") },
                        singleLine = true,
                        shape = RoundedCornerShape(12.dp)
                    )
                }
            },
            confirmButton = {
                TextButton(onClick = {
                    if (ip.isNotBlank()) {
                        viewModel.addIpWhitelist(ip, remark)
                        showAddDialog = false
                    }
                }) {
                    Text("添加", color = AppColors.primary)
                }
            },
            dismissButton = {
                TextButton(onClick = { showAddDialog = false }) {
                    Text("取消")
                }
            }
        )
    }
}

@Composable
private fun TwoFaTab(state: SecurityState, viewModel: SecurityViewModel) {
    val isLight = !isSystemInDarkTheme()
    val isEnabled = state.twoFaStatus["enabled"] as? Boolean ?: false
    var showSetupDialog by remember { mutableStateOf(false) }
    var showDisableDialog by remember { mutableStateOf(false) }
    var verifyCode by remember { mutableStateOf("") }

    Column(
        modifier = Modifier.padding(16.dp)
    ) {
        GlassCard(
            modifier = Modifier.fillMaxWidth(),
        ) {
            Column {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Default.Lock,
                        contentDescription = null,
                        tint = if (isEnabled) AppColors.primary else AppColors.slate400
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "两步验证",
                            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold),
                            color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                        )
                        Text(
                            text = if (isEnabled) "已启用" else "未启用",
                            style = MaterialTheme.typography.bodySmall,
                            color = if (isEnabled) AppColors.primary else AppColors.slate400
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                if (!isEnabled) {
                    Button(
                        onClick = {
                            viewModel.setup2Fa()
                            showSetupDialog = true
                        },
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.buttonColors(containerColor = AppColors.primary),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Text("启用两步验证")
                    }
                } else {
                    Button(
                        onClick = { showDisableDialog = true },
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.buttonColors(containerColor = AppColors.red500),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Text("禁用两步验证")
                    }
                }
            }
        }
    }

    if (showSetupDialog) {
        AlertDialog(
            onDismissRequest = { showSetupDialog = false },
            title = { Text("设置两步验证") },
            text = {
                Column {
                    if (state.twoFaSecret.isNotBlank()) {
                        Text("请使用验证器 App 扫描或手动输入以下密钥：")
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = state.twoFaSecret,
                            style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Bold),
                            color = AppColors.primary
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                    }
                    OutlinedTextField(
                        value = verifyCode,
                        onValueChange = { verifyCode = it },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text("验证码") },
                        singleLine = true,
                        shape = RoundedCornerShape(12.dp)
                    )
                }
            },
            confirmButton = {
                TextButton(onClick = {
                    if (verifyCode.isNotBlank()) {
                        viewModel.verify2Fa(verifyCode) { showSetupDialog = false }
                    }
                }) {
                    Text("验证", color = AppColors.primary)
                }
            },
            dismissButton = {
                TextButton(onClick = { showSetupDialog = false }) {
                    Text("取消")
                }
            }
        )
    }

    if (showDisableDialog) {
        AlertDialog(
            onDismissRequest = { showDisableDialog = false },
            title = { Text("禁用两步验证") },
            text = {
                Column {
                    Text("请输入验证码以禁用两步验证")
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(
                        value = verifyCode,
                        onValueChange = { verifyCode = it },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text("验证码") },
                        singleLine = true,
                        shape = RoundedCornerShape(12.dp)
                    )
                }
            },
            confirmButton = {
                TextButton(onClick = {
                    if (verifyCode.isNotBlank()) {
                        viewModel.disable2Fa(verifyCode) { showDisableDialog = false }
                    }
                }) {
                    Text("禁用", color = AppColors.red500)
                }
            },
            dismissButton = {
                TextButton(onClick = { showDisableDialog = false }) {
                    Text("取消")
                }
            }
        )
    }
}

@Composable
private fun AuditLogsTab(state: SecurityState) {
    val isLight = !isSystemInDarkTheme()

    if (state.auditLogs.isEmpty()) {
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Text("暂无审计日志", color = AppColors.slate400)
        }
    } else {
        LazyColumn(
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(state.auditLogs) { log ->
                GlassCard(
                    modifier = Modifier.fillMaxWidth(),
                    padding = PaddingValues(12.dp)
                ) {
                    Column {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                Icons.Default.History,
                                contentDescription = null,
                                tint = AppColors.primary,
                                modifier = Modifier.size(16.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = log["action"] as? String ?: "",
                                style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.SemiBold),
                                color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                            )
                            Spacer(modifier = Modifier.weight(1f))
                            Text(
                                text = log["time"] as? String ?: "",
                                style = MaterialTheme.typography.labelSmall,
                                color = if (isLight) AppColors.slate400 else AppColors.slate500
                            )
                        }
                        if (log["detail"] as? String != null) {
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = log["detail"] as? String ?: "",
                                style = MaterialTheme.typography.bodySmall,
                                color = if (isLight) AppColors.slate500 else AppColors.slate400
                            )
                        }
                    }
                }
            }
        }
    }
}
