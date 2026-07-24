package com.daidai.daidai_app

import android.content.Context
import fi.iki.elonen.NanoHTTPD

object LocalPanelRuntime {
    private var server: LocalPanelHttpServer? = null
    private var failure: String = ""

    @Synchronized
    fun ensureStarted(context: Context): Map<String, Any> {
        if (server?.wasStarted() == true) return status()
        return try {
            server = LocalPanelHttpServer(context.applicationContext).also {
                it.start(NanoHTTPD.SOCKET_READ_TIMEOUT, true)
            }
            failure = ""
            status()
        } catch (error: Exception) {
            server = null
            failure = error.message ?: "Local panel server failed to start"
            status()
        }
    }

    @Synchronized
    fun stop() {
        server?.stop()
        server = null
    }

    @Synchronized
    fun restart(context: Context): Map<String, Any> {
        stop()
        return ensureStarted(context)
    }

    @Synchronized
    fun status(): Map<String, Any> {
        val current = server
        val ready = current?.wasStarted() == true
        return mapOf(
            "phase" to if (ready) "ready" else if (failure.isEmpty()) "stopped" else "failed",
            "base_url" to if (ready) current!!.endpoint else "",
            "instance_id" to "android-local",
            "core_version" to "android-local-mvp",
            "schema_version" to LocalPanelStore.SCHEMA_VERSION,
            "failure_stage" to if (failure.isEmpty()) "" else "http_server",
            "message" to failure,
            "foreground_service_enabled" to false
        )
    }
}
