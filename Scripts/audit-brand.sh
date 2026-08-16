#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> Verify canonical brand identifiers"

CANONICAL_BUNDLE_ID="irodake.hinoshiba.com"

if [[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' Info.plist)" != "Irodake" ]] || \
   [[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' Info.plist)" != "Irodake" ]] || \
   [[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' Info.plist)" != "$CANONICAL_BUNDLE_ID" ]]; then
    print -u2 "Info.plist brand identifiers are inconsistent."
    exit 1
fi

if [[ "$(plutil -extract bundleIdentifier raw -o - app-store/app.json)" != "$CANONICAL_BUNDLE_ID" ]]; then
    print -u2 "App Store bundle identifier is inconsistent."
    exit 1
fi

if ! grep -nE 'name: "Irodake"|name: "IrodakeTests"|path: "Sources/Irodake"|path: "Tests/IrodakeTests"' Package.swift >/dev/null; then
    print -u2 "Swift package brand identifiers are missing."
    exit 1
fi

LEGACY=$(git grep --untracked -nE \
    'Sukima|sukima|SUKM|com\.hinoshiba\.sukima|com\.hinoshiba\.[Ii]rodake|github\.com/hinoshiba/Sukima' \
    -- . ':!Scripts/audit-brand.sh' ':!Scripts/audit-store-assets.sh' || true)

if [[ -n "$LEGACY" ]]; then
    print -u2 "Unexpected legacy brand identifier found:"
    print -u2 "$LEGACY"
    exit 1
fi

echo "Brand audit passed: Irodake / $CANONICAL_BUNDLE_ID"
