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

## 参考

[VRAM Sprite Attribute Table (OAM)](https://gbdev.io/pandocs/#vram-sprite-attribute-table-oam)