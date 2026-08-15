#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-}"
if [[ ! "$VERSION" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]]; then
    print -u2 "Usage: $0 X.Y.Z"
    exit 1
fi

BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" Info.plist)
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $((BUILD + 1))" Info.plist
echo "Irodake $VERSION (build $((BUILD + 1)))"
