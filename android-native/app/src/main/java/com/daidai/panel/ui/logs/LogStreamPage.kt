package com.daidai.panel.ui.logs

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.daidai.panel.core.theme.AppColors
import com.daidai.panel.ui.components.BadgeStatus
import com.daidai.panel.ui.components.GlassCard
import com.daidai.panel.ui.components.StatusBadge

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LogStreamPage(
    onBack: () -> Unit,
    viewModel: LogStreamViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()
    val isLight = !isSystemInDarkTheme()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("日志详情") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "返回")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = if (isLight) AppColors.primaryContainer else AppColors.primaryDark
                )
            )
        }
    ) { innerPadding ->
        if (state.isLoading && state.logLines.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(color = AppColors.primary)
            }
            return@Scaffold
        }

        if (state.error != null && state.logLines.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = state.error ?: "未知错误",
                    style = MaterialTheme.typography.bodyLarge,
                    color = AppColors.red500
                )
            }
            return@Scaffold
        }

        val log = state.log
        val content = state.content

        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            if (log != null) {
                item {
                    GlassCard(
                        modifier = Modifier.fillMaxWidth(),
                        glassMode = false,
                        padding = androidx.compose.foundation.layout.PaddingValues(16.dp)
                    ) {
                        Column {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text(
                                    text = log.taskName.ifEmpty { "任务#${log.taskId}" },
                                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold),
                                    color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                                )
                                val badgeStatus = when {
                                    log.isRunning -> BadgeStatus.RUNNING
                                    log.isSuccess -> BadgeStatus.SUCCESS
                                    log.isFailed -> BadgeStatus.FAILED
                                    log.status == 3 -> BadgeStatus.FAILED
                                    else -> BadgeStatus.DISABLED
                                }
                                StatusBadge(status = badgeStatus)
                            }

                            Spacer(modifier = Modifier.height(12.dp))
                            HorizontalDivider(color = if (isLight) AppColors.slate200 else AppColors.slate700)
                            Spacer(modifier = Modifier.height(12.dp))

                            val statusText = if (state.isDone) state.status else log.statusText
                            InfoRow("状态", statusText, isLight)
                            if (state.durationText.isNotEmpty()) {
                                InfoRow("耗时", state.durationText, isLight)
                            }
                            if (log.startedAt.isNotEmpty()) {
                                InfoRow("开始时间", log.startedAt, isLight)
                            }
                            if (log.endedAt.isNotEmpty()) {
                                InfoRow("结束时间", log.endedAt, isLight)
                            }
                        }
                    }
                }
            } else if (state.logLines.isEmpty()) {
                item {
                    Box(
                        modifier = Modifier.fillMaxWidth().height(200.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "日志不存在",
                            style = MaterialTheme.typography.bodyLarge,
                            color = AppColors.slate500
                        )
                    }
                }
            } else {
                item {
                    Text(
                        text = "日志 #${viewModel.logIdValue}",
                        style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold),
                        color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                    )
                }
            }

            if (content.isNotEmpty()) {
                item {
                    GlassCard(
                        modifier = Modifier.fillMaxWidth(),
                        glassMode = false,
                        padding = androidx.compose.foundation.layout.PaddingValues(16.dp)
                    ) {
                        Column {
                            Text(
                                text = "日志内容",
                                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold),
                                color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                            )
                            Spacer(modifier = Modifier.height(8.dp))

                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = if (isLight) AppColors.slate50 else AppColors.slate800,
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Text(
                                    text = content,
                                    style = MaterialTheme.typography.bodySmall.copy(
                                        fontFamily = FontFamily.Monospace,
                                        fontSize = 12.sp,
                                        lineHeight = 18.sp
                                    ),
                                    color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface,
                                    modifier = Modifier.padding(12.dp)
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
private fun InfoRow(label: String, value: String, isLight: Boolean) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = if (isLight) AppColors.slate500 else AppColors.slate400
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Medium),
            color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
        )
    }
}
