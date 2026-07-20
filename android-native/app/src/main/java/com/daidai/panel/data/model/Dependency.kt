package com.daidai.panel.data.model

import com.google.gson.annotations.SerializedName

data class Dependency(
    @SerializedName("id") val id: Int = 0,
    @SerializedName("name") val name: String = "",
    @SerializedName("version") val version: String = "",
    @SerializedName("type") val type: String = "",
    @SerializedName("python_version") val pythonVersion: String = "",
    @SerializedName("status") val status: String = "",
    @SerializedName("remark") val remark: String? = null,
    @SerializedName("log") val log: String? = null,
    @SerializedName("created_at") val createdAt: String = "",
    @SerializedName("updated_at") val updatedAt: String = ""
) {
    val isQueued: Boolean get() = status == "queued"
    val isInstalling: Boolean get() = status == "installing"
    val isRemoving: Boolean get() = status == "removing"
    val isInstalled: Boolean get() = status == "installed"
    val isFailed: Boolean get() = status == "failed"
    val isBusy: Boolean get() = isInstalling || isRemoving

    val statusText: String
        get() = when (status) {
            "queued" -> "队列中"
            "installing" -> "安装中"
            "installed" -> "已安装"
            "removing" -> "卸载中"
            "failed" -> "安装失败"
            else -> "未知"
        }
}
