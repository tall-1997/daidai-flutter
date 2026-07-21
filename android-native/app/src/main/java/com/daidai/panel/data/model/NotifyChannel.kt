package com.daidai.panel.data.model

import com.google.gson.annotations.SerializedName

data class NotifyChannel(
    @SerializedName("id") val id: Int = 0,
    @SerializedName("name") val name: String = "",
    @SerializedName("type") val type: String = "",
    @SerializedName("config") val config: String = "",
    @SerializedName("enabled") val enabled: Boolean = true,
    @SerializedName("created_at") val createdAt: String = "",
    @SerializedName("updated_at") val updatedAt: String = ""
)
