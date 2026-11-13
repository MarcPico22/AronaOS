# AronaOS

Experimental iOS / CarPlay project for a **SEAT Arona (approx. 2021)** with infotainment part **575035816A**, hardware **H40**, software **0517**, using an iPhone on iOS 26.4.

## Status

**Research and prototype only.** Apple has received a request for CarPlay Video entitlement; approval is **not confirmed**. Playback on the original SEAT screen is **not verified**. This repository does **not** modify the car's firmware, ECU, radio, or safety controls.

Work in progress: [Cafari Lite](https://github.com/rPlayAI/cafari-lite) is an MIT-licensed upstream starting point (Copyright 2026 rPlay AI). Our adaptation should prevent video playback when movement status is unknown, unavailable, or indicates driving. Vehicle motion inferred from iPhone GPS is imperfect; never assume it is a certified parked signal.

### Roadmap
1. Review upstream source, license, and parked-only behavior.
2. Prototype the UI on Windows/iPhone, separately from the vehicle.
3. Build for iPhone with Xcode / authorized macOS CI; check entitlements in signed app.
4. Only after Apple entitlement approval, evaluate real CarPlay video compatibility **with the vehicle parked**.
5. No firmware changes, jailbreak, unsafe video bypass, or payment/production changes in unrelated projects.

A paid Apple Developer membership **does not** automatically grant `com.apple.developer.carplay-video` (or audio). Request entitlement(s) from Apple and use only approved, matching provisioning profiles.
