# ProGuard & R8 Rules for EasyGo Google Maps and Flutter

# Google Play Services & Maps SDK
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }
-dontwarn com.google.android.gms.maps.**

-keep class com.google.android.gms.common.** { *; }
-dontwarn com.google.android.gms.common.**

# Flutter Google Maps Plugin (critical: used via Platform Channels and Pigeon)
-keep class io.flutter.plugins.googlemaps.** { *; }
-keep interface io.flutter.plugins.googlemaps.** { *; }
-keepclassmembers class io.flutter.plugins.googlemaps.** { *; }
-dontwarn io.flutter.plugins.googlemaps.**

# Keep Flutter Platform Views for Hybrid Composition & Virtual Display
-keep class io.flutter.plugin.platform.** { *; }
-dontwarn io.flutter.plugin.platform.**

# Keep Flutter Embedding & Engine
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-dontwarn io.flutter.embedding.**

# Keep WebKit and Network
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(..);
}
