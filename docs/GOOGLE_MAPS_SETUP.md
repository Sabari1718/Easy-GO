# EasyGo Google Maps Setup

To enable the actual Google Maps rendering on Android and iOS devices, you must provide a valid Google Maps API Key.

## 1. Create a Google Cloud Project
1. Go to the [Google Cloud Console](https://console.cloud.google.com/).
2. Create a new project or select an existing one.

## 2. Enable Required APIs
Ensure the following APIs are enabled for your project:
- **Maps SDK for Android**
- **Maps SDK for iOS**

## 3. Generate an API Key
1. Go to **APIs & Services > Credentials**.
2. Click **Create Credentials > API key**.
3. Copy the generated API key.

## 4. Configure the API Key in the Project

### For Android
We have securely configured `android/app/build.gradle.kts` and `AndroidManifest.xml` to load the API key from your `local.properties` file.

Open the file at `android/local.properties` (or create it if it doesn't exist) and add the following line:

```properties
MAPS_API_KEY=YOUR_ACTUAL_API_KEY
```

> **Note:** `local.properties` is already added to `.gitignore`, so your API key will remain safe and will not be committed to version control.

### For iOS
Open `ios/Runner/AppDelegate.swift` and insert the API key in the `GMSServices.provideAPIKey` call:

```swift
import UIKit
import Flutter
import GoogleMaps // Add this import

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_ACTUAL_API_KEY") // Add this line
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  // ...
}
```

## 5. Security Best Practices (For Production)
For production, you **MUST** restrict your API key in the Google Cloud Console:
1. Go to your API Key settings in Google Cloud.
2. Under **Application restrictions**:
   - Add an **Android restriction** using the Package Name: `com.easygo.easy_go` and your app's SHA-1 certificate fingerprint.
   - Add an **iOS restriction** using your Apple Bundle Identifier.
3. Under **API restrictions**, select exactly these APIs:
   - Maps SDK for Android
   - Maps SDK for iOS

## 6. Testing
After configuring the keys, completely rebuild the application to ensure the keys are picked up correctly:

```bash
flutter clean
flutter pub get
flutter run
```