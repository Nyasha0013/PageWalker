package com.pagewalker.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.example.pagewalker.R
import es.antonborri.home_widget.HomeWidgetProvider

class PagewalkerWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.pagewalker_widget).apply {
                val title = widgetData.getString("widget_book_title", "No current read")
                val author = widgetData.getString("widget_author", "Add a book to start")
                val progress = widgetData.getInt("widget_progress", 0)
                val pages = widgetData.getString("widget_pages", "Tap to open Pagewalker")
                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_author, author)
                setTextViewText(R.id.widget_pages, pages)
                setProgressBar(R.id.widget_progress_bar, 100, progress.coerceIn(0, 100), false)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
