package com.daidai.panel.ui.dashboard

import androidx.compose.foundation.Canvas
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Terminal
import androidx.compose.material.icons.filled.TaskAlt
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.compose.foundation.background
import com.daidai.panel.core.theme.AppColors
import com.daidai.panel.ui.components.GlassCard
import com.daidai.panel.ui.components.ResourceCard
import coil.compose.AsyncImage

@Composable
fun DashboardPage(
    contentPadding: PaddingValues,
    glassMode: Boolean,
    onNavigate: (String) -> Unit,
    viewModel: DashboardViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()
    val isLight = !isSystemInDarkTheme()

    if (state.isLoading && state.systemInfo.isEmpty()) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(contentPadding),
            contentAlignment = Alignment.Center
        ) {
            CircularProgressIndicator(color = AppColors.primary)
        }
        return
    }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(contentPadding),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Server info header
        item {
            GlassCard(
                modifier = Modifier.fillMaxWidth(),
                glassMode = glassMode,
                padding = PaddingValues(16.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = state.panelTitle,
                            style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold),
                            color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = state.hostname,
                            style = MaterialTheme.typography.bodyMedium,
                            color = if (isLight) AppColors.slate500 else AppColors.slate400
                        )
                        Row {
                            Text(
                                text = state.os,
                                style = MaterialTheme.typography.bodySmall,
                                color = if (isLight) AppColors.slate400 else AppColors.slate500
                            )
                            if (state.uptime.isNotEmpty()) {
                                Text(
                                    text = " | ",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = if (isLight) AppColors.slate300 else AppColors.slate600
                                )
                                Text(
                                    text = "运行 ${state.uptime}",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = if (isLight) AppColors.slate400 else AppColors.slate500
                                )
                            }
                        }
                        if (state.panelVersion.isNotEmpty()) {
                            Text(
                                text = "v${state.panelVersion}",
                                style = MaterialTheme.typography.labelSmall,
                                color = AppColors.primary
                            )
                        }
                    }

                    Box(
                        modifier = Modifier
                            .size(48.dp)
                            .clip(CircleShape),
                        contentAlignment = Alignment.Center
                    ) {
                        val avatarUrl = state.systemInfo["user_avatar"] as? String
                        if (!avatarUrl.isNullOrEmpty()) {
                            AsyncImage(
                                model = avatarUrl,
                                contentDescription = null,
                                modifier = Modifier.fillMaxSize()
                            )
                        } else {
                            val username = state.systemInfo["username"] as? String ?: "U"
                            Box(
                                modifier = Modifier
                                    .fillMaxSize()
                                    .clip(CircleShape)
                                    .background(AppColors.primary),
                                contentAlignment = Alignment.Center
                            ) {
                                Text(
                                    text = username.take(1).uppercase(),
                                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                                    color = AppColors.white
                                )
                            }
                        }
                    }
                }
            }
        }

        // Resource cards
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                ResourceCard(
                    percentage = state.cpuUsage,
                    label = "CPU",
                    glassMode = glassMode,
                    modifier = Modifier.weight(1f),
                    size = 80.dp
                )
                ResourceCard(
                    percentage = state.memoryUsage,
                    label = "内存",
                    glassMode = glassMode,
                    modifier = Modifier.weight(1f),
                    size = 80.dp,
                    subtitle = state.memoryFormatted
                )
                ResourceCard(
                    percentage = state.diskUsage,
                    label = "磁盘",
                    glassMode = glassMode,
                    modifier = Modifier.weight(1f),
                    size = 80.dp,
                    subtitle = state.diskFormatted
                )
            }
        }

        // Task stats
        if (state.totalTasks > 0) {
            item {
                GlassCard(
                    modifier = Modifier.fillMaxWidth(),
                    glassMode = glassMode,
                    padding = PaddingValues(16.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        StatItem("总计", state.totalTasks, AppColors.primary, isLight, Modifier.weight(1f))
                        StatItem("已启用", state.enabledTasks, AppColors.primary, isLight, Modifier.weight(1f))
                        StatItem("运行中", state.runningTasks, AppColors.blue500, isLight, Modifier.weight(1f))
                        StatItem("已禁用", state.disabledTasks, AppColors.slate400, isLight, Modifier.weight(1f))
                    }

                    Spacer(modifier = Modifier.height(12.dp))
                    HorizontalDivider(
                        thickness = 1.dp,
                        color = if (isLight) AppColors.glassDivider else AppColors.slate800
                    )
                    Spacer(modifier = Modifier.height(12.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        StatItem("今日成功", state.todaySuccess, AppColors.primary, isLight, Modifier.weight(1f))
                        StatItem("今日失败", state.todayFailed, AppColors.red500, isLight, Modifier.weight(1f))
                    }
                }
            }
        }

        // Execution trend
        item {
            GlassCard(
                modifier = Modifier.fillMaxWidth(),
                glassMode = glassMode,
                padding = PaddingValues(16.dp)
            ) {
                Text(
                    "7日执行趋势",
                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold),
                    color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                )
                Spacer(modifier = Modifier.height(16.dp))

                val trend = state.executionTrend
                if (trend.isNotEmpty()) {
                    ExecutionTrendChart(
                        data = trend.map { item ->
                            val success = (item["success"] as? Number)?.toInt() ?: 0
                            val failed = (item["failed"] as? Number)?.toInt() ?: 0
                            success to failed
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(160.dp)
                    )
                } else {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(160.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            "暂无数据",
                            style = MaterialTheme.typography.bodySmall,
                            color = AppColors.slate400
                        )
                    }
                }
            }
        }

        // Quick actions
        item {
            GlassCard(
                modifier = Modifier.fillMaxWidth(),
                glassMode = glassMode,
                padding = PaddingValues(16.dp)
            ) {
                Text(
                    "快捷操作",
                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold),
                    color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                )
                Spacer(modifier = Modifier.height(12.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    QuickActionButton(
                        icon = Icons.Default.PlayArrow,
                        label = "运行全部",
                        color = AppColors.primary,
                        onClick = { onNavigate("tasks") },
                        modifier = Modifier.weight(1f)
                    )
                    QuickActionButton(
                        icon = Icons.Default.Terminal,
                        label = "查看日志",
                        color = AppColors.blue500,
                        onClick = { onNavigate("logs") },
                        modifier = Modifier.weight(1f)
                    )
                    QuickActionButton(
                        icon = Icons.Default.TaskAlt,
                        label = "任务管理",
                        color = AppColors.purple500,
                        onClick = { onNavigate("tasks") },
                        modifier = Modifier.weight(1f)
                    )
                }
            }
        }

        item { Spacer(modifier = Modifier.height(16.dp)) }
    }
}

