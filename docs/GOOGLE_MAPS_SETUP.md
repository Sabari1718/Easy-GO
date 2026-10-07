# EasyGo Google Maps Setup & Release Build Guide

To enable actual Google Maps rendering on Android and iOS devices across **both debug and release builds**, follow this guide.

---

## 1. Architecture: API Key Injection (Zero Dart Secrets)

The API key is injected at compile-time via Gradle without exposing secrets in Dart or Git:

```
android/local.properties (MAPS_API_KEY)
           ↓
android/app/build.gradle.kts (manifestPlaceholders["MAPS_API_KEY"])
           ↓
android/app/src/main/AndroidManifest.xml (<meta-data android:name="com.google.android.geo.API_KEY" .../>)
           ↓
Google Maps SDK for Android
```

> **Security Rule:**
> - `android/local.properties` is in `.gitignore` and must **never** be committed.
> - The API key is **never** hardcoded into Dart source code or Git-tracked files.

---

## 2. Certificates & SHA-1 Fingerprints

Google Cloud restricts API requests based on **Package Name** + **SHA-1 Fingerprint**.

### Package Name / Application ID
```
com.easygo.easy_go
```

### Current Signing Certificates (via `gradlew signingReport`)
- **Debug Build (`flutter run`)**:
  - Keystore: `C:\Users\sabar\.android\debug.keystore`
  - SHA-1: `71:84:3A:91:B2:57:F3:E9:82:B3:5D:17:90:2C:1D:16:A6:17:7E:17`
  - SHA-256: `C8:8A:26:E2:FC:AB:62:A4:7B:3D:69:5B:A2:1F:E5:73:F2:62:65:51:F4:3B:7D:C3:FC:AF:B4:C5:00:EF:FC:44`

- **Local Release Build (`flutter build apk --release`)**:
  - Currently configured to fall back to `debug.keystore` unless `key.properties` is present.
  - Current SHA-1: `71:84:3A:91:B2:57:F3:E9:82:B3:5D:17:90:2C:1D:16:A6:17:7E:17`

- **Production Custom Keystore (Optional / Future)**:
  - If you generate your own release keystore, place configuration in `android/key.properties`.
  - Obtain its SHA-1 by running `keytool -list -v -keystore <your-keystore.jks>`.

- **Google Play App Signing (When publishing on Play Store)**:
  - When distributing via Google Play App Bundle (`.aab`), Google Play re-signs the APK with Google's Play App Signing key.
  - You must copy the SHA-1 from **Google Play Console > Setup > App Integrity > App signing key certificate** and add it to Google Cloud Console.

---

## 3. Google Cloud Console Configuration (CRITICAL)

To prevent blank maps / authorization failures:

1. Open [Google Cloud Console - Credentials](https://console.cloud.google.com/apis/credentials).
2. Select your Maps API Key.
3. Under **Set an application restriction**, select **Android apps**.
4. Click **+ Add an item** under Android applications:
   - **Package name:** `com.easygo.easy_go`
   - **SHA-1 certificate fingerprint:** `71:84:3A:91:B2:57:F3:E9:82:B3:5D:17:90:2C:1D:16:A6:17:7E:17`
5. *(If using a separate production release keystore or Google Play App Signing)*:
   - Click **+ Add an item** again.
   - Enter package: `com.easygo.easy_go`
   - Enter your Production Release SHA-1 or Google Play App Signing SHA-1.
6. Under **API restrictions**:
   - Choose **Restrict key**.
   - Check **Maps SDK for Android**.
7. Click **Save**.

*(Note: Changes in Google Cloud Console may take 2–5 minutes to propagate).*

---

## 4. R8 / ProGuard Configuration

In `android/app/build.gradle.kts` and `android/app/proguard-rules.pro`:
- Code shrinking / minification is safely disabled (`isMinifyEnabled = false`, `isShrinkResources = false`) for release builds so that Flutter Platform Views and the `io.flutter.plugins.googlemaps` plugin cannot be stripped by R8.
- Comprehensive keep rules are defined in `android/app/proguard-rules.pro` to keep:
  - `com.google.android.gms.maps.**`
  - `com.google.android.gms.common.**`
  - `io.flutter.plugins.googlemaps.**` (Flutter plugin platform channel serializers & controllers)
  - `io.flutter.plugin.platform.**`
  - `io.flutter.embedding.**`

---

## 5. Building & Verifying

### Build Release APK
```bash
flutter clean
flutter pub get
flutter build apk --release
```

The output will be:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Install Release APK on Connected Physical Device
```bash
flutter install --release
# OR
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Checking for Errors on Device (if needed)
```bash
adb logcat | Select-String -Pattern "Google Maps|MapsNetwork|AuthorizationFailure"
```