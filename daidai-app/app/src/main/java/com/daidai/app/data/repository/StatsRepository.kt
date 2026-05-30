package com.daidai.app.data.repository

import com.daidai.app.data.remote.ApiService
import com.daidai.app.data.remote.model.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class StatsRepository @Inject constructor(
    private val apiService: ApiService
) {
    suspend fun getTaskStats(taskId: Int): Result<TaskStatsDetail> {
        return try {
            val response = apiService.getTaskStats(taskId)
            if (response.isSuccessful) {
                val body = response.body()
                if (body?.data != null) {
                    Result.success(body.data)
                } else {
                    Result.failure(Exception("获取任务统计失败"))
                }
            } else {
                Result.failure(Exception("获取任务统计失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getSystemStats(): Result<StatsData> {
        return try {
            val response = apiService.getStats()
            if (response.isSuccessful) {
                val body = response.body()
                if (body?.data != null) {
                    Result.success(body.data)
                } else {
                    Result.failure(Exception("获取系统统计失败"))
                }
            } else {
                Result.failure(Exception("获取系统统计失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getDashboard(): Result<DashboardData> {
        return try {
            val response = apiService.getDashboard()
            if (response.isSuccessful) {
                val body = response.body()
                if (body?.data != null) {
                    Result.success(body.data)
                } else {
                    Result.failure(Exception("获取仪表盘数据失败"))
                }
            } else {
                Result.failure(Exception("获取仪表盘数据失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getLoginStats(): Result<LoginStats> {
        return try {
            val response = apiService.getLoginStats()
            if (response.isSuccessful) {
                val body = response.body()
                if (body?.data != null) {
                    Result.success(body.data)
                } else {
                    Result.failure(Exception("获取登录统计失败"))
                }
            } else {
                Result.failure(Exception("获取登录统计失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
