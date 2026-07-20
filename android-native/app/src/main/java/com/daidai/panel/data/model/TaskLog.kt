package com.daidai.panel.data.model

import com.google.gson.annotations.SerializedName

data class TaskLog(
    @SerializedName("id") val id: Int = 0,
    @SerializedName("task_id") val taskId: Int = 0,
    @SerializedName("content") val content: String = "",
    @SerializedName("status") val status: Int = 0,
    @SerializedName("duration") val duration: Double = 0.0,
    @SerializedName("log_path") val logPath: String? = null,
    @SerializedName("started_at") val startedAt: String = "",
    @SerializedName("ended_at") val endedAt: String = "",
    @SerializedName("created_at") val createdAt: String = "",
    @SerializedName("task_name") val taskName: String = "",
    @SerializedName("task_type") val taskType: String = "",
    @SerializedName("labels") val labels: List<String> = emptyList()
) {
    val isSuccess: Boolean get() = status == 0
    val isFailed: Boolean get() = status == 1
    val isRunning: Boolean get() = status == 2

    val statusText: String
        get() = when (status) {
            0 -> "成功"
            1 -> "失败"
            2 -> "运行中"
            3 -> "超时"
            else -> "未知"
        }

    val durationText: String
        get() {
            if (duration <= 0) return ""
            val totalSeconds = duration.toLong()
            val hours = totalSeconds / 3600
            val minutes = (totalSeconds % 3600) / 60
            val seconds = totalSeconds % 60
            val millis = ((duration - totalSeconds) * 1000).toLong()
            return when {
                hours > 0 -> "%d:%02d:%02d.%03d".format(hours, minutes, seconds, millis)
                minutes > 0 -> "%d:%02d.%03d".format(minutes, seconds, millis)
                else -> "%d.%03ds".format(seconds, millis)
            }
        }
}
