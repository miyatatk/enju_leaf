# StudyLib — Custom Fork of Next-L Enju Leaf

**StudyLib（スタディライブラリー）** は、書斎・自宅の書籍、雑誌、資料、電子化資料などを管理するための、オープンソース図書館管理システム **[Next-L Enju Leaf](https://github.com/next-l/enju_leaf)** の独自カスタマイズ版です。

**StudyLib** is an independent customization of Next-L Enju Leaf for managing a personal library and study-room collection.

> **StudyLibの最新版・詳細README / Current StudyLib source and documentation:**  
> ### [`studylib/deploy-1.6.3` — 機能紹介・本家との差分・技術構成を見る](https://github.com/miyatatk/enju_leaf/tree/studylib/deploy-1.6.3)
>
> GitHubの既定ブランチは`main`ですが、**StudyLibの実際の統合・運用コードは`studylib/deploy-1.6.3`** にあります。  
> The repository default branch is `main`; the StudyLib integration/deployment branch is `studylib/deploy-1.6.3`.

## StudyLibの特徴 / Highlights

| 項目 | 概要 |
| --- | --- |
| 書影自動取得 / Book covers | ISBNからGoogle Books APIをサーバー側で呼び出して書影を表示 |
| APIキー管理 / Secure API key | 管理者専用「StudyLib拡張設定」画面で登録・暗号化保存 |
| 所蔵情報ID / Local identifiers | `Ayyyy-mmdd-nnnc` 形式の正規化・日付検証・チェックデジット処理 |
| 既存機能 / Enju foundation | 書誌、所蔵、検索、利用者管理など、本家の図書館管理機能を活用 |
| 運用 / Deployment | Enju Leaf 1.6.3に基づくDocker Compose環境 |

これらの追加機能、導入上の注意、制約、開発ブランチと本家Enjuとの関係については、**[StudyLibの詳細README](https://github.com/miyatatk/enju_leaf/blob/studylib/deploy-1.6.3/README.md)** に記載しています。

## 本家プロジェクト / Original project

StudyLib is a **fork, not an official Project Next-L release**.

- [Next-L Enju Leaf — original repository](https://github.com/next-l/enju_leaf)
- [Project Next-L](https://www.next-l.jp)
- [Enju documentation](https://next-l.github.io/manual/)
- [MIT License](MIT-LICENSE)

The underlying integrated library system was developed by Project Next-L contributors. StudyLib adds independent customizations on top of that work.
