# Irodake Privacy Policy / プライバシーポリシー

Last updated / 最終更新: 2026-08-15

## 日本語

Irodake は、選択した領域の表示色を切り替えるため、画面をこの Mac 上でリアルタイム処理します。

### 取得・保存・送信しないもの

- 画面画像や映像をファイルへ保存しません。
- 画面画像、ウインドウ内容、音声を Mac の外へ送信しません。
- 音声を取得しません。
- アカウント、広告、分析、テレメトリ、クラッシュ自動送信を使いません。
- ネットワーク通信を行いません。

### Mac 内に保存する設定

次の設定を macOS の UserDefaults に保存します。

- 表示モード、固定矩形の位置・大きさ、フレームレート
- 表示言語、オンボーディング完了状態、ログイン時起動の選択

ウインドウ追跡で表示するタイトルは選択 UI の実行中だけ利用し、永続化しません。`CGWindowID` とウインドウ追跡ルールもアプリ終了時に破棄します。

設定はアプリを削除するか、macOS の app container / preferences から削除できます。将来アプリ内の「設定をリセット」を提供する予定です。

### 画面収録の許可

macOS の「システム設定 → プライバシーとセキュリティ → 画面とシステムオーディオの収録」で、いつでも許可を取り消せます。Irodake を OFF にすると capture stream を停止します。sleep、画面消灯、ユーザー切替では安全のため一時停止し、同じ起動セッション内で直前にONだった場合だけ復帰後に再開します。権限取消やcapture error時はOFFにします。

### 第三者

Irodake は第三者 SDK を含みません。Apple の macOS system frameworks だけを動的に利用します。Screen Recording の同意と表示は macOS が管理します。

### 変更

将来、通信、分析、クラッシュ送信、ライセンス認証などを追加する場合は、実装前にこの方針、Privacy Manifest、App Store disclosure を更新し、必要な同意を求めます。

### お問い合わせ

公開前に正式な support email と事業者情報を設定します。現時点の技術的な問い合わせ・脆弱性報告は GitHub repository の Issue または Private vulnerability reporting を利用してください。

## English

Irodake processes the display on this Mac in real time to change color in regions you choose.

### What Irodake does not collect, save, or transmit

- It does not save screen images or video to files.
- It does not transmit screen images, window contents, or audio off this Mac.
- It does not capture audio.
- It has no account, advertising, analytics, telemetry, or automatic crash reporting.
- It makes no network requests.

### Settings stored on this Mac

Irodake stores the following in macOS UserDefaults:

- Display mode, fixed rectangle positions and sizes, and frame rate
- Display language, onboarding state, and the Open at Login choice

Window titles shown by the picker are used only during that selection UI and are not persisted. CGWindowID values and tracked-window rules are discarded when the app quits.

You can remove settings by deleting the app and its app container/preferences. An in-app Reset Settings action is planned.

### Screen Recording permission

You can revoke access at any time in System Settings → Privacy & Security → Screen & System Audio Recording. Turning Irodake off stops its capture streams. Irodake pauses for sleep, screen sleep, or user switching and resumes only in the same app session when it was previously on. Permission revocation or a capture error turns it off.

### Third parties

Irodake includes no third-party SDK. It dynamically uses only Apple system frameworks supplied with macOS. macOS manages Screen Recording consent and system indicators.

### Changes

Before adding networking, analytics, crash upload, or license activation, we will update this policy, the Privacy Manifest, and App Store disclosures, and request any required consent.

### Contact

A formal support email and seller identity must be added before public release. Until then, use the GitHub repository Issues or Private vulnerability reporting for technical and security reports.
