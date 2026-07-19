package com.example.hcm_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Push notifications play the app's signature tone. Both brands get it
        // (the sound lives in the shared main sourceset); only the channel's
        // display name differs, since that is what the user sees in Android's
        // notification settings.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Reference the resource by its R id (not just a name string) so
            // the resource shrinker sees it as USED and keeps it in the APK,
            // and resolve the sound URI by id (survives name collapsing too).
            val soundUri = Uri.parse(
                "android.resource://$packageName/${R.raw.hca_notify}"
            )
            val attrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            val label = if (packageName == "com.bluesoft.phh") {
                "PHH Housing Alerts"
            } else {
                "HomeCloudAsia Alerts"
            }
            val channel = NotificationChannel(
                "hca_alerts",
                label,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Community updates, approvals and visitor alerts"
                setSound(soundUri, attrs)
                enableVibration(true)
            }
            (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                .createNotificationChannel(channel)
        }
    }
}
