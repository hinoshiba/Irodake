#!/bin/zsh
set -euo pipefail

SCRIPT_DIR=${0:A:h}
ROOT_DIR=${SCRIPT_DIR:h}
cd "$ROOT_DIR"

CAPTURE_SOURCE='Sources/Irodake/Capture/CaptureManager.swift'
if ! /usr/bin/grep -nE \
    'configuration[.]capturesAudio[[:space:]]*=[[:space:]]*false' \
    "$CAPTURE_SOURCE" >/dev/null; then
    print -u2 'Audio capture must remain explicitly disabled.'
    exit 1
fi

if /usr/bin/grep -RInE \
    'URLSession|NWConnection|Network[.]framework|import Network|CFNetwork' \
    Sources Package.swift; then
    print -u2 'Network-related code found; privacy, entitlement, and App Store disclosures require review.'
    exit 1
fi

if /usr/bin/grep -RInE 'CGS[A-Z]|SkyLight|CoreDisplay' Sources; then
    print -u2 'Private display API marker found.'
    exit 1
fi

ABOUT_SOURCE='Sources/Irodake/UI/AboutView.swift'
if ! /usr/bin/grep -Fq 'object(forInfoDictionaryKey: "CFBundleShortVersionString")' "$ABOUT_SOURCE" || \
   ! /usr/bin/grep -Fq '?? "—"' "$ABOUT_SOURCE"; then
    print -u2 'About must display the bundle marketing version and avoid a release-specific fallback.'
    exit 1
fi

DEPENDENCIES=$(swift package show-dependencies)
if [[ "$DEPENDENCIES" != 'No external dependencies found' ]]; then
    print -u2 'The Swift package dependency graph is non-empty; update the license and privacy review.'
    print -u2 "$DEPENDENCIES"
    exit 1
fi

print 'Source privacy, public-API, and dependency audit passed.'
