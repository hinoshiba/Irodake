#!/bin/sh
set -eu

if [ "${CI_XCODEBUILD_ACTION:-}" != "archive" ]; then
  exit 0
fi

# Xcode Cloud invokes post scripts even after xcodebuild fails. Preserve the
# original failure and audit only a completed archive.
if [ "${CI_XCODEBUILD_EXIT_CODE:-1}" != "0" ]; then
  exit 0
fi

: "${CI_ARCHIVE_PATH:?Xcode Cloud did not provide the archive path}"
: "${CI_TAG:?Xcode Cloud release archives require a Git tag}"
: "${CI_BUILD_NUMBER:?Xcode Cloud did not provide a build number}"

app="$CI_ARCHIVE_PATH/Products/Applications/Irodake.app"
info="$app/Contents/Info.plist"
executable="$app/Contents/MacOS/Irodake"

if [ ! -d "$app" ] || [ ! -f "$info" ] || [ ! -x "$executable" ]; then
  echo "error: Irodake.app is missing from the completed archive" >&2
  exit 1
fi

bundle_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$info")
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$info")
build=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$info")

if [ "$bundle_id" != "com.hinoshiba.irodake" ]; then
  echo "error: archived app has unexpected bundle identifier: $bundle_id" >&2
  exit 1
fi
if [ "$version" != "${CI_TAG#v}" ] || [ "$build" != "$CI_BUILD_NUMBER" ]; then
  echo "error: archived app version/build does not match the Xcode Cloud release" >&2
  exit 1
fi

codesign --verify --deep --strict "$app"
entitlements=$(mktemp /tmp/irodake-cloud-entitlements.XXXXXX)
unexpected_dependencies_file=$(mktemp /tmp/irodake-cloud-dependencies.XXXXXX)
otool_output=$(mktemp /tmp/irodake-cloud-otool.XXXXXX)
dependencies_file=$(mktemp /tmp/irodake-cloud-dependency-list.XXXXXX)
trap 'rm -f "$entitlements" "$unexpected_dependencies_file" "$otool_output" "$dependencies_file"' EXIT
codesign -d --entitlements :- "$app" 2>&1 | sed -n '/^<?xml/,$p' > "$entitlements"
if [ "$(plutil -extract 'com\.apple\.security\.app-sandbox' raw -o - "$entitlements")" != "true" ]; then
  echo "error: archived app is missing the App Sandbox entitlement" >&2
  exit 1
fi

for resource in PrivacyInfo.xcprivacy LICENSE THIRD_PARTY_LICENSES.txt TRADEMARKS.md; do
  if [ ! -f "$app/Contents/Resources/$resource" ]; then
    echo "error: archived app is missing resource: $resource" >&2
    exit 1
  fi
done

architectures=$(lipo -archs "$executable")
case " $architectures " in *' arm64 '*) ;; *) echo "error: archived app is missing arm64" >&2; exit 1 ;; esac
case " $architectures " in *' x86_64 '*) ;; *) echo "error: archived app is missing x86_64" >&2; exit 1 ;; esac

if [ -d "$app/Contents/Frameworks" ]; then
  echo "error: archived app unexpectedly bundles third-party frameworks" >&2
  exit 1
fi

if ! otool -L "$executable" > "$otool_output"; then
  echo "error: failed to inspect archived app dependencies" >&2
  exit 1
fi
if ! awk '/^[[:space:]]/ {print $1}' "$otool_output" > "$dependencies_file"; then
  echo "error: failed to parse archived app dependencies" >&2
  exit 1
fi
while IFS= read -r dependency; do
  case "$dependency" in
    /System/Library/*|/usr/lib/*) ;;
    *) printf '%s\n' "$dependency" >> "$unexpected_dependencies_file" ;;
  esac
done < "$dependencies_file"
if [ -s "$unexpected_dependencies_file" ]; then
  echo "error: archived app has unexpected dynamic dependencies" >&2
  cat "$unexpected_dependencies_file" >&2
  exit 1
fi

echo "Verified Irodake $version ($build) Xcode Cloud archive"
