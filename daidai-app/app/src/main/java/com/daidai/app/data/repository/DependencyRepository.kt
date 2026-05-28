package com.daidai.app.data.repository

import com.daidai.app.data.remote.ApiService
import com.daidai.app.data.remote.model.*
import javax.inject.Inject

class DependencyRepository @Inject constructor(
    private val apiService: ApiService
) {
    suspend fun getDeps(type: String = "nodejs"): Result<DependencyListResponse> {
        return try {
            val response = apiService.getDeps(type)
            if (response.isSuccessful) {
                response.body()?.let { Result.success(it) }
                    ?: Result.failure(Exception("获取依赖列表失败"))
            } else {
                Result.failure(Exception("获取依赖列表失败: ${response.message()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun createDep(type: String, names: List<String>): Result<DependencyResponse> {
        return try {
            val response = apiService.createDep(CreateDepRequest(type, names))
            if (response.isSuccessful && response.body() != null) {
                response.body()?.let { Result.success(it) }
                    ?: Result.failure(Exception("创建依赖失败"))
            } else {
                Result.failure(Exception("创建依赖失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun deleteDep(id: Int): Result<Unit> {
        return try {
            val response = apiService.deleteDep(id)
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("删除依赖失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun reinstallDep(id: Int): Result<Unit> {
        return try {
            val response = apiService.reinstallDep(id)
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("重新安装依赖失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
