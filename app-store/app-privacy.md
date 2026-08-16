# App privacy answers

Select **No, we do not collect data from this app** in App Store Connect.

Evidence for version 0.1.3:

- Screen frames are processed in memory with ScreenCaptureKit, Core Image, and Metal.
- Screen images, video, audio, window titles, and tracked-window identifiers are not transmitted.
- The app has no networking code, analytics, advertising, crash-upload, account, or payment SDK.
- Fixed regions and preferences are stored locally in `UserDefaults`.
- Window titles and window identifiers are not persisted; tracked-window rules are discarded when the app quits.

Privacy Policy URLs:

- Japanese: `https://irodake.hinoshiba.com/#privacy`
- English: `https://irodake.hinoshiba.com/en/#privacy`

Re-evaluate these answers before any release that adds networking, telemetry, external updates, accounts, cloud sync, or third-party SDKs.
