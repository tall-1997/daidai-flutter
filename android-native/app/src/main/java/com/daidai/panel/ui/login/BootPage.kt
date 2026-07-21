package com.daidai.panel.ui.login

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.daidai.panel.core.theme.AppColors

@Composable
fun BootPage(
    onNavigateToServerConfig: () -> Unit,
    onNavigateToLogin: () -> Unit,
    onNavigateToMain: () -> Unit,
    bootViewModel: BootViewModel = hiltViewModel()
) {
    val state by bootViewModel.state

    val infiniteTransition = rememberInfiniteTransition(label = "boot_pulse")
    val logoAlpha by infiniteTransition.animateFloat(
        initialValue = 0.6f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(1200, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "logo_alpha"
    )

    LaunchedEffect(Unit) {
        bootViewModel.checkBootState()
    }

    LaunchedEffect(state) {
        when (state) {
            is BootState.NoServer -> onNavigateToLogin()
            is BootState.Authenticated -> onNavigateToMain()
            is BootState.NeedLogin -> onNavigateToLogin()
            is BootState.Loading -> {}
            is BootState.Error -> {}
        }
    }

    val isLight = !isSystemInDarkTheme()

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                if (isLight) AppColors.lightBackground else AppColors.darkBackground
            ),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Box(
                modifier = Modifier
                    .size(100.dp)
                    .alpha(logoAlpha)
                    .clip(CircleShape)
                    .background(AppColors.primary),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "DD",
                    style = MaterialTheme.typography.headlineLarge.copy(
                        fontWeight = FontWeight.Bold,
                        fontSize = 36.sp
                    ),
                    color = AppColors.white
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            Text(
                text = "呆呆面板",
                style = MaterialTheme.typography.headlineMedium.copy(
                    fontWeight = FontWeight.Bold
                ),
                color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "DaiDai Panel",
                style = MaterialTheme.typography.bodyMedium,
                color = if (isLight) AppColors.slate400 else AppColors.slate500
            )

            Spacer(modifier = Modifier.height(48.dp))

            if (state is BootState.Loading) {
                CircularProgressIndicator(
                    color = AppColors.primary,
                    strokeWidth = 3.dp,
                    modifier = Modifier.size(32.dp)
                )
            }

            if (state is BootState.Error) {
                Text(
                    text = (state as BootState.Error).message,
                    style = MaterialTheme.typography.bodySmall,
                    color = AppColors.red500,
                    modifier = Modifier.padding(horizontal = 32.dp)
                )
                Spacer(modifier = Modifier.height(16.dp))
                Row(
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 32.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    OutlinedButton(
                        onClick = onNavigateToServerConfig,
                        modifier = Modifier.weight(1f)
                    ) {
                        Text("修改地址")
                    }
                    Button(
                        onClick = { bootViewModel.checkBootState() },
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.buttonColors(containerColor = AppColors.primary)
                    ) {
                        Text("重试")
                    }
                }
            }
        }
    }
}
