# License and Distribution Audit

Audit date: 2026-08-15 JST

This is an engineering compliance record, not legal advice.

## Current conclusion

Irodake can be released as MIT-licensed open source while official signed binaries are sold commercially.

Current runtime dependencies:

| Component | Type | Distributed by Irodake | Terms / action |
|---|---|---:|---|
| Irodake source and generated icon | first-party | Yes | MIT `LICENSE` |
| Swift standard runtime | OS-provided | No | Apple system component |
| AppKit, SwiftUI, ScreenCaptureKit, CoreImage, Metal, QuartzCore, Carbon, ServiceManagement | OS frameworks | No | Dynamically linked; do not copy into bundle |
| Third-party package / framework / SDK | none | No | Re-audit on any dependency PR |

`Package.swift` has no dependency declarations. `dist/Irodake.app/Contents` has no `Frameworks` directory. `THIRD_PARTY_LICENSES.txt`, `LICENSE.txt`, `TRADEMARKS.txt`, and `PrivacyInfo.xcprivacy` are bundled as release resources.

## MIT and commercial sales

MIT permits use, copy, modification, publication, distribution, sublicensing, and sale, provided the copyright and permission notice remain in substantial copies. Official paid binaries are therefore allowed.

MIT also allows other people to redistribute and sell forks. It is not a business exclusivity license. Official value should come from signing, notarization, Store delivery, updates, support, QA, and a legally cleared brand.

## Apple code

Apple frameworks and SDKs are proprietary system/development components, not MIT dependencies. Irodake links system frameworks and does not redistribute them. Keep framework binaries out of the repository and app bundle.

SF Symbols may be used as interface symbols under Apple platform terms. Do not export them as the app icon, standalone asset pack, or non-Apple-platform branding. Irodake's app icon is generated from first-party AppKit drawing code.

## Reference project

Operational concepts were reviewed from `hinoshiba/youyaku`, MIT, commit `26142892b3387b58f2a8bd76c3145da3d8d6031d`:

- versioned universal builds
- code signing, notarization, staple, verification
- bundled third-party notices
- privacy and release documentation
- immutable release ordering

No Youyaku source file, binary, model, framework, or visual asset is included in Irodake.

Do not copy Youyaku's pinned Sparkle 2.9.4. It is affected by [GHSA-gmj2-gq3j-vqmj](https://github.com/sparkle-project/Sparkle/security/advisories/GHSA-gmj2-gq3j-vqmj). Irodake currently has no updater and the Mac App Store build must use Store updates only. If a direct build later adds Sparkle, audit the then-current advisory, source, transitive notices, sandbox configuration, and exact checksum from scratch.

## Privacy / export

- `PrivacyInfo.xcprivacy`: tracking false, collected data empty, accessed API types empty.
- Apple currently does not list macOS among platforms requiring Required Reason API declarations. Re-check before every release.
- `ITSAppUsesNonExemptEncryption = false` matches the current no-network/no-custom-cryptography implementation. Reassess if updating, licensing, or networking is added.

## Name and trademark blocker

`Irodake` is the selected launch brand after the dated public-record screening in [BRAND_AUDIT.md](BRAND_AUDIT.md). No exact app, repository, or word-mark conflict was found in the sources checked. J-PlatPat phonetic-similarity results do include active `IRUDAKE` / `イルダケ` marks in class 35, so the engineering screen is not legal clearance.

Before an App Store record, paid binary, domain, press kit, or trademark policy is published:

1. obtain professional similarity clearance for `Irodake`, `IRODAKE`, `イロダケ`, and relevant Japanese spellings in launch jurisdictions, including classes 9 and 42 and adjacent class 35 services;
2. reserve the App Store Connect name and explicit bundle ID `com.hinoshiba.irodake`;
3. reserve the canonical GitHub repository, domains, and social handles;
4. record the final legal review and reservation evidence in the release checklist.

Do not claim `®` without registration.

## Release audit commands

```bash
swift package show-dependencies --format json
swift build -c release
swift test
./build.sh
./Scripts/audit-release.sh dist/Irodake.app
```

Re-run the audit from a clean, reviewed, signed tag. The current record does not approve an uncommitted or later worktree.
