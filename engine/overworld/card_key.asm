PrintCardKeyText:
	; ループの初期化
	ld hl, SilphCoMapList
	ld a, [wCurMap]
	ld b, a
.silphCoMapListLoop
	; a = SilphCoMapList[i] (i: ループ回数)
	ld a, [hli]

	; 現在SilphCoMapListの中にいない
	cp $ff
	ret z
	
	; 次の要素を確認
	cp b
	jr nz, .silphCoMapListLoop

	; プレイヤーの目の前のタイルがカードキーのドアのタイルである
	predef GetTileAndCoordsInFrontOfPlayer
	ld a, [wTileInFrontOfPlayer]
	cp $18	; タイルID
	jr z, .cardKeyDoorInFrontOfPlayer
	cp $24  ; タイルID
	jr z, .cardKeyDoorInFrontOfPlayer

	; SILPH_CO_11FだけはタイルID=$5eもOK
	ld b, a
	ld a, [wCurMap]
	cp SILPH_CO_11F
	ret nz
	ld a, b
	cp $5e
	ret nz
.cardKeyDoorInFrontOfPlayer
	; カードキーで開くドアの前にいる

	; カードキーを持っていない
	ld b, CARD_KEY
	call IsItemInBag
	jr z, .noCardKey

	call GetCoordsInFrontOfPlayer
	push de
	tx_pre_id CardKeySuccessText
	ld [hSpriteIndexOrTextID], a
	call PrintPredefTextID
	pop de
	srl d
	ld a, d
	ld b, a
	ld [wCardKeyDoorY], a
	srl e
	ld a, e
	ld c, a
	ld [wCardKeyDoorX], a
	ld a, [wCurMap]
	cp SILPH_CO_11F
	jr nz, .notSilphCo11F
	ld a, $3
	jr .replaceCardKeyDoorTileBlock
.notSilphCo11F
	ld a, $e
.replaceCardKeyDoorTileBlock
	ld [wNewTileBlockID], a
	predef ReplaceTileBlock
	ld hl, wCurrentMapScriptFlags
	set 5, [hl]
	ld a, SFX_GO_INSIDE
	jp PlaySound
.noCardKey
	tx_pre_id CardKeyFailText
	ld [hSpriteIndexOrTextID], a
	jp PrintPredefTextID

SilphCoMapList:
	db SILPH_CO_2F
	db SILPH_CO_3F
	db SILPH_CO_4F
	db SILPH_CO_5F
	db SILPH_CO_6F
	db SILPH_CO_7F
	db SILPH_CO_8F
	db SILPH_CO_9F
	db SILPH_CO_10F
	db SILPH_CO_11F
	db $FF

CardKeySuccessText:
	TX_FAR _CardKeySuccessText1
	TX_SFX_ITEM_1
	TX_FAR _CardKeySuccessText2
	db "@"

CardKeyFailText:
	TX_FAR _CardKeyFailText
	db "@"

; プレイヤーの目の前のマスの座標(16*16単位)を得る
; 
; OUTPUT: 
; - d: Y座標
; - e: X座標
GetCoordsInFrontOfPlayer:
	ld a, [wYCoord]
	ld d, a
	ld a, [wXCoord]
	ld e, a
	ld a, [wSpriteStateData1 + 9] ; player's sprite facing direction
	and a
	jr nz, .notFacingDown
; facing down
	inc d
	ret
.notFacingDown
	cp SPRITE_FACING_UP
	jr nz, .notFacingUp
; facing up
	dec d
	ret
.notFacingUp
	cp SPRITE_FACING_LEFT
	jr nz, .notFacingLeft
; facing left
	dec e
	ret
.notFacingLeft
; facing right
	inc e
	ret
