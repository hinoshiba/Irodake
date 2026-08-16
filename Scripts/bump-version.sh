#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-}"
if [[ ! "$VERSION" =~ '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' ]]; then
    print -u2 "Usage: $0 X.Y.Z"
    exit 1
fi

if ! command -v xcodegen >/dev/null 2>&1; then
    print -u2 "XcodeGen is required to update the committed Xcode project (brew install xcodegen)."
    exit 1
fi

BUILD=$(sed -n 's/^[[:space:]]*CURRENT_PROJECT_VERSION: "\([0-9][0-9]*\)"/\1/p' project.yml)
perl -0pi -e 's/MARKETING_VERSION: "[^"]+"/MARKETING_VERSION: "'"$VERSION"'"/' project.yml
perl -0pi -e 's/CURRENT_PROJECT_VERSION: "[^"]+"/CURRENT_PROJECT_VERSION: "'"$((BUILD + 1))"'"/' project.yml
xcodegen generate
echo "Irodake $VERSION (build $((BUILD + 1)))"
