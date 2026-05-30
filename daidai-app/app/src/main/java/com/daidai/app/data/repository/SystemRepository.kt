package com.daidai.app.data.repository

import com.daidai.app.data.remote.ApiService
import com.daidai.app.data.remote.model.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SystemRepository @Inject constructor(
    private val apiService: ApiService
) {
    suspend fun getSystemInfo(): Result<SystemInfo> {
        return try {
            val response = apiService.getSystemInfo()
            if (response.isSuccessful) {
                val body = response.body()
                if (body?.data != null) {
                    Result.success(body.data)
                } else {
                    Result.failure(Exception("获取系统信息失败"))
                }
            } else {
                Result.failure(Exception("获取系统信息失败: ${response.code()}"))
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

    suspend fun getStats(): Result<StatsData> {
        return try {
            val response = apiService.getStats()
            if (response.isSuccessful) {
                val body = response.body()
                if (body?.data != null) {
                    Result.success(body.data)
                } else {
                    Result.failure(Exception("获取统计数据失败"))
                }
            } else {
                Result.failure(Exception("获取统计数据失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getVersion(): Result<VersionData> {
        return try {
            val response = apiService.getVersion()
            if (response.isSuccessful) {
                val body = response.body()
                if (body?.data != null) {
                    Result.success(body.data)
                } else {
                    Result.failure(Exception("获取版本信息失败"))
                }
            } else {
                Result.failure(Exception("获取版本信息失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun checkUpdate(): Result<CheckUpdateData> {
        return try {
            val response = apiService.checkUpdate()
            if (response.isSuccessful) {
                val body = response.body()
                if (body?.data != null) {
                    Result.success(body.data)
                } else {
                    Result.failure(Exception("检查更新失败"))
                }
            } else {
                Result.failure(Exception("检查更新失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getHealthCheck(): Result<HealthCheckResponse> {
        return try {
            val response = apiService.getHealthCheck()
            if (response.isSuccessful) {
                val body = response.body()
                if (body != null) {
                    Result.success(body)
                } else {
                    Result.failure(Exception("健康检查失败"))
                }
            } else {
                Result.failure(Exception("健康检查失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun doHealthCheck(): Result<HealthCheckResponse> {
        return try {
            val response = apiService.runHealthCheck()
            if (response.isSuccessful) {
                val body = response.body()
                if (body != null) {
                    Result.success(body)
                } else {
                    Result.failure(Exception("执行健康检查失败"))
                }
            } else {
                Result.failure(Exception("执行健康检查失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getMachineCode(): Result<String> {
        return try {
            val response = apiService.getMachineCode()
            if (response.isSuccessful) {
                val body = response.body()
                if (body?.data?.machineCode != null) {
                    Result.success(body.data.machineCode)
                } else {
                    Result.failure(Exception("获取机器码失败"))
                }
            } else {
                Result.failure(Exception("获取机器码失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getPanelLog(): Result<PanelLogResponse> {
        return try {
            val response = apiService.getPanelLog()
            if (response.isSuccessful) {
                val body = response.body()
                if (body != null) {
                    Result.success(body)
                } else {
                    Result.failure(Exception("获取面板日志失败"))
                }
            } else {
                Result.failure(Exception("获取面板日志失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun createBackup(): Result<BackupData> {
        return try {
            val response = apiService.createBackup()
            if (response.isSuccessful) {
                val body = response.body()
                if (body?.data != null) {
                    Result.success(body.data)
                } else {
                    Result.failure(Exception("创建备份失败"))
                }
            } else {
                Result.failure(Exception("创建备份失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getBackups(): Result<List<BackupFile>> {
        return try {
            val response = apiService.getBackupList()
            if (response.isSuccessful) {
                val body = response.body()
                if (body?.data != null) {
                    Result.success(body.data)
                } else {
                    Result.failure(Exception("获取备份列表失败"))
                }
            } else {
                Result.failure(Exception("获取备份列表失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun deleteBackup(filename: String): Result<Unit> {
        return try {
            val response = apiService.deleteBackup(DeleteBackupRequest(filename))
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("删除备份失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun restoreBackup(filename: String): Result<Unit> {
        return try {
            val response = apiService.restoreBackup(RestoreBackupRequest(filename))
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("恢复备份失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun updatePanel(): Result<Unit> {
        return try {
            val response = apiService.updatePanel()
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("更新面板失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun restartPanel(): Result<Unit> {
        return try {
            val response = apiService.restartPanel()
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("重启面板失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getConfigScript(): Result<ConfigScriptData> {
        return try {
            val response = apiService.getConfigScript()
            if (response.isSuccessful) {
                val body = response.body()
                if (body?.data != null) {
                    Result.success(body.data)
                } else {
                    Result.failure(Exception("获取配置脚本失败"))
                }
            } else {
                Result.failure(Exception("获取配置脚本失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun updateConfigScript(script: String): Result<Unit> {
        return try {
            val response = apiService.saveConfigScript(SaveConfigScriptRequest(script))
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("更新配置脚本失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
