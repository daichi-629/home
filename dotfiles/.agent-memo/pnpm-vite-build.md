# pnpm run build が TS 設定でつまずく場合

`pnpm run build` が package.json の build スクリプト内の tsc 型チェックステップで
失敗することがある(TS 設定の問題)。

回避策: `pnpm exec vite build` を直接実行して、失敗する tsc ステップを迂回する。

2026-07-03 のセッション観測からインポート。
