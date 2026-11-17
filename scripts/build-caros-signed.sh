#!/usr/bin/env bash
# CarOs: signed App Store Connect IPA export (manual GitHub Actions).
# Requires CAROS_P12_BASE64, CAROS_P12_PASSWORD, CAROS_PROFILE_BASE64 secrets.
# Never prints secrets; never uploads to App Store Connect automatically.
set -euo pipefail
umask 077

for variable in CAROS_P12_BASE64 CAROS_P12_PASSWORD CAROS_PROFILE_BASE64; do
  if [[ -z "${!variable:-}" ]]; then
    echo "::error::Missing Actions secret: $variable"
    exit 1
  fi
done

echo "Using $(xcodebuild -version | head -1)"
if [[ "$(xcodebuild -version | head -1)" != Xcode\ 27* ]]; then
  echo "::error::CarOs requires Xcode 27 for this distribution test."
  exit 1
fi

working="$RUNNER_TEMP/car-os-signing"
mkdir -p "$working" "$HOME/Library/MobileDevice/Provisioning Profiles"
p12="$working/distribution.p12"
profile="$working/distribution.mobileprovision"
profile_plist="$working/profile.plist"
keychain="$working/temporary.keychain-db"
keychain_password="$(/usr/bin/openssl rand -hex 24)"

printf '%s' "$CAROS_P12_BASE64" | base64 -D > "$p12"
printf '%s' "$CAROS_PROFILE_BASE64" | base64 -D > "$profile"
security cms -D -i "$profile" > "$profile_plist"

# Validate the distribution profile and get only non-secret metadata.
python3 - "$profile_plist" "$working/profile.env" <<'PY'
import plistlib
import shlex
import sys
from pathlib import Path
profile = plistlib.loads(Path(sys.argv[1]).read_bytes())
e = profile.get("Entitlements", {})
app_id = e.get("application-identifier", "")
assert app_id.endswith(".com.marcpico.aronaos"), "Wrong App ID in profile"
assert e.get("com.apple.developer.carplay-video") is True, "CarPlay Video missing from profile"
assert "com.apple.developer.carplay-audio" not in e, "CarPlay Audio cannot be combined with Video"
assert e.get("get-task-allow", False) is False, "Development profile cannot export App Store IPA"
team = profile.get("TeamIdentifier", [])
assert len(team) == 1 and app_id == f"{team[0]}.com.marcpico.aronaos", "Team/App ID mismatch"
name = profile["Name"]
uuid = profile["UUID"]
assert all("\n" not in value and "\r" not in value for value in (team[0], name, uuid))
assert profile.get("ExpirationDate"), "Missing expiry"
with Path(sys.argv[2]).open("w") as output:
    output.write(f"TEAM_ID={shlex.quote(team[0])}\n")
    output.write(f"PROFILE_NAME={shlex.quote(name)}\n")
    output.write(f"PROFILE_UUID={shlex.quote(uuid)}\n")
print("Distribution profile validated for CarOs with Video-only entitlement")
PY
# Controlled metadata from a signed Apple provisioning profile.
source "$working/profile.env"
cp "$profile" "$HOME/Library/MobileDevice/Provisioning Profiles/$PROFILE_UUID.mobileprovision"

# Keychain is local to this disposable macOS runner.
security create-keychain -p "$keychain_password" "$keychain"
security set-keychain-settings -lut 21600 "$keychain"
security unlock-keychain -p "$keychain_password" "$keychain"
security list-keychains -d user -s "$keychain"
security default-keychain -d user -s "$keychain"
security import "$p12" -k "$keychain" -P "$CAROS_P12_PASSWORD" -T /usr/bin/codesign >/dev/null
security set-key-partition-list -S apple-tool:,apple: -s -k "$keychain_password" "$keychain" >/dev/null
security find-identity -p codesigning -v "$keychain" | grep 'Apple Distribution:' >/dev/null || {
  echo "::error::No valid Apple Distribution identity was imported"
  exit 1
}

# Require an explicit entitlement file; never combine Audio and Video.
python3 - <<'PY'
import plistlib
from pathlib import Path
data = plistlib.loads(Path("CarPlay.entitlements").read_bytes())
carplay_keys = [key for key in data if key.startswith("com.apple.developer.carplay-")]
assert carplay_keys == ["com.apple.developer.carplay-video"]
assert data["com.apple.developer.carplay-video"] is True
PY

# App Store Connect requires an opaque 1024px icon inside the signed app.
swift scripts/generate_app_icon.swift
archive="$RUNNER_TEMP/CarOs.xcarchive"
mkdir -p "$GITHUB_WORKSPACE/build/signed-export"
xcodebuild archive \
  -project CafariLite.xcodeproj \
  -scheme CafariLite \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$archive" \
  PRODUCT_BUNDLE_IDENTIFIER=com.marcpico.aronaos \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY='Apple Distribution' \
  PROVISIONING_PROFILE_SPECIFIER="$PROFILE_NAME" \
  CODE_SIGN_ENTITLEMENTS=CarPlay.entitlements \
  CURRENT_PROJECT_VERSION="${GITHUB_RUN_NUMBER:-1}"

app="$archive/Products/Applications/CafariLite.app"
if [[ ! -d "$app" ]]; then
  echo "::error::Archive did not produce the expected iOS app"
  exit 1
fi
codesign --verify --strict "$app"
codesign -d --entitlements :- "$app" > "$working/signed-entitlements.plist" 2>/dev/null
python3 - "$working/signed-entitlements.plist" "$TEAM_ID" <<'PY'
import plistlib
import sys
from pathlib import Path
e = plistlib.loads(Path(sys.argv[1]).read_bytes())
assert e.get("com.apple.developer.carplay-video") is True, "Signed app has no CarPlay Video entitlement"
assert "com.apple.developer.carplay-audio" not in e, "Unexpected CarPlay Audio entitlement"
assert e.get("application-identifier") == f"{sys.argv[2]}.com.marcpico.aronaos", "Wrong signed App ID"
print("Signed app entitlements verified: CarPlay Video ONLY")
PY

# Export only; do not submit to Apple in this workflow.
python3 - "$working/exportOptions.plist" "$TEAM_ID" "$PROFILE_NAME" <<'PY'
import plistlib
import sys
from pathlib import Path
data = {
    "method": "app-store-connect",
    "destination": "export",
    "signingStyle": "manual",
    "teamID": sys.argv[2],
    "provisioningProfiles": {"com.marcpico.aronaos": sys.argv[3]},
    "uploadSymbols": False,
    "manageAppVersionAndBuildNumber": False,
}
with Path(sys.argv[1]).open("wb") as f:
    plistlib.dump(data, f)
PY
xcodebuild -exportArchive \
  -archivePath "$archive" \
  -exportPath "$GITHUB_WORKSPACE/build/signed-export" \
  -exportOptionsPlist "$working/exportOptions.plist"

find "$GITHUB_WORKSPACE/build/signed-export" -maxdepth 1 -type f -name '*.ipa' -print | grep -q '.ipa'
echo "SIGNED IPA exported locally in GitHub Actions. Not uploaded to TestFlight."
