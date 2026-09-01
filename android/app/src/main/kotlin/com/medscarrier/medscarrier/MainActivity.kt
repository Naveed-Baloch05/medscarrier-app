package com.medscarrier.medscarrier

import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.content.pm.Signature
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.medscarrier.medscarrier/maps",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getApiKey" -> {
                    val key = BuildConfig.MAPS_API_KEY
                    if (key.isNullOrEmpty()) {
                        result.error("NO_MAPS_KEY", "Maps API key is not configured.", null)
                    } else {
                        result.success(key)
                    }
                }
                "getAndroidClientInfo" -> {
                    // Google's REST endpoints (Places / Geocoding) reject a
                    // key that is restricted to Android apps unless the caller
                    // identifies itself via the X-Android-Package and
                    // X-Android-Cert (SHA-1 signing fingerprint) headers.
                    result.success(mapOf(
                        "packageName" to packageName,
                        "sha1" to signingCertificateSha1(),
                    ))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun signingCertificateSha1(): String {
        return try {
            val info: PackageInfo = if (android.os.Build.VERSION.SDK_INT >= 28) {
                packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
            }

            val signatures: List<Signature> = if (android.os.Build.VERSION.SDK_INT >= 28) {
                info.signingInfo?.apkContentsSigners?.toList() ?: emptyList()
            } else {
                @Suppress("DEPRECATION")
                (info.signatures?.toList() ?: emptyList())
            }

            if (signatures.isEmpty()) "" else {
                val digest = MessageDigest.getInstance("SHA-1").digest(signatures.first().toByteArray())
                digest.joinToString(":") { "%02X".format(it) }
            }
        } catch (_: Exception) {
            ""
        }
    }
}
