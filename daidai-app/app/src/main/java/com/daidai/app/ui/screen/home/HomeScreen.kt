package com.daidai.app.ui.screen.home

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.daidai.app.data.remote.model.Dependency
import com.daidai.app.data.remote.model.Env
import com.daidai.app.data.remote.model.Notification
import com.daidai.app.data.remote.model.Platform
import com.daidai.app.data.remote.model.Script
import com.daidai.app.data.remote.model.Task
import com.daidai.app.data.remote.model.TaskLog
import com.daidai.app.ui.screen.dependency.DependencyViewModel
import com.daidai.app.ui.screen.env.EnvViewModel
import com.daidai.app.ui.screen.config.ConfigViewModel
import com.daidai.app.ui.screen.log.LogViewModel
import com.daidai.app.ui.screen.notification.NotificationViewModel
import com.daidai.app.ui.screen.quickactions.QuickActionsViewModel
import com.daidai.app.ui.screen.script.ScriptViewModel
import com.daidai.app.ui.screen.stats.StatsViewModel
import com.daidai.app.ui.screen.system.SystemViewModel
import com.daidai.app.ui.screen.login.ServerAddressDialog

sealed class HomeTab(val title: String, val icon: ImageVector) {
    object Tasks : HomeTab("任务", Icons.Default.List)
    object Environments : HomeTab("环境变量", Icons.Default.Settings)
    object Dependencies : HomeTab("依赖管理", Icons.Default.Extension)
    object Scripts : HomeTab("脚本", Icons.Default.Code)
    object Logs : HomeTab("日志", Icons.Default.Article)
    object Notifications : HomeTab("通知", Icons.Default.Notifications)
    object System : HomeTab("系统", Icons.Default.Computer)
    object QuickActions : HomeTab("快捷操作", Icons.Default.FlashOn)
    object Stats : HomeTab("统计", Icons.Default.BarChart)
    object Config : HomeTab("配置", Icons.Default.Tune)
    object Settings : HomeTab("设置", Icons.Default.Settings)
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    onNavigateToWebHelper: () -> Unit = {},
    onNavigateToTaskDetail: (Int) -> Unit = {},
    onLogout: () -> Unit = {}
) {
    var selectedTab by remember { mutableStateOf<HomeTab>(HomeTab.Tasks) }
    var showSearch by remember { mutableStateOf(false) }
    var searchQuery by remember { mutableStateOf("") }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("呆呆面板") },
                actions = {
                    IconButton(onClick = { showSearch = !showSearch }) {
                        Icon(
                            if (showSearch) Icons.Default.Close else Icons.Default.Search,
                            contentDescription = "搜索"
                        )
                    }
                    IconButton(onClick = { /* TODO: 刷新 */ }) {
                        Icon(Icons.Default.Refresh, contentDescription = "刷新")
                    }
                    IconButton(onClick = onNavigateToWebHelper) {
                        Icon(Icons.Default.Web, contentDescription = "Web助手")
                    }
                }
            )
        },
        bottomBar = {
            NavigationBar {
                val tabs = listOf(
                    HomeTab.Tasks,
                    HomeTab.Environments,
                    HomeTab.Dependencies,
                    HomeTab.Scripts,
                    HomeTab.Logs,
                    HomeTab.Notifications,
                    HomeTab.System,
                    HomeTab.QuickActions,
                    HomeTab.Stats,
                    HomeTab.Config,
                    HomeTab.Settings
                )
                tabs.forEach { tab ->
                    NavigationBarItem(
                        icon = { Icon(tab.icon, contentDescription = tab.title) },
                        label = { Text(tab.title) },
                        selected = selectedTab == tab,
                        onClick = { selectedTab = tab }
                    )
                }
            }
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // 搜索框
            if (showSearch && selectedTab is HomeTab.Tasks) {
                SearchBar(
                    query = searchQuery,
                    onQueryChange = { searchQuery = it },
                    onSearch = { /* 搜索由onQueryChange触发 */ },
                    active = false,
                    onActiveChange = {},
                    placeholder = { Text("搜索任务名称...") },
                    leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
                    trailingIcon = {
                        if (searchQuery.isNotEmpty()) {
                            IconButton(onClick = { searchQuery = "" }) {
                                Icon(Icons.Default.Close, contentDescription = "清除")
                            }
                        }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 8.dp)
                ) {}
            }

            // 内容区域
            Box(modifier = Modifier.fillMaxSize()) {
                when (selectedTab) {
                    is HomeTab.Tasks -> TasksContent(
                        onNavigateToTaskDetail = onNavigateToTaskDetail,
                        searchQuery = searchQuery
                    )
                    is HomeTab.Environments -> EnvironmentsContent()
                    is HomeTab.Dependencies -> DependenciesContent()
                    is HomeTab.Scripts -> ScriptsContent()
                    is HomeTab.Logs -> LogsContent()
                    is HomeTab.Notifications -> NotificationsContent()
                    is HomeTab.System -> SystemContent()
                    is HomeTab.QuickActions -> QuickActionsContent()
                    is HomeTab.Stats -> StatsContent()
                    is HomeTab.Config -> ConfigContent()
                    is HomeTab.Settings -> SettingsContent(onLogout = onLogout)
                }
            }
        }
    }
}

