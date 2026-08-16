# Xcode Cloud Release Runbook

Irodake's Mac App Store binary is built only by Xcode Cloud. Swift Package Manager and unsigned Xcode builds remain available for development; local signing, packaging, notarization, and App Store upload are not release steps.

## Release identity

- Xcode project: `Irodake.xcodeproj`
- Shared scheme: `Irodake`
- Platform: macOS 14 or later
- App bundle ID: `com.hinoshiba.irodake`
- Test bundle ID: `com.hinoshiba.irodake.tests`
- Apple Developer Team: `94HVVWXLK3`
- Version source: `MARKETING_VERSION` in `project.yml`
- Release tag: `vX.Y.Z` (for example, `v0.1.3`)

`project.yml` is the project-configuration source of truth. The generated project and shared scheme are intentionally committed because Xcode Cloud requires a continuously present project or workspace. Run `xcodegen generate` after changing `project.yml` and commit both; pull-request CI rejects a stale project.

## One-time Xcode Cloud setup

Complete initial onboarding in Xcode after this change is merged to `main`:

1. Check out `main`, open `Irodake.xcodeproj`, select the `Irodake` scheme, and use Product > Xcode Cloud > Create Workflow (or the Cloud section of the Report navigator).
2. Select Team `94HVVWXLK3` and confirm the existing App Store Connect record whose bundle ID is exactly `com.hinoshiba.irodake`. Do not create a second app record or change the bundle ID.
3. Grant Xcode Cloud access to `hinoshiba/Irodake` through GitHub's authorization flow. Grant only the repository access needed for this product.
4. Keep **Automatically manage signing** enabled for the app target. Xcode Cloud uses Apple's managed signing service; do not add certificates, private keys, provisioning profiles, or App Store Connect keys to GitHub.
5. Start the initial validation build from `main`. The non-archive build establishes the Xcode Cloud product without invoking the release-only checks.

After the first build, create or edit the release workflow in Xcode or App Store Connect:

| Section | Setting |
| --- | --- |
| General | Name: `App Store Release`; enable **Restrict Editing** |
| Start Conditions | **Tag Changes**; custom tag pattern `v*`; remove branch-change conditions; set **Auto-cancel Builds** to **Off** in this condition's Options |
| Environment | Latest stable Xcode and macOS supported by the project; **Clean** enabled |
| Action 1 | **Test**, scheme `Irodake`, macOS destination |
| Action 2 | **Archive**, platform **macOS**, scheme `Irodake`, Deployment Preparation **TestFlight and App Store** |
| Post-Actions | None required to upload the archive. Add a TestFlight post-action only when a specific tester group should receive every tagged build. |

The pre-Xcodebuild script rejects an Archive unless its platform, scheme, bundle ID, and Team match Irodake, `CI_TAG` is exactly `vX.Y.Z`, the tag version matches both `project.yml` and the checked-in project, and `CI_BUILD_NUMBER` is a positive integer. It applies that Cloud number as `CURRENT_PROJECT_VERSION`. The post-Xcodebuild script then verifies the archived bundle ID, version/build, signature, App Sandbox entitlement, universal architectures, privacy/compliance resources, and dependency boundary before any distribution post-action.

macOS build numbers must increase across marketing versions. In App Store Connect, open Irodake > Xcode Cloud > Settings > Build Number and set **Next Build Number** at or above `CURRENT_PROJECT_VERSION` in `project.yml`, and above the highest build uploaded across all Irodake marketing versions.

## Protect release authority

Before enabling the release workflow, create an **Active** tag ruleset in
GitHub **Settings > Rules > Rulesets** for the `v*` target pattern. Enable
**Restrict creations**, **Restrict updates**, and **Restrict deletions**, and
allow bypass only for the designated release manager. Create a release tag only
on a reviewed `main` commit. Never move, replace, or reuse it. Keep Xcode Cloud
**Restrict Editing** enabled and limit workflow administration to the same
small release group.

## Prepare and tag a release

1. Update the marketing version (the helper also increments the repository fallback build and regenerates the project):

   ```sh
   ./Scripts/bump-version.sh 0.1.3
   ```

2. Update `app-store/app.json`, the evidence version in
   `app-store/app-privacy.md`, and both localized
   `app-store/versions/<version>/*/whats_new.txt` files. The store-assets audit
   rejects any mismatch with `project.yml`.
3. Run the repository checks:

   ```sh
   swift build
   swift test
   xcodebuild -project Irodake.xcodeproj -scheme Irodake -destination 'platform=macOS' test CODE_SIGNING_ALLOWED=NO
   ./Scripts/audit-source.sh
   ./Scripts/audit-brand.sh
   ./Scripts/audit-store-assets.sh
   ```

4. Complete the applicable checks in [TEST_MATRIX.md](TEST_MATRIX.md) on Intel and Apple silicon where available, including Screen Recording permission states, multiple displays, Spaces, sleep/wake, Japanese/English, VoiceOver, Reduce Motion, and failure recovery.
5. Merge the version and metadata changes through a reviewed pull request. Wait for GitHub CI on the merge commit to pass.
6. Create the release tag on that exact `main` commit and push it:

   ```sh
   git tag -a v0.1.3 -m "Irodake 0.1.3"
   git push origin v0.1.3
   ```

Never move or replace a release tag. Correct a failed or superseded release with a new version tag.

## Verify the cloud release

1. In App Store Connect > Irodake > Xcode Cloud, confirm `App Store Release` was started by the expected tag and commit.
2. Require successful Test and Archive actions and the final archive-audit message. Confirm Team `94HVVWXLK3`, bundle ID `com.hinoshiba.irodake`, the tag's marketing version, and the Xcode Cloud build number.
3. Wait for App Store Connect processing. Confirm the exact version/build appears in TestFlight and is eligible for Mac App Store submission.
4. Recheck App Privacy, permission copy, screenshots, release notes, and the metadata in `app-store/` against the uploaded binary.
5. Selecting the build for an App Store version and submitting it to App Review remain explicit App Store Connect actions. A release tag uploads a candidate; it does not submit or release the app automatically.

Follow [the code-signing policy](CODE_SIGNING.md). Keep signed artifacts in Xcode Cloud/App Store Connect rather than the checkout or ordinary GitHub Actions artifacts.
