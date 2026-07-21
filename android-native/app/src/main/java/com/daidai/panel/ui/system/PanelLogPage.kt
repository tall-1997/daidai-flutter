package com.daidai.panel.ui.system

import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
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
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.daidai.panel.core.theme.AppColors
import com.daidai.panel.ui.components.GlassCard
import com.daidai.panel.ui.components.SearchBar

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PanelLogPage(
    onBack: () -> Unit,
    viewModel: SystemViewModel = hiltViewModel()
) {
    val isLight = !isSystemInDarkTheme()
    val state by viewModel.state.collectAsState()
    var searchQuery by remember { mutableStateOf("") }
    var selectedLevel by remember { mutableStateOf("") }
    var showLevelMenu by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        viewModel.loadPanelLogs()
    }

    Column(modifier = Modifier.fillMaxSize()) {
        TopAppBar(
            title = {
                Text(
                    "面板日志",
                    style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold)
                )
            },
            navigationIcon = {
                IconButton(onClick = onBack) {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "返回")
                }
            },
            actions = {
                Box {
                    IconButton(onClick = { showLevelMenu = true }) {
                        Icon(Icons.Default.FilterList, contentDescription = "筛选")
                    }
                    DropdownMenu(
                        expanded = showLevelMenu,
                        onDismissRequest = { showLevelMenu = false }
                    ) {
                        DropdownMenuItem(
                            text = { Text("全部") },
                            onClick = {
                                selectedLevel = ""
                                showLevelMenu = false
                                viewModel.loadPanelLogs(searchQuery, "")
                            }
                        )
                        listOf("info", "warn", "error", "debug").forEach { level ->
                            DropdownMenuItem(
                                text = { Text(level.uppercase()) },
                                onClick = {
                                    selectedLevel = level
                                    showLevelMenu = false
                                    viewModel.loadPanelLogs(searchQuery, level)
                                }
                            )
                        }
                    }
                }
                IconButton(onClick = { viewModel.loadPanelLogs(searchQuery, selectedLevel) }) {
                    Icon(Icons.Default.Refresh, contentDescription = "刷新")
                }
            },
            colors = TopAppBarDefaults.topAppBarColors(
                containerColor = Color.Transparent,
                titleContentColor = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
            )
        )

        SearchBar(
            query = searchQuery,
            onQueryChange = {
                searchQuery = it
                viewModel.loadPanelLogs(it, selectedLevel)
            },
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp),
            placeholder = "搜索日志..."
        )

        Spacer(modifier = Modifier.height(8.dp))

        if (selectedLevel.isNotBlank()) {
            Row(
                modifier = Modifier.padding(horizontal = 16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "筛选: ${selectedLevel.uppercase()}",
                    style = MaterialTheme.typography.bodySmall,
                    color = AppColors.primary
                )
                Spacer(modifier = Modifier.width(8.dp))
                IconButton(
                    onClick = {
                        selectedLevel = ""
                        viewModel.loadPanelLogs(searchQuery, "")
                    },
                    modifier = Modifier.padding(0.dp)
                ) {
                    Icon(
                        Icons.Default.FilterList,
                        contentDescription = "清除筛选",
                        tint = AppColors.slate400
                    )
                }
            }
        }

        if (state.panelLogs.isEmpty() && !state.isLoading) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Text("暂无日志", color = AppColors.slate400)
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                items(state.panelLogs) { log ->
                    LogEntry(log, isLight)
                }
            }
        }
    }
}

@Composable
private fun LogEntry(log: Map<String, Any>, isLight: Boolean) {
    val level = log["level"] as? String ?: "info"
    val message = log["message"] as? String ?: ""
    val time = log["time"] as? String ?: ""

    val levelColor = when (level.lowercase()) {
        "error" -> AppColors.red500
        "warn" -> AppColors.amber500
        "debug" -> AppColors.slate400
        else -> AppColors.primary
    }

    GlassCard(
        modifier = Modifier.fillMaxWidth(),
        padding = PaddingValues(8.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState())
        ) {
            Text(
                text = time,
                style = MaterialTheme.typography.labelSmall.copy(
                    fontFamily = FontFamily.Monospace,
                    fontSize = 11.sp
                ),
                color = if (isLight) AppColors.slate400 else AppColors.slate500
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = "[${level.uppercase()}]",
                style = MaterialTheme.typography.labelSmall.copy(
                    fontFamily = FontFamily.Monospace,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold
                ),
                color = levelColor
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = parseAnsiToAnnotatedString(message),
                style = MaterialTheme.typography.bodySmall.copy(
                    fontFamily = FontFamily.Monospace,
                    fontSize = 12.sp,
                    lineHeight = 18.sp
                )
            )
        }
    }
}

private fun parseAnsiToAnnotatedString(text: String): AnnotatedString {
    return buildAnnotatedString {
        val regex = Regex("\u001B\\[([0-9;]*)m")
        var lastIndex = 0
        var currentColor: Color? = null

        regex.findAll(text).forEach { match ->
            val before = text.substring(lastIndex, match.range.first)
            if (before.isNotEmpty()) {
                withStyle(SpanStyle(color = currentColor ?: Color.Unspecified)) {
                    append(before)
                }
            }

            val code = match.groupValues[1]
            currentColor = when (code) {
                "30" -> Color(0xFF000000)
                "31" -> Color(0xFFEF4444)
                "32" -> Color(0xFF22C55E)
                "33" -> Color(0xFFF59E0B)
                "34" -> Color(0xFF3B82F6)
                "35" -> Color(0xFFA855F7)
                "36" -> Color(0xFF06B6D4)
                "37" -> Color(0xFFFFFFFF)
                "90" -> Color(0xFF6B7280)
                "91" -> Color(0xFFFCA5A5)
                "92" -> Color(0xFF86EFAC)
                "93" -> Color(0xFFFDE68A)
                "94" -> Color(0xFF93C5FD)
                "95" -> Color(0xFFD8B4FE)
                "96" -> Color(0xFF67E8F9)
                "97" -> Color(0xFFFFFFFF)
                "0", "" -> null
                else -> currentColor
            }

            lastIndex = match.range.last + 1
        }

        if (lastIndex < text.length) {
            val remaining = text.substring(lastIndex)
            val cleanText = remaining.replace(regex, "")
            if (cleanText.isNotEmpty()) {
                withStyle(SpanStyle(color = currentColor ?: Color.Unspecified)) {
                    append(cleanText)
                }
            }
        }
    }
}
