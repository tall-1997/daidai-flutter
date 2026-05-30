package com.daidai.app.data.remote.model

import com.google.gson.annotations.SerializedName

// ==================== Base Response ====================
data class BaseResponse(
    val code: Int,
    val message: String,
    val data: Any?
)

// ==================== Auth Models ====================
data class LoginRequest(
    val username: String,
    val password: String,
    @SerializedName("totp_code")
    val totpCode: String? = null
)

data class LoginResponse(
    val message: String?,
    @SerializedName("access_token")
    val accessToken: String?,
    @SerializedName("refresh_token")
    val refreshToken: String?,
    val user: User?
)

data class RefreshTokenRequest(
    @SerializedName("refresh_token")
    val refreshToken: String
)

data class User(
    val id: Int,
    val username: String,
    val role: String,
    @SerializedName("avatar_url")
    val avatarUrl: String?
)

data class UserResponse(
    val user: User?
)

data class UserListResponse(
    val data: List<User>?,
    val total: Int
)

data class ChangePasswordRequest(
    @SerializedName("old_password")
    val oldPassword: String,
    @SerializedName("new_password")
    val newPassword: String
)

data class ChangeUsernameRequest(
    val username: String,
    val password: String
)

data class CaptchaConfigResponse(
    val data: CaptchaConfig?
)

data class CaptchaConfig(
    val enabled: Boolean,
    val type: String?
)

data class AvatarResponse(
    val message: String?,
    @SerializedName("avatar_url")
    val avatarUrl: String?
)

data class CreateUserRequest(
    val username: String,
    val password: String,
    val role: String = "viewer"
)

data class UpdateUserRequest(
    val username: String? = null,
    val role: String? = null,
    val enabled: Boolean? = null
)

data class ResetPasswordRequest(
    val password: String
)

// ==================== Task Models ====================
data class TaskListResponse(
    val data: List<Task>?,
    val total: Int,
    val page: Int,
    @SerializedName("page_size")
    val pageSize: Int
)

data class Task(
    val id: Int,
    val name: String,
    val command: String,
    @SerializedName("cron_expression")
    val cronExpression: String?,
    @SerializedName("cron_expressions")
    val cronExpressions: List<String>?,
    @SerializedName("task_type")
    val taskType: String?,
    val status: Double,
    @SerializedName("is_pinned")
    val isPinned: Boolean,
    @SerializedName("last_run_at")
    val lastRunAt: String?,
    @SerializedName("last_run_status")
    val lastRunStatus: Int?,
    @SerializedName("last_running_time")
    val lastRunningTime: String?,
    @SerializedName("created_at")
    val createdAt: String,
    @SerializedName("updated_at")
    val updatedAt: String,
    @SerializedName("next_run_at")
    val nextRunAt: String?,
    @SerializedName("log_path")
    val logPath: String?,
    @SerializedName("allow_multiple_instances")
    val allowMultipleInstances: Boolean?,
    @SerializedName("depends_on")
    val dependsOn: String?,
    val labels: List<String>?,
    @SerializedName("display_labels")
    val displayLabels: List<String>?,
    @SerializedName("max_retries")
    val maxRetries: Int?,
    @SerializedName("notification_channel_id")
    val notificationChannelId: Int?,
    @SerializedName("notify_on_failure")
    val notifyOnFailure: Boolean?,
    @SerializedName("notify_on_success")
    val notifyOnSuccess: Boolean?,
    val pid: Int?,
    @SerializedName("random_delay_seconds")
    val randomDelaySeconds: Int?,
    @SerializedName("retry_interval")
    val retryInterval: Int?,
    @SerializedName("sort_order")
    val sortOrder: Int?,
    @SerializedName("stop_schedule")
    val stopSchedule: String?,
    @SerializedName("task_after")
    val taskAfter: String?,
    @SerializedName("task_before")
    val taskBefore: String?,
    val timeout: Int?
) {
    companion object {
        const val STATUS_DISABLED = 0.0
        const val STATUS_QUEUED = 0.5
        const val STATUS_ENABLED = 1.0
        const val STATUS_RUNNING = 2.0
    }

    val statusText: String
        get() = when (status) {
            STATUS_DISABLED -> "已禁用"
            STATUS_QUEUED -> "排队中"
            STATUS_ENABLED -> "已启用"
            STATUS_RUNNING -> "运行中"
            else -> "未知"
        }

    val isRunning: Boolean
        get() = status == STATUS_RUNNING

    val isEnabled: Boolean
        get() = status == STATUS_ENABLED || status == STATUS_RUNNING || status == STATUS_QUEUED

    val schedule: String
        get() = cronExpression ?: ""
}

