#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."

xmllint --noout http_dist/sitemap.xml
swift Scripts/AuditStoreAssets.swift

if rg -n 'hinoshiba\.github\.io/Irodake|github\.com/hinoshiba/Sukima' app-store http_dist Sources/Irodake/UI/AboutView.swift; then
    print -u2 "Stale public URL found."
    exit 1
fi
