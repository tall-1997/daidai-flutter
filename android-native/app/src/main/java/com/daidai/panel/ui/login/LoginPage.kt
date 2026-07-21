package com.daidai.panel.ui.login

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.Language
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CheckboxDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
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
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.daidai.panel.core.auth.AuthStatus
import com.daidai.panel.core.auth.AuthViewModel
import com.daidai.panel.core.theme.AppColors
import com.daidai.panel.ui.components.GlassCard

@Composable
fun LoginPage(
    needsServerUrl: Boolean = false,
    onLoginSuccess: () -> Unit,
    onNavigateToServerConfig: () -> Unit,
    authViewModel: AuthViewModel = hiltViewModel(),
    loginViewModel: LoginViewModel = hiltViewModel()
) {
    val authState by authViewModel.authState.collectAsState()
    val loginState by loginViewModel.loginState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }
    val isLight = !isSystemInDarkTheme()
    var isLoginLoading by remember { mutableStateOf(false) }

    LaunchedEffect(authState.status) {
        if (authState.status == AuthStatus.AUTHENTICATED) {
            isLoginLoading = false
            onLoginSuccess()
        }
    }

    // Sync TOTP visibility from auth state
    LaunchedEffect(authState.needTotp) {
        if (authState.needTotp) {
            loginViewModel.showTotpField()
            isLoginLoading = false
        }
    }

    // Initialize auth state if still UNKNOWN
    LaunchedEffect(Unit) {
        if (authState.status == AuthStatus.UNKNOWN) {
            authViewModel.checkAuthStatus()
        }
    }

    LaunchedEffect(authState.error) {
        authState.error?.let {
            isLoginLoading = false
            snackbarHostState.showSnackbar(it)
            authViewModel.clearError()
        }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        containerColor = if (isLight) AppColors.lightBackground else AppColors.darkBackground
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentAlignment = Alignment.Center
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 32.dp)
                    .verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Box(
                    modifier = Modifier
                        .size(80.dp)
                        .clip(CircleShape)
                        .background(AppColors.primary),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        "DD",
                        style = MaterialTheme.typography.headlineMedium.copy(
                            fontWeight = FontWeight.Bold
                        ),
                        color = AppColors.white
                    )
                }

                Spacer(modifier = Modifier.height(16.dp))

                Text(
                    "呆呆面板",
                    style = MaterialTheme.typography.headlineSmall.copy(fontWeight = FontWeight.Bold),
                    color = if (isLight) AppColors.lightOnSurface else AppColors.darkOnSurface
                )

                Spacer(modifier = Modifier.height(32.dp))

                // Server URL input when no server configured
                if (needsServerUrl) {
                    OutlinedTextField(
                        value = loginState.directServerUrl,
                        onValueChange = { loginViewModel.updateDirectServerUrl(it) },
                        label = { Text("服务器地址") },
                        placeholder = { Text("例如：192.168.1.100:5700 或 panel.example.com") },
                        leadingIcon = {
                            Icon(Icons.Default.Language, contentDescription = null)
                        },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = AppColors.primary,
                            cursorColor = AppColors.primary
                        )
                    )
                    Spacer(modifier = Modifier.height(12.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.End
                    ) {
                        TextButton(onClick = onNavigateToServerConfig) {
                            Text("管理服务器列表", style = MaterialTheme.typography.bodySmall, color = AppColors.primary)
                        }
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                }

                // Server selector (multiple servers)
                if (loginState.servers.size > 1) {
                    var expanded by remember { mutableStateOf(false) }
                    GlassCard(
                        modifier = Modifier.fillMaxWidth(),
                        onClick = { expanded = true },
                        padding = androidx.compose.foundation.layout.PaddingValues(horizontal = 16.dp, vertical = 12.dp)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = loginState.currentServerName.ifEmpty { loginState.currentServerUrl },
                                style = MaterialTheme.typography.bodyMedium,
                                modifier = Modifier.weight(1f)
                            )
                            Icon(Icons.Default.ArrowDropDown, contentDescription = null)
                        }
                        DropdownMenu(
                            expanded = expanded,
                            onDismissRequest = { expanded = false }
                        ) {
                            loginState.servers.forEach { server ->
                                DropdownMenuItem(
                                    text = { Text(server["name"] as? String ?: server["url"] as? String ?: "") },
                                    onClick = {
                                        loginViewModel.selectServer(server["url"] as? String ?: "")
                                        expanded = false
                                    }
                                )
                            }
                            DropdownMenuItem(
                                text = { Text("管理服务器...", color = AppColors.primary) },
                                onClick = {
                                    expanded = false
                                    onNavigateToServerConfig()
                                }
                            )
                        }
                    }
                    Spacer(modifier = Modifier.height(16.dp))
                }

                // Username
                OutlinedTextField(
                    value = loginState.username,
                    onValueChange = { loginViewModel.updateUsername(it) },
                    label = { Text("用户名") },
                    leadingIcon = {
                        Icon(Icons.Default.Person, contentDescription = null)
                    },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = AppColors.primary,
                        cursorColor = AppColors.primary
                    )
                )

                Spacer(modifier = Modifier.height(12.dp))

                // Password
                OutlinedTextField(
                    value = loginState.password,
                    onValueChange = { loginViewModel.updatePassword(it) },
                    label = { Text("密码") },
                    leadingIcon = {
                        Icon(Icons.Default.Lock, contentDescription = null)
                    },
                    trailingIcon = {
                        IconButton(onClick = { loginViewModel.togglePasswordVisibility() }) {
                            Icon(
                                if (loginState.passwordVisible) Icons.Default.Visibility else Icons.Default.VisibilityOff,
                                contentDescription = null
                            )
                        }
                    },
                    singleLine = true,
                    visualTransformation = if (loginState.passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = AppColors.primary,
                        cursorColor = AppColors.primary
                    )
                )

                // TOTP
                AnimatedVisibility(
                    visible = loginState.showTotp,
                    enter = fadeIn(),
                    exit = fadeOut()
                ) {
                    Column {
                        Spacer(modifier = Modifier.height(12.dp))
                        OutlinedTextField(
                            value = loginState.totpCode,
                            onValueChange = { loginViewModel.updateTotpCode(it) },
                            label = { Text("两步验证码") },
                            singleLine = true,
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(12.dp),
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedBorderColor = AppColors.primary,
                                cursorColor = AppColors.primary
                            )
                        )
                    }
                }

                Spacer(modifier = Modifier.height(8.dp))

                // Remember & auto login
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.weight(1f)
                    ) {
                        Checkbox(
                            checked = loginState.rememberPassword,
                            onCheckedChange = { loginViewModel.toggleRememberPassword() },
                            colors = CheckboxDefaults.colors(checkedColor = AppColors.primary)
                        )
                        Text("记住密码", style = MaterialTheme.typography.bodySmall)
                    }
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Checkbox(
                            checked = loginState.autoLogin,
                            onCheckedChange = { loginViewModel.toggleAutoLogin() },
                            colors = CheckboxDefaults.colors(checkedColor = AppColors.primary)
                        )
                        Text("自动登录", style = MaterialTheme.typography.bodySmall)
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                // Login button
                Button(
                    onClick = {
                        isLoginLoading = true
                        if (needsServerUrl) {
                            val rawUrl = loginState.directServerUrl.trim()
                            val normalizedUrl = ServerConfigViewModel.normalizeServerUrl(rawUrl)
                            loginViewModel.setupDirectServerUrl(normalizedUrl)
                        }
                        authViewModel.login(
                            username = loginState.username,
                            password = loginState.password,
                            totpCode = loginState.totpCode.ifBlank { null }
                        )
                    },
                    enabled = loginState.username.isNotBlank() &&
                            loginState.password.isNotBlank() &&
                            !isLoginLoading,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(48.dp),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = AppColors.primary)
                ) {
                    if (isLoginLoading) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(24.dp),
                            color = AppColors.white,
                            strokeWidth = 2.dp
                        )
                    } else {
                        Text(
                            "登录",
                            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold)
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                TextButton(onClick = onNavigateToServerConfig) {
                    Text("切换服务器", color = AppColors.primary)
                }

                Spacer(modifier = Modifier.height(32.dp))
            }
        }
    }
}
