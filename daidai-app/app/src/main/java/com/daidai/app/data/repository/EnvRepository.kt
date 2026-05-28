package com.daidai.app.data.repository

import com.daidai.app.data.remote.ApiService
import com.daidai.app.data.remote.model.*
import javax.inject.Inject

class EnvRepository @Inject constructor(
    private val apiService: ApiService
) {
    suspend fun getEnvs(
        page: Int = 1,
        pageSize: Int = 20,
        search: String? = null
    ): Result<EnvListResponse> {
        return try {
            val response = apiService.getEnvs(page, pageSize, search)
            if (response.isSuccessful && response.body()?.data != null) {
                response.body()?.let { Result.success(it) }
                    ?: Result.failure(Exception("获取环境变量列表失败"))
            } else {
                Result.failure(Exception("获取环境变量列表失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun createEnv(request: CreateEnvRequest): Result<Env> {
        return try {
            val response = apiService.createEnv(request)
            if (response.isSuccessful && response.body()?.data != null) {
                response.body()?.data?.let { Result.success(it) }
                    ?: Result.failure(Exception("创建环境变量失败"))
            } else {
                Result.failure(Exception(response.body()?.message ?: "创建环境变量失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun updateEnv(id: Int, request: UpdateEnvRequest): Result<Env> {
        return try {
            val response = apiService.updateEnv(id, request)
            if (response.isSuccessful && response.body()?.data != null) {
                response.body()?.data?.let { Result.success(it) }
                    ?: Result.failure(Exception("更新环境变量失败"))
            } else {
                Result.failure(Exception(response.body()?.message ?: "更新环境变量失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun deleteEnv(id: Int): Result<Unit> {
        return try {
            val response = apiService.deleteEnv(id)
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception(response.body()?.message ?: "删除环境变量失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
