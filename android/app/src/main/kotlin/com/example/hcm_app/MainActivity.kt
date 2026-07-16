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
        // HCA (boss 16/07): push notifications play the app's signature tone.
        // The channel only exists on the HCA flavor — its applicationId is
        // com.bluesoft.hcm_app and the sound lives in the hca sourceset — so
        // the PHH build is untouched.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            packageName == "com.bluesoft.hcm_app"
        ) {
            val soundUri = Uri.parse("android.resource://$packageName/raw/hca_notify")
            val attrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            val channel = NotificationChannel(
                "hca_alerts",
                "HomeCloudAsia Alerts",
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
