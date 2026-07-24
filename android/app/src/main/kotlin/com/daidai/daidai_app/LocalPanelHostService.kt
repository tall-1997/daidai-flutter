package com.daidai.daidai_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class LocalPanelHostService : Service() {
    companion object {
        const val PREFS_NAME = "local_panel_host"
        const val PREF_PERSISTENT_SCHEDULING = "persistent_scheduling"
        const val ACTION_STOP = "com.daidai.daidai_app.LOCAL_PANEL_STOP"
        private const val CHANNEL_ID = "local_panel_scheduler"
        private const val NOTIFICATION_ID = 5700
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification())
        LocalPanelRuntime.ensureStarted(applicationContext)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
                .edit()
                .putBoolean(PREF_PERSISTENT_SCHEDULING, false)
                .apply()
            stopSelf()
            return START_NOT_STICKY
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        LocalPanelRuntime.stop()
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                "本地面板调度",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "保持本地面板任务调度和依赖操作运行"
            }
        )
    }

    private fun buildNotification() = NotificationCompat.Builder(this, CHANNEL_ID)
        .setSmallIcon(R.mipmap.ic_launcher)
        .setContentTitle("呆呆面板本地服务")
        .setContentText("本地面板与任务调度宿主正在运行")
        .setOngoing(true)
        .setContentIntent(
            PendingIntent.getActivity(
                this,
                0,
                Intent(this, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        )
        .addAction(
            0,
            "停止",
            PendingIntent.getService(
                this,
                1,
                Intent(this, LocalPanelHostService::class.java).apply {
                    action = ACTION_STOP
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        )
        .build()
}
