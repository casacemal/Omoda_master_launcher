
package com.example.chery_master_launcher

import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.omodalauncher/apps"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "getInstalledApps") {
                result.success(getInstalledApps())
            } else if (call.method == "launchApp") {
                val packageName = call.argument<String>("packageName")
                if (packageName != null) {
                    launchApp(packageName)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENT", "Package name cannot be null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getInstalledApps(): List<Map<String, Any?>> {
        val pm: PackageManager = packageManager
        val apps = mutableListOf<Map<String, Any?>>()
        val intent = Intent(Intent.ACTION_MAIN, null)
        intent.addCategory(Intent.CATEGORY_LAUNCHER)
        val resolveInfoList = pm.queryIntentActivities(intent, 0)

        for (resolveInfo in resolveInfoList) {
            val app = HashMap<String, Any?>()
            app["appName"] = resolveInfo.loadLabel(pm).toString()
            app["packageName"] = resolveInfo.activityInfo.packageName
            app["icon"] = drawableToByteArray(resolveInfo.loadIcon(pm))
            apps.add(app)
        }
        return apps
    }

    private fun launchApp(packageName: String) {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        if (intent != null) {
            startActivity(intent)
        }
    }

    private fun drawableToByteArray(drawable: Drawable): ByteArray {
        val bitmap = Bitmap.createBitmap(drawable.intrinsicWidth, drawable.intrinsicHeight, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }
}
