package com.daidai.app.data.remote

import javax.inject.Inject

class TokenManager @Inject constructor() {
    private var accessToken: String? = null
    private var refreshToken: String? = null

    fun getAccessToken(): String? = accessToken

    fun getRefreshToken(): String? = refreshToken

    fun saveTokens(accessToken: String, refreshToken: String) {
        this.accessToken = accessToken
        this.refreshToken = refreshToken
    }

    fun clearTokens() {
        accessToken = null
        refreshToken = null
    }

    fun hasTokens(): Boolean {
        return accessToken != null && refreshToken != null
    }
}
