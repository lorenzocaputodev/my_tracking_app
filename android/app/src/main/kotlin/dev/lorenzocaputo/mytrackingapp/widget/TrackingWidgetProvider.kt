package dev.lorenzocaputo.mytrackingapp.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import dev.lorenzocaputo.mytrackingapp.MainActivity
import dev.lorenzocaputo.mytrackingapp.R
import org.json.JSONArray
import org.json.JSONObject
import java.text.NumberFormat
import java.time.LocalDate
import java.time.OffsetDateTime
import java.time.ZoneId
import java.util.Currency
import java.util.Locale
import java.util.UUID

class TrackingWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        appWidgetIds.forEach { updateWidget(context, appWidgetManager, it) }
        scheduleMidnightRefresh(context)
    }

    override fun onEnabled(context: Context) {
        updateAllWidgets(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        context.getSystemService(AlarmManager::class.java)?.cancel(midnightRefreshIntent(context))
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        appWidgetIds.forEach { WidgetPreferences.removeConfiguredProductId(context, it) }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        updateWidget(context, appWidgetManager, appWidgetId)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_INCREMENT, ACTION_MIDNIGHT_REFRESH -> updateAllWidgets(context)
        }
    }

    internal fun handleIncrement(context: Context, productId: String) {
        val products = WidgetPreferences.readProducts(context) ?: run {
            updateAllWidgets(context)
            return
        }
        val product = findProductById(products, productId) ?: run {
            updateAllWidgets(context)
            return
        }
        if (isArchivedProduct(product)) {
            updateAllWidgets(context)
            return
        }
        val snapshot = readValidSnapshot(context, productId) ?: run {
            updateAllWidgets(context)
            return
        }

        val tracksInventory = snapshot.optBoolean(
            "tracksInventory",
            product.optBoolean("tracksInventory", true)
        )
        val remaining = snapshot.optInt("packRemaining", product.optInt("packRemaining", 0))
        if (tracksInventory && remaining <= 0) {
            updateAllWidgets(context)
            return
        }

        val updatedRemaining = if (tracksInventory) remaining - 1 else remaining

        val pieces = snapshot.optInt("pieces", product.optInt("pieces", 1)).coerceAtLeast(1)
        val unitCost = if (snapshot.has("unitCost")) {
            snapshot.optDouble("unitCost", 0.0)
        } else {
            product.optDouble("totalCost", 0.0) / pieces.toDouble()
        }
        val minutesLostPerUnit = snapshot.optInt("minutesLostPerUnit", product.optInt("minutesLost", 0))
        val now = OffsetDateTime.now(ZoneId.systemDefault())
        val pendingEntry = JSONObject().apply {
            put("id", UUID.randomUUID().toString())
            put("timestamp", now.toString())
            put("costDeducted", unitCost)
            put("minutesLost", minutesLostPerUnit)
            put("productId", productId)
            put("deductStock", tracksInventory)
        }
        WidgetPreferences.appendPendingEntry(context, pendingEntry)

        val updatedSnapshot = buildSnapshotAfterIncrement(
            snapshot = snapshot,
            product = product,
            tracksInventory = tracksInventory,
            updatedRemaining = updatedRemaining,
            dayKey = now.toLocalDate().toString()
        )
        WidgetPreferences.putWidgetSnapshotForProduct(context, productId, updatedSnapshot)

        val activeProductId = WidgetPreferences.readActiveProductId(context)
        if (activeProductId == productId) {
            WidgetPreferences.putString(context, "widget_snapshot_v1", updatedSnapshot.toString())
        }

        updateAllWidgets(context)
    }

    private fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val size = resolveWidgetSize(appWidgetManager.getAppWidgetOptions(appWidgetId))
        val views = RemoteViews(context.packageName, size.layoutRes)
        val texts = WidgetPreferences.localizedContext(context)
        paint(context, views, size, if (WidgetPreferences.readWidgetTheme(context) == "light") WidgetPalette.LIGHT else WidgetPalette.DARK)
        bindLabels(texts, views, size)
        val products = WidgetPreferences.readProducts(context)
        val product = products?.let { list ->
            listOfNotNull(
                WidgetPreferences.readConfiguredProductId(context, appWidgetId),
                WidgetPreferences.readActiveProductId(context)
            ).firstNotNullOfOrNull { productId ->
                findProductById(list, productId)?.takeUnless { isArchivedProduct(it) }
            }
        }

        if (product == null || isArchivedProduct(product)) {
            bindEmptyState(context, texts, views)
            appWidgetManager.updateAppWidget(appWidgetId, views)
            return
        }

        val productId = product.optString("id")
        val snapshot = readValidSnapshot(context, productId)
        if (snapshot == null) {
            bindSnapshotUnavailableState(context, texts, views)
            appWidgetManager.updateAppWidget(appWidgetId, views)
            return
        }

        val isToday = snapshot.optString("dayKeyLocal") == LocalDate.now(ZoneId.systemDefault()).toString()

        val defaultName = texts.getString(R.string.widget_default_product)
        bindCommonState(
            context = context,
            texts = texts,
            views = views,
            productId = productId,
            name = snapshot.optString("name", defaultName).ifBlank { defaultName },
            tracksInventory = snapshot.optBoolean("tracksInventory", product.optBoolean("tracksInventory", true)),
            remaining = snapshot.optInt("packRemaining", 0),
            pieces = snapshot.optInt("pieces", 1).coerceAtLeast(1),
            unitCost = snapshot.optDouble("unitCost", 0.0),
            dailyCount = if (isToday) snapshot.optInt("dailyCount", 0) else 0,
            dailyCost = if (isToday) snapshot.optDouble("dailyCost", 0.0) else 0.0,
            dailyMinutes = if (isToday) snapshot.optInt("dailyMinutesLost", 0) else 0,
            totalSpent = snapshot.optDouble("totalSpentForActive", 0.0),
            size = size
        )

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun readValidSnapshot(context: Context, productId: String): JSONObject? =
        WidgetPreferences.readWidgetSnapshotForProduct(context, productId)
            ?.takeIf { isValidSnapshotForProduct(it, productId) }
            ?: WidgetPreferences.readWidgetSnapshot(context)
                ?.takeIf { isValidSnapshotForProduct(it, productId) }

    private fun isValidSnapshotForProduct(snapshot: JSONObject, productId: String): Boolean {
        if (snapshot.optString("activeProductId") != productId) return false
        return snapshot.has("name") &&
            snapshot.has("tracksInventory") &&
            snapshot.has("pieces") &&
            snapshot.has("packRemaining") &&
            snapshot.has("minutesLostPerUnit") &&
            snapshot.has("unitCost") &&
            snapshot.has("dailyCount") &&
            snapshot.has("dailyCost") &&
            snapshot.has("dailyMinutesLost") &&
            snapshot.has("totalSpentForActive") &&
            snapshot.has("dayKeyLocal")
    }

    private fun buildSnapshotAfterIncrement(
        snapshot: JSONObject,
        product: JSONObject,
        tracksInventory: Boolean,
        updatedRemaining: Int,
        dayKey: String
    ): JSONObject {
        val pieces = snapshot.optInt("pieces", product.optInt("pieces", 1)).coerceAtLeast(1)
        val unitCost = if (snapshot.has("unitCost")) {
            snapshot.optDouble("unitCost", 0.0)
        } else {
            product.optDouble("totalCost", 0.0) / pieces.toDouble()
        }
        val minutesLostPerUnit = snapshot.optInt("minutesLostPerUnit", product.optInt("minutesLost", 0))
        val sameDay = snapshot.optString("dayKeyLocal") == dayKey
        val nextDailyCount = if (sameDay) snapshot.optInt("dailyCount", 0) + 1 else 1
        val nextDailyCost = if (sameDay) snapshot.optDouble("dailyCost", 0.0) + unitCost else unitCost
        val nextDailyMinutes = if (sameDay) {
            snapshot.optInt("dailyMinutesLost", 0) + minutesLostPerUnit
        } else {
            minutesLostPerUnit
        }
        val nextTotalSpent = snapshot.optDouble("totalSpentForActive", 0.0) + unitCost

        return JSONObject().apply {
            put("activeProductId", product.optString("id"))
            put("name", snapshot.optString("name", product.optString("name")).ifBlank {
                product.optString("name")
            })
            put("tracksInventory", tracksInventory)
            put("pieces", pieces)
            put("packRemaining", updatedRemaining)
            put("minutesLostPerUnit", minutesLostPerUnit)
            put("unitCost", unitCost)
            put("dailyCount", nextDailyCount)
            put("dailyCost", nextDailyCost)
            put("dailyMinutesLost", nextDailyMinutes)
            put("totalSpentForActive", nextTotalSpent)
            put("dayKeyLocal", dayKey)
            put("updatedAtEpochMs", System.currentTimeMillis())
        }
    }

    private fun findProductById(products: JSONArray, productId: String): JSONObject? {
        for (index in 0 until products.length()) {
            val product = products.optJSONObject(index) ?: continue
            if (product.optString("id") == productId) {
                return product
            }
        }
        return null
    }

    private fun isArchivedProduct(product: JSONObject): Boolean =
        product.optBoolean("isArchived", false)

    private fun bindLabels(texts: Context, views: RemoteViews, size: WidgetSize) {
        if (size != WidgetSize.LARGE) return
        views.setTextViewText(R.id.widget_stat_cost_label, texts.getString(R.string.widget_spent_today))
        views.setTextViewText(R.id.widget_stat_minutes_label, texts.getString(R.string.widget_life_lost))
        views.setTextViewText(R.id.widget_stat_total_label, texts.getString(R.string.widget_total_spent))
    }

    private fun bindEmptyState(context: Context, texts: Context, views: RemoteViews) {
        views.setTextViewText(R.id.widget_product_name, texts.getString(R.string.widget_no_product))
        views.setTextViewText(R.id.widget_increment, texts.getString(R.string.widget_open_app))
        views.setTextViewText(R.id.widget_count, "0")
        views.setTextViewText(R.id.widget_count_label, texts.getString(R.string.widget_total_today))
        views.setTextViewText(R.id.widget_hint, texts.getString(R.string.widget_hint_configure))
        views.setTextViewText(R.id.widget_cost_today_value, formatCurrency(texts, 0.0))
        views.setTextViewText(R.id.widget_minutes_today_value, "--")
        views.setTextViewText(R.id.widget_total_cost_value, formatCurrency(texts, 0.0))
        views.setOnClickPendingIntent(R.id.widget_root, openAppIntent(context))
        views.setOnClickPendingIntent(R.id.widget_increment, openAppIntent(context))
        views.setViewVisibility(R.id.widget_hint, View.VISIBLE)
    }

    private fun bindSnapshotUnavailableState(context: Context, texts: Context, views: RemoteViews) {
        views.setTextViewText(R.id.widget_product_name, texts.getString(R.string.widget_open_app))
        views.setTextViewText(R.id.widget_increment, texts.getString(R.string.widget_open_app))
        views.setTextViewText(R.id.widget_count, "--")
        views.setTextViewText(R.id.widget_count_label, texts.getString(R.string.widget_syncing))
        views.setTextViewText(R.id.widget_hint, texts.getString(R.string.widget_hint_resync))
        views.setTextViewText(R.id.widget_cost_today_value, formatCurrency(texts, 0.0))
        views.setTextViewText(R.id.widget_minutes_today_value, "--")
        views.setTextViewText(R.id.widget_total_cost_value, formatCurrency(texts, 0.0))
        views.setOnClickPendingIntent(R.id.widget_root, openAppIntent(context))
        views.setOnClickPendingIntent(R.id.widget_increment, openAppIntent(context))
        views.setViewVisibility(R.id.widget_hint, View.VISIBLE)
    }

    private fun bindCommonState(
        context: Context,
        texts: Context,
        views: RemoteViews,
        productId: String,
        name: String,
        tracksInventory: Boolean,
        remaining: Int,
        pieces: Int,
        unitCost: Double,
        dailyCount: Int,
        dailyCost: Double,
        dailyMinutes: Int,
        totalSpent: Double,
        size: WidgetSize
    ) {
        views.setTextViewText(R.id.widget_product_name, name)
        views.setTextViewText(
            R.id.widget_increment,
            texts.getString(
                if (!tracksInventory || remaining > 0) R.string.widget_add else R.string.widget_open_app
            )
        )
        views.setOnClickPendingIntent(
            R.id.widget_increment,
            if (!tracksInventory || remaining > 0) incrementIntent(context, productId) else openAppIntent(context)
        )
        views.setOnClickPendingIntent(R.id.widget_root, openAppIntent(context))

        if (size != WidgetSize.SMALL) {
            views.setTextViewText(R.id.widget_count, dailyCount.toString())
            views.setTextViewText(R.id.widget_count_label, texts.getString(R.string.widget_total_today))
            views.setTextViewText(
                R.id.widget_hint,
                if (tracksInventory) {
                    texts.getString(R.string.widget_hint_stock, remaining, pieces, formatCurrency(texts, unitCost))
                } else {
                    texts.getString(R.string.widget_hint_no_stock, formatCurrency(texts, unitCost))
                }
            )
            views.setViewVisibility(R.id.widget_hint, View.VISIBLE)
        }

        if (size == WidgetSize.SMALL) {
            views.setTextViewText(R.id.widget_count, dailyCount.toString())
            views.setViewVisibility(R.id.widget_count, View.VISIBLE)
        }

        if (size == WidgetSize.LARGE) {
            views.setTextViewText(R.id.widget_cost_today_value, formatCurrency(texts, dailyCost))
            views.setTextViewText(
                R.id.widget_minutes_today_value,
                if (dailyMinutes > 0) "${dailyMinutes}m" else "--"
            )
            views.setTextViewText(R.id.widget_total_cost_value, formatCurrency(texts, totalSpent))
        }
    }

    private fun paint(context: Context, views: RemoteViews, size: WidgetSize, palette: WidgetPalette) {
        val primary = context.getColor(palette.primary)
        val muted = context.getColor(palette.muted)
        views.setInt(R.id.widget_root, "setBackgroundResource", palette.background)
        views.setInt(R.id.widget_increment, "setBackgroundResource", palette.button)
        views.setTextColor(R.id.widget_product_name, primary)
        views.setTextColor(R.id.widget_count, context.getColor(palette.count))
        views.setTextColor(R.id.widget_count_label, muted)
        views.setTextColor(R.id.widget_hint, muted)
        views.setTextColor(R.id.widget_cost_today_value, primary)
        views.setTextColor(R.id.widget_minutes_today_value, primary)
        views.setTextColor(R.id.widget_total_cost_value, primary)
        if (size == WidgetSize.SMALL) {
            views.setInt(R.id.widget_count, "setBackgroundResource", palette.stat)
        }
        if (size == WidgetSize.LARGE) {
            listOf(R.id.widget_stat_cost, R.id.widget_stat_minutes, R.id.widget_stat_total).forEach {
                views.setInt(it, "setBackgroundResource", palette.stat)
            }
            listOf(R.id.widget_stat_cost_label, R.id.widget_stat_minutes_label, R.id.widget_stat_total_label).forEach {
                views.setTextColor(it, context.getColor(palette.faint))
            }
        }
    }

    private fun resolveWidgetSize(options: Bundle): WidgetSize {
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        return when {
            minWidth < 180 || minHeight < 100 -> WidgetSize.SMALL
            minWidth < 280 || minHeight < 190 -> WidgetSize.MEDIUM
            else -> WidgetSize.LARGE
        }
    }

    private fun formatCurrency(texts: Context, value: Double): String {
        val language = texts.resources.configuration.locales[0].language
        val locale = if (language == "it") Locale.ITALY else Locale.US
        return NumberFormat.getCurrencyInstance(locale).apply {
            currency = Currency.getInstance("EUR")
        }.format(value)
    }

    private fun incrementIntent(context: Context, productId: String): PendingIntent {
        val intent = Intent(context, WidgetActionReceiver::class.java).apply {
            action = ACTION_INCREMENT
            putExtra(EXTRA_PRODUCT_ID, productId)
        }
        return PendingIntent.getBroadcast(
            context,
            productId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun openAppIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        return PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    companion object {
        const val ACTION_INCREMENT = "dev.lorenzocaputo.mytrackingapp.widget.ACTION_INCREMENT"
        const val EXTRA_PRODUCT_ID = "extra_product_id"
        const val ACTION_MIDNIGHT_REFRESH = "dev.lorenzocaputo.mytrackingapp.widget.ACTION_MIDNIGHT_REFRESH"

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, TrackingWidgetProvider::class.java))
            ids.forEach { appWidgetId ->
                TrackingWidgetProvider().updateWidget(context, manager, appWidgetId)
            }
            if (ids.isNotEmpty()) scheduleMidnightRefresh(context)
        }

        private fun scheduleMidnightRefresh(context: Context) {
            val zone = ZoneId.systemDefault()
            val nextMidnight = LocalDate.now(zone).plusDays(1).atStartOfDay(zone).toInstant().toEpochMilli()
            context.getSystemService(AlarmManager::class.java)
                ?.set(AlarmManager.RTC, nextMidnight, midnightRefreshIntent(context))
        }

        private fun midnightRefreshIntent(context: Context): PendingIntent {
            val intent = Intent(context, WidgetActionReceiver::class.java).apply {
                action = ACTION_MIDNIGHT_REFRESH
            }
            return PendingIntent.getBroadcast(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        fun updateSingleWidget(context: Context, appWidgetId: Int) {
            val manager = AppWidgetManager.getInstance(context)
            TrackingWidgetProvider().updateWidget(context, manager, appWidgetId)
        }
    }
}

private enum class WidgetSize(val layoutRes: Int) {
    SMALL(R.layout.tracking_widget_small),
    MEDIUM(R.layout.tracking_widget_medium),
    LARGE(R.layout.tracking_widget_large)
}

private enum class WidgetPalette(
    val background: Int,
    val stat: Int,
    val button: Int,
    val primary: Int,
    val muted: Int,
    val faint: Int,
    val count: Int
) {
    DARK(
        R.drawable.widget_background,
        R.drawable.widget_stat_background,
        R.drawable.widget_button_background,
        R.color.widget_text_primary,
        R.color.widget_text_muted,
        R.color.widget_text_faint,
        R.color.widget_count
    ),
    LIGHT(
        R.drawable.widget_background_light,
        R.drawable.widget_stat_background_light,
        R.drawable.widget_button_background_light,
        R.color.widget_light_text_primary,
        R.color.widget_light_text_muted,
        R.color.widget_light_text_faint,
        R.color.widget_light_count
    )
}
