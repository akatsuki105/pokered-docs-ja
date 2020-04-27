# 詳解ポケモン赤

これは[ポケモン赤を逆アセンブルしたレポジトリ](https://github.com/pret/pokered)に対して、日本語で詳細な解説を加えたレポジトリです。

日本語で解説を加えてはいますが、対象のROMは英語版のポケモン赤であることに注意してください。

## 前提知識

- アセンブリやリンカなどの一般的な低レイヤの知識
- 割り込みやMBC、バンクなどのGameBoyのハードウェア仕様
- [rgbds(Rednex Game Boy Development System)](https://github.com/rednex/rgbds)に関する理解

またエディタを使ってコードを読む場合はVSCodeと[RGBDS用の拡張機能](https://marketplace.visualstudio.com/items?itemName=donaldhays.rgbds-z80)の使用を推奨します。

## 各ディレクトリの説明

- [home](./home/README.md)
- [text](./text/README.md)
- [pic](./pic/README.md)

## ドキュメント一覧

- [カートリッジ](./docs/cartridge.md)
- [バンク](./docs/bank.md)
- [テキストデータ](./docs/text.md)
- [文字コード](./docs/charcode.md)