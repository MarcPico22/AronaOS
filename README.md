# AronaOS — experimental iOS / CarPlay multimedia

**Status: development only — NOT verified on the SEAT display.** Separate project for a SEAT Arona (approx. 2021), infotainment **575035816A / H40 / 0517**, iPhone iOS 26.4.

This branch incorporates a minimal, MIT-licensed [Cafari Lite](https://github.com/rPlayAI/cafari-lite) codebase (original commit `fed8f84b6ab1e254a1fd8d59b144cb71d0f9798f`, Copyright © 2026 rPlay AI) with a **fail-closed experimental motion gate**. See LICENSE. The source is an upstream adaptation, **not** an official Apple or SEAT product.

## Safety and limitations
- The car-side web view starts blank and blocks content until **3 recent GPS fixes indicate near-zero speed**. Denied/old/invalid GPS or movement blocks it immediately, and there is **no switch to disable this gate**. CarPlay/SEAT OS safeguards must also remain intact.
- **GPS speed does not prove the vehicle is parked.** It might allow video at a traffic stop. This is **not a certified parking detector**; do not rely on it for road use. For real usage, video must be governed by a trusted parked-state restriction from Apple/the vehicle. Test only while safely parked.
- Apple Developer membership does not automatically grant **CarPlay Video** (or CarPlay Audio). Both may be needed by this upstream architecture, subject to Apple's approval. Leave signing entitlements **off** until authorised.
- CarPlay video support on this SEAT system has **not** been confirmed. No ECU, firmware, root or jailbreak modifications are used.

## Local development
- Windows: open `web/index.html` to preview the **independent web mock-up**, not the CarPlay app.
- macOS/Xcode required for native build:
  ```sh
  cp Local.xcconfig.example Local.xcconfig
  # Set your bundle ID and TEAM in Local.xcconfig (keep entitlements empty).
  xcodebuild -project CafariLite.xcodeproj -scheme CafariLite -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
  ```
  iPhone install and signing: `tools/run-on-device.sh` on macOS, only after configuring your own signing. It is **phone-only until Apple approves entitlements**.
- Do not commit Apple credentials, provisioning profiles, signing keys or personal identifiers.

## Roadmap
1. Verify unsigned simulator compilation with CI (does not prove CarPlay compatibility).
2. Review the parked gate and its limits, test phone-only UI.
3. If Apple grants permissions, validate the signed entitlements and compatible head-unit behaviour *while parked only*.
4. Replace experimental GPS gate with a verifiable parked-state signal or restrict car video pending support.
5. Design AronaOS home interface, browser, music and assistant, without enabling unsafe video on the road.
