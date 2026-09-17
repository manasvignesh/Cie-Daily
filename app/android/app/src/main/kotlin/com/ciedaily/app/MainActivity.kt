package com.ciedaily.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.InstallStatus
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val updateChannel = "com.ciedaily.app/in_app_update"
    private val appUpdateManager by lazy { AppUpdateManagerFactory.create(this) }
    private val installListener = InstallStateUpdatedListener { state ->
        if (state.installStatus() == InstallStatus.DOWNLOADED) {
            appUpdateManager.completeUpdate()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "cie_daily_messages",
                "Messages and updates",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Chat messages and updates from CIE Daily"
                enableVibration(true)
            }
            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, updateChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkForUpdate" -> appUpdateManager.appUpdateInfo
                        .addOnSuccessListener { info ->
                            result.success(
                                mapOf(
                                    "updateAvailable" to
                                        (info.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE),
                                    "flexibleAllowed" to info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE),
                                ),
                            )
                        }
                        .addOnFailureListener { result.error("UPDATE_CHECK_FAILED", null, null) }
                    "startFlexibleUpdate" -> {
                        appUpdateManager.registerListener(installListener)
                        appUpdateManager.appUpdateInfo
                            .addOnSuccessListener { info ->
                                appUpdateManager.startUpdateFlow(
                                    info,
                                    this,
                                    AppUpdateOptions.newBuilder(AppUpdateType.FLEXIBLE).build(),
                                ).addOnSuccessListener { result.success(null) }
                                    .addOnFailureListener { result.error("UPDATE_START_FAILED", null, null) }
                            }
                            .addOnFailureListener { result.error("UPDATE_START_FAILED", null, null) }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        appUpdateManager.unregisterListener(installListener)
        super.onDestroy()
    }
}
