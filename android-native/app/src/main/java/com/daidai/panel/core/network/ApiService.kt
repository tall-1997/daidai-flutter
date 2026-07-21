package com.daidai.panel.core.network

import com.daidai.panel.data.model.*
import okhttp3.MultipartBody
import okhttp3.RequestBody
import okhttp3.ResponseBody
import retrofit2.Response
import retrofit2.http.*

interface ApiService {

    // ==================== Auth ====================

    @GET(ApiEndpoints.AUTH_CHECK_INIT)
    suspend fun checkInit(): Response<ResponseBody>

    @POST(ApiEndpoints.AUTH_INIT)
    suspend fun initAdmin(@Body body: Map<String, String>): Response<ApiResponse<Any>>

    @POST(ApiEndpoints.AUTH_LOGIN)
    suspend fun login(@Body body: Map<String, String>): Response<ResponseBody>

    @POST(ApiEndpoints.AUTH_LOGOUT)
    suspend fun logout(): Response<ApiResponse<Any>>

    @POST(ApiEndpoints.AUTH_REFRESH)
    suspend fun refresh(@Body body: Map<String, String>): Response<ApiResponse<Map<String, String>>>

    @GET(ApiEndpoints.AUTH_USER)
    suspend fun getUser(): Response<ResponseBody>

    @PUT(ApiEndpoints.AUTH_PASSWORD)
    suspend fun changePassword(@Body body: Map<String, String>): Response<ApiResponse<Any>>

    @GET(ApiEndpoints.AUTH_CAPTCHA_CONFIG)
    suspend fun getCaptchaConfig(): Response<ApiResponse<Map<String, Any>>>

    // ==================== System ====================

    @GET(ApiEndpoints.SYSTEM_HEALTH)
    suspend fun health(): Response<ResponseBody>

    @GET(ApiEndpoints.SYSTEM_VERSION)
    suspend fun version(): Response<ApiResponse<Map<String, Any>>>

    @GET(ApiEndpoints.SYSTEM_INFO)
    suspend fun systemInfo(): Response<ApiResponse<Map<String, Any>>>

    @GET(ApiEndpoints.SYSTEM_DASHBOARD)
    suspend fun dashboard(): Response<ApiResponse<Map<String, Any>>>

    @GET(ApiEndpoints.SYSTEM_STATS)
    suspend fun systemStats(): Response<ApiResponse<Map<String, Any>>>

    @GET(ApiEndpoints.SYSTEM_CHECK_UPDATE)
    suspend fun checkUpdate(): Response<ApiResponse<Map<String, Any>>>

    @GET(ApiEndpoints.SYSTEM_SETTINGS)
    suspend fun getPanelSettings(): Response<ApiResponse<Map<String, Any>>>

    @PUT(ApiEndpoints.SYSTEM_SETTINGS)
    suspend fun updatePanelSettings(@Body body: Map<String, Any>): Response<ApiResponse<Any>>

    @GET(ApiEndpoints.SYSTEM_LOG)
    suspend fun getPanelLog(@QueryMap params: Map<String, String>): Response<ApiResponse<Any>>

    @GET(ApiEndpoints.SYSTEM_SPONSORS)
    suspend fun getSponsors(): Response<ApiResponse<List<Map<String, Any>>>>

    @POST(ApiEndpoints.SYSTEM_BACKUP)
    suspend fun createBackup(): Response<ApiResponse<Any>>

    @GET(ApiEndpoints.SYSTEM_BACKUPS)
    suspend fun getBackups(): Response<ApiResponse<List<Map<String, Any>>>>

    @Multipart
    @POST(ApiEndpoints.SYSTEM_BACKUP_UPLOAD)
    suspend fun uploadBackup(@Part file: MultipartBody.Part): Response<ApiResponse<Any>>

    @GET(ApiEndpoints.SYSTEM_BACKUP_DOWNLOAD)
    suspend fun downloadBackup(@Query("name") name: String): Response<ResponseBody>

    @POST(ApiEndpoints.SYSTEM_RESTORE)
    suspend fun restore(@Body body: Map<String, String>): Response<ApiResponse<Any>>

    @GET(ApiEndpoints.SYSTEM_RESTORE_PROGRESS)
    suspend fun getRestoreProgress(): Response<ApiResponse<Map<String, Any>>>

    // ==================== Tasks ====================

    @GET(ApiEndpoints.TASKS)
    suspend fun getTasks(@QueryMap params: Map<String, String>): Response<ApiResponse<List<Task>>>

