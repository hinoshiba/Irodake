# Brand and Name Audit

Audit snapshot: 2026-08-15 JST

Selected launch brand: **Irodake** / **イロダケ**

Pronunciation: **ee-roh-dah-keh**
Tagline: **色は、必要な場所だけ。 / Color only where it matters.**

This document records an engineering and public-record screening, not legal advice or a guarantee that a mark can be registered or used in every jurisdiction. Search indexes, private App Store Connect reservations, pending applications, common-law rights, domains, and social handles can change after the audit time.

## Decision

Use `Irodake` as the product, executable, Swift module, repository target, and App Store display name. Use `com.hinoshiba.irodake` as the explicit bundle ID before the first App Store build upload.

The name is short, visually distinctive, and directly supports the product promise: the Japanese phrase `色だけ` means “only color.” The existing dark icon with a narrow color strip reads naturally as “color only where it matters.” The localized subtitle carries the generic search terms so the brand itself stays uncluttered.

## Public-record checks

| Surface | Query and snapshot result |
|---|---|
| Apple Search API, Japan / US / UK | `Irodake` exact Mac app title: 0 in each checked storefront. Fuzzy US/UK results were unrelated. This cannot see private App Store Connect reservations. |
| GitHub repository search | `Irodake in:name`: 0 repositories. |
| General web exact-name search | No prominent software, company, or consumer brand using exact `Irodake` was found. Results were principally geographic/transliteration references. |
| J-PlatPat exact mark | `IRODAKE` / `イロダケ`: 0 application or registration records. |
| J-PlatPat phonetic similarity | `イロダケ`: 6 results. Active `IRUDAKE` / `イルダケ` registrations 6778472 and 6778473 are in class 35; the returned set contained no class 9 or 42 result. This remains a professional-review item. |
| USPTO word mark | `IRODAKE`: 0 live or dead exact-word results in the checked public search. |
| WIPO / EUIPO indexed exact search | No exact indexed result found. WIPO's official result could not be completed because its interactive verification blocked the session, and the full EUIPO official search was not completed; neither is recorded as an official zero-result search. |
| Domains | `irodake.com`, `irodake.app`, and `irodake.dev` returned RDAP 404; `irodake.jp` returned JPRS `No match`. This is an availability snapshot, not a reservation. |

Useful reproducible entry points:

- [Apple Search API — Japan](https://itunes.apple.com/search?term=Irodake&entity=macSoftware&country=jp&limit=200)
- [Apple Search API — United States](https://itunes.apple.com/search?term=Irodake&entity=macSoftware&country=us&limit=200)
- [GitHub repository search](https://github.com/search?q=Irodake%20in%3Aname&type=repositories)
- [J-PlatPat trademark search](https://www.j-platpat.inpit.go.jp/)
- [JPO trademark-search guide](https://www.jpo.go.jp/e/support/j_platpat/trademark_search.html)
- [USPTO trademark search](https://tmsearch.uspto.gov/search/search)
- [WIPO Global Brand Database](https://www.wipo.int/en/web/global-brand-database/index)
- [EUIPO search](https://www.euipo.europa.eu/en/search)
- [Verisign RDAP — irodake.com](https://rdap.verisign.com/com/v1/domain/IRODAKE.COM)
- [Google Registry RDAP — irodake.app](https://pubapi.registry.google/rdap/domain/irodake.app)
- [Google Registry RDAP — irodake.dev](https://pubapi.registry.google/rdap/domain/irodake.dev)

## Rejected names and collision reasons

| Candidate | Decision | Primary reason |
|---|---|---|
| Sukima | Reject | Existing [Mac-compatible App Store product](https://apps.apple.com/us/app/sukima-brain-dump-plan/id6763095735), [Steam title](https://store.steampowered.com/app/4238190/SUKIMA_The_Creeping_Gap/), and other services make search ownership and confusion poor. |
| ChromaPeek | Reject | Existing color-related software names, including [Chroma-Peek](https://github.com/Pawandeep-prog/chroma-peek), plus a product-name use. |
| ChromaHush | Reject | Exact public conflicts were low, but J-PlatPat phonetic similarity returned many active `CHROME HEARTS` / `クロムハーツ` registrations, including class 9. |
| Irodake | Select with legal gate | Exact-name surface is clear in this snapshot. The class-35 `IRUDAKE` / `イルダケ` phonetic similarity and the somewhat suggestive Japanese meaning require counsel review. |

Other screened names were rejected earlier for exact, close, or category-adjacent use: `QuietHue`, `HushHue`, `HueKeep`, `ChromaCove`, `Chromask`, `MonoSpot`, `Chromado`, `LumaSift`, `HushPixel`, `HueHush`, `ChromaFold`, `ChromaNook`, `IroSpot`, `Chromallow`, and `GrayLume`.

The strongest non-selected fallbacks were `QuietChroma`, `ChromaNagi`, `IroLocus`, `IroVeil`, `NagiHue`, `NagiChroma`, `HueLocus`, and `MonoNagi`. They did not improve the total balance of semantic fit, search ownership, pronunciation, and phonetic-mark risk enough to displace `Irodake`.

## Canonical identity map

| Purpose | Canonical value |
|---|---|
| Product and display name | `Irodake` |
| Japanese reading | `イロダケ` |
| App Store subtitle, ja | `部分カラー・画面グレースケール` |
| App Store subtitle, en | `Selective Screen Grayscale` |
| Bundle ID | `com.hinoshiba.irodake` |
| Swift package / executable / module | `Irodake` |
| Test module | `IrodakeTests` |
| UserDefaults key | `irodake.settings.v1` |
| Carbon hot-key signature | `IRDK` / `0x4952444B` |
| Build environment prefix | `IRODAKE_` |
| Intended GitHub repository | `hinoshiba/Irodake` |
| Intended primary domains | `irodake.com`, `irodake.app`, `irodake.jp` |

## Mandatory external actions before publication

1. Have trademark counsel search and assess exact and similar marks in every launch jurisdiction, at minimum classes 9 and 42 and the class-35 `IRUDAKE` / `イルダケ` records.
2. Reserve `Irodake` in App Store Connect and register the explicit App ID `com.hinoshiba.irodake` before uploading the first build. Apple states that a bundle ID cannot be changed after the first build upload.
3. Rename the GitHub repository to `hinoshiba/Irodake`; verify redirects, branch protection, release automation, SBOM URLs, badges, and the in-app About links.
4. Register the domains and desired social handles before public announcement, or deliberately document that they will not be used.
5. Keep health copy observational and user-controlled. Do not claim treatment, diagnosis, eye protection, sleep improvement, or guaranteed health outcomes.

For the present downloadable macOS app, Nice class 9 is the primary filing candidate. Class 42 becomes relevant if the business offers SaaS, hosted software, cloud synchronization, or software services. Do not add medical classes merely because users may choose grayscale for personal wellbeing.

Do not use `®` unless and until the relevant registration exists.

Apple recommends a simple, memorable, distinctive name and limits app names and subtitles to 30 characters. The proposed name and both subtitles fit that limit. Apple also states that the bundle ID cannot be changed after the first build upload, which is why the explicit ID must be reserved and verified first: [product-page guidance](https://developer.apple.com/app-store/product-page/), [App Store Connect app information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/).

## Development-build transition

This complete rename intentionally changes the bundle ID and UserDefaults key before any public release. A tester who ran a pre-brand development build should expect settings to reset, Screen Recording permission to be requested for the new identity, and any previous launch-at-login registration to be removed manually. No migration code is added because no public or Store build exists yet; preserving the new first-release identity is safer than shipping a permanent legacy identifier.
