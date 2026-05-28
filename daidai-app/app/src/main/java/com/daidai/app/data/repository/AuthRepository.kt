package com.daidai.app.data.repository

import com.daidai.app.data.remote.ApiService
import com.daidai.app.data.remote.model.*
import javax.inject.Inject

class AuthRepository @Inject constructor(
    private val apiService: ApiService
) {
    suspend fun login(username: String, password: String, totpCode: String? = null): Result<LoginResponse> {
        return try {
            val response = apiService.login(LoginRequest(username, password, totpCode))
            if (response.isSuccessful && response.body()?.accessToken != null) {
                response.body()?.let { Result.success(it) }
                    ?: Result.failure(Exception("登录失败"))
            } else {
                Result.failure(Exception(response.body()?.message ?: response.errorBody()?.string() ?: "登录失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun logout(): Result<Unit> {
        return try {
            val response = apiService.logout()
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("退出失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun refreshToken(refreshToken: String): Result<LoginResponse> {
        return try {
            val response = apiService.refreshToken(RefreshTokenRequest(refreshToken))
            if (response.isSuccessful && response.body()?.accessToken != null) {
                response.body()?.let { Result.success(it) }
                    ?: Result.failure(Exception("刷新token失败"))
            } else {
                Result.failure(Exception(response.body()?.message ?: "刷新token失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getCurrentUser(): Result<User> {
        return try {
            val response = apiService.getCurrentUser()
            if (response.isSuccessful) {
                // 需要根据实际响应格式解析
                val user = response.body()?.user
                if (user != null) {
                    Result.success(user)
                } else {
                    Result.failure(Exception("获取用户信息失败"))
                }
            } else {
                Result.failure(Exception("获取用户信息失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
