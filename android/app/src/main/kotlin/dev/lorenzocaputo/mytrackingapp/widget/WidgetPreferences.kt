package dev.lorenzocaputo.mytrackingapp.widget

import android.content.Context
import android.content.SharedPreferences
import android.content.res.Configuration
import org.json.JSONArray
import org.json.JSONObject
import java.util.Locale

internal object WidgetPreferences {
    private const val PREFS_NAME = "FlutterSharedPreferences"
    private const val PREFIX = "flutter."
    private const val PENDING_ENTRY_PREFIX = "widget_pending_entry_v2_"
    private const val PRODUCT_SNAPSHOTS_KEY = "widget_product_snapshots_v2"
    private const val WIDGET_CONFIG_MAP_KEY = "widget_product_widget_map_v1"

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun getString(context: Context, key: String, fallback: String? = null): String? =
        prefs(context).getString(PREFIX + key, fallback)

    fun putString(context: Context, key: String, value: String) {
        prefs(context).edit().putString(PREFIX + key, value).commit()
    }

    fun readProducts(context: Context): JSONArray? {
        val raw = getString(context, "tracked_products_v1") ?: return null
        return try {
            JSONArray(raw)
        } catch (_: Exception) {
            null
        }
    }

    fun readWidgetTheme(context: Context): String? =
        getString(context, "widget_theme")

    fun localizedContext(context: Context): Context {
        val tag = when (getString(context, "app_language")) {
            "italian" -> "it"
            "english" -> "en"
            else -> return context
        }
        val configuration = Configuration(context.resources.configuration)
        configuration.setLocale(Locale.forLanguageTag(tag))
        return context.createConfigurationContext(configuration)
    }

    fun readActiveProductId(context: Context): String? =
        getString(context, "active_product_id")

    fun readWidgetSnapshot(context: Context): JSONObject? {
        val raw = getString(context, "widget_snapshot_v1") ?: return null
        return try {
            JSONObject(raw)
        } catch (_: Exception) {
            null
        }
    }

    fun readWidgetSnapshotForProduct(context: Context, productId: String): JSONObject? {
        val raw = getString(context, PRODUCT_SNAPSHOTS_KEY) ?: return null
        return try {
            JSONObject(raw).optJSONObject(productId)
        } catch (_: Exception) {
            null
        }
    }

    fun putWidgetSnapshotForProduct(context: Context, productId: String, snapshot: JSONObject) {
        val snapshots = readWidgetSnapshots(context)
        snapshots.put(productId, snapshot)
        putString(context, PRODUCT_SNAPSHOTS_KEY, snapshots.toString())
    }

    private fun readWidgetSnapshots(context: Context): JSONObject {
        val raw = getString(context, PRODUCT_SNAPSHOTS_KEY, "{}") ?: "{}"
        return try {
            JSONObject(raw)
        } catch (_: Exception) {
            JSONObject()
        }
    }

    fun appendPendingEntry(context: Context, entry: JSONObject) {
        putString(context, PENDING_ENTRY_PREFIX + entry.getString("id"), entry.toString())
    }

    fun readConfiguredProductId(context: Context, appWidgetId: Int): String? {
        val raw = getString(context, WIDGET_CONFIG_MAP_KEY, "{}") ?: "{}"
        return try {
            JSONObject(raw).optString(appWidgetId.toString(), null)
        } catch (_: Exception) {
            null
        }
    }

    fun saveConfiguredProductId(context: Context, appWidgetId: Int, productId: String) {
        val map = readWidgetConfigMap(context)
        map.put(appWidgetId.toString(), productId)
        putString(context, WIDGET_CONFIG_MAP_KEY, map.toString())
    }

    fun removeConfiguredProductId(context: Context, appWidgetId: Int) {
        val map = readWidgetConfigMap(context)
        map.remove(appWidgetId.toString())
        putString(context, WIDGET_CONFIG_MAP_KEY, map.toString())
    }

    private fun readWidgetConfigMap(context: Context): JSONObject {
        val raw = getString(context, WIDGET_CONFIG_MAP_KEY, "{}") ?: "{}"
        return try {
            JSONObject(raw)
        } catch (_: Exception) {
            JSONObject()
        }
    }
}
