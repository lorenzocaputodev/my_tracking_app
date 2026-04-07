package com.example.my_tracking_app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import com.example.my_tracking_app.MainActivity
import com.example.my_tracking_app.R
import org.json.JSONArray
import org.json.JSONObject
import java.text.NumberFormat
import java.time.OffsetDateTime
import java.time.ZoneId
import java.util.Locale
import java.util.UUID

class TrackingWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        appWidgetIds.forEach { updateWidget(context, appWidgetManager, it) }
    }

    override fun onEnabled(context: Context) {
        updateAllWidgets(context)
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
        if (ACTION_INCREMENT == intent.action) {
            val productId = intent.getStringExtra(EXTRA_PRODUCT_ID) ?: return
            handleIncrement(context, productId)
        }
    }

    private fun handleIncrement(context: Context, productId: String) {
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
        val remaining = product.optInt("packRemaining", 0)
        if (tracksInventory && remaining <= 0) {
            updateAllWidgets(context)
            return
        }

        val updatedRemaining = if (tracksInventory) remaining - 1 else remaining
        if (tracksInventory) {
            product.put("packRemaining", updatedRemaining)
            WidgetPreferences.putString(context, "tracked_products_v1", products.toString())
        }

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
        val products = WidgetPreferences.readProducts(context)
        val configuredProductId =
            WidgetPreferences.readConfiguredProductId(context, appWidgetId)
                ?: WidgetPreferences.readActiveProductId(context)
        val product = products?.let { configuredProductId?.let { productId -> findProductById(it, productId) } }

        if (product == null || isArchivedProduct(product)) {
            bindEmptyState(context, views)
            appWidgetManager.updateAppWidget(appWidgetId, views)
            return
        }

        val productId = product.optString("id")
        val snapshot = readValidSnapshot(context, productId)
        if (snapshot == null) {
            bindSnapshotUnavailableState(context, views)
            appWidgetManager.updateAppWidget(appWidgetId, views)
            return
        }

        bindCommonState(
            context = context,
            views = views,
            productId = productId,
            name = snapshot.optString("name", "Prodotto").ifBlank { "Prodotto" },
            tracksInventory = snapshot.optBoolean("tracksInventory", product.optBoolean("tracksInventory", true)),
            remaining = snapshot.optInt("packRemaining", 0),
            pieces = snapshot.optInt("pieces", 1).coerceAtLeast(1),
            unitCost = snapshot.optDouble("unitCost", 0.0),
            dailyCount = snapshot.optInt("dailyCount", 0),
            dailyCost = snapshot.optDouble("dailyCost", 0.0),
            dailyMinutes = snapshot.optInt("dailyMinutesLost", 0),
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
            put("name", snapshot.optString("name", product.optString("name", "Prodotto")).ifBlank {
                product.optString("name", "Prodotto")
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

    private fun bindEmptyState(context: Context, views: RemoteViews) {
        views.setTextViewText(R.id.widget_product_name, "Nessun prodotto")
        views.setTextViewText(R.id.widget_increment, "Apri app")
        views.setTextViewText(R.id.widget_count, "0")
        views.setTextViewText(R.id.widget_count_label, "Totale usato oggi")
        views.setTextViewText(R.id.widget_hint, "Apri l'app per configurare il prodotto del widget")
        views.setTextViewText(R.id.widget_cost_today_value, formatCurrency(0.0))
        views.setTextViewText(R.id.widget_minutes_today_value, "--")
        views.setTextViewText(R.id.widget_total_cost_value, formatCurrency(0.0))
        views.setOnClickPendingIntent(R.id.widget_root, openAppIntent(context))
        views.setOnClickPendingIntent(R.id.widget_increment, openAppIntent(context))
        views.setViewVisibility(R.id.widget_hint, View.VISIBLE)
    }

    private fun bindSnapshotUnavailableState(context: Context, views: RemoteViews) {
        views.setTextViewText(R.id.widget_product_name, "Apri app")
        views.setTextViewText(R.id.widget_increment, "Apri app")
        views.setTextViewText(R.id.widget_count, "--")
        views.setTextViewText(R.id.widget_count_label, "Widget in sincronizzazione")
        views.setTextViewText(R.id.widget_hint, "Apri l'app per riallineare i dati del prodotto")
        views.setTextViewText(R.id.widget_cost_today_value, formatCurrency(0.0))
        views.setTextViewText(R.id.widget_minutes_today_value, "--")
        views.setTextViewText(R.id.widget_total_cost_value, formatCurrency(0.0))
        views.setOnClickPendingIntent(R.id.widget_root, openAppIntent(context))
        views.setOnClickPendingIntent(R.id.widget_increment, openAppIntent(context))
        views.setViewVisibility(R.id.widget_hint, View.VISIBLE)
    }

    private fun bindCommonState(
        context: Context,
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
            if (!tracksInventory || remaining > 0) "Aggiungi +" else "Apri app"
        )
        views.setOnClickPendingIntent(
            R.id.widget_increment,
            if (!tracksInventory || remaining > 0) incrementIntent(context, productId) else openAppIntent(context)
        )
        views.setOnClickPendingIntent(R.id.widget_root, openAppIntent(context))

        if (size != WidgetSize.SMALL) {
            views.setTextViewText(R.id.widget_count, dailyCount.toString())
            views.setTextViewText(R.id.widget_count_label, "Totale usato oggi")
            views.setTextViewText(
                R.id.widget_hint,
                if (tracksInventory) {
                    "Residuo $remaining/$pieces • Costo unit. ${formatCurrency(unitCost)}"
                } else {
                    "Tracciamento senza scorta • Costo ${formatCurrency(unitCost)}"
                }
            )
            views.setViewVisibility(R.id.widget_hint, View.VISIBLE)
        }

        if (size == WidgetSize.SMALL) {
            views.setTextViewText(R.id.widget_count, dailyCount.toString())
            views.setViewVisibility(R.id.widget_count, View.VISIBLE)
        }

        if (size == WidgetSize.LARGE) {
            views.setTextViewText(R.id.widget_cost_today_value, formatCurrency(dailyCost))
            views.setTextViewText(
                R.id.widget_minutes_today_value,
                if (dailyMinutes > 0) "${dailyMinutes}m" else "--"
            )
            views.setTextViewText(R.id.widget_total_cost_value, formatCurrency(totalSpent))
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

    private fun formatCurrency(value: Double): String =
        NumberFormat.getCurrencyInstance(Locale.ITALY).format(value)

    private fun incrementIntent(context: Context, productId: String): PendingIntent {
        val intent = Intent(context, TrackingWidgetProvider::class.java).apply {
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
        const val ACTION_INCREMENT = "com.example.my_tracking_app.widget.ACTION_INCREMENT"
        const val EXTRA_PRODUCT_ID = "extra_product_id"

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, TrackingWidgetProvider::class.java))
            ids.forEach { appWidgetId ->
                TrackingWidgetProvider().updateWidget(context, manager, appWidgetId)
            }
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
