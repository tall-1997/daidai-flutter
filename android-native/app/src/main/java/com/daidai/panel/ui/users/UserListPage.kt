package com.daidai.panel.ui.users

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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.Refresh
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.daidai.panel.core.theme.AppColors
import com.daidai.panel.data.model.User
import com.daidai.panel.ui.components.GlassCard

@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun UserListPage(
    onBack: () -> Unit,
    viewModel: UserViewModel = hiltViewModel()
) {
    val isLight = !isSystemInDarkTheme()
    val state by viewModel.state.collectAsState()
    var showAddSheet by remember { mutableStateOf(false) }
    var showDeleteDialog by remember { mutableStateOf<User?>(null) }
    var showResetDialog by remember { mutableStateOf<User?>(null) }
    var resetPassword by remember { mutableStateOf("") }
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
                        "用户管理",
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

            if (state.users.isEmpty() && !state.isLoading) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            Icons.Default.People,
                            contentDescription = null,
                            modifier = Modifier.size(64.dp),
                            tint = AppColors.slate400
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            "暂无用户",
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
                    items(state.users, key = { it.id }) { user ->
                        UserCard(
                            user = user,
                            onToggleEnabled = { viewModel.toggleEnabled(user.id, !user.enabled) },
                            onResetPassword = { showResetDialog = user },
                            onDelete = { showDeleteDialog = user }
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
            Icon(Icons.Default.Add, contentDescription = "添加用户")
        }
    }

    if (showAddSheet) {
        AddUserSheet(
            onDismiss = { showAddSheet = false },
            onConfirm = { username, password, role ->
                viewModel.create(username, password, role) { showAddSheet = false }
            }
        )
    }

    showDeleteDialog?.let { user ->
        AlertDialog(
            onDismissRequest = { showDeleteDialog = null },
            title = { Text("确认删除") },
            text = { Text("确定要删除用户「${user.username}」吗？") },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.delete(user.id)
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

    showResetDialog?.let { user ->
        AlertDialog(
            onDismissRequest = { showResetDialog = null },
            title = { Text("重置密码") },
            text = {
                Column {
                    Text("为用户「${user.username}」设置新密码")
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(
                        value = resetPassword,
                        onValueChange = { resetPassword = it },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text("新密码") },
                        singleLine = true,
                        visualTransformation = PasswordVisualTransformation(),
                        shape = RoundedCornerShape(12.dp)
                    )
                }
            },
            confirmButton = {
                TextButton(onClick = {
                    if (resetPassword.isNotBlank()) {
                        viewModel.resetPassword(user.id, resetPassword) {
                            showResetDialog = null
                            resetPassword = ""
                        }
                    }
                }) {
                    Text("确认", color = AppColors.primary)
                }
            },
            dismissButton = {
                TextButton(onClick = { showResetDialog = null; resetPassword = "" }) {
                    Text("取消")
                }
            }
        )
    }
}

@Composable
private fun UserCard(
    user: User,
    onToggleEnabled: () -> Unit,
    onResetPassword: () -> Unit,
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
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(AppColors.primary),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = user.username.take(1).uppercase(),
                    style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.Bold),
                    color = AppColors.white
                )
            }
            Spacer(modifier = Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = user.username,
                    style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.SemiBold),
                    color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                )
                Row {
                    Text(
                        text = if (user.isAdmin) "管理员" else "操作员",
                        style = MaterialTheme.typography.labelSmall,
                        color = AppColors.primary
                    )
                    if (user.lastLoginAt.isNotBlank()) {
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "最后登录: ${user.lastLoginAt}",
                            style = MaterialTheme.typography.labelSmall,
                            color = if (isLight) AppColors.slate400 else AppColors.slate500
                        )
                    }
                }
            }

            Switch(
                checked = user.enabled,
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
                        text = { Text("重置密码") },
                        leadingIcon = { Icon(Icons.Default.Lock, null) },
                        onClick = { showMenu = false; onResetPassword() }
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
private fun AddUserSheet(
    onDismiss: () -> Unit,
    onConfirm: (username: String, password: String, role: Int) -> Unit
) {
    var username by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var role by remember { mutableStateOf(2) }

    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Text(
                "添加用户",
                style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold)
            )
            Spacer(modifier = Modifier.height(16.dp))

            OutlinedTextField(
                value = username,
                onValueChange = { username = it },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("用户名") },
                singleLine = true,
                shape = RoundedCornerShape(12.dp)
            )
            Spacer(modifier = Modifier.height(12.dp))

            OutlinedTextField(
                value = password,
                onValueChange = { password = it },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("密码") },
                singleLine = true,
                visualTransformation = PasswordVisualTransformation(),
                shape = RoundedCornerShape(12.dp)
            )
            Spacer(modifier = Modifier.height(12.dp))

            Text(
                "角色",
                style = MaterialTheme.typography.titleSmall,
                color = if (androidx.compose.foundation.isSystemInDarkTheme()) AppColors.slate400 else AppColors.slate500
            )
            Spacer(modifier = Modifier.height(8.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                androidx.compose.material3.FilterChip(
                    selected = role == 1,
                    onClick = { role = 1 },
                    label = { Text("管理员") }
                )
                androidx.compose.material3.FilterChip(
                    selected = role == 2,
                    onClick = { role = 2 },
                    label = { Text("操作员") }
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
                    onClick = { onConfirm(username, password, role) },
                    enabled = username.isNotBlank() && password.length >= 4,
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
