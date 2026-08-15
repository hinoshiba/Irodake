#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."

APP="${1:-dist/Irodake.app}"
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Contents/Info.plist")
DMG="dist/Irodake-${VERSION}.dmg"
STAGE=$(mktemp -d /tmp/irodake-dmg.XXXXXX)
trap 'rm -rf "$STAGE"' EXIT

cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "Irodake" -srcfolder "$STAGE" -ov -format UDZO "$DMG"

if [[ -n "${IRODAKE_DIST_IDENTITY:-}" ]]; then
    codesign --force --timestamp --sign "$IRODAKE_DIST_IDENTITY" "$DMG"
fi

if [[ -z "${IRODAKE_NOTARY_PROFILE:-}" ]]; then
    print -u2 "IRODAKE_NOTARY_PROFILE is required for distributable DMGs."
    exit 1
fi
xcrun notarytool submit "$DMG" --keychain-profile "$IRODAKE_NOTARY_PROFILE" --wait
xcrun stapler staple "$DMG"
xcrun stapler validate "$DMG"
spctl --assess --type open --context context:primary-signature --verbose=2 "$DMG"

echo "Created: $DMG"
