package com.daidai.app.data.remote

import com.daidai.app.data.remote.model.*
import okhttp3.MultipartBody
import retrofit2.Response
import retrofit2.http.*

interface ApiService {
    // Auth
    @POST("api/v1/auth/login")
    suspend fun login(@Body request: LoginRequest): Response<LoginResponse>

    @POST("api/v1/auth/logout")
    suspend fun logout(): Response<BaseResponse>

    @POST("api/v1/auth/refresh")
    suspend fun refreshToken(@Body request: RefreshTokenRequest): Response<LoginResponse>

    @GET("api/v1/auth/user")
    suspend fun getCurrentUser(): Response<UserResponse>

    // Tasks
    @GET("api/v1/tasks")
    suspend fun getTasks(
        @Query("page") page: Int = 1,
        @Query("page_size") pageSize: Int = 20,
        @Query("search") search: String? = null,
        @Query("status") status: String? = null
    ): Response<TaskListResponse>

    @GET("api/v1/tasks/{id}")
    suspend fun getTask(@Path("id") id: Int): Response<TaskResponse>

    @POST("api/v1/tasks")
    suspend fun createTask(@Body request: CreateTaskRequest): Response<TaskResponse>

    @PUT("api/v1/tasks/{id}")
    suspend fun updateTask(
        @Path("id") id: Int,
        @Body request: UpdateTaskRequest
    ): Response<TaskResponse>

    @DELETE("api/v1/tasks/{id}")
    suspend fun deleteTask(@Path("id") id: Int): Response<BaseResponse>

    @PUT("api/v1/tasks/{id}/run")
    suspend fun runTask(@Path("id") id: Int): Response<BaseResponse>

    @PUT("api/v1/tasks/{id}/stop")
    suspend fun stopTask(@Path("id") id: Int): Response<BaseResponse>

    @PUT("api/v1/tasks/{id}/enable")
    suspend fun enableTask(@Path("id") id: Int): Response<BaseResponse>

    @PUT("api/v1/tasks/{id}/disable")
    suspend fun disableTask(@Path("id") id: Int): Response<BaseResponse>

    // Environment Variables
    @GET("api/v1/envs")
    suspend fun getEnvs(
        @Query("page") page: Int = 1,
        @Query("page_size") pageSize: Int = 20,
        @Query("search") search: String? = null
    ): Response<EnvListResponse>

    @POST("api/v1/envs")
    suspend fun createEnv(@Body request: CreateEnvRequest): Response<EnvResponse>

    @PUT("api/v1/envs/{id}")
    suspend fun updateEnv(
        @Path("id") id: Int,
        @Body request: UpdateEnvRequest
    ): Response<EnvResponse>

    @DELETE("api/v1/envs/{id}")
    suspend fun deleteEnv(@Path("id") id: Int): Response<BaseResponse>

    // Scripts
    @GET("api/v1/scripts")
    suspend fun getScripts(
        @Query("path") path: String? = null
    ): Response<ScriptListResponse>

    @GET("api/v1/scripts/content")
    suspend fun getScriptContent(
        @Query("path") path: String
    ): Response<ScriptContentResponse>

    @POST("api/v1/scripts/save")
    suspend fun saveScript(@Body request: SaveScriptRequest): Response<BaseResponse>

    @Multipart
    @POST("api/v1/scripts/upload")
    suspend fun uploadScript(
        @Part file: MultipartBody.Part,
        @Part("path") path: String? = null
    ): Response<BaseResponse>

    // Logs
    @GET("api/v1/logs")
    suspend fun getLogs(
        @Query("task_id") taskId: Int? = null,
        @Query("page") page: Int = 1,
        @Query("page_size") pageSize: Int = 20
    ): Response<LogListResponse>

    @GET("api/v1/logs/{id}")
    suspend fun getLog(@Path("id") id: Int): Response<LogDetailResponse>

    // System
    @GET("api/v1/system/info")
    suspend fun getSystemInfo(): Response<SystemInfoResponse>

    @GET("api/v1/system/health")
    suspend fun getHealth(): Response<HealthResponse>

    // Dependencies
    @GET("api/v1/deps")
    suspend fun getDeps(
        @Query("type") type: String = "nodejs"
    ): Response<DependencyListResponse>

    @POST("api/v1/deps")
    suspend fun createDep(@Body request: CreateDepRequest): Response<DependencyResponse>

    @DELETE("api/v1/deps/{id}")
    suspend fun deleteDep(@Path("id") id: Int): Response<BaseResponse>

    @PUT("api/v1/deps/{id}/reinstall")
    suspend fun reinstallDep(@Path("id") id: Int): Response<BaseResponse>

    // System Health
    @GET("api/v1/system/health-check")
    suspend fun getHealthCheck(): Response<HealthCheckResponse>

    @POST("api/v1/system/health-check")
    suspend fun runHealthCheck(): Response<HealthCheckResponse>

    @GET("api/v1/system/dashboard")
    suspend fun getDashboard(): Response<DashboardResponse>

    @GET("api/v1/system/stats")
    suspend fun getStats(): Response<StatsResponse>

    @GET("api/v1/system/panel-log")
    suspend fun getPanelLog(
        @Query("lines") lines: Int = 100
    ): Response<PanelLogResponse>
}
