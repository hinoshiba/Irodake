# Repository rules

## Apple distribution signing

- For Mac App Store releases under Apple Developer Team `94HVVWXLK3`, use the existing team-wide Mac App Store distribution private key. Do not create an app-specific distribution private key.
- Issue both the `Mac App Distribution` and `Mac Installer Distribution` certificates from that same team-wide private key. Reuse that key for other hinoshiba Mac App Store repositories on the same team.
- Keep the Explicit App ID and provisioning profile app-specific. Irodake uses `com.hinoshiba.irodake`.
- Before issuing or renewing a certificate, verify that the team-wide private key is present in the login keychain. If it is unavailable, stop and ask the repository owner instead of silently generating a replacement.
- Never commit private keys, `.p12` files, certificate signing requests, certificates, provisioning profiles, passwords, API keys, or App Store Connect credentials. Store the shared private-key backup only in the owner's approved encrypted secret storage.

