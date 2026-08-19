package com.solomon.sharedledger.shared_budget

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import org.json.JSONObject

class PaymentNotificationListener : NotificationListenerService() {
    override fun onNotificationPosted(statusBarNotification: StatusBarNotification) {
        val packageName = statusBarNotification.packageName
        if (packageName == applicationContext.packageName || packageName in messagingPackages) {
            return
        }

        val notification = statusBarNotification.notification
        if (notification.flags and Notification.FLAG_GROUP_SUMMARY != 0) {
            return
        }

        val extras = notification.extras
        val parts = linkedSetOf<String>()
        fun addPart(value: CharSequence?) {
            value?.toString()?.trim()?.takeIf { it.isNotEmpty() }?.let(parts::add)
        }

        addPart(extras.getCharSequence(Notification.EXTRA_TITLE))
        addPart(extras.getCharSequence(Notification.EXTRA_TITLE_BIG))
        addPart(extras.getCharSequence(Notification.EXTRA_TEXT))
        addPart(extras.getCharSequence(Notification.EXTRA_BIG_TEXT))
        addPart(extras.getCharSequence(Notification.EXTRA_SUB_TEXT))
        addPart(extras.getCharSequence(Notification.EXTRA_SUMMARY_TEXT))
        addPart(extras.getCharSequence(Notification.EXTRA_INFO_TEXT))
        extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)?.forEach(::addPart)
        addPart(notification.tickerText)

        val body = parts.joinToString("\n")
        if (!PaymentQueue.amountPattern.containsMatchIn(body) ||
            !PaymentQueue.paymentKeywordPattern.containsMatchIn(body)
        ) {
            return
        }

        val appLabel = runCatching {
            val applicationInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(applicationInfo).toString()
        }.getOrDefault(packageName)

        val preferences = applicationContext.getSharedPreferences(
            PaymentQueue.preferencesName,
            MODE_PRIVATE,
        )
        val observedApps = JSONObject(
            preferences.getString(PaymentQueue.observedAppsKey, "{}"),
        )
        observedApps.put(packageName, appLabel)
        preferences.edit()
            .putString(PaymentQueue.observedAppsKey, observedApps.toString())
            .apply()

        val selectedApps = preferences
            .getStringSet(PaymentQueue.selectedAppsKey, emptySet())
            .orEmpty()
        val selectionConfigured = preferences.getBoolean(
            PaymentQueue.selectedAppsConfiguredKey,
            false,
        )
        if (selectionConfigured && packageName !in selectedApps) {
            return
        }

        PaymentQueue.enqueue(
            applicationContext,
            appLabel,
            body,
            statusBarNotification.postTime,
        )
    }

    companion object {
        // 일반 SMS를 결제 Push로 오인하지 않도록 문자 앱 알림은 제외합니다.
        private val messagingPackages = setOf(
            "com.google.android.apps.messaging",
            "com.samsung.android.messaging",
            "com.android.mms",
        )
    }
}
