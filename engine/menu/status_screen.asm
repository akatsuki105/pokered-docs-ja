; **DrawHP**  
; ステータス画面でのHPバーとHP数値の描画  
; - - -  
; INPUT: hl = HPバーを描画する場所  
DrawHP:
	call GetPredefRegisters
	ld a, $1
	jr DrawHP_

; **DrawHP2**  
; 手持ち一覧でのHPバーの描画  
; - - -  
; INPUT: hl = HPバーを描画する場所  
DrawHP2:
	call GetPredefRegisters
	ld a, $2

; **DrawHP_**  
; DrawHP と DrawHP2 から呼ばれる内部処理  
DrawHP_:
	ld [wHPBarType], a
	push hl

; 描画対象のHP が 0のとき c = 0, de = 0x0600
; 描画対象のHP が 0でない c = XX, de = 0x06XX (XX = HPバーのピクセル数)
	ld a, [wLoadedMonHP]
	ld b, a
	ld a, [wLoadedMonHP + 1]
	ld c, a
	or b	; [wLoadedMonHP] | [wLoadedMonHP + 1]
	jr nz, .nonzeroHP
	xor a
	ld c, a	; bc = 0
	ld e, a
	ld a, $6
	ld d, a	; de = 0x0600
	jp .drawHPBarAndPrintFraction
.nonzeroHP
	ld a, [wLoadedMonMaxHP]
	ld d, a
	ld a, [wLoadedMonMaxHP + 1]
	ld e, a
	predef HPBarLength
	ld a, $6
	ld d, a	; de = 0x06XX
	ld c, a	; c = XX

.drawHPBarAndPrintFraction
	pop hl	; hl = HPバーの描画先
	push de
	push hl

	; HPバーを描画
	push hl
	call DrawHPBar
	pop hl

; bc = $9(手持ち画面) or SCREEN_WIDTH+1(それ以外)
	ld a, [hFlags_0xFFF6]
	bit 0, a
	jr z, .printFractionBelowBar
	ld bc, $9 ; right of bar
	jr .printFraction
.printFractionBelowBar
	ld bc, SCREEN_WIDTH + 1 ; below bar

.printFraction
	; AA/BB (AA: 現HP, BB: maxHP) を描画
	add hl, bc	; hl = HP数値の描画先
	ld de, wLoadedMonHP
	lb bc, 2, 3
	call PrintNumber
	ld a, "/"
	ld [hli], a
	ld de, wLoadedMonMaxHP
	lb bc, 2, 3
	call PrintNumber
	pop hl	; hl = HPバーの描画先
	pop de	; de = 0x06XX (XX = HPバーのピクセル数)
	ret


; **StatusScreen**  
; Predef 0x37  
; INPUT: [wMonDataLocation] = 表示対象がどのデータスロットにいるか
StatusScreen:
	call LoadMonData

	; PCBoxか育て屋の時はパラメータを変えて stats を再計算
	ld a, [wMonDataLocation]
	cp BOX_DATA
	jr c, .DontRecalculate
	ld a, [wLoadedMonBoxLevel]
	ld [wLoadedMonLevel], a
	ld [wCurEnemyLVL], a
	ld hl, wLoadedMonHPExp - 1
	ld de, wLoadedMonStats
	ld b, $1
	call CalcStats ; Recalculate stats

