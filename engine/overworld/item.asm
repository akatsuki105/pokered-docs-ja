; **PickUpItem**  
; マップ上に落ちているアイテムを拾う処理  
; - - -  
; マップ上に落ちているモンボアイコンのアイテムは missable objectとして扱われており、拾った後は missable object の表示フラグが非表示になりマップ上からなくなる  
; 
; INPUT:  [hSpriteIndexOrTextID] = 拾うアイテムのスプライトのオフセット
PickUpItem:
	call EnableAutoTextBoxDrawing

	; b = [hSpriteIndexOrTextID]
	ld a, [hSpriteIndexOrTextID]
	ld b, a

	ld hl, wMissableObjectList

; wMissableObjectList から [hSpriteIndexOrTextID] に対応する missable objectを見つける
.missableObjectsListLoop
; {
	; 最後までみた -> return
	ld a, [hli]
	cp $ff
	ret z
	; [hSpriteIndexOrTextID] に対応する missable object を見つけた -> .isMissable
	cp b
	jr z, .isMissable
	inc hl
	jr .missableObjectsListLoop
; }

.isMissable
	; [$ffdb] = missable object の global offset (MapHS00 を 0として対象の missable object が何番目のアイテムか)
	ld a, [hl]
	ld [$ffdb], a

	; a = missable object のアイテムID
	ld hl, wMapSpriteExtraData
	ld a, [hSpriteIndexOrTextID]
	dec a
	add a
	ld d, 0
	ld e, a
	add hl, de	; hl = wMapSpriteExtraData の対応エントリ
	ld a, [hl]

	; プレイヤーの持つ missable object の個数を 1つ増やす
	ld b, a
	ld c, 1
	call GiveItem
	; カバンがいっぱいで GiveItem に失敗 -> .BagFull ("No more room for items!")
	jr nc, .BagFull

	; 拾ったアイテムをマップ上から以後取り除く
	ld a, [$ffdb]	; a = missable object の global offset
	ld [wMissableObjectIndex], a
	predef HideObject

	; " found ${ITEM}!"
	ld a, 1
	ld [wDoNotWaitForButtonPressAfterDisplayingText], a
	ld hl, FoundItemText
	jr .print

.BagFull
	; "No more room for items!"
	ld hl, NoMoreRoomForItemText

.print
	call PrintText
	ret

; "<PLAYER> found ${ITEM}!"
FoundItemText:
	TX_FAR _FoundItemText
	TX_SFX_ITEM_1
	db "@"

; "No more room for items!"
NoMoreRoomForItemText:
	TX_FAR _NoMoreRoomForItemText
	db "@"
