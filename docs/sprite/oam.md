# OAM

OAM: Object Attribute Memory(スプライト属性テーブル)

\$FE00-\$FE9F(160バイト)に配置されるスプライトのプロパティを定義しているテーブル

1エントリ4バイトなのでOAMには160/4 = 40スプライト分のプロパティを格納できる

各エントリは

- 0byte: スプライトのY座標(px)
- 1byte: スプライトのX座標(px)
- 2byte: タイル番号
- 3byte: スプライトの属性

を定義している

## wOAMBuffer

`wOAMBuffer` は WRAMの 0xc300 にある160バイトの領域で、OAM DMAで転送されるデータ(160バイト)を格納しておくバッファとして使われている。

OAMに直接書き込むことができる期間は、ハードウェアの制約上ごくわずかな期間なので、普段スプライトのOAMを更新する時はこの`wOAMBuffer`を更新する。

`wOAMBuffer`に書き込まれた値は、OAM DMA で実際に OAM　に転送される。

実際に `engine/oam_dma.asm` の `DMARoutine`関数 に転送処理が記述されており、この関数は vBlank 時に呼び出されている。

## 参考

[VRAM Sprite Attribute Table (OAM)](https://gbdev.io/pandocs/#vram-sprite-attribute-table-oam)