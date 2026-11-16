#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TAG="${1:-v1.0.0}"
: "${DEVELOPER_ID_APPLICATION:?Set the exact Developer ID Application signing identity}"
: "${APPLE_TEAM_ID:?Set the 10-character Apple Developer Team ID}"
: "${NOTARYTOOL_PROFILE:?Set the notarytool keychain profile name}"

if ! security find-identity -v -p codesigning | grep -F "$DEVELOPER_ID_APPLICATION" >/dev/null; then
  echo "Signing identity not found in the keychain: $DEVELOPER_ID_APPLICATION" >&2
  exit 1
fi

OUT="$ROOT/build/release/${TAG}"
ARCHIVE="$OUT/Qyube.xcarchive"
EXPORT="$OUT/export"
APP="$EXPORT/Qoma.app"
DMG="$OUT/Qyube-${TAG}-macOS.dmg"
ZIP="$OUT/Qyube-${TAG}-notarization.zip"
OPTIONS="$OUT/ExportOptions.plist"
mkdir -p "$OUT" "$EXPORT"

plutil -create xml1 "$OPTIONS"
plutil -insert destination -string export "$OPTIONS"
plutil -insert method -string developer-id "$OPTIONS"
plutil -insert signingStyle -string manual "$OPTIONS"
plutil -insert teamID -string "$APPLE_TEAM_ID" "$OPTIONS"
plutil -insert signingCertificate -string "$DEVELOPER_ID_APPLICATION" "$OPTIONS"

xcodebuild archive -project "$ROOT/qoma.xcodeproj" -scheme Qoma -configuration Release \
  -destination 'generic/platform=macOS' -archivePath "$ARCHIVE" \
  CODE_SIGN_IDENTITY="$DEVELOPER_ID_APPLICATION" DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
  CODE_SIGN_STYLE=Manual
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportPath "$EXPORT" -exportOptionsPlist "$OPTIONS"

codesign --verify --deep --strict --verbose=2 "$APP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"
xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARYTOOL_PROFILE" --wait
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"

hdiutil create -volname Qyube -srcfolder "$APP" -ov -format UDZO "$DMG"
codesign --force --timestamp --sign "$DEVELOPER_ID_APPLICATION" "$DMG"
xcrun notarytool submit "$DMG" --keychain-profile "$NOTARYTOOL_PROFILE" --wait
xcrun stapler staple "$DMG"
xcrun stapler validate "$DMG"

shasum -a 256 "$DMG" > "$DMG.sha256"
if gh release view "$TAG" --repo BroKarim/qoma >/dev/null 2>&1; then
  gh release upload "$TAG" "$DMG" "$DMG.sha256" --repo BroKarim/qoma --clobber
else
  gh release create "$TAG" "$DMG" "$DMG.sha256" --repo BroKarim/qoma \
    --title "Qyube ${TAG#v}" --generate-notes
fi
echo "Published $DMG and checksum to GitHub release $TAG"
