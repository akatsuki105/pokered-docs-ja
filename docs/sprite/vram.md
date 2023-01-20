## VRAM 上のスプライトの2bppタイルデータ

マップにいるときスプライトの2bppタイルデータは次のように配置される

以下のスプライトは スプライトセット01 (`SpriteSets`の最初の11個) から取得したスプライトである

### 通常時  

VRAMのタイルデータ領域1 (0x8000-0x8800 グリッドの1番目)にスプライトの立ち姿のタイルデータが敷き詰められる

また 0x8780 からは1面スプライト(モンスターボールや化石など) を配置する領域が2個分存在する (0x8780-0x87c0, 0x87c0-8800)

VRAMのタイルデータ領域2 (0x8800-0x9000 グリッドの2番目)にスプライトの歩き姿のタイルデータが敷き詰められる

<img src="https://imgur.com/UHG2UDG.png" width="40%" />

### 会話中  

タイルデータ領域1は、通常時と同じ

タイルデータ領域2には、テキストデータのための文字タイルが格納される

<img src="https://imgur.com/Een2IqV.png" width="40%" />

### 外部マップと内部マップ

外部マップと内部マップでタイルデータの配置のされ方が変わってくる

外部マップでは VRAMに `SpriteSets` と同じ順番で配置される(先頭は必ず主人公のスプライト)

例. マサラタウン スプライトセット01

<img src="https://imgur.com/kMFr58l.png" width="40%" />

```asm
; sprite set $01
	db SPRITE_BLUE
	db SPRITE_BUG_CATCHER
	db SPRITE_GIRL
	db SPRITE_FISHER2
	db SPRITE_BLACK_HAIR_BOY_1
	db SPRITE_GAMBLER
	db SPRITE_SEEL
	db SPRITE_OAK
	db SPRITE_SWIMMER
	db SPRITE_BALL
	db SPRITE_LYING_OLD_MAN
```

内部マップでは TODO

<img src="https://imgur.com/UHG2UDG.png" width="40%" />