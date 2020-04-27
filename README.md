# 詳解ポケモン赤

これは[ポケモン赤を逆アセンブルしたレポジトリ](https://github.com/pret/pokered)に対して、日本語で詳細な解説を加えたレポジトリです。

日本語で解説を加えてはいますが、対象のROMは英語版のポケモン赤であることに注意してください。

## 前提知識

- アセンブリやリンカなどの一般的な低レイヤの知識
- 割り込みやMBC、バンクなどのGameBoyのハードウェア仕様
- [rgbds(Rednex Game Boy Development System)](https://github.com/rednex/rgbds)に関する理解

またエディタを使ってコードを読む場合はVSCodeと[RGBDS用の拡張機能](https://marketplace.visualstudio.com/items?itemName=donaldhays.rgbds-z80)の使用を推奨します。

## ドキュメント一覧

- [1bpp](./docs/1bpp.md)
- [2bpp](./docs/2bpp.md)
- [カートリッジ](./docs/cartridge.md)
- [バンク](./docs/bank.md)
- [テキストデータ](./docs/text.md)
- [文字コード](./docs/charcode.md)

## ファイル一覧

 ファイル名  |  内容
---- | ----
 audio/  |  null
 constants/  |  null
 data/  |  null
 engine/  |  null
 gfx/  |  [gfx](./gfx/README.md)参照
 home/  |  [home](./home/README.md)参照
 macros/  |  null
 maps/  |  [maps](./maps/README.md)参照
 pic/  |  [pic](./pic/README.md)参照
 scripts/  |  null
 text/  |  [text](./text/README.md)参照
 tools/  |  [tools](./tools/README.md)参照
 audio.asm  |  null
 charmap.asm  |  文字コードを定義している
 constants.asm  |  null
 home.asm  |  null
 hram.asm  |  null
 macros.asm  |  null
 main.asm  |  null
 pokered.link  |  リンカスクリプト 各セクションがどのバンクのどのアドレスに配置されるかを指示している
 sram.asm  |  null
 text.asm  |  null
 vram.asm  |  null
 wram.asm  |  null
