package com.solomon.sharedledger.shared_budget

import android.Manifest
import android.app.Activity
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
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private val channelName = "shared_budget/sms"
    private val settingsChannelName = "shared_budget/settings"
    private var methodChannel: MethodChannel? = null
    private var settingsChannel: MethodChannel? = null
    private var pendingCsvResult: MethodChannel.Result? = null
    private var pendingCsvContent: String? = null

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
                    result.success(
                        if (queue.length() > 0) {
                            mapOf(
                                "rawMessage" to PaymentQueue.rawMessageAt(queue, 0),
                                "receivedAt" to PaymentQueue.receivedAtAt(queue, 0),
                            )
                        } else {
                            null
                        },
                    )
                }

                "getPendingPayments" -> {
                    val preferences = getSharedPreferences(
                        PaymentQueue.preferencesName,
                        MODE_PRIVATE,
                    )
                    val queue = JSONArray(
                        preferences.getString(PaymentQueue.pendingQueueKey, "[]"),
                    )
                    result.success(
                        (0 until queue.length()).map { index ->
                            mapOf(
                                "rawMessage" to PaymentQueue.rawMessageAt(queue, index),
                                "receivedAt" to PaymentQueue.receivedAtAt(queue, index),
                            )
                        },
                    )
                }

                "getPendingPaymentCount" -> {
                    val preferences = getSharedPreferences(
                        PaymentQueue.preferencesName,
                        MODE_PRIVATE,
                    )
                    val queue = JSONArray(
                        preferences.getString(PaymentQueue.pendingQueueKey, "[]"),
                    )
                    result.success(queue.length())
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
                        val nextValue = PaymentQueue.rawMessageAt(queue, 0)
                        val nextBody = nextValue.substringAfter("\n", nextValue)
                        PaymentQueue.showPendingNotification(
                            this,
                            nextBody,
                            queue.length(),
                        )
                    }
                    result.success(queue.length())
                }


                "removePendingPayments" -> {
                    val rawMessages = call.argument<List<String>>("rawMessages").orEmpty().toSet()
                    val preferences = getSharedPreferences(
                        PaymentQueue.preferencesName,
                        MODE_PRIVATE,
                    )
                    val queue = JSONArray(
                        preferences.getString(PaymentQueue.pendingQueueKey, "[]"),
                    )
                    for (index in queue.length() - 1 downTo 0) {
                        if (PaymentQueue.rawMessageAt(queue, index) in rawMessages) {
                            queue.remove(index)
                        }
                    }
                    preferences.edit()
                        .putString(PaymentQueue.pendingQueueKey, queue.toString())
                        .apply()

                    if (queue.length() == 0) {
                        getSystemService(NotificationManager::class.java)
                            .cancel(PaymentQueue.notificationId)
                    } else {
                        val nextValue = PaymentQueue.rawMessageAt(queue, 0)
                        PaymentQueue.showPendingNotification(
                            this,
                            nextValue.substringAfter("\n", nextValue),
                            queue.length(),
                        )
                    }
                    result.success(queue.length())
                }

                else -> result.notImplemented()
            }
        }

        settingsChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            settingsChannelName,
        )
        settingsChannel?.setMethodCallHandler { call, result ->
            val preferences = getSharedPreferences("shared_budget_settings", MODE_PRIVATE)
            when (call.method) {
                "getObservedNotificationApps" -> {
                    val smsPreferences = getSharedPreferences(
                        PaymentQueue.preferencesName,
                        MODE_PRIVATE,
                    )
                    val observed = JSONObject(
                        smsPreferences.getString(PaymentQueue.observedAppsKey, "{}"),
                    )
                    val selected = smsPreferences
                        .getStringSet(PaymentQueue.selectedAppsKey, emptySet())
                        .orEmpty()
                    val selectionConfigured = smsPreferences.getBoolean(
                        PaymentQueue.selectedAppsConfiguredKey,
                        false,
                    )
                    val apps = observed.keys().asSequence().map { packageName ->
                        mapOf(
                            "packageName" to packageName,
                            "label" to observed.optString(packageName, packageName),
                            "selected" to (!selectionConfigured || packageName in selected),
                        )
                    }.sortedBy { it["label"].toString() }.toList()
                    result.success(apps)
                }

                "setSelectedNotificationApps" -> {
                    val packages = call.argument<List<String>>("packages").orEmpty().toSet()
                    getSharedPreferences(PaymentQueue.preferencesName, MODE_PRIVATE)
                        .edit()
                        .putStringSet(PaymentQueue.selectedAppsKey, packages)
                        .putBoolean(PaymentQueue.selectedAppsConfiguredKey, true)
                        .apply()
                    result.success(null)
                }

                "getThemeChoice" -> result.success(
                    preferences.getString("theme_choice", "pink"),
                )

                "setThemeChoice" -> {
                    preferences.edit()
                        .putString("theme_choice", call.argument<String>("value") ?: "pink")
                        .apply()
                    result.success(null)
                }

                "hasAppPin" -> result.success(AppSecurity.hasPin(this))
                "verifyAppPin" -> result.success(
                    AppSecurity.verifyPin(this, call.argument<String>("pin").orEmpty()),
                )
                "setAppPin" -> {
                    AppSecurity.setPin(this, call.argument<String>("pin").orEmpty())
                    result.success(null)
                }
                "removeAppPin" -> {
                    AppSecurity.removePin(this)
                    result.success(null)
                }

                "showBudgetAlert" -> {
                    PaymentQueue.showBudgetAlert(
                        this,
                        call.argument<Number>("expense")?.toLong() ?: 0L,
                        call.argument<Number>("budget")?.toLong() ?: 0L,
                    )
                    result.success(null)
                }

                "updateHomeWidget" -> {
                    BudgetWidgetProvider.updateAll(
                        this,
                        call.argument<Number>("expense")?.toLong() ?: 0L,
                        call.argument<Number>("budget")?.toLong() ?: 0L,
                    )
                    result.success(null)
                }

                "exportCsv" -> {
                    if (pendingCsvResult != null) {
                        result.error("busy", "다른 파일 작업이 진행 중입니다.", null)
                    } else {
                        pendingCsvResult = result
                        pendingCsvContent = call.argument<String>("content").orEmpty()
                        val fileName = call.argument<String>("fileName")
                            ?: "shared-budget.csv"
                        startActivityForResult(
                            Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                                addCategory(Intent.CATEGORY_OPENABLE)
                                type = "text/csv"
                                putExtra(Intent.EXTRA_TITLE, fileName)
                            },
                            exportCsvRequestCode,
                        )
                    }
                }

                "importCsv" -> {
                    if (pendingCsvResult != null) {
                        result.error("busy", "다른 파일 작업이 진행 중입니다.", null)
                    } else {
                        pendingCsvResult = result
                        startActivityForResult(
                            Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                                addCategory(Intent.CATEGORY_OPENABLE)
                                type = "text/*"
                            },
                            importCsvRequestCode,
                        )
                    }
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

    @Deprecated("Deprecated in Android")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        val result = pendingCsvResult ?: return
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result.success(null)
            clearPendingCsvOperation()
            return
        }
        try {
            if (requestCode == exportCsvRequestCode) {
                val output = contentResolver.openOutputStream(data.data!!)
                    ?: error("선택한 파일을 열 수 없습니다.")
                output.bufferedWriter(Charsets.UTF_8)
                    .use { writer ->
                        writer.write("\uFEFF")
                        writer.write(pendingCsvContent.orEmpty())
                    }
                result.success(true)
            } else if (requestCode == importCsvRequestCode) {
                val input = contentResolver.openInputStream(data.data!!)
                    ?: error("선택한 파일을 열 수 없습니다.")
                val content = input.bufferedReader().use { it.readText() }
                result.success(content)
            } else {
                result.success(null)
            }
        } catch (error: Exception) {
            result.error("file_error", error.message, null)
        } finally {
            clearPendingCsvOperation()
        }
    }

    private fun clearPendingCsvOperation() {
        pendingCsvResult = null
        pendingCsvContent = null
    }

    companion object {
        private const val exportCsvRequestCode = 3101
        private const val importCsvRequestCode = 3102
    }
}
