package dev.lorenzocaputo.mytrackingapp.widget

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class WidgetActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            TrackingWidgetProvider.ACTION_INCREMENT -> {
                val productId = intent.getStringExtra(TrackingWidgetProvider.EXTRA_PRODUCT_ID) ?: return
                TrackingWidgetProvider().handleIncrement(context, productId)
            }
            TrackingWidgetProvider.ACTION_MIDNIGHT_REFRESH -> TrackingWidgetProvider.updateAllWidgets(context)
        }
    }
}
