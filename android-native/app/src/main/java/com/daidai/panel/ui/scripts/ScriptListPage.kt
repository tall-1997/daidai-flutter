package com.daidai.panel.ui.scripts

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.InsertDriveFile
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Code
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.CreateNewFolder
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.DriveFileMove
import androidx.compose.material.icons.filled.CloudDownload
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.ExpandLess
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.Folder
import androidx.compose.material.icons.filled.FolderOpen
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Terminal
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.daidai.panel.core.theme.AppColors
import com.daidai.panel.ui.components.GlassCard
import com.daidai.panel.ui.components.SearchBar

@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun ScriptListPage(
    onBack: () -> Unit,
    onOpenFile: (String) -> Unit,
    viewModel: ScriptViewModel = hiltViewModel()
) {
    val isLight = !isSystemInDarkTheme()
    val state by viewModel.state.collectAsState()
    var showCreateDirDialog by remember { mutableStateOf(false) }
    var showDeleteDialog by remember { mutableStateOf<String?>(null) }
    var showRenameDialog by remember { mutableStateOf<String?>(null) }
    var showMoveDialog by remember { mutableStateOf<String?>(null) }
    var showCopyDialog by remember { mutableStateOf<String?>(null) }

    Column(modifier = Modifier.fillMaxSize()) {
        TopAppBar(
            title = {
                Text(
                    "脚本管理",
                    style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold)
                )
            },
            navigationIcon = {
                IconButton(onClick = onBack) {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "返回")
                }
            },
            actions = {
                IconButton(onClick = { showCreateDirDialog = true }) {
                    Icon(Icons.Default.CreateNewFolder, contentDescription = "新建目录")
                }
                IconButton(onClick = { viewModel.loadTree() }) {
                    Icon(Icons.Default.Refresh, contentDescription = "刷新")
                }
            },
            colors = TopAppBarDefaults.topAppBarColors(
                containerColor = Color.Transparent,
                titleContentColor = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
            )
        )

        SearchBar(
            query = state.searchQuery,
            onQueryChange = { viewModel.updateSearchQuery(it) },
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp),
            placeholder = "搜索文件..."
        )

        Spacer(modifier = Modifier.height(8.dp))

        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            val filteredTree = if (state.searchQuery.isBlank()) state.tree
            else filterTree(state.tree, state.searchQuery)

            renderTree(
                nodes = filteredTree,
                depth = 0,
                onToggleExpand = { viewModel.toggleExpand(it) },
                onFileClick = { onOpenFile(it) },
                onRename = { showRenameDialog = it },
                onMove = { showMoveDialog = it },
                onCopy = { showCopyDialog = it },
                onDownload = { viewModel.download(it) },
                onDelete = { showDeleteDialog = it },
                isLight = isLight
            )
        }
    }

    if (showCreateDirDialog) {
        var dirName by remember { mutableStateOf("") }
        AlertDialog(
            onDismissRequest = { showCreateDirDialog = false },
            title = { Text("新建目录") },
            text = {
                OutlinedTextField(
                    value = dirName,
                    onValueChange = { dirName = it },
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text("目录名称") },
                    singleLine = true
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    if (dirName.isNotBlank()) {
                        viewModel.createDirectory(dirName)
                        showCreateDirDialog = false
                    }
                }) {
                    Text("创建", color = AppColors.primary)
                }
            },
            dismissButton = {
                TextButton(onClick = { showCreateDirDialog = false }) {
                    Text("取消")
                }
            }
        )
    }

    showDeleteDialog?.let { path ->
        AlertDialog(
            onDismissRequest = { showDeleteDialog = null },
            title = { Text("确认删除") },
            text = { Text("确定要删除「${path.substringAfterLast("/")}」吗？") },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.delete(path)
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

    showRenameDialog?.let { path ->
        var newName by remember { mutableStateOf(path.substringAfterLast("/")) }
        AlertDialog(
            onDismissRequest = { showRenameDialog = null },
            title = { Text("重命名") },
            text = {
                OutlinedTextField(
                    value = newName,
                    onValueChange = { newName = it },
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text("新名称") },
                    singleLine = true
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    if (newName.isNotBlank()) {
                        viewModel.rename(path, newName)
                        showRenameDialog = null
                    }
                }) {
                    Text("确认", color = AppColors.primary)
                }
            },
            dismissButton = {
                TextButton(onClick = { showRenameDialog = null }) {
                    Text("取消")
                }
            }
        )
    }

    showMoveDialog?.let { path ->
        val currentDir = path.substringBeforeLast("/")
        var destination by remember { mutableStateOf(currentDir + "/") }
        AlertDialog(
            onDismissRequest = { showMoveDialog = null },
            title = { Text("移动到") },
            text = {
                OutlinedTextField(
                    value = destination,
                    onValueChange = { destination = it },
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text("目标路径") },
                    singleLine = true
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    if (destination.isNotBlank()) {
                        viewModel.move(path, destination)
                        showMoveDialog = null
                    }
                }) {
                    Text("移动", color = AppColors.primary)
                }
            },
            dismissButton = {
                TextButton(onClick = { showMoveDialog = null }) {
                    Text("取消")
                }
            }
        )
    }

    showCopyDialog?.let { path ->
        val currentDir = path.substringBeforeLast("/")
        val fileName = path.substringAfterLast("/")
        var destination by remember { mutableStateOf(currentDir + "/" + fileName + "_副本") }
        AlertDialog(
            onDismissRequest = { showCopyDialog = null },
            title = { Text("复制到") },
            text = {
                OutlinedTextField(
                    value = destination,
                    onValueChange = { destination = it },
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text("目标路径") },
                    singleLine = true
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    if (destination.isNotBlank()) {
                        viewModel.copy(path, destination)
                        showCopyDialog = null
                    }
                }) {
                    Text("复制", color = AppColors.primary)
                }
            },
            dismissButton = {
                TextButton(onClick = { showCopyDialog = null }) {
                    Text("取消")
                }
            }
        )
    }
}

