# Test plan — AronaOS prototype

## Repository / CI
- [ ] Static invariants pass.
- [ ] Unsigned Xcode simulator-target **compiles** on macOS; compilation does not make car scene work.
- [ ] No developer secrets or profiles committed.
- [ ] Review MIT attribution and app privacy behaviours.

## Phone-only
- [ ] Sign with own bundle ID and Apple team using macOS Xcode.
- [ ] Install and launch on iPhone without CarPlay entitlements.
- [ ] Phone web view opens; no promise of car display.

## CarPlay (BLOCKED until approved)
- [ ] Apple explicitly approves video/audio entitlements needed by architecture.
- [ ] Signed build contains only Apple-approved entitlements; profile matches.
- [ ] Vehicle reports support for CarPlay video and safely parked operation.
- [ ] Denied GPS, stale fixes, low quality fixes, motion and GPS loss all keep car content blocked.
- [ ] No bypass for safety / app policy / parked detection.
- [ ] Video absent while vehicle moving or parked-state cannot be verified by trusted vehicle/OS.
- [ ] No test while driving on public roads.

**Critical limitation:** phone GPS being stationary is not proof of parking; a stopped vehicle at a red light must not make video available. Until trusted OS/vehicle gating is confirmed, any prototype car-window video should not be treated as safe for road use.
