package com.daidai.panel.core.auth

import com.daidai.panel.core.network.NetworkModule
import com.daidai.panel.core.storage.SecureStorage
import com.daidai.panel.data.model.ApiResponse
import com.daidai.panel.data.model.User
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import java.net.ConnectException
import java.net.SocketTimeoutException
import javax.inject.Inject
import javax.inject.Singleton
import javax.net.ssl.SSLHandshakeException

@Singleton
class AuthRepository @Inject constructor(
    private val secureStorage: SecureStorage,
    private val networkModule: NetworkModule
) {
    suspend fun needsInitialization(): Result<Boolean> {
        return try {
            val response = networkModule.getApiService().checkInit()
            if (response.isSuccessful) {
                val responseBody = response.body()?.string()
                // Server returns {"need_init": false}
                val needInit = try {
                    val gson = Gson()
                    val mapType = object : TypeToken<Map<String, Any?>>() {}.type
                    val map: Map<String, Any?> = gson.fromJson(responseBody, mapType)
                    map["need_init"] as? Boolean ?: false
                } catch (_: Exception) {
                    false
                }
                Result.success(needInit)
            } else {
                Result.failure(Exception("Check init failed"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun initAdmin(username: String, password: String): Result<Any> {
        return try {
            val response = networkModule.getApiService().initAdmin(
                mapOf("username" to username, "password" to password)
            )
            if (response.isSuccessful && response.body()?.isSuccess == true) {
                Result.success(Unit)
            } else {
                Result.failure(Exception(response.body()?.message ?: "Init failed"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun login(
        username: String,
        password: String,
        captchaCode: String? = null,
        captchaId: String? = null,
        totpCode: String? = null
    ): Result<User> {
        return try {
            val body = mutableMapOf(
                "username" to username,
                "password" to password
            )
            captchaCode?.let { body["captcha_code"] = it }
            captchaId?.let { body["captcha_id"] = it }
            totpCode?.let { body["totp_code"] = it }

            val response = networkModule.getApiService().login(body)
            val responseBody = response.body()?.string()

            if (response.isSuccessful && responseBody != null) {
                val gson = Gson()
                val mapType = object : TypeToken<Map<String, Any?>>() {}.type
                val map: Map<String, Any?> = gson.fromJson(responseBody, mapType)

                // Handle two_factor_required
                if (map["two_factor_required"] == true) {
                    val errorMsg = map["error"] as? String ?: "需要两步验证码"
                    return Result.failure(TwoFactorRequiredException(errorMsg))
                }

                // Handle captcha_required
                if (map["captcha_required"] == true) {
                    val errorMsg = map["error"] as? String ?: "验证码已失效，请重新完成验证"
                    return Result.failure(CaptchaRequiredException(errorMsg))
                }

                val accessToken = map["access_token"] as? String ?: ""
                val refreshToken = map["refresh_token"] as? String ?: ""

                if (accessToken.isEmpty()) {
                    return Result.failure(Exception("登录响应缺少 access_token"))
                }

                secureStorage.saveTokens(accessToken, refreshToken)

                // Server returns user in login response - use it directly
                @Suppress("UNCHECKED_CAST")
                val userData = map["user"] as? Map<String, Any?>
                if (userData != null) {
                    val user = User(
                        id = (userData["id"] as? Number)?.toInt() ?: 0,
                        username = userData["username"] as? String ?: "",
                        role = userData["role"] as? String ?: "viewer",
                        enabled = userData["enabled"] as? Boolean ?: true,
                        avatarUrl = userData["avatar_url"] as? String ?: ""
                    )
                    secureStorage.saveAuthUser(mapOf(
                        "id" to user.id,
                        "username" to user.username,
                        "role" to user.role
                    ))
                    return Result.success(user)
                }

                // Fallback: fetch user separately
                val user = getUser()
                user.onSuccess { return Result.success(it) }
                Result.failure(user.exceptionOrNull() ?: Exception("获取用户信息失败"))
            } else {
                // Parse error response - server returns {"error": "...", ...}
                val errorMessage = try {
                    if (responseBody != null) {
                        val gson = Gson()
                        val mapType = object : TypeToken<Map<String, Any?>>() {}.type
                        val map: Map<String, Any?> = gson.fromJson(responseBody, mapType)
                        map["error"] as? String ?: map["message"] as? String ?: "登录失败"
                    } else {
                        "登录失败 (${response.code()})"
                    }
                } catch (_: Exception) {
                    "登录失败 (${response.code()})"
                }
                Result.failure(Exception(errorMessage))
            }
        } catch (e: java.net.ConnectException) {
            val serverUrl = secureStorage.getServerUrlSync() ?: "未知地址"
            Result.failure(Exception("无法连接到服务器 ($serverUrl)，请检查：\n1. 服务器地址和端口是否正确\n2. 服务器是否已启动\n3. 网络连接是否正常"))
        } catch (e: java.net.SocketTimeoutException) {
            Result.failure(Exception("连接服务器超时，请检查网络"))
        } catch (e: javax.net.ssl.SSLHandshakeException) {
            Result.failure(Exception("SSL 证书验证失败，如果是自签名证书请使用 HTTP"))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun logout(): Result<Unit> {
        return try {
            networkModule.getApiService().logout()
            secureStorage.clearAuth()
            networkModule.invalidateApiService()
            Result.success(Unit)
        } catch (e: Exception) {
            secureStorage.clearAuth()
            networkModule.invalidateApiService()
            Result.success(Unit)
        }
    }

    suspend fun getUser(): Result<User> {
        return try {
            val response = networkModule.getApiService().getUser()
            if (response.isSuccessful) {
                val responseBody = response.body()?.string()
                val gson = Gson()
                val mapType = object : TypeToken<Map<String, Any?>>() {}.type
                val map: Map<String, Any?> = gson.fromJson(responseBody, mapType)

                // Server returns {"user": {...}} or {"data": {...}} or direct user object
                val userData = map["user"] as? Map<String, Any?>
                    ?: map["data"] as? Map<String, Any?>
                    ?: map

                val user = User(
                    id = (userData["id"] as? Number)?.toInt() ?: 0,
                    username = userData["username"] as? String ?: "",
                    role = userData["role"] as? String ?: "viewer",
                    enabled = userData["enabled"] as? Boolean ?: true,
                    avatarUrl = userData["avatar_url"] as? String ?: ""
                )

                secureStorage.saveAuthUser(mapOf(
                    "id" to user.id,
                    "username" to user.username,
                    "role" to user.role
                ))
                Result.success(user)
            } else {
                Result.failure(Exception("获取用户信息失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun changePassword(oldPassword: String, newPassword: String): Result<Unit> {
        return try {
            val response = networkModule.getApiService().changePassword(
                mapOf("old_password" to oldPassword, "new_password" to newPassword)
            )
            if (response.isSuccessful && response.body()?.isSuccess == true) {
                Result.success(Unit)
            } else {
                Result.failure(Exception(response.body()?.message ?: "Change password failed"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun checkHealth(): Result<Boolean> {
        return try {
            val response = networkModule.getApiService().health()
            Result.success(response.isSuccessful)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun isTrustedLogin(serverUrl: String): Boolean {
        val until = secureStorage.getTrustedLoginUntil()
        val trustedUrl = secureStorage.getTrustedLoginServerUrl()
        return until > System.currentTimeMillis() && trustedUrl == serverUrl
    }

    suspend fun setTrustedLogin(serverUrl: String, durationMillis: Long) {
        secureStorage.saveTrustedLoginUntil(System.currentTimeMillis() + durationMillis)
        secureStorage.saveTrustedLoginServerUrl(serverUrl)
    }
}

class TwoFactorRequiredException(message: String) : Exception(message)
class CaptchaRequiredException(message: String) : Exception(message)
