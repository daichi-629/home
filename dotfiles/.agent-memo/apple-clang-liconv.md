# Apple clang と -liconv のリンクエラー

Rust のビルドで、Apple clang ツールチェインの切り替え(Xcode Command Line Tools の
更新や `xcode-select` の切り替えなど)後に `-liconv` の解決に失敗してリンクエラー
になることがある。

回避策: 未確認(プレースホルダー)。過去のセッションで観測されたが具体的な回避策は
未記録。再発時に確認して埋めること。

2026-07-03 のセッション観測からインポート。