data class TaskResponse(
    val message: String?,
    val data: Task?
)

data class CreateTaskRequest(
    val name: String,
    val command: String,
    @SerializedName("cron_expression")
    val cronExpression: String,
    @SerializedName("task_type")
    val taskType: String = "cron"
)

data class UpdateTaskRequest(
    val name: String? = null,
    val command: String? = null,
    @SerializedName("cron_expression")
    val cronExpression: String? = null,
    @SerializedName("is_enabled")
    val isEnabled: Boolean? = null,
    @SerializedName("task_type")
    val taskType: String? = null,
    val status: Double? = null,
    @SerializedName("is_pinned")
    val isPinned: Boolean? = null,
    @SerializedName("allow_multiple_instances")
    val allowMultipleInstances: Boolean? = null,
    @SerializedName("depends_on")
    val dependsOn: String? = null,
    val labels: List<String>? = null,
    @SerializedName("max_retries")
    val maxRetries: Int? = null,
    @SerializedName("notification_channel_id")
    val notificationChannelId: Int? = null,
    @SerializedName("notify_on_failure")
    val notifyOnFailure: Boolean? = null,
    @SerializedName("notify_on_success")
    val notifyOnSuccess: Boolean? = null,
    @SerializedName("random_delay_seconds")
    val randomDelaySeconds: Int? = null,
    @SerializedName("retry_interval")
    val retryInterval: Int? = null,
    @SerializedName("sort_order")
    val sortOrder: Int? = null,
    @SerializedName("stop_schedule")
    val stopSchedule: String? = null,
    @SerializedName("task_after")
    val taskAfter: String? = null,
    @SerializedName("task_before")
    val taskBefore: String? = null,
    val timeout: Int? = null
)

data class BatchTaskRequest(
    val ids: List<Int>,
    val task: Map<String, Any?>
)

data class BatchTaskIdsRequest(
    val ids: List<Int>
)

data class ImportTasksRequest(
    val data: String
)

data class ImportTasksResponse(
    val message: String?,
    @SerializedName("imported_count")
    val importedCount: Int?
)

data class ExportTasksResponse(
    val data: String?
)

data class CronParseRequest(
    @SerializedName("cron_expression")
    val cronExpression: String
)

data class CronParseResponse(
    val data: CronParseData?
)

data class CronParseData(
    @SerializedName("next_runs")
    val nextRuns: List<String>?,
    val description: String?
)

data class CronTemplatesResponse(
    val data: List<CronTemplate>?
)

data class CronTemplate(
    val name: String,
    val expression: String,
    val description: String?
)

data class NotificationChannelsResponse(
    val data: List<NotificationChannel>?
)

data class NotificationChannel(
    val id: Int,
    val name: String,
    val type: String
)

data class TaskLatestLogResponse(
    val data: TaskLog?
)

data class TaskStatsResponse(
    val data: TaskStatsDetail?
)

data class TaskStatsDetail(
    @SerializedName("total_runs")
    val totalRuns: Int?,
    @SerializedName("success_runs")
    val successRuns: Int?,
    @SerializedName("failed_runs")
    val failedRuns: Int?,
    @SerializedName("avg_duration")
    val avgDuration: Double?
)

data class TaskLogFilesResponse(
    val data: List<TaskLogFile>?
)

data class TaskLogFile(
    val name: String,
    val size: Long,
    @SerializedName("created_at")
    val createdAt: String?
)