@Composable
private fun StatItem(label: String, value: Int, color: Color, isLight: Boolean, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = value.toString(),
            style = MaterialTheme.typography.titleLarge.copy(
                fontWeight = FontWeight.Bold,
                fontSize = 22.sp
            ),
            color = color,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall.copy(
                fontSize = 11.sp
            ),
            color = if (isLight) AppColors.slate500 else AppColors.slate400,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
    }
}

@Composable
private fun QuickActionButton(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    color: Color,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    TextButton(
        onClick = onClick,
        modifier = modifier
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = color,
                modifier = Modifier.size(28.dp)
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = label,
                style = MaterialTheme.typography.labelMedium,
                color = color
            )
        }
    }
}

@Composable
private fun ExecutionTrendChart(
    data: List<Pair<Int, Int>>,
    modifier: Modifier = Modifier
) {
    val isLight = !isSystemInDarkTheme()
    val successColor = AppColors.primary
    val failedColor = AppColors.red500
    val trackColor = if (isLight) AppColors.slate100 else AppColors.slate800

    val maxVal = data.maxOfOrNull { maxOf(it.first, it.second) } ?: 1

    Canvas(modifier = modifier) {
        val barCount = data.size
        if (barCount == 0) return@Canvas

        val groupWidth = size.width / barCount
        val barWidth = groupWidth * 0.3f
        val maxHeight = size.height * 0.85f

        data.forEachIndexed { index, (success, failed) ->
            val groupX = index * groupWidth + groupWidth / 2

            val successHeight = if (maxVal > 0) maxHeight * success / maxVal else 0f
            drawRoundRect(
                color = successColor,
                topLeft = Offset(groupX - barWidth - 1.dp.toPx(), size.height - successHeight),
                size = Size(barWidth, successHeight),
                cornerRadius = CornerRadius(4.dp.toPx())
            )

            val failedHeight = if (maxVal > 0) maxHeight * failed / maxVal else 0f
            drawRoundRect(
                color = failedColor,
                topLeft = Offset(groupX + 1.dp.toPx(), size.height - failedHeight),
                size = Size(barWidth, failedHeight),
                cornerRadius = CornerRadius(4.dp.toPx())
            )
        }
    }
}
