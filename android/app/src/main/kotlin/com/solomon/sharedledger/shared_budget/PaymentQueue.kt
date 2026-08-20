package com.solomon.sharedledger.shared_budget

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import org.json.JSONObject

object PaymentQueue {
    const val preferencesName = "shared_budget_sms"
    const val pendingQueueKey = "pending_sms_queue"
    const val disclosureConsentKey = "sms_push_disclosure_consent_v4"
    const val notificationChannelId = "payment_sms"
    const val notificationId = 2107
    const val openPaymentExtra = "open_pending_sms"
    const val observedAppsKey = "observed_payment_apps"
    const val selectedAppsKey = "selected_payment_apps"
    const val selectedAppsConfiguredKey = "selected_payment_apps_configured"
    const val budgetNotificationChannelId = "monthly_budget"
    const val budgetNotificationId = 2110
    private const val rawMessageKey = "rawMessage"
    private const val receivedAtKey = "receivedAt"
    val amountPattern = Regex(
        """(?:(?:₩|KRW\s*)\s*[\d,]+|[\d,]+\s*(?:원|KRW))""",
        RegexOption.IGNORE_CASE,
    )
    val paymentKeywordPattern = Regex(
        "승인|결제|사용|출금|입금|취소|환불|일시불|할부|체크카드|신용카드|이체",
        RegexOption.IGNORE_CASE,
    )

    fun enqueue(
        context: Context,
        source: String,
        body: String,
        receivedAt: Long = System.currentTimeMillis(),
    ) {
        val value = "$source\n$body"
        val preferences = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        val queue = JSONArray(preferences.getString(pendingQueueKey, "[]"))

        // 같은 알림이 몇 초 안에 갱신된 경우만 중복으로 처리합니다.
        // 내용이 같아도 시간이 지난 실제 재결제는 새 내역으로 보존합니다.
        for (index in 0 until queue.length()) {
            val queuedAt = receivedAtAt(queue, index)
            if (rawMessageAt(queue, index) == value &&
                queuedAt > 0L &&
                kotlin.math.abs(receivedAt - queuedAt) < 10_000L
            ) {
                return
            }
        }

        queue.put(
            JSONObject()
                .put(rawMessageKey, value)
                .put(receivedAtKey, receivedAt),
        )
        preferences.edit()
            .putString(pendingQueueKey, queue.toString())
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

    fun showBudgetAlert(context: Context, expense: Long, budget: Long, threshold: Int) {
        if (budget <= 0L || threshold < 70) return
        val manager = context.getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    budgetNotificationChannelId,
                    "월 예산 알림",
                    NotificationManager.IMPORTANCE_HIGH,
                ).apply {
                    description = "설정한 월 예산에 도달하거나 초과하면 알려줍니다."
                },
            )
        }
        val openIntent = PendingIntent.getActivity(
            context,
            1002,
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val over = expense - budget
        val text = if (over > 0) {
            "이번 달 예산을 ${String.format("%,d", over)}원 초과했어요."
        } else if (threshold < 100) {
            "이번 달 예산의 ${threshold}%를 사용했어요. 남은 예산을 확인해 보세요."
        } else {
            "이번 달 예산에 도달했어요."
        }
        val notification = NotificationCompat.Builder(context, budgetNotificationChannelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("예산을 확인해 주세요")
            .setContentText(text)
            .setStyle(NotificationCompat.BigTextStyle().bigText(text))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(openIntent)
            .setAutoCancel(true)
            .build()
        try {
            manager.notify(budgetNotificationId + threshold, notification)
        } catch (_: SecurityException) {
            // 알림 권한이 없어도 앱 안의 예산 진행률은 계속 표시됩니다.
        }
    }

    fun rawMessageAt(queue: JSONArray, index: Int): String {
        val item = queue.opt(index)
        return if (item is JSONObject) {
            item.optString(rawMessageKey)
        } else {
            queue.optString(index)
        }
    }

    fun receivedAtAt(queue: JSONArray, index: Int): Long {
        val item = queue.opt(index)
        return if (item is JSONObject) item.optLong(receivedAtKey, 0L) else 0L
    }
}
