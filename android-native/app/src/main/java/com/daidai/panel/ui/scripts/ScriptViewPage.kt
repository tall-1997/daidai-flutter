package com.daidai.panel.ui.scripts

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
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Code
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Save
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
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
import androidx.compose.ui.graphics.SolidColor
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
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ScriptViewPage(
    filePath: String,
    onBack: () -> Unit,
    viewModel: ScriptViewModel = hiltViewModel()
) {
    val isLight = !isSystemInDarkTheme()
    val state by viewModel.state.collectAsState()
    var showVersions by remember { mutableStateOf(false) }
    var showRunOutput by remember { mutableStateOf(false) }
    var editedContent by remember { mutableStateOf("") }
    var isEditing by remember { mutableStateOf(false) }
    var highlightedContent by remember { mutableStateOf(AnnotatedString("")) }
    var isHighlighting by remember { mutableStateOf(false) }

    LaunchedEffect(filePath) {
        viewModel.loadContent(filePath)
    }

    LaunchedEffect(state.currentContent) {
        if (!isEditing) {
            editedContent = state.currentContent
        }
        if (state.currentContent.isNotBlank()) {
            isHighlighting = true
            highlightedContent = withContext(Dispatchers.Default) {
                highlightSyntax(state.currentContent)
            }
            isHighlighting = false
        } else {
            highlightedContent = AnnotatedString("")
        }
    }

    val pathParts = filePath.split("/").filter { it.isNotBlank() }

    Column(modifier = Modifier.fillMaxSize()) {
        TopAppBar(
            title = {
                Column {
                    Text(
                        text = filePath.substringAfterLast("/"),
                        style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold),
                        color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                    )
                    Row {
                        pathParts.forEachIndexed { index, part ->
                            Text(
                                text = part,
                                style = MaterialTheme.typography.labelSmall,
                                color = if (index == pathParts.lastIndex) AppColors.primary
                                else if (isLight) AppColors.slate400 else AppColors.slate500
                            )
                            if (index < pathParts.lastIndex) {
                                Text(
                                    text = " / ",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = if (isLight) AppColors.slate300 else AppColors.slate600
                                )
                            }
                        }
                    }
                }
            },
            navigationIcon = {
                IconButton(onClick = onBack) {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "返回")
                }
            },
            actions = {
                IconButton(onClick = {
                    viewModel.format(filePath)
                }) {
                    Icon(Icons.Default.Code, contentDescription = "格式化")
                }
                IconButton(onClick = {
                    viewModel.loadVersions(filePath)
                    showVersions = true
                }) {
                    Icon(Icons.Default.History, contentDescription = "版本历史")
                }
                IconButton(
                    onClick = {
                        isEditing = !isEditing
                    },
                    enabled = !state.isBinary
                ) {
                    Icon(
                        Icons.Default.Save,
                        contentDescription = if (isEditing) "查看" else "编辑",
                        tint = if (isEditing) AppColors.primary else if (isLight) AppColors.slate400 else AppColors.slate500
                    )
                }
            },
            colors = TopAppBarDefaults.topAppBarColors(
                containerColor = Color.Transparent
            )
        )

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Button(
                onClick = {
                    if (isEditing) {
                        viewModel.save(filePath, editedContent)
                    }
                },
                enabled = isEditing && !state.isSaving,
                modifier = Modifier.weight(1f),
                colors = ButtonDefaults.buttonColors(containerColor = AppColors.primary),
                shape = RoundedCornerShape(12.dp)
            ) {
                Icon(Icons.Default.Save, null, modifier = Modifier.padding(end = 4.dp))
                Text(if (state.isSaving) "保存中..." else "保存")
            }

            Button(
                onClick = {
                    viewModel.run(filePath)
                    showRunOutput = true
                },
                enabled = !state.isRunning,
                modifier = Modifier.weight(1f),
                colors = ButtonDefaults.buttonColors(containerColor = AppColors.blue500),
                shape = RoundedCornerShape(12.dp)
            ) {
                Icon(
                    if (state.isRunning) Icons.Default.Stop else Icons.Default.PlayArrow,
                    null,
                    modifier = Modifier.padding(end = 4.dp)
                )
                Text(if (state.isRunning) "运行中..." else "运行")
            }
        }

        GlassCard(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            padding = PaddingValues(0.dp)
        ) {
            if (state.isLoading) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Text("加载中...", color = AppColors.slate400)
                }
            } else if (state.isBinary) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            "二进制文件无法预览",
                            style = MaterialTheme.typography.bodyLarge,
                            color = if (isLight) AppColors.slate700 else AppColors.slate300
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            "请下载后查看",
                            style = MaterialTheme.typography.bodySmall,
                            color = AppColors.slate400
                        )
                    }
                }
            } else if (isEditing) {
                BasicTextField(
                    value = editedContent,
                    onValueChange = {
                        editedContent = it
                        isEditing = true
                    },
                    modifier = Modifier
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState())
                        .horizontalScroll(rememberScrollState())
                        .padding(16.dp),
                    textStyle = MaterialTheme.typography.bodySmall.copy(
                        fontFamily = FontFamily.Monospace,
                        fontSize = 13.sp,
                        lineHeight = 20.sp,
                        color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                    ),
                    cursorBrush = SolidColor(AppColors.primary)
                )
            } else {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState())
                        .horizontalScroll(rememberScrollState())
                        .padding(16.dp)
                ) {
                    if (isHighlighting) {
                        Text(
                            text = state.currentContent,
                            style = MaterialTheme.typography.bodySmall.copy(
                                fontFamily = FontFamily.Monospace,
                                fontSize = 13.sp,
                                lineHeight = 20.sp,
                                color = if (isLight) AppColors.slate400 else AppColors.slate500
                            )
                        )
                    } else {
                        Text(
                            text = highlightedContent,
                            style = MaterialTheme.typography.bodySmall.copy(
                                fontFamily = FontFamily.Monospace,
                                fontSize = 13.sp,
                                lineHeight = 20.sp
                            )
                        )
                    }
                }
            }
        }
    }

    if (showVersions) {
        ModalBottomSheet(onDismissRequest = { showVersions = false }) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                Text(
                    "版本历史",
                    style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold)
                )
                Spacer(modifier = Modifier.height(16.dp))

                if (state.versions.isEmpty()) {
                    Text("暂无版本记录", color = AppColors.slate400)
                } else {
                    LazyColumn {
                        items(state.versions) { version ->
                            GlassCard(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 4.dp),
                                padding = PaddingValues(12.dp)
                            ) {
                                Column {
                                    Text(
                                        text = version["created_at"] as? String ?: "",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = if (isLight) AppColors.slate500 else AppColors.slate400
                                    )
                                    Text(
                                        text = version["message"] as? String ?: "",
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    if (showRunOutput) {
        ModalBottomSheet(onDismissRequest = { showRunOutput = false }) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                Text(
                    "运行输出",
                    style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold)
                )
                Spacer(modifier = Modifier.height(16.dp))

                GlassCard(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(300.dp),
                    padding = PaddingValues(12.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(AppColors.termBg, RoundedCornerShape(12.dp))
                            .padding(8.dp)
                    ) {
                        Text(
                            text = state.runResult.ifBlank { if (state.isRunning) "运行中..." else "暂无输出" },
                            style = MaterialTheme.typography.bodySmall.copy(
                                fontFamily = FontFamily.Monospace,
                                fontSize = 12.sp,
                                color = AppColors.termText
                            ),
                            modifier = Modifier.verticalScroll(rememberScrollState())
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                Button(
                    onClick = { showRunOutput = false },
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(containerColor = AppColors.primary),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Text("关闭")
                }
            }
        }
    }
}

private fun highlightSyntax(code: String): AnnotatedString {
    val keywords = setOf(
        "fun", "val", "var", "class", "object", "if", "else", "when", "for", "while",
        "return", "import", "package", "interface", "abstract", "override", "private",
        "public", "protected", "internal", "data", "sealed", "enum", "companion",
        "def", "from", "import", "class", "if", "elif", "else", "for", "while",
        "return", "try", "except", "finally", "with", "as", "in", "not", "and", "or",
        "function", "const", "let", "var", "if", "else", "for", "while", "return",
        "async", "await", "import", "export", "default", "class", "extends", "new",
        "echo", "function", "if", "else", "for", "while", "return", "class", "public",
        "private", "protected", "static", "void", "int", "string", "bool", "true", "false",
        "null", "None", "True", "False", "undefined", "this", "self", "super"
    )

    return buildAnnotatedString {
        val lines = code.split("\n")
        lines.forEachIndexed { lineIndex, line ->
            if (lineIndex > 0) append("\n")

            var i = 0
            while (i < line.length) {
                val ch = line[i]

                if (ch == '#' || (ch == '/' && i + 1 < line.length && line[i + 1] == '/') ||
                    (ch == '/' && i + 1 < line.length && line[i + 1] == '*')
                ) {
                    withStyle(SpanStyle(color = AppColors.slate400)) {
                        append(line.substring(i))
                    }
                    i = line.length
                } else if (ch == '"' || ch == '\'') {
                    val quote = ch
                    var end = i + 1
                    while (end < line.length && line[end] != quote) {
                        if (line[end] == '\\') end++
                        end++
                    }
                    if (end < line.length) end++
                    withStyle(SpanStyle(color = AppColors.termGreen)) {
                        append(line.substring(i, end))
                    }
                    i = end
                } else if (ch.isDigit()) {
                    var end = i
                    while (end < line.length && (line[end].isDigit() || line[end] == '.')) end++
                    withStyle(SpanStyle(color = AppColors.termBlue)) {
                        append(line.substring(i, end))
                    }
                    i = end
                } else if (ch.isLetter() || ch == '_') {
                    var end = i
                    while (end < line.length && (line[end].isLetterOrDigit() || line[end] == '_')) end++
                    val word = line.substring(i, end)
                    if (keywords.contains(word)) {
                        withStyle(SpanStyle(color = AppColors.purple500)) {
                            append(word)
                        }
                    } else {
                        append(word)
                    }
                    i = end
                } else {
                    append(ch)
                    i++
                }
            }
        }
    }
}
