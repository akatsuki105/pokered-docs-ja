# mapObjects

マップ上のオブジェクト(スプライトやマップ移動パネル)を定義している

主人公の家の1Fを例にmapObjectを解説する

```asm
RedsHouse1F_Object:
    ; border block: ボーダーブロック
	db $a

    ; warps: ワープ
	db 3                        ; ワープは3つ
	warp 2, 7, 0, -1            ; 家の出口1
	warp 3, 7, 0, -1            ; 家の出口2(カーペットなので2マス出口がある)
	warp 7, 1, 0, REDS_HOUSE_2F ; 上に上がる階段

    ; signs: 看板やテレビなどのAボタンでテキストが出てくるオブジェクト
	db 1            ; signsは1つ
	sign 3, 1, 2    ; TV

    ; objects: 人などのオブジェクト
	db 1                                    ; オブジェクトは1つ
	object SPRITE_MOM, 5, 4, STAY, LEFT, 1  ; 主人公の母親

	; warp-to
	warp_to 2, 7, REDS_HOUSE_1F_WIDTH
	warp_to 3, 7, REDS_HOUSE_1F_WIDTH
	warp_to 7, 1, REDS_HOUSE_1F_WIDTH
```

### border block

TODO

### warps

```
; warpマクロ
; \1: x座標
; \2: y座標
; \3: dest_warp_id
; \4: ワープ先のマップ
warp \1, \2, \3, \4
```

ワープ先のマップが-1のときは最後にいたマップを示す

### signs

signsは看板やテレビなどのAボタンでテキストが出てくるオブジェクトのこと

```
; signマクロ  
; \1: x座標
; \2: y座標
; \3: signID
sign \1, \2, \3
```

TODO: 要検証  
signIDはobjectsのspriteIDと同じスコープに存在していて、`DisplayTextID`の対象の識別子として使われるID

### objects

objectsは人やアイテムなどのオブジェクトのこと

```
; objectマクロ
; \1: spriteID
; \2: x座標
; \3: y座標
; \4: そのオブジェクトが動くかどうか(WALK or STAY)
; \5: 最初に向いている方向
; \6: テキストID
; \7(optional): アイテム->アイテムID トレーナー->トレーナクラス or ポケモンID
; \8(optional): トレーナー->トレーナー番号 or ポケモンのレベル 
object \1, \2, \3, \4, \5, \6, (\7), (\8)


; SPRITE_MOMが(5, 4)で左方向で固定 話しかけたときのテキストIDが1
object SPRITE_MOM, 5, 4, STAY, LEFT, 1

; SPRITE_SLOWBROが(27, 13)で下方向で固定 話しかけるとテキストIDが1でミューツーLv70とのバトルが始まる(CeruleanCaveB1F.asmより)
object SPRITE_SLOWBRO, 27, 13, STAY, DOWN, 1, MEWTWO, 70
```

TODO: 要検証  
spriteIDはsignsのsignIDと同じスコープに存在していて、`DisplayTextID`の対象の識別子として使われるID

### warp_to

TODO