package com.teddoro.teddoro

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.util.Locale

/**
 * Home-screen / lock-screen widget. Reads the keys the Dart side publishes
 * through `home_widget` (status, type, endsAt, remaining) and drives a
 * Chronometer so the countdown ticks without waking the app.
 */
class TeddoroWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val data = HomeWidgetPlugin.getData(context)
        val status = data.getString("status", "idle") ?: "idle"
        val type = data.getString("type", "Work") ?: "Work"
        val endsAt = data.getLong("endsAt", 0L)
        val remaining = data.getInt("remaining", 0)

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.teddoro_widget)
            val launch = PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_root, launch)

            when (status) {
                "running" -> {
                    val msLeft = (endsAt - System.currentTimeMillis()).coerceAtLeast(0L)
                    views.setTextViewText(R.id.widget_label, "$type in progress")
                    views.setChronometer(
                        R.id.widget_countdown,
                        SystemClock.elapsedRealtime() + msLeft,
                        null,
                        true,
                    )
                    views.setViewVisibility(R.id.widget_countdown, View.VISIBLE)
                    views.setViewVisibility(R.id.widget_static, View.GONE)
                }
                "paused" -> {
                    views.setTextViewText(R.id.widget_label, "$type paused")
                    showStatic(views, remaining)
                }
                else -> {
                    views.setTextViewText(R.id.widget_label, context.getString(R.string.widget_idle))
                    showStatic(views, remaining)
                }
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun showStatic(views: RemoteViews, seconds: Int) {
        views.setTextViewText(R.id.widget_static, formatSeconds(seconds))
        views.setViewVisibility(R.id.widget_countdown, View.GONE)
        views.setViewVisibility(R.id.widget_static, View.VISIBLE)
    }

    private fun formatSeconds(total: Int): String =
        String.format(Locale.US, "%d:%02d", total / 60, total % 60)
}
