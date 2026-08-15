# Commercial Release Gates

An unchecked P0 means **do not publish or sell**.

## P0 — legal and business

- [ ] `Irodake` / `イロダケ`, logo, domain, and social handles have professional trademark/name clearance in launch jurisdictions; J-PlatPat class-35 `IRUDAKE` / `イルダケ` similarity is reviewed in writing.
- [ ] App Store Connect name and explicit bundle ID `com.hinoshiba.irodake` are reserved before the first build upload.
- [ ] The GitHub repository is renamed to `hinoshiba/Irodake`, canonical links resolve, and `irodake.com` / `irodake.app` / `irodake.jp` ownership is decided and reserved as needed.
- [ ] Legal seller identity, support email, Privacy Policy URL, Terms, refund policy, and required commercial disclosure are public.
- [ ] Paid Apps Agreement, tax, and banking are complete for Store sales.
- [ ] Japanese direct sales include legally reviewed Specified Commercial Transactions Act disclosure; other sales regions are reviewed.
- [ ] Health copy avoids diagnosis, treatment, guaranteed benefit, and unsupported medical claims.
- [ ] Contributor DCO/CLA strategy is approved before external contributions are accepted.

## P0 — privacy and App Review

- [ ] Screen Recording purpose string is localized and matches actual behavior.
- [ ] First capture requires explicit user action; launch never silently resumes capture.
- [ ] ON is continuously visible and OFF is reachable from menu bar and `⌥⌘G`.
- [ ] OFF/error/revocation/sleep/logout removes overlays before waiting for stream shutdown.
- [ ] Audio remains disabled; no screen image, title, or content leaves the Mac.
- [ ] App Privacy answers and Privacy Manifest match the release binary.
- [ ] Privacy Policy is linked inside the app and in App Store Connect.
- [ ] Review notes and a reviewer video explain full-display capture, local masks, window-rectangle semantics, and DRM limits.

## P0 — product quality

- [ ] The full [TEST_MATRIX.md](TEST_MATRIX.md) passes on the release candidate.
- [ ] Orientation and color output are visually verified on Intel and Apple Silicon.
- [ ] 8-hour memory / IOSurface leak test passes.
- [ ] Input-to-display p95 latency and Energy Impact meet the written launch target.
- [ ] Single and multiple 4K/5K displays remain usable at the default 30 fps.
- [ ] No state exists where UI says OFF while an overlay remains visible.
- [ ] No effect mode starts a capture stream when there is no visible target.
- [ ] Screen Recording denial, later grant, later revoke, and process restart all recover cleanly.

## P0 — distribution integrity

- [ ] Release comes from a protected, reviewed, immutable tag and clean checkout.
- [ ] `swift build`, `swift test`, `./build.sh`, and `audit-release.sh` pass.
- [ ] `otool -L` and bundle scan match the audited Apple-only dependency set.
- [ ] Runtime dependencies, license notices, Privacy Manifest, and entitlements are re-audited.
- [ ] Developer ID DMG passes signing, notarization, staple, Gatekeeper, and clean-Mac install checks; or Store PKG passes TestFlight and Store validation.
- [ ] SHA-256 / SHA-512, SPDX SBOM, toolchain record, source tag, changelog, and provenance are published together.
- [ ] Published release assets cannot be overwritten.

## P1 — launch quality

- [ ] Japanese and English are reviewed by native speakers.
- [ ] VoiceOver, Voice Control, keyboard-only, Increase Contrast, Reduce Motion, and large text are tested.
- [ ] 30–50 beta users cover design, development, study, multiple-display, Intel, and lower-end Apple Silicon workflows.
- [ ] At least two weeks of daily beta use is complete.
- [ ] App Store screenshots and preview use only first-party demo content and correctly show actual behavior.
- [ ] Support, issue triage, vulnerability response, rollback, and emergency release ownership are staffed.
