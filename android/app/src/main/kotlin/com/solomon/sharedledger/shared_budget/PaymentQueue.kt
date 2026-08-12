package com.solomon.sharedledger.shared_budget

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import org.json.JSONArray

object PaymentQueue {
    const val preferencesName = "shared_budget_sms"
    const val pendingQueueKey = "pending_sms_queue"
    const val disclosureConsentKey = "sms_push_disclosure_consent_v4"
    const val notificationChannelId = "payment_sms"
    const val notificationId = 2107
    const val openPaymentExtra = "open_pending_sms"
    private const val lastAmountKey = "last_payment_amount"
    private const val lastQueuedAtKey = "last_payment_queued_at"
    val amountPattern = Regex(
        """(?:(?:₩|KRW\s*)\s*[\d,]+|[\d,]+\s*(?:원|KRW))""",
        RegexOption.IGNORE_CASE,
    )
    val paymentKeywordPattern = Regex(
        "승인|결제|사용|출금|입금|취소|환불|일시불|할부|체크카드|신용카드|이체",
        RegexOption.IGNORE_CASE,
    )

    fun enqueue(context: Context, source: String, body: String) {
        val value = "$source\n$body"
        val preferences = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        val queue = JSONArray(preferences.getString(pendingQueueKey, "[]"))

        // 같은 알림이 갱신되어 여러 번 전달되는 경우 중복으로 쌓지 않습니다.
        for (index in 0 until queue.length()) {
            if (queue.optString(index) == value) {
                return
            }
        }

        // 같은 결제가 SMS와 Push로 거의 동시에 도착하면 한 건만 남깁니다.
        val amount = amountPattern.find(body)?.value?.filter { it.isDigit() }.orEmpty()
        val now = System.currentTimeMillis()
        val recentlyQueuedSameAmount = amount.isNotEmpty() &&
            preferences.getString(lastAmountKey, null) == amount &&
            now - preferences.getLong(lastQueuedAtKey, 0L) < 30_000L
        if (recentlyQueuedSameAmount) {
            return
        }

        queue.put(value)
        preferences.edit()
            .putString(pendingQueueKey, queue.toString())
            .putString(lastAmountKey, amount)
            .putLong(lastQueuedAtKey, now)
            .apply()
        showPendingNotification(context, body, queue.length())
    }

    fun showPendingNotification(context: Context, body: String, count: Int) {
        val manager = context.getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    notificationChannelId,
                    "결제 내역 확인",
                    NotificationManager.IMPORTANCE_HIGH,
                ).apply {
                    description = "은행·카드 앱 알림의 결제 내역을 확인하도록 알려줍니다."
                },
            )
        }

        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(openPaymentExtra, true)
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            1001,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val title = if (count == 1) {
            "새 결제 내역을 확인해 주세요"
        } else {
            "저장하지 않은 결제 내역 ${count}건"
        }
        val notification = NotificationCompat.Builder(context, notificationChannelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setNumber(count)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setAutoCancel(false)
            .setOngoing(true)
            .build()

        try {
            manager.notify(notificationId, notification)
        } catch (_: SecurityException) {
            // 앱 알림 표시 권한을 거절해도 결제 대기열은 보존합니다.
        }
    }
}
