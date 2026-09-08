pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // Flutter 3.44 warns below AGP 8.11.1 / Gradle 8.14.0 and errors below
    // AGP 8.6.0 / Gradle 8.7.0. Kept above the warn line so the next SDK bump
    // does not block the release build.
    id("com.android.application") version "8.11.1" apply false
    // Flutter 3.44 warns below 2.2.20 and errors below 2.0.0. Kept current so a
    // future SDK bump does not block the release build again.
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    // Firebase (push notifications) — reads android/app/google-services.json.
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")
