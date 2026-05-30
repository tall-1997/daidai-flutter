package com.daidai.app.data.repository

import com.daidai.app.data.remote.ApiService
import com.daidai.app.data.remote.model.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ConfigRepository @Inject constructor(
    private val apiService: ApiService
) {
    suspend fun getConfigs(): Result<List<Config>> {
        return try {
            val response = apiService.getConfigs()
            if (response.isSuccessful) {
                val body = response.body()
                if (body?.data != null) {
                    Result.success(body.data)
                } else {
                    Result.failure(Exception("获取配置列表失败"))
                }
            } else {
                Result.failure(Exception("获取配置列表失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getConfig(key: String): Result<Config> {
        return try {
            val response = apiService.getConfig(key)
            if (response.isSuccessful) {
                val body = response.body()
                if (body?.data != null) {
                    Result.success(body.data)
                } else {
                    Result.failure(Exception("获取配置失败"))
                }
            } else {
                Result.failure(Exception("获取配置失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun setConfig(key: String, value: String): Result<Unit> {
        return try {
            val response = apiService.setConfig(SetConfigRequest(key, value))
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("设置配置失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun deleteConfig(key: String): Result<Unit> {
        return try {
            val response = apiService.deleteConfig(key)
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("删除配置失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getPlatforms(): Result<List<Platform>> {
        return try {
            val response = apiService.getPlatforms()
            if (response.isSuccessful) {
                val body = response.body()
                if (body?.data != null) {
                    Result.success(body.data)
                } else {
                    Result.failure(Exception("获取平台列表失败"))
                }
            } else {
                Result.failure(Exception("获取平台列表失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun createPlatform(name: String, type: String): Result<Platform> {
        return try {
            val response = apiService.createPlatform(CreatePlatformRequest(name, type))
            if (response.isSuccessful) {
                val body = response.body()
                if (body?.data != null) {
                    Result.success(body.data)
                } else {
                    Result.failure(Exception("创建平台失败"))
                }
            } else {
                Result.failure(Exception("创建平台失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun deletePlatform(id: Int): Result<Unit> {
        return try {
            val response = apiService.deletePlatform(id)
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("删除平台失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getPlatformTokens(): Result<List<PlatformToken>> {
        return try {
            val response = apiService.getPlatformTokens()
            if (response.isSuccessful) {
                val body = response.body()
                if (body?.data != null) {
                    Result.success(body.data)
                } else {
                    Result.failure(Exception("获取平台Token列表失败"))
                }
            } else {
                Result.failure(Exception("获取平台Token列表失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun createPlatformToken(platformId: Int, name: String, token: String): Result<PlatformToken> {
        return try {
            val response = apiService.createPlatformToken(CreatePlatformTokenRequest(platformId, name, token))
            if (response.isSuccessful) {
                val body = response.body()
                if (body?.data != null) {
                    Result.success(body.data)
                } else {
                    Result.failure(Exception("创建平台Token失败"))
                }
            } else {
                Result.failure(Exception("创建平台Token失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun deletePlatformToken(id: Int): Result<Unit> {
        return try {
            val response = apiService.deletePlatformToken(id)
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("删除平台Token失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun togglePlatformToken(id: Int, enabled: Boolean): Result<Unit> {
        return try {
            val response = if (enabled) {
                apiService.enablePlatformToken(id)
            } else {
                apiService.disablePlatformToken(id)
            }
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("切换平台Token状态失败: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
