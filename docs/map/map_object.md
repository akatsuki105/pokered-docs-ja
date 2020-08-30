# Map Object

マップに配置されるオブジェクトを定義している場所

ここで定義したデータはMap Headerによってマップに紐づけられる

#### オブジェクトの種類

- border block マップを囲む壁に使うタイルの種類
- warps ワープが起こるマス
- signs 看板やテレビなどのAボタンでテキストが出てくるオブジェクト
- objects 人などのオブジェクト
- warp-to ここで定義した場所にワープが可能

主人公の家の1Fを例に Map Object を解説する

```asm
RedsHouse1F_Object:
    ; border block
	db $a

    ; warps
	db 3                        ; ワープは3つ
	warp 2, 7, 0, -1            ; 家の出口1
	warp 3, 7, 0, -1            ; 家の出口2(カーペットなので2マス出口がある)
	warp 7, 1, 0, REDS_HOUSE_2F ; 上に上がる階段

    ; signs
	db 1            ; signsは1つ
	sign 3, 1, 2    ; TV

    ; objects
	db 1                                    ; オブジェクトは1つ
	object SPRITE_MOM, 5, 4, STAY, LEFT, 1  ; 主人公の母親

	; warp-to
	warp_to 2, 7, REDS_HOUSE_1F_WIDTH
	warp_to 3, 7, REDS_HOUSE_1F_WIDTH
	warp_to 7, 1, REDS_HOUSE_1F_WIDTH
```

## warps

```
; warpマクロ
; \1: ワープマスのx座標
; \2: ワープマスのy座標
; \3: dest_warp_id(ワープ先でこのワープイベントに割り当てられたインデックス マップ内でのwarpマス識別に使う)
; \4: ワープ先のマップ
warp \1, \2, \3, \4
```

\4(ワープ先のマップ)が-1のときは最後にいたマップを示す

\3(dest_warp_id)と\4(ワープ先のマップ)でワープ先でどのwarp-toにワープするか決めている

dest_warp_idの割り振りについてはwarp_to参照

## signs

signsは看板やテレビなどのAボタンでテキストが出てくるオブジェクトのこと

```
; signマクロ  
; \1: x座標
; \2: y座標
; \3: signID
sign \1, \2, \3
```

#### signID

spriteIDはsignsのsignIDと同じスコープに存在していて、`DisplayTextID`の対象の識別子として使われるID

## objects

objectsは人やアイテムなどのオブジェクトのこと

```
; objectマクロ
; \1: spriteID
; \2: x座標
; \3: y座標
; \4: そのオブジェクトが動くかどうか(WALK or STAY)
; \5: movement byte 2
; \6: テキストID
; \7(optional): アイテム->アイテムID トレーナー->トレーナクラス or ポケモンID
; \8(optional): トレーナー->トレーナー番号 or ポケモンのレベル 
object \1, \2, \3, \4, \5, \6, (\7), (\8)


; SPRITE_MOMが(5, 4)で左方向で固定 話しかけたときにはテキストID 1のテキストを実行する
object SPRITE_MOM, 5, 4, STAY, LEFT, 1

; CeruleanCaveB1F.asmより
; SPRITE_SLOWBROが(27, 13)で下方向で固定 話しかけるとテキストID 1のテキストを実行しミューツーLv70とのバトルが始まる
object SPRITE_SLOWBRO, 27, 13, STAY, DOWN, 1, MEWTWO, 70
```

#### spriteID

spriteIDはsignsのsignIDと同じスコープに存在していて、`DisplayTextID`の対象の識別子として使われるID

0は常にプレイヤーに割り当てられるので1から始まる？

#### テキストID

[テキストIDのドキュメント](./text_id.md)を参照

## warp_to

ここで定義した場所にワープが可能になる

```
; warp_toマクロ
; \1 X座標
; \2 Y座標  
; \3 マップの幅 
warp_to \1, \2, \3
```

\3(マップの幅)は基本 `MAP_NAME_WIDTH`としておく

#### dest_warp_id

warp_toを定義した順番が、dest_warp_idとなる

```
; warp-to
warp_to 2, 7, REDS_HOUSE_1F_WIDTH       ; dest_warp_id = 0
warp_to 3, 7, REDS_HOUSE_1F_WIDTH       ; dest_warp_id = 1
warp_to 7, 1, REDS_HOUSE_1F_WIDTH       ; dest_warp_id = 2
```

## 参考

- [マップ](./map/README.md)
- [Map Header](./map/map_header.md)