package com.example.my_tracking_app.widget

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

internal object WidgetPreferences {
    private const val PREFS_NAME = "FlutterSharedPreferences"
    private const val PREFIX = "flutter."
    private const val PENDING_ENTRIES_KEY = "widget_pending_entries_v1"
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

    fun readPendingEntries(context: Context): JSONArray {
        val raw = getString(context, PENDING_ENTRIES_KEY, "[]") ?: "[]"
        return try {
            JSONArray(raw)
        } catch (_: Exception) {
            JSONArray()
        }
    }

    fun appendPendingEntry(context: Context, entry: JSONObject) {
        val entries = readPendingEntries(context)
        entries.put(entry)
        putString(context, PENDING_ENTRIES_KEY, entries.toString())
    }

    fun clearPendingEntries(context: Context) {
        putString(context, PENDING_ENTRIES_KEY, JSONArray().toString())
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
