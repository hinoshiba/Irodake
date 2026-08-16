# Contributing to Irodake

Contributions are accepted under the repository's MIT License. The `Irodake` name and logo are governed separately by [TRADEMARKS.md](TRADEMARKS.md); the code license does not make a modified distribution official.

Issue と Pull Request を歓迎します。

## 開発手順

```bash
swift build
swift test
xcodegen generate
xcodebuild -project Irodake.xcodeproj -scheme Irodake -destination 'platform=macOS' test CODE_SIGNING_ALLOWED=NO
./Scripts/audit-source.sh
./Scripts/audit-brand.sh
./Scripts/audit-store-assets.sh
```

画面処理を変更する場合は [docs/TEST_MATRIX.md](docs/TEST_MATRIX.md) の該当項目を実機で確認してください。画面収録権限を要求する自動 UI テストは CI では実行しません。

## Pull Request

- 1 PR は1つの論理変更に絞る。
- 公開 API と App Sandbox の範囲を維持する。
- 新しい権限、通信、保存、分析を追加する場合は Privacy Policy と App Store disclosure を同時更新する。
- 依存追加は [docs/DEPENDENCY_POLICY.md](docs/DEPENDENCY_POLICY.md) の監査票を PR に含める。
- UI の状態を色だけで伝えず、VoiceOver label とキーボード操作を保つ。
- `Signed-off-by` を付け、[Developer Certificate of Origin](https://developercertificate.org/) への同意を示す。

```bash
git commit -s -m "変更内容"
```

コミット、push、公開を行う前に、第三者のコード・画像・フォント・文章を無断で含めていないことを確認してください。
