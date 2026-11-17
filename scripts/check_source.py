"""Conservative source checks; not a substitute for signing/road-safety tests."""
from pathlib import Path
import plistlib

gate = Path("CafariLite/CarGate.swift").read_text()
browser = Path("CafariLite/BrowserViewController.swift").read_text()
settings = Path("CafariLite/Settings.swift").read_text()
signing = Path("Signing.xcconfig").read_text()
with Path("CarPlay.entitlements").open("rb") as file:
    entitlements = plistlib.load(file)
keys = [key for key in entitlements if key.startswith("com.apple.developer.carplay-")]
assert keys == ["com.apple.developer.carplay-video"], f"Must use video-only entitlement, got: {keys}"
assert entitlements["com.apple.developer.carplay-video"] is True
assert "private(set) var isMoving = true" in gate, "GPS gate must default blocked"
assert "setBlocked(true)" in gate and "checkFreshness()" in gate
assert "playOnlyWhenParked" not in browser + settings, "No motion bypass allowed"
assert "if CarGate.shared.isMoving" in browser
assert "carPendingURL = url" in browser
assert "\nCAFARI_LITE_ENTITLEMENTS =\n" in signing, "Entitlements should be off by default"
print("Static safety and video-only signing invariants passed; car capability unverified.")
