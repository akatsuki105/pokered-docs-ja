; **PrintBookshelfText**  
; 目の前に本棚があるかチェックし、あればテキストを表示する  
; - - -  
; 本棚がなかった場合は、カードキーのドアチェックに入る  
; 
; OUTPUT: [$ffdb] = $0(本棚あり) or $ff(なし)
PrintBookshelfText:
	; 主人公が上を向いていない -> .noMatch
	ld a, [wSpriteStateData1 + 9] ; 本棚は常に下から話しかける配置になっている
	cp SPRITE_FACING_UP
	jr nz, .noMatch

	; 上を向いているとき

	; b = タイルセットID, c = プレイヤーの1マス上のタイル
	ld a, [wCurMapTileset]
	ld b, a
	aCoord 8, 7
	ld c, a
	ld hl, BookshelfTileIDs

; BookshelfTileIDs を1エントリ ずつ見ていってプレイヤーの1マス上のタイルが本棚(タウンマップ、陳列棚)かチェックする
.loop
	ld a, [hli]
	cp $ff
	jr z, .noMatch

	; タイルセットが不一致
	cp b
	jr nz, .nextBookshelfEntry1

	; タイル番号が不一致
	ld a, [hli]
	cp c
	jr nz, .nextBookshelfEntry2

	; 一致した場合はテキストを表示
	ld a, [hl]
	push af
	call EnableAutoTextBoxDrawing
	pop af
	call PrintPredefTextID
	
	xor a
	ld [$ffdb], a
	ret
.nextBookshelfEntry1
	inc hl
.nextBookshelfEntry2
	inc hl
	jr .loop
.noMatch
	ld a, $ff
	ld [$ffdb], a
	jpba PrintCardKeyText

; db タイルセットID, タイルID  
; db_tx_pre TextID  
BookshelfTileIDs:
	db PLATEAU,      $30
	db_tx_pre IndigoPlateauStatues
	db HOUSE,        $3D
	db_tx_pre TownMapText
	db HOUSE,        $1E
	db_tx_pre BookOrSculptureText	; "Crammed full of #MON books!" or "It's a sculpture of DIGLETT."
	db MANSION,      $32
	db_tx_pre BookOrSculptureText
	db REDS_HOUSE_1, $32
	db_tx_pre BookOrSculptureText
	db LAB,          $28
	db_tx_pre BookOrSculptureText
	db LOBBY,        $16
	db_tx_pre ElevatorText			; "This is an elevator."
	db GYM,          $1D
	db_tx_pre BookOrSculptureText
	db DOJO,         $1D
	db_tx_pre BookOrSculptureText
	db GATE,         $22
	db_tx_pre BookOrSculptureText
	db MART,         $54
	db_tx_pre PokemonStuffText		; "Wow! Tons of #MON stuff!"
	db MART,         $55
	db_tx_pre PokemonStuffText
	db POKECENTER,   $54
	db_tx_pre PokemonStuffText
	db POKECENTER,   $55
	db_tx_pre PokemonStuffText
	db LOBBY,        $50
	db_tx_pre PokemonStuffText
	db LOBBY,        $52
	db_tx_pre PokemonStuffText
	db SHIP,         $36
	db_tx_pre BookOrSculptureText
	db $FF

IndigoPlateauStatues:
	TX_ASM
	ld hl, IndigoPlateauStatuesText1
	call PrintText
	ld a, [wXCoord]
	bit 0, a
	ld hl, IndigoPlateauStatuesText2
	jr nz, .ok
	ld hl, IndigoPlateauStatuesText3
.ok
	call PrintText
	jp TextScriptEnd

IndigoPlateauStatuesText1:
	TX_FAR _IndigoPlateauStatuesText1
	db "@"

IndigoPlateauStatuesText2:
	TX_FAR _IndigoPlateauStatuesText2
	db "@"

IndigoPlateauStatuesText3:
	TX_FAR _IndigoPlateauStatuesText3
	db "@"

BookOrSculptureText:
	TX_ASM

; hl = PokemonBooksText or DiglettSculptureText
	ld hl, PokemonBooksText		; "Crammed full of #MON books!"
	ld a, [wCurMapTileset]
	; タマムシマンション -> hl = DiglettSculptureText
	cp MANSION
	jr nz, .ok
	; (8, 6)のタイル番号が$38の場合 -> hl = DiglettSculptureText
	aCoord 8, 6
	cp $38
	jr nz, .ok
	ld hl, DiglettSculptureText	; "It's a sculpture of DIGLETT."

.ok
	call PrintText
	jp TextScriptEnd

; "Crammed full of #MON books!"
PokemonBooksText:
	TX_FAR _PokemonBooksText
	db "@"

; "It's a sculpture of DIGLETT."
DiglettSculptureText:
	TX_FAR _DiglettSculptureText
	db "@"

; "This is an elevator."
ElevatorText:
	TX_FAR _ElevatorText
	db "@"

TownMapText:
	TX_FAR _TownMapText	; "A TOWN MAP."
	TX_BLINK
	TX_ASM
	ld a, $1
	ld [wDoNotWaitForButtonPressAfterDisplayingText], a
	ld hl, wd730
	set 6, [hl]
	call GBPalWhiteOutWithDelay3
	xor a
	ld [hWY], a
	inc a
	ld [H_AUTOBGTRANSFERENABLED], a
	call LoadFontTilePatterns
	callba DisplayTownMap
	ld hl, wd730
	res 6, [hl]
	ld de, TextScriptEnd
	push de
	ld a, [H_LOADEDROMBANK]
	push af
	jp CloseTextDisplay

; "Wow! Tons of #MON stuff!"
PokemonStuffText:
	TX_FAR _PokemonStuffText
	db "@"
