; **HiddenItems**  
; 隠しアイテムを調べる処理  
; 隠しアイテムが存在する場所かつまだ取得フラグが立っていないのなら隠しアイテムを取得する  
; - - -
; INPUT: 
; - [wCurMap] = 現在のマップ
; - [wHiddenObjectX]/[wHiddenObjectY] = 現在調べているマスのcoord
HiddenItems:
	; [wHiddenItemOrCoinsIndex] = HiddenItemCoordsのオフセット
	ld hl, HiddenItemCoords
	call FindHiddenItemOrCoinsIndex
	ld [wHiddenItemOrCoinsIndex], a

	; wObtainedHiddenItemsFlagsの[wHiddenItemOrCoinsIndex]bit目をcレジスタに入れる
	ld hl, wObtainedHiddenItemsFlags
	ld a, [wHiddenItemOrCoinsIndex]
	ld c, a
	ld b, FLAG_TEST
	predef FlagActionPredef

	; 1ならhidden itemは発見済み
	ld a, c
	and a
	ret nz

	; 
	call EnableAutoTextBoxDrawing
	ld a, 1
	ld [wDoNotWaitForButtonPressAfterDisplayingText], a
	
	; hidden itemの名前を取得
	ld a, [wHiddenObjectFunctionArgument] ; item ID
	ld [wd11e], a
	call GetItemName

	; hidden item発見テキストを表示する
	tx_pre_jump FoundHiddenItemText

INCLUDE "data/hidden_item_coords.asm"

FoundHiddenItemText:
	TX_FAR _FoundHiddenItemText
	TX_ASM
	ld a, [wHiddenObjectFunctionArgument] ; item ID
	ld b, a
	ld c, 1
	call GiveItem
	jr nc, .bagFull
	ld hl, wObtainedHiddenItemsFlags
	ld a, [wHiddenItemOrCoinsIndex]
	ld c, a
	ld b, FLAG_SET
	predef FlagActionPredef
	ld a, SFX_GET_ITEM_2
	call PlaySoundWaitForCurrent
	call WaitForSoundToFinish
	jp TextScriptEnd
.bagFull
	call WaitForTextScrollButtonPress ; wait for button press
	xor a
	ld [wDoNotWaitForButtonPressAfterDisplayingText], a
	ld hl, HiddenItemBagFullText
	call PrintText
	jp TextScriptEnd

HiddenItemBagFullText:
	TX_FAR _HiddenItemBagFullText
	db "@"

; **HiddenCoins**  
; 隠しコインを調べる処理  
; 隠しコインが存在する場所かつまだ取得フラグが立っていないのなら隠しアイテムを取得する  
; - - -  
; INPUT: 
; - [wCurMap] = 現在のマップ
; - [wHiddenObjectX]/[wHiddenObjectY] = 現在調べているマスのcoord  
HiddenCoins:
	; コインケースを持っていないなら返る
	ld b, COIN_CASE
	predef GetQuantityOfItemInBag
	ld a, b
	and a
	ret z

	; hidden coinが存在するか調べて、存在しない or 既に取得済み なら返る 
	ld hl, HiddenCoinCoords
	call FindHiddenItemOrCoinsIndex
	ld [wHiddenItemOrCoinsIndex], a
	ld hl, wObtainedHiddenCoinsFlags
	ld a, [wHiddenItemOrCoinsIndex]
	ld c, a
	ld b, FLAG_TEST
	predef FlagActionPredef
	ld a, c
	and a
	ret nz

	; hCoins = 0
	xor a
	ld [hUnusedCoinsByte], a
	ld [hCoins], a
	ld [hCoins + 1], a

	; 
	ld a, [wHiddenObjectFunctionArgument]
	sub COIN	; コインのアイテムID
	; コイン10枚を発見
	cp 10
	jr z, .bcd10
	; コイン20枚を発見
	cp 20
	jr z, .bcd20
	; コイン40枚を発見(なぜか.bcd20 おそらくミス)
	cp 40
	jr z, .bcd20 ; should be bcd40
	; それ以外はコイン100枚
	jr .bcd100

	; hCoinsに取得したhidden coinの枚数を格納
.bcd10
	ld a, $10
	ld [hCoins + 1], a
	jr .bcdDone
.bcd20
	ld a, $20
	ld [hCoins + 1], a
	jr .bcdDone
.bcd40 ; due to a typo, this is never used
	ld a, $40
	ld [hCoins + 1], a
	jr .bcdDone
.bcd100
	ld a, $1
	ld [hCoins], a
	
.bcdDone
	ld de, wPlayerCoins + 1
	ld hl, hCoins + 1
	ld c, $2
	predef AddBCDPredef
	ld hl, wObtainedHiddenCoinsFlags
	ld a, [wHiddenItemOrCoinsIndex]
	ld c, a
	ld b, FLAG_SET
	predef FlagActionPredef
	call EnableAutoTextBoxDrawing
	ld a, [wPlayerCoins]
	cp $99
	jr nz, .roomInCoinCase
	ld a, [wPlayerCoins + 1]
	cp $99
	jr nz, .roomInCoinCase
	tx_pre_id DroppedHiddenCoinsText
	jr .done
.roomInCoinCase
	tx_pre_id FoundHiddenCoinsText
.done
	jp PrintPredefTextID

INCLUDE "data/hidden_coins.asm"

FoundHiddenCoinsText:
	TX_FAR _FoundHiddenCoinsText
	TX_SFX_ITEM_2
	db "@"

DroppedHiddenCoinsText:
	TX_FAR _FoundHiddenCoins2Text
	TX_SFX_ITEM_2
	TX_FAR _DroppedHiddenCoinsText
	db "@"

; **FindHiddenItemOrCoinsIndex**  
; 現在調べているマスにhidden item(coin)があるなら該当するHiddenItemCoordsのオフセットを取得する
; - - -  
; INPUT: 
; - hl = HiddenItemCoords or HiddenCoinCoords
; - [wCurMap] = 現在のマップ
; - [wHiddenObjectX]/[wHiddenObjectY] = 現在調べているマスのcoord
; 
; OUTPUT: a = HiddenItemCoordsのオフセット hidden itemがなかったら$ff
FindHiddenItemOrCoinsIndex:
	; de = 現在調べている座標
	ld a, [wHiddenObjectY]
	ld d, a
	ld a, [wHiddenObjectX]
	ld e, a
	; bc = ([wCurMap] << 8 | 0xff)
	ld a, [wCurMap]
	ld b, a
	ld c, -1
.loop
	inc c
	
	; a = hidden itemのマップID
	ld a, [hli]
	
	; hidden itemのエントリをすべて見たが該当するものはなかった 
	cp $ff ; end of the list?
	ret z  ; if so, we're done here
	
	; 現在調べているマップのマスとhidden itemの場所が一致するか
	cp b
	jr nz, .next1
	ld a, [hli]
	cp d
	jr nz, .next2
	ld a, [hli]
	cp e
	jr nz, .loop
	ld a, c
	ret
	; 次のエントリを検討
.next1
	inc hl
.next2
	inc hl
	jr .loop
