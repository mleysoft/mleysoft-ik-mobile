package com.mleysoft.ik

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.mleysoft.ik/badge").setMethodCallHandler { call, result ->
            if (call.method == "setBadge") {
                // Android launcher rozetleri aktif notification sayÄ±sÄ± / Notification.number ile yÃ¶netilir.
                result.success(true)
            } else result.notImplemented()
        }
    }
}
