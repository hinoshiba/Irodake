# Release Guide

This guide separates Developer ID direct distribution from Mac App Store distribution. Never reuse Store signing identities, provisioning profiles, or update mechanisms across the two paths without review.

## Preflight for every release

1. Complete [COMMERCIAL_RELEASE_GATES.md](COMMERCIAL_RELEASE_GATES.md).
2. Release from a reviewed, clean, signed tag; no untracked source files.
3. Update version before building:

   ```bash
   ./Scripts/bump-version.sh X.Y.Z
   ```

4. Run:

   ```bash
   swift build -c release
   swift test
   ./build.sh
   ./Scripts/audit-release.sh dist/Irodake.app
   VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Info.plist)
   REVISION=$(git rev-parse HEAD)
   swift Scripts/GenerateSBOM.swift "$VERSION" "$REVISION" "dist/Irodake-$VERSION.spdx.json"
   ```

5. Re-run dependency/license/advisory, Privacy Manifest, export-compliance, App Review Guideline, and trademark/name checks.
6. Record Xcode, Swift, macOS, commit SHA, build number, entitlements, and test-matrix results.

## Developer ID direct distribution

Requirements:

- explicit Developer ID Application identity;
- Hardened Runtime;
- App Sandbox retained;
- `notarytool` keychain profile;
- no updater in the initial build;
- HTTPS download and public Privacy Policy / Terms / seller information.

One-time setup:

```bash
xcrun notarytool store-credentials irodake-notary \
  --apple-id YOUR_APPLE_ID \
  --team-id YOUR_TEAM_ID \
  --password YOUR_APP_SPECIFIC_PASSWORD
```

Build:

```bash
export IRODAKE_DIST_IDENTITY='Developer ID Application: Legal Name (TEAMID)'
export IRODAKE_NOTARY_PROFILE='irodake-notary'
./build.sh --dist
```

The script:

1. creates an arm64 + x86_64 binary;
2. assembles resources and entitlements;
3. signs with timestamp + Hardened Runtime;
4. verifies the app signature;
5. builds and signs the DMG;
6. submits the DMG to Apple notary service and waits;
7. staples and validates the DMG;
8. runs Gatekeeper assessment.

Before upload, record hashes without modifying the asset:

```bash
shasum -a 256 dist/Irodake-X.Y.Z.dmg
shasum -a 512 dist/Irodake-X.Y.Z.dmg
```

Published release assets are immutable. Never overwrite a DMG, tag, checksum, SBOM, or attestation. Increase the version for any correction.

## Mac App Store distribution

Requirements:

- a registered, legally cleared final app name and bundle identifier;
- Paid Apps Agreement / tax / banking when selling;
- Mac App Distribution application identity;
- Mac Installer Distribution identity;
- distribution provisioning profile for the exact bundle ID;
- App Sandbox;
- no Sparkle or external license-key updater;
- public support and Privacy Policy URLs.

Build a signed installer package:

```bash
export IRODAKE_APP_STORE_IDENTITY='3rd Party Mac Developer Application: Legal Name (TEAMID)'
export IRODAKE_INSTALLER_IDENTITY='3rd Party Mac Developer Installer: Legal Name (TEAMID)'
export IRODAKE_PROVISIONING_PROFILE='/absolute/path/to/Irodake_AppStore.provisionprofile'
./build.sh --store
```

Certificate display names vary by Apple account generation. Use the exact identities returned by:

```bash
security find-identity -v -p codesigning
```

`dist/Irodake-X.Y.Z-AppStore.pkg` is created for App Store Connect upload. Validate bundle ID, application identifier entitlement, team identifier, provisioning profile, version/build, and receipt behavior before upload. Use Apple's current Transporter / Xcode upload path; do not notarize or staple the Store package as a direct-download artifact.

Before the first production upload, reproduce this manual SwiftPM packaging route in a dedicated App Store CI environment or create a reviewed Xcode app target. Submit a beta through TestFlight and verify Screen Recording consent, Sandbox behavior, launch-at-login registration, receipt, update, and uninstall behavior.

## Review notes template

```text
Irodake uses ScreenCaptureKit to process each display on this Mac in real time.
It renders a grayscale click-through overlay and masks the regions selected by the user.
It does not save screen images or audio to files, capture audio, or transmit content off-device.
There is no account, analytics SDK, advertising SDK, or network entitlement.

Test:
1. Launch the app and continue through onboarding.
2. Allow Screen & System Audio Recording when prompted.
3. Choose “Keep Color”, select a fixed rectangle, and turn Irodake on.
4. Use the menu bar item or Option-Command-G to stop immediately.
5. Hold Option-Command-C to temporarily reveal all original colors.

Known platform behavior: DRM/capture-protected content may appear black or unavailable.
A “window area” follows the window bounding rectangle; overlapping windows in that rectangle receive the same effect.
```

Update it to exactly match the submitted build.

## Secrets

Never store certificates, provisioning profiles, app-specific passwords, notary credentials, seller data, API keys, or future updater keys in Git, build logs, or public artifacts. Use a dedicated release keychain or secret manager, least privilege, two-person approval, and an offline recovery backup.
