# Code-Signing and Secret-Handling Policy

This public repository contains only non-secret signing metadata.

## Public application identity

- Apple Developer Team ID: `94HVVWXLK3`
- App bundle identifier: `com.hinoshiba.irodake`
- Unit-test bundle identifier: `com.hinoshiba.irodake.tests`
- Signing mode: automatic
- Distribution channel: Mac App Store through Xcode Cloud

Routine local and GitHub CI builds use `CODE_SIGNING_ALLOWED=NO` or Swift Package Manager and have no release credentials. App Store archives run only in the restricted `App Store Release` Xcode Cloud workflow described in [RELEASE.md](RELEASE.md).

The initial setup owner must confirm that Xcode Cloud resolves the existing Irodake App Store Connect record, Explicit App ID, Team `94HVVWXLK3`, and Apple's managed Mac App Store signing path. Verify the same app, team, bundle ID, version, and build in every Xcode Cloud archive and App Store Connect delivery record. Do not create, revoke, rotate, import, or export a team signing identity as a speculative fix.

`Developer ID Application` and Developer ID notarization are for distribution outside the Mac App Store and are no longer part of this repository's release workflow. Do not configure Developer ID signing, installer identities, local provisioning-profile selectors, or credential environment variables here.

## Repository boundary

Never place any of the following in this repository, Git history, an issue, a pull request, a log, a cache, or an ordinary CI artifact:

- private keys or exported identities, including `.p12`, `.pfx`, `.pkcs12`, `.p8`, `.pem`, and `.key` files;
- certificates, certificate requests, provisioning profiles, or Keychain databases;
- App Store Connect keys, authentication files, `.env` files, passwords, tokens, or credential JSON;
- private certificate fingerprints, identity listings, or managed-signer aliases; or
- signed `.app`, `.pkg`, `.dmg`, or `.xcarchive` output.

Xcode Cloud automatic signing does not require checked-in export options or GitHub secrets. Signed release output remains in Xcode Cloud and App Store Connect. Download an artifact only into an approved temporary location when investigation or archival is required; never commit it or attach it to routine CI.

If signing or credential material is disclosed, do not display or resend it. Report only its material type, path, and affected commit or job to the repository owner, revoke or rotate it as appropriate, remove it from reachable history and caches, and restore cloud signing only after the exact app, team, repository access, and replacement credential state are verified.
