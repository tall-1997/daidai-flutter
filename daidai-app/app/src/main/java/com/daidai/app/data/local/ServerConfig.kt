package com.daidai.app.data.local

import android.content.Context
import android.content.SharedPreferences
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ServerConfig @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val prefs: SharedPreferences = context.getSharedPreferences("server_config", Context.MODE_PRIVATE)
    
    companion object {
        private const val KEY_SERVER_URL = "server_url"
        private const val KEY_USERNAME = "username"
        private const val KEY_PASSWORD = "password"
        private const val KEY_REMEMBER_ME = "remember_me"
        private const val DEFAULT_SERVER_URL = "http://127.0.0.1:5700"
    }
    
    var serverUrl: String
        get() = prefs.getString(KEY_SERVER_URL, DEFAULT_SERVER_URL) ?: DEFAULT_SERVER_URL
        set(value) = prefs.edit().putString(KEY_SERVER_URL, value).apply()
    
    var username: String
        get() = prefs.getString(KEY_USERNAME, "") ?: ""
        set(value) = prefs.edit().putString(KEY_USERNAME, value).apply()
    
    var password: String
        get() = prefs.getString(KEY_PASSWORD, "") ?: ""
        set(value) = prefs.edit().putString(KEY_PASSWORD, value).apply()
    
    var rememberMe: Boolean
        get() = prefs.getBoolean(KEY_REMEMBER_ME, false)
        set(value) = prefs.edit().putBoolean(KEY_REMEMBER_ME, value).apply()
    
    fun saveLoginInfo(username: String, password: String, rememberMe: Boolean) {
        if (rememberMe) {
            this.username = username
            this.password = password
            this.rememberMe = true
        } else {
            this.username = ""
            this.password = ""
            this.rememberMe = false
        }
    }
    
    fun getSavedLoginInfo(): Triple<String, String, Boolean> {
        return Triple(username, password, rememberMe)
    }
    
    fun clearSavedLoginInfo() {
        username = ""
        password = ""
        rememberMe = false
    }
}
