# Map Header

マップの持つ様々な情報を格納する場所のことをここではMap Headerと呼んでいる

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

```asm
db PALLET_TOWN_HEIGHT, PALLET_TOWN_WIDTH 
```

PALLET_TOWN_HEIGHT, PALLET_TOWN_WIDTH は `./constants/map_constants.asm` で定義されている 

大きさはブロック(32*32px)単位であることに注意

### コネクションマクロ

マップがほかのマップとどのようにつながっているか(コネクション)を定義したもの

```asm
db NORTH | SOUTH													;　北と南にマップのつなぎ目がある

; ここでコネクションがどのようなものであるか定義している
NORTH_MAP_CONNECTION PALLET_TOWN, ROUTE_1, 0, 0, Route1_Blocks
SOUTH_MAP_CONNECTION PALLET_TOWN, ROUTE_21, 0, 0, Route21_Blocks, 1
```

コネクションマクロは次のようなものである

#### NORTH_MAP_CONNECTION

北のコネクションを定義したマクロ

```asm
; NORTH_MAP_CONNECTION \1, \2, \3, \4, \5
; \1 (byte) = 現在のMap ID
; \2 (byte) = コネクション先のMap ID
; \3 (byte) = x movement of connection strip
; \4 (byte) = connection strip offset
; \5 (word) = コネクション先のマップのブロックデータ
NORTH_MAP_CONNECTION PALLET_TOWN, ROUTE_1, 0, 0, Route1_Blocks
```

#### SOUTH_MAP_CONNECTION

南のコネクションを定義したマクロ

```asm
;\1 (byte) = 現在のMap ID
;\2 (byte) = コネクション先のMap ID
;\3 (byte) = x movement of connection strip
;\4 (byte) = connection strip offset
;\5 (word) = コネクション先のマップのブロックデータ
;\6 (flag) = add 3 to width of connection strip (why?)
SOUTH_MAP_CONNECTION PALLET_TOWN, ROUTE_21, 0, 0, Route21_Blocks, 1
```

#### WEST_MAP_CONNECTION

西のコネクションを定義したマクロ

北のコネクションとほぼ同じなので割愛

#### EAST_MAP_CONNECTION

東のコネクションを定義したマクロ

南のコネクションとほぼ同じなので割愛


