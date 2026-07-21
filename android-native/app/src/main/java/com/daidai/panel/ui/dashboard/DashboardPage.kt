package com.daidai.panel.ui.dashboard

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.daidai.panel.core.theme.AppColors
import com.daidai.panel.ui.components.GlassCard
import com.daidai.panel.ui.components.ResourceCard
import coil.compose.AsyncImage
import com.daidai.panel.core.auth.AuthViewModel

@Composable
fun DashboardPage(
    contentPadding: PaddingValues,
    glassMode: Boolean,
    onNavigate: (String) -> Unit,
    viewModel: DashboardViewModel = hiltViewModel(),
    authViewModel: AuthViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()
    val authState by authViewModel.authState.collectAsState()
    val isLight = !isSystemInDarkTheme()
    val username = authState.user?.username ?: ""
    val avatarUrl = authState.user?.avatarUrl

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
        contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 16.dp, bottom = 110.dp)
    ) {
        // Page header
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    if (state.panelTitle.isNotEmpty()) {
                        Text(
                            text = state.panelTitle,
                            style = MaterialTheme.typography.headlineSmall.copy(
                                fontSize = 20.sp,
                                fontWeight = FontWeight.ExtraBold
                            ),
                            color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                        )
                    }
                    if (username.isNotEmpty()) {
                        Text(
                            text = "欢迎，$username",
                            style = MaterialTheme.typography.bodyMedium.copy(fontSize = 14.sp),
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .clip(CircleShape)
                        .border(
                            width = 1.dp,
                            color = if (isLight) AppColors.slate200 else AppColors.slate800,
                            shape = CircleShape
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    if (!avatarUrl.isNullOrEmpty()) {
                        AsyncImage(
                            model = avatarUrl,
                            contentDescription = null,
                            modifier = Modifier.fillMaxSize()
                        )
                    } else {
                        Box(
                            modifier = Modifier
                                .fillMaxSize()
                                .clip(CircleShape)
                                .background(AppColors.primary.copy(alpha = 0.1f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = username.take(1).uppercase().ifEmpty { "?" },
                                style = MaterialTheme.typography.titleMedium.copy(
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 16.sp
                                ),
                                color = AppColors.primary
                            )
                    }
                }
            }
            }
            Spacer(modifier = Modifier.height(24.dp))
        }

        // Server info card
        item {
            GlassCard(
                modifier = Modifier.fillMaxWidth(),
                padding = PaddingValues(16.dp)
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        modifier = Modifier
                            .size(8.dp)
                            .clip(CircleShape)
                            .background(Color(0xFF34C759))
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = state.hostname.ifEmpty { "未知主机" },
                            style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.SemiBold),
                            color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                        )
                        Spacer(modifier = Modifier.height(2.dp))
                        Text(
                            text = if (state.os.isNotEmpty()) "${state.os}  ·  已运行 ${state.uptime}" else "",
                            style = MaterialTheme.typography.bodySmall.copy(fontSize = 12.sp),
                            color = if (isLight) AppColors.slate500 else AppColors.slate400
                        )
                    }
                    if (state.panelVersion.isNotEmpty()) {
                        Text(
                            text = "v${state.panelVersion}",
                            style = MaterialTheme.typography.labelSmall.copy(
                                fontWeight = FontWeight.SemiBold,
                                fontSize = 12.sp
                            ),
                            color = AppColors.primary
                        )
                    }
                }
            }
            Spacer(modifier = Modifier.height(24.dp))
        }

        // System status section
        item {
            SectionTitle("系统状态", isLight)
            Spacer(modifier = Modifier.height(12.dp))
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
                    modifier = Modifier.weight(1f),
                    size = 80.dp
                )
                ResourceCard(
                    percentage = state.memoryUsage,
                    label = "内存",
                    modifier = Modifier.weight(1f),
                    size = 80.dp,
                    subtitle = state.memoryFormatted
                )
            }
            Spacer(modifier = Modifier.height(12.dp))
        }

        item {
            ResourceCard(
                percentage = state.diskUsage,
                label = "磁盘",
                modifier = Modifier.fillMaxWidth(),
                size = 56.dp,
                subtitle = state.diskFormatted,
                horizontal = true
            )
            Spacer(modifier = Modifier.height(24.dp))
        }

        // Task overview section
        if (state.totalTasks > 0) {
            item {
                SectionTitle("任务概览", isLight)
                Spacer(modifier = Modifier.height(12.dp))
            }

            item {
                GlassCard(
                    modifier = Modifier.fillMaxWidth(),
                    padding = PaddingValues(16.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        StatItem("总任务", state.totalTasks, AppColors.primary, isLight, Modifier.weight(1f))
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
                Spacer(modifier = Modifier.height(24.dp))
            }
        }

        // Execution trend section
        item {
            SectionTitle("执行趋势", isLight)
            Spacer(modifier = Modifier.height(12.dp))
        }

        // Trend chart
        item {
            val trend = state.executionTrend
            if (trend.isNotEmpty()) {
                ExecutionTrendChart(
                    data = trend,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(200.dp)
                )
            } else {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(180.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text("暂无数据", style = MaterialTheme.typography.bodySmall, color = AppColors.slate400)
                }
            }
            Spacer(modifier = Modifier.height(24.dp))
        }

        // Quick actions section
        item {
            SectionTitle("快捷操作", isLight)
            Spacer(modifier = Modifier.height(12.dp))
        }

        item {
            val isAdmin = authState.user?.isAdmin == true
            GlassCard(
                modifier = Modifier.fillMaxWidth(),
                padding = PaddingValues(16.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    if (isAdmin) {
                        QuickActionButton(
                            icon = Icons.Default.PlayArrow,
                            label = "新建任务",
                            color = if (isLight) AppColors.slate700 else AppColors.slate300,
                            onClick = { onNavigate("tasks") },
                            modifier = Modifier.weight(1f)
                        )
                        QuickActionButton(
                            icon = Icons.Default.Terminal,
                            label = "脚本管理",
                            color = if (isLight) AppColors.slate700 else AppColors.slate300,
                            onClick = { onNavigate("scripts") },
                            modifier = Modifier.weight(1f)
                        )
                        QuickActionButton(
                            icon = Icons.Default.TaskAlt,
                            label = "订阅管理",
                            color = if (isLight) AppColors.slate700 else AppColors.slate300,
                            onClick = { onNavigate("subscriptions") },
                            modifier = Modifier.weight(1f)
                        )
                        QuickActionButton(
                            icon = Icons.Default.TaskAlt,
                            label = "依赖管理",
                            color = if (isLight) AppColors.slate700 else AppColors.slate300,
                            onClick = { onNavigate("deps") },
                            modifier = Modifier.weight(1f)
                        )
                    } else {
                        QuickActionButton(
                            icon = Icons.Default.TaskAlt,
                            label = "任务",
                            color = if (isLight) AppColors.slate700 else AppColors.slate300,
                            onClick = { onNavigate("tasks") },
                            modifier = Modifier.weight(1f)
                        )
                        QuickActionButton(
                            icon = Icons.Default.TaskAlt,
                            label = "环境变量",
                            color = if (isLight) AppColors.slate700 else AppColors.slate300,
                            onClick = { onNavigate("envs") },
                            modifier = Modifier.weight(1f)
                        )
                        QuickActionButton(
                            icon = Icons.Default.TaskAlt,
                            label = "赞助名单",
                            color = if (isLight) AppColors.slate700 else AppColors.slate300,
                            onClick = { onNavigate("sponsors") },
                            modifier = Modifier.weight(1f)
                        )
                        QuickActionButton(
                            icon = Icons.Default.TaskAlt,
                            label = "设置",
                            color = if (isLight) AppColors.slate700 else AppColors.slate300,
                            onClick = { onNavigate("more") },
                            modifier = Modifier.weight(1f)
                        )
                    }
                }
            }
        }

        item { Spacer(modifier = Modifier.height(16.dp)) }
    }
}

