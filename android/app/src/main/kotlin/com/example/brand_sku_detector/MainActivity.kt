package com.example.brand_sku_detector

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.Person
import androidx.core.content.ContextCompat
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private companion object {
        const val CHANNEL = "assistance_bubble"
        const val NOTIF_CHANNEL_ID = "assistance_bubble_channel"
        const val SHORTCUT_ID = "assistance_bubble_shortcut"
        const val PERSON_KEY = "sku-assistant"
        const val NOTIF_ID = 4580
        const val POST_NOTIF_REQUEST = 9911
    }

    // Set while a POST_NOTIFICATIONS request is in flight so the result can be
    // returned to the awaiting Dart caller.
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isSupported" ->
                        // Bubbles are usable from Android 11 (API 30).
                        result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.R)
                    "areBubblesAllowed" -> result.success(areBubblesAllowed())
                    "ensureNotificationPermission" -> ensureNotificationPermission(result)
                    "showBubble" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                            showBubble()
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun areBubblesAllowed(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return false
        val nm = getSystemService(NotificationManager::class.java)
        // Global toggle; per-conversation permission is also required but only
        // becomes meaningful once the channel/shortcut exist.
        return nm.areBubblesAllowed()
    }

    private fun ensureNotificationPermission(result: MethodChannel.Result) {
        // POST_NOTIFICATIONS runtime permission only exists on Android 13+.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(true)
            return
        }
        val granted = ContextCompat.checkSelfPermission(
            this,
            android.Manifest.permission.POST_NOTIFICATIONS,
        ) == PackageManager.PERMISSION_GRANTED
        if (granted) {
            result.success(true)
            return
        }
        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
            POST_NOTIF_REQUEST,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == POST_NOTIF_REQUEST) {
            val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
    }

    @RequiresApi(Build.VERSION_CODES.R)
    private fun showBubble() {
        val icon = IconCompat.createWithResource(this, R.mipmap.ic_launcher)

        // Conversation channel that permits bubbles.
        val nm = getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            NOTIF_CHANNEL_ID,
            "Assistance Bubble",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Floating assistance bubble for the SKU detector"
            setAllowBubbles(true)
        }
        nm.createNotificationChannel(channel)

        // The "person" the conversation is with (bubbles are modelled as chats).
        val person = Person.Builder()
            .setName("SKU Assistant")
            .setKey(PERSON_KEY)
            .setIcon(icon)
            .setImportant(true)
            .build()

        // Long-lived dynamic shortcut the notification points at (required for
        // conversation notifications / bubbles).
        val shortcut = ShortcutInfoCompat.Builder(this, SHORTCUT_ID)
            .setLongLived(true)
            .setShortLabel("SKU Assistant")
            .setIcon(icon)
            .setPerson(person)
            .setCategories(setOf("com.example.brand_sku_detector.category.BUBBLE"))
            .setIntent(
                Intent(this, MainActivity::class.java).setAction(Intent.ACTION_VIEW),
            )
            .build()
        ShortcutManagerCompat.pushDynamicShortcut(this, shortcut)

        // Expanded bubble hosts BubbleActivity.
        val bubbleIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, BubbleActivity::class.java),
            PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        val bubbleData = NotificationCompat.BubbleMetadata.Builder(bubbleIntent, icon)
            .setDesiredHeight(600)
            .setAutoExpandBubble(true)
            .setSuppressNotification(true)
            .build()

        val notification = NotificationCompat.Builder(this, NOTIF_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setBubbleMetadata(bubbleData)
            .setShortcutId(SHORTCUT_ID)
            .addPerson(person)
            .setCategory(Notification.CATEGORY_MESSAGE)
            .setStyle(
                NotificationCompat.MessagingStyle(person).addMessage(
                    "Tap to open the SKU detector",
                    System.currentTimeMillis(),
                    person,
                ),
            )
            .build()

        NotificationManagerCompat.from(this).notify(NOTIF_ID, notification)
    }
}