data class TaskLogFileContentResponse(
    val data: TaskLogFileContent?
)

data class TaskLogFileContent(
    val content: String,
    val name: String?
)

// Task Views
data class TaskViewsResponse(
    val data: List<TaskView>?
)

data class TaskView(
    val id: String,
    val name: String,
    val filter: Map<String, Any?>?,
    @SerializedName("sort_order")
    val sortOrder: Int?
)

data class TaskViewResponse(
    val message: String?,
    val data: TaskView?
)

data class CreateTaskViewRequest(
    val name: String,
    val filter: Map<String, Any?>? = null
)

data class UpdateTaskViewRequest(
    val name: String? = null,
    val filter: Map<String, Any?>? = null
)

data class ReorderTaskViewsRequest(
    val ids: List<String>
)

// ==================== Environment Variables ====================
data class EnvListResponse(
    val data: List<Env>?,
    val total: Int,
    val page: Int,
    @SerializedName("page_size")
    val pageSize: Int
)

data class Env(
    val id: Int,
    val name: String,
    val value: String,
    val remark: String?,
    val remarks: String?,
    @SerializedName("is_enabled")
    val isEnabled: Boolean,
    val enabled: Boolean?,
    val group: String?,
    val groups: List<String>?,
    val position: Int?,
    @SerializedName("sort_order")
    val sortOrder: Int?,
    @SerializedName("created_at")
    val createdAt: String,
    @SerializedName("updated_at")
    val updatedAt: String
)

data class EnvResponse(
    val message: String?,
    val data: Env?
)

data class CreateEnvRequest(
    val name: String,
    val value: String,
    val remark: String? = null,
    @SerializedName("is_enabled")
    val isEnabled: Boolean = true,
    val enabled: Boolean? = null,
    val group: String? = null
)

data class UpdateEnvRequest(
    val name: String? = null,
    val value: String? = null,
    val remark: String? = null,
    val remarks: String? = null,
    @SerializedName("is_enabled")
    val isEnabled: Boolean? = null,
    val enabled: Boolean? = null,
    val group: String? = null
)

data class BatchEnvIdsRequest(
    val ids: List<Int>
)

data class BatchRenameEnvRequest(
    val ids: List<Int>,
    val name: String
)

data class BatchSetGroupRequest(
    val ids: List<Int>,
    val group: String
)

data class ExportEnvsResponse(
    val data: String?
)

data class SortEnvsRequest(
    val ids: List<Int>
)

data class EnvGroupsResponse(
    val data: List<String>?
)

data class ImportEnvsRequest(
    val data: String
)

// ==================== Scripts ====================
data class ScriptListResponse(
    val data: List<Script>?,
    val total: Int
)

data class Script(
    val name: String,
    val path: String,
    val size: Long,
    @SerializedName("is_dir")
    val isDir: Boolean = false,
    @SerializedName("modified_at")
    val modifiedAt: String? = null,
    @SerializedName("mtime")
    val mtime: Long? = null
)

data class ScriptTreeResponse(
    val data: List<ScriptTreeNode>?
)

data class ScriptTreeNode(
    val name: String,
    val path: String,
    @SerializedName("is_dir")
    val isDir: Boolean,
    val children: List<ScriptTreeNode>?
)

data class ScriptContentResponse(
    val data: ScriptContent?
)

data class ScriptContent(
    val content: String,
    val path: String?,
    val binary: Boolean?,
    @SerializedName("is_binary")
    val isBinary: Boolean?
)

data class SaveScriptRequest(
    val path: String,
    val content: String
)

data class CreateScriptRequest(
    val name: String,
    val content: String,
    val description: String? = null
)

data class UpdateScriptRequest(
    val name: String,
    val content: String,
    val description: String? = null
)

data class CreateDirectoryRequest(
    val path: String
)

data class RenameScriptRequest(
    @SerializedName("old_path")
    val oldPath: String,
    @SerializedName("new_path")
    val newPath: String
)

data class MoveScriptRequest(
    val source: String,
    val destination: String
)