private fun filterTree(nodes: List<ScriptTreeNode>, query: String): List<ScriptTreeNode> {
    return nodes.mapNotNull { node ->
        val nameMatch = node.name.contains(query, ignoreCase = true)
        val filteredChildren = filterTree(node.children, query)
        when {
            nameMatch -> node
            filteredChildren.isNotEmpty() -> node.copy(children = filteredChildren)
            else -> null
        }
    }
}

private fun androidx.compose.foundation.lazy.LazyListScope.renderTree(
    nodes: List<ScriptTreeNode>,
    depth: Int,
    onToggleExpand: (String) -> Unit,
    onFileClick: (String) -> Unit,
    onRename: (String) -> Unit,
    onMove: ((String) -> Unit)? = null,
    onCopy: ((String) -> Unit)? = null,
    onDownload: ((String) -> Unit)? = null,
    onDelete: (String) -> Unit,
    isLight: Boolean
) {
    nodes.forEach { node ->
        item(key = node.path) {
            ScriptTreeNodeItem(
                node = node,
                depth = depth,
                onToggleExpand = { onToggleExpand(node.path) },
                onFileClick = { onFileClick(node.path) },
                onRename = { onRename(node.path) },
                onMove = onMove?.let { { it(node.path) } },
                onCopy = onCopy?.let { { it(node.path) } },
                onDownload = onDownload?.let { { it(node.path) } },
                onDelete = { onDelete(node.path) },
                isLight = isLight
            )
        }
        if (node.isDirectory && node.isExpanded && node.children.isNotEmpty()) {
            renderTree(
                nodes = node.children,
                depth = depth + 1,
                onToggleExpand = onToggleExpand,
                onFileClick = onFileClick,
                onRename = onRename,
                onMove = onMove,
                onCopy = onCopy,
                onDownload = onDownload,
                onDelete = onDelete,
                isLight = isLight
            )
        }
    }
}

