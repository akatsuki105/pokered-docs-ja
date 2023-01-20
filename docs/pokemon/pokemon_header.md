# Pokemon Header

ポケモンのゲームの進行状態にかかわらず不変な情報を定義している(例えば種族値やタイプなど)

このデータ構造は`ポケモンヘッダ`とも呼ばれる

[data/base_stats.asm](./../../data/base_stats.asm)で定義されている

各ポケモンのデータは[data/base_stats/](./../../data/base_stats/)でファイルごとに定義されている

## description

ズバットを例にポケモンのデータ構造を解説する

```asm
; data/base_stats/zubat.asm

db DEX_ZUBAT ; 図鑑番号

; 種族値
db 40 ; HP
db 45 ; こうげき
db 35 ; ぼうぎょ
db 55 ; すばやさ
db 40 ; とくしゅ

; タイプ
db POISON   ; タイプ1
db FLYING   ; タイプ2

; 野生のポケモンとして出てきたの時のパラメータ
db 255      ; 捕獲率
db 54       ; 倒した際の基礎経験値

; グラフィックデータ
INCBIN "pic/bmon/zubat.pic",0,1 ; 55, sprite dimensions
dw ZubatPicFront
dw ZubatPicBack

; Lv0で覚えている技
db LEECH_LIFE       ; きゅうけつ
db 0                ; null
db 0                ; null
db 0                ; null

; レベルアップに必要な経験値パターン
db 0

; 技マシンで覚える技
	tmlearn 2,4,6
	tmlearn 9,10
	tmlearn 20,21
	tmlearn 31,32
	tmlearn 34,39
	tmlearn 44
	tmlearn 50
db 0 ; padding

```

### tmlearnマクロ

tmlearnマクロは`macros/data_macros.asm`で定義されているマクロ

技マシン番号を内部で利用しているフォーマットに変換する

```asm
; \n 技マシン番号   
tmlearn \1, \2, ...
```

## 進化情報、レベルアップで覚える技

進化情報、レベルアップで覚える技は`data/evos_moves.asm`で定義されている

ここでもズバットを例に解説する

```asm
; data/evos_moves.asm

ZubatEvosMoves:
; 進化情報
	db EV_LEVEL, 22, GOLBAT     ; レベル22でゴルバットに進化
	db 0                        ; 終端記号
; レベルアップで覚える技
	db 10, SUPERSONIC           ; レベル10でSUPERSONIC(ちょうおんぱ)を覚える
	db 15, BITE
	db 21, CONFUSE_RAY
	db 28, WING_ATTACK
	db 36, HAZE
	db 0                        ; 終端記号

```

### Evolution typesについて

進化の仕方をカテゴライズしたもの

```asm
; Evolution types
EV_LEVEL EQU 1      ; レベルアップによる進化
EV_ITEM  EQU 2      ; アイテム利用による進化
EV_TRADE EQU 3      ; 通信交換による進化

; ズバット
db EV_LEVEL, 22, GOLBAT                 ; レベル22でゴルバットに進化

; タマタマ
db EV_ITEM, LEAF_STONE, 1, EXEGGUTOR    ; TODO

; ゴローン
db EV_TRADE, 1, GOLEM                   ; TODO
```

の3パターンある

## 関連

- [Pokemon Data](./pokemon_data.md)
