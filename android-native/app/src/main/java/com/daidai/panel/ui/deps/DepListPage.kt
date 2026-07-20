package com.daidai.panel.ui.deps

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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.InstallDesktop
import androidx.compose.material.icons.filled.Memory
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.RestartAlt
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
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
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.daidai.panel.core.theme.AppColors
import com.daidai.panel.data.model.Dependency
import com.daidai.panel.ui.components.GlassCard
import com.daidai.panel.ui.components.StatusBadge
import com.daidai.panel.ui.components.BadgeStatus

@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun DepListPage(
    onBack: () -> Unit,
    viewModel: DepViewModel = hiltViewModel()
) {
    val isLight = !isSystemInDarkTheme()
    val state by viewModel.state.collectAsState()
    var showInstallSheet by remember { mutableStateOf(false) }
    var showDeleteDialog by remember { mutableStateOf<Dependency?>(null) }
    var showInstallLog by remember { mutableStateOf(false) }
    val snackbarHostState = remember { SnackbarHostState() }

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
                        "依赖管理",
                        style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold)
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "返回")
                    }
                },
                actions = {
                    IconButton(onClick = { showInstallLog = true }) {
                        Icon(Icons.Default.Description, contentDescription = "安装日志")
                    }
                    IconButton(onClick = { viewModel.load() }) {
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
                FilterChip(
                    selected = state.selectedTab == 0,
                    onClick = { viewModel.selectTab(0) },
                    label = { Text("Python") },
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(12.dp),
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = AppColors.primary,
                        selectedLabelColor = AppColors.white,
                        containerColor = if (isLight) AppColors.slate100 else AppColors.slate800
                    )
                )
                FilterChip(
                    selected = state.selectedTab == 1,
                    onClick = { viewModel.selectTab(1) },
                    label = { Text("Node.js") },
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(12.dp),
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = AppColors.primary,
                        selectedLabelColor = AppColors.white,
                        containerColor = if (isLight) AppColors.slate100 else AppColors.slate800
                    )
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            if (state.selectedTab == 0 && state.pythonRuntimes.isNotEmpty()) {
                GlassCard(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp),
                    glassMode = false,
                    padding = PaddingValues(12.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            Icons.Default.Memory,
                            contentDescription = null,
                            tint = AppColors.primary,
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Python 运行时",
                            style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.SemiBold),
                            color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                        )
                        Spacer(modifier = Modifier.weight(1f))
                        Text(
                            text = "${state.pythonRuntimes.size} 个可用",
                            style = MaterialTheme.typography.bodySmall,
                            color = AppColors.slate400
                        )
                    }
                }
                Spacer(modifier = Modifier.height(8.dp))
            }

            if (state.deps.isEmpty() && !state.isLoading) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            Icons.Default.InstallDesktop,
                            contentDescription = null,
                            modifier = Modifier.size(64.dp),
                            tint = AppColors.slate400
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            "暂无已安装依赖",
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
                    items(state.deps, key = { it.id }) { dep ->
                        DepCard(
                            dep = dep,
                            isInstalling = state.installingDeps.contains(dep.name),
                            onUninstall = { showDeleteDialog = dep },
                            onReinstall = { viewModel.reinstall(dep.id) },
                            onCancel = { viewModel.cancel(dep.name) }
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
        androidx.compose.material3.FloatingActionButton(
            onClick = { showInstallSheet = true },
            modifier = Modifier.padding(16.dp),
            containerColor = AppColors.primary,
            contentColor = AppColors.white
        ) {
            Icon(Icons.Default.Add, contentDescription = "安装依赖")
        }
    }

    if (showInstallSheet) {
        InstallDepSheet(
            selectedTab = state.selectedTab,
            onDismiss = { showInstallSheet = false },
            onConfirm = { name, type ->
                viewModel.install(name, type)
                showInstallSheet = false
            }
        )
    }

    showDeleteDialog?.let { dep ->
        AlertDialog(
            onDismissRequest = { showDeleteDialog = null },
            title = { Text("确认卸载") },
            text = { Text("确定要卸载「${dep.name}」吗？") },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.uninstall(dep.id)
                    showDeleteDialog = null
                }) {
                    Text("卸载", color = AppColors.red500)
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = null }) {
                    Text("取消")
                }
            }
        )
    }

    if (showInstallLog) {
        ModalBottomSheet(onDismissRequest = { showInstallLog = false }) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                Text(
                    "安装日志",
                    style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold)
                )
                Spacer(modifier = Modifier.height(16.dp))

                GlassCard(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(300.dp),
                    glassMode = false,
                    padding = PaddingValues(12.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(AppColors.termBg, RoundedCornerShape(12.dp))
                            .padding(8.dp)
                    ) {
                        Text(
                            text = state.installLog.ifBlank { "暂无日志" },
                            style = MaterialTheme.typography.bodySmall.copy(
                                fontFamily = FontFamily.Monospace,
                                fontSize = 12.sp,
                                color = AppColors.termText
                            ),
                            modifier = Modifier.verticalScroll(rememberScrollState())
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))
                Button(
                    onClick = { showInstallLog = false },
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
private fun DepCard(
    dep: Dependency,
    isInstalling: Boolean,
    onUninstall: () -> Unit,
    onReinstall: () -> Unit,
    onCancel: () -> Unit
) {
    val isLight = !isSystemInDarkTheme()

    GlassCard(
        modifier = Modifier.fillMaxWidth(),
        glassMode = false
    ) {
        Column {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = dep.name,
                        style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.SemiBold),
                        color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                    )
                    Row {
                        Text(
                            text = "v${dep.version}",
                            style = MaterialTheme.typography.bodySmall,
                            color = if (isLight) AppColors.slate500 else AppColors.slate400
                        )
                        if (dep.pythonVersion.isNotBlank()) {
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "Python ${dep.pythonVersion}",
                                style = MaterialTheme.typography.bodySmall,
                                color = AppColors.blue500
                            )
                        }
                    }
                }

                if (isInstalling) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        strokeWidth = 2.dp,
                        color = AppColors.primary
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    IconButton(onClick = onCancel) {
                        Icon(
                            Icons.Default.Cancel,
                            contentDescription = "取消",
                            tint = AppColors.red500,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                } else {
                    StatusBadge(
                        status = when (dep.status) {
                            "queued" -> BadgeStatus.QUEUED
                            "installing" -> BadgeStatus.RUNNING
                            "installed" -> BadgeStatus.SUCCESS
                            "removing" -> BadgeStatus.RUNNING
                            "failed" -> BadgeStatus.FAILED
                            else -> BadgeStatus.DISABLED
                        }
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    IconButton(onClick = onReinstall) {
                        Icon(
                            Icons.Default.RestartAlt,
                            contentDescription = "重装",
                            tint = AppColors.primary,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                    IconButton(onClick = onUninstall) {
                        Icon(
                            Icons.Default.Delete,
                            contentDescription = "卸载",
                            tint = AppColors.red500,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }
            }

            if (!dep.remark.isNullOrBlank()) {
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = dep.remark ?: "",
                    style = MaterialTheme.typography.bodySmall,
                    color = if (isLight) AppColors.slate400 else AppColors.slate500
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun InstallDepSheet(
    selectedTab: Int,
    onDismiss: () -> Unit,
    onConfirm: (name: String, type: String) -> Unit
) {
    var packageName by remember { mutableStateOf("") }
    val type = if (selectedTab == 0) "pip" else "npm"

    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Text(
                "安装 ${type.uppercase()} 依赖",
                style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold)
            )
            Spacer(modifier = Modifier.height(16.dp))

            OutlinedTextField(
                value = packageName,
                onValueChange = { packageName = it },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("包名称") },
                placeholder = { Text(if (type == "pip") "例如: requests" else "例如: axios") },
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
                    onClick = { onConfirm(packageName, type) },
                    enabled = packageName.isNotBlank(),
                    colors = ButtonDefaults.buttonColors(containerColor = AppColors.primary),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Text("安装")
                }
            }
            Spacer(modifier = Modifier.height(16.dp))
        }
    }
}
