package com.example.my_tracking_app.widget

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.ListView
import android.widget.TextView
import android.widget.Toast
import com.example.my_tracking_app.MainActivity
import com.example.my_tracking_app.R
import org.json.JSONArray

class WidgetConfigureActivity : Activity() {
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)
        setContentView(R.layout.activity_widget_configure)

        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        val products = WidgetPreferences.readProducts(this)
        val options = products?.toOptions().orEmpty()
        if (options.isEmpty()) {
            Toast.makeText(this, "Apri l'app per configurare almeno un prodotto", Toast.LENGTH_LONG).show()
            startActivity(
                Intent(this, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                }
            )
            finish()
            return
        }

        val titleView = findViewById<TextView>(R.id.widget_config_title)
        titleView.text = "Scegli il prodotto del widget"

        val listView = findViewById<ListView>(R.id.widget_config_list)
        listView.adapter = object : ArrayAdapter<ProductOption>(
            this,
            R.layout.widget_config_item,
            options
        ) {
            override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
                val view = convertView ?: LayoutInflater.from(context)
                    .inflate(R.layout.widget_config_item, parent, false)
                val textView = view.findViewById<TextView>(R.id.widget_config_item_name)
                val option = getItem(position)
                textView.text = option?.name ?: ""
                return view
            }
        }

        listView.setOnItemClickListener { _, _, position, _ ->
            val selected = options[position]
            WidgetPreferences.saveConfiguredProductId(this, appWidgetId, selected.id)
            TrackingWidgetProvider.updateSingleWidget(this, appWidgetId)
            val result = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            setResult(RESULT_OK, result)
            finish()
        }
    }

    private fun JSONArray.toOptions(): List<ProductOption> {
        return buildList {
            for (index in 0 until length()) {
                val product = optJSONObject(index) ?: continue
                val id = product.optString("id")
                val name = product.optString("name")
                val isArchived = product.optBoolean("isArchived", false)
                if (id.isNotBlank() && name.isNotBlank() && !isArchived) {
                    add(ProductOption(id = id, name = name))
                }
            }
        }
    }
}

private data class ProductOption(
    val id: String,
    val name: String
)
