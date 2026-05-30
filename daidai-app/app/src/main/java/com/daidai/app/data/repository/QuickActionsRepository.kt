package com.daidai.app.data.repository

import com.daidai.app.data.remote.ApiService
import com.daidai.app.data.remote.model.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class QuickActionsRepository @Inject constructor(
    private val apiService: ApiService
) {
    // 任务批量操作
    suspend fun batchRunTasks(taskIds: List<Int>): Result<Unit> {
        return try {
            val response = apiService.batchRunTasks(BatchTaskIdsRequest(taskIds))
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("批量运行任务失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun batchEnableTasks(taskIds: List<Int>): Result<Unit> {
        return try {
            val response = apiService.batchEnableTasks(BatchTaskIdsRequest(taskIds))
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("批量启用任务失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun batchDisableTasks(taskIds: List<Int>): Result<Unit> {
        return try {
            val response = apiService.batchDisableTasks(BatchTaskIdsRequest(taskIds))
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("批量禁用任务失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun batchDeleteTasks(taskIds: List<Int>): Result<Unit> {
        return try {
            val response = apiService.batchDeleteTasks(BatchTaskIdsRequest(taskIds))
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("批量删除任务失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    // 环境变量批量操作
    suspend fun batchEnableEnvs(envIds: List<Int>): Result<Unit> {
        return try {
            val response = apiService.batchEnableEnvs(BatchEnvIdsRequest(envIds))
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("批量启用环境变量失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun batchDisableEnvs(envIds: List<Int>): Result<Unit> {
        return try {
            val response = apiService.batchDisableEnvs(BatchEnvIdsRequest(envIds))
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("批量禁用环境变量失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun batchDeleteEnvs(envIds: List<Int>): Result<Unit> {
        return try {
            val response = apiService.batchDeleteEnvs(BatchEnvIdsRequest(envIds))
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("批量删除环境变量失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    // 依赖批量操作
    suspend fun batchReinstallDeps(depIds: List<Int>): Result<Unit> {
        return try {
            val response = apiService.batchReinstallDeps(BatchDepIdsRequest(depIds))
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("批量重装依赖失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun batchDeleteDeps(depIds: List<Int>): Result<Unit> {
        return try {
            val response = apiService.batchDeleteDeps(BatchDepIdsRequest(depIds))
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("批量删除依赖失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    // 日志批量操作
    suspend fun batchDeleteLogs(logIds: List<Int>): Result<Unit> {
        return try {
            val response = apiService.batchDeleteLogs(BatchDeleteLogsRequest(logIds))
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("批量删除日志失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    // 脚本批量操作
    suspend fun batchDeleteScripts(scriptPaths: List<String>): Result<Unit> {
        return try {
            val response = apiService.batchDeleteScripts(BatchDeleteScriptsRequest(scriptPaths))
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("批量删除脚本失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    // 导入导出
    suspend fun exportTasks(): Result<String> {
        return try {
            val response = apiService.exportTasks()
            if (response.isSuccessful) {
                val body = response.body()
                if (body?.data != null) {
                    Result.success(body.data)
                } else {
                    Result.failure(Exception("导出任务失败"))
                }
            } else {
                Result.failure(Exception("导出任务失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun importTasks(data: String): Result<Int> {
        return try {
            val response = apiService.importTasks(ImportTasksRequest(data))
            if (response.isSuccessful) {
                val body = response.body()
                if (body?.importedCount != null) {
                    Result.success(body.importedCount)
                } else {
                    Result.failure(Exception("导入任务失败"))
                }
            } else {
                Result.failure(Exception("导入任务失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    // 解析Cron表达式
    suspend fun parseCron(expression: String): Result<CronParseData> {
        return try {
            val response = apiService.parseCron(CronParseRequest(expression))
            if (response.isSuccessful) {
                val body = response.body()
                if (body?.data != null) {
                    Result.success(body.data)
                } else {
                    Result.failure(Exception("解析Cron表达式失败"))
                }
            } else {
                Result.failure(Exception("解析Cron表达式失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
