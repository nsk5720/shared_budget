package com.solomon.sharedledger.shared_budget

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Telephony
import androidx.core.app.NotificationCompat
import org.json.JSONArray

class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            return
        }

        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
        if (messages.isEmpty()) {
            return
        }

        val sender = messages.first().originatingAddress.orEmpty()
        val body = messages.joinToString(separator = "") { it.messageBody.orEmpty() }
        if (!Regex("""[\d,]+\s*원""").containsMatchIn(body)) {
            return
        }
        val value = "$sender\n$body"

        val preferences = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        val queue = JSONArray(preferences.getString(pendingSmsQueueKey, "[]"))
        queue.put(value)
        preferences.edit().putString(pendingSmsQueueKey, queue.toString()).apply()

        showPendingNotification(context, body, queue.length())
    }

    companion object {
        const val preferencesName = "shared_budget_sms"
        const val pendingSmsQueueKey = "pending_sms_queue"
        const val disclosureConsentKey = "sms_disclosure_consent"
        const val notificationChannelId = "payment_sms"
        const val notificationId = 2107
        const val openSmsExtra = "open_pending_sms"

        fun showPendingNotification(context: Context, body: String, count: Int) {
            val manager = context.getSystemService(NotificationManager::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                manager.createNotificationChannel(
                    NotificationChannel(
                        notificationChannelId,
                        "결제 문자",
                        NotificationManager.IMPORTANCE_HIGH,
                    ).apply {
                        description = "결제 문자를 가계부에 저장하도록 알려줍니다."
                    },
                )
            }

            val openIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra(openSmsExtra, true)
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
                // 알림 권한을 거절해도 문자 대기열은 보존합니다.
            }
        }
    }
}
