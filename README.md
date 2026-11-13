# Enju Leaf StudyLib Custom

This repository is a StudyLib custom fork of [Next-L Enju Leaf](https://github.com/next-l/enju_leaf), based on Next-L Enju Leaf v1.6.0.

StudyLib is intended for managing study-room and home collection materials, including books, journals, documents, digitized materials, CDs, and other media.

このリポジトリは、[Next-L Enju Leaf](https://github.com/next-l/enju_leaf) v1.6.0 をベースにした StudyLib カスタムフォークです。

StudyLib は、書籍、雑誌、資料、電子化資料、CD等のメディアを含む、書斎・自宅資料コレクション管理向けのカスタマイズ版です。


## Optional customizations / 任意カスタマイズ

### StudyLib item identifier format / StudyLib 所蔵情報ID形式

The `studylib/item-identifier` branch adds a local item identifier format for StudyLib:

- `Ayyyy-mmdd-nnnc`
- automatic normalization
- date validation
- UPC-A / JAN-style check digit correction

This branch is optional and is intended for users who want to adopt the StudyLib item identifier convention.

`studylib/item-identifier` ブランチでは、StudyLib 用のローカル所蔵情報ID形式を追加しています。

- `Ayyyy-mmdd-nnnc`
- 入力値の自動正規化
- 日付部分の妥当性検証
- UPC-A / JAN 方式に準じたチェックデジット補正

このブランチは任意です。StudyLib の所蔵情報ID命名規則を採用したい場合のみ利用してください。

---


# Next-L Enju Leaf
[![Ruby on Rails CI](https://github.com/next-l/enju_leaf/actions/workflows/rubyonrails.yml/badge.svg)](https://github.com/next-l/enju_leaf/actions/workflows/rubyonrails.yml)
[![Code Coverage](https://qlty.sh/gh/next-l/projects/enju_leaf/coverage.svg)](https://qlty.sh/gh/next-l/projects/enju_leaf)

Next-L Enju Leaf は、[Project Next-L](https://www.next-l.jp) で開発している図書館管理システムです。

Next-L Enju Leaf is an integrated library system developed by [Project
Next-L](https://www.next-l.jp).

## Project Next-L とは (What is Project Next-L?)
[Project Next-L](https://www.next-l.jp)
とは、日本の図書館関係者有志の手で新しい図書館管理システムを作り上げるプロジェクトです。

[Project Next-L](https://www.next-l.jp) is a project to build a new integrated
library system maintained by Japanese volunteers interested in libraries.

## 動作デモ (Demonstration)
* https://enju.next-l.jp


## マニュアル (Manual)
* https://next-l.github.io/manual/


## インストール (Install)

* https://github.com/next-l/enju_leaf/wiki/Install


## 関連するプロジェクト (Related projects)
* [Next-L Enju Root](https://github.com/next-l/enju_root)
* [Next-L Enju Flower](https://github.com/next-l/enju_flower)


## 製作者・貢献者 (Authors and contributors)
* [TANABE, Kosuke](https://github.com/nabeta) ([@nabeta](https://twitter.com/nabeta))
* [Project Next-L](https://www.next-l.jp) ([@ProjectNextL](https://twitter.com/ProjectNextL))