data class CopyScriptRequest(
    val source: String,
    val destination: String
)

data class BatchDeleteScriptsRequest(
    val paths: List<String>
)

data class ScriptVersionsResponse(
    val data: List<ScriptVersion>?
)

data class ScriptVersion(
    val id: String,
    val path: String,
    val content: String?,
    @SerializedName("created_at")
    val createdAt: String?
)

data class ScriptVersionResponse(
    val data: ScriptVersion?
)

data class RunScriptRequest(
    val path: String,
    val args: List<String>? = null,
    val env: Map<String, String>? = null
)

data class RunCodeRequest(
    val code: String,
    val language: String = "javascript"
)

data class RunScriptResponse(
    val data: RunScriptData?
)

data class RunScriptData(
    @SerializedName("run_id")
    val runId: String?,
    val message: String?
)

data class ScriptRunLogsResponse(
    val data: ScriptRunLogs?
)

data class ScriptRunLogs(
    val logs: String?,
    val status: String?,
    @SerializedName("exit_code")
    val exitCode: Int?
)

data class FormatScriptRequest(
    val content: String,
    val language: String = "javascript"
)

data class FormatScriptResponse(
    val data: FormatScriptData?
)

data class FormatScriptData(
    val content: String?
)

// ==================== Logs ====================
data class LogListResponse(
    val data: List<TaskLog>?,
    val total: Int,
    val page: Int,
    @SerializedName("page_size")
    val pageSize: Int
)

data class TaskLog(
    val id: Int,
    @SerializedName("task_id")
    val taskId: Int,
    @SerializedName("task_name")
    val taskName: String?,
    @SerializedName("task_type")
    val taskType: String?,
    val status: Int?,
    val content: String?,
    val output: String?,
    @SerializedName("started_at")
    val startedAt: String,
    @SerializedName("ended_at")
    val endedAt: String?,
    @SerializedName("finished_at")
    val finishedAt: String?,
    @SerializedName("duration")
    val duration: Double?,
    @SerializedName("log_path")
    val logPath: String?,
    val labels: List<String>?,
    val task: LogTask?,
    @SerializedName("created_at")
    val createdAt: String?,
    @SerializedName("updated_at")
    val updatedAt: String?
)

data class LogTask(
    val labels: List<String>?,
    @SerializedName("task_type")
    val taskType: String?
)

data class LogDetailResponse(
    val id: Int,
    @SerializedName("task_id")
    val taskId: Int,
    @SerializedName("task_name")
    val taskName: String?,
    @SerializedName("task_type")
    val taskType: String?,
    val status: Int?,
    val content: String?,
    val output: String?,
    @SerializedName("started_at")
    val startedAt: String,
    @SerializedName("ended_at")
    val endedAt: String?,
    @SerializedName("finished_at")
    val finishedAt: String?,
    @SerializedName("duration")
    val duration: Double?,
    @SerializedName("log_path")
    val logPath: String?,
    val labels: List<String>?,
    val task: LogTask?,
    @SerializedName("created_at")
    val createdAt: String?,
    @SerializedName("updated_at")
    val updatedAt: String?
)

data class BatchDeleteLogsRequest(
    val ids: List<Int>
)

// ==================== Dependencies ====================
data class DependencyListResponse(
    val data: List<Dependency>?,
    val total: Int
)

data class Dependency(
    val id: Int,
    val type: String,
    val name: String,
    val status: String,
    @SerializedName("created_at")
    val createdAt: String,
    @SerializedName("updated_at")
    val updatedAt: String
) {
    companion object {
        const val TYPE_NODEJS = "nodejs"
        const val TYPE_PYTHON = "python"
        const val TYPE_LINUX = "linux"

        const val STATUS_QUEUED = "queued"
        const val STATUS_INSTALLING = "installing"
        const val STATUS_INSTALLED = "installed"
        const val STATUS_FAILED = "failed"
        const val STATUS_REMOVING = "removing"
        const val STATUS_CANCELLED = "cancelled"
    }

    val statusText: String
        get() = when (status) {
            STATUS_QUEUED -> "排队中"
            STATUS_INSTALLING -> "安装中"
            STATUS_INSTALLED -> "已安装"
            STATUS_FAILED -> "安装失败"
            STATUS_REMOVING -> "卸载中"
            STATUS_CANCELLED -> "已取消"
            else -> "未知"
        }

    val typeText: String
        get() = when (type) {
            TYPE_NODEJS -> "Node.js"
            TYPE_PYTHON -> "Python"
            TYPE_LINUX -> "Linux"
            else -> type
        }
}

