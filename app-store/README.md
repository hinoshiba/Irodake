# App Store submission resources

This directory is the public, non-secret source of truth for Irodake's Mac App Store product page.

- Primary language: Japanese (`ja`)
- Additional localization: English (U.S.) (`en-US`)
- Bundle identifier / Explicit App ID: `com.hinoshiba.irodake`
- Screenshot size: 1440 × 900 px, opaque PNG, identical order in both locales
- Public URLs: the GitHub Pages site built from `http_dist/`

Copy each text file into the matching App Store Connect field. Register the exact Explicit App ID above and generate the Mac App Store provisioning profile for it before building. Never commit App Store Connect credentials, certificates, provisioning profiles, reviewer phone numbers, private legal addresses, or unreleased commercial terms here.

Run `./Scripts/audit-store-assets.sh` before submission. Screenshots are generated from actual Irodake UI captures by `swift Scripts/MakeStoreScreenshots.swift` and must not be retouched to show behavior the submitted build does not produce. Raw captures live in the gitignored `screenshots/source/<locale>/` workspace; only the reviewed, opaque App Store exports are committed.

The first release does not use a custom EULA, in-app purchases, subscriptions, accounts, analytics, advertising, or third-party content. App privacy is declared as **Data Not Collected**.

App Store Connect still requires account-only information that must not be committed: the reviewer's name and phone number, the legal seller name, agreements, tax and banking data, price, and territories. Start with `review-contact.template.json`, enter those values directly in App Store Connect, and keep credentials and personal data outside this repository.
