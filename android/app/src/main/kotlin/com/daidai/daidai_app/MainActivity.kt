package com.daidai.daidai_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.daidai.app/root"
    
    private var isRootChecked = false
    private var isRootAvailable = false
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isRooted" -> {
                    result.success(isRooted())
                }
                "executeAsRoot" -> {
                    val command = call.argument<String>("command")
                    if (command != null) {
                        val output = executeAsRoot(command)
                        if (output.isSuccess) {
                            result.success(output.getOrNull())
                        } else {
                            result.error("ROOT_ERROR", output.exceptionOrNull()?.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Command is required", null)
                    }
                }
                "readFileAsRoot" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        val content = readFileAsRoot(path)
                        if (content.isSuccess) {
                            result.success(content.getOrNull())
                        } else {
                            result.error("ROOT_ERROR", content.exceptionOrNull()?.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Path is required", null)
                    }
                }
                "listDirectoryAsRoot" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        val entries = listDirectoryAsRoot(path)
                        if (entries.isSuccess) {
                            result.success(entries.getOrNull())
                        } else {
                            result.error("ROOT_ERROR", entries.exceptionOrNull()?.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Path is required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun isRooted(): Boolean {
        if (isRootChecked) return isRootAvailable
        
        isRootChecked = true
        isRootAvailable = checkRootAccess()
        return isRootAvailable
    }
    
    private fun checkRootAccess(): Boolean {
        return try {
            val suPaths = listOf(
                "/system/bin/su",
                "/system/xbin/su",
                "/sbin/su",
                "/data/local/xbin/su",
                "/data/local/bin/su",
                "/system/sd/xbin/su",
                "/system/bin/failsafe/su",
                "/data/local/su",
                "/su/bin/su",
                "/system/app/Superuser.apk",
                "/system/app/SuperSU.apk",
                "/system/app/SuperSU/SuperSU.apk"
            )
            
            val suExists = suPaths.any { File(it).exists() }
            if (suExists) {
                try {
                    val process = Runtime.getRuntime().exec(arrayOf("su", "-c", "id"))
                    val result = process.inputStream.bufferedReader().readText()
                    process.waitFor()
                    result.contains("uid=0")
                } catch (e: Exception) {
                    suExists
                }
            } else {
                false
            }
        } catch (e: Exception) {
            false
        }
    }
    
    private fun executeAsRoot(command: String): Result<String> {
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("su", "-c", command))
            val output = process.inputStream.bufferedReader().readText()
            val error = process.errorStream.bufferedReader().readText()
            val exitCode = process.waitFor()
            
            if (exitCode == 0) {
                Result.success(output.trim())
            } else {
                Result.failure(Exception("Root command failed: $error"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    private fun readFileAsRoot(path: String): Result<String> {
        return executeAsRoot("cat $path")
    }
    
    private fun listDirectoryAsRoot(path: String): Result<List<String>> {
        return executeAsRoot("ls -la $path").map { output ->
            output.lines().filter { it.isNotBlank() }
        }
    }
}
