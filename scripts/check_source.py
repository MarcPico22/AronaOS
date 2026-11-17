"""CarOs static security and architecture checks; simulator/hardware QA still required."""
from pathlib import Path
import plistlib

source = Path("CafariLite")
car = (source / "CarPlaySceneDelegate.swift").read_text()
browser = (source / "BrowserViewController.swift").read_text()
dashboard = (source / "CarOsDashboardViewController.swift").read_text()
library = (source / "CarOsVideoLibrary.swift").read_text()
player_ui = (source / "CarOsVideoLibraryViewController.swift").read_text()
signing = Path("Signing.xcconfig").read_text()

with Path("CarPlay.entitlements").open("rb") as file:
    entitlements = plistlib.load(file)
keys = [k for k in entitlements if k.startswith("com.apple.developer.carplay-")]
assert keys == ["com.apple.developer.carplay-video"], f"video-only required, got {keys}"
assert entitlements[keys[0]] is True
assert "\nCAFARI_LITE_ENTITLEMENTS =\n" in signing, "Entitlements must be off by default"

with Path("Info.plist").open("rb") as file:
    info = plistlib.load(file)
assert info["CFBundleDisplayName"] == "CarOs"
config = info["UIApplicationSceneManifest"]["UISceneConfigurations"]["CPTemplateApplicationSceneSessionRoleApplication"][0]
assert config["UISceneClassName"] == "CPTemplateApplicationScene", "No custom car UIKit window"
assert config["UISceneDelegateClassName"].endswith(".CarPlaySceneDelegate")

assert "CPTemplateApplicationSceneDelegate" in car
assert "CPGridTemplate" in car and "CPListTemplate" in car
assert "supportsVideoPlayback" in car and "#available(iOS 27.0" in car
assert "UIWindow(" not in car and "WKWebView(" not in car, "No custom car overlays"
assert "CarOsVideoLibrary.items" in car
assert "CarOsVideoPlayback.shared.play" in car
assert "CPPlaybackConfiguration(" in car and "preferredPresentation: .video" in car
assert "CarOsVideoPlayback.shared.stop" in car
assert "AVRoutePickerView" in player_ui and "AVPlayerViewController" in player_ui
assert "components.scheme?.lowercased() == \"https\"" in library
assert 'path.hasSuffix(".m3u8")' in library and 'path.hasSuffix(".mp4")' in library
assert "allowsExternalPlayback = true" in library
assert "AVPlayerLayer()" in library and "mode: .moviePlayback" in library
assert "MPNowPlayingInfoCenter" in library
assert "CarOsDashboardViewController" in (source / "SceneDelegate.swift").read_text()
assert "CarOsVideoLibraryViewController" in dashboard
assert "CarOsVideoPlayback.shared.attachVideoOutput" in dashboard
assert "caros.shortcuts.v1" in dashboard and "caros.theme.v1" in dashboard
assert "showCarPlayInformation" in browser and '#selector(sendToCar)' not in browser
assert Path("CafariLite.xcodeproj/project.pbxproj").read_text().count("IPHONEOS_DEPLOYMENT_TARGET = 27.0;") == 2
# App Store Connect requires a properly configured AppIcon catalog.
assert Path("CafariLite/Assets.xcassets/AppIcon.appiconset/Contents.json").exists()
assert "ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;" in Path("CafariLite.xcodeproj/project.pbxproj").read_text()
assert "representation(using: .jpeg" in Path("scripts/generate_app_icon.swift").read_text()
print("CarOs checks passed: official CarPlay templates, video-only capability, HTTPS media links and local dashboard.")
