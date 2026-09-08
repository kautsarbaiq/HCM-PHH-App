import java.util.Properties
import java.io.FileInputStream

// Release signing. Play Store rejects debug-signed uploads, so a real keystore
// is read from android/key.properties (kept OUT of git). When that file is
// absent the build falls back to debug keys so local `flutter run` still works.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.hcm_app"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        // flutter_local_notifications (foreground push banners) needs this.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Must match the package registered in Firebase (google-services.json).
        applicationId = "com.bluesoft.hcm_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Was a hardcoded 23. Do NOT put a number back here: Flutter's
        // MinSdkVersionMigration rewrites any minSdk of 16-23 to
        // flutter.minSdkVersion on EVERY build, so a pin silently reverts.
        // On Flutter 3.44 that value is 24, i.e. Android 7.0 - upgrading the
        // SDK dropped Android 6 support. That is Flutter's floor, not ours.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // White-label: one codebase → two apps with separate ids, names and
    // Supabase projects. Build with:
    //   flutter build apk --flavor phh --dart-define=BRAND=phh
    //   flutter build apk --flavor hca --dart-define=BRAND=hca
    flavorDimensions += "brand"
    productFlavors {
        create("phh") {
            dimension = "brand"
            applicationId = "com.bluesoft.phh"
            resValue("string", "app_name", "PHH Housing")
        }
        create("hca") {
            dimension = "brand"
            applicationId = "com.bluesoft.hcm_app"
            resValue("string", "app_name", "HomeCloudAsia")
        }
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Real keystore when android/key.properties exists; debug keys
            // otherwise so day-to-day `flutter run --release` keeps working.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
