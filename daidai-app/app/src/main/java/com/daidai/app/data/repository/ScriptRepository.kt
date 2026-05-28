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
            val response = apiService.saveScript(request)
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
            val response = apiService.uploadScript(file, path)
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("上传脚本失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
