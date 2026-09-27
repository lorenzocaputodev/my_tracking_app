package dev.lorenzocaputo.mytrackingapp

import dev.lorenzocaputo.mytrackingapp.widget.TrackingWidgetProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val widgetChannel = "dev.lorenzocaputo.mytrackingapp/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, widgetChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateWidgets" -> {
                        TrackingWidgetProvider.updateAllWidgets(this)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
