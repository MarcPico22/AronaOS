"""Fast source invariants; not a substitute for iOS/car testing."""
from pathlib import Path

gate = Path("CafariLite/CarGate.swift").read_text()
browser = Path("CafariLite/BrowserViewController.swift").read_text()
settings = Path("CafariLite/Settings.swift").read_text()
signing = Path("Signing.xcconfig").read_text()

assert "private(set) var isMoving = true" in gate, "gate must default to blocked"
assert "setBlocked(true)" in gate and "checkFreshness()" in gate
assert "playOnlyWhenParked" not in browser + settings, "no gate bypass allowed"
assert "if CarGate.shared.isMoving" in browser
assert "carPendingURL = url" in browser
assert "CAFARI_LITE_ENTITLEMENTS =" in signing
assert "CAFARI_LITE_ENTITLEMENTS = CarPlay.entitlements" not in signing
print("Static invariants passed (not a signed build or parked-state certification).")
