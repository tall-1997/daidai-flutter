package com.daidai.panel.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Fingerprint
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.daidai.panel.core.theme.AppColors
import com.daidai.panel.ui.components.GlassCard

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppLockSettingsPage(
    onBack: () -> Unit
) {
    val isLight = !isSystemInDarkTheme()
    var lockEnabled by remember { mutableStateOf(false) }
    var lockType by remember { mutableIntStateOf(0) }
    var password by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") }
    var biometricEnabled by remember { mutableStateOf(false) }
    val patternPoints = remember { mutableStateListOf<Int>() }
    var setupStep by remember { mutableIntStateOf(0) }

    Column(modifier = Modifier.fillMaxSize()) {
        TopAppBar(
            title = {
                Text(
                    "应用锁",
                    style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold)
                )
            },
            navigationIcon = {
                IconButton(onClick = onBack) {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "返回")
                }
            },
            colors = TopAppBarDefaults.topAppBarColors(
                containerColor = Color.Transparent,
                titleContentColor = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
            )
        )

        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item {
                GlassCard(
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = "启用应用锁",
                                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold),
                                color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                            )
                            Text(
                                text = "每次打开应用时需要验证身份",
                                style = MaterialTheme.typography.bodySmall,
                                color = if (isLight) AppColors.slate500 else AppColors.slate400
                            )
                        }
                        Switch(
                            checked = lockEnabled,
                            onCheckedChange = { lockEnabled = it },
                            colors = SwitchDefaults.colors(
                                checkedThumbColor = AppColors.white,
                                checkedTrackColor = AppColors.primary,
                                uncheckedThumbColor = if (isLight) AppColors.slate400 else AppColors.slate500,
                                uncheckedTrackColor = if (isLight) AppColors.slate200 else AppColors.slate700
                            )
                        )
                    }
                }
            }

            if (lockEnabled) {
                item {
                    GlassCard(
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        Column {
                            Text(
                                text = "锁定类型",
                                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold),
                                color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                            )
                            Spacer(modifier = Modifier.height(12.dp))
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                FilterChip(
                                    selected = lockType == 0,
                                    onClick = { lockType = 0 },
                                    label = { Text("密码锁") },
                                    modifier = Modifier.weight(1f),
                                    shape = RoundedCornerShape(12.dp),
                                    colors = FilterChipDefaults.filterChipColors(
                                        selectedContainerColor = AppColors.primary,
                                        selectedLabelColor = AppColors.white,
                                        containerColor = if (isLight) AppColors.slate100 else AppColors.slate800
                                    )
                                )
                                FilterChip(
                                    selected = lockType == 1,
                                    onClick = { lockType = 1 },
                                    label = { Text("图案锁") },
                                    modifier = Modifier.weight(1f),
                                    shape = RoundedCornerShape(12.dp),
                                    colors = FilterChipDefaults.filterChipColors(
                                        selectedContainerColor = AppColors.primary,
                                        selectedLabelColor = AppColors.white,
                                        containerColor = if (isLight) AppColors.slate100 else AppColors.slate800
                                    )
                                )
                            }
                        }
                    }
                }

                if (lockType == 0) {
                    item {
                        GlassCard(
                            modifier = Modifier.fillMaxWidth(),
                        ) {
                            Column {
                                Text(
                                    text = if (setupStep == 0) "设置密码" else "确认密码",
                                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold),
                                    color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                                )
                                Spacer(modifier = Modifier.height(12.dp))
                                OutlinedTextField(
                                    value = if (setupStep == 0) password else confirmPassword,
                                    onValueChange = {
                                        if (setupStep == 0) password = it else confirmPassword = it
                                    },
                                    modifier = Modifier.fillMaxWidth(),
                                    placeholder = { Text("请输入密码") },
                                    visualTransformation = PasswordVisualTransformation(),
                                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                                    singleLine = true,
                                    shape = RoundedCornerShape(12.dp),
                                    colors = OutlinedTextFieldDefaults.colors(
                                        focusedBorderColor = AppColors.primary,
                                        cursorColor = AppColors.primary
                                    )
                                )
                                Spacer(modifier = Modifier.height(8.dp))
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.End
                                ) {
                                    if (setupStep == 1) {
                                        TextButton(onClick = { setupStep = 0 }) {
                                            Text("返回")
                                        }
                                    }
                                    Button(
                                        onClick = {
                                            if (setupStep == 0 && password.length >= 4) {
                                                setupStep = 1
                                            } else if (setupStep == 1 && password == confirmPassword) {
                                                setupStep = 0
                                            }
                                        },
                                        colors = ButtonDefaults.buttonColors(
                                            containerColor = AppColors.primary
                                        ),
                                        shape = RoundedCornerShape(12.dp)
                                    ) {
                                        Text(if (setupStep == 0) "下一步" else "确认")
                                    }
                                }
                            }
                        }
                    }
                } else {
                    item {
                        GlassCard(
                            modifier = Modifier.fillMaxWidth(),
                        ) {
                            Column(
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                Text(
                                    text = "绘制解锁图案",
                                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold),
                                    color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                                )
                                Spacer(modifier = Modifier.height(16.dp))
                                PatternGrid(
                                    points = patternPoints,
                                    onPatternComplete = { points ->
                                        patternPoints.clear()
                                        patternPoints.addAll(points)
                                    }
                                )
                                Spacer(modifier = Modifier.height(8.dp))
                                TextButton(onClick = { patternPoints.clear() }) {
                                    Text("重新绘制")
                                }
                            }
                        }
                    }
                }

                item {
                    GlassCard(
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                Icons.Default.Fingerprint,
                                contentDescription = null,
                                tint = AppColors.primary,
                                modifier = Modifier.size(24.dp)
                            )
                            Spacer(modifier = Modifier.width(12.dp))
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = "生物识别",
                                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold),
                                    color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                                )
                                Text(
                                    text = "使用指纹或面部识别解锁",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = if (isLight) AppColors.slate500 else AppColors.slate400
                                )
                            }
                            Switch(
                                checked = biometricEnabled,
                                onCheckedChange = { biometricEnabled = it },
                                colors = SwitchDefaults.colors(
                                    checkedThumbColor = AppColors.white,
                                    checkedTrackColor = AppColors.primary
                                )
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun PatternGrid(
    points: List<Int>,
    onPatternComplete: (List<Int>) -> Unit
) {
    val isLight = !isSystemInDarkTheme()
    val selectedPoints = remember { mutableStateListOf<Int>() }

    Box(
        modifier = Modifier
            .size(240.dp)
            .clip(RoundedCornerShape(16.dp))
            .background(if (isLight) AppColors.slate50 else AppColors.slate900)
            .border(1.dp, if (isLight) AppColors.slate200 else AppColors.slate700, RoundedCornerShape(16.dp))
            .padding(24.dp)
    ) {
        Column(
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            for (row in 0..2) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    for (col in 0..2) {
                        val index = row * 3 + col
                        val isSelected = points.contains(index) || selectedPoints.contains(index)
                        Box(
                            modifier = Modifier
                                .size(48.dp)
                                .clip(CircleShape)
                                .background(
                                    if (isSelected) AppColors.primary
                                    else if (isLight) AppColors.slate200 else AppColors.slate700
                                )
                                .clickable {
                                    if (!selectedPoints.contains(index)) {
                                        selectedPoints.add(index)
                                        if (selectedPoints.size == 9) {
                                            onPatternComplete(selectedPoints.toList())
                                        }
                                    }
                                },
                            contentAlignment = Alignment.Center
                        ) {
                            if (isSelected) {
                                Box(
                                    modifier = Modifier
                                        .size(12.dp)
                                        .clip(CircleShape)
                                        .background(AppColors.white)
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
