package com.daidai.app.data.repository

import com.daidai.app.data.remote.ApiService
import com.daidai.app.data.remote.model.*
import okhttp3.MultipartBody
import javax.inject.Inject

class ScriptRepository @Inject constructor(
    private val apiService: ApiService
) {
    suspend fun getScripts(path: String? = null): Result<ScriptListResponse> {
        return try {
            val response = apiService.getScripts(path)
            if (response.isSuccessful && response.body()?.data != null) {
                response.body()?.let { Result.success(it) }
                    ?: Result.failure(Exception("获取脚本列表失败"))
            } else {
                Result.failure(Exception("获取脚本列表失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getScriptContent(path: String): Result<ScriptContent> {
        return try {
            val response = apiService.getScriptContent(path)
            if (response.isSuccessful && response.body()?.data != null) {
                response.body()?.data?.let { Result.success(it) }
                    ?: Result.failure(Exception("获取脚本内容失败"))
            } else {
                Result.failure(Exception("获取脚本内容失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun saveScript(request: SaveScriptRequest): Result<Unit> {
        return try {
            val response = apiService.saveScriptContent(request)
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("保存脚本失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun uploadScript(file: MultipartBody.Part, path: String? = null): Result<Unit> {
        return try {
            val pathBody = path?.let { okhttp3.RequestBody.create(null, it) }
            val response = apiService.uploadScript(file, pathBody)
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("上传脚本失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun createScript(request: CreateScriptRequest): Result<Unit> {
        return try {
            val response = apiService.saveScriptContent(SaveScriptRequest(request.name, request.content))
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("创建脚本失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun updateScript(id: Int, request: UpdateScriptRequest): Result<Unit> {
        return try {
            val response = apiService.saveScriptContent(SaveScriptRequest(request.name, request.content))
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("更新脚本失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun deleteScript(path: String): Result<Unit> {
        return try {
            val response = apiService.deleteScript(path)
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception(response.body()?.message ?: "删除脚本失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun runScript(request: RunScriptRequest): Result<RunScriptResponse> {
        return try {
            val response = apiService.runScript(request)
            if (response.isSuccessful && response.body() != null) {
                response.body()?.let { Result.success(it) }
                    ?: Result.failure(Exception("运行脚本失败"))
            } else {
                Result.failure(Exception("运行脚本失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
