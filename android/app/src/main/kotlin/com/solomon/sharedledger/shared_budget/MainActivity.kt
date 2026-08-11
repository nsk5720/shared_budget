package com.solomon.sharedledger.shared_budget

import android.Manifest
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray

class MainActivity : FlutterActivity() {
    private val channelName = "shared_budget/sms"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        )
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestSmsPermission" -> {
                    val permissions = mutableListOf<String>()
                    if (ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.RECEIVE_SMS,
                        ) != PackageManager.PERMISSION_GRANTED
                    ) {
                        permissions.add(Manifest.permission.RECEIVE_SMS)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                        ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.POST_NOTIFICATIONS,
                        ) != PackageManager.PERMISSION_GRANTED
                    ) {
                        permissions.add(Manifest.permission.POST_NOTIFICATIONS)
                    }

                    if (permissions.isNotEmpty()) {
                        ActivityCompat.requestPermissions(
                            this,
                            permissions.toTypedArray(),
                            1001,
                        )
                    }
                    result.success(permissions.isEmpty())
                }

                "hasSmsPermission" -> {
                    result.success(
                        ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.RECEIVE_SMS,
                        ) == PackageManager.PERMISSION_GRANTED,
                    )
                }

                "getPendingSms" -> {
                    val preferences = getSharedPreferences(
                        SmsReceiver.preferencesName,
                        MODE_PRIVATE,
                    )
                    val queue = JSONArray(
                        preferences.getString(SmsReceiver.pendingSmsQueueKey, "[]"),
                    )
                    result.success(if (queue.length() > 0) queue.getString(0) else null)
                }

                "clearPendingSms" -> {
                    val preferences = getSharedPreferences(
                        SmsReceiver.preferencesName,
                        MODE_PRIVATE,
                    )
                    val queue = JSONArray(
                        preferences.getString(SmsReceiver.pendingSmsQueueKey, "[]"),
                    )
                    if (queue.length() > 0) {
                        queue.remove(0)
                    }
                    preferences.edit()
                        .putString(SmsReceiver.pendingSmsQueueKey, queue.toString())
                        .apply()

                    if (queue.length() == 0) {
                        getSystemService(NotificationManager::class.java)
                            .cancel(SmsReceiver.notificationId)
                    } else {
                        val nextValue = queue.getString(0)
                        val nextBody = nextValue.substringAfter("\n", nextValue)
                        SmsReceiver.showPendingNotification(
                            this,
                            nextBody,
                            queue.length(),
                        )
                    }
                    result.success(queue.length())
                }

                else -> result.notImplemented()
            }
        }

        if (intent?.getBooleanExtra(SmsReceiver.openSmsExtra, false) == true) {
            methodChannel?.invokeMethod("smsNotificationTapped", null)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.getBooleanExtra(SmsReceiver.openSmsExtra, false)) {
            methodChannel?.invokeMethod("smsNotificationTapped", null)
        }
    }
}
