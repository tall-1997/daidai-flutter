package com.daidai.app.data.repository

import com.daidai.app.data.remote.ApiService
import com.daidai.app.data.remote.model.*
import javax.inject.Inject

class SystemRepository @Inject constructor(
    private val apiService: ApiService
) {
    suspend fun getSystemInfo(): Result<SystemInfoResponse> {
        return try {
            val response = apiService.getSystemInfo()
            if (response.isSuccessful && response.body() != null) {
                response.body()?.let { Result.success(it) }
                    ?: Result.failure(Exception("获取系统信息失败"))
            } else {
                Result.failure(Exception("获取系统信息失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getHealth(): Result<HealthResponse> {
        return try {
            val response = apiService.getHealth()
            if (response.isSuccessful && response.body() != null) {
                response.body()?.let { Result.success(it) }
                    ?: Result.failure(Exception("获取健康状态失败"))
            } else {
                Result.failure(Exception("获取健康状态失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getHealthCheck(): Result<HealthCheckResponse> {
        return try {
            val response = apiService.getHealthCheck()
            if (response.isSuccessful && response.body() != null) {
                response.body()?.let { Result.success(it) }
                    ?: Result.failure(Exception("获取健康检查失败"))
            } else {
                Result.failure(Exception("获取健康检查失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun runHealthCheck(): Result<HealthCheckResponse> {
        return try {
            val response = apiService.runHealthCheck()
            if (response.isSuccessful && response.body() != null) {
                response.body()?.let { Result.success(it) }
                    ?: Result.failure(Exception("执行健康检查失败"))
            } else {
                Result.failure(Exception("执行健康检查失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getDashboard(): Result<DashboardResponse> {
        return try {
            val response = apiService.getDashboard()
            if (response.isSuccessful && response.body() != null) {
                response.body()?.let { Result.success(it) }
                    ?: Result.failure(Exception("获取仪表盘数据失败"))
            } else {
                Result.failure(Exception("获取仪表盘数据失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getStats(): Result<StatsResponse> {
        return try {
            val response = apiService.getStats()
            if (response.isSuccessful && response.body() != null) {
                response.body()?.let { Result.success(it) }
                    ?: Result.failure(Exception("获取统计数据失败"))
            } else {
                Result.failure(Exception("获取统计数据失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getPanelLog(lines: Int = 100): Result<PanelLogResponse> {
        return try {
            val response = apiService.getPanelLog(lines)
            if (response.isSuccessful && response.body() != null) {
                response.body()?.let { Result.success(it) }
                    ?: Result.failure(Exception("获取面板日志失败"))
            } else {
                Result.failure(Exception("获取面板日志失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
