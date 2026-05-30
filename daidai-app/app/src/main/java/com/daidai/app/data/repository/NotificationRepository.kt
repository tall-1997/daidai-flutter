package com.daidai.app.data.repository

import com.daidai.app.data.remote.ApiService
import com.daidai.app.data.remote.model.*
import javax.inject.Inject

class NotificationRepository @Inject constructor(
    private val apiService: ApiService
) {
    suspend fun getNotifications(): Result<NotificationListResponse> {
        return try {
            val response = apiService.getNotifications()
            if (response.isSuccessful && response.body() != null) {
                response.body()?.let { Result.success(it) }
                    ?: Result.failure(Exception("获取通知列表失败"))
            } else {
                Result.failure(Exception("获取通知列表失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun createNotification(request: CreateNotificationRequest): Result<Notification> {
        return try {
            val response = apiService.createNotification(request)
            if (response.isSuccessful && response.body()?.data != null) {
                response.body()?.data?.let { Result.success(it) }
                    ?: Result.failure(Exception("创建通知失败"))
            } else {
                Result.failure(Exception(response.body()?.message ?: "创建通知失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun updateNotification(id: Int, request: UpdateNotificationRequest): Result<Notification> {
        return try {
            val response = apiService.updateNotification(id, request)
            if (response.isSuccessful && response.body()?.data != null) {
                response.body()?.data?.let { Result.success(it) }
                    ?: Result.failure(Exception("更新通知失败"))
            } else {
                Result.failure(Exception(response.body()?.message ?: "更新通知失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun deleteNotification(id: Int): Result<Unit> {
        return try {
            val response = apiService.deleteNotification(id)
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception(response.body()?.message ?: "删除通知失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun enableNotification(id: Int): Result<Unit> {
        return try {
            val response = apiService.enableNotification(id)
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception(response.body()?.message ?: "启用通知失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun disableNotification(id: Int): Result<Unit> {
        return try {
            val response = apiService.disableNotification(id)
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception(response.body()?.message ?: "禁用通知失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun testNotification(id: Int): Result<Unit> {
        return try {
            val response = apiService.testNotification(id)
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception(response.body()?.message ?: "测试通知失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getNotificationTypes(): Result<NotificationTypesResponse> {
        return try {
            val response = apiService.getNotificationTypes()
            if (response.isSuccessful && response.body() != null) {
                response.body()?.let { Result.success(it) }
                    ?: Result.failure(Exception("获取通知类型失败"))
            } else {
                Result.failure(Exception("获取通知类型失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getNotificationChannels(): Result<NotificationChannelsResponse> {
        return try {
            val response = apiService.getNotificationChannels()
            if (response.isSuccessful && response.body() != null) {
                response.body()?.let { Result.success(it) }
                    ?: Result.failure(Exception("获取通知渠道失败"))
            } else {
                Result.failure(Exception("获取通知渠道失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
