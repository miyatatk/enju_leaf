# StudyLib — Personal Collection Management with Next-L Enju Leaf

**[日本語](#studylibについて) | [English](#about-studylib)**

StudyLib is a customized edition of [Next-L Enju Leaf](https://github.com/next-l/enju_leaf) for organizing a personal library or study-room collection. It retains Enju's integrated library management features while adding local identifier handling, automatic book-cover lookup, and an administrator-only extension settings page.

> **Current StudyLib integration branch:** [`studylib/deploy-1.6.3`](https://github.com/miyatatk/enju_leaf/tree/studylib/deploy-1.6.3)  
> **Upstream release base:** Next-L Enju Leaf **1.6.3**. StudyLib does **not** change the upstream application version number.  
> **Project status:** Independently customized and operated; not an official release of Project Next-L.

## StudyLibについて

**StudyLib** は、書斎・自宅の資料コレクションを管理するための [Next-L Enju Leaf](https://github.com/next-l/enju_leaf) のカスタマイズ版です。書籍、雑誌、資料、電子化資料、CD等を対象に、本家の図書館管理機能を活用しながら、個人コレクションに合わせた機能を追加しています。

### StudyLib独自の機能

| 機能 | StudyLibの実装 |
| --- | --- |
| **ISBNによる書影自動取得** | Google Books APIをRailsサーバー側から呼び出し、ISBNに対応する書影を表示。個別登録された画像を優先し、取得できない場合は代替画像を使用 |
| **Google Books APIキー管理** | 「図書館の管理 → StudyLib拡張設定」（`/studylib/settings`）から管理者が登録・変更・削除。暗号化保存し、保存済みキーは画面に再表示しない |
| **StudyLib所蔵情報ID** | `Ayyyy-mmdd-nnnc` 形式。入力値の正規化、日付部分の検証、チェックデジットの計算・補正を実装 |
| **従来機能との互換性** | Enjuの書誌・所蔵・利用者管理などを維持。書影の取得元として既存のopenBD・版元ドットコムも利用可能 |
| **Docker運用** | PostgreSQL、Solr、Cantaloupe、Tika、NGINX等を組み合わせたDocker Compose構成で運用 |

### 本家Next-L Enju Leafとの違い

StudyLibは**別製品として書き直したシステムではありません**。本家Enju Leafの図書館管理機能を基盤とし、次の部分を独自に追加・変更しています。

1. **個人コレクション向けの所蔵情報ID体系** — StudyLib固有の入力規則とチェック処理
2. **Google Books書影取得のサーバー側処理** — ブラウザからAPIキーを直接利用しない構成
3. **管理者専用の拡張設定ページ** — APIキーの暗号化保存・管理
4. **運用構成の調整** — StudyLib環境に合わせたDockerイメージとデプロイ用ブランチ

本家の書誌・所蔵、貸出、検索等の基本機能はEnju Leafに由来します。上記の独自機能を、すべて本家に存在しない新機能であるかのように扱うものではありません。

### 書影取得の仕組みと制約

- 管理者がGoogle Books APIキーを設定すると、ISBNから書影URLをサーバー側で照会します。APIキーはブラウザに送信しません。
- Google Booksへの問い合わせが失敗した場合、または対象画像がない場合は代替画像を表示します。
- 外部APIの応答がキャッシュ有効期間を指定した場合のみ、その期間内でメタデータを一時キャッシュします。**現在確認したGoogle Books APIの応答には有効期間が指定されていないため、実環境ではキャッシュされず、表示時に再照会が発生します。** Google APIの利用枠・利用条件にご注意ください。
- Google Books APIキーは利用者自身がGoogle Cloudで取得・管理する必要があります。キーや認証情報をGitリポジトリにコミットしないでください。

### 開発・運用ブランチ

| ブランチ | 用途 |
| --- | --- |
| [`studylib/deploy-1.6.3`](https://github.com/miyatatk/enju_leaf/tree/studylib/deploy-1.6.3) | StudyLibの統合・運用ブランチ（現在の主要成果物） |
| [`studylib/base-1.6.3`](https://github.com/miyatatk/enju_leaf/tree/studylib/base-1.6.3) | 本家1.6.3を基礎とするブランチ |
| [`studylib/item-identifier-1.6.3`](https://github.com/miyatatk/enju_leaf/tree/studylib/item-identifier-1.6.3) | 所蔵情報IDの開発・管理 |
| [`studylib/cover-image-1.6.3`](https://github.com/miyatatk/enju_leaf/tree/studylib/cover-image-1.6.3) | 書影取得機能の開発履歴 |
| `main` | GitHubフォークの既定ブランチ。**StudyLib運用版は上記の`deploy`ブランチです** |

### 動作確認と今後の方向性

- Google Books書影取得・設定ページは実環境で動作確認済み。
- 書影取得・設定管理に関するRSpec **23件成功（2026-11-15、ローカル実行）**。プロジェクト全体のテスト完了を意味するものではありません。
- 将来的には、現在のEnju標準画面を段階的に見直し、レスポンシブなStudyLib独自UIを検討しています。**現時点で全面的なUI刷新は実装されていません。**

---

## About StudyLib

StudyLib is an independent customization of Next-L Enju Leaf for managing a home library and personal research collection, including books, journals, documents, digitized materials, and other media.

**What StudyLib adds:** a local item-identifier format with validation and check-digit correction; server-side ISBN-based cover lookup through Google Books; an administrator-only settings screen for an encrypted API key; and a Docker-based deployment adapted to the StudyLib environment. Existing Enju functionality remains the foundation.

The current integration branch tracks **Enju Leaf 1.6.3**. Google Books covers require a user-provided API key and an external API request; results are not guaranteed for every ISBN. The code has passed 23 targeted RSpec examples in the local environment (15 November 2026), but this is not a claim of full upstream test-suite coverage.

**Getting started:** examine the [StudyLib integration branch](https://github.com/miyatatk/enju_leaf/tree/studylib/deploy-1.6.3) and the [upstream Enju documentation](https://next-l.github.io/manual/). This repository contains a deployment-oriented customization, not a turnkey hosted service.

## Upstream, credits and license

StudyLib builds on **[Next-L Enju Leaf](https://github.com/next-l/enju_leaf)**, an open-source integrated library system developed by [Project Next-L](https://www.next-l.jp) and its contributors.

- Upstream demonstration: https://enju.next-l.jp
- Upstream documentation: https://next-l.github.io/manual/
- Upstream installation guidance: https://github.com/next-l/enju_leaf/wiki/Install
- Source license: [MIT License](MIT-LICENSE)

Thanks to the original developers and contributors, including [Kosuke Tanabe](https://github.com/nabeta), and the Project Next-L community. StudyLib is an independent fork and is not affiliated with or endorsed by Project Next-L.
