# Dependency Policy

Runtime dependency zero is a product, privacy, App Store, supply-chain, and license requirement. Prefer Apple public system APIs and first-party code.

Every new dependency PR must document:

- package name, exact version, upstream repository and commit/checksum;
- declared license and actual `LICENSE` / `NOTICE` files;
- runtime, build-only, or test-only use;
- whether source or binary is bundled;
- attribution, source-offer, relinking, patent, and trademark conditions;
- network behavior, data collection, permissions, Required Reason APIs;
- current advisories, maintenance activity, and update owner;
- Mac App Store and Sandbox compatibility;
- why a small first-party implementation or system framework is insufficient.

Default review posture:

- normally acceptable after review: MIT, BSD-2-Clause, BSD-3-Clause, ISC, Zlib, Apache-2.0, CC0;
- legal/product review: MPL-2.0, LGPL, OFL-1.1, CC-BY, custom licenses;
- do not merge without explicit legal approval: GPL, AGPL, SSPL, BUSL, Commons Clause, NC, ND, source-available, unknown, or no license.

If any dependency is added:

1. commit `Package.resolved`;
2. pin downloadable binary assets by version and SHA-256;
3. add complete notices to `THIRD_PARTY_LICENSES.txt`;
4. update Privacy Manifest and App Store disclosures as needed;
5. add license/advisory checks to CI;
6. regenerate the release SBOM.
