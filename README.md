# 詳解ポケモン赤

![cover](./docs/image/cover.png)

これは[ポケモン赤を逆アセンブルしたレポジトリ](https://github.com/pret/pokered)に対して、日本語で詳細な解説を加えたレポジトリです。

日本語で解説を加えてはいますが、対象のROMは英語版のポケモン赤であることに注意してください。

## 前提知識

- アセンブリやリンカなどの一般的な低レイヤの知識
- gbz80のISAや割り込みやMBC、バンクなどのGameBoyのハードウェア仕様
- [rgbds(Rednex Game Boy Development System)](https://github.com/rednex/rgbds)に関する多少の理解

またエディタを使ってコードを読む場合はVSCodeと[rgbds用の拡張機能](https://marketplace.visualstudio.com/items?itemName=donaldhays.rgbds-z80)の使用を推奨します。

## ドキュメント一覧

- [1bpp](./docs/1bpp.md)
- [2bpp](./docs/2bpp.md)
- [バンク](./docs/bank.md)
- [ポケモンのデータ構造](./docs/baseStats.md)
- [BCD](./docs/bcd.md)
- [blk](./docs/blk.md)
- [カートリッジ](./docs/cartridge.md)
- [文字コード](./docs/charcode.md)
- [マクロ](./docs/macro.md)
- [マップオブジェクト](./docs/map_object.md)
- [マップ](./docs/map.md)
- [movement byte](./docs/movement_byte.md)
- [picファイル](./docs/pic_format.md)
- [predef](./docs/predef.md)
- [rgbgfx](./docs/rgbgfx.md)
- [スプライトデータ](./docs/sprite_data.md)
- [スプライト](./docs/sprite.md)
- [用語](./docs/term.md)
- [テキストID](./docs/text_id.md)
- [テキストデータ](./docs/text.md)
- [タイル](./docs/tile.md)
- [野生のポケモン](./docs/wild_pokemon.md)

## ファイル一覧

 ファイル名  |  内容
---- | ----
 audio/  |  null
 constants/  |  [constants](./constants/README.md)参照
 data/  |  null
 engine/  |  [engine](./engine/README.md)参照
 gfx/  |  [gfx](./gfx/README.md)参照
 home/  |  [home](./home/README.md)参照
 macros/  |  [macros](./macros/README.md)参照
 maps/  |  [maps](./maps/README.md)参照
 pic/  |  [pic](./pic/README.md)参照
 scripts/  |  null
 text/  |  [text](./text/README.md)参照
 tools/  |  [tools](./tools/README.md)参照
 audio.asm  |  null
 charmap.asm  |  文字コードのマクロ定義
 constants.asm  |  定数シンボルのマクロ定義
 home.asm  |  null
 hram.asm  |  HRAM領域にどのようなデータが配置されるかの定義を行っている
 macros.asm  |  macros/以下の各マクロファイルをまとめている
 main.asm  |  null
 pokered.link  |  リンカスクリプト <br/>各セクションがどのバンクのどのアドレスに配置されるかを指示している
 sram.asm  |  null
 text.asm  |  各テキストデータファイルをまとめている <br/>pokered.linkでROMバンク$20以降に配置されている 
 vram.asm  |  null
 wram.asm  |  WRAM領域にどのようなデータが配置されるかの定義を行っている
