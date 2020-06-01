# Map Header

マップの持つメタデータのことをここではMap Headerと呼んでいる

各マップのMap Headerは `./data/mapHeaders/` で定義されている

## Example

マサラタウンを例にMap Headerのフォーマットについて説明する

```asm
PalletTown_h:
	db OVERWORLD                                                            ; このマップで利用するタイルセット
	db PALLET_TOWN_HEIGHT, PALLET_TOWN_WIDTH                                ; マップの大きさ(ブロック単位)
	dw PalletTown_Blocks                                                    ; blkデータのポインタ
	dw PalletTown_TextPointers                                              ; テキストテーブルのポインタ
	dw PalletTown_Script                                                    ; スクリプトテーブルのポインタ
	db NORTH | SOUTH                                                        ; マップがほかのマップとどのようにつながっているかを定義している
	NORTH_MAP_CONNECTION PALLET_TOWN, ROUTE_1, 0, 0, Route1_Blocks
	SOUTH_MAP_CONNECTION PALLET_TOWN, ROUTE_21, 0, 0, Route21_Blocks, 1
	dw PalletTown_Object                                                    ; Map Object へのポインタ ./map_object.md 参照
```

### マップの大きさ

PALLET_TOWN_HEIGHT, PALLET_TOWN_WIDTH は `./constants/map_constants.asm` で定義されている 

大きさはブロック(32*32px)単位であることに注意


