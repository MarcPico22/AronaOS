# AronaOS verification checklist

## Account and provisioning
- [x] Developer reports CarPlay Video approval email.
- [x] Repo's CarPlay entitlement file is **Video only**; signing disabled by default.
- [ ] Enable the video capability on an explicit App ID in Apple Developer and save.
- [ ] Generate fresh matching development provisioning profile.
- [ ] Configure local Bundle ID / Team ID and sign a real iPhone build on macOS.
- [ ] Check signed entitlements include Video ONLY (no Audio).

## Compatibility
- [ ] Test iPhone updated from iOS 26.4 to **iOS 27+**.
- [ ] Verify official CarPlay video UI implementation with iOS 27 SDK.
- [ ] Confirm CarPlay Video support on a compatible vehicle/simulator.
- [ ] Confirm **this specific SEAT Arona** supports video; if not, the video-only app is hidden.

## Safety and QA
- [ ] Static checks + unsigned simulator-target build pass at latest commit.
- [ ] No signed profile, certs, private keys in public GitHub.
- [ ] Replace legacy experimental car-side WKWebView with official CarPlay framework video flow.
- [ ] Trust the OS/vehicle's parked-state enforcement; GPS zero is insufficient.
- [ ] No testing video while vehicle moving; no firmware/ECU alterations.

*Approval is account-level, not proof of App ID configuration or hardware compatibility.*
