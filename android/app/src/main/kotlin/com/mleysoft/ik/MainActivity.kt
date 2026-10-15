package com.mleysoft.ik

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.os.Looper
import android.os.Handler
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val locationRequestCode = 9182
    private var pendingLocationResult: MethodChannel.Result? = null
    private val locationHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.mleysoft.ik/badge").setMethodCallHandler { call, result ->
            if (call.method == "setBadge") result.success(true) else result.notImplemented()
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.mleysoft.ik/location").setMethodCallHandler { call, result ->
            if (call.method == "getCurrentLocation") getCurrentLocation(result) else result.notImplemented()
        }
    }

    private fun getCurrentLocation(result: MethodChannel.Result) {
        val fine = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        val coarse = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
        if (!fine && !coarse) {
            pendingLocationResult = result
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION), locationRequestCode)
            return
        }
        obtainLocation(result)
    }

    private fun obtainLocation(result: MethodChannel.Result) {
        val manager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val fine = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        val coarse = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
        val providers = listOf(LocationManager.NETWORK_PROVIDER, LocationManager.GPS_PROVIDER).filter { name ->
            (name != LocationManager.GPS_PROVIDER || fine) && (fine || coarse) &&
                runCatching { manager.isProviderEnabled(name) }.getOrDefault(false)
        }
        if (providers.isEmpty()) {
            result.error("LOCATION_SERVICE_DISABLED", "GPS veya aÄŸ konumu kapalÄ±. Konum ayarlarÄ±nÄ±zÄ± kontrol edin.", null)
            return
        }
        try {
            // KapalÄ± alanda sadece GPS'i beklemek yerine aÄŸ+GPS sonuÃ§larÄ±nÄ± birlikte al.
            val cached = providers.mapNotNull { name -> runCatching { manager.getLastKnownLocation(name) }.getOrNull() }
                .filter { System.currentTimeMillis() - it.time in 0L..120000L && it.accuracy <= 75f }
                .minByOrNull { it.accuracy }
            if (cached != null) { returnLocation(result, cached); return }

            var completed = false
            var best: Location? = null
            val listeners = mutableListOf<LocationListener>()
            val timeout = Runnable {
                if (!completed) {
                    completed = true
                    listeners.forEach { listener -> runCatching { manager.removeUpdates(listener) } }
                    val candidate = best
                    if (candidate != null) returnLocation(result, candidate)
                    else result.error("LOCATION_TIMEOUT", "Konum henÃ¼z belirlenemedi. Konum hizmetlerini aÃ§Ä±p tekrar deneyin.", null)
                }
            }
            fun complete(location: Location) {
                if (completed) return
                completed = true
                locationHandler.removeCallbacks(timeout)
                listeners.forEach { listener -> runCatching { manager.removeUpdates(listener) } }
                returnLocation(result, location)
            }
            for (name in providers) {
                val listener = object : LocationListener {
                    override fun onLocationChanged(location: Location) {
                        if (completed) return
                        if (best == null || location.accuracy < best!!.accuracy) best = location
                        if (location.accuracy in 0f..75f) complete(location)
                    }
                    override fun onProviderEnabled(provider: String) {}
                    override fun onProviderDisabled(provider: String) {}
                    @Deprecated("Deprecated in Android") override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
                }
                listeners.add(listener)
            }
            providers.forEachIndexed { i, name ->
                runCatching { manager.requestLocationUpdates(name, 0L, 0f, listeners[i], Looper.getMainLooper()) }
            }
            locationHandler.postDelayed(timeout, 30000)
        } catch (_: SecurityException) {
            result.error("LOCATION_PERMISSION_DENIED", "Konum izni gerekli.", null)
        } catch (e: Exception) {
            result.error("LOCATION_ERROR", e.message ?: "Konum bilgisi alÄ±namadÄ±.", null)
        }
    }

    private fun returnLocation(result: MethodChannel.Result, location: Location) {
        result.success(mapOf("latitude" to location.latitude, "longitude" to location.longitude, "accuracy" to location.accuracy.toDouble(), "is_mocked" to (if (android.os.Build.VERSION.SDK_INT >= 31) location.isMock else location.isFromMockProvider)))
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != locationRequestCode) return
        val result = pendingLocationResult ?: return
        pendingLocationResult = null
        if (grantResults.any { it == PackageManager.PERMISSION_GRANTED }) {
            obtainLocation(result)
        } else {
            val permanentlyDenied = !ActivityCompat.shouldShowRequestPermissionRationale(this, Manifest.permission.ACCESS_FINE_LOCATION)
            result.error(if (permanentlyDenied) "LOCATION_PERMISSION_DENIED_FOREVER" else "LOCATION_PERMISSION_DENIED", "Konum izni gerekli.", null)
        }
    }
}