@Composable
private fun SectionTitle(title: String, isLight: Boolean) {
    Text(
        text = title,
        style = MaterialTheme.typography.labelLarge.copy(
            fontSize = 13.sp,
            fontWeight = FontWeight.SemiBold,
            letterSpacing = 0.5.sp
        ),
        color = MaterialTheme.colorScheme.onSurfaceVariant
    )
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
    data: List<Map<String, Any>>,
    modifier: Modifier = Modifier
) {
    val isLight = !isSystemInDarkTheme()
    val successColor = AppColors.primary
    val failedColor = AppColors.red500
    val gridColor = if (isLight) AppColors.slate200.copy(alpha = 0.5f) else AppColors.slate800.copy(alpha = 0.6f)
    val labelColor = if (isLight) AppColors.slate400 else AppColors.slate500
    if (data.isEmpty()) return

    val successValues = data.map { (it["success"] as? Number)?.toFloat() ?: 0f }
    val failedValues = data.map { (it["failed"] as? Number)?.toFloat() ?: 0f }
    val maxVal = (successValues.maxOrNull() ?: 0f).coerceAtLeast((failedValues.maxOrNull() ?: 0f))
    val yMax = (maxVal * 1.3f).coerceAtLeast(5f)
    val gridSteps = 4

    GlassCard(
        modifier = modifier,
        padding = PaddingValues(16.dp)
    ) {
        Column {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    "近7天执行统计",
                    fontSize = 13.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = if (isLight) AppColors.slate700 else AppColors.slate300
                )
                Row {
                    LegendDot(color = successColor, label = "成功", isLight = isLight)
                    Spacer(modifier = Modifier.width(12.dp))
                    LegendDot(color = failedColor, label = "失败", isLight = isLight)
                }
            }
            Spacer(modifier = Modifier.height(12.dp))
            Row(modifier = Modifier.weight(1f)) {
                Column(
                    modifier = Modifier
                        .width(24.dp)
                        .fillMaxSize(),
                    verticalArrangement = Arrangement.SpaceBetween
                ) {
                    for (i in gridSteps downTo 0) {
                        Text(
                            text = (yMax * i / gridSteps).toInt().toString(),
                            fontSize = 9.sp,
                            color = labelColor,
                            modifier = Modifier.align(Alignment.End)
                        )
                    }
                }
                Spacer(modifier = Modifier.width(4.dp))
                Canvas(modifier = Modifier.fillMaxSize()) {
                    val cw = size.width
                    val ch = size.height
                    val xStep = if (data.size > 1) cw / (data.size - 1) else cw / 2

                    for (i in 0..gridSteps) {
                        val y = ch * i / gridSteps
                        drawLine(gridColor, Offset(0f, y), Offset(cw, y), 1.dp.toPx())
                    }

                    if (successValues.any { it > 0 }) drawLineChart(successValues, xStep, ch, yMax, successColor)
                    if (failedValues.any { it > 0 }) drawLineChart(failedValues, xStep, ch, yMax, failedColor)
                }
            }
            Spacer(modifier = Modifier.height(4.dp))
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(start = 28.dp),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                data.forEach { item ->
                    val date = (item["date"] as? String) ?: ""
                    Text(
                        text = if (date.length >= 5) date.substring(5) else date,
                        fontSize = 9.sp,
                        color = labelColor
                    )
                }
            }
        }
    }
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawLineChart(
    values: List<Float>, xStep: Float, chartHeight: Float, yMax: Float, color: Color
) {
    val path = Path()
    values.forEachIndexed { index, value ->
        val x = index * xStep
        val y = chartHeight - (value / yMax * chartHeight)
        if (index == 0) path.moveTo(x, y)
        else {
            val px = (index - 1) * xStep
            val py = chartHeight - (values[index - 1] / yMax * chartHeight)
            path.cubicTo(px + xStep / 2, py, x - xStep / 2, y, x, y)
        }
    }
    val lastX = (values.size - 1) * xStep
    path.lineTo(lastX, chartHeight)
    path.lineTo(0f, chartHeight)
    path.close()
    drawPath(path, color.copy(alpha = 0.15f))

    val linePath = Path()
    values.forEachIndexed { index, value ->
        val x = index * xStep
        val y = chartHeight - (value / yMax * chartHeight)
        if (index == 0) linePath.moveTo(x, y)
        else {
            val px = (index - 1) * xStep
            val py = chartHeight - (values[index - 1] / yMax * chartHeight)
            linePath.cubicTo(px + xStep / 2, py, x - xStep / 2, y, x, y)
        }
    }
    drawPath(linePath, color, style = Stroke(width = 2.dp.toPx(), cap = StrokeCap.Round))
}

@Composable
private fun LegendDot(color: Color, label: String, isLight: Boolean) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Canvas(modifier = Modifier.size(8.dp)) {
            drawCircle(color, radius = 4.dp.toPx())
        }
        Spacer(modifier = Modifier.width(4.dp))
        Text(label, fontSize = 10.sp, color = if (isLight) AppColors.slate500 else AppColors.slate400)
    }
}

@Composable
fun StatItem(
    label: String,
    value: Int,
    color: Color,
    isLight: Boolean,
    modifier: Modifier = Modifier
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = modifier
    ) {
        Text(
            text = value.toString(),
            fontSize = 22.sp,
            fontWeight = FontWeight.Bold,
            color = color
        )
        Text(
            text = label,
            fontSize = 11.sp,
            color = if (isLight) AppColors.slate500 else AppColors.slate400
        )
    }
}
