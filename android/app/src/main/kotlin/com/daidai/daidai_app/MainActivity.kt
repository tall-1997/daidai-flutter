package com.daidai.daidai_app

import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.yzq.bsdiff.BsDiffTool
import java.io.File
import java.security.MessageDigest
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.Executors
import java.util.concurrent.Future
import java.util.concurrent.RejectedExecutionException
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

class MainActivity : FlutterActivity() {
    private val ROOT_CHANNEL = "com.daidai.app/root"
    private val INSTALL_CHANNEL = "com.daidai.panel/app_install"
    private val updateExecutor = Executors.newSingleThreadExecutor()
    private val rootExecutor = ThreadPoolExecutor(
        1,
        1,
        0L,
        TimeUnit.MILLISECONDS,
        ArrayBlockingQueue(8)
    )
    private val rootStreamExecutor = Executors.newFixedThreadPool(2)
    private val destroyed = AtomicBoolean(false)
    private val activeRootProcess = AtomicReference<Process?>(null)
    private val maxRootOutputCharacters = 200_000

    private var isRootChecked = false
    private var isRootAvailable = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ROOT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isRooted" -> {
                    submitRootOperation(result) { Result.success(isRooted()) }
                }
                "executeAsRoot" -> {
                    val command = call.argument<String>("command")
                    if (command != null) {
                        submitRootOperation(result) { executeAsRoot(command) }
                    } else {
                        result.error("INVALID_ARGS", "Command is required", null)
                    }
                }
                "readFileAsRoot" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        submitRootOperation(result) { readFileAsRoot(path) }
                    } else {
                        result.error("INVALID_ARGS", "Path is required", null)
                    }
                }
                "listDirectoryAsRoot" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        submitRootOperation(result) { listDirectoryAsRoot(path) }
                    } else {
                        result.error("INVALID_ARGS", "Path is required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INSTALL_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "installApk" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        try {
                            installApk(path)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("INSTALL_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Path is required", null)
                    }
                }
                "getInstalledApkInfo" -> {
                    updateExecutor.execute {
                        try {
                            val sourceApk = File(applicationInfo.sourceDir)
                            val packageInfo = packageManager.getPackageInfo(packageName, 0)
                            val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                                packageInfo.longVersionCode
                            } else {
                                @Suppress("DEPRECATION")
                                packageInfo.versionCode.toLong()
                            }
                            val info = mapOf(
                                "packageName" to packageName,
                                "versionName" to packageInfo.versionName,
                                "versionCode" to versionCode,
                                "size" to sourceApk.length(),
                                "md5" to digest(sourceApk, "MD5"),
                                "sha256" to digest(sourceApk, "SHA-256")
                            )
                            runOnUiThread { result.success(info) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("APK_INFO_ERROR", e.message, null) }
                        }
                    }
                }
                "applyPatch" -> {
                    val patchPath = call.argument<String>("patchPath")
                    val outputName = call.argument<String>("outputName")
                    if (patchPath.isNullOrBlank() || outputName.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "Patch path and output name are required", null)
                        return@setMethodCallHandler
                    }
                    updateExecutor.execute {
                        try {
                            val updateDir = File(cacheDir, "updates").apply { mkdirs() }.canonicalFile
                            val patchFile = File(patchPath).canonicalFile
                            if (patchFile.parentFile != updateDir || !patchFile.exists()) {
                                throw SecurityException("Patch file is outside the update directory")
                            }
                            val outputFile = File(updateDir, outputName).canonicalFile
                            if (outputFile.parentFile != updateDir || !outputFile.name.endsWith(".apk")) {
                                throw SecurityException("Output file is invalid")
                            }
                            if (outputFile.exists()) outputFile.delete()
                            val status = BsDiffTool.patch(
                                applicationInfo.sourceDir,
                                patchFile.absolutePath,
                                outputFile.absolutePath
                            )
                            if (status != 0 || !outputFile.exists()) {
                                throw IllegalStateException("bspatch failed with status $status")
                            }
                            runOnUiThread { result.success(mapOf("path" to outputFile.absolutePath)) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("PATCH_ERROR", e.message, null) }
                        }
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

    }

    override fun onDestroy() {
        destroyed.set(true)
        activeRootProcess.getAndSet(null)?.destroy()
        rootExecutor.shutdownNow()
        rootStreamExecutor.shutdownNow()
        updateExecutor.shutdownNow()
        super.onDestroy()
    }

    private fun <T> deliverRootResult(result: MethodChannel.Result, output: Result<T>) {
        if (destroyed.get()) return
        runOnUiThread {
            if (destroyed.get()) return@runOnUiThread
            if (output.isSuccess) {
                result.success(output.getOrNull())
            } else {
                result.error("ROOT_ERROR", output.exceptionOrNull()?.message, null)
            }
        }
    }

    private fun <T> submitRootOperation(
        result: MethodChannel.Result,
        operation: () -> Result<T>
    ) {
        try {
            rootExecutor.execute { deliverRootResult(result, operation()) }
        } catch (_: RejectedExecutionException) {
            result.error("ROOT_BUSY", "Too many pending root operations", null)
        }
    }

    private fun installApk(path: String) {
        val apkFile = File(path)
        if (!apkFile.exists()) {
            throw Exception("APK file not found: $path")
        }
        val updateDir = File(cacheDir, "updates").canonicalFile
        val canonicalApk = apkFile.canonicalFile
        if (canonicalApk.parentFile != updateDir || !canonicalApk.name.endsWith(".apk")) {
            throw SecurityException("APK file is outside the update directory")
        }
        val archiveInfo = packageManager.getPackageArchiveInfo(canonicalApk.absolutePath, 0)
            ?: throw SecurityException("APK package information is invalid")
        if (archiveInfo.packageName != packageName) {
            throw SecurityException("APK package name does not match this application")
        }
        val archiveVersionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            archiveInfo.longVersionCode
        } else {
            @Suppress("DEPRECATION")
            archiveInfo.versionCode.toLong()
        }
        val currentInfo = packageManager.getPackageInfo(packageName, 0)
        val currentVersionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            currentInfo.longVersionCode
        } else {
            @Suppress("DEPRECATION")
            currentInfo.versionCode.toLong()
        }
        if (archiveVersionCode <= currentVersionCode) {
            throw SecurityException("APK version is not newer than the installed version")
        }

        val authority = "${applicationContext.packageName}.fileProvider"
        val apkUri = FileProvider.getUriForFile(this, authority, canonicalApk)

        val intent = Intent(Intent.ACTION_INSTALL_PACKAGE).apply {
            data = apkUri
            flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK
            putExtra(Intent.EXTRA_NOT_UNKNOWN_SOURCE, true)
            putExtra(Intent.EXTRA_RETURN_RESULT, true)
        }
        startActivity(intent)
    }

    private fun digest(file: File, algorithm: String): String {
        val digest = MessageDigest.getInstance(algorithm)
        file.inputStream().buffered().use { input ->
            val buffer = ByteArray(1024 * 1024)
            while (true) {
                val read = input.read(buffer)
                if (read <= 0) break
                digest.update(buffer, 0, read)
            }
        }
        return digest.digest().joinToString("") { "%02x".format(it) }
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
                    val result = consumeProcess(process)
                    result.isSuccess && result.getOrNull()?.contains("uid=0") == true
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
            consumeProcess(process)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    private fun consumeProcess(process: Process): Result<String> {
        activeRootProcess.set(process)
        var outputFuture: Future<String>? = null
        var errorFuture: Future<String>? = null

        return try {
            val outputTask = rootStreamExecutor.submit<String> {
                process.inputStream.bufferedReader().use(::readBoundedOutput)
            }
            outputFuture = outputTask
            val errorTask = rootStreamExecutor.submit<String> {
                process.errorStream.bufferedReader().use(::readBoundedOutput)
            }
            errorFuture = errorTask

            if (!waitForProcess(process, 30_000)) {
                terminateProcess(process)
                outputTask.cancel(true)
                errorTask.cancel(true)
                return Result.failure(Exception("Root command timed out"))
            }

            val output = outputTask.get(1, TimeUnit.SECONDS)
            val error = errorTask.get(1, TimeUnit.SECONDS)
            if (process.exitValue() == 0) {
                Result.success(output.trim())
            } else {
                Result.failure(Exception("Root command failed: ${error.trim()}"))
            }
        } catch (e: Exception) {
            terminateProcess(process)
            outputFuture?.cancel(true)
            errorFuture?.cancel(true)
            Result.failure(e)
        } finally {
            activeRootProcess.compareAndSet(process, null)
            runCatching { process.inputStream.close() }
            runCatching { process.errorStream.close() }
            runCatching { process.outputStream.close() }
        }
    }

    private fun readBoundedOutput(reader: java.io.BufferedReader): String {
        val output = StringBuilder()
        val buffer = CharArray(8_192)
        while (true) {
            val count = reader.read(buffer)
            if (count < 0) break
            output.append(buffer, 0, count)
            if (output.length > maxRootOutputCharacters) {
                output.delete(0, output.length - maxRootOutputCharacters)
            }
        }
        return output.toString()
    }

    private fun waitForProcess(process: Process, timeoutMillis: Long): Boolean {
        val deadline = System.nanoTime() + TimeUnit.MILLISECONDS.toNanos(timeoutMillis)
        while (System.nanoTime() < deadline && !destroyed.get()) {
            try {
                process.exitValue()
                return true
            } catch (_: IllegalThreadStateException) {
                Thread.sleep(50)
            }
        }
        return false
    }

    private fun terminateProcess(process: Process) {
        process.destroy()
        if (waitForProcess(process, 1_000)) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            process.destroyForcibly()
            waitForProcess(process, 1_000)
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
