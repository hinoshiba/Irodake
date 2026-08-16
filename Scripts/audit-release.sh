#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."

APP="${1:-dist/Irodake.app}"
if [[ ! -d "$APP" ]]; then
    print -u2 "App not found: $APP"
    exit 1
fi

./Scripts/audit-brand.sh
./Scripts/audit-store-assets.sh

echo "==> Validate property lists"
plutil -lint Info.plist PrivacyInfo.xcprivacy Irodake.entitlements Irodake.direct.entitlements
plutil -lint Resources/ja.lproj/InfoPlist.strings Resources/en.lproj/InfoPlist.strings
if [[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Contents/Info.plist")" != "irodake.hinoshiba.com" ]]; then
    print -u2 "Built app has an unexpected bundle identifier."
    exit 1
fi

echo "==> Verify signature and sandbox"
codesign --verify --deep --strict --verbose=2 "$APP"
ENTITLEMENTS=$(mktemp /tmp/irodake-entitlements.XXXXXX)
trap 'rm -f "$ENTITLEMENTS"' EXIT
codesign -d --entitlements :- "$APP" 2>&1 | sed -n '/^<?xml/,$p' > "$ENTITLEMENTS"
if [[ "$(plutil -extract 'com\.apple\.security\.app-sandbox' raw -o - "$ENTITLEMENTS")" != "true" ]]; then
    print -u2 "App Sandbox entitlement is missing."
    exit 1
fi

echo "==> Verify bundled compliance resources"
for resource in LICENSE.txt THIRD_PARTY_LICENSES.txt TRADEMARKS.txt PrivacyInfo.xcprivacy; do
    if [[ ! -f "$APP/Contents/Resources/$resource" ]]; then
        print -u2 "Missing resource: $resource"
        exit 1
    fi
done
cmp LICENSE "$APP/Contents/Resources/LICENSE.txt"
cmp THIRD_PARTY_LICENSES.txt "$APP/Contents/Resources/THIRD_PARTY_LICENSES.txt"
cmp TRADEMARKS.md "$APP/Contents/Resources/TRADEMARKS.txt"
cmp PrivacyInfo.xcprivacy "$APP/Contents/Resources/PrivacyInfo.xcprivacy"
for locale in ja en; do
    cmp "Resources/$locale.lproj/InfoPlist.strings" \
        "$APP/Contents/Resources/$locale.lproj/InfoPlist.strings"
done

echo "==> Verify no bundled third-party binaries"
if [[ -d "$APP/Contents/Frameworks" ]]; then
    print -u2 "Unexpected bundled Frameworks directory. Re-run license review."
    exit 1
fi
UNEXPECTED=$(otool -L "$APP/Contents/MacOS/Irodake" | awk 'NR > 1 {print $1}' \
    | while read -r dependency; do
        case "$dependency" in
            /System/Library/*|/usr/lib/*) ;;
            *) echo "$dependency" ;;
        esac
      done)
if [[ -n "$UNEXPECTED" ]]; then
    print -u2 "Unexpected dynamic dependencies:"
    print -u2 "$UNEXPECTED"
    exit 1
fi

echo "==> Verify privacy-sensitive invariants"
grep -nE 'configuration\.capturesAudio = false' Sources/Irodake/Capture/CaptureManager.swift >/dev/null
if grep -RInE 'URLSession|NWConnection|Network\.framework|import Network|CFNetwork' Sources Package.swift; then
    print -u2 "Network-related code found. Re-run privacy and entitlement review."
    exit 1
fi
if grep -RInE 'CGS[A-Z]|SkyLight|CoreDisplay' Sources; then
    print -u2 "Private display API marker found."
    exit 1
fi

echo "==> Verify dependency graph"
DEPENDENCIES=$(swift package show-dependencies)
if [[ "$DEPENDENCIES" != "No external dependencies found" ]]; then
    print -u2 "Dependency graph is non-empty; this release requires a new license review."
    print -u2 "$DEPENDENCIES"
    exit 1
fi

echo "Release audit passed: $APP"
