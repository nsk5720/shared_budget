package com.solomon.sharedledger.shared_budget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class BudgetWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { widgetId -> update(context, appWidgetManager, widgetId) }
    }

    companion object {
        private const val preferencesName = "shared_budget_widget"

        fun updateAll(context: Context, expense: Long, budget: Long) {
            context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
                .edit()
                .putLong("expense", expense)
                .putLong("budget", budget)
                .apply()
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, BudgetWidgetProvider::class.java)
            manager.getAppWidgetIds(component).forEach { update(context, manager, it) }
        }

        private fun update(
            context: Context,
            manager: AppWidgetManager,
            widgetId: Int,
        ) {
            val preferences = context.getSharedPreferences(
                preferencesName,
                Context.MODE_PRIVATE,
            )
            val expense = preferences.getLong("expense", 0L)
            val budget = preferences.getLong("budget", 0L)
            val remainingText = if (budget > 0) {
                val remaining = budget - expense
                if (remaining >= 0) {
                    "남은 예산 ${String.format("%,d", remaining)}원"
                } else {
                    "예산 초과 ${String.format("%,d", -remaining)}원"
                }
            } else {
                "앱에서 월 예산을 설정해 주세요"
            }
            val views = RemoteViews(context.packageName, R.layout.budget_widget).apply {
                setTextViewText(R.id.widget_expense, "${String.format("%,d", expense)}원")
                setTextViewText(R.id.widget_remaining, remainingText)
                setOnClickPendingIntent(
                    R.id.widget_root,
                    PendingIntent.getActivity(
                        context,
                        3301,
                        Intent(context, MainActivity::class.java),
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                    ),
                )
            }
            manager.updateAppWidget(widgetId, views)
        }
    }
}