    @POST(ApiEndpoints.TASKS)
    suspend fun createTask(@Body body: Map<String, Any>): Response<ApiResponse<Task>>

    @GET("${ApiEndpoints.TASKS}/{id}")
    suspend fun getTask(@Path("id") id: Int): Response<ApiResponse<Task>>

    @PUT("${ApiEndpoints.TASKS}/{id}")
    suspend fun updateTask(@Path("id") id: Int, @Body body: Map<String, Any>): Response<ApiResponse<Task>>

    @DELETE("${ApiEndpoints.TASKS}/{id}")
    suspend fun deleteTask(@Path("id") id: Int): Response<ApiResponse<Any>>

    @POST
    suspend fun runTask(@Url url: String): Response<ApiResponse<Any>>

    @POST
    suspend fun stopTask(@Url url: String): Response<ApiResponse<Any>>

    @POST
    suspend fun enableTask(@Url url: String): Response<ApiResponse<Any>>

    @POST
    suspend fun disableTask(@Url url: String): Response<ApiResponse<Any>>

    @POST
    suspend fun pinTask(@Url url: String): Response<ApiResponse<Any>>

    @POST
    suspend fun unpinTask(@Url url: String): Response<ApiResponse<Any>>

    @POST
    suspend fun copyTask(@Url url: String): Response<ApiResponse<Any>>

    @GET
    suspend fun getLatestLog(@Url url: String): Response<ApiResponse<TaskLog>>

    @GET
    suspend fun getLiveLogs(@Url url: String): Response<ApiResponse<List<TaskLog>>>

    @GET
    suspend fun getLogFiles(@Url url: String): Response<ApiResponse<List<Map<String, Any>>>>

    @GET
    suspend fun getTaskStats(@Url url: String): Response<ApiResponse<Map<String, Any>>>

    @POST(ApiEndpoints.TASKS_BATCH)
    suspend fun batchTasks(@Body body: Map<String, Any>): Response<ApiResponse<Any>>

    @POST(ApiEndpoints.TASKS_CLEAN_LOGS)
    suspend fun cleanLogs(@Body body: Map<String, Any>): Response<ApiResponse<Any>>

    @GET(ApiEndpoints.TASKS_EXPORT)
    suspend fun exportTasks(@QueryMap params: Map<String, String>): Response<ResponseBody>

    @Multipart
    @POST(ApiEndpoints.TASKS_IMPORT)
    suspend fun importTasks(@Part file: MultipartBody.Part): Response<ApiResponse<Any>>

    @POST(ApiEndpoints.TASKS_CRON_PARSE)
    suspend fun parseCron(@Body body: Map<String, String>): Response<ApiResponse<List<String>>>

    @GET(ApiEndpoints.TASKS_CRON_TEMPLATES)
    suspend fun getCronTemplates(): Response<ApiResponse<List<Map<String, Any>>>>

    @GET(ApiEndpoints.TASKS_NOTIFICATION_CHANNELS)
    suspend fun getNotificationChannels(): Response<ApiResponse<List<NotifyChannel>>>

    // ==================== Logs ====================

    @GET(ApiEndpoints.LOGS)
    suspend fun getLogs(@QueryMap params: Map<String, String>): Response<ApiResponse<List<TaskLog>>>

    @GET("${ApiEndpoints.LOGS}/{id}")
    suspend fun getLog(@Path("id") id: Int): Response<ApiResponse<TaskLog>>

    @DELETE("${ApiEndpoints.LOGS}/{id}")
    suspend fun deleteLog(@Path("id") id: Int): Response<ApiResponse<Any>>

    @GET
    suspend fun streamLogs(@Url url: String): Response<ResponseBody>

    @POST(ApiEndpoints.LOGS_BATCH_DELETE)
    suspend fun batchDeleteLogs(@Body body: Map<String, Any>): Response<ApiResponse<Any>>

    @POST(ApiEndpoints.LOGS_CLEAN)
    suspend fun cleanAllLogs(@Body body: Map<String, Any> = emptyMap()): Response<ApiResponse<Any>>

    // ==================== Scripts ====================

    @GET(ApiEndpoints.SCRIPTS_TREE)
    suspend fun getScriptsTree(@QueryMap params: Map<String, String>): Response<ApiResponse<List<Map<String, Any>>>>

    @GET(ApiEndpoints.SCRIPTS_CONTENT)
    suspend fun getScriptContent(@QueryMap params: Map<String, String>): Response<ApiResponse<String>>

