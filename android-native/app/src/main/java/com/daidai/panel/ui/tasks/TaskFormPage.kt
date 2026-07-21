package com.daidai.panel.ui.tasks

import androidx.compose.foundation.isSystemInDarkTheme
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Terminal
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TaskFormPage(
    taskId: Int? = null,
    onBack: () -> Unit,
    viewModel: TaskFormViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()
    val isLight = !isSystemInDarkTheme()
    val snackbarHostState = remember { SnackbarHostState() }
    val isEditMode = taskId != null && taskId > 0

    LaunchedEffect(taskId) {
        if (isEditMode) viewModel.loadTask(taskId!!)
    }

    LaunchedEffect(state.error) {
        state.error?.let { snackbarHostState.showSnackbar(it) }
    }

    LaunchedEffect(state.saved) {
        if (state.saved) onBack()
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            TopAppBar(
                title = { Text(if (isEditMode) "编辑任务" else "新建任务") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "返回")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Transparent
                )
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp)
        ) {
            OutlinedTextField(
                value = state.name,
                onValueChange = { viewModel.updateName(it) },
                label = { Text("任务名称") },
                placeholder = { Text("输入任务名称") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = AppColors.primary,
                    cursorColor = AppColors.primary
                )
            )

            Spacer(modifier = Modifier.height(12.dp))

            OutlinedTextField(
                value = state.command,
                onValueChange = { viewModel.updateCommand(it) },
                label = { Text("执行命令") },
                placeholder = { Text("脚本命令或路径") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = AppColors.primary,
                    cursorColor = AppColors.primary
                )
            )

            Spacer(modifier = Modifier.height(12.dp))

            var typeExpanded by remember { mutableStateOf(false) }
            val types = listOf("cron" to "定时任务", "manual" to "手动触发", "startup" to "开机启动")
            ExposedDropdownMenuBox(
                expanded = typeExpanded,
                onExpandedChange = { typeExpanded = it }
            ) {
                OutlinedTextField(
                    value = types.find { it.first == state.type }?.second ?: "手动触发",
                    onValueChange = {},
                    readOnly = true,
                    label = { Text("任务类型") },
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = typeExpanded) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .menuAnchor(),
                    shape = RoundedCornerShape(12.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = AppColors.primary,
                        cursorColor = AppColors.primary
                    )
                )
                ExposedDropdownMenu(expanded = typeExpanded, onDismissRequest = { typeExpanded = false }) {
                    types.forEach { (value, label) ->
                        DropdownMenuItem(
                            text = { Text(label) },
                            onClick = {
                                viewModel.updateType(value)
                                typeExpanded = false
                            }
                        )
                    }
                }
            }

            if (state.type == "cron") {
                Spacer(modifier = Modifier.height(12.dp))
                OutlinedTextField(
                    value = state.cron,
                    onValueChange = { viewModel.updateCron(it) },
                    label = { Text("Cron 表达式") },
                    placeholder = { Text("*/5 * * * *") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = AppColors.primary,
                        cursorColor = AppColors.primary
                    )
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            Row(modifier = Modifier.fillMaxWidth()) {
                OutlinedTextField(
                    value = state.timeout.toString(),
                    onValueChange = { viewModel.updateTimeout(it.toIntOrNull() ?: state.timeout) },
                    label = { Text("超时(秒)") },
                    singleLine = true,
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(12.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = AppColors.primary,
                        cursorColor = AppColors.primary
                    )
                )
                Spacer(modifier = Modifier.width(12.dp))
                OutlinedTextField(
                    value = state.retryCount.toString(),
                    onValueChange = { viewModel.updateRetryCount(it.toIntOrNull() ?: state.retryCount) },
                    label = { Text("重试次数") },
                    singleLine = true,
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(12.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = AppColors.primary,
                        cursorColor = AppColors.primary
                    )
                )
            }

            Spacer(modifier = Modifier.height(12.dp))
            OutlinedTextField(
                value = state.directory,
                onValueChange = { viewModel.updateDirectory(it) },
                label = { Text("工作目录") },
                placeholder = { Text("留空使用默认目录") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = AppColors.primary,
                    cursorColor = AppColors.primary
                )
            )

            Spacer(modifier = Modifier.height(12.dp))
            OutlinedTextField(
                value = state.tags,
                onValueChange = { viewModel.updateTags(it) },
                label = { Text("标签(逗号分隔)") },
                placeholder = { Text("例如：备份,监控") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = AppColors.primary,
                    cursorColor = AppColors.primary
                )
            )

            Spacer(modifier = Modifier.height(24.dp))

            Button(
                onClick = { viewModel.save() },
                enabled = state.name.isNotBlank() && state.command.isNotBlank() && !state.isSaving,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(48.dp),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(containerColor = AppColors.primary)
            ) {
                if (state.isSaving) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        color = AppColors.white,
                        strokeWidth = 2.dp
                    )
                } else {
                    Icon(Icons.Default.Add, contentDescription = null, tint = AppColors.white)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        if (isEditMode) "保存修改" else "创建任务",
                        color = AppColors.white,
                        style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold)
                    )
                }
            }
        }
    }
}
