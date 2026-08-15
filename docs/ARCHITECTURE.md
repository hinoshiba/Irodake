# Architecture

## Design constraints

Irodake は次を不変条件とします。

1. Apple の公開 API のみを使う。
2. App Sandbox を維持する。
3. 画面フレームを保存・送信しない。
4. OFF、sleep、logout、capture error では overlay を最初に消す（fail open）。
5. 基本機能で Screen Recording 以外の権限を求めない。

macOS には最終 framebuffer の一部だけへ grayscale filter を適用する公開 API がありません。システムの Accessibility color filter は全画面のみで、領域例外を作れません。gamma table は RGB channel 間の輝度変換ができず、private `CGS*` / SkyLight API は App Store へ提出できません。

そのため ScreenCaptureKit + GPU overlay が唯一の現実的な公開 API 構成です。

## Runtime pipeline

```text
AppModel (@MainActor)
 ├── user settings / menu bar / hotkeys
 ├── RegionSelectionController
 └── CaptureManager (@MainActor)
      └── per NSScreen
           ├── OverlayWindow (click-through)
           │    └── MetalFrameView / CAMetalLayer
           └── DisplayCaptureSession
                └── SCStream / SCStreamOutput
```

### Capture

- 1つの `SCDisplay` につき1つの `SCStream`。
- output は BGRA / SDR、音声なし、cursor なし。
- `queueDepth = 2`、既定 30 fps。
- `.complete` / `.started` の frame を処理し、`.blank` / `.suspended` / `.stopped` では古い overlay を即時非表示にする。
- `SCContentFilter` で効果用 overlay window だけを除外し、feedback loop を防止する。通常の Irodake 設定画面はキャプチャ対象に含める。
- overlay は content query より先に作り、self application が取得できない場合も window 単位で除外できるようにする。

### Rendering

`CVPixelBuffer` から `CIImage` を作り、`CIColorControls(inputSaturation: 0)` を Metal-backed `CIContext` で `CAMetalDrawable.texture` へ直接 render します。CPU の `CGImage` 生成は行いません。

1 frame の render が pending の間は未処理 buffer を最新 frame で置換し、GPU 完了後に最新だけを描画します。非制限 queue に古い frame を溜めません。

### Mask semantics

- `colorFocus`: grayscale overlay 全体を表示し、選択矩形の重複しない union を even-odd mask の穴にする。
- `grayFocus`: 選択矩形の union だけ grayscale overlay を表示する。
- color peek: 空の `grayFocus` mask を一時適用して overlay を透明にする。

選択ウインドウそのものを別 stream で前面へ合成すると、本来隠れている内容まで見えるため行いません。「ウインドウ領域」は bounding rectangle semantics です。

### Window levels

- effect overlay: `mainMenu - 1`。通常アプリより上、macOS の menu / popover より下。
- Irodake main window: 非アクティブ時は通常 level、key window の間だけ `mainMenu + 1`。overlay に隠れず、通常アプリとしての重なり順も維持する。
- region selection panel: `screenSaver`。選択中だけ入力可能。

`.screenSaver` を通常 effect overlay には使いません。通知、Control Center、menu まで覆う危険があるためです。

### Coordinate systems

ScreenCaptureKit / Quartz の global rect は primary display 左上原点、AppKit は primary display 左下原点です。`DesktopGeometry.appKitRect(fromQuartz:)` で primary screen height を基準に変換し、screen frame と intersect 後に overlay local rect へ offset します。

負座標、上下配置、回転、mixed scale は実機 test matrix の必須項目です。

## Permissions and sandbox

- `com.apple.security.app-sandbox = true`
- Screen Recording は TCC で user consent を取得
- Accessibility / Input Monitoring / Apple Events / network entitlement なし
- `com.apple.developer.persistent-content-capture` は申請しない
- private screen capture entitlement は追加しない

グローバルショートカットは Carbon `RegisterEventHotKey` の pressed / released event を使い、keyboard event tap を作りません。

## Lifecycle and failure safety

- app launch 時は必ず OFF。前回 ON を自動再開しない。
- OFF は overlay を同期的に `orderOut` / `close` してから `SCStream.stopCapture()` を待つ。
- overlay は最初の有効 frame まで表示せず、開始途中の window も停止対象として追跡する。停止後の遅延 callback は presentation gate で再表示を拒否する。
- stream error は UI state を OFF にし、capture manager を停止。
- sleep、screen sleep、session resign active は一時停止し、同じ app session 内で直前に ON だった場合だけ wake / session復帰後に再開する。
- `grayFocus` の有効スポットが0件になった場合は、無効果の capture を続けず OFF にする。
- display configuration change は通知を debounce し、全 display を原子的に検証してから pipeline を再構築。

## Data model

固定矩形、mode、frame rate、language、launch at login は `UserDefaults` の JSON へ保存します。

ウインドウ title と `CGWindowID` は永続化しません。Window ID は session を超えて再利用されるため、誤ったウインドウを追跡する危険があり、title は機密情報を含む可能性があります。追跡ウインドウは現在の app process 内だけで保持し、PIDと所有アプリ名の一致も継続確認します。

## Known technical limits

- protected / DRM content cannot be reliably processed.
- 1–2 frame latency cannot be eliminated with this architecture.
- HDR requires a distinct capture/render/color-space path.
- a transparent hole affects every visible pixel in that rectangle, not only the selected owner window.
- ScreenCaptureKit use is visible in macOS system privacy UI and must not be hidden.

## Future work

- normalized display-UUID-based fixed region persistence
- HDR local-display preset and 16-bit float render path
- Instruments-based energy benchmark and adaptive frame rate
- stale-frame watchdog
- event-driven AX follow-focus as an explicitly optional permission tier
- `SCContentSharingPicker` evaluation for window selection
