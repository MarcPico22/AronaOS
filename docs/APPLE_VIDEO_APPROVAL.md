# Apple CarPlay Video approval: provisioning checklist

Developer reports receiving account-level approval for `com.apple.developer.carplay-video` (17 November 2026). This is **not** yet proof that an individual App ID/provisioning profile is configured.

1. Open https://developer.apple.com/account/resources/identifiers/list and create or edit an **explicit** App ID for AronaOS. Use a unique Bundle ID you own, e.g. `com.examplecompany.aronaos`. Do not use the example literally if already taken.
2. Under the App ID's capabilities, enable **CarPlay Video App** and Save. **Do not enable CarPlay Audio App** alongside Video: Apple says iOS 26.3+ does not support mixing CarPlay entitlements.
3. Create a **fresh provisioning profile** for that App ID after enabling the capability. For local iPhone tests, use Apple Development certificate and registered iPhone; for TestFlight, later use distribution signing.
4. On macOS/Xcode, copy `Local.xcconfig.example` to `Local.xcconfig`. Set `CAFARI_LITE_BUNDLE_ID` to the exact registered Bundle ID and `CAFARI_LITE_TEAM` to your Apple Team ID. Uncomment `CAFARI_LITE_ENTITLEMENTS = CarPlay.entitlements` only once the correct profile is installed.
5. Inspect the signed .app:
   ```sh
   codesign -d --entitlements :- /path/to/CafariLite.app
   ```
   The only **CarPlay** entitlement key must be `com.apple.developer.carplay-video = true`. Verify the generated provisioning profile grants it.
6. **Official CarPlay video apps require iOS 27+**, the matching Xcode/iOS 27 SDK and a **vehicle supporting video playback**. The SEAT Arona 2021's head unit `575035816A / H40 / 0517` is not verified to support it. Even with successful signing, the app can be **hidden** if the vehicle lacks the feature.
7. The older Cafari Lite custom UIWindowScene/WKWebView method is an **experimental research baseline**, not evidence of compatibility with Apple's official CarPlay video-browsing framework. For the supported approach, implement CarPlay framework browsing templates, AirPlay-compatible playback and inspect `CPSessionConfiguration.supportsVideoPlayback` when appropriate.
8. Playback must obey **Apple/vehicle** parked-state enforcement. GPS speed near zero is not proof the transmission is in Park (e.g., traffic light). Never bypass vehicle limitations.

Do not upload certificates, private keys, provisioning profiles or other secrets to this **public** repo.

References:
- https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.carplay-video
- https://developer.apple.com/videos/play/wwdc2026/212/
- https://developer.apple.com/documentation/carplay/cpsessionconfiguration/supportsvideoplayback
