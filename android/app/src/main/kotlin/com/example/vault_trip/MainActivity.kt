package com.example.vault_trip

import android.content.pm.PackageManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.vault_trip/config"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getGoogleMapsApiKey") {
                try {
                    val appInfo = packageManager.getApplicationInfo(
                        packageName,
                        PackageManager.GET_META_DATA
                    )
                    val apiKey = appInfo.metaData.getString("com.google.android.geo.API_KEY")
                    result.success(apiKey)
                } catch (e: Exception) {
                    result.error("UNAVAILABLE", "API Key not available", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
