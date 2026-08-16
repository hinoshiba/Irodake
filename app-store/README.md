# App Store submission resources

This directory is the public, non-secret source of truth for Irodake's Mac App Store product page.

- Primary language: Japanese (`ja`)
- Additional localization: English (U.S.) (`en-US`)
- Bundle identifier / Explicit App ID: `com.hinoshiba.irodake`
- Screenshot size: 1440 x 900 px, opaque PNG, identical order in both locales
- Public URLs: the GitHub Pages site built from `http_dist/`

Copy each text file into the matching App Store Connect field. Never commit App Store Connect credentials, certificates, provisioning profiles, reviewer phone numbers, private legal addresses, or unreleased commercial terms here.

## Xcode Cloud distribution

Mac App Store archives are built and uploaded only by Xcode Cloud using automatic signing for Apple Developer Team `94HVVWXLK3`. The Xcode Cloud product must resolve the existing App Store Connect record and Explicit App ID `com.hinoshiba.irodake`; do not create a replacement record or an app-specific distribution key.

The release workflow starts from a `vX.Y.Z` tag on `main`, runs tests, archives the shared `Irodake` scheme for macOS with **TestFlight and App Store** deployment preparation, and uploads the result to App Store Connect. See [the release runbook](../docs/RELEASE.md) and [code-signing policy](../docs/CODE_SIGNING.md). Local Mac App Store packages, Developer ID disk images, and local credential environment variables are no longer part of the release process.

Run `./Scripts/audit-store-assets.sh` before submission. Screenshots are generated from actual Irodake UI captures by `swift Scripts/MakeStoreScreenshots.swift` and must not be retouched to show behavior the submitted build does not produce. Raw captures live in the gitignored `screenshots/source/<locale>/` workspace; only reviewed, opaque App Store exports are committed.

The first release does not use a custom EULA, in-app purchases, subscriptions, accounts, analytics, advertising, or third-party content. App privacy is declared as **Data Not Collected**.

App Store Connect still requires account-only information that must not be committed: the reviewer's name and phone number, legal seller name, agreements, tax and banking data, price, and territories. Start with `review-contact.template.json`, enter those values directly in App Store Connect, and keep credentials and personal data outside this repository.
