# Security Policy

## Supported versions

一般公開前のため、現時点では `main` のみを対象に修正します。公開後は最新 minor release をサポート対象とします。

## Reporting a vulnerability

画面内容、権限、署名・更新、Sandbox 逸脱、任意コード実行に関する問題は公開 Issue に機密情報を書かず、GitHub の **Private vulnerability reporting** から報告してください。

受領から3営業日以内の一次応答、影響評価後の修正計画共有を目標にします。公開時期は修正版の配布準備が整うまで調整してください。

Irodake は画面を扱うため、次を特に重大とみなします。

- 画面フレームやウインドウ情報の意図しない保存・通信
- OFF / エラー後もキャプチャまたはオーバーレイが残る問題
- 配布物の署名・公証・更新検証の迂回
- private API、過剰 entitlement、Sandbox 逸脱
