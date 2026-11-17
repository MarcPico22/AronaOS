# AronaOS — experimental iOS / CarPlay video

Independent research project for a SEAT Arona 2021-ish (infotainment `575035816A / H40 / 0517`) and iPhone previously reported on iOS 26.4. Wired and wireless CarPlay confirmed; **video support unverified**.

### What changed after the Apple approval email

The developer has reported that Apple granted the **CarPlay Video App** entitlement to their account. The repo now contains only `com.apple.developer.carplay-video` — **not** CarPlay Audio. Since iOS 26.3, Apple says these categories cannot be combined in the same app. The entitlement remains **disabled by default** in `Signing.xcconfig` until the explicit App ID and a new provisioning profile are configured.

**Read [the Apple Video setup checklist](docs/APPLE_VIDEO_APPROVAL.md) before attempting to sign.**

### Compatibility blockers

- Apple's **official CarPlay video apps were introduced in iOS 27**. Update the test iPhone to iOS 27+ before official tests, with an appropriate Xcode/iOS SDK.
- Video-only apps are **hidden on cars that lack the video feature**. We have not confirmed SEAT Arona 2021 support; account entitlement approval alone does not enable it.
- This branch adapts MIT-licensed [Cafari Lite](https://github.com/rPlayAI/cafari-lite) at upstream `fed8f84b6ab1e254a1fd8d59b144cb71d0f9798f`, Copyright (c) 2026 rPlay AI. See LICENSE. The existing UIKit/WKWebView car scene is **experimental**, not the final supported iOS 27 CarPlay video application. Apple's official path uses CarPlay framework and AirPlay-compatible video.
- The experimental CoreLocation motion gate is fail-closed on missing/invalid GPS, but GPS speed zero **cannot certify the car is parked**. Do not operate in-car video without trusted Apple/vehicle parked-state enforcement. Do not defeat the car's safety mechanisms.

### Code and tests

- `CafariLite/`: native Swift experimental baseline, builds for iPhone.
- `web/index.html`: AronaOS design concept running in a **normal browser**, not in CarPlay.
- `CarPlay.entitlements`: video-only permission; requires valid Apple-approved App ID and provisioning.
- `scripts/check_source.py`: static safety and entitlement assertions.
- `docs/TEST_PLAN.md`: remaining QA gates.

Unsigned smoke build on a compatible macOS/Xcode environment:
```sh
xcodebuild -project CafariLite.xcodeproj -scheme CafariLite -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

A successful compile is **not** a signed install, a vehicle test, or proof of video playback compatibility. No ECU/firmware changes, jailbreak, live payments or secrets.
