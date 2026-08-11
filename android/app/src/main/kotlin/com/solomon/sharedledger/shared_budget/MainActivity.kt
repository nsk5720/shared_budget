package com.solomon.sharedledger.shared_budget

import android.Manifest
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
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

                "hasSmsDisclosureConsent" -> {
                    val preferences = getSharedPreferences(
                        PaymentQueue.preferencesName,
                        MODE_PRIVATE,
                    )
                    result.success(
                        preferences.getBoolean(
                            PaymentQueue.disclosureConsentKey,
                            false,
                        ),
                    )
                }

                "saveSmsDisclosureConsent" -> {
                    getSharedPreferences(
                        PaymentQueue.preferencesName,
                        MODE_PRIVATE,
                    ).edit()
                        .putBoolean(PaymentQueue.disclosureConsentKey, true)
                        .apply()
                    result.success(null)
                }

                "hasNotificationAccess" -> {
                    result.success(
                        NotificationManagerCompat.getEnabledListenerPackages(this)
                            .contains(packageName),
                    )
                }

                "openNotificationAccessSettings" -> {
                    startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                    result.success(null)
                }

                "getPendingSms" -> {
                    val preferences = getSharedPreferences(
                        PaymentQueue.preferencesName,
                        MODE_PRIVATE,
                    )
                    val queue = JSONArray(
                        preferences.getString(PaymentQueue.pendingQueueKey, "[]"),
                    )
                    result.success(if (queue.length() > 0) queue.getString(0) else null)
                }

                "clearPendingSms" -> {
                    val preferences = getSharedPreferences(
                        PaymentQueue.preferencesName,
                        MODE_PRIVATE,
                    )
                    val queue = JSONArray(
                        preferences.getString(PaymentQueue.pendingQueueKey, "[]"),
                    )
                    if (queue.length() > 0) {
                        queue.remove(0)
                    }
                    preferences.edit()
                        .putString(PaymentQueue.pendingQueueKey, queue.toString())
                        .apply()

                    if (queue.length() == 0) {
                        getSystemService(NotificationManager::class.java)
                            .cancel(PaymentQueue.notificationId)
                    } else {
                        val nextValue = queue.getString(0)
                        val nextBody = nextValue.substringAfter("\n", nextValue)
                        PaymentQueue.showPendingNotification(
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

        if (intent?.getBooleanExtra(PaymentQueue.openPaymentExtra, false) == true) {
            methodChannel?.invokeMethod("smsNotificationTapped", null)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.getBooleanExtra(PaymentQueue.openPaymentExtra, false)) {
            methodChannel?.invokeMethod("smsNotificationTapped", null)
        }
    }
}
