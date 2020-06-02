HandleLedges:
	; すでに段差から飛び降り終えたなら終了
	ld a, [wd736]
	bit 6, a
	ret nz
	
	; 現在のタイルセットが OVERWORLD でないなら終了
	ld a, [wCurMapTileset]
	and a ; OVERWORLD
	ret nz

	predef GetTileAndCoordsInFrontOfPlayer

	; b = 主人公の方向
	ld a, [wSpriteStateData1 + 9]
	ld b, a

	; c = (8, 9)　= プレイヤーの立っている座標のBGタイル番号
	aCoord 8, 9
	ld c, a
	; d = プレイヤーの目の前のBGタイル番号
	ld a, [wTileInFrontOfPlayer]
	ld d, a

	ld hl, LedgeTiles
.loop
	; LedgeTilesを全部見た -> 終了
	ld a, [hli]
	cp $ff
	ret z

	; 方向が一致しない -> .nextLedgeTile1
	cp b
	jr nz, .nextLedgeTile1

	; 現在のタイルが一致しない
	ld a, [hli]
	cp c
	jr nz, .nextLedgeTile2

	; 段差のタイルが一致しない
	ld a, [hli]
	cp d
	jr nz, .nextLedgeTile3

	; ここまで来た時点で段差飛び降り処理の条件を満たしている
	; e = 段差を飛び降りるのに必要な入力 として -> .foundMatch
	ld a, [hl]
	ld e, a
	jr .foundMatch

	; 次の段差をチェックする
.nextLedgeTile1
	inc hl
.nextLedgeTile2
	inc hl
.nextLedgeTile3
	inc hl
	jr .loop

	; 現在飛び降りようとしている段差が見つかった
.foundMatch
	; 要求されている入力が入力されていないなら終了
	ld a, [hJoyHeld]
	and e
	ret z

	; 段差を飛び降りている間はキー入力を全て無視する
	ld a, $ff
	ld [wJoyIgnore], a

	; 段差飛び降り中のフラグを立てる
	ld hl, wd736
	set 6, [hl] ; jumping down ledge

	call StartSimulatingJoypadStates

	; 段差飛び降りの入力を simulated joypad として扱うようにする
	ld a, e
	ld [wSimulatedJoypadStatesEnd], a
	ld [wSimulatedJoypadStatesEnd + 1], a
	ld a, $2
	ld [wSimulatedJoypadStatesIndex], a

	call LoadHoppingShadowOAM
	ld a, SFX_LEDGE
	call PlaySound
	ret

; 段差を定義したテーブル  
; 各エントリ: db プレイヤーの方向 プレイヤーの立っているタイルID 段差のタイルID 段差を飛び降りるのに必要な入力
LedgeTiles:
	db SPRITE_FACING_DOWN, $2C,$37,D_DOWN
	db SPRITE_FACING_DOWN, $39,$36,D_DOWN
	db SPRITE_FACING_DOWN, $39,$37,D_DOWN
	db SPRITE_FACING_LEFT, $2C,$27,D_LEFT
	db SPRITE_FACING_LEFT, $39,$27,D_LEFT
	db SPRITE_FACING_RIGHT,$2C,$0D,D_RIGHT
	db SPRITE_FACING_RIGHT,$2C,$1D,D_RIGHT
	db SPRITE_FACING_RIGHT,$39,$0D,D_RIGHT
	db $FF

LoadHoppingShadowOAM:
	ld hl, vChars1 + $7f0
	ld de, LedgeHoppingShadow
	lb bc, BANK(LedgeHoppingShadow), (LedgeHoppingShadowEnd - LedgeHoppingShadow) / $8
	call CopyVideoDataDouble
	ld a, $9
	lb bc, $54, $48 ; b, c = y, x coordinates of shadow
	ld de, LedgeHoppingShadowOAM
	call WriteOAMBlock
	ret

LedgeHoppingShadow:
	INCBIN "gfx/ledge_hopping_shadow.1bpp"
LedgeHoppingShadowEnd:

LedgeHoppingShadowOAM:
	db $FF,$10,$FF,$20
	db $FF,$40,$FF,$60