.DontRecalculate
	; 音量を下げる
	ld hl, wd72c
	set 1, [hl]
	ld a, $33
	ld [rNR50], a ; Reduce the volume

	; 画面を真っ白にする
	call GBPalWhiteOutWithDelay3
	call ClearScreen
	call UpdateSprites

	call LoadHpBarAndStatusTilePatterns

	; ·│ :L and half-arrow line end をVRAMに転送
	ld de, BattleHudTiles1	; from
	ld hl, vChars2 + $6d0	; to
	lb bc, BANK(BattleHudTiles1), $03 ; 3枚
	call CopyVideoDataDouble

	; │ をVRAMに転送
	ld de, BattleHudTiles2
	ld hl, vChars2 + $780
	lb bc, BANK(BattleHudTiles2), $01
	call CopyVideoDataDouble

	; ─┘ をVRAMに転送
	ld de, BattleHudTiles3
	ld hl, vChars2 + $760
	lb bc, BANK(BattleHudTiles3), $02
	call CopyVideoDataDouble

	; PP の Pの字のタイルをVRAMに転送
	ld de, PTile
	ld hl, vChars2 + $720
	lb bc, BANK(PTile), (PTileEnd - PTile) / $8
	call CopyVideoDataDouble

	; [hTilesetType] を indoor に(水や花が定期的に動く処理をoffに)
	ld a, [hTilesetType]
	push af
	xor a
	ld [hTilesetType], a

	; ┘ 形の線を描画その1 https://imgur.com/g8sBtXb.png
	coord hl, 19, 1
	lb bc, 6, 10
	call DrawLineBox

	; "No."を描画
	ld de, -6
	add hl, de
	ld [hl], "⠄"
	dec hl
	ld [hl], "№"

	; ┘ 形の線を描画その2 https://imgur.com/6Cmgx8B.png
	coord hl, 19, 9
	lb bc, 8, 6
	call DrawLineBox

	; "TYPE1/" を描画
	coord hl, 10, 9
	ld de, Type1Text
	call PlaceString

	; HP を描画
	coord hl, 11, 3
	predef DrawHP
	
	; SGBのときはHPバーに色を反映
	ld hl, wStatusScreenHPBarColor
	call GetHealthBarColor
	ld b, SET_PAL_STATUS_SCREEN
	call RunPaletteCommand

	; ポケモンの状態異常を描画
	coord hl, 16, 6
	ld de, wLoadedMonStatus
	call PrintStatusCondition
	jr nz, .StatusWritten
	coord hl, 16, 6
	ld de, OKText
	call PlaceString ; "OK"

.StatusWritten
	; "STATUS/" を描画
	coord hl, 9, 6
	ld de, StatusText
	call PlaceString

	; ポケモンのレベル を描画
	coord hl, 14, 2
	call PrintLevel
	
	; 図鑑番号を描画
	ld a, [wMonHIndex]
	ld [wd11e], a
	ld [wd0b5], a
	predef IndexToPokedex
	coord hl, 3, 7
	ld de, wd11e
	lb bc, LEADING_ZEROES | 1, 3
	call PrintNumber ; Pokémon no.

	; ポケモンのタイプ(タイプ1, タイプ2) を描画
	coord hl, 11, 10
	predef PrintMonType

	; ポケモンのニックネーム を描画
	ld hl, NamePointers2
	call .GetStringPointer
	ld d, h
	ld e, l
	coord hl, 9, 1
	call PlaceString

	; OT を描画
	ld hl, OTPointers
	call .GetStringPointer
	ld d, h
	ld e, l
	coord hl, 12, 16
	call PlaceString

	; IDNo. を描画
	coord hl, 12, 14
	ld de, wLoadedMonOTID
	lb bc, LEADING_ZEROES | 2, 5
	call PrintNumber

	ld d, $0
	call PrintStatsBox

	; ポケモンのグラフィックを描画
	call Delay3
	call GBPalNormal
	coord hl, 1, 0
	call LoadFlippedFrontSpriteByMonIndex

	; 鳴き声を出す
	ld a, [wcf91]
	call PlayCry

	; A/Bボタンを待つ
	call WaitForTextScrollButtonPress

	; 終了
	pop af
	ld [hTilesetType], a
	ret

.GetStringPointer
	ld a, [wMonDataLocation]
	add a
	ld c, a
	ld b, 0
	add hl, bc
	inline "hl = [hl]"
	ld a, [wMonDataLocation]
	cp DAYCARE_DATA
	ret z
	ld a, [wWhichPokemon]
	jp SkipFixedLengthTextEntries

OTPointers:
	dw wPartyMonOT
	dw wEnemyMonOT
	dw wBoxMonOT
	dw wDayCareMonOT

NamePointers2:
	dw wPartyMonNicks
	dw wEnemyMonNicks
	dw wBoxMonNicks
	dw wDayCareMonName