    @GET(ApiEndpoints.SCRIPTS_DOWNLOAD)
    suspend fun downloadScript(@QueryMap params: Map<String, String>): Response<ResponseBody>

    @Multipart
    @POST(ApiEndpoints.SCRIPTS_UPLOAD)
    suspend fun uploadScript(
        @Part file: MultipartBody.Part,
        @Part("path") path: RequestBody
    ): Response<ApiResponse<Any>>

    @POST(ApiEndpoints.SCRIPTS_DIRECTORY)
    suspend fun createDirectory(@Body body: Map<String, String>): Response<ApiResponse<Any>>

    @POST(ApiEndpoints.SCRIPTS_RENAME)
    suspend fun renameScript(@Body body: Map<String, String>): Response<ApiResponse<Any>>

    @POST(ApiEndpoints.SCRIPTS_MOVE)
    suspend fun moveScript(@Body body: Map<String, String>): Response<ApiResponse<Any>>

    @POST(ApiEndpoints.SCRIPTS_COPY)
    suspend fun copyScript(@Body body: Map<String, String>): Response<ApiResponse<Any>>

    @POST(ApiEndpoints.SCRIPTS_BATCH)
    suspend fun batchScripts(@Body body: Map<String, Any>): Response<ApiResponse<Any>>

    @GET(ApiEndpoints.SCRIPTS_VERSIONS)
    suspend fun getScriptVersions(@QueryMap params: Map<String, String>): Response<ApiResponse<List<Map<String, Any>>>>

    @POST(ApiEndpoints.SCRIPTS_RUN)
    suspend fun runScript(@Body body: Map<String, Any>): Response<ApiResponse<Any>>

    @POST(ApiEndpoints.SCRIPTS_RUN_CODE)
    suspend fun runScriptCode(@Body body: Map<String, Any>): Response<ApiResponse<Any>>

    @GET(ApiEndpoints.SCRIPTS_RUN_LOGS)
    suspend fun getRunLogs(@QueryMap params: Map<String, String>): Response<ApiResponse<Map<String, Any>>>

    @POST(ApiEndpoints.SCRIPTS_RUN_STOP)
    suspend fun stopRunScript(@Body body: Map<String, Any>): Response<ApiResponse<Any>>

    @POST(ApiEndpoints.SCRIPTS_RUN_CLEAR)
    suspend fun clearRunScript(@Body body: Map<String, Any>): Response<ApiResponse<Any>>

    @POST(ApiEndpoints.SCRIPTS_FORMAT)
    suspend fun formatScript(@Body body: Map<String, String>): Response<ApiResponse<String>>

    // ==================== EnvVars ====================

    @GET(ApiEndpoints.ENVS)
    suspend fun getEnvVars(@QueryMap params: Map<String, String>): Response<ApiResponse<List<EnvVar>>>

    @POST(ApiEndpoints.ENVS)
    suspend fun createEnvVar(@Body body: Map<String, Any>): Response<ApiResponse<EnvVar>>

    @GET("${ApiEndpoints.ENVS}/{id}")
    suspend fun getEnvVar(@Path("id") id: Int): Response<ApiResponse<EnvVar>>

    @PUT("${ApiEndpoints.ENVS}/{id}")
    suspend fun updateEnvVar(@Path("id") id: Int, @Body body: Map<String, Any>): Response<ApiResponse<EnvVar>>

    @DELETE("${ApiEndpoints.ENVS}/{id}")
    suspend fun deleteEnvVar(@Path("id") id: Int): Response<ApiResponse<Any>>

    @POST
    suspend fun enableEnvVar(@Url url: String): Response<ApiResponse<Any>>

    @POST
    suspend fun disableEnvVar(@Url url: String): Response<ApiResponse<Any>>

    @POST
    suspend fun moveTopEnvVar(@Url url: String): Response<ApiResponse<Any>>

    @POST
    suspend fun cancelTopEnvVar(@Url url: String): Response<ApiResponse<Any>>

    @POST(ApiEndpoints.ENVS_BATCH)
    suspend fun batchEnvVars(@Body body: Map<String, Any>): Response<ApiResponse<Any>>

    @GET(ApiEndpoints.ENVS_GROUPS)
    suspend fun getEnvGroups(): Response<ApiResponse<List<String>>>

    @GET(ApiEndpoints.ENVS_EXPORT)
    suspend fun exportEnvVars(@QueryMap params: Map<String, String>): Response<ResponseBody>

