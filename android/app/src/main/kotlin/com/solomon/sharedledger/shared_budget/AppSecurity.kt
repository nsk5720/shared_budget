package com.solomon.sharedledger.shared_budget

import android.content.Context
import java.security.MessageDigest
import java.util.UUID

object AppSecurity {
    private const val preferencesName = "shared_budget_security"
    private const val pinHashKey = "pin_hash"
    private const val saltKey = "pin_salt"

    fun hasPin(context: Context): Boolean = preferences(context).contains(pinHashKey)

    fun setPin(context: Context, pin: String) {
        val preferences = preferences(context)
        val salt = preferences.getString(saltKey, null) ?: UUID.randomUUID().toString()
        preferences.edit()
            .putString(saltKey, salt)
            .putString(pinHashKey, hash(pin, salt))
            .apply()
    }

    fun verifyPin(context: Context, pin: String): Boolean {
        val preferences = preferences(context)
        val salt = preferences.getString(saltKey, null) ?: return false
        return preferences.getString(pinHashKey, null) == hash(pin, salt)
    }

    fun removePin(context: Context) {
        preferences(context).edit().clear().apply()
    }

    private fun preferences(context: Context) =
        context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)

    private fun hash(pin: String, salt: String): String {
        val bytes = MessageDigest.getInstance("SHA-256")
            .digest("$salt:$pin".toByteArray(Charsets.UTF_8))
        return bytes.joinToString("") { "%02x".format(it) }
    }
}