data class DependencyResponse(
    val message: String?,
    val data: Dependency?
)

data class CreateDepRequest(
    val type: String,
    val names: List<String>
)

data class InstallDepRequest(
    val name: String,
    val type: String
)

data class DepStatusResponse(
    val data: DepStatus?
)

data class DepStatus(
    val id: Int,
    val status: String,
    val progress: Int?,
    val message: String?
)

data class BatchDepIdsRequest(
    val ids: List<Int>
)

data class ExportDepsResponse(
    val data: String?
)

data class PipListResponse(
    val data: List<PipPackage>?
)

data class PipPackage(
    val name: String,
    val version: String
)

data class NpmListResponse(
    val data: List<NpmPackage>?
)

data class NpmPackage(
    val name: String,
    val version: String
)

data class DepMirrorsResponse(
    val data: DepMirrors?
)

data class DepMirrors(
    val npm: String?,
    val pip: String?
)

data class SetDepMirrorsRequest(
    val npm: String? = null,
    val pip: String? = null
)

// ==================== System ====================
data class SystemInfoResponse(
    val data: SystemInfo?
)

data class SystemInfo(
    val hostname: String?,
    @SerializedName("machine_code")
    val machineCode: String?,
    @SerializedName("cpu_usage")
    val cpuUsage: Double?,
    @SerializedName("memory_total")
    val memoryTotal: Long?,
    @SerializedName("memory_used")
    val memoryUsed: Long?,
    @SerializedName("memory_free")
    val memoryFree: Long?,
    @SerializedName("memory_usage")
    val memoryUsage: Double?,
    @SerializedName("disk_total")
    val diskTotal: Long?,
    @SerializedName("disk_used")
    val diskUsed: Long?,
    @SerializedName("disk_free")
    val diskFree: Long?,
    @SerializedName("disk_usage")
    val diskUsage: Double?,
    val uptime: String?,
    val goroutines: Int?,
    @SerializedName("go_version")
    val goVersion: String?,
    val os: String?,
    val arch: String?,
    @SerializedName("num_cpu")
    val numCpu: Int?,
    @SerializedName("data_dir")
    val dataDir: String?,
    @SerializedName("net_rx_bytes")
    val netRxBytes: Long?,
    @SerializedName("net_tx_bytes")
    val netTxBytes: Long?,
    @SerializedName("net_rx_speed")
    val netRxSpeed: Long?,
    @SerializedName("net_tx_speed")
    val netTxSpeed: Long?
)

data class HealthResponse(
    val data: HealthData?
)

data class HealthData(
    val status: String
)

data class MachineCodeResponse(
    val data: MachineCodeData?
)

data class MachineCodeData(
    @SerializedName("machine_code")
    val machineCode: String?
)

data class VersionResponse(
    val data: VersionData?
)

data class VersionData(
    val version: String?,
    @SerializedName("api_version")
    val apiVersion: String?,
    val framework: String?
)

data class CheckUpdateResponse(
    val data: CheckUpdateData?
)

data class CheckUpdateData(
    @SerializedName("has_update")
    val hasUpdate: Boolean?,
    @SerializedName("latest_version")
    val latestVersion: String?,
    @SerializedName("current_version")
    val currentVersion: String?,
    val changelog: String?
)

data class HealthCheckResponse(
    val items: List<HealthCheckItem>?,
    @SerializedName("last_checked_at")
    val lastCheckedAt: String?
)

