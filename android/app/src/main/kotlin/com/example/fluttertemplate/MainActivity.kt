package com.example.fluttertemplate

import android.app.KeyguardManager
import android.app.admin.DevicePolicyManager
import android.content.Context
import android.content.pm.ApplicationInfo
import android.os.Debug
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.theamorn.flutter"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val method = call.method
            when (method) {
                "deviceHasPasscode" -> result.success(deviceSecure)
                "returnValue" -> returnValueSDK(result, call.arguments)
                "methodNameOne" -> callNativeSDK(call.arguments)
                else -> result.notImplemented()
            }
        }

        // Check Security
        // Open ADB Debugging in Android, Mostly we can turn it off since all Android developers need this
        if (Settings.Secure.getInt(this.applicationContext.contentResolver, Settings.Global.ADB_ENABLED, 0) == 1) {
            quitApp()
        }

        // check by using adb shell getprop ro.crypto.type
        if ((applicationContext.getSystemService(DEVICE_POLICY_SERVICE) as DevicePolicyManager).storageEncryptionStatus == DevicePolicyManager.ENCRYPTION_STATUS_UNSUPPORTED) {
            quitApp()
        }

        // flag debuggable in gradle is true, work only in production, disable in dev
        if ((0 != applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE || BuildConfig.DEBUG) && BuildConfig.FLAVOR.equals("production")) {
            quitApp()
        }

        // Use Debugger in Android Studio to connect for getting log
        if (Debug.isDebuggerConnected() || Debug.waitingForDebugger()) {
            quitApp()
        }
    }

    private val deviceSecure: Boolean
        get() = (getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager).isDeviceSecure

    private fun quitApp() {
//        moveTaskToBack(true)
//        exitProcess(1)
    }

    private fun callToFlutter(value: String) {
        flutterEngine?.let {
            runOnUiThread { MethodChannel(it.dartExecutor.binaryMessenger, CHANNEL)
                    .invokeMethod("methodNameTwoFromSDK", value) }
        }
    }

    private fun callNativeSDK(id: Any) {
        if (id is String) {
            val sdk = ThirdPartySDK(id)
            sdk.thirdPartyDidFinished {
                callToFlutter(it)
            }
        }
    }

    private fun returnValueSDK(result: MethodChannel.Result, id: Any) {
        if (id is String) {
            val sdk = ThirdPartySDK(id)
            result.success(sdk.process())
        }
    }

    public override fun onPause() {
        this.window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        super.onPause()
    }

    public override fun onResume() {
        super.onResume()
        this.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

}