    @Multipart
    @POST(ApiEndpoints.ENVS_IMPORT)
    suspend fun importEnvVars(@Part file: MultipartBody.Part): Response<ApiResponse<Any>>

    // ==================== Subscriptions ====================

    @GET(ApiEndpoints.SUBSCRIPTIONS)
    suspend fun getSubscriptions(@QueryMap params: Map<String, String>): Response<ApiResponse<List<Subscription>>>

    @POST(ApiEndpoints.SUBSCRIPTIONS)
    suspend fun createSubscription(@Body body: Map<String, Any>): Response<ApiResponse<Subscription>>

    @GET("${ApiEndpoints.SUBSCRIPTIONS}/{id}")
    suspend fun getSubscription(@Path("id") id: Int): Response<ApiResponse<Subscription>>

    @PUT("${ApiEndpoints.SUBSCRIPTIONS}/{id}")
    suspend fun updateSubscription(@Path("id") id: Int, @Body body: Map<String, Any>): Response<ApiResponse<Subscription>>

    @DELETE("${ApiEndpoints.SUBSCRIPTIONS}/{id}")
    suspend fun deleteSubscription(@Path("id") id: Int): Response<ApiResponse<Any>>

    @POST
    suspend fun enableSubscription(@Url url: String): Response<ApiResponse<Any>>

    @POST
    suspend fun disableSubscription(@Url url: String): Response<ApiResponse<Any>>

    @POST
    suspend fun pullSubscription(@Url url: String): Response<ApiResponse<Any>>

    @POST
    suspend fun stopPullSubscription(@Url url: String): Response<ApiResponse<Any>>

    @GET
    suspend fun streamPullSubscription(@Url url: String): Response<ResponseBody>

    @GET
    suspend fun getSubscriptionLogs(@Url url: String): Response<ApiResponse<List<Map<String, Any>>>>

    @POST(ApiEndpoints.SUBSCRIPTIONS_BATCH_DELETE)
    suspend fun batchDeleteSubscriptions(@Body body: Map<String, Any>): Response<ApiResponse<Any>>

    // ==================== Notifications ====================

    @GET(ApiEndpoints.NOTIFICATIONS)
    suspend fun getNotifications(@QueryMap params: Map<String, String>): Response<ApiResponse<List<NotifyChannel>>>

    @POST(ApiEndpoints.NOTIFICATIONS)
    suspend fun createNotification(@Body body: Map<String, Any>): Response<ApiResponse<NotifyChannel>>

    @GET("${ApiEndpoints.NOTIFICATIONS}/{id}")
    suspend fun getNotification(@Path("id") id: Int): Response<ApiResponse<NotifyChannel>>

    @PUT("${ApiEndpoints.NOTIFICATIONS}/{id}")
    suspend fun updateNotification(@Path("id") id: Int, @Body body: Map<String, Any>): Response<ApiResponse<NotifyChannel>>

    @DELETE("${ApiEndpoints.NOTIFICATIONS}/{id}")
    suspend fun deleteNotification(@Path("id") id: Int): Response<ApiResponse<Any>>

    @POST
    suspend fun enableNotification(@Url url: String): Response<ApiResponse<Any>>

    @POST
    suspend fun disableNotification(@Url url: String): Response<ApiResponse<Any>>

    @POST
    suspend fun testNotification(@Url url: String): Response<ApiResponse<Any>>

    @GET(ApiEndpoints.NOTIFICATIONS_TYPES)
    suspend fun getNotificationTypes(): Response<ApiResponse<List<Map<String, Any>>>>

    @POST(ApiEndpoints.NOTIFICATIONS_SEND)
    suspend fun sendNotification(@Body body: Map<String, Any>): Response<ApiResponse<Any>>

    // ==================== Dependencies ====================

    @GET(ApiEndpoints.DEPS)
    suspend fun getDependencies(@QueryMap params: Map<String, String>): Response<ApiResponse<List<Dependency>>>

    @POST(ApiEndpoints.DEPS)
    suspend fun createDependency(@Body body: Map<String, Any>): Response<ApiResponse<Dependency>>

    @POST(ApiEndpoints.DEPS)
    suspend fun installDep(@Body body: Map<String, Any>): Response<ApiResponse<Any>>

    @DELETE("${ApiEndpoints.DEPS}/{id}")
    suspend fun deleteDependency(@Path("id") id: Int): Response<ApiResponse<Any>>