@Composable
private fun ScriptTreeNodeItem(
    node: ScriptTreeNode,
    depth: Int,
    onToggleExpand: () -> Unit,
    onFileClick: () -> Unit,
    onRename: () -> Unit,
    onMove: (() -> Unit)? = null,
    onCopy: (() -> Unit)? = null,
    onDownload: (() -> Unit)? = null,
    onDelete: () -> Unit,
    isLight: Boolean
) {
    var showMenu by remember { mutableStateOf(false) }
    val icon = getFileIcon(node.name, node.isDirectory)

    GlassCard(
        modifier = Modifier
            .fillMaxWidth()
            .padding(start = (depth * 16).dp),
        padding = PaddingValues(horizontal = 12.dp, vertical = 8.dp),
        onClick = if (node.isDirectory) onToggleExpand else onFileClick
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (node.isDirectory) {
                Icon(
                    if (node.isExpanded) Icons.Default.ExpandLess else Icons.Default.ExpandMore,
                    contentDescription = null,
                    tint = if (isLight) AppColors.slate400 else AppColors.slate500,
                    modifier = Modifier.size(20.dp)
                )
            } else {
                Spacer(modifier = Modifier.width(20.dp))
            }

            Spacer(modifier = Modifier.width(4.dp))

            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = if (node.isDirectory) AppColors.amber500 else AppColors.primary,
                modifier = Modifier.size(20.dp)
            )

            Spacer(modifier = Modifier.width(8.dp))

            Text(
                text = node.name,
                style = MaterialTheme.typography.bodyMedium,
                color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.weight(1f)
            )

            Box {
                IconButton(
                    onClick = { showMenu = true },
                    modifier = Modifier.size(24.dp)
                ) {
                    Icon(
                        Icons.Default.MoreVert,
                        contentDescription = "更多",
                        tint = if (isLight) AppColors.slate400 else AppColors.slate500,
                        modifier = Modifier.size(16.dp)
                    )
                }
                DropdownMenu(
                    expanded = showMenu,
                    onDismissRequest = { showMenu = false }
                ) {
                    if (!node.isDirectory) {
                        if (onDownload != null) {
                            DropdownMenuItem(
                                text = { Text("下载") },
                                leadingIcon = { Icon(Icons.Default.CloudDownload, null) },
                                onClick = { showMenu = false; onDownload() }
                            )
                        }
                        if (onMove != null) {
                            DropdownMenuItem(
                                text = { Text("移动") },
                                leadingIcon = { Icon(Icons.Default.DriveFileMove, null) },
                                onClick = { showMenu = false; onMove() }
                            )
                        }
                        if (onCopy != null) {
                            DropdownMenuItem(
                                text = { Text("复制") },
                                leadingIcon = { Icon(Icons.Default.ContentCopy, null) },
                                onClick = { showMenu = false; onCopy() }
                            )
                        }
                    }
                    DropdownMenuItem(
                        text = { Text("重命名") },
                        leadingIcon = { Icon(Icons.Default.Edit, null) },
                        onClick = { showMenu = false; onRename() }
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

private fun getFileIcon(name: String, isDirectory: Boolean): ImageVector {
    if (isDirectory) return Icons.Default.Folder
    return when (name.substringAfterLast(".").lowercase()) {
        "py" -> Icons.Default.Code
        "js", "ts", "jsx", "tsx" -> Icons.Default.Code
        "sh", "bash" -> Icons.Default.Terminal
        "jpg", "jpeg", "png", "gif", "svg" -> Icons.Default.Image
        "json", "yaml", "yml", "toml", "xml" -> Icons.Default.Code
        else -> Icons.AutoMirrored.Filled.InsertDriveFile
    }
}
