# Flutter + plugins mostly ship their own rules; these cover what R8 still
# strips or warns about in a release build.

-keep class io.flutter.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Flutter references Play Core for deferred components. This app does not use
# deferred components and does not bundle Play Core, so silence those refs
# instead of adding an unused dependency.
-dontwarn com.google.android.play.core.**
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# mobile_scanner / ML Kit barcode.
-dontwarn com.google.mlkit.**
-keep class com.google.mlkit.** { *; }
