package com.example.sms_apk

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.annotation.SuppressLint
import android.os.Build
import android.util.Base64
import android.hardware.fingerprint.FingerprintManager
import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import android.widget.Toast
import javax.crypto.Cipher

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.abhotel/fingerprint"
    private lateinit var fingerprintManager: FingerprintManager
    private lateinit var cryptoObject: FingerprintManager.CryptoObject

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize fingerprint manager
        fingerprintManager = getSystemService(Context.FINGERPRINT_SERVICE) as FingerprintManager
        
        // Set up method channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanFingerprint" -> handleFingerprintScan(result)
                else -> result.notImplemented()
            }
        }
        
        // Initialize crypto object (simplified - implement proper crypto in production)
        try {
            val cipher = Cipher.getInstance("AES/CBC/PKCS7Padding") // Use proper transformation
            cryptoObject = FingerprintManager.CryptoObject(cipher)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun handleFingerprintScan(result: MethodChannel.Result) {
        if (!checkFingerprintSupport()) {
            result.error("UNAVAILABLE", "Fingerprint not supported", null)
            return
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            fingerprintManager.authenticate(
                cryptoObject,
                null,
                0,
                object : FingerprintManager.AuthenticationCallback() {
                    override fun onAuthenticationError(errMsgId: Int, errString: CharSequence) {
                        result.error("AUTH_ERROR", errString.toString(), null)
                    }

                    override fun onAuthenticationHelp(helpMsgId: Int, helpString: CharSequence) {
                        // Optional: Provide help feedback
                    }

                    override fun onAuthenticationSucceeded(authResult: FingerprintManager.AuthenticationResult) {
                        // In a real app, you would get the actual auth result
                        // Here we simulate fingerprint data for demonstration
                        val simulatedData = "FP_DATA_${System.currentTimeMillis()}".toByteArray()
                        result.success(Base64.encodeToString(simulatedData, Base64.DEFAULT))
                    }

                    override fun onAuthenticationFailed() {
                        result.error("AUTH_FAILED", "Fingerprint not recognized", null)
                    }
                },
                null
            )
        } else {
            result.error("UNSUPPORTED", "Android version too old", null)
        }
    }

    private fun checkFingerprintSupport(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return false
        }
        
        return if (ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.USE_FINGERPRINT
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            Toast.makeText(
                this,
                "Fingerprint permission not granted",
                Toast.LENGTH_LONG
            ).show()
            false
        } else {
            fingerprintManager.isHardwareDetected && fingerprintManager.hasEnrolledFingerprints()
        }
    }
}