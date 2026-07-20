package com.daidai.panel.data.model

import com.google.gson.annotations.SerializedName
import com.google.gson.annotations.JsonAdapter

data class EnvVar(
    @SerializedName("id") val id: Int = 0,
    @SerializedName("name") val name: String = "",
    @SerializedName("value") val value: String = "",
    @SerializedName("remarks") val remarks: String? = null,
    @SerializedName("enabled") val enabled: Boolean = true,
    @SerializedName("position") val position: Int = 0,
    @SerializedName("sort_order") val sortOrder: Int = 0,
    @SerializedName("group") @JsonAdapter(LabelsDeserializer::class) val group: String = "",
    @SerializedName("created_at") val createdAt: String = "",
    @SerializedName("updated_at") val updatedAt: String = ""
) {
    val isPinned: Boolean get() = sortOrder < 0
    val groups: List<String>
        get() = group.split(",").filter { it.isNotBlank() }.map { it.trim() }
}