@Composable
fun TasksContent(
    onNavigateToTaskDetail: (Int) -> Unit = {},
    searchQuery: String = "",
    viewModel: TaskViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    var showCreateDialog by remember { mutableStateOf(false) }
    
    // 当搜索词变化时触发搜索
    LaunchedEffect(searchQuery) {
        if (searchQuery != uiState.searchQuery) {
            viewModel.searchTasks(searchQuery)
        }
    }
    
    Box(modifier = Modifier.fillMaxSize()) {
        if (uiState.isLoading && uiState.tasks.isEmpty()) {
            CircularProgressIndicator(
                modifier = Modifier.align(Alignment.Center)
            )
        } else if (uiState.error != null && uiState.tasks.isEmpty()) {
            Column(
                modifier = Modifier.align(Alignment.Center),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = uiState.error ?: "未知错误",
                    color = MaterialTheme.colorScheme.error
                )
                Spacer(modifier = Modifier.height(16.dp))
                Button(onClick = { viewModel.loadTasks(refresh = true) }) {
                    Text("重试")
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(uiState.tasks) { task ->
                    TaskItem(
                        task = task,
                        onClick = { onNavigateToTaskDetail(task.id) },
                        onRun = { viewModel.runTask(task.id) },
                        onStop = { viewModel.stopTask(task.id) },
                        onEnable = { viewModel.enableTask(task.id) },
                        onDisable = { viewModel.disableTask(task.id) },
                        onDelete = { viewModel.deleteTask(task.id) },
                        onGetLogs = { viewModel.getTaskLogs(it) },
                        taskLogs = uiState.taskLogs[task.id] ?: emptyList()
                    )
                }
                
                if (uiState.hasMore) {
                    item {
                        LaunchedEffect(Unit) {
                            viewModel.loadMore()
                        }
                    }
                }
            }
        }
        
        // 添加任务按钮
        FloatingActionButton(
            onClick = { showCreateDialog = true },
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(16.dp)
        ) {
            Icon(Icons.Default.Add, contentDescription = "添加任务")
        }
    }
    
    // 创建任务对话框
    if (showCreateDialog) {
        CreateTaskDialog(
            onDismiss = { showCreateDialog = false },
            onCreate = { name, command, schedule, taskType ->
                viewModel.createTask(name, command, schedule, taskType)
                showCreateDialog = false
            }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateTaskDialog(
    onDismiss: () -> Unit,
    onCreate: (String, String, String, String) -> Unit,
    onUploadScript: ((String, String) -> Unit)? = null
) {
    var name by remember { mutableStateOf("") }
    var command by remember { mutableStateOf("") }
    var schedule by remember { mutableStateOf("") }
    var taskType by remember { mutableStateOf("cron") }
    var showScriptSelector by remember { mutableStateOf(false) }
    var expanded by remember { mutableStateOf(false) }
    
    val taskTypes = listOf("cron", "interval", "once", "manual")
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("创建任务") },
        text = {
            Column {
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("任务名称") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
                Spacer(modifier = Modifier.height(12.dp))
                
                // 任务类型选择
                ExposedDropdownMenuBox(
                    expanded = expanded,
                    onExpandedChange = { expanded = !expanded }
                ) {
                    OutlinedTextField(
                        value = taskType,
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("任务类型") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor()
                    )
                    ExposedDropdownMenu(
                        expanded = expanded,
                        onDismissRequest = { expanded = false }
                    ) {
                        taskTypes.forEach { type ->
                            DropdownMenuItem(
                                text = { Text(type) },
                                onClick = {
                                    taskType = type
                                    expanded = false
                                }
                            )
                        }
                    }
                }
                Spacer(modifier = Modifier.height(12.dp))
                
                OutlinedTextField(
                    value = command,
                    onValueChange = { command = it },
                    label = { Text("执行命令") },
                    modifier = Modifier.fillMaxWidth(),
                    minLines = 3,
                    maxLines = 5
                )
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.End
                ) {
                    TextButton(
                        onClick = { showScriptSelector = true }
                    ) {
                        Icon(Icons.Default.Upload, contentDescription = null)
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("上传脚本")
                    }
                }
                Spacer(modifier = Modifier.height(8.dp))
                
                // Cron表达式输入（仅当类型为cron时显示）
                if (taskType == "cron") {
                    OutlinedTextField(
                        value = schedule,
                        onValueChange = { schedule = it },
                        label = { Text("调度表达式 (cron)") },
                        modifier = Modifier.fillMaxWidth(),
                        placeholder = { Text("例如: 0 0 * * * (每天0点)") },
                        supportingText = { Text("分 时 日 月 周") }
                    )
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    // 常用Cron模板
                    Text(
                        text = "常用模板",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        AssistChip(
                            onClick = { schedule = "0 0 * * *" },
                            label = { Text("每天0点", style = MaterialTheme.typography.labelSmall) }
                        )
                        AssistChip(
                            onClick = { schedule = "0 */1 * * *" },
                            label = { Text("每小时", style = MaterialTheme.typography.labelSmall) }
                        )
                        AssistChip(
                            onClick = { schedule = "*/5 * * * *" },
                            label = { Text("每5分钟", style = MaterialTheme.typography.labelSmall) }
                        )
                    }
                } else if (taskType == "interval") {
                    OutlinedTextField(
                        value = schedule,
                        onValueChange = { schedule = it },
                        label = { Text("间隔秒数") },
                        modifier = Modifier.fillMaxWidth(),
                        placeholder = { Text("例如: 3600 (每小时)") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
                    )
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = { onCreate(name, command, schedule, taskType) },
                enabled = name.isNotBlank() && command.isNotBlank()
            ) {
                Text("创建")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("取消")
            }
        }
    )
    
    // 脚本选择器对话框
    if (showScriptSelector) {
        ScriptSelectorDialog(
            onDismiss = { showScriptSelector = false },
            onSelect = { scriptPath ->
                command = "sh $scriptPath"
                showScriptSelector = false
            }
        )
    }
}

@Composable
fun ScriptSelectorDialog(
    onDismiss: () -> Unit,
    onSelect: (String) -> Unit
) {
    var scriptPath by remember { mutableStateOf("") }
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("选择脚本") },
        text = {
            Column {
                Text(
                    text = "输入脚本路径或从上传的脚本中选择",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(16.dp))
                OutlinedTextField(
                    value = scriptPath,
                    onValueChange = { scriptPath = it },
                    label = { Text("脚本路径") },
                    modifier = Modifier.fillMaxWidth(),
                    placeholder = { Text("例如: /scripts/my_script.sh") }
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = { onSelect(scriptPath) },
                enabled = scriptPath.isNotBlank()
            ) {
                Text("确定")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("取消")
            }
        }
    )
}

@Composable
fun EnvironmentsContent(
    viewModel: EnvViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    var showCreateDialog by remember { mutableStateOf(false) }
    var editingEnv by remember { mutableStateOf<Env?>(null) }
    var showDeleteDialog by remember { mutableStateOf<Env?>(null) }
    
    Box(modifier = Modifier.fillMaxSize()) {
        if (uiState.isLoading && uiState.envs.isEmpty()) {
            CircularProgressIndicator(
                modifier = Modifier.align(Alignment.Center)
            )
        } else if (uiState.error != null && uiState.envs.isEmpty()) {
            Column(
                modifier = Modifier.align(Alignment.Center),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = uiState.error ?: "未知错误",
                    color = MaterialTheme.colorScheme.error
                )
                Spacer(modifier = Modifier.height(16.dp))
                Button(onClick = { viewModel.loadEnvs(refresh = true) }) {
                    Text("重试")
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(uiState.envs) { env ->
                    Card(
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp)
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(
                                        text = env.name,
                                        style = MaterialTheme.typography.titleMedium
                                    )
                                    Spacer(modifier = Modifier.height(4.dp))
                                    Text(
                                        text = env.value,
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                    env.remark?.let { remark ->
                                        Spacer(modifier = Modifier.height(4.dp))
                                        Text(
                                            text = remark,
                                            style = MaterialTheme.typography.bodySmall,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                    }
                                }
                                Switch(
                                    checked = env.isEnabled,
                                    onCheckedChange = { enabled ->
                                        viewModel.toggleEnv(env.id, enabled)
                                    }
                                )
                            }
                            
                            Spacer(modifier = Modifier.height(8.dp))
                            
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.End
                            ) {
                                IconButton(
                                    onClick = { editingEnv = env },
                                    modifier = Modifier.size(32.dp)
                                ) {
                                    Icon(
                                        Icons.Default.Edit,
                                        contentDescription = "编辑",
                                        modifier = Modifier.size(18.dp)
                                    )
                                }
                                IconButton(
                                    onClick = { showDeleteDialog = env },
                                    modifier = Modifier.size(32.dp)
                                ) {
                                    Icon(
                                        Icons.Default.Delete,
                                        contentDescription = "删除",
                                        tint = MaterialTheme.colorScheme.error,
                                        modifier = Modifier.size(18.dp)
                                    )
                                }
                            }
                        }
                    }
                }
                
                if (uiState.hasMore) {
                    item {
                        LaunchedEffect(Unit) {
                            viewModel.loadMore()
                        }
                    }
                }
            }
        }
        
        // 添加环境变量按钮
        FloatingActionButton(
            onClick = { showCreateDialog = true },
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(16.dp)
        ) {
            Icon(Icons.Default.Add, contentDescription = "添加环境变量")
        }
    }
    
    // 创建环境变量对话框
    if (showCreateDialog) {
        EnvDialog(
            title = "创建环境变量",
            onDismiss = { showCreateDialog = false },
            onConfirm = { name, value, remark ->
                viewModel.createEnv(name, value, remark)
                showCreateDialog = false
            }
        )
    }
    
    // 编辑环境变量对话框
    editingEnv?.let { env ->
        EnvDialog(
            title = "编辑环境变量",
            initialName = env.name,
            initialValue = env.value,
            initialRemark = env.remark ?: "",
            onDismiss = { editingEnv = null },
            onConfirm = { name, value, remark ->
                viewModel.updateEnv(env.id, name, value, remark)
                editingEnv = null
            }
        )
    }
    
    // 删除确认对话框
    showDeleteDialog?.let { env ->
        AlertDialog(
            onDismissRequest = { showDeleteDialog = null },
            title = { Text("确认删除") },
            text = { Text("确定要删除环境变量「${env.name}」吗？") },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.deleteEnv(env.id)
                        showDeleteDialog = null
                    },
                    colors = ButtonDefaults.textButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Text("删除")
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
fun EnvDialog(
    title: String,
    initialName: String = "",
    initialValue: String = "",
    initialRemark: String = "",
    onDismiss: () -> Unit,
    onConfirm: (String, String, String?) -> Unit
) {
    var name by remember { mutableStateOf(initialName) }
    var value by remember { mutableStateOf(initialValue) }
    var remark by remember { mutableStateOf(initialRemark) }
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = {
            Column {
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("变量名") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
                Spacer(modifier = Modifier.height(12.dp))
                OutlinedTextField(
                    value = value,
                    onValueChange = { value = it },
                    label = { Text("变量值") },
                    modifier = Modifier.fillMaxWidth(),
                    minLines = 2,
                    maxLines = 4
                )
                Spacer(modifier = Modifier.height(12.dp))
                OutlinedTextField(
                    value = remark,
                    onValueChange = { remark = it },
                    label = { Text("备注（可选）") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = { onConfirm(name, value, remark.ifBlank { null }) },
                enabled = name.isNotBlank() && value.isNotBlank()
            ) {
                Text("确定")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("取消")
            }
        }
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DependenciesContent(
    viewModel: DependencyViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    var showInstallDialog by remember { mutableStateOf(false) }
    var showDeleteDialog by remember { mutableStateOf<Dependency?>(null) }
    
    Column(modifier = Modifier.fillMaxSize()) {
        // 类型选择标签
        ScrollableTabRow(
            selectedTabIndex = when (uiState.selectedType) {
                "nodejs" -> 0
                "python" -> 1
                "linux" -> 2
                else -> 0
            },
            modifier = Modifier.fillMaxWidth()
        ) {
            Tab(
                selected = uiState.selectedType == "nodejs",
                onClick = { viewModel.changeType("nodejs") },
                text = { Text("Node.js") }
            )
            Tab(
                selected = uiState.selectedType == "python",
                onClick = { viewModel.changeType("python") },
                text = { Text("Python") }
            )
            Tab(
                selected = uiState.selectedType == "linux",
                onClick = { viewModel.changeType("linux") },
                text = { Text("Linux") }
            )
        }
        
        // 内容区域
        Box(modifier = Modifier.fillMaxSize()) {
            if (uiState.isLoading && uiState.dependencies.isEmpty()) {
                CircularProgressIndicator(
                    modifier = Modifier.align(Alignment.Center)
                )
            } else if (uiState.error != null && uiState.dependencies.isEmpty()) {
                Column(
                    modifier = Modifier.align(Alignment.Center),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = uiState.error ?: "未知错误",
                        color = MaterialTheme.colorScheme.error
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Button(onClick = { viewModel.loadDeps() }) {
                        Text("重试")
                    }
                }
            } else if (uiState.dependencies.isEmpty()) {
                Column(
                    modifier = Modifier.align(Alignment.Center),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Icon(
                        Icons.Default.Extension,
                        contentDescription = null,
                        modifier = Modifier.size(64.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "暂无${uiState.selectedType}依赖",
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Button(onClick = { showInstallDialog = true }) {
                        Icon(Icons.Default.Add, contentDescription = null)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("安装依赖")
                    }
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(uiState.dependencies) { dep ->
                        Card(
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Row(
                                modifier = Modifier.padding(16.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    Icons.Default.Extension,
                                    contentDescription = null,
                                    modifier = Modifier.size(40.dp),
                                    tint = when (dep.status) {
                                        "installed" -> MaterialTheme.colorScheme.primary
                                        "installing", "queued" -> MaterialTheme.colorScheme.tertiary
                                        else -> MaterialTheme.colorScheme.error
                                    }
                                )
                                Spacer(modifier = Modifier.width(16.dp))
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(
                                        text = dep.name,
                                        style = MaterialTheme.typography.titleMedium
                                    )
                                    Text(
                                        text = dep.typeText,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                                AssistChip(
                                    onClick = {},
                                    label = { Text(dep.statusText) },
                                    colors = AssistChipDefaults.assistChipColors(
                                        containerColor = when (dep.status) {
                                            "installed" -> MaterialTheme.colorScheme.primaryContainer
                                            "installing", "queued" -> MaterialTheme.colorScheme.tertiaryContainer
                                            else -> MaterialTheme.colorScheme.errorContainer
                                        }
                                    )
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                IconButton(
                                    onClick = { viewModel.reinstallDep(dep.id) },
                                    modifier = Modifier.size(32.dp)
                                ) {
                                    Icon(
                                        Icons.Default.Refresh,
                                        contentDescription = "重新安装",
                                        modifier = Modifier.size(18.dp)
                                    )
                                }
                                IconButton(
                                    onClick = { showDeleteDialog = dep },
                                    modifier = Modifier.size(32.dp)
                                ) {
                                    Icon(
                                        Icons.Default.Delete,
                                        contentDescription = "删除",
                                        tint = MaterialTheme.colorScheme.error,
                                        modifier = Modifier.size(18.dp)
                                    )
                                }
                            }
                        }
                    }
                }
            }
            
            // 安装依赖按钮
            FloatingActionButton(
                onClick = { showInstallDialog = true },
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .padding(16.dp)
            ) {
                Icon(Icons.Default.Add, contentDescription = "安装依赖")
            }
        }
    }
    
    // 安装依赖对话框
    if (showInstallDialog) {
        InstallDepDialog(
            depType = uiState.selectedType,
            onDismiss = { showInstallDialog = false },
            onInstall = { name, type ->
                viewModel.installDep(name, type)
                showInstallDialog = false
            }
        )
    }
    
    // 删除确认对话框
    showDeleteDialog?.let { dep ->
        AlertDialog(
            onDismissRequest = { showDeleteDialog = null },
            title = { Text("确认删除") },
            text = { Text("确定要删除依赖「${dep.name}」吗？") },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.deleteDep(dep.id)
                        showDeleteDialog = null
                    },
                    colors = ButtonDefaults.textButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Text("删除")
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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InstallDepDialog(
    depType: String,
    onDismiss: () -> Unit,
    onInstall: (String, String) -> Unit
) {
    var name by remember { mutableStateOf("") }
    var type by remember { mutableStateOf(depType) }
    var expanded by remember { mutableStateOf(false) }
    
    val depTypes = listOf("nodejs", "python", "linux")
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("安装依赖") },
        text = {
            Column {
                ExposedDropdownMenuBox(
                    expanded = expanded,
                    onExpandedChange = { expanded = !expanded }
                ) {
                    OutlinedTextField(
                        value = type,
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("依赖类型") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor()
                    )
                    ExposedDropdownMenu(
                        expanded = expanded,
                        onDismissRequest = { expanded = false }
                    ) {
                        depTypes.forEach { depType ->
                            DropdownMenuItem(
                                text = { Text(depType) },
                                onClick = {
                                    type = depType
                                    expanded = false
                                }
                            )
                        }
                    }
                }
                Spacer(modifier = Modifier.height(12.dp))
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("依赖名称") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    placeholder = { Text("例如: axios, requests, curl") }
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = { onInstall(name, type) },
                enabled = name.isNotBlank()
            ) {
                Text("安装")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("取消")
            }
        }
    )
}

fun formatFileSize(bytes: Long): String {
    return when {
        bytes < 1024 -> "$bytes B"
        bytes < 1024 * 1024 -> "${bytes / 1024} KB"
        bytes < 1024 * 1024 * 1024 -> "${bytes / (1024 * 1024)} MB"
        else -> "${bytes / (1024 * 1024 * 1024)} GB"
    }
}

@Composable
fun ScriptsContent(
    viewModel: ScriptViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    var showCreateDialog by remember { mutableStateOf(false) }
    var showDeleteDialog by remember { mutableStateOf<Script?>(null) }
    
    Box(modifier = Modifier.fillMaxSize()) {
        if (uiState.isLoading && uiState.scripts.isEmpty()) {
            CircularProgressIndicator(
                modifier = Modifier.align(Alignment.Center)
            )
        } else if (uiState.error != null && uiState.scripts.isEmpty()) {
            Column(
                modifier = Modifier.align(Alignment.Center),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = uiState.error ?: "未知错误",
                    color = MaterialTheme.colorScheme.error
                )
                Spacer(modifier = Modifier.height(16.dp))
                Button(onClick = { viewModel.loadScripts() }) {
                    Text("重试")
                }
            }
        } else if (uiState.scripts.isEmpty()) {
            Column(
                modifier = Modifier.align(Alignment.Center),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Icon(
                    Icons.Default.Code,
                    contentDescription = null,
                    modifier = Modifier.size(64.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(16.dp))
                Text(
                    text = "暂无脚本",
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(16.dp))
                Button(onClick = { showCreateDialog = true }) {
                    Icon(Icons.Default.Add, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("创建脚本")
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(uiState.scripts) { script ->
                    Card(
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp)
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    Icons.Default.Code,
                                    contentDescription = null,
                                    modifier = Modifier.size(40.dp),
                                    tint = MaterialTheme.colorScheme.primary
                                )
                                Spacer(modifier = Modifier.width(16.dp))
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(
                                        text = script.name,
                                        style = MaterialTheme.typography.titleMedium
                                    )
                                    Text(
                                        text = script.path,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                    script.size?.let { size ->
                                        Text(
                                            text = formatFileSize(size.toLong()),
                                            style = MaterialTheme.typography.bodySmall,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                    }
                                }
                            }
                            
                            Spacer(modifier = Modifier.height(8.dp))
                            
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.End
                            ) {
                                IconButton(
                                    onClick = { viewModel.runScript(script.path) },
                                    modifier = Modifier.size(32.dp)
                                ) {
                                    Icon(
                                        Icons.Default.PlayArrow,
                                        contentDescription = "运行",
                                        tint = MaterialTheme.colorScheme.primary,
                                        modifier = Modifier.size(18.dp)
                                    )
                                }
                                IconButton(
                                    onClick = { showDeleteDialog = script },
                                    modifier = Modifier.size(32.dp)
                                ) {
                                    Icon(
                                        Icons.Default.Delete,
                                        contentDescription = "删除",
                                        tint = MaterialTheme.colorScheme.error,
                                        modifier = Modifier.size(18.dp)
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // 创建脚本按钮
        FloatingActionButton(
            onClick = { showCreateDialog = true },
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(16.dp)
        ) {
            Icon(Icons.Default.Add, contentDescription = "创建脚本")
        }
    }
    
    // 创建脚本对话框
    if (showCreateDialog) {
        CreateScriptDialog(
            onDismiss = { showCreateDialog = false },
            onCreate = { name, content, description ->
                viewModel.createScript(name, content, description)
                showCreateDialog = false
            }
        )
    }
    
    // 删除确认对话框
    showDeleteDialog?.let { script ->
        AlertDialog(
            onDismissRequest = { showDeleteDialog = null },
            title = { Text("确认删除") },
            text = { Text("确定要删除脚本「${script.name}」吗？") },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.deleteScript(script.path)
                        showDeleteDialog = null
                    },
                    colors = ButtonDefaults.textButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Text("删除")
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
fun CreateScriptDialog(
    onDismiss: () -> Unit,
    onCreate: (String, String, String?) -> Unit
) {
    var name by remember { mutableStateOf("") }
    var content by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("创建脚本") },
        text = {
            Column {
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("脚本名称") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    placeholder = { Text("例如: my_script.sh") }
                )
                Spacer(modifier = Modifier.height(12.dp))
                OutlinedTextField(
                    value = content,
                    onValueChange = { content = it },
                    label = { Text("脚本内容") },
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(min = 150.dp),
                    minLines = 5
                )
                Spacer(modifier = Modifier.height(12.dp))
                OutlinedTextField(
                    value = description,
                    onValueChange = { description = it },
                    label = { Text("描述（可选）") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = { onCreate(name, content, description.ifBlank { null }) },
                enabled = name.isNotBlank() && content.isNotBlank()
            ) {
                Text("创建")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("取消")
            }
        }
    )
}

@Composable
fun NotificationsContent(
    viewModel: NotificationViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    var showCreateDialog by remember { mutableStateOf(false) }
    var showDeleteDialog by remember { mutableStateOf<Notification?>(null) }
    
    Box(modifier = Modifier.fillMaxSize()) {
        if (uiState.isLoading && uiState.notifications.isEmpty()) {
            CircularProgressIndicator(
                modifier = Modifier.align(Alignment.Center)
            )
        } else if (uiState.error != null && uiState.notifications.isEmpty()) {
            Column(
                modifier = Modifier.align(Alignment.Center),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = uiState.error ?: "未知错误",
                    color = MaterialTheme.colorScheme.error
                )
                Spacer(modifier = Modifier.height(16.dp))
                Button(onClick = { viewModel.loadNotifications() }) {
                    Text("重试")
                }
            }
        } else if (uiState.notifications.isEmpty()) {
            Column(
                modifier = Modifier.align(Alignment.Center),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Icon(
                    Icons.Default.Notifications,
                    contentDescription = null,
                    modifier = Modifier.size(64.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(16.dp))
                Text(
                    text = "暂无通知配置",
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(16.dp))
                Button(onClick = { showCreateDialog = true }) {
                    Icon(Icons.Default.Add, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("添加通知")
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(uiState.notifications) { notification ->
                    Card(
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp)
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(
                                        text = notification.name,
                                        style = MaterialTheme.typography.titleMedium
                                    )
                                    Text(
                                        text = notification.type,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                                Switch(
                                    checked = notification.enabled,
                                    onCheckedChange = { enabled ->
                                        viewModel.toggleNotification(notification.id, enabled)
                                    }
                                )
                            }
                            
                            Spacer(modifier = Modifier.height(8.dp))
                            
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.End
                            ) {
                                IconButton(
                                    onClick = { viewModel.testNotification(notification.id) },
                                    modifier = Modifier.size(32.dp)
                                ) {
                                    Icon(
                                        Icons.Default.Send,
                                        contentDescription = "测试",
                                        modifier = Modifier.size(18.dp)
                                    )
                                }
                                IconButton(
                                    onClick = { showDeleteDialog = notification },
                                    modifier = Modifier.size(32.dp)
                                ) {
                                    Icon(
                                        Icons.Default.Delete,
                                        contentDescription = "删除",
                                        tint = MaterialTheme.colorScheme.error,
                                        modifier = Modifier.size(18.dp)
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // 添加通知按钮
        FloatingActionButton(
            onClick = { showCreateDialog = true },
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(16.dp)
        ) {
            Icon(Icons.Default.Add, contentDescription = "添加通知")
        }
    }
    
    // 创建通知对话框
    if (showCreateDialog) {
        CreateNotificationDialog(
            onDismiss = { showCreateDialog = false },
            onCreate = { name, type, config ->
                viewModel.createNotification(name, type, config)
                showCreateDialog = false
            }
        )
    }
    
    // 删除确认对话框
    showDeleteDialog?.let { notification ->
        AlertDialog(
            onDismissRequest = { showDeleteDialog = null },
            title = { Text("确认删除") },
            text = { Text("确定要删除通知「${notification.name}」吗？") },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.deleteNotification(notification.id)
                        showDeleteDialog = null
                    },
                    colors = ButtonDefaults.textButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Text("删除")
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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateNotificationDialog(
    onDismiss: () -> Unit,
    onCreate: (String, String, Map<String, Any?>) -> Unit
) {
    var name by remember { mutableStateOf("") }
    var type by remember { mutableStateOf("webhook") }
    var config by remember { mutableStateOf("") }
    var expanded by remember { mutableStateOf(false) }
    
    val notificationTypes = listOf("webhook", "email", "telegram", "bark", "dingtalk", "wechat")
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("添加通知") },
        text = {
            Column {
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("通知名称") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
                Spacer(modifier = Modifier.height(12.dp))
                
                ExposedDropdownMenuBox(
                    expanded = expanded,
                    onExpandedChange = { expanded = !expanded }
                ) {
                    OutlinedTextField(
                        value = type,
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("通知类型") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor()
                    )
                    ExposedDropdownMenu(
                        expanded = expanded,
                        onDismissRequest = { expanded = false }
                    ) {
                        notificationTypes.forEach { notificationType ->
                            DropdownMenuItem(
                                text = { Text(notificationType) },
                                onClick = {
                                    type = notificationType
                                    expanded = false
                                }
                            )
                        }
                    }
                }
                Spacer(modifier = Modifier.height(12.dp))
                
                OutlinedTextField(
                    value = config,
                    onValueChange = { config = it },
                    label = { Text("配置 (JSON)") },
                    modifier = Modifier.fillMaxWidth(),
                    minLines = 3,
                    maxLines = 5,
                    placeholder = { Text("{\"url\": \"https://...\"}") }
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = { 
                    try {
                        val jsonObject = org.json.JSONObject(config)
                        val configMap = mutableMapOf<String, Any?>()
                        jsonObject.keys().forEach { key ->
                            configMap[key] = jsonObject.get(key)
                        }
                        onCreate(name, type, configMap)
                    } catch (e: Exception) {
                        // 如果JSON解析失败，创建一个包含原始字符串的Map
                        onCreate(name, type, mapOf("raw" to config))
                    }
                },
                enabled = name.isNotBlank() && config.isNotBlank()
            ) {
                Text("添加")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("取消")
            }
        }
    )
}

@Composable
fun LogsContent(
    viewModel: LogViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    var showDeleteDialog by remember { mutableStateOf<TaskLog?>(null) }
    
    Box(modifier = Modifier.fillMaxSize()) {
        if (uiState.isLoading && uiState.logs.isEmpty()) {
            CircularProgressIndicator(
                modifier = Modifier.align(Alignment.Center)
            )
        } else if (uiState.error != null && uiState.logs.isEmpty()) {
            Column(
                modifier = Modifier.align(Alignment.Center),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = uiState.error ?: "未知错误",
                    color = MaterialTheme.colorScheme.error
                )
                Spacer(modifier = Modifier.height(16.dp))
                Button(onClick = { viewModel.loadLogs(refresh = true) }) {
                    Text("重试")
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(uiState.logs) { log ->
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { viewModel.loadLogDetail(log.id) }
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp)
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = log.taskName ?: "未知任务",
                                    style = MaterialTheme.typography.titleMedium,
                                    modifier = Modifier.weight(1f)
                                )
                                Surface(
                                    shape = MaterialTheme.shapes.small,
                                    color = if (log.status == 0) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.error
                                ) {
                                    Text(
                                        text = if (log.status == 0) "成功" else "失败",
                                        color = MaterialTheme.colorScheme.onPrimary,
                                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                                        style = MaterialTheme.typography.labelSmall
                                    )
                                }
                            }
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = "开始时间: ${log.startedAt}",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            log.endedAt?.let { endedAt ->
                                Text(
                                    text = "结束时间: $endedAt",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                            log.duration?.let { duration ->
                                Text(
                                    text = "耗时: ${String.format("%.2f", duration / 1000)}秒",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                            
                            Spacer(modifier = Modifier.height(8.dp))
                            
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.End
                            ) {
                                IconButton(
                                    onClick = { showDeleteDialog = log },
                                    modifier = Modifier.size(32.dp)
                                ) {
                                    Icon(
                                        Icons.Default.Delete,
                                        contentDescription = "删除",
                                        tint = MaterialTheme.colorScheme.error,
                                        modifier = Modifier.size(18.dp)
                                    )
                                }
                            }
                        }
                    }
                }
                
                if (uiState.hasMore) {
                    item {
                        LaunchedEffect(Unit) {
                            viewModel.loadMore()
                        }
                    }
                }
            }
        }
        
        // 日志详情弹窗
        uiState.selectedLog?.let { logDetail ->
            AlertDialog(
                onDismissRequest = { viewModel.clearSelectedLog() },
                title = { Text("日志详情") },
                text = {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .verticalScroll(rememberScrollState())
                    ) {
                        Text("任务ID: ${logDetail.taskId}")
                        logDetail.taskName?.let { Text("任务名称: $it") }
                        Text("状态: ${if (logDetail.status == 0) "成功" else "失败"}")
                        Text("开始时间: ${logDetail.startedAt}")
                        logDetail.endedAt?.let { Text("结束时间: $it") }
                        logDetail.duration?.let { Text("耗时: ${String.format("%.2f", it / 1000)}秒") }
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        Text(
                            text = "日志内容:",
                            style = MaterialTheme.typography.titleSmall
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        if (uiState.isLoadingDetail) {
                            CircularProgressIndicator(
                                modifier = Modifier.align(Alignment.CenterHorizontally)
                            )
                        } else {
                            Surface(
                                modifier = Modifier.fillMaxWidth(),
                                shape = MaterialTheme.shapes.small,
                                color = MaterialTheme.colorScheme.surfaceVariant
                            ) {
                                Text(
                                    text = logDetail.content ?: "暂无日志内容",
                                    style = MaterialTheme.typography.bodySmall,
                                    modifier = Modifier.padding(8.dp)
                                )
                            }
                        }
                    }
                },
                confirmButton = {
                    TextButton(onClick = { viewModel.clearSelectedLog() }) {
                        Text("关闭")
                    }
                }
            )
        }
    }
    
    // 删除确认对话框
    showDeleteDialog?.let { log ->
        AlertDialog(
            onDismissRequest = { showDeleteDialog = null },
            title = { Text("确认删除") },
            text = { Text("确定要删除该日志吗？") },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.deleteLog(log.id)
                        showDeleteDialog = null
                    },
                    colors = ButtonDefaults.textButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Text("删除")
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
fun SystemContent(
    viewModel: SystemViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    
    Box(modifier = Modifier.fillMaxSize()) {
        if (uiState.isLoading && uiState.systemInfo == null) {
            CircularProgressIndicator(
                modifier = Modifier.align(Alignment.Center)
            )
        } else if (uiState.error != null && uiState.systemInfo == null) {
            Column(
                modifier = Modifier.align(Alignment.Center),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = uiState.error ?: "未知错误",
                    color = MaterialTheme.colorScheme.error
                )
                Spacer(modifier = Modifier.height(16.dp))
                Button(onClick = { viewModel.loadSystemInfo() }) {
                    Text("重试")
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // 系统信息卡片
                item {
                    Card(
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp)
                        ) {
                            Text(
                                text = "系统信息",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                            Spacer(modifier = Modifier.height(12.dp))
                            
                            uiState.systemInfo?.let { info ->
                                SystemInfoRow("主机名", info.hostname ?: "-")
                                SystemInfoRow("操作系统", info.os ?: "-")
                                SystemInfoRow("架构", info.arch ?: "-")
                                SystemInfoRow("CPU核心数", info.numCpu?.toString() ?: "-")
                                SystemInfoRow("Go版本", info.goVersion ?: "-")
                                SystemInfoRow("运行时间", info.uptime ?: "-")
                            }
                        }
                    }
                }
                
                // 资源使用卡片
                item {
                    Card(
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp)
                        ) {
                            Text(
                                text = "资源使用",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                            Spacer(modifier = Modifier.height(12.dp))
                            
                            uiState.systemInfo?.let { info ->
                                // CPU使用率
                                ResourceProgressBar(
                                    label = "CPU",
                                    usage = info.cpuUsage ?: 0.0,
                                    color = MaterialTheme.colorScheme.primary
                                )
                                
                                Spacer(modifier = Modifier.height(12.dp))
                                
                                // 内存使用
                                ResourceProgressBar(
                                    label = "内存",
                                    usage = info.memoryUsage ?: 0.0,
                                    detail = "${formatBytes(info.memoryUsed)} / ${formatBytes(info.memoryTotal)}",
                                    color = MaterialTheme.colorScheme.secondary
                                )
                                
                                Spacer(modifier = Modifier.height(12.dp))
                                
                                // 磁盘使用
                                ResourceProgressBar(
                                    label = "磁盘",
                                    usage = info.diskUsage ?: 0.0,
                                    detail = "${formatBytes(info.diskUsed)} / ${formatBytes(info.diskTotal)}",
                                    color = MaterialTheme.colorScheme.tertiary
                                )
                                
                                Spacer(modifier = Modifier.height(12.dp))
                                
                                // 网络
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    Column {
                                        Text(
                                            text = "网络接收",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                        Text(
                                            text = "${formatBytes(info.netRxBytes)} (${formatSpeed(info.netRxSpeed)})",
                                            style = MaterialTheme.typography.bodyMedium
                                        )
                                    }
                                    Column(horizontalAlignment = Alignment.End) {
                                        Text(
                                            text = "网络发送",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                        Text(
                                            text = "${formatBytes(info.netTxBytes)} (${formatSpeed(info.netTxSpeed)})",
                                            style = MaterialTheme.typography.bodyMedium
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
                
                // 仪表盘数据卡片
                uiState.dashboardData?.let { dashboard ->
                    item {
                        Card(
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Column(
                                modifier = Modifier.padding(16.dp)
                            ) {
                                Text(
                                    text = "任务统计",
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold
                                )
                                Spacer(modifier = Modifier.height(12.dp))
                                
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceEvenly
                                ) {
                                    DashboardItem("总任务数", dashboard.taskCount?.toString() ?: "0")
                                    DashboardItem("运行中", dashboard.runningTasks?.toString() ?: "0")
                                    DashboardItem("今日执行", dashboard.todayLogs?.toString() ?: "0")
                                }
                            }
                        }
                    }
                }
                
                // 版本信息卡片
                uiState.versionData?.let { version ->
                    item {
                        Card(
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Column(
                                modifier = Modifier.padding(16.dp)
                            ) {
                                Text(
                                    text = "版本信息",
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold
                                )
                                Spacer(modifier = Modifier.height(12.dp))
                                
                                SystemInfoRow("版本", version.version ?: "-")
                                SystemInfoRow("API版本", version.apiVersion ?: "-")
                                SystemInfoRow("框架", version.framework ?: "-")
                                
                                Spacer(modifier = Modifier.height(12.dp))
                                
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.End
                                ) {
                                    Button(onClick = { viewModel.checkUpdate() }) {
                                        Text("检查更新")
                                    }
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Button(onClick = { viewModel.updatePanel() }) {
                                        Text("更新面板")
                                    }
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Button(
                                        onClick = { viewModel.restartPanel() },
                                        colors = ButtonDefaults.buttonColors(
                                            containerColor = MaterialTheme.colorScheme.error
                                        )
                                    ) {
                                        Text("重启面板")
                                    }
                                }
                            }
                        }
                    }
                }
                
                // 健康检查卡片
                item {
                    Card(
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp)
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = "健康检查",
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold
                                )
                                Button(onClick = { viewModel.doHealthCheck() }) {
                                    Text("执行检查")
                                }
                            }
                            
                            Spacer(modifier = Modifier.height(12.dp))
                            
                            uiState.healthCheckItems?.let { items ->
                                items.forEach { item ->
                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(vertical = 4.dp),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Icon(
                                            imageVector = if (item.status == "ok") Icons.Default.CheckCircle else Icons.Default.Error,
                                            contentDescription = null,
                                            tint = if (item.status == "ok") MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.error,
                                            modifier = Modifier.size(20.dp)
                                        )
                                        Spacer(modifier = Modifier.width(8.dp))
                                        Column(modifier = Modifier.weight(1f)) {
                                            Text(
                                                text = item.name,
                                                style = MaterialTheme.typography.bodyMedium
                                            )
                                            item.message?.let { message ->
                                                Text(
                                                    text = message,
                                                    style = MaterialTheme.typography.bodySmall,
                                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                                )
                                            }
                                        }
                                    }
                                }
                            } ?: run {
                                Text(
                                    text = "点击「执行检查」进行健康检查",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun SystemInfoRow(label: String, value: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium
        )
    }
}

@Composable
fun ResourceProgressBar(
    label: String,
    usage: Double,
    detail: String? = null,
    color: Color
) {
    Column {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text = label,
                style = MaterialTheme.typography.bodyMedium
            )
            Text(
                text = detail ?: "${String.format("%.1f", usage)}%",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        Spacer(modifier = Modifier.height(4.dp))
        LinearProgressIndicator(
            progress = (usage / 100).toFloat().coerceIn(0f, 1f),
            modifier = Modifier
                .fillMaxWidth()
                .height(8.dp),
            color = color,
            trackColor = color.copy(alpha = 0.2f)
        )
    }
}

@Composable
fun DashboardItem(label: String, value: String) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = value,
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.primary
        )
        Text(
            text = label,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

private fun formatBytes(bytes: Long?): String {
    if (bytes == null) return "-"
    return when {
        bytes < 1024 -> "$bytes B"
        bytes < 1024 * 1024 -> "${String.format("%.1f", bytes / 1024.0)} KB"
        bytes < 1024 * 1024 * 1024 -> "${String.format("%.1f", bytes / (1024.0 * 1024))} MB"
        else -> "${String.format("%.2f", bytes / (1024.0 * 1024 * 1024))} GB"
    }
}

private fun formatSpeed(bytesPerSecond: Long?): String {
    if (bytesPerSecond == null) return "-"
    return when {
        bytesPerSecond < 1024 -> "$bytesPerSecond B/s"
        bytesPerSecond < 1024 * 1024 -> "${String.format("%.1f", bytesPerSecond / 1024.0)} KB/s"
        else -> "${String.format("%.1f", bytesPerSecond / (1024.0 * 1024))} MB/s"
    }
}

@Composable
fun QuickActionsContent(
    viewModel: QuickActionsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    var showImportDialog by remember { mutableStateOf(false) }
    var showCronDialog by remember { mutableStateOf(false) }
    var importData by remember { mutableStateOf("") }
    var cronExpression by remember { mutableStateOf("") }
    
    Box(modifier = Modifier.fillMaxSize()) {
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // 任务批量操作
            item {
                Card(
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp)
                    ) {
                        Text(
                            text = "任务批量操作",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceEvenly
                        ) {
                            QuickActionButton(
                                text = "全部运行",
                                icon = Icons.Default.PlayArrow,
                                onClick = { /* TODO: 需要获取所有任务ID */ }
                            )
                            QuickActionButton(
                                text = "全部启用",
                                icon = Icons.Default.CheckCircle,
                                onClick = { /* TODO: 需要获取所有任务ID */ }
                            )
                            QuickActionButton(
                                text = "全部禁用",
                                icon = Icons.Default.Block,
                                onClick = { /* TODO: 需要获取所有任务ID */ }
                            )
                        }
                    }
                }
            }
            
            // 导入导出
            item {
                Card(
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp)
                    ) {
                        Text(
                            text = "导入导出",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceEvenly
                        ) {
                            QuickActionButton(
                                text = "导出任务",
                                icon = Icons.Default.FileDownload,
                                onClick = { viewModel.exportTasks() }
                            )
                            QuickActionButton(
                                text = "导入任务",
                                icon = Icons.Default.FileUpload,
                                onClick = { showImportDialog = true }
                            )
                        }
                        
                        // 显示导出的数据
                        uiState.exportedData?.let { data ->
                            Spacer(modifier = Modifier.height(12.dp))
                            Text(
                                text = "导出数据:",
                                style = MaterialTheme.typography.titleSmall
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Surface(
                                modifier = Modifier.fillMaxWidth(),
                                shape = MaterialTheme.shapes.small,
                                color = MaterialTheme.colorScheme.surfaceVariant
                            ) {
                                Text(
                                    text = data,
                                    style = MaterialTheme.typography.bodySmall,
                                    modifier = Modifier.padding(8.dp),
                                    maxLines = 10
                                )
                            }
                        }
                    }
                }
            }
            
            // Cron表达式解析
            item {
                Card(
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp)
                    ) {
                        Text(
                            text = "Cron表达式解析",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        
                        OutlinedTextField(
                            value = cronExpression,
                            onValueChange = { cronExpression = it },
                            label = { Text("Cron表达式") },
                            modifier = Modifier.fillMaxWidth(),
                            singleLine = true,
                            placeholder = { Text("例如: 0 0 * * *") }
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        Button(
                            onClick = { viewModel.parseCron(cronExpression) },
                            enabled = cronExpression.isNotBlank(),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text("解析")
                        }
                        
                        // 显示解析结果
                        uiState.cronNextRuns?.let { nextRuns ->
                            Spacer(modifier = Modifier.height(12.dp))
                            Text(
                                text = "未来5次执行时间:",
                                style = MaterialTheme.typography.titleSmall
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            nextRuns.forEachIndexed { index, run ->
                                Text(
                                    text = "${index + 1}. $run",
                                    style = MaterialTheme.typography.bodySmall
                                )
                            }
                        }
                    }
                }
            }
            
            // 日志清理
            item {
                Card(
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp)
                    ) {
                        Text(
                            text = "日志清理",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceEvenly
                        ) {
                            QuickActionButton(
                                text = "清理7天前日志",
                                icon = Icons.Default.DeleteSweep,
                                onClick = { /* TODO: 需要实现清理指定天数前的日志 */ }
                            )
                            QuickActionButton(
                                text = "清理全部日志",
                                icon = Icons.Default.DeleteForever,
                                onClick = { /* TODO: 需要实现清理全部日志 */ },
                                color = MaterialTheme.colorScheme.error
                            )
                        }
                    }
                }
            }
        }
        
        // 加载指示器
        if (uiState.isLoading) {
            CircularProgressIndicator(
                modifier = Modifier.align(Alignment.Center)
            )
        }
    }
    
    // 导入对话框
    if (showImportDialog) {
        AlertDialog(
            onDismissRequest = { showImportDialog = false },
            title = { Text("导入任务") },
            text = {
                Column {
                    Text("请输入要导入的任务数据（JSON格式）:")
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(
                        value = importData,
                        onValueChange = { importData = it },
                        modifier = Modifier
                            .fillMaxWidth()
                            .heightIn(min = 150.dp),
                        minLines = 5
                    )
                }
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.importTasks(importData)
                        showImportDialog = false
                        importData = ""
                    },
                    enabled = importData.isNotBlank()
                ) {
                    Text("导入")
                }
            },
            dismissButton = {
                TextButton(onClick = { showImportDialog = false }) {
                    Text("取消")
                }
            }
        )
    }
}

@Composable
fun QuickActionButton(
    text: String,
    icon: ImageVector,
    onClick: () -> Unit,
    color: Color = MaterialTheme.colorScheme.primary
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        IconButton(
            onClick = onClick,
            modifier = Modifier
                .size(48.dp)
                .background(
                    color = color.copy(alpha = 0.1f),
                    shape = MaterialTheme.shapes.medium
                )
        ) {
            Icon(
                imageVector = icon,
                contentDescription = text,
                tint = color,
                modifier = Modifier.size(24.dp)
            )
        }
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = text,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurface
        )
    }
}

@Composable
fun StatsContent(
    viewModel: StatsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    
    Box(modifier = Modifier.fillMaxSize()) {
        if (uiState.isLoading && uiState.systemStats == null) {
            CircularProgressIndicator(
                modifier = Modifier.align(Alignment.Center)
            )
        } else if (uiState.error != null && uiState.systemStats == null) {
            Column(
                modifier = Modifier.align(Alignment.Center),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = uiState.error ?: "未知错误",
                    color = MaterialTheme.colorScheme.error
                )
                Spacer(modifier = Modifier.height(16.dp))
                Button(onClick = { viewModel.loadSystemStats() }) {
                    Text("重试")
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // 任务统计卡片
                item {
                    Card(
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp)
                        ) {
                            Text(
                                text = "任务统计",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                            Spacer(modifier = Modifier.height(12.dp))
                            
                            uiState.systemStats?.tasks?.let { tasks ->
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceEvenly
                                ) {
                                    StatItem("总任务数", tasks.total.toString())
                                    StatItem("已启用", tasks.enabled.toString())
                                    StatItem("已禁用", tasks.disabled.toString())
                                    StatItem("运行中", tasks.running.toString())
                                }
                            }
                        }
                    }
                }
                
                // 日志统计卡片
                item {
                    Card(
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp)
                        ) {
                            Text(
                                text = "日志统计",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                            Spacer(modifier = Modifier.height(12.dp))
                            
                            uiState.systemStats?.logs?.let { logs ->
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceEvenly
                                ) {
                                    StatItem("总日志数", logs.total.toString())
                                    StatItem("成功", logs.success.toString())
                                    StatItem("失败", logs.failed.toString())
                                    StatItem("成功率", "${String.format("%.1f", logs.successRate)}%")
                                }
                            }
                        }
                    }
                }
                
                // 脚本统计卡片
                item {
                    Card(
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp)
                        ) {
                            Text(
                                text = "脚本统计",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                            Spacer(modifier = Modifier.height(12.dp))
                            
                            uiState.systemStats?.scripts?.let { scripts ->
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceEvenly
                                ) {
                                    StatItem("总脚本数", scripts.total.toString())
                                }
                            }
                        }
                    }
                }
                
                // 仪表盘数据卡片
                uiState.dashboardData?.let { dashboard ->
                    item {
                        Card(
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Column(
                                modifier = Modifier.padding(16.dp)
                            ) {
                                Text(
                                    text = "今日概览",
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold
                                )
                                Spacer(modifier = Modifier.height(12.dp))
                                
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceEvenly
                                ) {
                                    StatItem("总任务数", dashboard.taskCount?.toString() ?: "0")
                                    StatItem("运行中", dashboard.runningTasks?.toString() ?: "0")
                                    StatItem("今日执行", dashboard.todayLogs?.toString() ?: "0")
                                }
                                
                                Spacer(modifier = Modifier.height(12.dp))
                                
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceEvenly
                                ) {
                                    StatItem("昨日日志", dashboard.yesterdayLogs?.toString() ?: "0")
                                    StatItem("昨日成功", dashboard.yesterdaySuccess?.toString() ?: "0")
                                    StatItem("环境变量", dashboard.envCount?.toString() ?: "0")
                                }
                            }
                        }
                    }
                }
                
                // 登录统计卡片
                uiState.loginStats?.let { loginStats ->
                    item {
                        Card(
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Column(
                                modifier = Modifier.padding(16.dp)
                            ) {
                                Text(
                                    text = "登录统计",
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold
                                )
                                Spacer(modifier = Modifier.height(12.dp))
                                
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceEvenly
                                ) {
                                    StatItem("总登录次数", loginStats.totalLogins?.toString() ?: "0")
                                    StatItem("失败次数", loginStats.failedLogins?.toString() ?: "0")
                                    StatItem("唯一IP数", loginStats.uniqueIps?.toString() ?: "0")
                                }
                            }
                        }
                    }
                }
                
                // 每日统计图表（简化版）
                uiState.dashboardData?.dailyStats?.let { dailyStats ->
                    if (dailyStats.isNotEmpty()) {
                        item {
                            Card(
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Column(
                                    modifier = Modifier.padding(16.dp)
                                ) {
                                    Text(
                                        text = "每日执行统计",
                                        style = MaterialTheme.typography.titleMedium,
                                        fontWeight = FontWeight.Bold
                                    )
                                    Spacer(modifier = Modifier.height(12.dp))
                                    
                                    dailyStats.take(7).forEach { stat ->
                                        Row(
                                            modifier = Modifier
                                                .fillMaxWidth()
                                                .padding(vertical = 4.dp),
                                            horizontalArrangement = Arrangement.SpaceBetween
                                        ) {
                                            Text(
                                                text = stat.date,
                                                style = MaterialTheme.typography.bodySmall
                                            )
                                            Row {
                                                Text(
                                                    text = "成功: ${stat.success}",
                                                    style = MaterialTheme.typography.bodySmall,
                                                    color = MaterialTheme.colorScheme.primary
                                                )
                                                Spacer(modifier = Modifier.width(8.dp))
                                                Text(
                                                    text = "失败: ${stat.failed}",
                                                    style = MaterialTheme.typography.bodySmall,
                                                    color = MaterialTheme.colorScheme.error
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun StatItem(label: String, value: String) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = value,
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.primary
        )
        Text(
            text = label,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
fun ConfigContent(
    viewModel: ConfigViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    var showAddConfigDialog by remember { mutableStateOf(false) }
    var showAddPlatformDialog by remember { mutableStateOf(false) }
    var showAddTokenDialog by remember { mutableStateOf(false) }
    var showDeleteDialog by remember { mutableStateOf<String?>(null) }
    
    Box(modifier = Modifier.fillMaxSize()) {
        if (uiState.isLoading && uiState.configs.isEmpty()) {
            CircularProgressIndicator(
                modifier = Modifier.align(Alignment.Center)
            )
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // 配置列表
                item {
                    Card(
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp)
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = "系统配置",
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold
                                )
                                IconButton(onClick = { showAddConfigDialog = true }) {
                                    Icon(Icons.Default.Add, contentDescription = "添加配置")
                                }
                            }
                            Spacer(modifier = Modifier.height(12.dp))
                            
                            if (uiState.configs.isEmpty()) {
                                Text(
                                    text = "暂无配置",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            } else {
                                uiState.configs.forEach { config ->
                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(vertical = 4.dp),
                                        horizontalArrangement = Arrangement.SpaceBetween,
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Column(modifier = Modifier.weight(1f)) {
                                            Text(
                                                text = config.key,
                                                style = MaterialTheme.typography.bodyMedium,
                                                fontWeight = FontWeight.Medium
                                            )
                                            Text(
                                                text = config.value ?: "",
                                                style = MaterialTheme.typography.bodySmall,
                                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                                maxLines = 1
                                            )
                                        }
                                        IconButton(
                                            onClick = { showDeleteDialog = config.key },
                                            modifier = Modifier.size(32.dp)
                                        ) {
                                            Icon(
                                                Icons.Default.Delete,
                                                contentDescription = "删除",
                                                tint = MaterialTheme.colorScheme.error,
                                                modifier = Modifier.size(18.dp)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // 平台列表
                item {
                    Card(
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp)
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = "平台管理",
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold
                                )
                                IconButton(onClick = { showAddPlatformDialog = true }) {
                                    Icon(Icons.Default.Add, contentDescription = "添加平台")
                                }
                            }
                            Spacer(modifier = Modifier.height(12.dp))
                            
                            if (uiState.platforms.isEmpty()) {
                                Text(
                                    text = "暂无平台",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            } else {
                                uiState.platforms.forEach { platform ->
                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(vertical = 4.dp),
                                        horizontalArrangement = Arrangement.SpaceBetween,
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Column(modifier = Modifier.weight(1f)) {
                                            Text(
                                                text = platform.name,
                                                style = MaterialTheme.typography.bodyMedium,
                                                fontWeight = FontWeight.Medium
                                            )
                                            Text(
                                                text = platform.type ?: "未知类型",
                                                style = MaterialTheme.typography.bodySmall,
                                                color = MaterialTheme.colorScheme.onSurfaceVariant
                                            )
                                        }
                                        IconButton(
                                            onClick = { viewModel.deletePlatform(platform.id) },
                                            modifier = Modifier.size(32.dp)
                                        ) {
                                            Icon(
                                                Icons.Default.Delete,
                                                contentDescription = "删除",
                                                tint = MaterialTheme.colorScheme.error,
                                                modifier = Modifier.size(18.dp)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // 平台Token列表
                item {
                    Card(
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp)
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = "平台Token",
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold
                                )
                                IconButton(onClick = { showAddTokenDialog = true }) {
                                    Icon(Icons.Default.Add, contentDescription = "添加Token")
                                }
                            }
                            Spacer(modifier = Modifier.height(12.dp))
                            
                            if (uiState.platformTokens.isEmpty()) {
                                Text(
                                    text = "暂无Token",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            } else {
                                uiState.platformTokens.forEach { token ->
                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(vertical = 4.dp),
                                        horizontalArrangement = Arrangement.SpaceBetween,
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Column(modifier = Modifier.weight(1f)) {
                                            Text(
                                                text = token.name ?: "未命名",
                                                style = MaterialTheme.typography.bodyMedium,
                                                fontWeight = FontWeight.Medium
                                            )
                                            Text(
                                                text = "平台ID: ${token.platformId}",
                                                style = MaterialTheme.typography.bodySmall,
                                                color = MaterialTheme.colorScheme.onSurfaceVariant
                                            )
                                        }
                                        Row {
                                            Switch(
                                                checked = token.enabled,
                                                onCheckedChange = { enabled ->
                                                    viewModel.togglePlatformToken(token.id, enabled)
                                                },
                                                modifier = Modifier.size(32.dp)
                                            )
                                            IconButton(
                                                onClick = { viewModel.deletePlatformToken(token.id) },
                                                modifier = Modifier.size(32.dp)
                                            ) {
                                                Icon(
                                                    Icons.Default.Delete,
                                                    contentDescription = "删除",
                                                    tint = MaterialTheme.colorScheme.error,
                                                    modifier = Modifier.size(18.dp)
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 添加配置对话框
    if (showAddConfigDialog) {
        AddConfigDialog(
            onDismiss = { showAddConfigDialog = false },
            onAdd = { key, value ->
                viewModel.setConfig(key, value)
                showAddConfigDialog = false
            }
        )
    }
    
    // 添加平台对话框
    if (showAddPlatformDialog) {
        AddPlatformDialog(
            onDismiss = { showAddPlatformDialog = false },
            onAdd = { name, type ->
                viewModel.createPlatform(name, type)
                showAddPlatformDialog = false
            }
        )
    }
    
    // 添加Token对话框
    if (showAddTokenDialog) {
        AddTokenDialog(
            platforms = uiState.platforms,
            onDismiss = { showAddTokenDialog = false },
            onAdd = { platformId, name, token ->
                viewModel.createPlatformToken(platformId, name, token)
                showAddTokenDialog = false
            }
        )
    }
    
    // 删除确认对话框
    showDeleteDialog?.let { key ->
        AlertDialog(
            onDismissRequest = { showDeleteDialog = null },
            title = { Text("确认删除") },
            text = { Text("确定要删除配置「$key」吗？") },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.deleteConfig(key)
                        showDeleteDialog = null
                    },
                    colors = ButtonDefaults.textButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Text("删除")
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
fun AddConfigDialog(
    onDismiss: () -> Unit,
    onAdd: (String, String) -> Unit
) {
    var key by remember { mutableStateOf("") }
    var value by remember { mutableStateOf("") }
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("添加配置") },
        text = {
            Column {
                OutlinedTextField(
                    value = key,
                    onValueChange = { key = it },
                    label = { Text("配置键") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
                Spacer(modifier = Modifier.height(12.dp))
                OutlinedTextField(
                    value = value,
                    onValueChange = { value = it },
                    label = { Text("配置值") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = { onAdd(key, value) },
                enabled = key.isNotBlank() && value.isNotBlank()
            ) {
                Text("添加")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("取消")
            }
        }
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddPlatformDialog(
    onDismiss: () -> Unit,
    onAdd: (String, String) -> Unit
) {
    var name by remember { mutableStateOf("") }
    var type by remember { mutableStateOf("") }
    var expanded by remember { mutableStateOf(false) }
    
    val platformTypes = listOf("jd", "ele", "meituan", "vip", "alipay", "other")
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("添加平台") },
        text = {
            Column {
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("平台名称") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
                Spacer(modifier = Modifier.height(12.dp))
                
                ExposedDropdownMenuBox(
                    expanded = expanded,
                    onExpandedChange = { expanded = !expanded }
                ) {
                    OutlinedTextField(
                        value = type,
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("平台类型") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor()
                    )
                    ExposedDropdownMenu(
                        expanded = expanded,
                        onDismissRequest = { expanded = false }
                    ) {
                        platformTypes.forEach { platformType ->
                            DropdownMenuItem(
                                text = { Text(platformType) },
                                onClick = {
                                    type = platformType
                                    expanded = false
                                }
                            )
                        }
                    }
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = { onAdd(name, type) },
                enabled = name.isNotBlank() && type.isNotBlank()
            ) {
                Text("添加")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("取消")
            }
        }
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddTokenDialog(
    platforms: List<Platform>,
    onDismiss: () -> Unit,
    onAdd: (Int, String, String) -> Unit
) {
    var selectedPlatformId by remember { mutableStateOf<Int?>(null) }
    var name by remember { mutableStateOf("") }
    var token by remember { mutableStateOf("") }
    var expanded by remember { mutableStateOf(false) }
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("添加Token") },
        text = {
            Column {
                ExposedDropdownMenuBox(
                    expanded = expanded,
                    onExpandedChange = { expanded = !expanded }
                ) {
                    OutlinedTextField(
                        value = platforms.find { it.id == selectedPlatformId }?.name ?: "",
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("选择平台") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor()
                    )
                    ExposedDropdownMenu(
                        expanded = expanded,
                        onDismissRequest = { expanded = false }
                    ) {
                        platforms.forEach { platform ->
                            DropdownMenuItem(
                                text = { Text(platform.name) },
                                onClick = {
                                    selectedPlatformId = platform.id
                                    expanded = false
                                }
                            )
                        }
                    }
                }
                Spacer(modifier = Modifier.height(12.dp))
                
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("Token名称") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
                Spacer(modifier = Modifier.height(12.dp))
                
                OutlinedTextField(
                    value = token,
                    onValueChange = { token = it },
                    label = { Text("Token值") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = { selectedPlatformId?.let { onAdd(it, name, token) } },
                enabled = selectedPlatformId != null && name.isNotBlank() && token.isNotBlank()
            ) {
                Text("添加")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("取消")
            }
        }
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsContent(
    onLogout: () -> Unit = {},
    viewModel: SystemViewModel = hiltViewModel(),
    serverConfigViewModel: ServerConfigViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val serverConfigState by serverConfigViewModel.uiState.collectAsStateWithLifecycle()
    var showSystemInfo by remember { mutableStateOf(false) }
    var showAbout by remember { mutableStateOf(false) }
    var showHealthCheck by remember { mutableStateOf(false) }
    var showPanelLog by remember { mutableStateOf(false) }
    var showServerDialog by remember { mutableStateOf(false) }
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp)
    ) {
        Text(
            text = "系统设置",
            style = MaterialTheme.typography.headlineMedium,
            modifier = Modifier.padding(bottom = 16.dp)
        )
        
        // 系统状态卡片
        Card(
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier.padding(16.dp)
            ) {
                Text(
                    text = "系统状态",
                    style = MaterialTheme.typography.titleMedium,
                    modifier = Modifier.padding(bottom = 8.dp)
                )
                
                if (uiState.isLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier.align(Alignment.CenterHorizontally)
                    )
                } else {
                    // 健康检查状态
                    uiState.healthCheckItems?.forEach { item ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 4.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                when (item.status) {
                                    "ok" -> Icons.Default.CheckCircle
                                    "warning" -> Icons.Default.Warning
                                    else -> Icons.Default.Error
                                },
                                contentDescription = null,
                                tint = when (item.status) {
                                    "ok" -> MaterialTheme.colorScheme.primary
                                    "warning" -> MaterialTheme.colorScheme.tertiary
                                    else -> MaterialTheme.colorScheme.error
                                },
                                modifier = Modifier.size(20.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = item.name,
                                style = MaterialTheme.typography.bodyMedium,
                                modifier = Modifier.weight(1f)
                            )
                            Text(
                                text = item.message ?: item.status,
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    Button(
                        onClick = { viewModel.doHealthCheck() },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(Icons.Default.Refresh, contentDescription = null)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("刷新健康检查")
                    }
                }
            }
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // 服务器地址卡片
        Card(
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier.padding(16.dp)
            ) {
                Text(
                    text = "服务器连接",
                    style = MaterialTheme.typography.titleMedium,
                    modifier = Modifier.padding(bottom = 8.dp)
                )
                
                OutlinedCard(
                    modifier = Modifier.fillMaxWidth(),
                    onClick = { showServerDialog = true }
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = "服务器地址",
                                style = MaterialTheme.typography.labelMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = serverConfigState.serverUrl,
                                style = MaterialTheme.typography.bodyLarge
                            )
                        }
                        Icon(
                            Icons.Default.Edit,
                            contentDescription = "修改服务器",
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
        
        // 服务器地址选择对话框
        if (showServerDialog) {
            ServerAddressDialog(
                currentUrl = serverConfigState.serverUrl,
                presetServers = serverConfigState.presetServers,
                historyServers = serverConfigState.serverHistory,
                onDismiss = { showServerDialog = false },
                onSelect = { url ->
                    serverConfigViewModel.updateServerUrl(url)
                    showServerDialog = false
                },
                onDeleteHistory = { url ->
                    serverConfigViewModel.removeServerFromHistory(url)
                },
                onClearHistory = {
                    serverConfigViewModel.clearServerHistory()
                }
            )
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // 统计信息卡片
        Card(
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier.padding(16.dp)
            ) {
                Text(
                    text = "统计信息",
                    style = MaterialTheme.typography.titleMedium,
                    modifier = Modifier.padding(bottom = 8.dp)
                )
                
                uiState.statsData?.let { stats ->
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        StatItem(
                            title = "任务总数",
                            value = "${stats.tasks?.total ?: 0}",
                            icon = Icons.Default.List
                        )
                        StatItem(
                            title = "已启用",
                            value = "${stats.tasks?.enabled ?: 0}",
                            icon = Icons.Default.CheckCircle
                        )
                        StatItem(
                            title = "运行中",
                            value = "${stats.tasks?.running ?: 0}",
                            icon = Icons.Default.PlayArrow
                        )
                    }
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        StatItem(
                            title = "日志总数",
                            value = "${stats.logs?.total ?: 0}",
                            icon = Icons.Default.Article
                        )
                        StatItem(
                            title = "成功率",
                            value = "${String.format("%.1f", stats.logs?.successRate ?: 0.0)}%",
                            icon = Icons.Default.TrendingUp
                        )
                        StatItem(
                            title = "脚本数",
                            value = "${stats.scripts?.total ?: 0}",
                            icon = Icons.Default.Code
                        )
                    }
                } ?: run {
                    Text(
                        text = "加载中...",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // 设置选项卡片
        Card(
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier.padding(16.dp)
            ) {
                SettingItem(
                    icon = Icons.Default.Info,
                    title = "系统信息",
                    subtitle = "查看系统版本和状态",
                    onClick = { showSystemInfo = true }
                )
                Divider(modifier = Modifier.padding(vertical = 8.dp))
                SettingItem(
                    icon = Icons.Default.HealthAndSafety,
                    title = "健康检查",
                    subtitle = "查看系统健康状态详情",
                    onClick = { showHealthCheck = true }
                )
                Divider(modifier = Modifier.padding(vertical = 8.dp))
                SettingItem(
                    icon = Icons.Default.Article,
                    title = "面板日志",
                    subtitle = "查看系统运行日志",
                    onClick = { 
                        viewModel.loadPanelLog()
                        showPanelLog = true 
                    }
                )
                Divider(modifier = Modifier.padding(vertical = 8.dp))
                SettingItem(
                    icon = Icons.Default.Update,
                    title = "检查更新",
                    subtitle = "检查App最新版本",
                    onClick = { /* TODO: 检查更新 */ }
                )
                Divider(modifier = Modifier.padding(vertical = 8.dp))
                SettingItem(
                    icon = Icons.Default.Backup,
                    title = "数据备份",
                    subtitle = "备份任务和配置数据",
                    onClick = { /* TODO: 数据备份 */ }
                )
                Divider(modifier = Modifier.padding(vertical = 8.dp))
                SettingItem(
                    icon = Icons.Default.Security,
                    title = "安全设置",
                    subtitle = "密码修改和安全配置",
                    onClick = { /* TODO: 安全设置 */ }
                )
            }
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Card(
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier.padding(16.dp)
            ) {
                SettingItem(
                    icon = Icons.Default.Help,
                    title = "帮助与反馈",
                    subtitle = "使用帮助和问题反馈",
                    onClick = { /* TODO: 帮助反馈 */ }
                )
                Divider(modifier = Modifier.padding(vertical = 8.dp))
                SettingItem(
                    icon = Icons.Default.Info,
                    title = "关于",
                    subtitle = "App版本和开发者信息",
                    onClick = { showAbout = true }
                )
            }
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Button(
            onClick = onLogout,
            modifier = Modifier.fillMaxWidth(),
            colors = ButtonDefaults.buttonColors(
                containerColor = MaterialTheme.colorScheme.error
            )
        ) {
            Icon(Icons.Default.ExitToApp, contentDescription = null)
            Spacer(modifier = Modifier.width(8.dp))
            Text("退出登录")
        }
    }
    
    // 系统信息弹窗
    if (showSystemInfo) {
        AlertDialog(
            onDismissRequest = { showSystemInfo = false },
            title = { Text("系统信息") },
            text = {
                Column(
                    modifier = Modifier.verticalScroll(rememberScrollState())
                ) {
                    uiState.systemInfo?.let { info ->
                        // 主机信息
                        Text("主机名: ${info.hostname ?: "未知"}", style = MaterialTheme.typography.bodyMedium)
                        Text("机器码: ${info.machineCode ?: "未知"}", style = MaterialTheme.typography.bodyMedium)
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        // CPU信息
                        Text("CPU使用率: ${info.cpuUsage ?: 0}%", style = MaterialTheme.typography.bodyMedium)
                        Text("CPU核心数: ${info.numCpu ?: 0}", style = MaterialTheme.typography.bodyMedium)
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        // 内存信息
                        val memoryTotalGB = (info.memoryTotal ?: 0) / (1024.0 * 1024 * 1024)
                        val memoryUsedGB = (info.memoryUsed ?: 0) / (1024.0 * 1024 * 1024)
                        Text("内存使用率: ${String.format("%.1f", info.memoryUsage ?: 0)}%", style = MaterialTheme.typography.bodyMedium)
                        Text("内存总量: ${String.format("%.2f", memoryTotalGB)} GB", style = MaterialTheme.typography.bodyMedium)
                        Text("内存已用: ${String.format("%.2f", memoryUsedGB)} GB", style = MaterialTheme.typography.bodyMedium)
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        // 磁盘信息
                        val diskTotalGB = (info.diskTotal ?: 0) / (1024.0 * 1024 * 1024)
                        val diskUsedGB = (info.diskUsed ?: 0) / (1024.0 * 1024 * 1024)
                        Text("磁盘使用率: ${String.format("%.1f", info.diskUsage ?: 0)}%", style = MaterialTheme.typography.bodyMedium)
                        Text("磁盘总量: ${String.format("%.2f", diskTotalGB)} GB", style = MaterialTheme.typography.bodyMedium)
                        Text("磁盘已用: ${String.format("%.2f", diskUsedGB)} GB", style = MaterialTheme.typography.bodyMedium)
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        // 网络信息
                        val netRxMB = (info.netRxBytes ?: 0) / (1024.0 * 1024)
                        val netTxMB = (info.netTxBytes ?: 0) / (1024.0 * 1024)
                        Text("网络接收: ${String.format("%.2f", netRxMB)} MB", style = MaterialTheme.typography.bodyMedium)
                        Text("网络发送: ${String.format("%.2f", netTxMB)} MB", style = MaterialTheme.typography.bodyMedium)
                        Text("接收速度: ${info.netRxSpeed ?: 0} B/s", style = MaterialTheme.typography.bodyMedium)
                        Text("发送速度: ${info.netTxSpeed ?: 0} B/s", style = MaterialTheme.typography.bodyMedium)
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        // 系统信息
                        Text("运行时间: ${info.uptime ?: "未知"}", style = MaterialTheme.typography.bodyMedium)
                        Text("Go版本: ${info.goVersion ?: "未知"}", style = MaterialTheme.typography.bodyMedium)
                        Text("操作系统: ${info.os ?: "未知"}", style = MaterialTheme.typography.bodyMedium)
                        Text("架构: ${info.arch ?: "未知"}", style = MaterialTheme.typography.bodyMedium)
                        Text("协程数: ${info.goroutines ?: 0}", style = MaterialTheme.typography.bodyMedium)
                        Text("数据目录: ${info.dataDir ?: "未知"}", style = MaterialTheme.typography.bodyMedium)
                    } ?: run {
                        Text("App版本: 0.0.3")
                        Text("构建版本: 3")
                        Text("最低支持: Android 8.0")
                        Text("目标版本: Android 14")
                        Text("技术栈: Kotlin + Jetpack Compose")
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { showSystemInfo = false }) {
                    Text("确定")
                }
            }
        )
    }
    
    // 健康检查详情弹窗
    if (showHealthCheck) {
        AlertDialog(
            onDismissRequest = { showHealthCheck = false },
            title = { Text("健康检查详情") },
            text = {
                Column {
                    Text(
                        text = "最后检查时间: ${uiState.lastHealthCheckAt ?: "未检查"}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(bottom = 8.dp)
                    )
                    
                    uiState.healthCheckItems?.forEach { item ->
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 4.dp)
                        ) {
                            Column(
                                modifier = Modifier.padding(8.dp)
                            ) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(
                                        when (item.status) {
                                            "ok" -> Icons.Default.CheckCircle
                                            "warning" -> Icons.Default.Warning
                                            else -> Icons.Default.Error
                                        },
                                        contentDescription = null,
                                        tint = when (item.status) {
                                            "ok" -> MaterialTheme.colorScheme.primary
                                            "warning" -> MaterialTheme.colorScheme.tertiary
                                            else -> MaterialTheme.colorScheme.error
                                        },
                                        modifier = Modifier.size(16.dp)
                                    )
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text(
                                        text = item.name,
                                        style = MaterialTheme.typography.titleSmall
                                    )
                                }
                                if (item.message != null) {
                                    Text(
                                        text = item.message,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                                        modifier = Modifier.padding(start = 24.dp)
                                    )
                                }
                            }
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { showHealthCheck = false }) {
                    Text("确定")
                }
            }
        )
    }
    
    // 面板日志弹窗
    if (showPanelLog) {
        AlertDialog(
            onDismissRequest = { showPanelLog = false },
            title = { Text("面板日志") },
            text = {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(max = 400.dp)
                        .verticalScroll(rememberScrollState())
                ) {
                    if (uiState.panelLogs.isNullOrEmpty()) {
                        Text(
                            text = "暂无日志",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    } else {
                        uiState.panelLogs?.forEach { log ->
                            Text(
                                text = log,
                                style = MaterialTheme.typography.bodySmall,
                                modifier = Modifier.padding(vertical = 2.dp)
                            )
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { showPanelLog = false }) {
                    Text("关闭")
                }
            }
        )
    }
    
    // 关于弹窗
    if (showAbout) {
        AlertDialog(
            onDismissRequest = { showAbout = false },
            title = { Text("关于") },
            text = {
                Column {
                    Text("呆呆面板 Android App")
                    Text("版本: 0.0.1")
                    Spacer(modifier = Modifier.height(8.dp))
                    Text("一个功能强大的定时任务管理平台客户端")
                    Spacer(modifier = Modifier.height(8.dp))
                    Text("开源地址:")
                    Text("https://github.com/tall-1997/daidai-panel", 
                        color = MaterialTheme.colorScheme.primary)
                }
            },
            confirmButton = {
                TextButton(onClick = { showAbout = false }) {
                    Text("确定")
                }
            }
        )
    }
}

@Composable
fun StatItem(
    title: String,
    value: String,
    icon: ImageVector
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(
            icon,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.primary,
            modifier = Modifier.size(24.dp)
        )
        Text(
            text = value,
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold
        )
        Text(
            text = title,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
fun SettingItem(
    icon: ImageVector,
    title: String,
    subtitle: String,
    onClick: () -> Unit = {}
) {
    Surface(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                icon,
                contentDescription = null,
                modifier = Modifier.size(24.dp),
                tint = MaterialTheme.colorScheme.primary
            )
            Spacer(modifier = Modifier.width(16.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleSmall
                )
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Icon(
                Icons.Default.ChevronRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
fun TaskItem(
    task: Task,
    onClick: () -> Unit = {},
    onRun: () -> Unit,
    onStop: () -> Unit,
    onEnable: () -> Unit,
    onDisable: () -> Unit,
    onDelete: () -> Unit,
    onGetLogs: (Int) -> Unit,
    taskLogs: List<String>
) {
    var expanded by remember { mutableStateOf(false) }
    var showLogsDialog by remember { mutableStateOf(false) }
    var showDeleteDialog by remember { mutableStateOf(false) }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() }
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = task.name,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        if (task.isPinned) {
                            Spacer(modifier = Modifier.width(8.dp))
                            Icon(
                                Icons.Default.PushPin,
                                contentDescription = "置顶",
                                modifier = Modifier.size(16.dp),
                                tint = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = task.schedule.ifBlank { "无调度" },
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                StatusChip(status = task.status)
            }

            Spacer(modifier = Modifier.height(8.dp))

            // 调度信息
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column {
                    Text(
                        text = "任务类型",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = task.taskType ?: "cron",
                        style = MaterialTheme.typography.bodySmall
                    )
                }
                Column {
                    Text(
                        text = "上次执行",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = task.lastRunAt?.take(19) ?: "未执行",
                        style = MaterialTheme.typography.bodySmall
                    )
                }
                Column {
                    Text(
                        text = "下次执行",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = task.nextRunAt?.take(19) ?: "未安排",
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.End
            ) {
                if (task.isRunning) {
                    IconButton(
                        onClick = onStop,
                        modifier = Modifier.size(32.dp)
                    ) {
                        Icon(
                            Icons.Default.Stop,
                            contentDescription = "停止",
                            tint = MaterialTheme.colorScheme.error
                        )
                    }
                } else {
                    IconButton(
                        onClick = onRun,
                        modifier = Modifier.size(32.dp)
                    ) {
                        Icon(
                            Icons.Default.PlayArrow,
                            contentDescription = "执行",
                            tint = MaterialTheme.colorScheme.primary
                        )
                    }
                }
                IconButton(
                    onClick = { expanded = !expanded },
                    modifier = Modifier.size(32.dp)
                ) {
                    Icon(
                        if (expanded) Icons.Default.ExpandLess else Icons.Default.ExpandMore,
                        contentDescription = "展开"
                    )
                }
            }

            if (expanded) {
                Spacer(modifier = Modifier.height(8.dp))
                Divider()
                Spacer(modifier = Modifier.height(8.dp))

                Text(
                    text = "命令",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = MaterialTheme.shapes.small,
                    color = MaterialTheme.colorScheme.surfaceVariant
                ) {
                    Text(
                        text = task.command,
                        style = MaterialTheme.typography.bodySmall,
                        modifier = Modifier.padding(8.dp)
                    )
                }

                Spacer(modifier = Modifier.height(8.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    OutlinedButton(
                        onClick = if (task.isEnabled) onDisable else onEnable,
                        modifier = Modifier.weight(1f)
                    ) {
                        Icon(
                            if (task.isEnabled) Icons.Default.Pause else Icons.Default.PlayArrow,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = if (task.isEnabled) "禁用" else "启用",
                            style = MaterialTheme.typography.labelSmall
                        )
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                    OutlinedButton(
                        onClick = { showDeleteDialog = true },
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.outlinedButtonColors(
                            contentColor = MaterialTheme.colorScheme.error
                        )
                    ) {
                        Icon(
                            Icons.Default.Delete,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = "删除",
                            style = MaterialTheme.typography.labelSmall
                        )
                    }
                }
            }
        }
    }

    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("确认删除") },
            text = { Text("确定要删除任务「${task.name}」吗？") },
            confirmButton = {
                TextButton(
                    onClick = {
                        showDeleteDialog = false
                        onDelete()
                    },
                    colors = ButtonDefaults.textButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Text("删除")
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = false }) {
                    Text("取消")
                }
            }
        )
    }
}

@Composable
fun StatusChip(status: Double) {
    val (text, color) = when (status) {
        Task.STATUS_DISABLED -> "已禁用" to MaterialTheme.colorScheme.onSurfaceVariant
        Task.STATUS_QUEUED -> "排队中" to MaterialTheme.colorScheme.secondary
        Task.STATUS_ENABLED -> "已启用" to MaterialTheme.colorScheme.tertiary
        Task.STATUS_RUNNING -> "运行中" to MaterialTheme.colorScheme.primary
        else -> "未知" to MaterialTheme.colorScheme.onSurfaceVariant
    }

    Surface(
        shape = MaterialTheme.shapes.small,
        color = color.copy(alpha = 0.1f)
    ) {
        Text(
            text = text,
            color = color,
            style = MaterialTheme.typography.labelSmall,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
        )
    }
}