data class HealthCheckItem(
    val name: String,
    val status: String,
    val message: String?
)

data class DashboardResponse(
    val data: DashboardData?
)

data class DashboardData(
    @SerializedName("task_count")
    val taskCount: Int,
    @SerializedName("enabled_tasks")
    val enabledTasks: Int,
    @SerializedName("running_tasks")
    val runningTasks: Int,
    @SerializedName("today_logs")
    val todayLogs: Int,
    @SerializedName("success_logs")
    val successLogs: Int,
    @SerializedName("failed_logs")
    val failedLogs: Int,
    @SerializedName("env_count")
    val envCount: Int,
    @SerializedName("recent_logs")
    val recentLogs: List<TaskLog>?,
    @SerializedName("daily_stats")
    val dailyStats: List<DailyStat>?,
    @SerializedName("prev_task_count")
    val prevTaskCount: Int?,
    @SerializedName("range_days")
    val rangeDays: Int?,
    @SerializedName("sub_count")
    val subCount: Int?,
    @SerializedName("yesterday_logs")
    val yesterdayLogs: Int?,
    @SerializedName("yesterday_success")
    val yesterdaySuccess: Int?
)

data class DailyStat(
    val date: String,
    val success: Int,
    val failed: Int
)

data class StatsResponse(
    val data: StatsData?
)

data class StatsData(
    val tasks: TaskStats?,
    val logs: LogStats?,
    val scripts: ScriptStats?
)

data class TaskStats(
    val total: Int,
    val enabled: Int,
    val disabled: Int,
    val running: Int
)

data class LogStats(
    val total: Int,
    val success: Int,
    val failed: Int,
    @SerializedName("success_rate")
    val successRate: Double
)

data class ScriptStats(
    val total: Int
)

data class PanelLogResponse(
    val data: PanelLogData?
)

data class PanelLogData(
    val logs: List<String>?,
    val total: Int,
    val level: String?
)

// Backup
data class BackupResponse(
    val message: String?,
    val data: BackupData?
)

data class BackupData(
    val filename: String?
)

data class BackupListResponse(
    val data: List<BackupFile>?
)

data class BackupFile(
    val filename: String,
    val size: Long,
    @SerializedName("created_at")
    val createdAt: String?
)

data class RestoreBackupRequest(
    val filename: String
)

data class RestoreProgressResponse(
    val data: RestoreProgress?
)

data class RestoreProgress(
    val status: String?,
    val progress: Int?,
    val message: String?
)

data class DeleteBackupRequest(
    val filename: String
)

data class ConfigScriptResponse(
    val data: ConfigScriptData?
)

data class ConfigScriptData(
    val content: String?
)

data class SaveConfigScriptRequest(
    val content: String
)

data class ApiVersionResponse(
    val version: String?,
    @SerializedName("api_version")
    val apiVersion: String?,
    val framework: String?
)

data class ApiHealthResponse(
    val status: String?
)

data class PanelSettingsResponse(
    val data: PanelSettings?
)

data class PanelSettings(
    val title: String?,
    val logo: String?,
    val theme: String?
)

data class PublicVersionResponse(
    val data: PublicVersionData?
)

data class PublicVersionData(
    val version: String?
)

// ==================== Notifications ====================
data class NotificationListResponse(
    val data: List<Notification>?,
    val total: Int
)

data class Notification(
    val id: Int,
    val name: String,
    val type: String,
    val enabled: Boolean,
    val config: Map<String, Any?>?,
    @SerializedName("created_at")
    val createdAt: String,
    @SerializedName("updated_at")
    val updatedAt: String
)

data class NotificationResponse(
    val message: String?,
    val data: Notification?
)

data class CreateNotificationRequest(
    val name: String,
    val type: String,
    val config: Map<String, Any?>
)

data class UpdateNotificationRequest(
    val name: String? = null,
    val config: Map<String, Any?>? = null
)

data class NotificationTypesResponse(
    val data: List<NotificationType>?
)

data class NotificationType(
    val type: String,
    val name: String
)

