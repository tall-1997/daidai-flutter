package com.daidai.panel.ui.components

import androidx.compose.foundation.Canvas
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
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.daidai.panel.core.theme.AppColors

@Composable
fun ResourceCard(
    percentage: Float,
    label: String,
    modifier: Modifier = Modifier,
    size: Dp = 100.dp,
    strokeWidth: Dp = 8.dp,
    subtitle: String = "",
    horizontal: Boolean = false
) {
    val isLight = !isSystemInDarkTheme()
    val progressColor = when {
        percentage < 60f -> AppColors.primary
        percentage < 80f -> AppColors.amber500
        else -> AppColors.red500
    }
    val trackColor = if (isLight) AppColors.slate200 else AppColors.slate800

    if (horizontal) {
        GlassCard(
            modifier = modifier,
            padding = androidx.compose.foundation.layout.PaddingValues(12.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
            ) {
                Box(
                    contentAlignment = androidx.compose.ui.Alignment.Center,
                    modifier = Modifier.size(size)
                ) {
                    Canvas(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(strokeWidth / 2)
                    ) {
                        val strokePx = strokeWidth.toPx()
                        val arcSize = Size(
                            this.size.width - strokePx,
                            this.size.height - strokePx
                        )
                        val topLeft = Offset(strokePx / 2, strokePx / 2)

                        drawArc(
                            color = trackColor,
                            startAngle = -90f,
                            sweepAngle = 360f,
                            useCenter = false,
                            topLeft = topLeft,
                            size = arcSize,
                            style = Stroke(width = strokePx, cap = StrokeCap.Round)
                        )
                        drawArc(
                            color = progressColor,
                            startAngle = -90f,
                            sweepAngle = 360f * (percentage / 100f).coerceIn(0f, 1f),
                            useCenter = false,
                            topLeft = topLeft,
                            size = arcSize,
                            style = Stroke(width = strokePx, cap = StrokeCap.Round)
                        )
                    }

                    Text(
                        text = "${percentage.toInt()}%",
                        style = MaterialTheme.typography.bodySmall.copy(
                            fontWeight = FontWeight.Bold
                        ),
                        color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                    )
                }

                Spacer(modifier = Modifier.width(12.dp))

                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = label,
                        style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Medium),
                        color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    LinearProgressIndicator(
                        progress = { (percentage / 100f).coerceIn(0f, 1f) },
                        modifier = Modifier.fillMaxWidth().height(6.dp),
                        color = progressColor,
                        trackColor = trackColor,
                    )
                    if (subtitle.isNotEmpty()) {
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = subtitle,
                            style = MaterialTheme.typography.labelSmall.copy(fontSize = 11.sp),
                            color = if (isLight) AppColors.slate500 else AppColors.slate400
                        )
                    }
                }
            }
        }
        return
    }

    GlassCard(
        modifier = modifier,
        padding = androidx.compose.foundation.layout.PaddingValues(12.dp)
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
            modifier = Modifier.fillMaxWidth()
        ) {
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier.size(size)
            ) {
                Canvas(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(strokeWidth / 2)
                ) {
                    val strokePx = strokeWidth.toPx()
                    val arcSize = Size(
                        this.size.width - strokePx,
                        this.size.height - strokePx
                    )
                    val topLeft = Offset(strokePx / 2, strokePx / 2)

                    drawArc(
                        color = trackColor,
                        startAngle = -90f,
                        sweepAngle = 360f,
                        useCenter = false,
                        topLeft = topLeft,
                        size = arcSize,
                        style = Stroke(width = strokePx, cap = StrokeCap.Round)
                    )
                    drawArc(
                        color = progressColor,
                        startAngle = -90f,
                        sweepAngle = 360f * (percentage / 100f).coerceIn(0f, 1f),
                        useCenter = false,
                        topLeft = topLeft,
                        size = arcSize,
                        style = Stroke(width = strokePx, cap = StrokeCap.Round)
                    )
                }

                Text(
                    text = "${percentage.toInt()}%",
                    style = MaterialTheme.typography.titleMedium.copy(
                        fontWeight = FontWeight.Bold,
                        fontSize = 16.sp
                    ),
                    color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                )
            }

            Text(
                text = label,
                style = MaterialTheme.typography.bodySmall,
                color = if (isLight) AppColors.slate500 else AppColors.slate400,
                modifier = Modifier.padding(top = 4.dp)
            )

            if (subtitle.isNotEmpty()) {
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.labelSmall.copy(fontSize = 9.sp),
                    color = if (isLight) AppColors.slate400 else AppColors.slate500,
                    modifier = Modifier.padding(top = 2.dp),
                    maxLines = 1
                )
            }
        }
    }
}