Type1Text:
	db "TYPE1/", $4e

Type2Text:
	db "TYPE2/", $4e

IDNoText:
	db $73, "№/", $4e

OTText:
	db   "OT/"
	next "@"

StatusText:
	db "STATUS/@"

OKText:
	db "OK@"

; **DrawLineBox**  
; ステータスボックス用に ┘ 形の線を描画する  
; - - -  
; hl = 描画先  
; b = ┘ 形の縦の線の長さ(タイル)  
; c = ┘ 形の横の線の長さ(タイル)  
DrawLineBox:
	ld de, SCREEN_WIDTH ; New line
.PrintVerticalLine
	ld [hl], $78 ; │
	add hl, de
	dec b
	jr nz, .PrintVerticalLine
	ld [hl], $77 ; ┘
	dec hl
.PrintHorizLine
	ld [hl], $76 ; ─
	dec hl
	dec c
	jr nz, .PrintHorizLine
	ld [hl], $6f ; ← (halfarrow ending)
	ret

PTile: ; This is a single 1bpp "P" tile
	INCBIN "gfx/p_tile.1bpp"
PTileEnd:

; **PrintStatsBox**  
; ステータスボックスを描画する  
; - - -  
; INPUT: 
; d = 0(ステータス画面) or 1(レベルUP時など)  
PrintStatsBox:
	; 
	ld a, d
	and a ; a is 0 from the status screen

	; ステータス画面では左下に描画
	jr nz, .DifferentBox
	coord hl, 0, 8
	ld b, 8
	ld c, 8
	call TextBoxBorder ; Draws the box
	coord hl, 1, 9 ; Start printing stats from here
	ld bc, $0019 ; Number offset
	jr .PrintStats

	; LvUp時などは右に描画 (https://imgur.com/k7vtwEW.jpg)
.DifferentBox
	coord hl, 9, 2
	ld b, 8
	ld c, 9
	call TextBoxBorder
	coord hl, 11, 3
	ld bc, $0018

.PrintStats
	; "ATTACK/DEFENSE/SPEED/SPECIAL" を描画
	push bc
	push hl
	ld de, StatsText
	call PlaceString
	pop hl
	pop bc

	; ステータス値を描画していく
	add hl, bc
	ld de, wLoadedMonAttack
	lb bc, 2, 3
	call PrintStat
	ld de, wLoadedMonDefense
	call PrintStat
	ld de, wLoadedMonSpeed
	call PrintStat
	ld de, wLoadedMonSpecial
	jp PrintNumber

PrintStat:
	push hl
	call PrintNumber
	pop hl
	ld de, SCREEN_WIDTH * 2
	add hl, de
	ret

; "ATTACK"  
; "DEFENSE"  
; "SPEED"  
; "SPECIAL"  
StatsText:
	db   "ATTACK"
	next "DEFENSE"
	next "SPEED"
	next "SPECIAL@"

; **StatusScreen2**  
; ステータス画面2を描画  
; - - -  
; https://imgur.com/ek7iTFP.png
StatusScreen2:
	; [hTilesetType] = 0
	ld a, [hTilesetType]
	push af
	xor a
	ld [hTilesetType], a
	ld [H_AUTOBGTRANSFERENABLED], a

	; wMoves にポケモンの技データをコピー
	ld bc, NUM_MOVES + 1
	ld hl, wMoves
	call FillMemory
	ld hl, wLoadedMonMoves
	ld de, wMoves
	ld bc, NUM_MOVES
	call CopyData

	callab FormatMovesString

	; ステータス画面1のニックネームの下をクリアする
	coord hl, 9, 2
	lb bc, 5, 10
	call ClearScreenArea

	; ???
	coord hl, 19, 3
	ld [hl], $78	; │

	; 技を描画するためのテキストボックスを描画
	coord hl, 0, 8
	ld b, 8
	ld c, 18
	call TextBoxBorder

	; 技を描画していく
	coord hl, 2, 9
	ld de, wMovesString
	call PlaceString ; Print moves

	ld a, [wNumMovesMinusOne]
	inc a
	ld c, a
	ld a, $4
	sub c
	ld b, a ; Number of moves ?
	coord hl, 11, 10
	ld de, SCREEN_WIDTH * 2
	ld a, $72 ; special P tile id
	call StatusScreen_PrintPP ; Print "PP"
	ld a, b
	and a
	jr z, .InitPP
	ld c, a
	ld a, "-"
	call StatusScreen_PrintPP ; Fill the rest with --
.InitPP
	ld hl, wLoadedMonMoves
	coord de, 14, 10
	ld b, 0
.PrintPP
	ld a, [hli]
	and a
	jr z, .PPDone
	push bc
	push hl
	push de
	ld hl, wCurrentMenuItem
	ld a, [hl]
	push af
	ld a, b
	ld [hl], a
	push hl
	callab GetMaxPP
	pop hl
	pop af
	ld [hl], a
	pop de
	pop hl
	push hl
	ld bc, wPartyMon1PP - wPartyMon1Moves - 1
	add hl, bc
	ld a, [hl]
	and $3f
	ld [wStatusScreenCurrentPP], a
	ld h, d
	ld l, e
	push hl
	ld de, wStatusScreenCurrentPP
	lb bc, 1, 2
	call PrintNumber
	ld a, "/"
	ld [hli], a
	ld de, wMaxPP
	lb bc, 1, 2
	call PrintNumber
	pop hl
	ld de, SCREEN_WIDTH * 2
	add hl, de
	ld d, h
	ld e, l
	pop hl
	pop bc
	inc b
	ld a, b
	cp $4
	jr nz, .PrintPP
.PPDone
	coord hl, 9, 3
	ld de, StatusScreenExpText
	call PlaceString
	ld a, [wLoadedMonLevel]
	push af
	cp MAX_LEVEL
	jr z, .Level100
	inc a
	ld [wLoadedMonLevel], a ; Increase temporarily if not 100
.Level100
	coord hl, 14, 6
	ld [hl], $70 ; 1-tile "to"
	inc hl
	inc hl
	call PrintLevel
	pop af
	ld [wLoadedMonLevel], a
	ld de, wLoadedMonExp
	coord hl, 12, 4
	lb bc, 3, 7
	call PrintNumber ; exp
	call CalcExpToLevelUp
	ld de, wLoadedMonExp
	coord hl, 7, 6
	lb bc, 3, 7
	call PrintNumber ; exp needed to level up
	coord hl, 9, 0
	call StatusScreen_ClearName
	coord hl, 9, 1
	call StatusScreen_ClearName
	ld a, [wMonHIndex]
	ld [wd11e], a
	call GetMonName
	coord hl, 9, 1
	call PlaceString
	ld a, $1
	ld [H_AUTOBGTRANSFERENABLED], a
	call Delay3
	call WaitForTextScrollButtonPress ; wait for button
	pop af
	ld [hTilesetType], a
	ld hl, wd72c
	res 1, [hl]
	ld a, $77
	ld [rNR50], a
	call GBPalWhiteOut
	jp ClearScreen

CalcExpToLevelUp:
	ld a, [wLoadedMonLevel]
	cp MAX_LEVEL
	jr z, .atMaxLevel
	inc a
	ld d, a
	callab CalcExperience
	ld hl, wLoadedMonExp + 2
	ld a, [hExperience + 2]
	sub [hl]
	ld [hld], a
	ld a, [hExperience + 1]
	sbc [hl]
	ld [hld], a
	ld a, [hExperience]
	sbc [hl]
	ld [hld], a
	ret
.atMaxLevel
	ld hl, wLoadedMonExp
	xor a
	ld [hli], a
	ld [hli], a
	ld [hl], a
	ret

StatusScreenExpText:
	db   "EXP POINTS"
	next "LEVEL UP@"

StatusScreen_ClearName:
	ld bc, 10
	ld a, " "
	jp FillMemory

StatusScreen_PrintPP:
; print PP or -- c times, going down two rows each time
	ld [hli], a
	ld [hld], a
	add hl, de
	dec c
	jr nz, StatusScreen_PrintPP
	ret
