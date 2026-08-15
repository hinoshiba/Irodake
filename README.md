# Irodake — 色は、必要な場所だけ。

Irodake は、Mac 全体をグレースケールにしながら選んだ範囲だけカラーを残したり、その逆に選んだ範囲だけをグレーにしたりできる、ネイティブ macOS アプリです。

通常のアプリウインドウとメニューバーの両方から操作できます。画面はこの Mac 上でリアルタイム処理され、画像・音声の保存、外部送信、テレメトリ、広告はありません。

> [!IMPORTANT]
> 現在は動作する MVP / 技術検証版です。署名・公証済みの一般配布や Mac App Store 公開を行う前に、[実機テスト項目](docs/TEST_MATRIX.md)と[商用公開ゲート](docs/COMMERCIAL_RELEASE_GATES.md)を完了してください。`Irodake` は公開情報による一次名称調査を通過していますが、商標の法的クリアランスと App Store Connect・ドメイン等の予約は未完了です。根拠と残課題は[ブランド監査](docs/BRAND_AUDIT.md)を参照してください。

## できること

- **カラーを残す** — 画面全体をグレーにし、選択スポットだけ元のカラーで表示
- **ここだけグレー** — 画面全体はカラーのまま、選択スポットだけグレーで表示
- **固定範囲** — 任意の矩形をドラッグして追加
- **ウインドウ領域** — 選択ウインドウの矩形へ移動・リサイズ追従
- **一括 ON / OFF** — メニューバーまたは `⌥⌘G`
- **カラーピーク** — `⌥⌘C` を押している間だけ元の全カラーを確認
- **複数ディスプレイ** — ディスプレイごとに ScreenCaptureKit stream を構成
- **日本語 / English** — アプリ内で切り替え
- **ログイン時起動** — macOS 標準の `SMAppService` を使用

## 必要環境

- macOS 14 Sonoma 以降
- Metal 対応 Mac
- 「画面とシステムオーディオの収録」の許可

Accessibility、Input Monitoring、Apple Events、ネットワークの各権限は使いません。音声キャプチャも無効です。

## ビルド

Xcode 26.6 / Swift 6.3 で検証しています。外部パッケージや Homebrew 依存はありません。

```bash
swift build
swift test

./build.sh
open dist/Irodake.app
```

`./build.sh` は release binary、独自生成アイコン、MIT License、第三者通知、Privacy Manifest、日英の権限説明を含む ad-hoc 署名済み `dist/Irodake.app` を作ります。

配布ビルドは [docs/RELEASE.md](docs/RELEASE.md) を参照してください。

## 使い方

1. Irodake を起動し、3画面のオンボーディングを確認します。
2. macOS の画面収録許可を与えます。
3. 「カラーを残す」または「ここだけグレー」を選びます。
4. 固定範囲かウインドウ領域を追加します。
5. トグルを ON にします。

ウインドウ領域は実際には対象ウインドウの現在の矩形です。他のウインドウが上に重なると、重なった部分にも同じ表示効果が適用されます。追跡ルールはプライバシーと `CGWindowID` 再利用事故を避けるため、アプリ終了時に破棄されます。

## 仕組み

```text
ScreenCaptureKit（1 display = 1 stream）
  → CVPixelBuffer / IOSurface
  → Core Image + Metal で saturation = 0
  → クリック透過 CAMetalLayer overlay
  → CAShapeLayer mask でカラー／グレーのスポットを作成
```

公開 API と App Sandbox の範囲だけで実装しています。詳細は [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) を参照してください。

## 既知の制約

- 表示はリアルタイム再描画のため、1〜2フレーム程度遅れる場合があります。
- DRM / capture-protected content は黒、静止画、または欠落として表示される場合があります。回避処理は行いません。
- 初期版は SDR。HDR / XDR の正確な色管理は公開前の追加検証対象です。
- 4K / 5K の複数画面では GPU・メモリ帯域・電力を使います。既定は 30 fps です。
- macOS 標準のシステムグレースケールが既に ON の場合、Irodake がカラーを復元することはできません。
- スリープ、画面消灯、ユーザー切替では最初に効果を外して一時停止し、同じ起動セッション内で直前にONだった場合だけ復帰後に再開します。権限取消やキャプチャエラー時はOFFにします。

## プライバシー

Irodake は画面フレームを GPU で処理しますが、画面画像や音声をファイルへ保存せず、Mac の外へ送信しません。ネットワーク通信コードと分析 SDK はありません。

詳しくは [Privacy Policy](docs/PRIVACY.md) を参照してください。

## OSS と商用販売

ソースコードは [MIT License](LICENSE) です。自作ビルドを無料で利用でき、公式の署名・公証済みバイナリを有償販売できます。MIT は第三者による再配布・販売も許すため、公式版の価値は署名、更新、サポート、品質保証、正式ブランドで提供します。

現在の runtime 依存は Apple の OS 提供 framework だけです。外部コード・バイナリはありません。[THIRD_PARTY_LICENSES.txt](THIRD_PARTY_LICENSES.txt) と [ライセンス監査](docs/LICENSE_AUDIT.md) を参照してください。

名称、商標、販売条件、各国消費者法はコードライセンスと別問題です。[商用公開ゲート](docs/COMMERCIAL_RELEASE_GATES.md)を完了し、必要な法域の専門家へ確認してから販売してください。

## 開発・報告

- [Contributing](CONTRIBUTING.md)
- [Security Policy](SECURITY.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Product Strategy](docs/PRODUCT_STRATEGY.md)
- [Brand Audit](docs/BRAND_AUDIT.md)
- [Trademark Policy](TRADEMARKS.md)

Irodake の運用設計は [Youyaku](https://github.com/hinoshiba/youyaku) の署名・公証・ライセンス表示・リリース不変性の考え方を参考にしつつ、Irodake は App Sandbox と外部依存ゼロを維持しています。Youyaku のソースや配布バイナリは組み込んでいません。