data class SendNotificationRequest(
    @SerializedName("channel_id")
    val channelId: Int?,
    val title: String,
    val content: String
)

// ==================== Subscriptions ====================
data class SubscriptionListResponse(
    val data: List<Subscription>?,
    val total: Int
)

data class Subscription(
    val id: Int,
    val name: String,
    val url: String,
    val type: String?,
    val enabled: Boolean,
    @SerializedName("last_pull_at")
    val lastPullAt: String?,
    @SerializedName("last_pull_status")
    val lastPullStatus: String?,
    @SerializedName("created_at")
    val createdAt: String,
    @SerializedName("updated_at")
    val updatedAt: String
)

data class SubscriptionResponse(
    val message: String?,
    val data: Subscription?
)

data class CreateSubscriptionRequest(
    val name: String,
    val url: String,
    val type: String? = null
)

data class UpdateSubscriptionRequest(
    val name: String? = null,
    val url: String? = null,
    val type: String? = null
)

data class SubscriptionLogsResponse(
    val data: List<SubscriptionLog>?
)

data class SubscriptionLog(
    val id: Int,
    val message: String?,
    @SerializedName("created_at")
    val createdAt: String?
)

data class BatchDeleteSubscriptionsRequest(
    val ids: List<Int>
)

// ==================== SSH Keys ====================
data class SSHKeyListResponse(
    val data: List<SSHKey>?,
    val total: Int
)

data class SSHKey(
    val id: Int,
    val name: String,
    val type: String?,
    @SerializedName("public_key")
    val publicKey: String?,
    @SerializedName("created_at")
    val createdAt: String,
    @SerializedName("updated_at")
    val updatedAt: String
)

data class SSHKeyResponse(
    val message: String?,
    val data: SSHKey?
)

data class CreateSSHKeyRequest(
    val name: String,
    @SerializedName("public_key")
    val publicKey: String
)

data class UpdateSSHKeyRequest(
    val name: String? = null,
    @SerializedName("public_key")
    val publicKey: String? = null
)

// ==================== Security ====================
data class LoginLogListResponse(
    val data: List<LoginLog>?,
    val total: Int,
    val page: Int,
    @SerializedName("page_size")
    val pageSize: Int
)

data class LoginLog(
    val id: Int,
    @SerializedName("user_id")
    val userId: Int?,
    val username: String?,
    val ip: String?,
    @SerializedName("user_agent")
    val userAgent: String?,
    val status: String?,
    @SerializedName("created_at")
    val createdAt: String?
)

data class SessionListResponse(
    val data: List<Session>?,
    val total: Int
)

data class Session(
    val id: String,
    @SerializedName("user_id")
    val userId: Int?,
    val username: String?,
    val ip: String?,
    @SerializedName("user_agent")
    val userAgent: String?,
    @SerializedName("last_active")
    val lastActive: String?,
    @SerializedName("created_at")
    val createdAt: String?
)

data class IPWhitelistResponse(
    val data: List<IPWhitelistItem>?,
    val total: Int
)

data class IPWhitelistItem(
    val id: Int,
    val ip: String,
    val remark: String?,
    @SerializedName("created_at")
    val createdAt: String?
)

data class AddIPWhitelistRequest(
    val ip: String,
    val remark: String? = null
)

data class AuditLogListResponse(
    val data: List<AuditLog>?,
    val total: Int,
    val page: Int,
    @SerializedName("page_size")
    val pageSize: Int
)

data class AuditLog(
    val id: Int,
    @SerializedName("user_id")
    val userId: Int?,
    val username: String?,
    val action: String?,
    val resource: String?,
    val detail: String?,
    val ip: String?,
    @SerializedName("created_at")
    val createdAt: String?
)

data class LoginStatsResponse(
    val data: LoginStats?
)

data class LoginStats(
    @SerializedName("total_logins")
    val totalLogins: Int?,
    @SerializedName("failed_logins")
    val failedLogins: Int?,
    @SerializedName("unique_ips")
    val uniqueIps: Int?
)

data class Setup2FAResponse(
    val data: Setup2FAData?
)