    @POST
    suspend fun reinstallDep(@Url url: String): Response<ApiResponse<Any>>

    @POST
    suspend fun cancelDep(@Url url: String): Response<ApiResponse<Any>>

    @GET
    suspend fun streamDepLog(@Url url: String): Response<ResponseBody>

    @POST(ApiEndpoints.DEPS_BATCH_DELETE)
    suspend fun batchDeleteDeps(@Body body: Map<String, Any>): Response<ApiResponse<Any>>

    @POST(ApiEndpoints.DEPS_PIP)
    suspend fun pipInstall(@Body body: Map<String, Any>): Response<ApiResponse<Any>>

    @POST(ApiEndpoints.DEPS_NPM)
    suspend fun npmInstall(@Body body: Map<String, Any>): Response<ApiResponse<Any>>

    @GET(ApiEndpoints.DEPS_MIRRORS)
    suspend fun getMirrors(): Response<ApiResponse<List<Map<String, Any>>>>

    @GET(ApiEndpoints.DEPS_PYTHON_RUNTIMES)
    suspend fun getPythonRuntimes(): Response<ApiResponse<List<Map<String, Any>>>>

    @GET(ApiEndpoints.DEPS_PYTHON_RUNTIME_DEFAULT)
    suspend fun getPythonRuntimeDefault(): Response<ApiResponse<Map<String, Any>>>

    @PUT(ApiEndpoints.DEPS_PYTHON_RUNTIME_DEFAULT)
    suspend fun setPythonRuntimeDefault(@Body body: Map<String, Any>): Response<ApiResponse<Any>>

    // ==================== Users ====================

    @GET(ApiEndpoints.USERS)
    suspend fun getUsers(): Response<ApiResponse<List<User>>>

    @POST(ApiEndpoints.USERS)
    suspend fun createUser(@Body body: Map<String, Any>): Response<ApiResponse<User>>

    @GET("${ApiEndpoints.USERS}/{id}")
    suspend fun getUserById(@Path("id") id: Int): Response<ApiResponse<User>>

    @PUT("${ApiEndpoints.USERS}/{id}")
    suspend fun updateUser(@Path("id") id: Int, @Body body: Map<String, Any>): Response<ApiResponse<User>>

    @DELETE("${ApiEndpoints.USERS}/{id}")
    suspend fun deleteUser(@Path("id") id: Int): Response<ApiResponse<Any>>

    @POST
    suspend fun resetPassword(@Url url: String, @Body body: Map<String, Any>): Response<ApiResponse<Any>>

    // ==================== Security ====================

    @GET(ApiEndpoints.SECURITY)
    suspend fun getSecurity(): Response<ApiResponse<Map<String, Any>>>

    @PUT(ApiEndpoints.SECURITY)
    suspend fun updateSecurity(@Body body: Map<String, Any>): Response<ApiResponse<Any>>

    @GET(ApiEndpoints.SECURITY_LOGIN_LOGS)
    suspend fun getLoginLogs(@QueryMap params: Map<String, String>): Response<ApiResponse<List<Map<String, Any>>>>

    @GET(ApiEndpoints.SECURITY_SESSIONS)
    suspend fun getSessions(): Response<ApiResponse<List<Map<String, Any>>>>

    @DELETE(ApiEndpoints.SECURITY_SESSIONS_OTHERS)
    suspend fun deleteOtherSessions(): Response<ApiResponse<Any>>

    @DELETE
    suspend fun deleteSessionById(@Url url: String): Response<ApiResponse<Any>>

    @GET(ApiEndpoints.SECURITY_IP_WHITELIST)
    suspend fun getIpWhitelist(): Response<ApiResponse<List<Map<String, Any>>>>

    @POST(ApiEndpoints.SECURITY_IP_WHITELIST)
    suspend fun addIpWhitelist(@Body body: Map<String, Any>): Response<ApiResponse<Any>>

    @DELETE
    suspend fun deleteIpWhitelist(@Url url: String): Response<ApiResponse<Any>>

    @GET(ApiEndpoints.SECURITY_AUDIT_LOGS)
    suspend fun getAuditLogs(@QueryMap params: Map<String, String>): Response<ApiResponse<List<Map<String, Any>>>>

    @GET(ApiEndpoints.SECURITY_LOGIN_STATS)
    suspend fun getLoginStats(@QueryMap params: Map<String, String>): Response<ApiResponse<Map<String, Any>>>

