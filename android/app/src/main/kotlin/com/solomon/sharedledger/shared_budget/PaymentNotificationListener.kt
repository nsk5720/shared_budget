package com.solomon.sharedledger.shared_budget

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

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
        addPart(extras.getCharSequence(Notification.EXTRA_TEXT))
        addPart(extras.getCharSequence(Notification.EXTRA_BIG_TEXT))
        addPart(extras.getCharSequence(Notification.EXTRA_SUB_TEXT))
        extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)?.forEach(::addPart)

        val body = parts.joinToString("\n")
        if (!PaymentQueue.amountPattern.containsMatchIn(body) ||
            !paymentKeywordPattern.containsMatchIn(body)
        ) {
            return
        }

        val appLabel = runCatching {
            val applicationInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(applicationInfo).toString()
        }.getOrDefault(packageName)

        PaymentQueue.enqueue(applicationContext, appLabel, body)
    }

    companion object {
        private val paymentKeywordPattern = Regex(
            "승인|결제|사용|출금|입금|취소|환불|일시불|할부|체크카드|신용카드",
            RegexOption.IGNORE_CASE,
        )

        // 일반 SMS를 결제 Push로 오인하지 않도록 문자 앱 알림은 제외합니다.
        private val messagingPackages = setOf(
            "com.google.android.apps.messaging",
            "com.samsung.android.messaging",
            "com.android.mms",
        )
    }
}
