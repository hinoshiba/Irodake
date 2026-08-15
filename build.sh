#!/bin/zsh
# Build Irodake.app with no third-party downloads.
#   ./build.sh            Development build (host architecture, ad-hoc signed)
#   ./build.sh --dist     Universal Developer ID build + notarized DMG
#   ./build.sh --store    Universal Mac App Store signed PKG
set -euo pipefail
cd "$(dirname "$0")"

MODE="dev"
if [[ "${1:-}" == "--dist" || "${1:-}" == "dist" ]]; then
    MODE="dist"
elif [[ "${1:-}" == "--store" || "${1:-}" == "store" ]]; then
    MODE="store"
fi

if [[ "$MODE" == "dist" || "$MODE" == "store" ]]; then
    swift build -c release --arch arm64 --arch x86_64
    BIN=".build/apple/Products/Release/Irodake"
else
    swift build -c release
    BIN=".build/release/Irodake"
fi

APP="dist/Irodake.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Irodake"
cp Info.plist "$APP/Contents/Info.plist"
cp LICENSE "$APP/Contents/Resources/LICENSE.txt"
cp THIRD_PARTY_LICENSES.txt "$APP/Contents/Resources/THIRD_PARTY_LICENSES.txt"
cp TRADEMARKS.md "$APP/Contents/Resources/TRADEMARKS.txt"
cp PrivacyInfo.xcprivacy "$APP/Contents/Resources/PrivacyInfo.xcprivacy"
cp -R Resources/*.lproj "$APP/Contents/Resources/"
printf 'APPL????' > "$APP/Contents/PkgInfo"

if [[ ! -f "dist/AppIcon.icns" ]]; then
    swift Scripts/MakeIcon.swift dist
    iconutil -c icns dist/Irodake.iconset -o dist/AppIcon.icns
fi
cp dist/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

if [[ "$MODE" == "dist" || "$MODE" == "store" ]]; then
    ARCHS=$(lipo -archs "$APP/Contents/MacOS/Irodake")
    if [[ "$ARCHS" != *arm64* || "$ARCHS" != *x86_64* ]]; then
        print -u2 "Distribution build is not universal: $ARCHS"
        exit 1
    fi

fi

if [[ "$MODE" == "dist" ]]; then
    DIST_ID="${IRODAKE_DIST_IDENTITY:-}"
    if [[ -z "$DIST_ID" ]]; then
        print -u2 "Set IRODAKE_DIST_IDENTITY explicitly to the intended Developer ID Application identity."
        exit 1
    fi
    codesign --force --options runtime --timestamp \
        --entitlements Irodake.direct.entitlements --sign "$DIST_ID" "$APP"
    codesign --verify --deep --strict --verbose=2 "$APP"
    export IRODAKE_DIST_IDENTITY="$DIST_ID"
    if [[ -z "${IRODAKE_NOTARY_PROFILE:-}" ]]; then
        print -u2 "Set IRODAKE_NOTARY_PROFILE; refusing to create an unnotarized distribution."
        exit 1
    fi
    ./Scripts/make-dmg.sh "$APP"
elif [[ "$MODE" == "store" ]]; then
    APP_ID="${IRODAKE_APP_STORE_IDENTITY:-}"
    INSTALLER_ID="${IRODAKE_INSTALLER_IDENTITY:-}"
    PROFILE="${IRODAKE_PROVISIONING_PROFILE:-}"
    if [[ -z "$APP_ID" || -z "$INSTALLER_ID" || ! -f "$PROFILE" ]]; then
        print -u2 "Store build requires IRODAKE_APP_STORE_IDENTITY, IRODAKE_INSTALLER_IDENTITY, and IRODAKE_PROVISIONING_PROFILE."
        exit 1
    fi
    cp "$PROFILE" "$APP/Contents/embedded.provisionprofile"
    codesign --force --options runtime --timestamp \
        --entitlements Irodake.entitlements --sign "$APP_ID" "$APP"
    codesign --verify --deep --strict --verbose=2 "$APP"
    VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Info.plist)
    PKG="dist/Irodake-${VERSION}-AppStore.pkg"
    productbuild --component "$APP" /Applications --sign "$INSTALLER_ID" "$PKG"
    pkgutil --check-signature "$PKG"
    echo "Built for App Store upload: $PKG"
else
    codesign --force --entitlements Irodake.direct.entitlements --sign - "$APP"
fi

echo "Built: $APP"