data class Setup2FAData(
    val secret: String?,
    @SerializedName("qr_code")
    val qrCode: String?,
    val uri: String?
)

data class Verify2FARequest(
    val code: String
)

data class TwoFAStatusResponse(
    val data: TwoFAStatus?
)

data class TwoFAStatus(
    val enabled: Boolean
)

// ==================== Configs ====================
data class ConfigListResponse(
    val data: List<Config>?,
    val total: Int
)

data class Config(
    val key: String,
    val value: String?,
    val description: String?
)

data class ConfigResponse(
    val data: Config?
)

data class SetConfigRequest(
    val key: String,
    val value: String
)

data class BatchSetConfigsRequest(
    val configs: List<Config>
)

// ==================== Platform Tokens ====================
data class PlatformListResponse(
    val data: List<Platform>?,
    val total: Int
)

data class Platform(
    val id: Int,
    val name: String,
    val type: String?,
    @SerializedName("created_at")
    val createdAt: String?
)

data class PlatformResponse(
    val message: String?,
    val data: Platform?
)

data class CreatePlatformRequest(
    val name: String,
    val type: String
)

data class PlatformTokenListResponse(
    val data: List<PlatformToken>?,
    val total: Int
)

data class PlatformToken(
    val id: Int,
    @SerializedName("platform_id")
    val platformId: Int?,
    val name: String?,
    val enabled: Boolean,
    @SerializedName("created_at")
    val createdAt: String?,
    @SerializedName("updated_at")
    val updatedAt: String?
)

data class PlatformTokenResponse(
    val message: String?,
    val data: PlatformToken?
)

data class CreatePlatformTokenRequest(
    @SerializedName("platform_id")
    val platformId: Int,
    val name: String,
    val token: String
)

data class UpdatePlatformTokenRequest(
    val name: String? = null,
    val token: String? = null
)

// ==================== Open API ====================
data class OpenAPIAppListResponse(
    val data: List<OpenAPIApp>?,
    val total: Int
)

data class OpenAPIApp(
    val id: Int,
    val name: String,
    val enabled: Boolean,
    @SerializedName("created_at")
    val createdAt: String?,
    @SerializedName("updated_at")
    val updatedAt: String?
)

data class OpenAPIAppResponse(
    val message: String?,
    val data: OpenAPIApp?
)

data class CreateOpenAPIAppRequest(
    val name: String,
    val description: String? = null
)

data class UpdateOpenAPIAppRequest(
    val name: String? = null,
    val description: String? = null
)

data class ResetSecretResponse(
    val message: String?,
    val data: ResetSecretData?
)

data class ResetSecretData(
    @SerializedName("app_secret")
    val appSecret: String?
)

data class ViewSecretResponse(
    val data: ViewSecretData?
)

data class ViewSecretData(
    @SerializedName("app_secret")
    val appSecret: String?
)

data class OpenAPILogListResponse(
    val data: List<OpenAPILog>?,
    val total: Int,
    val page: Int,
    @SerializedName("page_size")
    val pageSize: Int
)

data class OpenAPILog(
    val id: Int,
    @SerializedName("app_id")
    val appId: Int?,
    val endpoint: String?,
    val method: String?,
    val status: Int?,
    @SerializedName("created_at")
    val createdAt: String?
)

// ==================== Sponsors ====================
data class SponsorResponse(
    val data: SponsorFeed?
)

data class SponsorFeed(
    val sponsors: List<SponsorItem>?,
    val count: Int?,
    @SerializedName("total_amount")
    val totalAmount: Double?,
    @SerializedName("updated_at")
    val updatedAt: String?,
    val unavailable: Boolean?
)

data class SponsorItem(
    val name: String?,
    val amount: Double?,
    @SerializedName("created_at")
    val createdAt: String?
)

// ==================== Android Runtime ====================
data class AndroidRuntimeStatusResponse(
    val data: AndroidRuntimeStatus?
)

data class AndroidRuntimeStatus(
    val installed: Boolean?,
    val version: String?
)