    @POST(ApiEndpoints.SECURITY_2FA_SETUP)
    suspend fun setup2Fa(): Response<ApiResponse<Map<String, Any>>>

    @POST(ApiEndpoints.SECURITY_2FA_VERIFY)
    suspend fun verify2Fa(@Body body: Map<String, String>): Response<ApiResponse<Any>>

    @DELETE(ApiEndpoints.SECURITY_2FA)
    suspend fun disable2Fa(@Body body: Map<String, String>): Response<ApiResponse<Any>>

    @GET(ApiEndpoints.SECURITY_2FA_STATUS)
    suspend fun get2FaStatus(): Response<ApiResponse<Map<String, Any>>>

    // ==================== Configs ====================

    @GET(ApiEndpoints.CONFIGS)
    suspend fun getConfigs(@QueryMap params: Map<String, String>): Response<ApiResponse<List<Map<String, Any>>>>

    @POST(ApiEndpoints.CONFIGS)
    suspend fun createConfig(@Body body: Map<String, Any>): Response<ApiResponse<Any>>

    @GET
    suspend fun getConfig(@Url url: String): Response<ApiResponse<Map<String, Any>>>

    @PUT
    suspend fun updateConfig(@Url url: String, @Body body: Map<String, Any>): Response<ApiResponse<Any>>

    @DELETE
    suspend fun deleteConfig(@Url url: String): Response<ApiResponse<Any>>

    @POST(ApiEndpoints.CONFIGS_BATCH)
    suspend fun batchConfigs(@Body body: Map<String, Any>): Response<ApiResponse<Any>>

    // ==================== SSH Keys ====================

    @GET(ApiEndpoints.SSH_KEYS)
    suspend fun getSshKeys(): Response<ApiResponse<List<Map<String, Any>>>>

    @POST(ApiEndpoints.SSH_KEYS)
    suspend fun createSshKey(@Body body: Map<String, Any>): Response<ApiResponse<Any>>

    @GET("${ApiEndpoints.SSH_KEYS}/{id}")
    suspend fun getSshKey(@Path("id") id: Int): Response<ApiResponse<Map<String, Any>>>

    @PUT("${ApiEndpoints.SSH_KEYS}/{id}")
    suspend fun updateSshKey(@Path("id") id: Int, @Body body: Map<String, Any>): Response<ApiResponse<Any>>

    @DELETE("${ApiEndpoints.SSH_KEYS}/{id}")
    suspend fun deleteSshKey(@Path("id") id: Int): Response<ApiResponse<Any>>

    // ==================== OpenAPI ====================

    @GET(ApiEndpoints.OPENAPI)
    suspend fun getOpenApi(): Response<ApiResponse<Map<String, Any>>>

    @POST(ApiEndpoints.OPENAPI_TOKEN)
    suspend fun generateOpenApiToken(@Body body: Map<String, Any>): Response<ApiResponse<Map<String, Any>>>

    @GET(ApiEndpoints.OPENAPI_APPS)
    suspend fun getOpenApiApps(@QueryMap params: Map<String, String>): Response<ApiResponse<List<Map<String, Any>>>>

    @POST(ApiEndpoints.OPENAPI_APPS)
    suspend fun createOpenApiApp(@Body body: Map<String, Any>): Response<ApiResponse<Any>>

    @GET("${ApiEndpoints.OPENAPI_APPS}/{id}")
    suspend fun getOpenApiApp(@Path("id") id: Int): Response<ApiResponse<Map<String, Any>>>

    @PUT("${ApiEndpoints.OPENAPI_APPS}/{id}")
    suspend fun updateOpenApiApp(@Path("id") id: Int, @Body body: Map<String, Any>): Response<ApiResponse<Any>>

    @DELETE("${ApiEndpoints.OPENAPI_APPS}/{id}")
    suspend fun deleteOpenApiApp(@Path("id") id: Int): Response<ApiResponse<Any>>

    @POST
    suspend fun enableOpenApiApp(@Url url: String): Response<ApiResponse<Any>>

    @POST
    suspend fun disableOpenApiApp(@Url url: String): Response<ApiResponse<Any>>

    @POST
    suspend fun resetOpenApiAppSecret(@Url url: String): Response<ApiResponse<Any>>

    @POST
    suspend fun viewOpenApiAppSecret(@Url url: String): Response<ApiResponse<Map<String, Any>>>

    @GET
    suspend fun getOpenApiAppLogs(@Url url: String): Response<ApiResponse<List<Map<String, Any>>>>
}
