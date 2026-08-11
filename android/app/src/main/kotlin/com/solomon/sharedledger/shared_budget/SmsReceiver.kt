package com.solomon.sharedledger.shared_budget

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony

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
        if (!PaymentQueue.amountPattern.containsMatchIn(body) ||
            !PaymentQueue.paymentKeywordPattern.containsMatchIn(body)
        ) {
            return
        }

        PaymentQueue.enqueue(context, sender, body)
    }
}
